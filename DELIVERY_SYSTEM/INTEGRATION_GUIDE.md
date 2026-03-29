# 🚀 INTEGRATION GUIDE - Delivery System for Period Tracker

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Database Setup](#database-setup)
3. [Backend Setup](#backend-setup)
4. [Flutter Integration](#flutter-integration)
5. [Testing](#testing)
6. [Deployment](#deployment)

---

## ⚡ Quick Start

### Prerequisites
- ✅ Flutter SDK (3.0+)
- ✅ Node.js (16+)
- ✅ Supabase account
- ✅ Android Studio / VS Code

### 5-Minute Setup

```bash
# 1. Run SQL schema in Supabase
# Go to Supabase Dashboard → SQL Editor → Paste DATABASE_SCHEMA.sql

# 2. Install backend dependencies
cd backend
npm install

# 3. Set environment variables
cp .env.example .env
# Edit .env with your Supabase credentials

# 4. Start backend server
npm start

# 5. Update Flutter API URL
# Edit lib/services/delivery_api_service.dart
# Change baseUrl to 'http://localhost:3000/api'

# 6. Run Flutter app
flutter run
```

---

## 🗄️ Database Setup

### Step 1: Execute SQL Schema

1. **Go to Supabase Dashboard**
   - URL: `https://vfzbewmyektmblkzlirp.supabase.co`
   - Navigate to **SQL Editor**

2. **Run the Schema**
   - Click **New Query**
   - Copy entire content from `DELIVERY_SYSTEM/DATABASE_SCHEMA.sql`
   - Paste and click **Run**

3. **Verify Tables Created**
   - Go to **Table Editor**
   - You should see 9 new tables:
     - categories
     - products
     - users
     - cart_items
     - orders
     - order_items
     - delivery_partners
     - delivery_tracking
     - emergency_kits

### Step 2: Seed Initial Data

```sql
-- Insert sample categories (already in schema)
INSERT INTO categories (name, description, icon, display_order) VALUES
('Sanitary Pads', 'Disposable and reusable pads', 'layers', 1),
('Tampons', 'Compact tampons', 'droplet', 2),
('Pain Relief', 'Medicines for cramps', 'medication', 3);

-- Insert sample products
INSERT INTO products (category_id, name, description, price, stock_quantity, is_emergency_item) VALUES
(1, 'Premium Pads Pack', 'Ultra-thin sanitary pads', 199, 100, true),
(3, 'Pain Relief Tablet', 'Fast acting cramp relief', 49, 200, true);
```

---

## 🔧 Backend Setup

### Step 1: Create Backend Folder

```bash
mkdir -p period_tracker/backend
cd period_tracker/backend
```

### Step 2: Initialize Node.js Project

```bash
npm init -y
```

### Step 3: Install Dependencies

```bash
npm install express @supabase/supabase-js dotenv cors helmet morgan
npm install --save-dev nodemon
```

### Step 4: Create Server File

Create `backend/server.js`:

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/products', require('./src/routes/products'));
app.use('/api/cart', require('./src/routes/cart'));
app.use('/api/orders', require('./src/routes/orders'));
app.use('/api/delivery', require('./src/routes/delivery'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
```

### Step 5: Create Environment File

Create `backend/.env`:

```env
SUPABASE_URL=https://vfzbewmyektmblkzlirp.supabase.co
SUPABASE_ANON_KEY=sb_publishable_DrH_abQya8dbBgxdObMmmA_GbS80Tpa
PORT=3000
NODE_ENV=development
```

### Step 6: Copy API Routes

Copy routes from `DELIVERY_SYSTEM/EXPRESS_API.js` to appropriate route files in `backend/src/routes/`.

### Step 7: Start Backend

```bash
# Development mode
npm run dev

# Production mode
npm start
```

Server should start at: `http://localhost:3000`

---

## 📱 Flutter Integration

### Step 1: Add Dependencies

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP client
  http: ^1.1.0
  
  # State management
  flutter_riverpod: ^2.4.0
  
  # UI enhancements
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Location services (for tracking)
  geolocator: ^10.1.0
  google_maps_flutter: ^2.5.0
```

Run:
```bash
flutter pub get
```

### Step 2: Create Models

Create model files in `lib/models/`:

**Example: `lib/models/product.dart`**
```dart
class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final List<String> imageUrls;
  final int categoryId;
  final bool isEmergencyItem;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.categoryId,
    required this.isEmergencyItem,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      description: json['description'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      categoryId: json['category_id'],
      isEmergencyItem: json['is_emergency_item'] ?? false,
    );
  }
}
```

### Step 3: Setup API Service

The API service is already created in `DELIVERY_SYSTEM/FLUTTER_API_SERVICE.dart`.

Copy it to:
```
lib/services/delivery_api_service.dart
```

Update the base URL:
```dart
static const String baseUrl = 'http://localhost:3000/api'; // For emulator
// OR
static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
```

### Step 4: Create Providers

Create `lib/providers/delivery_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/delivery_api_service.dart';
import '../models/product.dart';

final deliveryServiceProvider = Provider<DeliveryApiService>((ref) {
  return DeliveryApiService();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.read(deliveryServiceProvider);
  final response = await api.getProducts();
  return (response['data'] as List)
      .map((json) => Product.fromJson(json))
      .toList();
});

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    state = [...state, item];
  }

  void removeItem(int productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  double get total => state.fold(0, (sum, item) => sum + item.subtotal);
}
```

### Step 5: Add Screens

Copy screen code from `DELIVERY_SYSTEM/FLUTTER_SCREENS.dart` to respective files in:
```
lib/screens/delivery/
```

### Step 6: Setup Routes

Edit `lib/routes/app_routes.dart`:

```dart
class AppRoutes {
  static const String deliveryHome = '/delivery-home';
  static const String category = '/category';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderTracking = '/order-tracking';
  static const String emergencyKit = '/emergency-kit';
}
```

Edit `lib/routes/app_router.dart`:

```dart
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.deliveryHome:
      return MaterialPageRoute(builder: (_) => DeliveryHomeScreen());
    
    case AppRoutes.category:
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (_) => CategoryScreen(
          categoryId: args['id'],
          categoryName: args['name'],
        ),
      );
    
    // ... other routes
    
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('No route defined')),
        ),
      );
  }
}
```

### Step 7: Add Navigation to Home Screen

Edit your main home screen to add a navigation button:

```dart
ElevatedButton.icon(
  onPressed: () => Navigator.pushNamed(context, '/delivery-home'),
  icon: Icon(Icons.shopping_bag),
  label: Text('Order Essentials'),
)
```

---

## 🧪 Testing

### Test API Endpoints

```bash
# Test GET /products
curl http://localhost:3000/api/products

# Test GET /products/category/1
curl http://localhost:3000/api/products/category/1

# Test POST /cart/add (requires auth token)
curl -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 2}'
```

### Test Flutter App

1. **Run on Emulator**
   ```bash
   flutter run
   ```

2. **Test Flow**
   - Open Delivery Store
   - Browse products
   - Add to cart
   - Proceed to checkout
   - Place order
   - Track order

---

## 🚀 Deployment

### Backend Deployment (Heroku Example)

```bash
# Install Heroku CLI
npm install -g heroku

# Login
heroku login

# Create app
heroku create your-app-name

# Set environment variables
heroku config:set SUPABASE_URL=your_url
heroku config:set SUPABASE_ANON_KEY=your_key

# Deploy
git push heroku main
```

### Flutter Build

```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release

# Web
flutter build web
```

---

## 🔔 Emergency Kit Feature

### Quick Implementation

The Emergency Kit feature allows users to quickly order pre-configured kits during periods.

**Key Components:**

1. **Prominent Button** on home screen
2. **One-Tap Checkout** with saved address
3. **Priority Processing** in backend
4. **Express Delivery** assignment

**Code Example:**

```dart
// In DeliveryHomeScreen
ElevatedButton.icon(
  onPressed: () async {
    // Quick order emergency kit
    await ref.read(deliveryServiceProvider).orderEmergencyKit(
      kitId: 1,
      deliveryAddress: userDefaultAddress,
    );
    
    // Navigate directly to tracking
    Navigator.pushNamed(context, '/order-tracking');
  },
  icon: Icon(Icons.local_hospital, color: Colors.red),
  label: Text('EMERGENCY KIT'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  ),
)
```

---

## 📊 Monitoring & Analytics

### Recommended Tools

1. **Backend Monitoring**: PM2, New Relic
2. **Error Tracking**: Sentry, Bugsnag
3. **Analytics**: Firebase Analytics, Mixpanel
4. **Performance**: Lighthouse, WebPageTest

---

## 🆘 Troubleshooting

### Common Issues

**Issue**: Can't connect to backend from Flutter
- **Solution**: Use `10.0.2.2` instead of `localhost` for Android emulator
- For iOS simulator, use `localhost`

**Issue**: Supabase RLS policies blocking requests
- **Solution**: Check that user is authenticated and policies allow access

**Issue**: Products not showing
- **Solution**: Verify `is_active = true` and `stock_quantity > 0`

---

## 📞 Support

For issues or questions:
- Check documentation in `DELIVERY_SYSTEM/` folder
- Review Supabase docs: https://supabase.com/docs
- Flutter docs: https://docs.flutter.dev

---

**🎉 Congratulations! Your delivery system is now ready!**

Start testing and customize according to your needs!

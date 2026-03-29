# 🛍️ Period Tracker - Delivery System Feature

A comprehensive e-commerce delivery system integrated into the Period Tracker app, allowing users to order sanitary pads, medicines, comfort foods, and emergency period care kits.

---

## ✨ Features

### 🏪 **Online Store**
- Browse products by category
- Featured products showcase
- Search and filter functionality
- Product reviews and ratings
- Shopping cart management

### 🚨 **Emergency Period Care Kit** (Special Feature)
- One-tap ordering
- Pre-configured essential items:
  - Sanitary pads (regular/overnight)
  - Pain relief medicine
  - Comfort snacks (chocolate, etc.)
  - Optional: hot water bottle
- Express delivery (30 minutes)
- Priority processing

### 📦 **Order Management**
- Real-time order tracking
- Delivery partner assignment
- Live location updates
- Estimated arrival time
- Order history

### 💳 **Checkout & Payment**
- Multiple payment methods (COD, Card, UPI, Wallet)
- Saved addresses
- Order notes
- Emergency order toggle

---

## 📁 Documentation Structure

```
DELIVERY_SYSTEM/
├── README.md                    # This file - Overview
├── ARCHITECTURE.md              # System architecture & data flow
├── DATABASE_SCHEMA.sql          # Supabase PostgreSQL schema
├── EXPRESS_API.js               # Node.js API implementation
├── FLUTTER_API_SERVICE.dart     # Flutter HTTP service
├── FLUTTER_SCREENS.dart         # Complete UI screens
├── FOLDER_STRUCTURE.md          # Project organization
└── INTEGRATION_GUIDE.md         # Step-by-step setup guide
```

---

## 🗄️ Database Tables

| Table | Description |
|-------|-------------|
| `categories` | Product categories (Pads, Medicine, Snacks, etc.) |
| `products` | Available products with pricing and stock |
| `users` | User profiles with addresses and preferences |
| `cart_items` | Shopping cart items |
| `orders` | Order history and current orders |
| `order_items` | Individual items in each order |
| `delivery_partners` | Delivery personnel information |
| `delivery_tracking` | Real-time order tracking |
| `emergency_kits` | Pre-configured emergency kits |

---

## 🔌 API Endpoints

### Products
- `GET /api/products` - Get all products (with filters)
- `GET /api/products/category/:id` - Get products by category

### Cart
- `POST /api/cart/add` - Add product to cart

### Orders
- `POST /api/order/create` - Create new order
- `GET /api/orders/:userId` - Get user orders
- `PATCH /api/order/status/:orderId` - Update order status

### Emergency Kits
- `GET /api/emergency-kits` - Get available kits
- `POST /api/emergency-kit/order/:kitId` - Quick order kit

---

## 📱 Flutter Screens

1. **DeliveryHomeScreen** - Main store page with categories and featured products
2. **CategoryScreen** - Products filtered by category
3. **ProductListScreen** - All products view with sorting
4. **ProductDetailsScreen** - Detailed product information
5. **CartScreen** - Shopping cart with quantity management
6. **CheckoutScreen** - Address, payment, and review
7. **OrderTrackingScreen** - Real-time delivery tracking
8. **EmergencyKitScreen** - Quick emergency order page

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Node.js 16+
- Supabase account
- Android Studio / VS Code

### Installation (5 minutes)

```bash
# 1. Run SQL schema in Supabase Dashboard
# Copy DELIVERY_SYSTEM/DATABASE_SCHEMA.sql → SQL Editor → Run

# 2. Setup backend
cd backend
npm install
cp .env.example .env
# Edit .env with your Supabase credentials
npm start

# 3. Update Flutter config
# Edit lib/services/delivery_api_service.dart
# Change baseUrl to 'http://localhost:3000/api'

# 4. Install Flutter dependencies
flutter pub get

# 5. Run the app
flutter run
```

**Detailed instructions**: See [`INTEGRATION_GUIDE.md`](./INTEGRATION_GUIDE.md)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│      Flutter Mobile App             │
│  ┌────────┐ ┌──────┐ ┌──────────┐  │
│  │Screens │ │Models│ │ Services │  │
│  └────────┘ └──────┘ └──────────┘  │
└──────────────┬──────────────────────┘
               │ REST API
┌──────────────▼──────────────────────┐
│   Node.js + Express Backend         │
│  ┌────────┐ ┌──────────┐ ┌───────┐ │
│  │Routes  │ │Controllers│ │ Auth  │ │
│  └────────┘ └──────────┘ └───────┘ │
└──────────────┬──────────────────────┘
               │ PostgreSQL
┌──────────────▼──────────────────────┐
│      Supabase Database              │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ Tables │ │  RLS   │ │Triggers│  │
│  └────────┘ └────────┘ └────────┘  │
└─────────────────────────────────────┘
```

**Full architecture**: See [`ARCHITECTURE.md`](./ARCHITECTURE.md)

---

## 💻 Technology Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter 3.9.2 |
| State Management | Riverpod |
| Backend | Node.js + Express |
| Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| HTTP Client | `http` package |
| Real-time | Supabase Subscriptions |

---

## 🔐 Security Features

- ✅ JWT Authentication
- ✅ Row Level Security (RLS) in Supabase
- ✅ Role-based access control
- ✅ Secure password hashing
- ✅ API rate limiting
- ✅ Input validation
- ✅ CORS protection

---

## 🎯 Key Features Breakdown

### Emergency Period Care Kit

**User Flow:**
1. User taps "Emergency Kit" button on home screen
2. Pre-configured kit displayed with contents:
   - Sanitary Pads (10 pcs)
   - Pain Relief Tablet (4 pcs)
   - Chocolate Bar (2 pcs)
3. One-tap checkout with saved address
4. Order immediately assigned to nearest delivery partner
5. Real-time tracking with 30-min ETA

**Backend Processing:**
```javascript
// Priority flag set
isEmergencyOrder: true

// Expedited delivery fee
deliveryFee: 50 // vs normal 30

// Auto-assign nearest partner
assign_nearest_partner(orderId)

// Send priority notification
notifyDeliveryPartner(partnerId, 'URGENT')
```

### Regular Shopping Flow

1. Browse categories
2. View products
3. Add to cart
4. Review cart
5. Checkout
6. Track order (60-min ETA)

---

## 📊 Sample Data

### Categories
- Sanitary Pads
- Tampons
- Menstrual Cups
- Pain Relief
- Comfort Foods
- Heat Therapy
- Hygiene Products
- Wellness

### Sample Products
- Premium Pads Pack - $199
- Organic Tampons (16pcs) - $249
- Menstrual Cup - $399
- Pain Relief Tablets (10pcs) - $49
- Dark Chocolate Bar - $89
- Hot Water Bottle - $299
- Intimate Wipes (20pcs) - $99

---

## 🧪 Testing

### API Testing
```bash
# Get products
curl http://localhost:3000/api/products

# Add to cart
curl -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer TOKEN" \
  -d '{"productId": 1, "quantity": 2}'
```

### Widget Testing
```bash
# Run Flutter tests
flutter test test/delivery/
```

---

## 📈 Future Enhancements

- [ ] Subscription model for recurring deliveries
- [ ] AI-powered product recommendations
- [ ] Group orders for offices/colleges
- [ ] Loyalty points and rewards
- [ ] Multiple delivery addresses
- [ ] Scheduled deliveries
- [ ] Contactless delivery option
- [ ] In-app chat with delivery partner

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📄 License

This project is part of the Period Tracker application. See main project license.

---

## 👥 Support

For issues or questions:
- 📖 Check [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)
- 🐛 Report bugs in issue tracker
- 💬 Discussion forum

---

## 🎉 Credits

Developed as part of the Period Tracker app to help users access essential period care products conveniently and quickly, especially during emergencies.

---

**Made with ❤️ for better period care accessibility**

*Last Updated: $(date)*

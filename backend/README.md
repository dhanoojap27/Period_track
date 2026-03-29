# 🚀 Period Tracker Delivery Backend

Backend server for the Period Tracker Delivery System built with Express.js and Supabase.

## 📦 Setup

### Install Dependencies
```bash
npm install
```

### Configure Environment
Create `.env` file (already created):
```env
SUPABASE_URL=https://vfzbewmyektmblkzlirp.supabase.co
SUPABASE_ANON_KEY=sb_publishable_DrH_abQya8dbBgxdObMmmA_GbS80Tpa
PORT=3000
NODE_ENV=development
```

## 🏃 Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

## 🌐 API Endpoints

### Products
- `GET /api/products` - Get all products
- `GET /api/products/category/:id` - Get products by category
- `GET /api/products/:id` - Get single product

### Cart
- `POST /api/cart/add` - Add item to cart
- `GET /api/cart/:userId` - Get user's cart
- `DELETE /api/cart/:userId/:productId` - Remove from cart
- `PUT /api/cart/update` - Update quantity

### Orders
- `POST /api/order/create` - Create new order
- `GET /api/orders/:userId` - Get user orders
- `GET /api/orders/details/:orderId` - Get order details
- `PATCH /api/order/status/:orderId` - Update order status

### Delivery
- `GET /api/delivery/partners` - Get delivery partners
- `GET /api/delivery/tracking/:orderId` - Track order
- `POST /api/delivery/assign` - Assign delivery partner
- `PATCH /api/delivery/tracking/:id` - Update tracking
- `GET /api/delivery/emergency-kits` - Get emergency kits

### Health Check
- `GET /health` - Server health status
- `GET /api` - API information

## 📁 Project Structure

```
backend/
├── src/
│   ├── routes/
│   │   ├── products.js      # Product routes
│   │   ├── cart.js          # Cart routes
│   │   ├── orders.js        # Order routes
│   │   └── delivery.js      # Delivery routes
│   ├── controllers/         # Business logic (optional)
│   ├── middleware/          # Auth, validation (optional)
│   └── services/            # External services (optional)
├── .env                     # Environment variables
├── server.js                # Main Express app
└── package.json             # Dependencies
```

## 🔧 Testing

Test the API with curl or Postman:

```bash
# Health check
curl http://localhost:3000/health

# Get products
curl http://localhost:3000/api/products

# Get categories
curl http://localhost:3000/api/products/category/1
```

## 🎯 Integration with Flutter

Update your Flutter app's API service:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator  
static const String baseUrl = 'http://localhost:3000/api';

// For Physical Device (same network)
static const String baseUrl = 'http://YOUR_IP_ADDRESS:3000/api';
```

## 📝 Notes

- Server runs on port 3000 by default
- CORS is enabled for all origins in development
- All responses are in JSON format
- Error responses include error messages

## 🐛 Debugging

Check console logs for:
- Server startup messages
- API request logs (morgan)
- Error messages
- Database query errors

## 🚨 Common Issues

**Port already in use:**
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Change PORT in .env
PORT=3001
```

**Cannot connect to Supabase:**
- Check SUPABASE_URL and SUPABASE_ANON_KEY in .env
- Ensure database schema is created
- Verify internet connection

**CORS errors from Flutter:**
- Ensure CORS_ORIGIN in .env matches your Flutter app URL
- For development, use '*' to allow all

---

**Made for Period Tracker App** ❤️

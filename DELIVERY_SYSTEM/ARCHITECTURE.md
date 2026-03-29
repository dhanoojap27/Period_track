# Delivery System Architecture - Period Tracker App

## 📐 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ DeliveryHome │  │   Cart       │  │  Order       │          │
│  │   Screen     │  │   Screen     │  │  Tracking    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                 │
│         └──────────────────┼──────────────────┘                 │
│                            │                                    │
│                    ┌───────▼────────┐                           │
│                    │ API Service    │                           │
│                    │ (HTTP Client)  │                           │
│                    └───────┬────────┘                           │
└────────────────────────────┼────────────────────────────────────┘
                             │
                      HTTPS/REST API
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                   Node.js + Express Backend                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │    Routes    │  │ Controllers  │  │ Middleware   │          │
│  │   (API End   │  │  (Business   │  │   (Auth,     │          │
│  │    points)   │  │   Logic)     │  │ Validation)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                  │                  │                 │
│         └──────────────────┼──────────────────┘                 │
│                            │                                    │
│                    ┌───────▼────────┐                           │
│                    │  Supabase      │                           │
│                    │   Client       │                           │
│                    └───────┬────────┘                           │
└────────────────────────────┼────────────────────────────────────┘
                             │
                    PostgreSQL Protocol
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                     Supabase Database                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │  users   │ │ products │ │  orders  │ │ delivery │           │
│  │          │ │categories│ │cart_items│ │ partners │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │order_    │ │ delivery │ │ emergency │                        │
│  │ items    │ │ tracking │ │   kits    │                        │
│  └──────────┘ └──────────┘ └──────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### 1. **Product Browsing Flow**
```
User → DeliveryHomeScreen → GET /products → Display Products
                              ↓
                    Filter by Category → GET /products/category/:id
```

### 2. **Add to Cart Flow**
```
User adds product → CartScreen → POST /cart/add → Supabase cart_items
```

### 3. **Order Creation Flow**
```
CheckoutScreen → Validate Cart → POST /order/create
                                      ↓
                              Create order + order_items
                                      ↓
                              Clear cart_items
                                      ↓
                              Return order confirmation
```

### 4. **Order Tracking Flow**
```
OrderTrackingScreen → GET /orders/:userId → Display orders
                              ↓
                    Real-time updates via WebSocket
                              ↓
                    PATCH /order/status/:orderId (admin/delivery)
```

### 5. **Emergency Kit Flow**
```
Emergency Button → Quick Checkout → POST /order/create (priority=true)
                                           ↓
                                   Notify nearest delivery partner
                                           ↓
                                   Fast-track delivery
```

## 🔐 Security Architecture

```
┌─────────────────────────────────────────┐
│         Authentication Layer            │
│  ┌─────────────────────────────────┐   │
│  │  JWT Token (from Flutter Auth)  │   │
│  └──────────────┬──────────────────┘   │
│                 │                       │
│         ┌───────▼────────┐             │
│         │ Auth Middleware│             │
│         │  (Verify JWT)  │             │
│         └───────┬────────┘             │
└─────────────────┼───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Authorization Layer                │
│  ┌─────────────────────────────────┐   │
│  │  Role-based Access Control      │   │
│  │  - User: Own data only          │   │
│  │  - Admin: Full access           │   │
│  │  - Delivery: Assigned orders    │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## 📊 Component Breakdown

### **Frontend (Flutter)**
- **Screens**: 7 main screens for delivery flow
- **Services**: API service, State management (Riverpod)
- **Models**: Product, Cart, Order, Delivery
- **Features**: Emergency kit, Real-time tracking

### **Backend (Node.js + Express)**
- **Routes**: RESTful API endpoints
- **Controllers**: Business logic
- **Middleware**: Auth, validation, error handling
- **Supabase Client**: Database operations

### **Database (Supabase)**
- **Tables**: 8 core tables
- **RLS Policies**: Row-level security
- **Triggers**: Auto-update timestamps, notifications
- **Functions**: Calculate totals, assign delivery

## ⚡ Performance Optimizations

1. **Caching**: Redis for frequently accessed products
2. **Indexes**: On user_id, order_id, category_id
3. **Pagination**: For product lists and order history
4. **Real-time**: Supabase subscriptions for order status
5. **CDN**: For product images

## 🚨 Emergency Feature Architecture

```
┌─────────────────────────────────────────┐
│   Emergency Period Care Kit Button      │
│         (One-Tap Access)                │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   Pre-configured Kit Contents:          │
│   - Sanitary Pads (regular/overnight)   │
│   - Pain relief medicine                │
│   - Comfort snacks (chocolate, etc.)    │
│   - Hot water bottle (optional)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   Priority Processing:                  │
│   - Skip browsing → Direct checkout     │
│   - Auto-fill default address           │
│   - Express delivery option             │
│   - Notify nearest delivery partner     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   Real-time Notifications:              │
│   - Order confirmed                     │
│   - Partner assigned                    │
│   - Out for delivery                    │
│   - ETA updates                         │
│   - Delivered                           │
└─────────────────────────────────────────┘
```

## 📱 User Journey

### Regular Shopping:
1. Browse products by category
2. Add items to cart
3. Review cart
4. Checkout
5. Track order

### Emergency Kit:
1. Tap "Emergency Kit" button (prominent on home screen)
2. Confirm pre-configured kit
3. One-tap checkout
4. Priority delivery
5. Real-time tracking with ETA

## 🔔 Notification System

```
Event                          Trigger
─────────────────────────────────────────────────────
Order Created                  → User confirmation email/SMS
Order Confirmed                → Push notification
Partner Assigned               → Push + SMS with partner details
Out for Delivery               → Push notification + ETA
Delivered                      → Push + Request review
Low Stock Alert                → Admin dashboard notification
Emergency Order                → SMS to partner + priority alert
```

This architecture ensures scalability, security, and excellent user experience for your delivery feature!

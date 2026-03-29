# 🚀 QUICK START CARD - Delivery System

## ⚡ 5-Minute Setup

### Step 1: Database (2 min)
```
1. Open Supabase Dashboard
2. Go to SQL Editor → New Query
3. Copy DELIVERY_SYSTEM/DATABASE_SCHEMA.sql
4. Paste and Run ✅
```

### Step 2: Backend (2 min)
```bash
mkdir backend && cd backend
npm init -y
npm install express @supabase/supabase-js dotenv cors
# Create server.js (see INTEGRATION_GUIDE.md)
# Create .env with your credentials
node server.js
```

### Step 3: Flutter (1 min)
```dart
// Add to pubspec.yaml
dependencies:
  http: ^1.1.0
  flutter_riverpod: ^2.4.0

// Run in terminal
flutter pub get

// Update API URL
lib/services/delivery_api_service.dart
baseUrl = 'http://localhost:3000/api';

// Run app
flutter run
```

---

## 📁 Files You Need

| File | Purpose | Location |
|------|---------|----------|
| `DATABASE_SCHEMA.sql` | Create all tables | Run in Supabase |
| `EXPRESS_API.js` | Backend API code | Copy to backend/ |
| `FLUTTER_API_SERVICE.dart` | API calls | Copy to lib/services/ |
| `FLUTTER_SCREENS.dart` | UI screens | Copy to lib/screens/ |
| `INTEGRATION_GUIDE.md` | Full setup guide | Read this! |

---

## 🔑 Key URLs

- **Supabase Dashboard**: https://vfzbewmyektmblkzlirp.supabase.co
- **Backend API**: http://localhost:3000/api
- **Flutter DevTools**: http://127.0.0.1:9123

---

## 📱 Test Flow

1. ✅ Launch app
2. ✅ Navigate to Delivery Store
3. ✅ Browse products
4. ✅ Add items to cart
5. ✅ Checkout
6. ✅ Place order
7. ✅ Track delivery

---

## 🚨 Emergency Kit Test

```dart
// Tap emergency kit button on home screen
// Confirm order (one-tap)
// Watch real-time tracking
// Should show 30-min ETA
```

---

## 🐛 Common Issues

| Problem | Solution |
|---------|----------|
| Can't connect to API | Use `10.0.2.2:3000` for Android emulator |
| Products not loading | Check stock_quantity > 0 in database |
| Auth errors | Verify JWT token is being sent |
| RLS blocking | Check user is authenticated |

---

## 📞 Help Resources

- Full Guide: `INTEGRATION_GUIDE.md`
- Architecture: `ARCHITECTURE.md`
- API Docs: See `EXPRESS_API.js` comments
- Flutter Docs: https://docs.flutter.dev

---

**✅ You're all set! Start coding! 🎉**

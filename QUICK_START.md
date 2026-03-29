# Quick Start Guide - Period Tracker with Supabase

## 🚀 Running the App (Quick Steps)

### 1. Clean and Get Dependencies
```bash
flutter clean
flutter pub get
```

### 2. Run on Your Device
```bash
# For Chrome (recommended for testing)
flutter run -d chrome

# For Windows
flutter run -d windows

# For Edge
flutter run -d edge
```

### 3. What You Should See

**On successful startup:**
```
✅ Supabase initialized successfully
📡 Connected to: https://vfzbewmyektmblkzlirp.supabase.co
✅ App initialized successfully with Supabase
```

**If you see this instead:**
```
❌ Supabase initialization failed: ...
⚠️ App will run in offline-only mode
```
→ Check that `.env` file exists and has correct credentials

## 🔐 Test Authentication

### Sign Up
1. Click "Don't have an account? Sign Up"
2. Enter email and password (min 6 chars)
3. Click Sign Up
4. **Check console**: Should show "Sign up response received"
5. If email confirmation required → check your email
6. If auto-confirm enabled → redirects to home screen

### Sign In
1. Enter email and password
2. Click Sign In
3. **Check console**: Should show "Sign in successful"
4. Redirects to home/questionnaire

## 🛠️ Common Issues & Quick Fixes

### Issue: "Supabase not initialized"
**Fix:** 
- Stop the app
- Run `flutter clean && flutter pub get`
- Run again

### Issue: Build errors on Windows
**Fix:** Use Chrome instead
```bash
flutter run -d chrome
```

### Issue: Can't sign up (email confirmation)
**Fix:** In Supabase Dashboard:
- Authentication → Providers → Email
- Disable "Confirm email" OR check your inbox

### Issue: No data syncing
**Fix:**
1. Check internet connection
2. Verify Supabase tables exist (run SQL schema)
3. Check console for database errors

## 📊 Supabase Setup Checklist

- [ ] SQL schema executed in Supabase SQL Editor
- [ ] `.env` file created with credentials
- [ ] Email provider enabled in Supabase Auth
- [ ] Console shows "Supabase initialized successfully"

## 🎯 Debug Mode Tips

Add debug prints to track what's happening:

**In login screen, check:**
```dart
debugPrint('Supabase initialized: ${SupabaseConfig.isInitialized}');
```

**After sign in attempt, check:**
```dart
debugPrint('User signed in: ${user?.email}');
```

## 📱 Features Working When:

✅ **Authentication works** → Can sign up/sign in  
✅ **Database works** → Data saves to Supabase  
✅ **Sync works** → Data persists across sessions  
✅ **AI Chat works** → Messages saved to cloud  
✅ **Predictions work** → ML calculations saved  

---

**Need more help?** See `SUPABASE_FIX_SUMMARY.md` for detailed troubleshooting.

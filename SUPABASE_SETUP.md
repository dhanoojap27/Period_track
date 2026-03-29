# Supabase Setup Guide for Period Tracker

## ✅ Configuration Complete!

Your Flutter project is now configured to connect to your Supabase database.

## 📋 What Was Done

### 1. Created `.env` File
- Added your Supabase project credentials securely
- **File**: `.env` (gitignored for security)

### 2. Updated `supabase_config.dart`
- Modified to load credentials from `.env` file using `flutter_dotenv`
- Added validation to ensure credentials are present
- Enhanced error logging

### 3. Added Dependencies
- Added `flutter_dotenv: ^5.1.0` to `pubspec.yaml`
- Ran `flutter pub get` to install

### 4. Security
- Added `.env` to `.gitignore` to prevent credential leaks

## 🚀 Next Steps

### Step 1: Run the Database Schema

1. Go to your Supabase Dashboard: https://vfzbewmyektmblkzlirp.supabase.co
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the entire contents of `supabase_schema.sql` from this project
5. Paste it into the SQL Editor
6. Click **Run** or press `Ctrl+Enter`

This will create all necessary tables:
- ✅ `user_profiles` - User information and health data
- ✅ `user_settings` - Quick reference settings
- ✅ `cycles` - Period cycle entries with symptoms/mood/flow
- ✅ `predictions` - ML-based period predictions
- ✅ `chat_messages` - AI chat history
- ✅ `notifications` - Reminder notifications

### Step 2: Enable Email Authentication (Optional but Recommended)

In Supabase Dashboard:
1. Go to **Authentication** → **Providers**
2. Enable **Email** provider
3. Configure email templates (optional):
   - Go to **Authentication** → **Email Templates**
   - Customize verification and recovery emails

### Step 3: Test the Connection

Run your app:
```bash
flutter run
```

You should see in the debug console:
```
✅ Supabase initialized successfully
📡 Connected to: https://vfzbewmyektmblkzlirp.supabase.co
```

## 🔧 Troubleshooting

### Issue: "Supabase credentials not found in .env file"
**Solution**: Make sure the `.env` file exists in the project root and contains:
```
SUPABASE_URL=https://vfzbewmyektmblkzlirp.supabase.co
SUPABASE_ANON_KEY=sb_publishable_DrH_abQya8dbBgxdObMmmA_GbS80Tpa
```

### Issue: "Failed to connect to Supabase"
**Solutions**:
1. Check your internet connection
2. Verify the URL and API key are correct in `.env`
3. Check Supabase status at https://status.supabase.com

### Issue: Tables don't exist after running schema
**Solution**: 
1. Check the SQL Editor output for errors
2. Try dropping tables first: Add `DROP TABLE IF EXISTS ... CASCADE;` at the top
3. Run the schema again

## 📊 Your Supabase Project Details

- **Project URL**: https://vfzbewmyektmblkzlirp.supabase.co
- **Publisher Key**: sb_publishable_DrH_abQya8dbBgxdObMmmA_GbS80Tpa

## 🔐 Security Best Practices

1. ✅ Never commit `.env` file to version control
2. ✅ Use Row Level Security (RLS) policies (already included in schema)
3. ✅ Never expose your service role key in client code
4. ✅ Regularly rotate your API keys

## 📱 How Data Flows

```
User Action → Flutter App → Supabase Client → Supabase Database
     ↓                                              ↓
  Local Cache (Hive) ← Sync ← Remote Data
```

- **Online**: Data syncs to Supabase in real-time
- **Offline**: Data stored locally in Hive, syncs when online

## 🎯 Features Enabled

With this Supabase connection, your app now supports:
- ✅ User authentication (sign up/sign in)
- ✅ Cloud backup of all period data
- ✅ Multi-device sync
- ✅ AI chat conversations saved to cloud
- ✅ Secure data storage with RLS
- ✅ Real-time updates across devices

## 📞 Need Help?

- Supabase Docs: https://supabase.com/docs
- Flutter Dotenv: https://pub.dev/packages/flutter_dotenv
- Your Schema: See `supabase_schema.sql` in this project

---

**Ready to go! 🎉** Just run the SQL schema in Supabase and start your app.

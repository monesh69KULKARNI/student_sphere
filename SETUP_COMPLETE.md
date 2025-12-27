# Complete Setup Guide - Firebase Auth + Supabase Database

## Architecture Overview

**Firebase**: Authentication only  
**Supabase**: Database, Storage, and all data operations

## Setup Steps

### 1. Firebase Setup (Authentication)

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project: "StudentSphere"
   - Enable **Authentication** → **Email/Password**

2. **Configure Firebase in App**
   ```powershell
   flutterfire configure
   ```
   Or manually download `google-services.json` to `android/app/`

3. **No Firestore Needed!**
   - We're NOT using Firestore
   - Only Firebase Auth is required

### 2. Supabase Setup (Database & Storage)

1. **Create Supabase Project**
   - Go to [Supabase](https://supabase.com/)
   - Create new project: "StudentSphere"
   - Wait 2-3 minutes for setup

2. **Get Credentials**
   - Settings → API
   - Copy **Project URL** and **anon public** key

3. **Update Config**
   - Open `lib/core/config/supabase_config.dart`
   - Replace placeholders with your credentials

4. **Create Database Tables**
   - Go to Supabase → SQL Editor
   - Copy contents of `SUPABASE_DATABASE_SCHEMA.sql`
   - Run the SQL script
   - This creates all tables and RLS policies

5. **Create Storage Buckets**
   - Go to Storage
   - Create buckets:
     - `resources` (public, 50MB)
     - `profile-images` (public, 5MB)
     - `event-images` (public, 10MB)

### 3. Verify Setup

```bash
flutter run
```

Check console for:
- ✅ `Firebase initialized successfully`
- ✅ `Supabase initialized successfully`

## What Changed

### Before
- Firebase Auth + Firestore
- All data in Firestore

### After
- Firebase Auth only
- Supabase for database
- Supabase for storage

## Benefits

✅ **Cost-effective**: Supabase free tier is generous  
✅ **Better queries**: PostgreSQL is powerful  
✅ **Real-time**: Supabase real-time subscriptions  
✅ **Storage**: Cheaper file storage  
✅ **Security**: Row Level Security (RLS)

## Files to Configure

1. **Firebase**: `android/app/google-services.json`
2. **Supabase**: `lib/core/config/supabase_config.dart`

## Database Schema

All tables are created by running `SUPABASE_DATABASE_SCHEMA.sql` in Supabase SQL Editor.

## Next Steps

1. ✅ Set up Firebase Auth
2. ✅ Set up Supabase database
3. ✅ Run database schema SQL
4. ✅ Create storage buckets
5. ✅ Test the app

**You're all set!** 🚀


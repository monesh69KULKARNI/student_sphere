# Quick Setup Guide - Almost Automated! 🚀

## ✅ Already Done
- ✅ Firebase configured
- ✅ Supabase credentials configured

## 🔧 What You Need to Do (5 minutes)

### Option 1: Automated Setup (if you have service_role key)

1. Get your **Service Role Key** from Supabase:
   - Go to: https://app.supabase.com/project/dqeahphtfvqiqaprkwmi/settings/api
   - Copy the **service_role** key (secret key)

2. Run the setup script:
   ```powershell
   .\setup_supabase_database.ps1 -ServiceRoleKey "your-service-role-key"
   ```

### Option 2: Manual Setup (Recommended - 2 minutes)

#### Step 1: Create Database Tables

1. Go to Supabase SQL Editor:
   https://app.supabase.com/project/dqeahphtfvqiqaprkwmi/sql/new

2. Open `SUPABASE_DATABASE_SCHEMA.sql` in this project

3. Copy ALL the SQL code

4. Paste into Supabase SQL Editor

5. Click **Run** (or press Ctrl+Enter)

✅ Tables created!

#### Step 2: Create Storage Buckets

1. Go to Supabase Storage:
   https://app.supabase.com/project/dqeahphtfvqiqaprkwmi/storage/buckets

2. Click **New bucket** and create:

   **Bucket 1: `resources`**
   - Name: `resources`
   - Public: ✅ Yes
   - File size limit: 50 MB
   - Allowed MIME types: `*/*`

   **Bucket 2: `profile-images`**
   - Name: `profile-images`
   - Public: ✅ Yes
   - File size limit: 5 MB
   - Allowed MIME types: `image/*`

   **Bucket 3: `event-images`**
   - Name: `event-images`
   - Public: ✅ Yes
   - File size limit: 10 MB
   - Allowed MIME types: `image/*`

#### Step 3: Enable Firebase Authentication

1. Go to Firebase Console:
   https://console.firebase.google.com/project/studentsphere-6601a/authentication

2. Click **Get Started**

3. Enable **Email/Password** provider

4. Click **Save**

## ✅ Done!

Now run the app:
```bash
flutter run
```

The app should connect to both Firebase and Supabase! 🎉


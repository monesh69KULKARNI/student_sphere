# Supabase Setup Guide for StudentSphere

## What is Supabase Used For?

Supabase is used for **file storage** in StudentSphere:
- 📄 Resource files (PDFs, notes, videos)
- 🖼️ Profile images
- 📸 Event images
- 📁 Other uploaded files

**Note:** Supabase is **OPTIONAL**. The app will work without it, but file upload/download features will be disabled.

---

## Quick Setup (5 Minutes)

### Step 1: Create Supabase Project

1. Go to [Supabase](https://supabase.com/)
2. Sign up or log in
3. Click **"New Project"**
4. Fill in:
   - **Name:** StudentSphere
   - **Database Password:** (choose a strong password)
   - **Region:** Choose closest to you
5. Click **"Create new project"**
6. Wait 2-3 minutes for project to be created

### Step 2: Get Your Credentials

1. In your Supabase project, go to **Settings** → **API**
2. You'll see:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

### Step 3: Configure in App

1. Open `lib/core/config/supabase_config.dart`
2. Replace the placeholders:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  // ... rest stays the same
}
```

### Step 4: Create Storage Buckets

1. In Supabase, go to **Storage**
2. Click **"New bucket"**
3. Create these buckets (one at a time):

   **Bucket 1: `resources`**
   - Name: `resources`
   - Public: ✅ Yes (for public resources)
   - File size limit: 50 MB (or your preference)
   - Allowed MIME types: `*/*` (all types)

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

### Step 5: Set Storage Policies (Security)

Go to **Storage** → **Policies** for each bucket:

**For `resources` bucket:**
```sql
-- Allow public read access
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'resources');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'resources' AND
  auth.role() = 'authenticated'
);
```

**For `profile-images` bucket:**
```sql
-- Allow public read access
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

-- Allow users to upload their own profile images
CREATE POLICY "User upload own profile"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

**For `event-images` bucket:**
```sql
-- Allow public read access
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-images');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'event-images' AND
  auth.role() = 'authenticated'
);
```

### Step 6: Enable Supabase in App

1. Open `lib/main.dart`
2. Uncomment the Supabase initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  // Initialize Supabase
  await SupabaseService.initialize();  // ← Uncomment this line
  
  runApp(const StudentSphereApp());
}
```

### Step 7: Test

```bash
flutter run
```

Check the console for:
- ✅ `Supabase initialized successfully` - Good!
- ⚠️ `Supabase not configured` - Check your credentials

---

## Alternative: Use Firebase Storage Instead

If you prefer to use Firebase Storage instead of Supabase:

1. **Don't configure Supabase** (leave it commented out)
2. **Use Firebase Storage** for file uploads
3. Update the resource upload code to use `FirebaseStorage` instead

The app is designed to work with either option!

---

## Troubleshooting

### "Supabase not initialized"
- Check that credentials are correct in `supabase_config.dart`
- Make sure you uncommented `SupabaseService.initialize()` in `main.dart`
- Verify URL format: `https://xxxxx.supabase.co` (not `https://app.supabase.com/...`)

### "Permission denied" when uploading
- Check Storage policies in Supabase
- Make sure bucket exists
- Verify bucket name matches exactly (case-sensitive)

### "Bucket not found"
- Create the buckets in Supabase Storage
- Names must match: `resources`, `profile-images`, `event-images`

### File upload fails
- Check file size limits in bucket settings
- Verify MIME type is allowed
- Check network connection

---

## Storage Bucket Structure

```
resources/
  ├── notes/
  │   ├── subject1/
  │   └── subject2/
  ├── pdfs/
  └── videos/

profile-images/
  └── {userId}/
      └── profile.jpg

event-images/
  └── {eventId}/
      └── banner.jpg
```

---

## Cost Information

**Supabase Free Tier:**
- ✅ 500 MB storage
- ✅ 2 GB bandwidth/month
- ✅ Perfect for development and small deployments

**Upgrade when needed:**
- Pro plan: $25/month
- More storage and bandwidth

---

## Security Best Practices

1. ✅ Use **anon key** in client (it's safe - it's public)
2. ✅ Never commit **service_role** key to code
3. ✅ Set up proper Storage policies
4. ✅ Validate file types and sizes on upload
5. ✅ Use Row Level Security (RLS) if using Supabase database

---

## Next Steps

Once Supabase is configured:
1. ✅ Test file upload in Resource Sharing module
2. ✅ Test profile image upload
3. ✅ Test event image upload
4. ✅ Verify files are accessible via public URLs

**You're all set!** 🚀


# Quick Supabase Setup - 3 Minutes

## Supabase is OPTIONAL ⚠️

The app works without Supabase, but file storage features will be disabled.

---

## Quick Setup

### 1. Create Project
- Go to https://supabase.com/
- Sign up → New Project
- Name: "StudentSphere"
- Wait 2-3 minutes

### 2. Get Credentials
- Settings → API
- Copy **Project URL** and **anon public** key

### 3. Update Config
Open `lib/core/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 4. Create Buckets
In Supabase → Storage, create:
- ✅ `resources` (public, 50MB)
- ✅ `profile-images` (public, 5MB)
- ✅ `event-images` (public, 10MB)

### 5. Enable in App
Uncomment in `lib/main.dart`:
```dart
await SupabaseService.initialize();
```

### 6. Test
```bash
flutter run
```

Look for: ✅ `Supabase initialized successfully`

---

## Done! 🎉

See `SUPABASE_SETUP_GUIDE.md` for detailed instructions and security policies.


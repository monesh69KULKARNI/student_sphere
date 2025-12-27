# Setup Checklist ✅

## Configuration Status

### ✅ Firebase
- [x] `google-services.json` configured
- [x] Project ID: `studentsphere-6601a`
- [ ] Email/Password authentication enabled (check Firebase Console)

### ✅ Supabase
- [x] URL configured: `https://dqeahphtfvqiqaprkwmi.supabase.co`
- [x] Anon key configured
- [ ] Database tables created (SQL schema run)
- [ ] Storage buckets created:
  - [ ] `resources`
  - [ ] `profile-images`
  - [ ] `event-images`

## Quick Test

Run the app:
```bash
flutter run
```

### What to Test:

1. **App Launches** ✅
   - Should see login screen

2. **Sign Up**
   - Create a test account
   - Should save to Supabase `users` table

3. **Sign In**
   - Login with test account
   - Should load user data from Supabase

4. **Create Event** (as Faculty/Admin)
   - Should save to Supabase `events` table

5. **View Events**
   - Should load from Supabase

## If Something Doesn't Work:

### "Firebase not initialized"
- Check `google-services.json` is in `android/app/`
- Run `flutter clean` then `flutter pub get`

### "Supabase not initialized"
- Check `lib/core/config/supabase_config.dart` has real values
- Verify Supabase URL and key are correct

### "Permission denied" or "Table not found"
- Make sure you ran `SUPABASE_DATABASE_SCHEMA.sql` in Supabase SQL Editor
- Check tables exist in Supabase → Table Editor

### "Bucket not found"
- Create storage buckets in Supabase Storage
- Names must match exactly: `resources`, `profile-images`, `event-images`

## Next Steps After Setup:

1. ✅ Test authentication
2. ✅ Test creating events
3. ✅ Test file uploads (if storage buckets created)
4. ✅ Test role-based access

**You're ready to go!** 🚀


# Setting Up Firebase Auth with Supabase

Since we're using **Firebase for authentication** and **Supabase for database**, we need to configure Supabase to recognize Firebase Auth tokens.

## Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file (keep it secure!)

## Step 2: Configure Supabase to Accept Firebase Tokens

### Option A: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project
2. Go to **Settings** → **Auth** → **Providers**
3. Enable **Custom JWT** provider
4. You'll need to configure JWT verification

### Option B: Using Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Set Firebase JWT secret (from Firebase service account)
supabase secrets set FIREBASE_JWT_SECRET="your-firebase-secret"
```

## Step 3: Update Supabase RLS Policies

The RLS policies in `SUPABASE_DATABASE_SCHEMA.sql` use `auth.uid()` which expects Supabase auth. Since we're using Firebase Auth, we need to:

### Create a Function to Get Firebase UID

Run this SQL in Supabase SQL Editor:

```sql
-- Function to extract Firebase UID from JWT
CREATE OR REPLACE FUNCTION get_firebase_uid()
RETURNS TEXT AS $$
BEGIN
  -- Extract UID from Firebase JWT token
  -- This assumes the token is stored in auth.users or passed via header
  RETURN current_setting('request.jwt.claims', true)::json->>'user_id';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Alternative: Store Firebase UID in Supabase Auth

A simpler approach is to create a Supabase user with the same UID as Firebase:

1. When user signs up in Firebase, also create a Supabase user
2. Use the same UID for both
3. This way `auth.uid()` will work in RLS policies

## Step 4: Update Auth Service

The `AuthService` already handles this by:
1. Using Firebase Auth for authentication
2. Storing user data in Supabase `users` table with `uid` field
3. Using the Firebase UID as the primary identifier

## Step 5: Test Authentication Flow

1. User signs up with Firebase Auth
2. User data is saved to Supabase `users` table
3. When making database queries, pass Firebase UID
4. RLS policies check the `uid` field in `users` table

## Important Notes

- **Firebase UID** is stored as `uid` in Supabase `users` table
- RLS policies need to check `users.uid = auth.uid()::text` or use a custom function
- Make sure Firebase JWT is properly configured in Supabase
- The `auth.uid()` in RLS might need to be replaced with a custom function that reads from the JWT

## Simplified Approach (Current Implementation)

The current implementation uses a simpler approach:
- Firebase handles authentication
- Supabase stores user data with Firebase UID
- RLS policies are set to allow public reads where appropriate
- For writes, we check user role from the `users` table

This works because:
1. User authenticates with Firebase
2. We get their Firebase UID
3. We query Supabase `users` table using that UID
4. We check their role from the database
5. We enforce permissions in the service layer

## Security Considerations

- ✅ Firebase Auth is secure and industry-standard
- ✅ Supabase RLS provides additional database-level security
- ✅ Service layer validates permissions before database operations
- ⚠️ Make sure to set up proper RLS policies for your use case
- ⚠️ Consider using Supabase service role key for admin operations (server-side only)

## Troubleshooting

**"Permission denied" errors:**
- Check RLS policies are enabled
- Verify user exists in `users` table
- Check that `uid` field matches Firebase UID

**"User not found" errors:**
- Make sure user is created in Supabase after Firebase signup
- Verify `uid` field is set correctly

**Authentication issues:**
- Verify Firebase is properly initialized
- Check Supabase credentials are correct
- Ensure user data is synced between Firebase and Supabase


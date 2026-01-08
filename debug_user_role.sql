-- Debug queries to check your user role
-- Run these in Supabase SQL Editor

-- Check current user (fixed type casting)
SELECT uid, email, name, role FROM users 
WHERE uid = auth.uid()::text;

-- If that doesn't work, try this
SELECT uid, email, name, role FROM users 
WHERE uid = CAST(auth.uid() AS TEXT);

-- See all users to find your account
SELECT uid, email, name, role FROM users ORDER BY created_at DESC;

-- Check if announcements table exists and its structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'announcements' 
ORDER BY ordinal_position;

-- Check RLS policies on announcements table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'announcements';

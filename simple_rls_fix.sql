-- Simple RLS fix for announcements table
-- Run this in Supabase SQL Editor

-- First, completely drop all existing policies
DROP POLICY IF EXISTS "Public announcements visible to all" ON announcements;
DROP POLICY IF EXISTS "Authenticated users can view private announcements" ON announcements;
DROP POLICY IF EXISTS "Faculty and admins can create announcements" ON announcements;
DROP POLICY IF EXISTS "Authors and admins can update announcements" ON announcements;
DROP POLICY IF EXISTS "Admins can delete announcements" ON announcements;

-- Simple policies that should work
CREATE POLICY "Enable read access for all users"
  ON announcements FOR SELECT
  USING (true);

CREATE POLICY "Enable insert for authenticated users"
  ON announcements FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Alternative: More restrictive insert policy
-- CREATE POLICY "Enable insert for faculty and admin only"
--   ON announcements FOR INSERT
--   WITH CHECK (
--     EXISTS (
--       SELECT 1 FROM users 
--       WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
--     )
--   );

-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'announcements';

-- Test with current user
SELECT auth.uid(), auth.role();

-- Quick test: Temporarily disable RLS completely
-- ALTER TABLE announcements DISABLE ROW LEVEL SECURITY;

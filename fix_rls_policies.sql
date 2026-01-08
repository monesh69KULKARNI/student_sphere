-- Fix RLS policies for announcements table
-- Run this in Supabase SQL Editor

-- First, drop existing policies
DROP POLICY IF EXISTS "Public announcements visible to all" ON announcements;
DROP POLICY IF EXISTS "Faculty and admins can create announcements" ON announcements;

-- Create new, simpler RLS policies
CREATE POLICY "Public announcements visible to all"
  ON announcements FOR SELECT
  USING (is_public = true);

CREATE POLICY "Authenticated users can view private announcements"
  ON announcements FOR SELECT
  USING (auth.role() = 'authenticated' AND is_public = false);

CREATE POLICY "Faculty and admins can create announcements"
  ON announcements FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM users 
      WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
    )
  );

CREATE POLICY "Authors and admins can update announcements"
  ON announcements FOR UPDATE
  USING (
    author_id = auth.uid()::text OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE uid = auth.uid()::text AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete announcements"
  ON announcements FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE uid = auth.uid()::text AND role = 'admin'
    )
  );

-- Alternative: Temporarily disable RLS for testing
-- ALTER TABLE announcements DISABLE ROW LEVEL SECURITY;

-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'announcements';

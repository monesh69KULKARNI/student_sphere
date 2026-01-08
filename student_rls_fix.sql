-- Update RLS policies to allow students to create announcements
-- Run this in Supabase SQL Editor

-- Drop existing policies
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON announcements;

-- Create new policy that allows students, faculty, and admin to create announcements
CREATE POLICY "Students, faculty and admin can create announcements"
  ON announcements FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM users 
      WHERE uid = auth.uid()::text AND role IN ('student', 'faculty', 'admin')
    )
  );

-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'announcements';

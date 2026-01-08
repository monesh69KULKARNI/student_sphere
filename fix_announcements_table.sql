-- Complete migration script for announcements table
-- Run this SQL in your Supabase SQL Editor to fix all missing columns

-- Drop existing table if it has wrong structure (WARNING: This will delete existing data)
-- DROP TABLE IF EXISTS announcements CASCADE;

-- Create announcements table with correct structure
CREATE TABLE IF NOT EXISTS announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  author_id TEXT NOT NULL, -- Firebase UID
  author_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  is_public BOOLEAN DEFAULT TRUE,
  target_audience TEXT, -- 'all', 'students', 'faculty', 'specific_department'
  read_by TEXT[] DEFAULT '{}',
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  attachment_url TEXT
);

-- Add columns if they don't exist (safer approach)
ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT uuid_generate_v4();

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS title TEXT NOT NULL;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS content TEXT NOT NULL;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS author_id TEXT NOT NULL;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS author_name TEXT NOT NULL;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS target_audience TEXT;

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS read_by TEXT[] DEFAULT '{}';

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent'));

ALTER TABLE announcements 
ADD COLUMN IF NOT EXISTS attachment_url TEXT;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at);
CREATE INDEX IF NOT EXISTS idx_announcements_is_public ON announcements(is_public);

-- Enable Row Level Security (RLS)
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public announcements visible to all"
  ON announcements FOR SELECT
  USING (is_public = true);

CREATE POLICY "Faculty and admins can create announcements"
  ON announcements FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
    )
  );

-- Add comments for documentation
COMMENT ON TABLE announcements IS 'Table for storing system announcements';
COMMENT ON COLUMN announcements.id IS 'Primary key UUID';
COMMENT ON COLUMN announcements.title IS 'Announcement title';
COMMENT ON COLUMN announcements.content IS 'Announcement content/body';
COMMENT ON COLUMN announcements.author_id IS 'Firebase UID of the author';
COMMENT ON COLUMN announcements.author_name IS 'Display name of the author';
COMMENT ON COLUMN announcements.created_at IS 'Creation timestamp';
COMMENT ON COLUMN announcements.updated_at IS 'Last update timestamp';
COMMENT ON COLUMN announcements.is_public IS 'Whether announcement is public or private';
COMMENT ON COLUMN announcements.target_audience IS 'Target audience: all, students, faculty, specific_department';
COMMENT ON COLUMN announcements.read_by IS 'Array of user IDs who have read this announcement';
COMMENT ON COLUMN announcements.priority IS 'Priority level: low, medium, high, urgent';
COMMENT ON COLUMN announcements.attachment_url IS 'URL to attached file (PDF, image, etc.)';

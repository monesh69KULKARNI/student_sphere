-- Complete resources table setup for StudentSphere
-- Run this SQL in Supabase SQL Editor

-- Create resources table with correct structure
CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL, -- notes, videos, pdfs, slides, other
  subject TEXT NOT NULL,
  course TEXT NOT NULL,
  uploaderId TEXT NOT NULL, -- Firebase UID
  uploaderName TEXT NOT NULL,
  fileUrl TEXT NOT NULL, -- Supabase Storage URL
  fileName TEXT NOT NULL,
  fileSize INTEGER NOT NULL, -- in bytes
  fileType TEXT NOT NULL, -- pdf, mp4, docx, etc.
  uploadedAt TIMESTAMPTZ DEFAULT NOW(),
  isPublic BOOLEAN DEFAULT TRUE,
  tags TEXT[] DEFAULT '{}',
  downloadCount INTEGER DEFAULT 0,
  viewCount INTEGER DEFAULT 0
);

-- Add columns if they don't exist (safer approach)
ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT uuid_generate_v4();

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS title TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS description TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS category TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS subject TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS course TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS uploaderId TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS uploaderName TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS fileUrl TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS fileName TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS fileSize INTEGER NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS fileType TEXT NOT NULL;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS uploadedAt TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS isPublic BOOLEAN DEFAULT TRUE;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS downloadCount INTEGER DEFAULT 0;

ALTER TABLE resources 
ADD COLUMN IF NOT EXISTS viewCount INTEGER DEFAULT 0;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_resources_uploaded_at ON resources(uploadedAt);
CREATE INDEX IF NOT EXISTS idx_resources_category ON resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_subject ON resources(subject);
CREATE INDEX IF NOT EXISTS idx_resources_course ON resources(course);
CREATE INDEX IF NOT EXISTS idx_resources_uploader_id ON resources(uploaderId);
CREATE INDEX IF NOT EXISTS idx_resources_is_public ON resources(isPublic);

-- Enable Row Level Security (RLS)
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Public resources visible to all" ON resources;
DROP POLICY IF EXISTS "Authenticated users can upload resources" ON resources;
DROP POLICY IF EXISTS "Users can view their own and public resources" ON resources;

CREATE POLICY "Public resources visible to all"
  ON resources FOR SELECT
  USING (isPublic = true);

CREATE POLICY "Users can view their own resources"
  ON resources FOR SELECT
  USING (auth.uid()::text = uploaderId);

CREATE POLICY "Authenticated users can upload resources"
  ON resources FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own resources"
  ON resources FOR UPDATE
  USING (auth.uid()::text = uploaderId);

CREATE POLICY "Users can delete their own resources"
  ON resources FOR DELETE
  USING (auth.uid()::text = uploaderId);

-- Create storage bucket for files
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('resources', 'resources', true, 52428800, ARRAY['*'])
ON CONFLICT (id) DO NOTHING;

-- Add comments for documentation
COMMENT ON TABLE resources IS 'Table for storing educational resources and files';
COMMENT ON COLUMN resources.id IS 'Primary key UUID';
COMMENT ON COLUMN resources.title IS 'Resource title';
COMMENT ON COLUMN resources.description IS 'Resource description';
COMMENT ON COLUMN resources.category IS 'Resource category: notes, videos, pdfs, slides, other';
COMMENT ON COLUMN resources.subject IS 'Subject name (e.g., Mathematics, Physics)';
COMMENT ON COLUMN resources.course IS 'Course name (e.g., BE 1st Year)';
COMMENT ON COLUMN resources.uploaderId IS 'Firebase UID of the uploader';
COMMENT ON COLUMN resources.uploaderName IS 'Display name of the uploader';
COMMENT ON COLUMN resources.fileUrl IS 'URL to file in Supabase Storage';
COMMENT ON COLUMN resources.fileName IS 'Original file name';
COMMENT ON COLUMN resources.fileSize IS 'File size in bytes';
COMMENT ON COLUMN resources.fileType IS 'File type: pdf, mp4, docx, etc.';
COMMENT ON COLUMN resources.uploadedAt IS 'Upload timestamp';
COMMENT ON COLUMN resources.isPublic IS 'Whether resource is public or private';
COMMENT ON COLUMN resources.tags IS 'Array of tags for categorization';
COMMENT ON COLUMN resources.downloadCount IS 'Number of times downloaded';
COMMENT ON COLUMN resources.viewCount IS 'Number of times viewed';

-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'resources';

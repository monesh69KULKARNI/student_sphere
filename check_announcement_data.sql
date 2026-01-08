-- Check actual announcement data and structure
-- Run this in Supabase SQL Editor

-- Check table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'announcements' 
ORDER BY ordinal_position;

-- Check actual data with field names
SELECT 
  id, 
  title, 
  content, 
  author_id, 
  author_name, 
  created_at, 
  updated_at, 
  is_public, 
  target_audience, 
  read_by, 
  priority, 
  attachment_url
FROM announcements 
LIMIT 3;

-- Check if there are any null values in required fields
SELECT 
  COUNT(*) as total_rows,
  COUNT(id) as has_id,
  COUNT(title) as has_title,
  COUNT(content) as has_content,
  COUNT(author_id) as has_author_id,
  COUNT(author_name) as has_author_name,
  COUNT(created_at) as has_created_at
FROM announcements;

-- Sample data with all field types
SELECT 
  id::text,
  title::text,
  content::text,
  author_id::text,
  author_name::text,
  created_at::text,
  updated_at::text,
  is_public::text,
  target_audience::text,
  read_by::text,
  priority::text,
  attachment_url::text
FROM announcements 
LIMIT 1;

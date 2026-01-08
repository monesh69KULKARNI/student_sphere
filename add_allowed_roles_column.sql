-- Migration: Add allowed_roles column to events table
-- Run this SQL in your Supabase SQL Editor

-- Add the allowed_roles column to the events table
ALTER TABLE events 
ADD COLUMN allowed_roles TEXT[] DEFAULT ARRAY['student', 'faculty', 'admin'];

-- Update existing events to have default allowed roles
UPDATE events 
SET allowed_roles = ARRAY['student', 'faculty', 'admin'] 
WHERE allowed_roles IS NULL;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_events_allowed_roles ON events USING GIN (allowed_roles);

-- Update the RLS policies to include the new column (if needed)
-- The existing policies should still work as they don't reference allowed_roles

-- Verify the column was added successfully
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'events' AND column_name = 'allowed_roles';

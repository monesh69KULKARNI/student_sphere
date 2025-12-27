-- StudentSphere Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (stores user profile data, auth handled by Firebase)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  uid TEXT UNIQUE NOT NULL, -- Firebase Auth UID
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'faculty', 'admin', 'guest')),
  student_id TEXT,
  department TEXT,
  year TEXT,
  phone TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  additional_data JSONB
);

-- Events table
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  location TEXT NOT NULL,
  organizer_id TEXT NOT NULL, -- Firebase UID
  organizer_name TEXT NOT NULL,
  max_participants INTEGER NOT NULL DEFAULT 50,
  registered_participants TEXT[] DEFAULT '{}',
  volunteers TEXT[] DEFAULT '{}',
  requires_volunteers BOOLEAN DEFAULT FALSE,
  max_volunteers INTEGER DEFAULT 0,
  image_url TEXT,
  is_public BOOLEAN DEFAULT TRUE,
  category TEXT DEFAULT 'general',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Announcements table
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

-- Resources table
CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('notes', 'videos', 'pdfs', 'slides', 'other')),
  subject TEXT NOT NULL,
  course TEXT NOT NULL,
  uploader_id TEXT NOT NULL, -- Firebase UID
  uploader_name TEXT NOT NULL,
  file_url TEXT NOT NULL, -- Supabase Storage URL
  file_name TEXT NOT NULL,
  file_size INTEGER NOT NULL, -- in bytes
  file_type TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  is_public BOOLEAN DEFAULT TRUE,
  tags TEXT[] DEFAULT '{}',
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0
);

-- Achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('academic', 'sports', 'cultural', 'leadership', 'volunteer')),
  student_id TEXT NOT NULL, -- Firebase UID
  student_name TEXT NOT NULL,
  awarded_by TEXT NOT NULL,
  awarded_by_id TEXT NOT NULL, -- Firebase UID
  awarded_at TIMESTAMPTZ DEFAULT NOW(),
  certificate_url TEXT,
  image_url TEXT,
  level TEXT DEFAULT 'college' CHECK (level IN ('college', 'state', 'national', 'international')),
  is_verified BOOLEAN DEFAULT FALSE
);

-- Careers table
CREATE TABLE IF NOT EXISTS careers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('internship', 'job', 'workshop', 'seminar')),
  company TEXT NOT NULL,
  location TEXT,
  salary TEXT,
  duration TEXT,
  posted_at TIMESTAMPTZ DEFAULT NOW(),
  deadline TIMESTAMPTZ,
  posted_by TEXT NOT NULL,
  posted_by_id TEXT NOT NULL, -- Firebase UID
  requirements TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  application_link TEXT,
  contact_email TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  view_count INTEGER DEFAULT 0,
  application_count INTEGER DEFAULT 0
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_uid ON users(uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
CREATE INDEX IF NOT EXISTS idx_events_is_public ON events(is_public);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at);
CREATE INDEX IF NOT EXISTS idx_announcements_is_public ON announcements(is_public);
CREATE INDEX IF NOT EXISTS idx_resources_category ON resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_subject ON resources(subject);
CREATE INDEX IF NOT EXISTS idx_achievements_student_id ON achievements(student_id);
CREATE INDEX IF NOT EXISTS idx_careers_type ON careers(type);
CREATE INDEX IF NOT EXISTS idx_careers_is_active ON careers(is_active);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE careers ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users: Users can read all, update own profile, admins can do everything
CREATE POLICY "Users can read all profiles"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid()::text = uid);

CREATE POLICY "Admins can manage all users"
  ON users FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role = 'admin'
    )
  );

-- Events: Public events visible to all, private to authenticated
CREATE POLICY "Public events visible to all"
  ON events FOR SELECT
  USING (is_public = true);

CREATE POLICY "Authenticated users can view private events"
  ON events FOR SELECT
  USING (auth.role() = 'authenticated' AND is_public = false);

CREATE POLICY "Faculty and admins can create events"
  ON events FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
    )
  );

CREATE POLICY "Organizers and admins can update events"
  ON events FOR UPDATE
  USING (
    organizer_id = auth.uid()::text OR
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete events"
  ON events FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role = 'admin'
    )
  );

-- Announcements: Public visible to all
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

-- Resources: Public resources visible to all
CREATE POLICY "Public resources visible to all"
  ON resources FOR SELECT
  USING (is_public = true);

CREATE POLICY "Faculty and admins can upload resources"
  ON resources FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
    )
  );

-- Achievements: Authenticated users can view
CREATE POLICY "Authenticated users can view achievements"
  ON achievements FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Faculty and admins can create achievements"
  ON achievements FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
    )
  );

-- Careers: Active careers visible to all
CREATE POLICY "Active careers visible to all"
  ON careers FOR SELECT
  USING (is_active = true);

CREATE POLICY "Faculty and admins can post careers"
  ON careers FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE uid = auth.uid()::text AND role IN ('faculty', 'admin')
    )
  );

-- Note: Firebase Auth UID is passed as text, so we use auth.uid()::text
-- Make sure to set up Firebase JWT in Supabase for proper authentication


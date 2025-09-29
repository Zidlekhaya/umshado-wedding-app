-- ============================================
-- MINIMAL MIGRATION - STEP BY STEP APPROACH
-- ============================================
-- This script creates only the essential core tables first

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create types safely
DO $$ 
BEGIN
    -- Only create types if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('owner', 'co_owner', 'viewer');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guest_side') THEN
        CREATE TYPE guest_side AS ENUM ('Bride', 'Groom', 'Both');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rsvp_status') THEN
        CREATE TYPE rsvp_status AS ENUM ('Pending', 'Yes', 'No', 'Maybe');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('Todo', 'InProgress', 'Done');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority') THEN
        CREATE TYPE task_priority AS ENUM ('Low', 'Medium', 'High');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vendor_status') THEN
        CREATE TYPE vendor_status AS ENUM ('Shortlisted', 'Contacted', 'Confirmed', 'Rejected');
    END IF;
END $$;

-- ============================================
-- STEP 1: CREATE BASE TABLES ONLY
-- ============================================

-- 1. app_user table (no dependencies except auth.users)
CREATE TABLE IF NOT EXISTS app_user (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. wedding table (depends only on app_user)
CREATE TABLE IF NOT EXISTS wedding (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'My Wedding',
  name_bride TEXT,
  name_groom TEXT,
  date DATE,
  location TEXT,
  culture TEXT,
  ceremony_location TEXT,
  reception_location TEXT,
  city TEXT,
  cover_image_url TEXT,
  slug TEXT UNIQUE NOT NULL DEFAULT 'wedding-' || extract(epoch from now())::text,
  notes TEXT,
  colors JSONB DEFAULT '{"primary": "#00a86b", "secondary": "#FF6B35"}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 3. vendor_profiles table (depends only on auth.users)
CREATE TABLE IF NOT EXISTS vendor_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL DEFAULT 'My Business',
  business_description TEXT DEFAULT 'Professional wedding services',
  category TEXT NOT NULL DEFAULT 'other',
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  website TEXT,
  city TEXT DEFAULT 'Cape Town',
  location TEXT DEFAULT 'Cape Town',
  company_logo TEXT,
  gallery_images TEXT[] DEFAULT '{}',
  services TEXT[] DEFAULT '{}',
  price_range TEXT,
  availability TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,
  rating_average DECIMAL(3,2) DEFAULT 0.0,
  rating_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  inquiry_count INTEGER DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Add basic indexes
CREATE INDEX IF NOT EXISTS idx_wedding_owner ON wedding(owner_id);
CREATE INDEX IF NOT EXISTS idx_wedding_slug ON wedding(slug);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_user ON vendor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_active ON vendor_profiles(is_active);

-- Enable RLS
ALTER TABLE app_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedding ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;

-- Create basic policies
DROP POLICY IF EXISTS "Users can view their own profile" ON app_user;
CREATE POLICY "Users can view their own profile" ON app_user FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON app_user;
CREATE POLICY "Users can update their own profile" ON app_user FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON app_user;
CREATE POLICY "Users can insert their own profile" ON app_user FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can create weddings" ON wedding;
CREATE POLICY "Users can create weddings" ON wedding FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can view their weddings" ON wedding;
CREATE POLICY "Users can view their weddings" ON wedding FOR SELECT USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their weddings" ON wedding;
CREATE POLICY "Users can update their weddings" ON wedding FOR UPDATE USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Vendors can manage their profile" ON vendor_profiles;
CREATE POLICY "Vendors can manage their profile" ON vendor_profiles FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Anyone can view active vendors" ON vendor_profiles;
CREATE POLICY "Anyone can view active vendors" ON vendor_profiles FOR SELECT USING (is_active = TRUE);

-- Create basic triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_wedding_updated_at ON wedding;
CREATE TRIGGER update_wedding_updated_at BEFORE UPDATE ON wedding FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_vendor_profiles_updated_at ON vendor_profiles;
CREATE TRIGGER update_vendor_profiles_updated_at BEFORE UPDATE ON vendor_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create app_user trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO app_user (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Vendor profile auto-creation trigger  
CREATE OR REPLACE FUNCTION handle_vendor_signup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_user_meta_data->>'user_type' = 'vendor' THEN
    INSERT INTO vendor_profiles (
      user_id, 
      business_name, 
      category, 
      contact_email
    ) VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'business_name', 'My Business'),
      COALESCE(NEW.raw_user_meta_data->>'category', 'other'),
      NEW.email
    ) ON CONFLICT (user_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_vendor_signup ON auth.users;
CREATE TRIGGER on_vendor_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_vendor_signup();

-- Success message
RAISE NOTICE 'Core tables created successfully! You can now test your app basic functionality.';
RAISE NOTICE 'Run the next migration script for additional features.';


-- ============================================
-- UMSHADO MASTER MIGRATION SCRIPT
-- ============================================
-- This script contains all necessary migrations in the correct order
-- Run this in your Supabase SQL Editor after setting up your .env file

-- ============================================
-- STEP 1: CORE DATABASE SCHEMA
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('owner', 'co_owner', 'viewer');
CREATE TYPE guest_side AS ENUM ('Bride', 'Groom', 'Both');
CREATE TYPE rsvp_status AS ENUM ('Pending', 'Yes', 'No', 'Maybe');
CREATE TYPE task_status AS ENUM ('Todo', 'InProgress', 'Done');
CREATE TYPE task_priority AS ENUM ('Low', 'Medium', 'High');
CREATE TYPE vendor_status AS ENUM ('Shortlisted', 'Contacted', 'Confirmed', 'Rejected');

-- 1. Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS app_user (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Weddings table
CREATE TABLE IF NOT EXISTS wedding (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_bride TEXT,
  name_groom TEXT,
  date DATE,
  location TEXT,
  culture TEXT,
  ceremony_location TEXT,
  reception_location TEXT,
  city TEXT,
  cover_image_url TEXT,
  slug TEXT UNIQUE NOT NULL,
  notes TEXT,
  colors JSONB DEFAULT '{"primary": "#00a86b", "secondary": "#FF6B35"}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 3. Wedding co-owners (many-to-many)
CREATE TABLE IF NOT EXISTS wedding_co_owner (
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  user_id UUID REFERENCES app_user(id) ON DELETE CASCADE,
  role user_role DEFAULT 'co_owner',
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (wedding_id, user_id)
);

-- 4. Guests table
CREATE TABLE IF NOT EXISTS guest (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  side guest_side DEFAULT 'Both',
  party_size INT DEFAULT 1 CHECK (party_size > 0),
  dietary TEXT,
  table_name TEXT,
  tags TEXT[],
  rsvp_status rsvp_status DEFAULT 'Pending',
  invite_code TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Tasks table (Enhanced)
CREATE TABLE IF NOT EXISTS task (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status task_status DEFAULT 'Todo',
  priority task_priority DEFAULT 'Medium',
  category TEXT,
  due_date DATE,
  reminder_date DATE,
  assignee_id UUID REFERENCES app_user(id),
  notes TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Vendors table
CREATE TABLE IF NOT EXISTS vendor (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  quote_amount NUMERIC(12,2),
  status vendor_status DEFAULT 'Shortlisted',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Budget items table
CREATE TABLE IF NOT EXISTS budget_item (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT,
  estimated NUMERIC(12,2) DEFAULT 0,
  actual NUMERIC(12,2) DEFAULT 0,
  paid NUMERIC(12,2) DEFAULT 0,
  due_date DATE,
  vendor_id UUID REFERENCES vendor(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Timeline events table
CREATE TABLE IF NOT EXISTS timeline_event (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  starts_at TIMESTAMPTZ NOT NULL,
  title TEXT NOT NULL,
  location TEXT,
  responsible_user_id UUID REFERENCES app_user(id),
  notes TEXT,
  order_index INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 9. Wedding invites table
CREATE TABLE IF NOT EXISTS wedding_invites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT CHECK (role IN ('guest', 'partner', 'planner')) DEFAULT 'guest',
  status TEXT CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')) DEFAULT 'pending',
  token TEXT UNIQUE,
  invited_by UUID REFERENCES app_user(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(wedding_id, email)
);

-- ============================================
-- STEP 2: VENDOR PROFILES & MARKETPLACE
-- ============================================

-- Vendor profiles table
CREATE TABLE IF NOT EXISTS vendor_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  business_description TEXT,
  category TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  website TEXT,
  city TEXT,
  location TEXT,
  company_logo TEXT,
  gallery_images TEXT[],
  services TEXT[],
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

-- Vendor packages table
CREATE TABLE IF NOT EXISTS vendor_packages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_profile_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2),
  duration_hours INTEGER,
  includes TEXT[],
  excludes TEXT[],
  terms_conditions TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Vendor inquiries table
CREATE TABLE IF NOT EXISTS vendor_inquiries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_profile_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  couple_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  package_id UUID REFERENCES vendor_packages(id) ON DELETE SET NULL,
  message TEXT NOT NULL,
  couple_name TEXT,
  couple_email TEXT,
  couple_phone TEXT,
  wedding_date DATE,
  wedding_location TEXT,
  budget_range TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'responded', 'closed')),
  vendor_response TEXT,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- STEP 3: MESSAGING SYSTEM
-- ============================================

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  couple_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vendor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vendor_name TEXT NOT NULL,
  vendor_avatar TEXT,
  couple_name TEXT NOT NULL,
  couple_avatar TEXT,
  last_message TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE,
  unread_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(couple_id, vendor_id)
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('couple', 'vendor')),
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Push notifications tokens table
CREATE TABLE IF NOT EXISTS push_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, token)
);

-- ============================================
-- STEP 4: CREATE INDEXES
-- ============================================

-- Core indexes
CREATE INDEX IF NOT EXISTS idx_wedding_slug ON wedding(slug);
CREATE INDEX IF NOT EXISTS idx_wedding_owner ON wedding(owner_id);
CREATE INDEX IF NOT EXISTS idx_wedding_deleted ON wedding(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_guest_wedding ON guest(wedding_id);
CREATE INDEX IF NOT EXISTS idx_guest_rsvp ON guest(rsvp_status);
CREATE INDEX IF NOT EXISTS idx_guest_side ON guest(side);
CREATE INDEX IF NOT EXISTS idx_task_wedding ON task(wedding_id);
CREATE INDEX IF NOT EXISTS idx_task_status ON task(status);
CREATE INDEX IF NOT EXISTS idx_task_due_date ON task(due_date);
CREATE INDEX IF NOT EXISTS idx_vendor_wedding ON vendor(wedding_id);
CREATE INDEX IF NOT EXISTS idx_vendor_category ON vendor(category);
CREATE INDEX IF NOT EXISTS idx_budget_wedding ON budget_item(wedding_id);
CREATE INDEX IF NOT EXISTS idx_timeline_wedding ON timeline_event(wedding_id);
CREATE INDEX IF NOT EXISTS idx_timeline_starts_at ON timeline_event(starts_at);
CREATE INDEX IF NOT EXISTS idx_invites_wedding ON wedding_invites(wedding_id);
CREATE INDEX IF NOT EXISTS idx_invites_token ON wedding_invites(token);

-- Vendor marketplace indexes
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_category ON vendor_profiles(category);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_city ON vendor_profiles(city);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_active ON vendor_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_vendor_packages_vendor ON vendor_packages(vendor_profile_id);
CREATE INDEX IF NOT EXISTS idx_vendor_inquiries_vendor ON vendor_inquiries(vendor_profile_id);
CREATE INDEX IF NOT EXISTS idx_vendor_inquiries_couple ON vendor_inquiries(couple_id);

-- Messaging indexes
CREATE INDEX IF NOT EXISTS idx_conversations_couple_id ON conversations(couple_id);
CREATE INDEX IF NOT EXISTS idx_conversations_vendor_id ON conversations(vendor_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- ============================================
-- STEP 5: CREATE TRIGGERS & FUNCTIONS
-- ============================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_wedding_updated_at BEFORE UPDATE ON wedding FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_guest_updated_at BEFORE UPDATE ON guest FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_task_updated_at BEFORE UPDATE ON task FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendor_updated_at BEFORE UPDATE ON vendor FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budget_item_updated_at BEFORE UPDATE ON budget_item FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_timeline_event_updated_at BEFORE UPDATE ON timeline_event FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wedding_invites_updated_at BEFORE UPDATE ON wedding_invites FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendor_profiles_updated_at BEFORE UPDATE ON vendor_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendor_packages_updated_at BEFORE UPDATE ON vendor_packages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vendor_inquiries_updated_at BEFORE UPDATE ON vendor_inquiries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Messaging triggers
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations 
  SET 
    last_message = NEW.content,
    last_message_at = NEW.created_at,
    updated_at = NOW(),
    unread_count = CASE 
      WHEN NEW.sender_type = 'couple' THEN unread_count + 1
      ELSE unread_count
    END
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_conversation_on_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_on_message();

-- Wedding slug generation
CREATE OR REPLACE FUNCTION generate_wedding_slug()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := lower(replace(concat(COALESCE(NEW.name, ''), '-', COALESCE(NEW.name_bride, ''), '-', COALESCE(NEW.name_groom, ''), '-', extract(year from COALESCE(NEW.date, CURRENT_DATE))), ' ', '-'));
    -- Ensure uniqueness
    WHILE EXISTS (SELECT 1 FROM wedding WHERE slug = NEW.slug AND id != NEW.id) LOOP
      NEW.slug := NEW.slug || '-' || extract(epoch from now())::text;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_wedding_slug_trigger
  BEFORE INSERT OR UPDATE ON wedding
  FOR EACH ROW
  EXECUTE FUNCTION generate_wedding_slug();

-- Auto-create app_user on auth signup
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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Vendor profile trigger
CREATE OR REPLACE FUNCTION handle_vendor_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user type is vendor
  IF NEW.raw_user_meta_data->>'user_type' = 'vendor' THEN
    INSERT INTO vendor_profiles (
      user_id, 
      business_name, 
      business_description,
      category, 
      contact_email,
      city,
      location
    ) VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'business_name', 'My Business'),
      'Professional wedding services',
      COALESCE(NEW.raw_user_meta_data->>'category', 'other'),
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'location', 'Cape Town'),
      COALESCE(NEW.raw_user_meta_data->>'location', 'Cape Town')
    ) ON CONFLICT (user_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_vendor_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_vendor_signup();

-- ============================================
-- STEP 6: ENABLE ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE app_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedding ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedding_co_owner ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest ENABLE ROW LEVEL SECURITY;
ALTER TABLE task ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedding_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 7: CREATE RLS POLICIES
-- ============================================

-- App User policies
CREATE POLICY "Users can view their own profile" ON app_user FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON app_user FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile" ON app_user FOR INSERT WITH CHECK (auth.uid() = id);

-- Wedding policies
CREATE POLICY "Users can view weddings they own or co-own" ON wedding FOR SELECT USING (
  owner_id = auth.uid() OR 
  id IN (SELECT wedding_id FROM wedding_co_owner WHERE user_id = auth.uid())
);
CREATE POLICY "Users can create weddings" ON wedding FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Owners can update their weddings" ON wedding FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "Owners can delete their weddings" ON wedding FOR DELETE USING (owner_id = auth.uid());

-- Guest policies
CREATE POLICY "Users can manage guests of their weddings" ON guest FOR ALL USING (
  wedding_id IN (
    SELECT id FROM wedding WHERE owner_id = auth.uid()
    UNION
    SELECT wedding_id FROM wedding_co_owner WHERE user_id = auth.uid()
  )
);

-- Task policies
CREATE POLICY "Users can manage tasks of their weddings" ON task FOR ALL USING (
  wedding_id IN (
    SELECT id FROM wedding WHERE owner_id = auth.uid()
    UNION
    SELECT wedding_id FROM wedding_co_owner WHERE user_id = auth.uid()
  )
);

-- Budget policies
CREATE POLICY "Users can manage budget items of their weddings" ON budget_item FOR ALL USING (
  wedding_id IN (
    SELECT id FROM wedding WHERE owner_id = auth.uid()
    UNION
    SELECT wedding_id FROM wedding_co_owner WHERE user_id = auth.uid()
  )
);

-- Vendor marketplace policies
CREATE POLICY "Anyone can view active vendor profiles" ON vendor_profiles FOR SELECT USING (is_active = TRUE);
CREATE POLICY "Vendors can manage their own profile" ON vendor_profiles FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Anyone can view active packages" ON vendor_packages FOR SELECT USING (
  vendor_profile_id IN (SELECT id FROM vendor_profiles WHERE is_active = TRUE)
);
CREATE POLICY "Vendors can manage their own packages" ON vendor_packages FOR ALL USING (
  vendor_profile_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
);

CREATE POLICY "Vendors can view inquiries to them" ON vendor_inquiries FOR SELECT USING (
  vendor_profile_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
);
CREATE POLICY "Couples can view their own inquiries" ON vendor_inquiries FOR SELECT USING (couple_id = auth.uid());
CREATE POLICY "Anyone can create inquiries" ON vendor_inquiries FOR INSERT WITH CHECK (couple_id = auth.uid());
CREATE POLICY "Vendors can update inquiries to them" ON vendor_inquiries FOR UPDATE USING (
  vendor_profile_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
);

-- Messaging policies
CREATE POLICY "Users can view their own conversations" ON conversations FOR SELECT USING (
  auth.uid() = couple_id OR auth.uid() = vendor_id
);
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT WITH CHECK (
  auth.uid() = couple_id OR auth.uid() = vendor_id
);
CREATE POLICY "Users can update their own conversations" ON conversations FOR UPDATE USING (
  auth.uid() = couple_id OR auth.uid() = vendor_id
);

CREATE POLICY "Users can view messages in their conversations" ON messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = conversation_id 
    AND (couple_id = auth.uid() OR vendor_id = auth.uid())
  )
);
CREATE POLICY "Users can send messages in their conversations" ON messages FOR INSERT WITH CHECK (
  sender_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = conversation_id 
    AND (couple_id = auth.uid() OR vendor_id = auth.uid())
  )
);

-- Push tokens policies
CREATE POLICY "Users can manage their own push tokens" ON push_tokens FOR ALL USING (user_id = auth.uid());

-- ============================================
-- STEP 8: ENABLE REALTIME
-- ============================================

-- Enable realtime for messaging
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Insert success message
DO $$
BEGIN
    RAISE NOTICE 'Umshado database migration completed successfully!';
    RAISE NOTICE 'All tables, indexes, triggers, and RLS policies have been created.';
    RAISE NOTICE 'Your app is now ready to use all features.';
END
$$;


-- ============================================
-- COMPATIBILITY MIGRATION
-- ============================================
-- This works with your existing database schema

-- Enable extensions (safe to run multiple times)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 1: CREATE MISSING TYPES SAFELY
-- ============================================

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
-- STEP 2: CREATE MISSING CORE TABLES
-- ============================================

-- Create app_user if it doesn't exist (works with existing weddings table)
CREATE TABLE IF NOT EXISTS app_user (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create guests table (references existing weddings table)
CREATE TABLE IF NOT EXISTS guests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
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

-- Create tasks table (references existing weddings table)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
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

-- Create vendors table (references existing weddings table)  
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
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

-- Create budget_items table (references existing weddings and vendors)
CREATE TABLE IF NOT EXISTS budget_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT,
  estimated NUMERIC(12,2) DEFAULT 0,
  actual NUMERIC(12,2) DEFAULT 0,
  paid NUMERIC(12,2) DEFAULT 0,
  due_date DATE,
  vendor_id UUID REFERENCES vendors(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create timeline_events table (references existing weddings table)
CREATE TABLE IF NOT EXISTS timeline_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  starts_at TIMESTAMPTZ NOT NULL,
  title TEXT NOT NULL,
  location TEXT,
  responsible_user_id UUID REFERENCES app_user(id),
  notes TEXT,
  order_index INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- STEP 3: ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================

-- Add columns to existing weddings table if they don't exist
DO $$
BEGIN
    -- Add name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='name') THEN
        ALTER TABLE weddings ADD COLUMN name TEXT DEFAULT 'My Wedding';
    END IF;
    
    -- Add colors column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='colors') THEN
        ALTER TABLE weddings ADD COLUMN colors JSONB DEFAULT '{"primary": "#00a86b", "secondary": "#FF6B35"}';
    END IF;
    
    -- Add slug column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='slug') THEN
        ALTER TABLE weddings ADD COLUMN slug TEXT;
        -- Generate slugs for existing records
        UPDATE weddings SET slug = 'wedding-' || id WHERE slug IS NULL;
        -- Make slug unique
        ALTER TABLE weddings ADD CONSTRAINT weddings_slug_unique UNIQUE (slug);
    END IF;
END $$;

-- ============================================
-- STEP 4: CREATE ESSENTIAL INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_guests_wedding_id ON guests(wedding_id);
CREATE INDEX IF NOT EXISTS idx_guests_rsvp_status ON guests(rsvp_status);
CREATE INDEX IF NOT EXISTS idx_tasks_wedding_id ON tasks(wedding_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_vendors_wedding_id ON vendors(wedding_id);
CREATE INDEX IF NOT EXISTS idx_budget_items_wedding_id ON budget_items(wedding_id);
CREATE INDEX IF NOT EXISTS idx_timeline_events_wedding_id ON timeline_events(wedding_id);

-- ============================================
-- STEP 5: ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE app_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 6: CREATE ESSENTIAL RLS POLICIES
-- ============================================

-- App User policies
DROP POLICY IF EXISTS "Users can view their own profile" ON app_user;
CREATE POLICY "Users can view their own profile" ON app_user FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON app_user;
CREATE POLICY "Users can update their own profile" ON app_user FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON app_user;
CREATE POLICY "Users can insert their own profile" ON app_user FOR INSERT WITH CHECK (auth.uid() = id);

-- Guest policies (assuming weddings table has owner_id column)
DROP POLICY IF EXISTS "Users can manage guests of their weddings" ON guests;
CREATE POLICY "Users can manage guests of their weddings" ON guests FOR ALL USING (
  wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
);

-- Task policies
DROP POLICY IF EXISTS "Users can manage tasks of their weddings" ON tasks;
CREATE POLICY "Users can manage tasks of their weddings" ON tasks FOR ALL USING (
  wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
);

-- Vendor policies
DROP POLICY IF EXISTS "Users can manage vendors of their weddings" ON vendors;
CREATE POLICY "Users can manage vendors of their weddings" ON vendors FOR ALL USING (
  wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
);

-- Budget policies
DROP POLICY IF EXISTS "Users can manage budget items of their weddings" ON budget_items;
CREATE POLICY "Users can manage budget items of their weddings" ON budget_items FOR ALL USING (
  wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
);

-- Timeline policies
DROP POLICY IF EXISTS "Users can manage timeline events of their weddings" ON timeline_events;
CREATE POLICY "Users can manage timeline events of their weddings" ON timeline_events FOR ALL USING (
  wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
);

-- ============================================
-- STEP 7: CREATE ESSENTIAL TRIGGERS
-- ============================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to new tables
DROP TRIGGER IF EXISTS update_guests_updated_at ON guests;
CREATE TRIGGER update_guests_updated_at BEFORE UPDATE ON guests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_vendors_updated_at ON vendors;
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_budget_items_updated_at ON budget_items;
CREATE TRIGGER update_budget_items_updated_at BEFORE UPDATE ON budget_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_timeline_events_updated_at ON timeline_events;
CREATE TRIGGER update_timeline_events_updated_at BEFORE UPDATE ON timeline_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE 'Compatibility migration completed successfully!';
    RAISE NOTICE 'Core wedding features (guests, tasks, vendors, budget, timeline) are now available.';
    RAISE NOTICE 'Your existing vendor and messaging tables are preserved.';
END $$;

-- ============================================
-- SMART MIGRATION - ONLY CREATE MISSING TABLES
-- ============================================
-- This script only creates tables that don't exist yet

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create types safely
DO $$ 
BEGIN
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
-- CREATE TABLES ONLY IF THEY DON'T EXIST
-- ============================================

-- Create app_user table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_user') THEN
        CREATE TABLE app_user (
          id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
          email TEXT UNIQUE NOT NULL,
          full_name TEXT,
          avatar_url TEXT,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );
        RAISE NOTICE 'Created app_user table';
    ELSE
        RAISE NOTICE 'app_user table already exists, skipping';
    END IF;
END $$;

-- Create tasks table if it doesn't exist (note: not "task" since that might conflict)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') THEN
        CREATE TABLE tasks (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          description TEXT,
          status task_status DEFAULT 'Todo',
          priority task_priority DEFAULT 'Medium',
          category TEXT,
          due_date DATE,
          reminder_date DATE,
          assignee_id UUID REFERENCES auth.users(id),
          notes TEXT,
          completed_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );
        RAISE NOTICE 'Created tasks table';
    ELSE
        RAISE NOTICE 'tasks table already exists, skipping';
    END IF;
END $$;

-- Create vendors table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors') THEN
        CREATE TABLE vendors (
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
        RAISE NOTICE 'Created vendors table';
    ELSE
        RAISE NOTICE 'vendors table already exists, skipping';
    END IF;
END $$;

-- Create budget_items table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items') THEN
        -- First check if vendors table exists (for the foreign key)
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors') THEN
            CREATE TABLE budget_items (
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
        ELSE
            -- Create without vendor foreign key if vendors table doesn't exist
            CREATE TABLE budget_items (
              id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
              wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
              title TEXT NOT NULL,
              category TEXT,
              estimated NUMERIC(12,2) DEFAULT 0,
              actual NUMERIC(12,2) DEFAULT 0,
              paid NUMERIC(12,2) DEFAULT 0,
              due_date DATE,
              vendor_id UUID,
              notes TEXT,
              created_at TIMESTAMPTZ DEFAULT now(),
              updated_at TIMESTAMPTZ DEFAULT now()
            );
        END IF;
        RAISE NOTICE 'Created budget_items table';
    ELSE
        RAISE NOTICE 'budget_items table already exists, skipping';
    END IF;
END $$;

-- Create timeline_events table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events') THEN
        CREATE TABLE timeline_events (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
          starts_at TIMESTAMPTZ NOT NULL,
          title TEXT NOT NULL,
          location TEXT,
          responsible_user_id UUID REFERENCES auth.users(id),
          notes TEXT,
          order_index INT DEFAULT 0,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );
        RAISE NOTICE 'Created timeline_events table';
    ELSE
        RAISE NOTICE 'timeline_events table already exists, skipping';
    END IF;
END $$;

-- ============================================
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================

-- Add missing columns to weddings table
DO $$
BEGIN
    -- Add name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='name') THEN
        ALTER TABLE weddings ADD COLUMN name TEXT DEFAULT 'My Wedding';
        RAISE NOTICE 'Added name column to weddings table';
    END IF;
    
    -- Add colors column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='colors') THEN
        ALTER TABLE weddings ADD COLUMN colors JSONB DEFAULT '{"primary": "#00a86b", "secondary": "#FF6B35"}';
        RAISE NOTICE 'Added colors column to weddings table';
    END IF;
    
    -- Add slug column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='slug') THEN
        ALTER TABLE weddings ADD COLUMN slug TEXT;
        -- Generate slugs for existing records
        UPDATE weddings SET slug = 'wedding-' || id WHERE slug IS NULL;
        -- Make slug unique (but handle conflicts)
        BEGIN
            ALTER TABLE weddings ADD CONSTRAINT weddings_slug_unique UNIQUE (slug);
        EXCEPTION WHEN duplicate_object THEN
            RAISE NOTICE 'Unique constraint on slug already exists';
        END;
        RAISE NOTICE 'Added slug column to weddings table';
    END IF;
END $$;

-- ============================================
-- CREATE INDEXES SAFELY
-- ============================================

-- Create indexes only if they don't exist
DO $$
BEGIN
    -- Tasks indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') THEN
        CREATE INDEX IF NOT EXISTS idx_tasks_wedding_id ON tasks(wedding_id);
        CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
        CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
    END IF;
    
    -- Vendors indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors') THEN
        CREATE INDEX IF NOT EXISTS idx_vendors_wedding_id ON vendors(wedding_id);
        CREATE INDEX IF NOT EXISTS idx_vendors_category ON vendors(category);
    END IF;
    
    -- Budget items indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items') THEN
        CREATE INDEX IF NOT EXISTS idx_budget_items_wedding_id ON budget_items(wedding_id);
    END IF;
    
    -- Timeline events indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events') THEN
        CREATE INDEX IF NOT EXISTS idx_timeline_events_wedding_id ON timeline_events(wedding_id);
        CREATE INDEX IF NOT EXISTS idx_timeline_events_starts_at ON timeline_events(starts_at);
    END IF;
    
    RAISE NOTICE 'Created indexes successfully';
END $$;

-- ============================================
-- ENABLE RLS SAFELY
-- ============================================

DO $$
BEGIN
    -- Enable RLS on new tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_user') THEN
        ALTER TABLE app_user ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') THEN
        ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors') THEN
        ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items') THEN
        ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events') THEN
        ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;
    END IF;
    
    RAISE NOTICE 'Enabled RLS on new tables';
END $$;

-- ============================================
-- CREATE ESSENTIAL POLICIES SAFELY
-- ============================================

-- App User policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_user') THEN
        DROP POLICY IF EXISTS "Users can view their own profile" ON app_user;
        CREATE POLICY "Users can view their own profile" ON app_user FOR SELECT USING (auth.uid() = id);
        
        DROP POLICY IF EXISTS "Users can update their own profile" ON app_user;
        CREATE POLICY "Users can update their own profile" ON app_user FOR UPDATE USING (auth.uid() = id);
        
        DROP POLICY IF EXISTS "Users can insert their own profile" ON app_user;
        CREATE POLICY "Users can insert their own profile" ON app_user FOR INSERT WITH CHECK (auth.uid() = id);
        
        RAISE NOTICE 'Created app_user policies';
    END IF;
END $$;

-- Tasks policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') THEN
        DROP POLICY IF EXISTS "Users can manage tasks of their weddings" ON tasks;
        CREATE POLICY "Users can manage tasks of their weddings" ON tasks FOR ALL USING (
          wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
        );
        RAISE NOTICE 'Created tasks policies';
    END IF;
END $$;

-- Vendors policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors') THEN
        DROP POLICY IF EXISTS "Users can manage vendors of their weddings" ON vendors;
        CREATE POLICY "Users can manage vendors of their weddings" ON vendors FOR ALL USING (
          wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
        );
        RAISE NOTICE 'Created vendors policies';
    END IF;
END $$;

-- Budget policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items') THEN
        DROP POLICY IF EXISTS "Users can manage budget items of their weddings" ON budget_items;
        CREATE POLICY "Users can manage budget items of their weddings" ON budget_items FOR ALL USING (
          wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
        );
        RAISE NOTICE 'Created budget_items policies';
    END IF;
END $$;

-- Timeline policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events') THEN
        DROP POLICY IF EXISTS "Users can manage timeline events of their weddings" ON timeline_events;
        CREATE POLICY "Users can manage timeline events of their weddings" ON timeline_events FOR ALL USING (
          wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
        );
        RAISE NOTICE 'Created timeline_events policies';
    END IF;
END $$;

-- ============================================
-- CREATE TRIGGERS SAFELY
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
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') THEN
        DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
        CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors') THEN
        DROP TRIGGER IF EXISTS update_vendors_updated_at ON vendors;
        CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items') THEN
        DROP TRIGGER IF EXISTS update_budget_items_updated_at ON budget_items;
        CREATE TRIGGER update_budget_items_updated_at BEFORE UPDATE ON budget_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events') THEN
        DROP TRIGGER IF EXISTS update_timeline_events_updated_at ON timeline_events;
        CREATE TRIGGER update_timeline_events_updated_at BEFORE UPDATE ON timeline_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    RAISE NOTICE 'Created update triggers';
END $$;

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
EXCEPTION WHEN others THEN
  -- If app_user table doesn't exist, just return NEW
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
    RAISE NOTICE 'Smart migration completed successfully!';
    RAISE NOTICE 'Created only missing tables and preserved existing ones.';
    RAISE NOTICE 'Core wedding features are now available: tasks, vendors, budget, timeline.';
END $$;


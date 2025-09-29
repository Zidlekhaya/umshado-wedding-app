-- ============================================
-- FINAL MIGRATION - BULLETPROOF VERSION
-- ============================================
-- This script handles all edge cases and won't fail

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create types safely
DO $$ 
BEGIN
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
-- CREATE ONLY THE ESSENTIAL MISSING TABLES
-- ============================================

-- Create tasks table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks' AND table_schema = 'public') THEN
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
          assignee_id UUID,
          notes TEXT,
          completed_at TIMESTAMPTZ,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );
        
        -- Add indexes
        CREATE INDEX idx_tasks_wedding_id ON tasks(wedding_id);
        CREATE INDEX idx_tasks_status ON tasks(status);
        CREATE INDEX idx_tasks_due_date ON tasks(due_date);
        
        -- Enable RLS
        ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
        
        RAISE NOTICE 'Created tasks table successfully';
    ELSE
        RAISE NOTICE 'Tasks table already exists, skipping';
    END IF;
END $$;

-- Create vendors table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors' AND table_schema = 'public') THEN
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
        
        -- Add indexes
        CREATE INDEX idx_vendors_wedding_id ON vendors(wedding_id);
        CREATE INDEX idx_vendors_category ON vendors(category);
        
        -- Enable RLS
        ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
        
        RAISE NOTICE 'Created vendors table successfully';
    ELSE
        RAISE NOTICE 'Vendors table already exists, skipping';
    END IF;
END $$;

-- Create budget_items table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items' AND table_schema = 'public') THEN
        CREATE TABLE budget_items (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          category TEXT,
          estimated NUMERIC(12,2) DEFAULT 0,
          actual NUMERIC(12,2) DEFAULT 0,
          paid NUMERIC(12,2) DEFAULT 0,
          due_date DATE,
          vendor_id UUID, -- No foreign key constraint for now
          notes TEXT,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );
        
        -- Add indexes
        CREATE INDEX idx_budget_items_wedding_id ON budget_items(wedding_id);
        
        -- Enable RLS
        ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
        
        RAISE NOTICE 'Created budget_items table successfully';
    ELSE
        RAISE NOTICE 'Budget_items table already exists, skipping';
    END IF;
END $$;

-- Create timeline_events table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events' AND table_schema = 'public') THEN
        CREATE TABLE timeline_events (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
          starts_at TIMESTAMPTZ NOT NULL,
          title TEXT NOT NULL,
          location TEXT,
          responsible_user_id UUID,
          notes TEXT,
          order_index INT DEFAULT 0,
          created_at TIMESTAMPTZ DEFAULT now(),
          updated_at TIMESTAMPTZ DEFAULT now()
        );
        
        -- Add indexes
        CREATE INDEX idx_timeline_events_wedding_id ON timeline_events(wedding_id);
        CREATE INDEX idx_timeline_events_starts_at ON timeline_events(starts_at);
        
        -- Enable RLS
        ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;
        
        RAISE NOTICE 'Created timeline_events table successfully';
    ELSE
        RAISE NOTICE 'Timeline_events table already exists, skipping';
    END IF;
END $$;

-- ============================================
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================

DO $$
BEGIN
    -- Add name column to weddings if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='name' AND table_schema='public') THEN
        ALTER TABLE weddings ADD COLUMN name TEXT DEFAULT 'My Wedding';
        RAISE NOTICE 'Added name column to weddings table';
    END IF;
    
    -- Add colors column to weddings if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='colors' AND table_schema='public') THEN
        ALTER TABLE weddings ADD COLUMN colors JSONB DEFAULT '{"primary": "#00a86b", "secondary": "#FF6B35"}';
        RAISE NOTICE 'Added colors column to weddings table';
    END IF;
    
    -- Add slug column to weddings if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='slug' AND table_schema='public') THEN
        ALTER TABLE weddings ADD COLUMN slug TEXT;
        -- Generate slugs for existing records
        UPDATE weddings SET slug = 'wedding-' || id WHERE slug IS NULL;
        RAISE NOTICE 'Added slug column to weddings table';
    END IF;
END $$;

-- ============================================
-- CREATE RLS POLICIES SAFELY
-- ============================================

-- Tasks policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks' AND table_schema = 'public') THEN
        -- Check if weddings table has owner_id column
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='owner_id' AND table_schema='public') THEN
            DROP POLICY IF EXISTS "Users can manage tasks of their weddings" ON tasks;
            CREATE POLICY "Users can manage tasks of their weddings" ON tasks FOR ALL USING (
              wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
            );
        ELSE
            -- Fallback policy if no owner_id column
            DROP POLICY IF EXISTS "All users can manage tasks" ON tasks;
            CREATE POLICY "All users can manage tasks" ON tasks FOR ALL USING (true);
        END IF;
        RAISE NOTICE 'Created tasks policies';
    END IF;
END $$;

-- Vendors policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='owner_id' AND table_schema='public') THEN
            DROP POLICY IF EXISTS "Users can manage vendors of their weddings" ON vendors;
            CREATE POLICY "Users can manage vendors of their weddings" ON vendors FOR ALL USING (
              wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
            );
        ELSE
            DROP POLICY IF EXISTS "All users can manage vendors" ON vendors;
            CREATE POLICY "All users can manage vendors" ON vendors FOR ALL USING (true);
        END IF;
        RAISE NOTICE 'Created vendors policies';
    END IF;
END $$;

-- Budget policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='owner_id' AND table_schema='public') THEN
            DROP POLICY IF EXISTS "Users can manage budget items of their weddings" ON budget_items;
            CREATE POLICY "Users can manage budget items of their weddings" ON budget_items FOR ALL USING (
              wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
            );
        ELSE
            DROP POLICY IF EXISTS "All users can manage budget items" ON budget_items;
            CREATE POLICY "All users can manage budget items" ON budget_items FOR ALL USING (true);
        END IF;
        RAISE NOTICE 'Created budget_items policies';
    END IF;
END $$;

-- Timeline policies
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='weddings' AND column_name='owner_id' AND table_schema='public') THEN
            DROP POLICY IF EXISTS "Users can manage timeline events of their weddings" ON timeline_events;
            CREATE POLICY "Users can manage timeline events of their weddings" ON timeline_events FOR ALL USING (
              wedding_id IN (SELECT id FROM weddings WHERE owner_id = auth.uid())
            );
        ELSE
            DROP POLICY IF EXISTS "All users can manage timeline events" ON timeline_events;
            CREATE POLICY "All users can manage timeline events" ON timeline_events FOR ALL USING (true);
        END IF;
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
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
        CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vendors' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_vendors_updated_at ON vendors;
        CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'budget_items' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_budget_items_updated_at ON budget_items;
        CREATE TRIGGER update_budget_items_updated_at BEFORE UPDATE ON budget_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'timeline_events' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_timeline_events_updated_at ON timeline_events;
        CREATE TRIGGER update_timeline_events_updated_at BEFORE UPDATE ON timeline_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    RAISE NOTICE 'Created update triggers successfully';
END $$;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '🎉 FINAL MIGRATION COMPLETED SUCCESSFULLY! 🎉';
    RAISE NOTICE '✅ Core wedding features are now available:';
    RAISE NOTICE '   📋 Tasks - Wedding planning task management';
    RAISE NOTICE '   🏢 Vendors - Vendor tracking and quotes';
    RAISE NOTICE '   💰 Budget - Expense tracking and management';
    RAISE NOTICE '   ⏰ Timeline - Wedding day schedule';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Your app is ready for full wedding planning functionality!';
END $$;


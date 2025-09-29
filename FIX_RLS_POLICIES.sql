-- ============================================
-- FIX RLS POLICIES - REMOVE INFINITE RECURSION
-- ============================================

-- First, disable RLS temporarily on problematic tables
ALTER TABLE vendors DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events DISABLE ROW LEVEL SECURITY;

-- Drop all problematic policies
DROP POLICY IF EXISTS "Users can manage vendors of their weddings" ON vendors;
DROP POLICY IF EXISTS "All users can manage vendors" ON vendors;
DROP POLICY IF EXISTS "Users can manage tasks of their weddings" ON tasks;
DROP POLICY IF EXISTS "All users can manage tasks" ON tasks;
DROP POLICY IF EXISTS "Users can manage budget items of their weddings" ON budget_items;
DROP POLICY IF EXISTS "All users can manage budget items" ON budget_items;
DROP POLICY IF EXISTS "Users can manage timeline events of their weddings" ON timeline_events;
DROP POLICY IF EXISTS "All users can manage timeline events" ON timeline_events;

-- Re-enable RLS
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;

-- Create simple, non-recursive policies
-- For now, allow all authenticated users to access these tables
-- We can make them more restrictive later once we have proper owner tracking

-- Vendors policies (simple)
CREATE POLICY "Authenticated users can manage vendors" ON vendors FOR ALL USING (auth.role() = 'authenticated');

-- Tasks policies (simple)
CREATE POLICY "Authenticated users can manage tasks" ON tasks FOR ALL USING (auth.role() = 'authenticated');

-- Budget policies (simple)
CREATE POLICY "Authenticated users can manage budget items" ON budget_items FOR ALL USING (auth.role() = 'authenticated');

-- Timeline policies (simple)
CREATE POLICY "Authenticated users can manage timeline events" ON timeline_events FOR ALL USING (auth.role() = 'authenticated');

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Fixed RLS policies - infinite recursion removed';
    RAISE NOTICE '✅ Vendors tab should now work properly';
    RAISE NOTICE 'ℹ️ Policies are now permissive - all authenticated users can access tables';
END $$;


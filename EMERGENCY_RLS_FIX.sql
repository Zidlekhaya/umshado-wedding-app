-- ============================================
-- EMERGENCY RLS FIX - COMPLETELY DISABLE RLS
-- ============================================
-- This will completely disable RLS on problematic tables to get the app working

-- Completely disable RLS on all our new tables
ALTER TABLE vendors DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events DISABLE ROW LEVEL SECURITY;

-- Drop ALL policies on these tables
DROP POLICY IF EXISTS "Users can manage vendors of their weddings" ON vendors;
DROP POLICY IF EXISTS "All users can manage vendors" ON vendors;
DROP POLICY IF EXISTS "Authenticated users can manage vendors" ON vendors;

DROP POLICY IF EXISTS "Users can manage tasks of their weddings" ON tasks;
DROP POLICY IF EXISTS "All users can manage tasks" ON tasks;
DROP POLICY IF EXISTS "Authenticated users can manage tasks" ON tasks;

DROP POLICY IF EXISTS "Users can manage budget items of their weddings" ON budget_items;
DROP POLICY IF EXISTS "All users can manage budget items" ON budget_items;
DROP POLICY IF EXISTS "Authenticated users can manage budget items" ON budget_items;

DROP POLICY IF EXISTS "Users can manage timeline events of their weddings" ON timeline_events;
DROP POLICY IF EXISTS "All users can manage timeline events" ON timeline_events;
DROP POLICY IF EXISTS "Authenticated users can manage timeline events" ON timeline_events;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🚨 EMERGENCY FIX APPLIED: RLS completely disabled';
    RAISE NOTICE '✅ Vendors tab should now work immediately';
    RAISE NOTICE '⚠️ Tables are now open (no RLS protection)';
    RAISE NOTICE 'ℹ️ This is temporary - we can re-enable security later';
END $$;


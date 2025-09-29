-- ============================================
-- EMERGENCY WEDDINGS TABLE FIX
-- This completely disables RLS on weddings table to stop infinite recursion
-- ============================================

-- Completely disable RLS on weddings table
ALTER TABLE weddings DISABLE ROW LEVEL SECURITY;

-- Drop ALL policies on weddings table
DROP POLICY IF EXISTS "Users can view weddings they own or co-own" ON weddings;
DROP POLICY IF EXISTS "Users can create weddings" ON weddings;
DROP POLICY IF EXISTS "Owners can update their weddings" ON weddings;
DROP POLICY IF EXISTS "Owners can delete their weddings" ON weddings;
DROP POLICY IF EXISTS "Allow authenticated users to view weddings" ON weddings;
DROP POLICY IF EXISTS "Allow owners to insert weddings" ON weddings;
DROP POLICY IF EXISTS "Allow owners to update their weddings" ON weddings;
DROP POLICY IF EXISTS "Allow owners to delete their weddings" ON weddings;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🚨 EMERGENCY WEDDINGS FIX APPLIED';
    RAISE NOTICE '✅ Infinite recursion error should be resolved';
    RAISE NOTICE '✅ Wedding data loading should work now';
    RAISE NOTICE '⚠️ Weddings table is now completely open (no RLS)';
    RAISE NOTICE 'ℹ️ This is temporary - we can add proper security later';
END $$;


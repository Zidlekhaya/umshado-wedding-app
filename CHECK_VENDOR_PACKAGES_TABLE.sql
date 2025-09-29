-- Check vendor packages table structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('vendor_packages', 'packages')
ORDER BY table_name, ordinal_position;

-- Also check if the tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('vendor_packages', 'packages')
  AND table_schema = 'public';


-- Check current conversation data to see if SQL fixes were applied

-- First, let's see what's in the conversations table
SELECT 
  id,
  couple_id,
  vendor_id,
  couple_name,
  vendor_name,
  created_at
FROM conversations 
ORDER BY created_at DESC 
LIMIT 5;

-- Check if vendor_name matches business_name from vendor_profiles
SELECT 
  c.id as conversation_id,
  c.vendor_name as conversation_vendor_name,
  vp.business_name as actual_business_name,
  c.couple_name,
  CASE 
    WHEN c.vendor_name = vp.business_name THEN '✅ CORRECT' 
    ELSE '❌ NEEDS UPDATE' 
  END as vendor_name_status
FROM conversations c
LEFT JOIN vendor_profiles vp ON c.vendor_id = vp.user_id
ORDER BY c.created_at DESC;




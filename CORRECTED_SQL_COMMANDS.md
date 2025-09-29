# 🔧 CORRECTED SQL Commands (Without wedding_id)

The error shows your `conversations` table doesn't have a `wedding_id` column. Here are the corrected SQL commands:

## 📝 **Step 1: Fix Existing Conversations (CORRECTED)**

```sql
-- Fix existing conversations to show proper business names and couple names

-- Update vendor_name to use business_name from vendor_profiles
UPDATE conversations 
SET vendor_name = vp.business_name
FROM vendor_profiles vp
WHERE conversations.vendor_id = vp.user_id
AND conversations.vendor_name != vp.business_name;

-- Since no wedding_id column exists, we'll try to get couple names from auth.users metadata
UPDATE conversations 
SET couple_name = COALESCE(
  (au.raw_user_meta_data->>'partner1_name')::text || ' & ' || (au.raw_user_meta_data->>'partner2_name')::text,
  COALESCE((au.raw_user_meta_data->>'full_name')::text, 'Wedding Couple')
)
FROM auth.users au
WHERE conversations.couple_id = au.id
AND (conversations.couple_name = 'Couple' OR conversations.couple_name IS NULL);
```

## 📝 **Step 2: Fix Function (CORRECTED)**

```sql
-- Fix the get_or_create_conversation function (without wedding_id references)

-- Drop the old function
DROP FUNCTION IF EXISTS get_or_create_conversation(UUID, TEXT, UUID, TEXT, TEXT);

-- Create updated function without wedding_id references
CREATE OR REPLACE FUNCTION get_or_create_conversation(
  p_wedding_id UUID,
  p_wedding_name TEXT,
  p_vendor_user_id UUID,
  p_vendor_name TEXT,
  p_vendor_avatar TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  conversation_id UUID;
  actual_vendor_name TEXT;
  actual_couple_name TEXT;
BEGIN
  -- Get actual vendor business name from vendor_profiles
  SELECT business_name INTO actual_vendor_name
  FROM vendor_profiles
  WHERE user_id = p_vendor_user_id;
  
  -- If vendor profile not found, fall back to provided name
  IF actual_vendor_name IS NULL THEN
    actual_vendor_name := p_vendor_name;
  END IF;
  
  -- Use the provided wedding name as couple name
  actual_couple_name := p_wedding_name;
  
  -- Try to find existing conversation (without wedding_id)
  SELECT id INTO conversation_id
  FROM conversations
  WHERE vendor_id = p_vendor_user_id 
  AND couple_id = auth.uid();
  
  -- If not found, create new conversation
  IF conversation_id IS NULL THEN
    INSERT INTO conversations (
      couple_id,
      vendor_id,
      couple_name,
      vendor_name,
      vendor_avatar
    ) VALUES (
      auth.uid(),
      p_vendor_user_id,
      actual_couple_name,
      actual_vendor_name,
      p_vendor_avatar
    )
    RETURNING id INTO conversation_id;
  ELSE
    -- Update existing conversation with correct names
    UPDATE conversations 
    SET 
      couple_name = actual_couple_name,
      vendor_name = actual_vendor_name,
      vendor_avatar = COALESCE(p_vendor_avatar, vendor_avatar)
    WHERE id = conversation_id;
  END IF;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_or_create_conversation TO authenticated;
```

---

## ⚠️ **Key Changes Made:**
1. **Removed all `wedding_id` references** - your table doesn't have this column
2. **Simplified couple name logic** - uses provided wedding name or auth metadata
3. **Fixed conversation lookup** - uses `couple_id` and `vendor_id` only

## 🧪 **Run These Instead:**
Copy and run these corrected SQL commands in your Supabase SQL Editor!




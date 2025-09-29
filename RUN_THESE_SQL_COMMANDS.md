# 🔧 SQL Commands to Fix Chat Header Names

## Problem
The chat headers are showing:
- **Vendor name**: `"Ubuhle@gmail.com"` instead of `"Ubuhle Makeup"`
- **Couple name**: `"Couple"` instead of actual wedding couple names

## Solution
Run these SQL commands in your **Supabase Dashboard → SQL Editor**:

---

### 1️⃣ First, fix existing conversation names:

```sql
-- Fix existing conversations to show proper business names and couple names

-- Update vendor_name to use business_name from vendor_profiles
UPDATE conversations 
SET vendor_name = vp.business_name
FROM vendor_profiles vp
WHERE conversations.vendor_id = vp.user_id
AND conversations.vendor_name != vp.business_name;

-- Update couple_name to use actual wedding names from weddings table
UPDATE conversations 
SET couple_name = CONCAT(w.partner1_name, ' & ', w.partner2_name)
FROM weddings w
WHERE conversations.wedding_id = w.id
AND (conversations.couple_name = 'Couple' OR conversations.couple_name IS NULL);

-- If no wedding found, try to get names from auth.users metadata
UPDATE conversations 
SET couple_name = COALESCE(
  (au.raw_user_meta_data->>'partner1_name')::text || ' & ' || (au.raw_user_meta_data->>'partner2_name')::text,
  COALESCE((au.raw_user_meta_data->>'full_name')::text, 'Wedding Couple')
)
FROM auth.users au
WHERE conversations.couple_id = au.id
AND (conversations.couple_name = 'Couple' OR conversations.couple_name IS NULL);
```

---

### 2️⃣ Then, fix the function for future conversations:

```sql
-- Fix the get_or_create_conversation function to use correct column names

-- Drop the old function
DROP FUNCTION IF EXISTS get_or_create_conversation(UUID, TEXT, UUID, TEXT, TEXT);

-- Create updated function with correct column names and improved name resolution
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
  
  -- Get actual couple name from weddings table
  SELECT CONCAT(partner1_name, ' & ', partner2_name) INTO actual_couple_name
  FROM weddings
  WHERE id = p_wedding_id;
  
  -- If wedding not found, use provided name
  IF actual_couple_name IS NULL OR actual_couple_name = ' & ' THEN
    actual_couple_name := p_wedding_name;
  END IF;
  
  -- Try to find existing conversation
  SELECT id INTO conversation_id
  FROM conversations
  WHERE wedding_id = p_wedding_id AND vendor_id = p_vendor_user_id;
  
  -- If not found, create new conversation
  IF conversation_id IS NULL THEN
    INSERT INTO conversations (
      couple_id,
      vendor_id,
      wedding_id,
      couple_name,
      vendor_name,
      vendor_avatar
    ) VALUES (
      auth.uid(),
      p_vendor_user_id,
      p_wedding_id,
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

## 🧪 How to Test:

1. **Run both SQL commands** in Supabase Dashboard
2. **Reload your app** (press `r` in terminal)
3. **Open the chat** as vendor
4. **Header should now show**: The actual couple/wedding name
5. **Test from couple side**: Should show "Ubuhle Makeup" instead of email

## ✅ Expected Results:
- **Vendor side header**: "Mthabisi & Thabi" (or actual wedding couple names)
- **Couple side header**: "Ubuhle Makeup" (business name, not email)

---

*After running these SQL commands, the chat headers should display the correct names on both sides!*




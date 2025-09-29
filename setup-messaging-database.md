# Quick Database Setup for Messaging

## The Issue
The error "Failed to start conversation" with "PGRST2..." means the messaging tables don't exist in your Supabase database yet.

## Solution: Apply the Migration Manually

Since you don't have Docker running locally, you need to apply the migration directly in Supabase:

### Step 1: Open Supabase Dashboard
1. Go to [https://supabase.com](https://supabase.com)
2. Sign in and select your uMshado project
3. Go to **SQL Editor** (left sidebar)

### Step 2: Create Messaging Tables
Copy and paste this entire SQL script into the SQL Editor and run it:

```sql
-- Create messaging system tables for uMshado
-- This migration creates the complete messaging system with conversations and messages

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  couple_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vendor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wedding_id UUID REFERENCES wedding(id) ON DELETE CASCADE,
  wedding_name TEXT NOT NULL,
  vendor_name TEXT NOT NULL,
  vendor_avatar TEXT,
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure unique conversations between wedding and vendor
  UNIQUE(wedding_id, vendor_user_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_avatar TEXT,
  message_text TEXT,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  image_url TEXT,
  file_url TEXT,
  file_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_couple ON conversations(couple_user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_vendor ON conversations(vendor_user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_wedding ON conversations(wedding_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);

-- Create function to update conversation timestamp
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations 
  SET 
    updated_at = NOW(),
    last_message = CASE 
      WHEN NEW.message_text IS NOT NULL THEN NEW.message_text
      WHEN NEW.file_name IS NOT NULL THEN '📎 ' || NEW.file_name
      WHEN NEW.image_url IS NOT NULL THEN '📷 Photo'
      ELSE 'Message'
    END,
    last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update conversation when message is added
DROP TRIGGER IF EXISTS update_conversation_on_message ON messages;
CREATE TRIGGER update_conversation_on_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_timestamp();

-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Couples can create conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON messages;

-- RLS Policies for conversations
-- Users can read conversations they are part of
CREATE POLICY "Users can view their conversations" ON conversations
  FOR SELECT USING (
    auth.uid() = couple_user_id OR 
    auth.uid() = vendor_user_id
  );

-- Users can create conversations (couples initiate with vendors)
CREATE POLICY "Couples can create conversations" ON conversations
  FOR INSERT WITH CHECK (
    auth.uid() = couple_user_id
  );

-- Users can update conversations they are part of
CREATE POLICY "Users can update their conversations" ON conversations
  FOR UPDATE USING (
    auth.uid() = couple_user_id OR 
    auth.uid() = vendor_user_id
  );

-- RLS Policies for messages
-- Users can read messages in conversations they are part of
CREATE POLICY "Users can view messages in their conversations" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversations 
      WHERE conversations.id = messages.conversation_id 
      AND (conversations.couple_user_id = auth.uid() OR conversations.vendor_user_id = auth.uid())
    )
  );

-- Users can create messages in conversations they are part of
CREATE POLICY "Users can send messages in their conversations" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM conversations 
      WHERE conversations.id = messages.conversation_id 
      AND (conversations.couple_user_id = auth.uid() OR conversations.vendor_user_id = auth.uid())
    )
  );

-- Grant permissions
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create helper function to get or create conversation
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
BEGIN
  -- Try to find existing conversation
  SELECT id INTO conversation_id
  FROM conversations
  WHERE wedding_id = p_wedding_id AND vendor_user_id = p_vendor_user_id;
  
  -- If not found, create new conversation
  IF conversation_id IS NULL THEN
    INSERT INTO conversations (
      couple_user_id,
      vendor_user_id,
      wedding_id,
      wedding_name,
      vendor_name,
      vendor_avatar
    ) VALUES (
      auth.uid(),
      p_vendor_user_id,
      p_wedding_id,
      p_wedding_name,
      p_vendor_name,
      p_vendor_avatar
    )
    RETURNING id INTO conversation_id;
  END IF;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_or_create_conversation TO authenticated;
```

### Step 3: Create Storage Bucket
After running the above, run this second script for file storage:

```sql
-- Create storage bucket for chat files
-- Insert the chat-files bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-files',
  'chat-files',
  true,
  10485760, -- 10MB limit
  array['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain']
)
ON CONFLICT (id) DO NOTHING;
```

### Step 4: Set Up Storage Policies
Go to **Storage** → **chat-files** bucket → **Policies** and create these policies:

**Policy 1: "Users can view chat files"**
```sql
((bucket_id = 'chat-files'::text) AND (auth.uid() IN ( SELECT
    CASE
        WHEN (c.couple_user_id = auth.uid()) THEN auth.uid()
        WHEN (c.vendor_user_id = auth.uid()) THEN auth.uid()
        ELSE NULL::uuid
    END AS "case"
   FROM conversations c
  WHERE (((storage.foldername(objects.name))[1])::uuid = c.id))))
```

**Policy 2: "Users can upload chat files"**
```sql
((bucket_id = 'chat-files'::text) AND (auth.uid() IN ( SELECT
    CASE
        WHEN (c.couple_user_id = auth.uid()) THEN auth.uid()
        WHEN (c.vendor_user_id = auth.uid()) THEN auth.uid()
        ELSE NULL::uuid
    END AS "case"
   FROM conversations c
  WHERE (((storage.foldername(objects.name))[1])::uuid = c.id))))
```

### Step 5: Test the System
1. Reload your app (press `r` in terminal)
2. Try tapping a message button on a vendor card
3. The conversation should now be created successfully!

## Troubleshooting
If you still get errors:
1. Check that your `wedding` table exists
2. Verify you have an active wedding in your wedding store
3. Make sure you're signed in as a couple (not vendor)
4. Check the Supabase logs for detailed error messages

The messaging system should work perfectly once these tables are created!




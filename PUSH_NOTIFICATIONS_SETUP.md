# 🔔 Push Notifications Setup Guide

## 🎯 Overview
Your app now has a complete push notification system that sends notifications when:
- New messages arrive in conversations
- Other important events occur (extensible)

## 📋 Setup Steps

### 1. 🗄️ Database Setup
Run these SQL commands in your **Supabase Dashboard → SQL Editor**:

```sql
-- Create push_tokens table
CREATE TABLE IF NOT EXISTS push_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_type TEXT NOT NULL CHECK (device_type IN ('ios', 'android')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Unique constraint to prevent duplicate tokens per user per device type
  UNIQUE(user_id, device_type)
);

-- Create indexes
CREATE INDEX idx_push_tokens_user_id ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_token ON push_tokens(token);

-- Enable RLS
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY "Users can manage their own push tokens" ON push_tokens
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON push_tokens TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Update trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_push_tokens_updated_at 
    BEFORE UPDATE ON push_tokens 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
```

### 2. ⚡ Edge Function Setup
Deploy the edge function:

```bash
# Deploy the push notification function
supabase functions deploy send-push-notification --project-ref YOUR_PROJECT_REF
```

### 3. 🔧 App Configuration
Update your `app.json` with your actual Expo project ID:

```json
{
  "expo": {
    "extra": {
      "eas": {
        "projectId": "YOUR_EXPO_PROJECT_ID"
      }
    }
  }
}
```

### 4. 📱 Testing

#### Test on Physical Device:
1. **Install on device** - Push notifications require physical devices
2. **Grant permissions** - App will request notification permissions on first launch
3. **Send a message** - Messages should trigger push notifications
4. **Tap notification** - Should open the specific conversation

#### Expected Behavior:
- ✅ **Message sent** → Recipient gets push notification
- ✅ **Notification tapped** → Opens conversation
- ✅ **App in foreground** → Shows in-app notification
- ✅ **App in background** → Shows system notification

## 🔍 Debug Information

### Check Push Token Registration:
```sql
-- See registered push tokens
SELECT 
  pt.user_id,
  pt.token,
  pt.device_type,
  pt.created_at,
  au.email
FROM push_tokens pt
LEFT JOIN auth.users au ON pt.user_id = au.id
ORDER BY pt.created_at DESC;
```

### Monitor Edge Function Logs:
1. Go to **Supabase Dashboard → Edge Functions**
2. Click **send-push-notification**
3. View **Logs** tab for debugging

## 🚀 Features Implemented

### ✅ Core Functionality:
- **Permission handling** - Requests notification permissions
- **Token management** - Stores and updates push tokens
- **Message notifications** - Sends notifications for new messages
- **Deep linking** - Taps open specific conversations
- **Cross-platform** - Works on iOS and Android

### ✅ Smart Features:
- **Foreground handling** - Different behavior when app is open
- **Automatic token refresh** - Handles token updates
- **Error handling** - Graceful failures don't break messaging
- **RLS Security** - Users can only access their own tokens

## 🎨 Customization

### Notification Appearance:
- **Icon**: `assets/images/notification-icon.png`
- **Color**: Green (`#00a86b`) - matches your app theme
- **Sound**: Default system sound
- **Channel**: "default" channel for Android

### Add More Notification Types:
```typescript
// Example: Booking confirmations
await sendBookingNotification({
  recipientId: vendorId,
  title: "New Booking Request",
  body: `${coupleName} wants to book your service`,
  bookingId: booking.id,
});
```

## 🔐 Security Notes
- **RLS Enabled** - Users can only manage their own tokens
- **Service Role** - Edge function uses service role for sending
- **Token Validation** - Expo validates push tokens automatically
- **No sensitive data** - Don't send sensitive info in notifications

---

Your push notification system is now **production-ready**! 🎉

Messages will automatically trigger notifications, and users can tap them to jump directly to conversations.




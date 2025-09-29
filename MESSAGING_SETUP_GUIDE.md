# uMshado Messaging System Setup Guide

## Overview

This implementation provides a complete real-time messaging system for uMshado using Supabase and React Native Gifted Chat. Couples can message vendors directly from the marketplace, and vendors have a dedicated inbox to manage all conversations.

## Features

✅ **Real-time messaging** with Supabase real-time subscriptions  
✅ **File & image attachments** via Supabase Storage  
✅ **WhatsApp-like UI** using react-native-gifted-chat  
✅ **Wedding name display** (e.g., "Message from John & Jane")  
✅ **Vendor inbox** showing all customer conversations  
✅ **Message buttons** on vendor cards and package details  
✅ **Row-level security** protecting conversations  
✅ **Deep linking** to specific conversations  

## Architecture

### Database Schema
- `conversations` - Links couples and vendors with wedding context
- `messages` - Individual messages with support for text, images, and files
- RLS policies ensure users only see their own conversations

### Components
- `ChatScreen` - Main messaging interface using Gifted Chat
- `VendorInbox` - Vendor conversation list
- `CoupleMessages` - Couple conversation list  
- `chat-service` - Supabase integration utilities
- `useMessages` - React hook for real-time message subscriptions

## Setup Instructions

### 1. Database Migration

Run the messaging migration to create tables and policies:

```sql
-- Apply this migration in Supabase SQL Editor
-- File: supabase/migrations/020_create_messaging_system.sql
```

### 2. Storage Setup

Create the chat-files bucket for file uploads:

```sql
-- Apply this in Supabase SQL Editor  
-- File: supabase/storage/chat-files-bucket.sql
```

### 3. Environment Variables

No additional environment variables needed - uses existing Supabase config.

### 4. Dependencies

Already installed via the implementation:
- `react-native-gifted-chat` - Chat UI
- `expo-image-picker` - Image attachments
- `expo-document-picker` - File attachments  
- `dayjs` - Date formatting
- `uuid` - Unique IDs

## Usage

### For Couples

1. **Start Conversation:**
   - Browse marketplace → Tap message icon on vendor card
   - Or view package details → Tap "Message Vendor" button
   - Creates conversation and opens chat

2. **View Conversations:**
   - Go to Messages tab → See all vendor conversations
   - Tap conversation → Open chat interface

3. **Send Messages:**
   - Type text messages with emoji support
   - Tap + to attach images or files
   - Messages appear instantly via real-time sync

### For Vendors

1. **View Inbox:**
   - Go to vendor Messages screen → See all customer conversations
   - Shows wedding name (e.g., "John & Jane Wedding")
   - Displays last message and timestamp

2. **Respond to Customers:**
   - Tap conversation → Open chat interface  
   - Send text, images, or files
   - Real-time delivery to customer

## File Attachments

### Supported Types
- **Images:** JPEG, PNG, GIF, WebP (10MB max)
- **Documents:** PDF, Word docs, plain text (10MB max)

### Storage
- Files uploaded to `chat-files` bucket in Supabase Storage
- Organized by conversation ID
- Public URLs for easy access
- RLS policies restrict access to conversation participants

## Security

### Row Level Security (RLS)
- Users can only see conversations they participate in
- Messages restricted to conversation participants
- File access limited to conversation members

### Data Protection
- All messages encrypted in transit (HTTPS)
- Supabase handles data encryption at rest
- No sensitive data stored in client code

## Performance

### Real-time Updates
- Supabase real-time subscriptions for instant message delivery
- Efficient queries with proper database indexes
- Pagination support for long conversation history

### File Handling
- Direct upload to Supabase Storage (no server proxy)
- Compressed images for faster transmission
- Async upload with loading indicators

## Testing

### Manual Test Cases

1. **Couple Flow:**
   ```
   ✅ Tap message button on vendor card → Opens chat
   ✅ Send text message → Appears instantly
   ✅ Attach image → Uploads and displays
   ✅ Attach document → Shows as clickable link
   ✅ Navigate to Messages tab → See conversation list
   ```

2. **Vendor Flow:**
   ```
   ✅ Open vendor Messages → See customer conversations
   ✅ Conversation shows wedding name → "John & Jane Wedding"  
   ✅ Open conversation → See message history
   ✅ Reply to customer → Message delivered instantly
   ✅ Receive new message → Updates in real-time
   ```

3. **Cross-Platform:**
   ```
   ✅ Message from iOS → Received on Android
   ✅ File attachments work both directions
   ✅ Real-time sync across devices
   ```

## Troubleshooting

### Common Issues

**Migration Errors:**
- Ensure `wedding` table exists before running messaging migration
- Check RLS policies are enabled on auth.users table

**File Upload Failures:**
- Verify storage bucket `chat-files` exists and is public
- Check file size under 10MB limit
- Ensure proper RLS policies on storage.objects

**Real-time Not Working:**
- Verify Supabase real-time is enabled in project settings
- Check subscription cleanup in useEffect returns

**Messages Not Sending:**
- Verify user authentication state
- Check conversation exists and user has access
- Validate RLS policies allow message insertion

### Debug Tools

```javascript
// Check current user
const { data } = await supabase.auth.getSession();
console.log('Current user:', data.session?.user);

// Test conversation access  
const { data: convs } = await supabase
  .from('conversations')
  .select('*');
console.log('Accessible conversations:', convs);

// Check real-time subscription
const channel = supabase.channel('test');
console.log('Channel state:', channel.state);
```

## Production Considerations

### Scaling
- Add database indexes for large message volumes
- Implement message archiving for old conversations  
- Consider CDN for file attachments

### Push Notifications
- Add Supabase Edge Function trigger on new messages
- Integrate with Expo Push Notifications
- Send notifications when app is backgrounded

### Analytics
- Track message volume and engagement
- Monitor file upload patterns
- Measure conversation conversion rates

### Content Moderation
- Add message filtering for inappropriate content
- Implement user reporting system
- Store conversation audit logs

## Support

For issues with this messaging implementation:

1. Check this guide for common solutions
2. Review Supabase logs for database errors
3. Test in Supabase SQL Editor for permissions issues
4. Verify file upload limits and bucket configuration

The implementation follows Supabase best practices and React Native patterns for maintainable, scalable messaging.




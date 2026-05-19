# GearShare Chat System - Implementation Guide

## Overview
The chat system allows users to communicate with each other directly within the GearShare app. Users can message each other about equipment rentals and other matters.

## Database Setup

### Step 1: Create Tables in Supabase

1. Open your Supabase project dashboard
2. Navigate to the **SQL Editor**
3. Create a new query
4. Copy all the SQL from `CHAT_SETUP.sql` in the root directory
5. Execute the SQL to create the tables and set up RLS policies

### Tables Created

#### `chats` Table
Stores conversation metadata between two users.

**Columns:**
- `id` (TEXT, PRIMARY KEY): Unique identifier for the chat
- `user1_id` (UUID): First user's ID
- `user2_id` (UUID): Second user's ID
- `user1_name` (TEXT): First user's display name
- `user2_name` (TEXT): Second user's display name
- `user1_avatar` (TEXT): First user's avatar URL
- `user2_avatar` (TEXT): Second user's avatar URL
- `last_message` (TEXT): Preview of the last message
- `last_message_time` (TIMESTAMP): When the last message was sent
- `unread_count` (INT): Number of unread messages
- `created_at` (TIMESTAMP): When the chat was created
- `updated_at` (TIMESTAMP): Last update timestamp

#### `messages` Table
Stores individual messages in conversations.

**Columns:**
- `id` (TEXT, PRIMARY KEY): Unique message identifier
- `chat_id` (TEXT): Reference to the chat
- `sender_id` (UUID): Who sent the message
- `sender_name` (TEXT): Sender's display name
- `sender_avatar` (TEXT): Sender's avatar URL
- `content` (TEXT): Message content
- `created_at` (TIMESTAMP): When the message was sent
- `is_read` (BOOLEAN): Whether the message has been read

### Security

RLS (Row Level Security) policies are automatically set up to ensure:
- Users can only view their own chats
- Users can only see messages from chats they're part of
- Users can only send messages to chats they're part of

## Features

### 1. Chat Page
- View all your conversations
- See the last message and timestamp
- Unread message indicators
- Easy navigation to individual chats

**Access:** From the main dashboard in the "Messages" tab

### 2. Chat Detail Page
- Full conversation thread
- Real-time message updates
- Send messages
- See message sender and timestamp
- Different styling for your messages vs. others

### 3. Auto Chat Creation
- Chats are automatically created when needed
- No manual setup required
- System stores user information automatically

## Usage

### Starting a Chat

From the Equipment Details page or user profile:
1. Tap the "Message" button
2. A chat will be created automatically if it doesn't exist
3. The Chat Detail page will open
4. Type your message and tap send

### Sending Messages

In a chat conversation:
1. Tap the message input field at the bottom
2. Type your message
3. Tap the send button (paper airplane icon)
4. Message appears immediately and is sent to the database

### Viewing Messages

Messages are displayed in chronological order:
- Your messages appear on the right in purple (0xFFBB86FC)
- Other user's messages appear on the left in gray
- Timestamps show when each message was sent
- Unread messages are displayed differently

## Integration Points

### ChatService Methods

```dart
// Get or create a chat
Future<Chat> getOrCreateChat({
  required String user1Id,
  required String user2Id,
  required String user1Name,
  required String user2Name,
  required String user1Avatar,
  required String user2Avatar,
})

// Get all user chats
Future<List<Chat>> getUserChats(String userId)

// Send a message
Future<Message> sendMessage({
  required String chatId,
  required String senderId,
  required String senderName,
  required String senderAvatar,
  required String content,
})

// Get chat messages
Future<List<Message>> getChatMessages(String chatId, {int limit = 50, int offset = 0})

// Mark message as read
Future<void> markMessageAsRead(String messageId)

// Subscribe to real-time messages
Stream<List<Message>> subscribeToMessages(String chatId)

// Delete a chat
Future<void> deleteChat(String chatId)
```

## File Structure

```
lib/
├── models/
│   ├── chat.dart          # Chat model
│   └── message.dart       # Message model
├── services/
│   └── chat_service.dart  # Chat service logic
└── pages/
    ├── chat_page.dart           # Chat list page
    └── chat_detail_page.dart    # Individual chat page
```

## Adding Messages Button to Equipment Details

To allow users to message equipment owners:

```dart
ElevatedButton.icon(
  onPressed: () async {
    final chat = await _chatService.getOrCreateChat(
      user1Id: _currentUserId,
      user2Id: equipment.ownerId,
      user1Name: _currentUserName,
      user2Name: equipment.ownerName, // You'll need to fetch this
      user1Avatar: '', // Your avatar
      user2Avatar: '', // Equipment owner's avatar
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chat: chat,
          currentUserId: _currentUserId,
          currentUserName: _currentUserName,
        ),
      ),
    );
  },
  icon: const Icon(Icons.message),
  label: const Text('Message Owner'),
)
```

## Real-Time Features

The chat system uses Supabase's real-time subscriptions to:
- Receive new messages instantly
- Update message lists automatically
- No need to refresh manually
- Efficient polling with stream architecture

## Future Enhancements

1. **Message Search** - Search through chat history
2. **File Sharing** - Share images and documents
3. **Typing Indicators** - Show when someone is typing
4. **Read Receipts** - Show when messages are read
5. **Message Reactions** - Emoji reactions to messages
6. **Chat Notifications** - Push notifications for new messages
7. **Chat Blocking** - Block users
8. **Message Pinning** - Pin important messages

## Troubleshooting

### Messages not sending
- Check internet connection
- Verify Supabase is configured correctly
- Check RLS policies are properly set

### Messages not appearing
- Ensure you're subscribed to the chat
- Check that the chat_id is correct
- Verify RLS policies allow access

### Chat list empty
- Check that chats exist in the database
- Verify you're getting the correct user ID

## Support

For more information, see:
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

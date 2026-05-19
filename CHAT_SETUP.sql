-- Create chats table
CREATE TABLE IF NOT EXISTS chats (
  id TEXT PRIMARY KEY,
  user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user1_name TEXT NOT NULL,
  user2_name TEXT NOT NULL,
  user1_avatar TEXT,
  user2_avatar TEXT,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  unread_count INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  CONSTRAINT different_users CHECK (user1_id != user2_id)
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  chat_id TEXT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_avatar TEXT,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  is_read BOOLEAN DEFAULT FALSE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_chats_user1_id ON chats(user1_id);
CREATE INDEX IF NOT EXISTS idx_chats_user2_id ON chats(user2_id);
CREATE INDEX IF NOT EXISTS idx_chats_last_message_time ON chats(last_message_time DESC);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Enable RLS (Row Level Security)
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create policies for chats table
-- Users can view chats they're part of
CREATE POLICY "Users can view their chats" ON chats
  FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Users can insert chats
CREATE POLICY "Users can create chats" ON chats
  FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Users can update chats they're part of
CREATE POLICY "Users can update their chats" ON chats
  FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Create policies for messages table
-- Users can view messages from chats they're part of
CREATE POLICY "Users can view messages from their chats" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chats WHERE id = messages.chat_id 
      AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
  );

-- Users can insert messages to chats they're part of
CREATE POLICY "Users can send messages" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM chats WHERE id = messages.chat_id 
      AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
  );

-- Users can update their own messages
CREATE POLICY "Users can update their messages" ON messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- Users can delete their own messages
CREATE POLICY "Users can delete their messages" ON messages
  FOR DELETE USING (auth.uid() = sender_id);

-- Create a function to update the updated_at timestamp for chats
CREATE OR REPLACE FUNCTION update_chats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update the updated_at column
CREATE TRIGGER update_chats_updated_at_trigger
BEFORE UPDATE ON chats
FOR EACH ROW
EXECUTE FUNCTION update_chats_updated_at();

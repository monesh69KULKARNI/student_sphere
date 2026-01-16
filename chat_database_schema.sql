-- Chat Database Schema for StudentSphere
-- This file creates the necessary tables for the chat feature

-- Chat Rooms Table
-- Represents a conversation between two or more users
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT, -- Optional name for group chats
    is_group_chat BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chat_rooms_name_check CHECK (
        (is_group_chat = TRUE AND name IS NOT NULL) OR 
        (is_group_chat = FALSE)
    )
);

-- Chat Participants Table
-- Links users to chat rooms (many-to-many relationship)
CREATE TABLE IF NOT EXISTS chat_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT FALSE, -- For group chat management
    
    -- Constraints
    UNIQUE(chat_room_id, user_id),
    CONSTRAINT chat_participants_admin_check CHECK (
        (is_group_chat = TRUE) OR (is_admin = FALSE)
    )
);

-- Messages Table
-- Stores individual messages in chat rooms
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    file_url TEXT, -- URL for image/file messages
    file_name TEXT, -- Original file name
    file_size BIGINT, -- File size in bytes
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL, -- For threaded replies
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT messages_content_check CHECK (
        (message_type = 'text' AND content IS NOT NULL) OR
        (message_type IN ('image', 'file') AND file_url IS NOT NULL)
    )
);

-- Typing Indicators Table
-- Tracks who is currently typing in which chat room
CREATE TABLE IF NOT EXISTS typing_indicators (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(chat_room_id, user_id)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_room_id ON chat_participants(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_room_id ON messages(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_chat_room_id ON typing_indicators(chat_room_id);

-- Row Level Security (RLS) Policies
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- Chat Rooms RLS Policies
CREATE POLICY "Users can view chat rooms they participate in" ON chat_rooms
    FOR SELECT USING (
        id IN (
            SELECT chat_room_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create chat rooms" ON chat_rooms
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update chat rooms they created" ON chat_rooms
    FOR UPDATE USING (created_by = auth.uid());

-- Chat Participants RLS Policies
CREATE POLICY "Users can view participants in their chat rooms" ON chat_participants
    FOR SELECT USING (
        chat_room_id IN (
            SELECT chat_room_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert participants in chat rooms they created" ON chat_participants
    FOR INSERT WITH CHECK (
        chat_room_id IN (
            SELECT id FROM chat_rooms WHERE created_by = auth.uid()
        )
    );

CREATE POLICY "Users can update their own participant info" ON chat_participants
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete themselves from chat rooms" ON chat_participants
    FOR DELETE USING (user_id = auth.uid());

-- Messages RLS Policies
CREATE POLICY "Users can view messages in their chat rooms" ON messages
    FOR SELECT USING (
        chat_room_id IN (
            SELECT chat_room_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages in their chat rooms" ON messages
    FOR INSERT WITH CHECK (
        chat_room_id IN (
            SELECT chat_room_id FROM chat_participants 
            WHERE user_id = auth.uid()
        ) AND sender_id = auth.uid()
    );

CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages" ON messages
    FOR DELETE USING (sender_id = auth.uid());

-- Typing Indicators RLS Policies
CREATE POLICY "Users can view typing indicators in their chat rooms" ON typing_indicators
    FOR SELECT USING (
        chat_room_id IN (
            SELECT chat_room_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own typing indicators" ON typing_indicators
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own typing indicators" ON typing_indicators
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own typing indicators" ON typing_indicators
    FOR DELETE USING (user_id = auth.uid());

-- Functions and Triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_chat_rooms_updated_at 
    BEFORE UPDATE ON chat_rooms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to get or create direct chat room between two users
CREATE OR REPLACE FUNCTION get_or_create_direct_chat(
    user1_id UUID,
    user2_id UUID
)
RETURNS UUID AS $$
DECLARE
    chat_room_id UUID;
BEGIN
    -- Check if a direct chat already exists between these users
    SELECT cr.id INTO chat_room_id
    FROM chat_rooms cr
    JOIN chat_participants cp1 ON cr.id = cp1.chat_room_id
    JOIN chat_participants cp2 ON cr.id = cp2.chat_room_id
    WHERE cr.is_group_chat = FALSE
      AND cp1.user_id = user1_id
      AND cp2.user_id = user2_id
      AND cp1.user_id != cp2.user_id;
    
    -- If no chat room exists, create one
    IF chat_room_id IS NULL THEN
        INSERT INTO chat_rooms (created_by, is_group_chat)
        VALUES (user1_id, FALSE)
        RETURNING id INTO chat_room_id;
        
        -- Add both users as participants
        INSERT INTO chat_participants (chat_room_id, user_id)
        VALUES 
            (chat_room_id, user1_id),
            (chat_room_id, user2_id);
    END IF;
    
    RETURN chat_room_id;
END;
$$ LANGUAGE plpgsql;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_chat_room_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE chat_participants 
    SET last_read_at = NOW()
    WHERE chat_room_id = p_chat_room_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get unread message count
CREATE OR REPLACE FUNCTION get_unread_message_count(
    p_chat_room_id UUID,
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    last_read_time TIMESTAMP WITH TIME ZONE;
    unread_count INTEGER;
BEGIN
    -- Get the last read time for the user
    SELECT last_read_at INTO last_read_time
    FROM chat_participants
    WHERE chat_room_id = p_chat_room_id AND user_id = p_user_id;
    
    -- Count unread messages
    SELECT COUNT(*) INTO unread_count
    FROM messages
    WHERE chat_room_id = p_chat_room_id
      AND sender_id != p_user_id
      AND created_at > COALESCE(last_read_time, '1970-01-01'::timestamp);
    
    RETURN COALESCE(unread_count, 0);
END;
$$ LANGUAGE plpgsql;

-- Real-time subscriptions setup
-- These will be used by the Flutter app for real-time messaging
-- The Supabase client will automatically handle subscriptions to these tables

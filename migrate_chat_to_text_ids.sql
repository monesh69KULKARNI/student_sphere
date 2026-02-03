-- First, disable all triggers and drop RLS policies to prevent issues during migration
SET session_replication_role = replica;

-- Step 1: Drop all RLS policies
DO $$
BEGIN
    -- Drop chat_rooms policies
    DROP POLICY IF EXISTS "Users can view chat rooms they participate in" ON chat_rooms;
    DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
    DROP POLICY IF EXISTS "Users can update chat rooms they created" ON chat_rooms;
    
    -- Drop chat_participants policies
    DROP POLICY IF EXISTS "Users can view participants in their chat rooms" ON chat_participants;
    DROP POLICY IF EXISTS "Users can insert participants in chat rooms they created" ON chat_participants;
    DROP POLICY IF EXISTS "Users can update their own participant info" ON chat_participants;
    DROP POLICY IF EXISTS "Users can delete themselves from chat rooms" ON chat_participants;
    
    -- Drop messages policies
    DROP POLICY IF EXISTS "Users can view messages in their chat rooms" ON messages;
    DROP POLICY IF EXISTS "Users can insert messages in their chat rooms" ON messages;
    DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
    DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
    
    -- Drop typing_indicators policies
    DROP POLICY IF EXISTS "Users can view typing indicators in their chat rooms" ON typing_indicators;
    DROP POLICY IF EXISTS "Users can update their own typing indicators" ON typing_indicators;
    DROP POLICY IF EXISTS "Users can delete their own typing indicators" ON typing_indicators;
END $$;

-- Step 2: Create a backup of the current tables
CREATE TABLE IF NOT EXISTS chat_rooms_backup AS SELECT * FROM chat_rooms;
CREATE TABLE IF NOT EXISTS chat_participants_backup AS SELECT * FROM chat_participants;
CREATE TABLE IF NOT EXISTS messages_backup AS SELECT * FROM messages;

-- Step 2: Drop dependent objects
DROP TRIGGER IF EXISTS update_chat_rooms_updated_at ON chat_rooms;
DROP TRIGGER IF EXISTS validate_chat_participant_admin_trigger ON chat_participants;

-- Step 3: Drop foreign key constraints
ALTER TABLE chat_participants DROP CONSTRAINT IF EXISTS chat_participants_chat_room_id_fkey;
ALTER TABLE chat_participants DROP CONSTRAINT IF EXISTS chat_participants_user_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_chat_room_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

-- Step 4: Change column types to TEXT
ALTER TABLE chat_rooms ALTER COLUMN id TYPE TEXT;
ALTER TABLE chat_rooms ALTER COLUMN created_by TYPE TEXT;

ALTER TABLE chat_participants ALTER COLUMN id TYPE TEXT;
ALTER TABLE chat_participants ALTER COLUMN chat_room_id TYPE TEXT;
ALTER TABLE chat_participants ALTER COLUMN user_id TYPE TEXT;

ALTER TABLE messages ALTER COLUMN id TYPE TEXT;
ALTER TABLE messages ALTER COLUMN chat_room_id TYPE TEXT;
ALTER TABLE messages ALTER COLUMN sender_id TYPE TEXT;
ALTER TABLE messages ALTER COLUMN reply_to_id TYPE TEXT;

-- Step 5: Recreate the chat_participants table with text IDs
CREATE OR REPLACE FUNCTION create_chat_participants_table()
RETURNS void AS $$
BEGIN
    -- Drop the old table if it exists
    DROP TABLE IF EXISTS chat_participants;
    
    -- Create the new table with text IDs
    CREATE TABLE chat_participants (
        id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
        chat_room_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        is_admin BOOLEAN DEFAULT FALSE,
        UNIQUE(chat_room_id, user_id)
    );
    
    -- Recreate indexes
    CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);
    CREATE INDEX idx_chat_participants_chat_room_id ON chat_participants(chat_room_id);
    
    -- Re-insert data
    INSERT INTO chat_participants (id, chat_room_id, user_id, joined_at, last_read_at, is_admin)
    SELECT id::text, chat_room_id::text, user_id::text, joined_at, last_read_at, is_admin
    FROM chat_participants_backup;
    
    -- Recreate foreign key constraints
    ALTER TABLE chat_participants 
        ADD CONSTRAINT chat_participants_chat_room_id_fkey 
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE;
        
    ALTER TABLE chat_participants 
        ADD CONSTRAINT chat_participants_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
END;
$$ LANGUAGE plpgsql;

-- Execute the function
SELECT create_chat_participants_table();

-- Step 6: Recreate the messages table with text IDs
CREATE OR REPLACE FUNCTION create_messages_table()
RETURNS void AS $$
BEGIN
    -- Drop the old table if it exists
    DROP TABLE IF EXISTS messages;
    
    -- Create the new table with text IDs
    CREATE TABLE messages (
        id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
        chat_room_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
        file_url TEXT,
        file_name TEXT,
        file_size BIGINT,
        reply_to_id TEXT,
        is_edited BOOLEAN DEFAULT FALSE,
        edited_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        CONSTRAINT messages_content_check CHECK (
            (message_type = 'text' AND content IS NOT NULL) OR
            (message_type IN ('image', 'file') AND file_url IS NOT NULL)
        )
    );
    
    -- Recreate indexes
    CREATE INDEX idx_messages_chat_room_id ON messages(chat_room_id);
    CREATE INDEX idx_messages_sender_id ON messages(sender_id);
    CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
    
    -- Re-insert data
    INSERT INTO messages (id, chat_room_id, sender_id, content, message_type, file_url, 
                         file_name, file_size, reply_to_id, is_edited, edited_at, created_at)
    SELECT id::text, chat_room_id::text, sender_id::text, content, message_type, file_url,
           file_name, file_size, reply_to_id::text, is_edited, edited_at, created_at
    FROM messages_backup;
    
    -- Recreate foreign key constraints
    ALTER TABLE messages 
        ADD CONSTRAINT messages_chat_room_id_fkey 
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE;
        
    ALTER TABLE messages 
        ADD CONSTRAINT messages_sender_id_fkey 
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE;
        
    ALTER TABLE messages 
        ADD CONSTRAINT messages_reply_to_id_fkey 
        FOREIGN KEY (reply_to_id) REFERENCES messages(id) ON DELETE SET NULL;
END;
$$ LANGUAGE plpgsql;

-- Execute the function
SELECT create_messages_table();

-- Step 7: Recreate the chat_rooms table with text IDs
CREATE OR REPLACE FUNCTION create_chat_rooms_table()
RETURNS void AS $$
BEGIN
    -- Drop the old table if it exists
    DROP TABLE IF EXISTS chat_rooms;
    
    -- Create the new table with text IDs
    CREATE TABLE chat_rooms (
        id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
        name TEXT,
        is_group_chat BOOLEAN DEFAULT FALSE,
        created_by TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        CONSTRAINT chat_rooms_name_check CHECK (
            (is_group_chat = TRUE AND name IS NOT NULL) OR 
            (is_group_chat = FALSE)
        )
    );
    
    -- Re-insert data
    INSERT INTO chat_rooms (id, name, is_group_chat, created_by, created_at, updated_at)
    SELECT id::text, name, is_group_chat, created_by::text, created_at, updated_at
    FROM chat_rooms_backup;
    
    -- Recreate foreign key constraints
    ALTER TABLE chat_rooms 
        ADD CONSTRAINT chat_rooms_created_by_fkey 
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
        
    -- Create the update_updated_at_column function using dynamic SQL
    EXECUTE 'CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $BODY$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $BODY$ LANGUAGE plpgsql;';
    
    -- Create the trigger
    EXECUTE 'CREATE TRIGGER update_chat_rooms_updated_at 
        BEFORE UPDATE ON chat_rooms 
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
END;
$$ LANGUAGE plpgsql;

-- Execute the function
SELECT create_chat_rooms_table();

-- Step 8: Re-enable triggers
SET session_replication_role = DEFAULT;

-- Step 9: Apply the fixed RLS policies to prevent infinite recursion

-- First, drop the problematic constraint
ALTER TABLE chat_participants DROP CONSTRAINT IF EXISTS chat_participants_admin_check;

-- Recreate the constraint using a trigger function
CREATE OR REPLACE FUNCTION validate_chat_participant_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- Only check for non-group chats
    IF EXISTS (
        SELECT 1 FROM chat_rooms 
        WHERE id = NEW.chat_room_id
        AND is_group_chat = FALSE 
        AND NEW.is_admin = TRUE
    ) THEN
        RAISE EXCEPTION 'Only group chats can have admin participants';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS validate_chat_participant_admin_trigger ON chat_participants;
CREATE TRIGGER validate_chat_participant_admin_trigger
BEFORE INSERT OR UPDATE ON chat_participants
FOR EACH ROW EXECUTE FUNCTION validate_chat_participant_admin();

-- Create a separate table to track user chat room memberships without recursion
CREATE TABLE IF NOT EXISTS user_chat_memberships (
    user_id TEXT NOT NULL,
    chat_room_id TEXT NOT NULL,
    PRIMARY KEY (user_id, chat_room_id)
);

-- Enable RLS on the membership table
ALTER TABLE user_chat_memberships ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_chat_memberships_user_id ON user_chat_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_user_chat_memberships_chat_room_id ON user_chat_memberships(chat_room_id);

-- RLS policies for user_chat_memberships table
CREATE POLICY "Users can view their own memberships" ON user_chat_memberships
FOR SELECT USING (user_id = auth.uid()::text);

CREATE POLICY "Users can insert their own memberships" ON user_chat_memberships
FOR INSERT WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can delete their own memberships" ON user_chat_memberships
FOR DELETE USING (user_id = auth.uid()::text);

-- Create a trigger to maintain the membership table
CREATE OR REPLACE FUNCTION maintain_user_chat_memberships()
RETURNS TRIGGER AS $$
BEGIN
    -- Temporarily disable RLS for this operation
    SET LOCAL session_replication_role = replica;
    
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_chat_memberships (user_id, chat_room_id)
        VALUES (NEW.user_id, NEW.chat_room_id)
        ON CONFLICT (user_id, chat_room_id) DO NOTHING;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM user_chat_memberships 
        WHERE user_id = OLD.user_id AND chat_room_id = OLD.chat_room_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.user_id != NEW.user_id OR OLD.chat_room_id != NEW.chat_room_id THEN
            DELETE FROM user_chat_memberships 
            WHERE user_id = OLD.user_id AND chat_room_id = OLD.chat_room_id;
            INSERT INTO user_chat_memberships (user_id, chat_room_id)
            VALUES (NEW.user_id, NEW.chat_room_id)
            ON CONFLICT (user_id, chat_room_id) DO NOTHING;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on chat_participants
DROP TRIGGER IF EXISTS maintain_user_chat_memberships_trigger ON chat_participants;
CREATE TRIGGER maintain_user_chat_memberships_trigger
AFTER INSERT OR DELETE OR UPDATE ON chat_participants
FOR EACH ROW EXECUTE FUNCTION maintain_user_chat_memberships();

-- Populate the membership table with existing data
SET LOCAL session_replication_role = replica;
INSERT INTO user_chat_memberships (user_id, chat_room_id)
SELECT DISTINCT user_id, chat_room_id 
FROM chat_participants
ON CONFLICT (user_id, chat_room_id) DO NOTHING;
RESET session_replication_role;

-- Helper function using the non-recursive table
CREATE OR REPLACE FUNCTION is_chat_member(room_id text, user_id text)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM user_chat_memberships 
        WHERE chat_room_id = room_id 
        AND user_id = user_id
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS for chat_rooms
CREATE POLICY "Users can view chat rooms they participate in" ON chat_rooms
FOR SELECT USING (EXISTS (
    SELECT 1 FROM user_chat_memberships 
    WHERE chat_room_id = chat_rooms.id 
    AND user_id = auth.uid()::text
));

CREATE POLICY "Users can create chat rooms" ON chat_rooms
FOR INSERT WITH CHECK (
    created_by = auth.uid()::text AND
    (
        (is_group_chat = FALSE AND name IS NULL) OR
        (is_group_chat = TRUE AND name IS NOT NULL AND name != '')
    )
);

CREATE POLICY "Users can update chat rooms they created" ON chat_rooms
FOR UPDATE USING (created_by = auth.uid()::text);

-- Trigger to automatically add creator as a participant when a chat room is created
CREATE OR REPLACE FUNCTION add_creator_as_participant()
RETURNS TRIGGER AS $$
BEGIN
    -- Temporarily disable RLS for this operation
    SET LOCAL session_replication_role = replica;
    
    -- Insert the creator as a participant
    INSERT INTO chat_participants (chat_room_id, user_id, is_admin)
    VALUES (NEW.id, NEW.created_by, TRUE)
    ON CONFLICT (chat_room_id, user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS add_creator_as_participant_trigger ON chat_rooms;
CREATE TRIGGER add_creator_as_participant_trigger
AFTER INSERT ON chat_rooms
FOR EACH ROW EXECUTE FUNCTION add_creator_as_participant();

-- RLS for chat_participants - simplified to avoid recursion
CREATE POLICY "Users can view participants in their chat rooms" ON chat_participants
FOR SELECT USING (EXISTS (
    SELECT 1 FROM user_chat_memberships 
    WHERE chat_room_id = chat_participants.chat_room_id 
    AND user_id = auth.uid()::text
));

CREATE POLICY "Users can insert participants in chat rooms they created" ON chat_participants
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM chat_rooms 
        WHERE id = chat_room_id
        AND created_by = auth.uid()::text
    )
);

CREATE POLICY "Users can update their own participant info" ON chat_participants
FOR UPDATE USING (user_id = auth.uid()::text);

CREATE POLICY "Users can delete themselves from chat rooms" ON chat_participants
FOR DELETE USING (user_id = auth.uid()::text);

-- RLS for messages
CREATE POLICY "Users can view messages in their chat rooms" ON messages
FOR SELECT USING (EXISTS (
    SELECT 1 FROM user_chat_memberships 
    WHERE chat_room_id = messages.chat_room_id 
    AND user_id = auth.uid()::text
));

CREATE POLICY "Users can insert messages in their chat rooms" ON messages
FOR INSERT WITH CHECK (
    sender_id = auth.uid()::text 
    AND EXISTS (
        SELECT 1 FROM user_chat_memberships 
        WHERE chat_room_id = messages.chat_room_id 
        AND user_id = auth.uid()::text
    )
);

CREATE POLICY "Users can update their own messages" ON messages
FOR UPDATE USING (sender_id = auth.uid()::text);

CREATE POLICY "Users can delete their own messages" ON messages
FOR DELETE USING (sender_id = auth.uid()::text);

-- RLS for typing_indicators
CREATE POLICY "Users can view typing indicators in their chat rooms" ON typing_indicators
FOR SELECT USING (EXISTS (
    SELECT 1 FROM user_chat_memberships 
    WHERE chat_room_id = typing_indicators.chat_room_id 
    AND user_id = auth.uid()::text
));

CREATE POLICY "Users can update their own typing indicators" ON typing_indicators
FOR ALL USING (user_id = auth.uid()::text);

-- Step 10: Clean up backup tables (uncomment after verifying the migration)
-- DROP TABLE IF EXISTS chat_rooms_backup;
-- DROP TABLE IF EXISTS chat_participants_backup;
-- DROP TABLE IF EXISTS messages_backup;

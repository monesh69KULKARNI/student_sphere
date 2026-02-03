-- Fix for infinite recursion in chat_participants RLS policy with text IDs
-- First, drop the problematic constraint
ALTER TABLE chat_participants DROP CONSTRAINT IF EXISTS chat_participants_admin_check;

-- Recreate the constraint without the circular reference
-- Using a trigger function to handle the validation
CREATE OR REPLACE FUNCTION validate_chat_participant_admin()
RETURNS TRIGGER AS $$
BEGIN
    -- Only check for non-group chats
    IF EXISTS (
        SELECT 1 FROM chat_rooms 
        WHERE id::text = NEW.chat_room_id::text
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

-- Update RLS policies to prevent infinite recursion and handle text IDs
-- First drop the existing policy
DROP POLICY IF EXISTS "Users can view participants in their chat rooms" ON chat_participants;

-- Recreate the policy with text ID comparison
CREATE POLICY "Users can view participants in their chat rooms" ON chat_participants
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM chat_participants cp
        WHERE cp.user_id = auth.uid()::text
        AND cp.chat_room_id = chat_participants.chat_room_id
    )
);

-- Drop and recreate other policies that might cause recursion
DROP POLICY IF EXISTS "Users can insert participants in chat rooms they created" ON chat_participants;
CREATE POLICY "Users can insert participants in chat rooms they created" ON chat_participants
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM chat_rooms 
        WHERE id::text = chat_room_id::text
        AND created_by = auth.uid()::text
    )
);

-- Add a function to check if a user is a participant in a chat room
CREATE OR REPLACE FUNCTION is_chat_participant(p_chat_room_id text, p_user_id text)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM chat_participants 
        WHERE chat_room_id = p_chat_room_id 
        AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the chat_rooms select policy to use the new function with text IDs
DROP POLICY IF EXISTS "Users can view chat rooms they participate in" ON chat_rooms;
CREATE POLICY "Users can view chat rooms they participate in" ON chat_rooms
FOR SELECT USING (is_chat_participant(id::text, auth.uid()::text));

-- Update the messages select policy
DROP POLICY IF EXISTS "Users can view messages in their chat rooms" ON messages;
CREATE POLICY "Users can view messages in their chat rooms" ON messages
FOR SELECT USING (is_chat_participant(chat_room_id::text, auth.uid()::text));

-- Update the typing indicators select policy
DROP POLICY IF EXISTS "Users can view typing indicators in their chat rooms" ON typing_indicators;
CREATE POLICY "Users can view typing indicators in their chat rooms" ON typing_indicators
FOR SELECT USING (is_chat_participant(chat_room_id::text, auth.uid()::text));

-- Update the chat_rooms RLS policy for updates
DROP POLICY IF EXISTS "Users can update chat rooms they created" ON chat_rooms;
CREATE POLICY "Users can update chat rooms they created" ON chat_rooms
FOR UPDATE USING (created_by = auth.uid()::text);

-- Update the chat_participants update policy
DROP POLICY IF EXISTS "Users can update their own participant info" ON chat_participants;
CREATE POLICY "Users can update their own participant info" ON chat_participants
FOR UPDATE USING (user_id = auth.uid()::text);

-- Update the chat_participants delete policy
DROP POLICY IF EXISTS "Users can delete themselves from chat rooms" ON chat_participants;
CREATE POLICY "Users can delete themselves from chat rooms" ON chat_participants
FOR DELETE USING (user_id = auth.uid()::text);

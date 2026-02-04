import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/services/supabase_service.dart';
import '../models/chat.dart';
import '../core/models/user_model.dart';
import '../core/providers/auth_provider.dart';

class ChatService {
  static final SupabaseClient? _supabase = SupabaseService.client;
  static final _uuid = Uuid();

  // Get current user - this should be called with AuthProvider context
  static Future<UserModel?> getCurrentUser(AuthProvider authProvider) async {
    return authProvider.currentUser;
  }

  // Generate a valid UUID for chat operations
  static String _generateChatId() {
    return _uuid.v4();
  }
  // Get all chat rooms for the current user
  static Future<List<ChatRoom>> getChatRooms(AuthProvider authProvider) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 Fetching chat rooms for user: ${currentUser.uid}');

      // Get chat rooms where the user is a participant
      final response = await _supabase!
          .from('chat_participants')
          .select('''
            chat_room_id,
            chat_rooms!inner(
              id,
              name,
              is_group_chat,
              created_by,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', currentUser.uid);

      debugPrint('📱 Chat rooms response: ${response.length} rooms');
      debugPrint('📱 Response data: $response');

      final List<ChatRoom> chatRooms = [];

      for (final participantData in response) {
        final room = participantData['chat_rooms'] as Map<String, dynamic>?;
        
        if (room == null) {
          debugPrint('⚠️ Skipping room with null chat_rooms data');
          continue;
        }

        final chatRoomId = room['id']?.toString() ?? '';

        debugPrint('🏠 Processing chat room: $chatRoomId');
        debugPrint('RAW ROOM MAP => $room');

        // Get participants for this chat room
        final participantsResponse = await _supabase!
            .from('chat_participants')
            .select('''
              id,
              user_id,
              joined_at,
              last_read_at,
              is_admin,
              users!inner(
                uid,
                name,
                email,
                role,
                student_id,
                department,
                year,
                phone,
                profile_image_url,
                created_at
              )
            ''')
            .eq('chat_room_id', chatRoomId);

        debugPrint('👥 Participants for $chatRoomId: ${participantsResponse.length}');

        // Get last message for this chat room
        final lastMessageResponse = await _supabase!
            .from('messages')
            .select('''
              id,
              sender_id,
              content,
              message_type,
              file_url,
              file_name,
              file_size,
              reply_to_id,
              is_edited,
              edited_at,
              created_at,
              users!inner(
                uid,
                name,
                email,
                role,
                student_id,
                department,
                year,
                phone,
                profile_image_url,
                created_at
              )
            ''')
            .eq('chat_room_id', chatRoomId)
            .order('created_at', ascending: false)
            .limit(1);

        debugPrint('💬 Last message for $chatRoomId: ${lastMessageResponse.isNotEmpty ? 'found' : 'none'}');

        // Convert to ChatRoom model
        // Create participants list
        final List<ChatParticipant> participants = participantsResponse
            .map((p) => ChatParticipant.fromJson({
                  ...p,
                  'chat_room_id': chatRoomId,
                  'user': p['users'],
                }))
            .cast<ChatParticipant>()
            .toList();

        // Create last message
        Message? lastMessage;
        if (lastMessageResponse.isNotEmpty) {
          lastMessage = Message.fromJson({
            ...lastMessageResponse.first,
            'chat_room_id': chatRoomId,
            'sender': lastMessageResponse.first['users'],
          });
        }

        // Create chat room with safe parsing (YOUR FIX APPLIED)
        try {
          final chatRoom = ChatRoom(
            id: room['id']?.toString() ?? '',
            name: room['name']?.toString() ?? 'Unnamed Chat',
            type: room['is_group_chat'] == true
                ? ChatType.group
                : ChatType.direct,
            createdBy: room['created_by']?.toString() ?? '',
            createdAt: DateTime.parse(room['created_at']?.toString() ?? DateTime.now().toIso8601String()),
            updatedAt: DateTime.parse(room['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
            participants: participants,
            lastMessage: lastMessage,
            unreadCount: 0,
          );
          chatRooms.add(chatRoom);
        } catch (e) {
          debugPrint('❌ Error creating chat room: $e');
          debugPrint('❌ Chat room fields: id=${room['id']}, name=${room['name']}, created_by=${room['created_by']}, created_at=${room['created_at']}, updated_at=${room['updated_at']}');
          rethrow;
        }
      }

      debugPrint('✅ Successfully loaded ${chatRooms.length} chat rooms');
      return chatRooms;
    } catch (e) {
      debugPrint('❌ Error loading chat rooms: $e');
      rethrow;
    }
  }

  // Get or create a direct chat between two users
  static Future<String> getOrCreateDirectChat(AuthProvider authProvider, String otherUserId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First, try to find existing direct chat between these users
      // Get all chat rooms where current user is a participant
      final currentUserChats = await _supabase!
          .from('chat_participants')
          .select('chat_room_id')
          .eq('user_id', currentUser.uid);

      // Get all chat rooms where other user is a participant
      final otherUserChats = await _supabase!
          .from('chat_participants')
          .select('chat_room_id')
          .eq('user_id', otherUserId);

      // Find common chat rooms
      final currentUserChatIds = currentUserChats.map((row) => row['chat_room_id']?.toString() ?? '').toSet();
      final otherUserChatIds = otherUserChats.map((row) => row['chat_room_id']?.toString() ?? '').toSet();
      final commonChatIds = currentUserChatIds.intersection(otherUserChatIds);

      if (commonChatIds.isNotEmpty) {
        return commonChatIds.first;
      }

      // Create new direct chat
      final chatRoomId = _generateChatId();
      
      // Create chat room
      await _supabase!.from('chat_rooms').insert({
        'id': chatRoomId,
        'is_group_chat': false,
        'created_by': currentUser.uid,
      });

      // Add both participants
      // ✅ FIX: Remove duplicates using Set to prevent duplicate participant error
      // This ensures currentUser.uid is only added once even if it's in participantIds
      final uniqueParticipantIds = {currentUser.uid, otherUserId}.toList();
      
      debugPrint('👥 Adding ${uniqueParticipantIds.length} unique participants');
      
      final participants = uniqueParticipantIds.map((userId) => {
            'chat_room_id': chatRoomId,
            'user_id': userId,
            'is_admin': userId == currentUser.uid,
          }).toList();

      await _supabase!.from('chat_participants').insert(participants);

      return chatRoomId;
    } catch (e) {
      debugPrint('❌ Error getting/creating direct chat: $e');
      rethrow;
    }
  }

  // Create a group chat
  static Future<String> createGroupChat(AuthProvider authProvider, {
    required String name,
    required List<String> participantIds,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Generate a valid UUID for the chat room
      final chatRoomId = _generateChatId();

      // Create chat room with generated UUID
      await _supabase!
          .from('chat_rooms')
          .insert({
            'id': chatRoomId,
            'name': name,
            'is_group_chat': true,
            'created_by': currentUser.uid,
          });

      // Add participants (including creator)
      // ✅ FIX: Remove duplicates using Set to prevent duplicate participant error
      // This ensures currentUser.uid is only added once even if it's in participantIds
      final uniqueParticipantIds = {currentUser.uid, ...participantIds}.toList();
      
      debugPrint('👥 Adding ${uniqueParticipantIds.length} unique participants');
      
      final participants = uniqueParticipantIds.map((userId) => {
            'chat_room_id': chatRoomId,
            'user_id': userId,
            'is_admin': userId == currentUser.uid,
          }).toList();

      await _supabase!.from('chat_participants').insert(participants);

      return chatRoomId;
    } catch (e) {
      debugPrint('❌ Error creating group chat: $e');
      rethrow;
    }
  }

  // Get messages for a chat room
  static Future<List<Message>> getMessages(String chatRoomId, {int limit = 50}) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _supabase!
          .from('messages')
          .select('''
            id,
            sender_id,
            content,
            message_type,
            file_url,
            file_name,
            file_size,
            reply_to_id,
            is_edited,
            edited_at,
            created_at,
            users!inner(
              uid,
              name,
              email,
              role,
              student_id,
              department,
              year,
              phone,
              profile_image_url,
              created_at
            )
          ''')
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = response
          .map((m) => Message.fromJson({
                ...m,
                'chat_room_id': chatRoomId,
                'sender': m['users'],
              }))
          .cast<Message>()
          .toList();

      // Reverse to get chronological order
      return messages.reversed.toList();
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      rethrow;
    }
  }

  // Send a message
  static Future<Message> sendMessage(AuthProvider authProvider, {
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final messageData = {
        'chat_room_id': chatRoomId,
        'sender_id': currentUser.uid,
        'content': content,
        'message_type': type.name,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'reply_to_id': replyToId,
      };

      final response = await _supabase!
          .from('messages')
          .insert(messageData)
          .select('''
            id,
            sender_id,
            content,
            message_type,
            file_url,
            file_name,
            file_size,
            reply_to_id,
            is_edited,
            edited_at,
            created_at,
            users!inner(
              uid,
              name,
              email,
              role,
              student_id,
              department,
              year,
              phone,
              profile_image_url,
              created_at
            )
          ''')
          .single();

      final message = Message.fromJson({
        ...response,
        'chat_room_id': chatRoomId,
        'sender': response['users'],
      });

      debugPrint('✅ Message sent successfully');
      return message;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Edit a message
  static Future<void> editMessage(AuthProvider authProvider, String messageId, String newContent) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', currentUser.uid);

      debugPrint('✅ Message edited successfully');
    } catch (e) {
      debugPrint('❌ Error editing message: $e');
      rethrow;
    }
  }

  // Delete a message
  static Future<void> deleteMessage(AuthProvider authProvider, String messageId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', currentUser.uid);

      debugPrint('✅ Message deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(AuthProvider authProvider, String chatRoomId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // ✅ FIX: Use direct query instead of RPC to avoid UUID type issues
      await _supabase!
          .from('chat_participants')
          .update({
            'last_read_at': DateTime.now().toIso8601String(),
          })
          .eq('chat_room_id', chatRoomId)
          .eq('user_id', currentUser.uid);

      debugPrint('✅ Messages marked as read');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
      rethrow;
    }
  }

  // Set typing indicator
  static Future<void> setTypingIndicator(AuthProvider authProvider, String chatRoomId, bool isTyping) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (isTyping) {
        await _supabase!.from('typing_indicators').upsert({
          'chat_room_id': chatRoomId,
          'user_id': currentUser.uid,
          'is_typing': true,
          'last_updated': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase!
            .from('typing_indicators')
            .delete()
            .eq('chat_room_id', chatRoomId)
            .eq('user_id', currentUser.uid);
      }
    } catch (e) {
      debugPrint('❌ Error setting typing indicator: $e');
      rethrow;
    }
  }

  // Get typing indicators for a chat room
  static Stream<List<TypingIndicator>> getTypingIndicators(String chatRoomId) {
    if (_supabase == null) {
      return Stream.error(Exception('Supabase not initialized'));
    }

    return _supabase!
        .from('typing_indicators')
        .stream(primaryKey: ['id'])
        .order('last_updated', ascending: false)
        .map((event) => event
            .where((row) => row['chat_room_id'] == chatRoomId && row['is_typing'] == true)
            .map((row) => TypingIndicator.fromJson(row))
            .cast<TypingIndicator>()
            .toList());
  }

  // Real-time message subscription
  static Stream<List<Message>> getMessageStream(String chatRoomId) {
    if (_supabase == null) {
      return Stream.error(Exception('Supabase not initialized'));
    }

    return _supabase!
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: false)
        .map((event) => event
            .map((row) => Message.fromJson({
                  ...row,
                  'chat_room_id': chatRoomId,
                }))
            .cast<Message>()
            .toList());
  }

  // Real-time chat room subscription
  static Stream<List<ChatRoom>> getChatRoomStream() {
    if (_supabase == null) {
      return Stream.error(Exception('Supabase not initialized'));
    }

    return _supabase!
        .from('chat_rooms')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((event) => event
            .map((row) => ChatRoom.fromJson(row))
            .cast<ChatRoom>()
            .toList());
  }

  // Upload file for chat message
  static Future<String> uploadChatFile(AuthProvider authProvider, {
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      final currentUser = await getCurrentUser(authProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'chat/${currentUser.uid}/$timestamp-$fileName';

      return await SupabaseService.uploadFile(
        bucket: 'chat-files',
        path: filePath,
        fileBytes: fileBytes,
        contentType: contentType,
      );
    } catch (e) {
      debugPrint('❌ Error uploading chat file: $e');
      rethrow;
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/chat.dart';
import '../core/models/user_model.dart';
import '../core/providers/auth_provider.dart';

class ChatService {
  static final SupabaseClient? _supabase = SupabaseService.client;

  // Get current user - this should be called with AuthProvider context
  static Future<UserModel?> getCurrentUser(AuthProvider authProvider) async {
    return authProvider.currentUser;
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

      final List<ChatRoom> chatRooms = [];

      for (final participantData in response) {
        final chatRoomData = participantData['chat_rooms'] as Map<String, dynamic>;
        final chatRoomId = chatRoomData['id'] as String;

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
                studentId,
                department,
                year,
                phone,
                profileImageUrl,
                createdAt
              )
            ''')
            .eq('chat_room_id', chatRoomId);

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
                studentId,
                department,
                year,
                phone,
                profileImageUrl,
                createdAt
              )
            ''')
            .eq('chat_room_id', chatRoomId)
            .order('created_at', ascending: false)
            .limit(1);

        // Get unread count
        final unreadCountResponse = await _supabase!
            .rpc('get_unread_message_count', params: {
              'p_chat_room_id': chatRoomId,
              'p_user_id': currentUser.uid,
            });

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

        // Create chat room
        final chatRoom = ChatRoom(
          id: chatRoomData['id'] as String,
          name: chatRoomData['name'] as String?,
          type: chatRoomData['is_group_chat'] == true
              ? ChatType.group
              : ChatType.direct,
          createdBy: chatRoomData['created_by'] as String,
          createdAt: DateTime.parse(chatRoomData['created_at'] as String),
          updatedAt: DateTime.parse(chatRoomData['updated_at'] as String),
          participants: participants,
          lastMessage: lastMessage,
          unreadCount: unreadCountResponse as int? ?? 0,
        );

        chatRooms.add(chatRoom);
      }

      // Sort by last message time or updated time
      chatRooms.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.updatedAt;
        final bTime = b.lastMessage?.createdAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

      return chatRooms;
    } catch (e) {
      debugPrint('❌ Error getting chat rooms: $e');
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

      final response = await _supabase!.rpc('get_or_create_direct_chat', params: {
        'user1_id': currentUser.uid,
        'user2_id': otherUserId,
      });

      return response as String;
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

      // Create chat room
      final chatRoomResponse = await _supabase!
          .from('chat_rooms')
          .insert({
            'name': name,
            'is_group_chat': true,
            'created_by': currentUser.uid,
          })
          .select('id')
          .single();

      final chatRoomId = chatRoomResponse['id'] as String;

      // Add participants (including creator)
      final allParticipantIds = [currentUser.uid, ...participantIds];
      final participants = allParticipantIds.map((userId) => {
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
              studentId,
              department,
              year,
              phone,
              profileImageUrl,
              createdAt
            ),
            reply_to_message:reply_to_id(
              id,
              sender_id,
              content,
              message_type,
              created_at,
              users!inner(
                uid,
                name,
                email,
                role,
                studentId,
                department,
                year,
                phone,
                profileImageUrl,
                createdAt
              )
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
                'reply_to_message': m['reply_to_message'] != null
                    ? {
                        ...m['reply_to_message'],
                        'sender': m['reply_to_message']['users'],
                      }
                    : null,
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
              studentId,
              department,
              year,
              phone,
              profileImageUrl,
              createdAt
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

      await _supabase!.rpc('mark_messages_as_read', params: {
        'p_chat_room_id': chatRoomId,
        'p_user_id': currentUser.uid,
      });

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

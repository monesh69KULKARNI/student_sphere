import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../core/providers/auth_provider.dart';
import '../core/models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  AuthProvider? _authProvider;

  // State variables
  bool _isLoading = false;
  List<ChatRoom> _chatRooms = [];
  List<Message> _messages = [];
  final Map<String, List<TypingIndicator>> _typingIndicators = {};
  String? _currentChatRoomId;
  String? _error;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;

  // Getters
  bool get isLoading => _isLoading;
  List<ChatRoom> get chatRooms => _chatRooms;
  List<Message> get messages => _messages;
  Map<String, List<TypingIndicator>> get typingIndicators => _typingIndicators;
  String? get currentChatRoomId => _currentChatRoomId;
  String? get error => _error;

  ChatProvider() {
    _initializeChat();
  }

  // Set the auth provider (called from main.dart)
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> _initializeChat() async {
    await loadChatRooms();
  }

  // Load all chat rooms for the current user
  Future<void> loadChatRooms() async {
    _setLoading(true);
    _clearError();

    try {
      final rooms = await ChatService.getChatRooms(_authProvider!);
      _chatRooms = rooms;
      notifyListeners();
      debugPrint('✅ Loaded ${rooms.length} chat rooms');
    } catch (e) {
      _setError('Failed to load chat rooms: $e');
      debugPrint('❌ Error loading chat rooms: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load messages for a specific chat room
  Future<void> loadMessages(String chatRoomId) async {
    _setLoading(true);
    _clearError();

    try {
      // Cancel previous subscriptions
      _messageSubscription?.cancel();
      _typingSubscription?.cancel();

      // Set current chat room
      _currentChatRoomId = chatRoomId;

      // Load initial messages
      final messages = await ChatService.getMessages(chatRoomId);
      _messages = messages;
      notifyListeners();

      // Mark messages as read
      await ChatService.markMessagesAsRead(_authProvider!, chatRoomId);

      // Subscribe to real-time messages
      _messageSubscription = ChatService
          .getMessageStream(chatRoomId)
          .listen((newMessages) {
        _messages = newMessages.reversed.toList();
        notifyListeners();
      });

      // Subscribe to typing indicators
      _typingSubscription = ChatService
          .getTypingIndicators(chatRoomId)
          .listen((indicators) {
        _typingIndicators[chatRoomId] = indicators
            .where((indicator) => indicator.userId != _getCurrentUserId())
            .toList();
        notifyListeners();
      });

      debugPrint('✅ Loaded ${messages.length} messages for room $chatRoomId');
    } catch (e) {
      _setError('Failed to load messages: $e');
      debugPrint('❌ Error loading messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send a text message
  Future<void> sendMessage(String content, {String? replyToId}) async {
    if (_currentChatRoomId == null || content.trim().isEmpty) return;

    try {
      final message = await ChatService.sendMessage(
        _authProvider!,
        chatRoomId: _currentChatRoomId!,
        content: content.trim(),
        replyToId: replyToId,
      );

      // Add message to local list immediately for better UX
      _messages.add(message);
      notifyListeners();

      debugPrint('✅ Message sent successfully');
    } catch (e) {
      _setError('Failed to send message: $e');
      debugPrint('❌ Error sending message: $e');
    }
  }

  // Send a file message
  Future<void> sendFileMessage({
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
    String? replyToId,
  }) async {
    if (_currentChatRoomId == null) return;

    try {
      // Upload file first
      final fileUrl = await ChatService.uploadChatFile(
        _authProvider!,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
      );

      // Send file message
      final messageType = _getMessageTypeFromContentType(contentType);
      final message = await ChatService.sendMessage(
        _authProvider!,
        chatRoomId: _currentChatRoomId!,
        content: fileName,
        type: messageType,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileBytes.length,
        replyToId: replyToId,
      );

      // Add message to local list immediately
      _messages.add(message);
      notifyListeners();

      debugPrint('✅ File message sent successfully');
    } catch (e) {
      _setError('Failed to send file: $e');
      debugPrint('❌ Error sending file message: $e');
    }
  }

  // Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await ChatService.editMessage(_authProvider!, messageId, newContent);
      
      // Update local message
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          content: newContent,
          isEdited: true,
          editedAt: DateTime.now(),
        );
        notifyListeners();
      }

      debugPrint('✅ Message edited successfully');
    } catch (e) {
      _setError('Failed to edit message: $e');
      debugPrint('❌ Error editing message: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await ChatService.deleteMessage(_authProvider!, messageId);
      
      // Remove from local list
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();

      debugPrint('✅ Message deleted successfully');
    } catch (e) {
      _setError('Failed to delete message: $e');
      debugPrint('❌ Error deleting message: $e');
    }
  }

  // Start typing indicator
  void startTyping() {
    if (_currentChatRoomId == null) return;

    ChatService.setTypingIndicator(_authProvider!, _currentChatRoomId!, true);

    // Cancel existing timer
    _typingTimer?.cancel();

    // Set timer to stop typing after 3 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping();
    });
  }

  // Stop typing indicator
  void stopTyping() {
    if (_currentChatRoomId == null) return;

    _typingTimer?.cancel();
    ChatService.setTypingIndicator(_authProvider!, _currentChatRoomId!, false);
  }

  // Get or create direct chat
  Future<String> getOrCreateDirectChat(String otherUserId) async {
    try {
      final chatRoomId = await ChatService.getOrCreateDirectChat(_authProvider!, otherUserId);
      await loadChatRooms(); // Refresh chat rooms list
      return chatRoomId;
    } catch (e) {
      _setError('Failed to create chat: $e');
      debugPrint('❌ Error creating direct chat: $e');
      rethrow;
    }
  }

  // Create group chat
  Future<String> createGroupChat({
    required String name,
    required List<String> participantIds,
  }) async {
    try {
      final chatRoomId = await ChatService.createGroupChat(
        _authProvider!,
        name: name,
        participantIds: participantIds,
      );
      await loadChatRooms(); // Refresh chat rooms list
      return chatRoomId;
    } catch (e) {
      _setError('Failed to create group chat: $e');
      debugPrint('❌ Error creating group chat: $e');
      rethrow;
    }
  }

  // Get unread count for all chat rooms
  int getTotalUnreadCount() {
    return _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  // Refresh current chat room
  Future<void> refreshChatRoom() async {
    if (_currentChatRoomId != null) {
      await loadMessages(_currentChatRoomId!);
    }
  }

  // Clear current chat room
  void clearCurrentChatRoom() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _currentChatRoomId = null;
    _messages = [];
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  String? _getCurrentUserId() {
    return _authProvider?.currentUser?.uid;
  }

  MessageType _getMessageTypeFromContentType(String contentType) {
    if (contentType.startsWith('image/')) {
      return MessageType.image;
    } else {
      return MessageType.file;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}

// Extension for Message copyWith method
extension MessageCopyWith on Message {
  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? content,
    MessageType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
    Message? replyToMessage,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    UserModel? sender,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }
}

import '../core/models/user_model.dart';

enum MessageType {
  text,
  image,
  file,
  system,
}

enum ChatType {
  direct, // One-on-one chat
  group,   // Group chat
}

class ChatRoom {
  final String id;
  final String? name;
  final ChatType type;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant> participants;
  final Message? lastMessage;
  final int unreadCount;

  ChatRoom({
    required this.id,
    this.name,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
  });

  // Get display name for the chat room
  String get displayName {
    if (type == ChatType.group) {
      return name ?? 'Group Chat';
    } else {
      // For direct chats, show the other participant's name
      final otherParticipants = participants
          .where((p) => p.userId != _currentUserId)
          .toList();
      if (otherParticipants.isNotEmpty) {
        return otherParticipants.first.user?.name ?? 'Unknown User';
      }
      return 'Unknown User';
    }
  }

  // Get profile image URL for the chat room
  String? get displayImage {
    if (type == ChatType.group) {
      return null; // TODO: Add group image support
    } else {
      final otherParticipants = participants
          .where((p) => p.userId != _currentUserId)
          .toList();
      if (otherParticipants.isNotEmpty) {
        return otherParticipants.first.user?.profileImageUrl;
      }
      return null;
    }
  }

  // This should be set from the chat provider
  static String _currentUserId = '';

  static void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
    };
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Chat',
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.direct,
      ),
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at']?.toString() ?? DateTime.now().toIso8601String()),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => ChatParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
    );
  }
}

class ChatParticipant {
  final String id;
  final String chatRoomId;
  final String userId;
  final DateTime joinedAt;
  final DateTime lastReadAt;
  final bool isAdmin;
  final UserModel? user;

  ChatParticipant({
    required this.id,
    required this.chatRoomId,
    required this.userId,
    required this.joinedAt,
    required this.lastReadAt,
    this.isAdmin = false,
    this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'last_read_at': lastReadAt.toIso8601String(),
      'is_admin': isAdmin,
      'user': user?.toMap(),
    };
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String? ?? '',
      chatRoomId: json['chat_room_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      joinedAt: DateTime.parse(json['joined_at'] as String? ?? DateTime.now().toIso8601String()),
      lastReadAt: DateTime.parse(json['last_read_at'] as String? ?? DateTime.now().toIso8601String()),
      isAdmin: json['is_admin'] as bool? ?? false,
      user: json['user'] != null
          ? UserModel.fromMap(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToId;
  final Message? replyToMessage;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final UserModel? sender;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyToId,
    this.replyToMessage,
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    this.sender,
  });

  bool get isFromCurrentUser => senderId == ChatRoom._currentUserId;

  String get timeFormatted {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get timeDetailed {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'reply_to_id': replyToId,
      'reply_to_message': replyToMessage?.toJson(),
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sender': sender?.toMap(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      chatRoomId: json['chat_room_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      replyToId: json['reply_to_id'] as String?,
      replyToMessage: json['reply_to_message'] != null
          ? Message.fromJson(json['reply_to_message'] as Map<String, dynamic>)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at']?.toString() ?? '')
          : null,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      sender: json['sender'] != null
          ? UserModel.fromMap(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TypingIndicator {
  final String chatRoomId;
  final String userId;
  final bool isTyping;
  final DateTime lastUpdated;
  final UserModel? user;

  TypingIndicator({
    required this.chatRoomId,
    required this.userId,
    required this.isTyping,
    required this.lastUpdated,
    this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'chat_room_id': chatRoomId,
      'user_id': userId,
      'is_typing': isTyping,
      'last_updated': lastUpdated.toIso8601String(),
      'user': user?.toMap(),
    };
  }

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      chatRoomId: json['chat_room_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      isTyping: json['is_typing'] == true,
      lastUpdated: DateTime.tryParse(json['last_updated']?.toString() ?? '') ?? DateTime.now(),
      user: json['user'] != null
          ? UserModel.fromMap(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Extended User model with additional chat-related fields
class ChatUser extends UserModel {
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.studentId,
    super.department,
    super.year,
    super.phone,
    super.profileImageUrl,
    required super.createdAt,
    super.lastLogin,
    super.additionalData,
    this.isOnline = false,
    this.lastSeen,
  });

  @override
  Map<String, dynamic> toMap() {
    final json = super.toMap();
    json.addAll({
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    });
    return json;
  }

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      role: UserRole.fromString(map['role']?.toString() ?? 'guest'),
      studentId: map['studentId']?.toString(),
      department: map['department']?.toString(),
      year: map['year']?.toString(),
      phone: map['phone']?.toString(),
      profileImageUrl: map['profileImageUrl']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastLogin: map['lastLogin'] != null
          ? DateTime.tryParse(map['lastLogin']?.toString() ?? '')
          : null,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
      isOnline: map['is_online'] == true,
      lastSeen: map['last_seen'] != null
          ? DateTime.tryParse(map['last_seen']?.toString() ?? '')
          : null,
    );
  }

  // Create a ChatUser from a UserModel
  factory ChatUser.fromUserModel(UserModel user, {
    bool isOnline = false,
    DateTime? lastSeen,
  }) {
    return ChatUser(
      uid: user.uid,
      email: user.email,
      name: user.name,
      role: user.role,
      studentId: user.studentId,
      department: user.department,
      year: user.year,
      phone: user.phone,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin,
      additionalData: user.additionalData,
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }
}

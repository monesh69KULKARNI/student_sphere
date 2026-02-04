import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../core/services/supabase_database_service.dart';
import '../../core/models/user_model.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.chat),
                    SizedBox(width: 8),
                    Text('New Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: 8),
                    Text('New Group'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chatProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => chatProvider.loadChatRooms(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final chatRooms = chatProvider.chatRooms;

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation to see it here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showNewChatDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Start New Chat'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadChatRooms(),
            child: ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return _ChatRoomTile(
                  chatRoom: chatRoom,
                  onTap: () => _openChatRoom(chatRoom),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openChatRoom(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: ChatSearchDelegate(),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewChatDialog(),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_chat':
        _showNewChatDialog();
        break;
      case 'new_group':
        _showNewGroupDialog();
        break;
    }
  }

  void _showNewGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewGroupDialog(),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: chatRoom.displayImage != null
            ? CachedNetworkImageProvider(chatRoom.displayImage!)
            : null,
        child: chatRoom.displayImage == null
            ? Text(
                chatRoom.displayName.isNotEmpty
                    ? chatRoom.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chatRoom.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chatRoom.type == ChatType.group)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chatRoom.participants.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              if (chatRoom.lastMessage?.type != MessageType.text)
                Icon(
                  _getMessageIcon(chatRoom.lastMessage?.type),
                  size: 16,
                  color: Colors.grey[600],
                ),
              if (chatRoom.lastMessage?.type != MessageType.text)
                const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getLastMessageText(chatRoom.lastMessage),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chatRoom.lastMessage?.createdAt ?? chatRoom.updatedAt),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          if (chatRoom.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                chatRoom.unreadCount > 99 ? '99+' : '${chatRoom.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getMessageIcon(MessageType? type) {
    switch (type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.system:
        return Icons.info;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _getLastMessageText(Message? message) {
    if (message == null) return 'No messages yet';

    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 ${message.fileName ?? 'File'}';
      case MessageType.system:
        return message.content;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: Implement search results
    return const Center(
      child: Text('Search results will appear here'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: Implement search suggestions
    return const Center(
      child: Text('Start typing to search'),
    );
  }
}

class NewChatDialog extends StatelessWidget {
  const NewChatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Chat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose how you want to start a conversation:'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Direct Chat'),
            subtitle: const Text('Chat with a specific person'),
            onTap: () {
              Navigator.pop(context);
              _showUserSelectionDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Group Chat'),
            subtitle: const Text('Create a group conversation'),
            onTap: () {
              Navigator.pop(context);
              _showGroupCreationDialog(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showUserSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserSelectionDialog(),
    );
  }

  void _showGroupCreationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewGroupDialog(),
    );
  }
}

class NewGroupDialog extends StatefulWidget {
  const NewGroupDialog({super.key});

  @override
  State<NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends State<NewGroupDialog> {
  final _nameController = TextEditingController();
  final List<String> _selectedParticipants = [];
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group Chat'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add participants:'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showParticipantSelection(context),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: _selectedParticipants.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.grey),
                            SizedBox(height: 4),
                            Text('Tap to add participants', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _selectedParticipants.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 16),
                            ),
                            title: Text('User ${_selectedParticipants[index]}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedParticipants.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isNotEmpty && !_isCreating
              ? _createGroupChat
              : null,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  void _showParticipantSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GroupParticipantSelectionDialog(
        onParticipantsSelected: (participants) {
          setState(() {
            _selectedParticipants.clear();
            _selectedParticipants.addAll(participants);
          });
        },
        initiallySelected: _selectedParticipants,
      ),
    );
  }

  Future<void> _createGroupChat() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      final chatRoomId = await chatProvider.createGroupChat(
        name: _nameController.text.trim(),
        participantIds: _selectedParticipants, // Can be empty for now
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        // Navigate to newly created chat room
        final chatRoom = chatProvider.chatRooms
            .firstWhere((room) => room.id == chatRoomId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class UserSelectionDialog extends StatefulWidget {
  const UserSelectionDialog({super.key});

  @override
  State<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select User'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red[400]),
                        const SizedBox(height: 8),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _users.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No other users found'),
                            Text('Be the first to add more users!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['profile_image_url'] != null
                                  ? CachedNetworkImageProvider(user['profile_image_url'])
                                  : null,
                              child: user['profile_image_url'] == null
                                  ? Text(
                                      user['name']?.isNotEmpty == true
                                          ? user['name'][0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(user['name'] ?? 'Unknown User'),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: Text(
                              user['role']?.toString().toUpperCase() ?? 'USER',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleColor(user['role']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => _createDirectChat(user['uid']),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'faculty':
        return Colors.purple;
      case 'student':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _createDirectChat(String otherUserId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      final chatRoomId = await chatProvider.getOrCreateDirectChat(otherUserId);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        // Navigate to the newly created chat room
        final chatRoom = chatProvider.chatRooms
            .firstWhere((room) => room.id == chatRoomId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to create chat: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await SupabaseDatabaseService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
}

class GroupParticipantSelectionDialog extends StatefulWidget {
  final Function(List<String>) onParticipantsSelected;
  final List<String> initiallySelected;

  const GroupParticipantSelectionDialog({
    super.key,
    required this.onParticipantsSelected,
    this.initiallySelected = const [],
  });

  @override
  State<GroupParticipantSelectionDialog> createState() => _GroupParticipantSelectionDialogState();
}

class _GroupParticipantSelectionDialogState extends State<GroupParticipantSelectionDialog> {
  bool _isLoading = false;
  String? _error;
  final Set<String> _selectedParticipants = {};
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _selectedParticipants.addAll(widget.initiallySelected);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Participants'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red[400]),
                        const SizedBox(height: 8),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _users.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No other users found'),
                            Text('Be the first to add more users!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final userId = user['uid'];
                                final isSelected = _selectedParticipants.contains(userId);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedParticipants.add(userId);
                                      } else {
                                        _selectedParticipants.remove(userId);
                                      }
                                    });
                                  },
                                  secondary: CircleAvatar(
                                    backgroundImage: user['profile_image_url'] != null
                                        ? CachedNetworkImageProvider(user['profile_image_url'])
                                        : null,
                                    child: user['profile_image_url'] == null
                                        ? Text(
                                            user['name']?.isNotEmpty == true
                                                ? user['name'][0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(user['name'] ?? 'Unknown User'),
                                      ),
                                      Text(
                                        user['role']?.toString().toUpperCase() ?? 'USER',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getRoleColor(user['role']),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(user['email'] ?? ''),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedParticipants.length} participant${_selectedParticipants.length == 1 ? '' : 's'} selected',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () {
            widget.onParticipantsSelected(_selectedParticipants.toList());
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'faculty':
        return Colors.purple;
      case 'student':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await SupabaseDatabaseService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }
}

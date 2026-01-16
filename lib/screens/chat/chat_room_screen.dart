import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.chatRoom.id);
    });
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    context.read<ChatProvider>().clearCurrentChatRoom();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      context.read<ChatProvider>().startTyping();
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      context.read<ChatProvider>().stopTyping();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(text);
    _messageController.clear();
    _isTyping = false;
    context.read<ChatProvider>().stopTyping();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        await context.read<ChatProvider>().sendFileMessage(
          fileBytes: file.bytes!,
          fileName: file.name,
          contentType: file.extension?.isNotEmpty == true
              ? 'application/${file.extension}'
              : 'application/octet-stream',
        );
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final bytes = await image.readAsBytes();
        await context.read<ChatProvider>().sendFileMessage(
          fileBytes: bytes,
          fileName: image.name,
          contentType: 'image/${image.name.split('.').last}',
        );
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.chatRoom.displayName.isNotEmpty
                    ? widget.chatRoom.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final typingIndicators =
                          chatProvider.typingIndicators[widget.chatRoom.id] ?? [];
                      if (typingIndicators.isNotEmpty) {
                        return Text(
                          '${typingIndicators.first.user?.name ?? 'Someone'} is typing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      if (widget.chatRoom.type == ChatType.group) {
                        return Text(
                          '${widget.chatRoom.participants.length} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
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
                          'Error loading messages',
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
                          onPressed: () => chatProvider.refreshChatRoom(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = chatProvider.messages;

                if (messages.isEmpty) {
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
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isFromCurrentUser: message.isFromCurrentUser,
                    );
                  },
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSend: _sendMessage,
            onPickFile: _pickFile,
            onPickImage: _pickImage,
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ChatInfoSheet(chatRoom: widget.chatRoom),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;

  const _MessageBubble({
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                message.sender?.name.isNotEmpty == true
                    ? message.sender!.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isFromCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.sender?.name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.replyToMessage != null)
                        _ReplyPreview(message: message.replyToMessage!),
                      _MessageContent(message: message),
                      if (message.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 10,
                              color: isFromCurrentUser
                                  ? Colors.white70
                                  : Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.timeDetailed,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                'You',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final Message message;

  const _ReplyPreview({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getMessagePreview(message),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getMessagePreview(Message message) {
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
}

class _MessageContent extends StatelessWidget {
  final Message message;

  const _MessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromCurrentUser
                ? Colors.white
                : Colors.black87,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.fileUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.fileUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            if (message.fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.fileName!,
                  style: TextStyle(
                    color: message.isFromCurrentUser
                        ? Colors.white70
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              size: 16,
              color: message.isFromCurrentUser
                  ? Colors.white70
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                message.fileName ?? 'File',
                style: TextStyle(
                  color: message.isFromCurrentUser
                      ? Colors.white
                      : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromCurrentUser
                ? Colors.white70
                : Colors.grey[600],
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        );
    }
  }
}

class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onPickFile;
  final VoidCallback onPickImage;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onPickFile,
    required this.onPickImage,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = widget.controller.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.onPickFile,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: widget.onPickImage,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isComposing ? Icons.send : Icons.mic,
              color: _isComposing
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
            onPressed: _isComposing ? widget.onSend : null,
          ),
        ],
      ),
    );
  }
}

class ChatInfoSheet extends StatelessWidget {
  final ChatRoom chatRoom;

  const ChatInfoSheet({super.key, required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatRoom.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (chatRoom.type == ChatType.group) ...[
            Text(
              'Participants (${chatRoom.participants.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              itemCount: chatRoom.participants.length,
              itemBuilder: (context, index) {
                final participant = chatRoom.participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      participant.user?.name.isNotEmpty == true
                          ? participant.user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(participant.user?.name ?? 'Unknown'),
                  subtitle: participant.isAdmin
                      ? const Text('Admin')
                      : null,
                );
              },
            ),
          ] else ...[
            Text(
              'Direct Chat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  chatRoom.participants.isNotEmpty &&
                          chatRoom.participants.first.user?.name.isNotEmpty == true
                      ? chatRoom.participants.first.user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(chatRoom.participants.first.user?.name ?? 'Unknown'),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (chatRoom.type == ChatType.group)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Show add participants dialog
                  },
                  child: const Text('Add People'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

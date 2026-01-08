import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/announcement_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isPublic = true;
  String _targetAudience = 'all';
  String _priority = 'medium';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      // Debug prints to check user details
      print('🔍 Current User Debug:');
      print('  UID: ${currentUser?.uid}');
      print('  Email: ${currentUser?.email}');
      print('  Name: ${currentUser?.name}');
      print('  Role: ${currentUser?.role.value}');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (currentUser.role != UserRole.student && currentUser.role != UserRole.faculty && currentUser.role != UserRole.admin) {
        throw Exception('User role is ${currentUser.role.value}, but need student, faculty or admin to create announcements');
      }

      await AnnouncementService.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorName: currentUser.name,
        targetAudience: _isPublic ? null : _targetAudience,
        isPublic: _isPublic,
        priority: _priority,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitAnnouncement,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter announcement title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content Field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter announcement content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                maxLength: 1000,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(1000),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Visibility Toggle
              SwitchListTile(
                title: const Text('Public Announcement'),
                subtitle: const Text('Make this announcement visible to everyone'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
              ),
              const SizedBox(height: 8),

              // Target Audience (only if not public)
              if (!_isPublic) ...[
                const Text(
                  'Target Audience',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('All Users'),
                  value: 'all',
                  groupValue: _targetAudience,
                  onChanged: (value) {
                    setState(() => _targetAudience = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Students Only'),
                  value: 'students',
                  groupValue: _targetAudience,
                  onChanged: (value) {
                    setState(() => _targetAudience = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Faculty Only'),
                  value: 'faculty',
                  groupValue: _targetAudience,
                  onChanged: (value) {
                    setState(() => _targetAudience = value!);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Priority
              const Text(
                'Priority',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (value) {
                  setState(() => _priority = value!);
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAnnouncement,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Announcement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


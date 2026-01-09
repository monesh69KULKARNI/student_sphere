import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/announcement_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/announcement_service.dart';
import 'create_announcement_screen.dart';

class AnnouncementsListScreen extends StatefulWidget {
  final bool isPublicOnly;

  const AnnouncementsListScreen({super.key, this.isPublicOnly = false});

  @override
  State<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterPriority = 'all';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 Loading announcements...');
      print('  isPublicOnly: ${widget.isPublicOnly}');
      
      final announcements = widget.isPublicOnly
          ? await AnnouncementService.getAnnouncements(isPublic: true)
          : await AnnouncementService.getUserAnnouncements();

      print('  Fetched ${announcements.length} announcements');
      for (int i = 0; i < announcements.length; i++) {
        print('  ${i + 1}: ${announcements[i].title} by ${announcements[i].authorName}');
      }

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
      
      print('✅ Announcements loaded successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading announcements: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AnnouncementModel> get _filteredAnnouncements {
    var filtered = _announcements;

    print('🔍 Filtering announcements...');
    print('  Total announcements: ${filtered.length}');
    print('  Search query: "$_searchQuery"');
    print('  Priority filter: "$_filterPriority"');

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((announcement) =>
          announcement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          announcement.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
      print('  After search filter: ${filtered.length}');
    }

    // Apply priority filter
    if (_filterPriority != 'all') {
      filtered = filtered.where((announcement) =>
          announcement.priority == _filterPriority
      ).toList();
      print('  After priority filter: ${filtered.length}');
    }

    print('  Final filtered count: ${filtered.length}');
    return filtered;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final canCreateAnnouncement = user?.role == UserRole.faculty || user?.role == UserRole.admin;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPublicOnly ? 'Public Announcements' : 'Announcements'),
        actions: [
          if (!widget.isPublicOnly && canCreateAnnouncement)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAnnouncementScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search announcements...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Priority Filter
                Row(
                  children: [
                    const Text('Priority: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['all', 'urgent', 'high', 'medium', 'low'].map((priority) {
                            final isSelected = _filterPriority == priority;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(priority.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _filterPriority = priority);
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: _getPriorityColor(priority).withValues(alpha: 0.3),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Announcements List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAnnouncements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.announcement_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _filterPriority != 'all'
                                  ? 'No announcements found matching your criteria'
                                  : 'No announcements available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAnnouncements,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            final announcement = _filteredAnnouncements[index];
                            return _AnnouncementCard(
                              announcement: announcement,
                              onTap: () => _showAnnouncementDetails(announcement),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDetails(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(announcement.priority),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                announcement.priority.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                announcement.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    announcement.authorName,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • h:mm a').format(announcement.createdAt),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (!announcement.isPublic) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.group, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      announcement.targetAudience ?? 'Targeted',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and priority
              Row(
                children: [
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(announcement.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      announcement.priority.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content preview
              Text(
                announcement.content,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer with author and date
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      announcement.authorName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}




import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../core/models/resource_model.dart';
import '../../core/services/resource_service.dart';
import 'upload_resource_screen.dart';

class ResourcesListScreen extends StatefulWidget {
  const ResourcesListScreen({super.key});

  @override
  State<ResourcesListScreen> createState() => _ResourcesListScreenState();
}

class _ResourcesListScreenState extends State<ResourcesListScreen> {
  List<ResourceModel> _resources = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterCategory = 'all';
  String _filterSubject = 'all';

  final List<String> _categories = [
    'all',
    'notes',
    'videos',
    'pdfs',
    'slides',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);

    try {
      final resources = await ResourceService.getResources(
        category: _filterCategory == 'all' ? null : _filterCategory,
        subject: _filterSubject == 'all' ? null : _filterSubject,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading resources: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ResourceModel> get _filteredResources {
    var filtered = _resources;

    // Apply search filter (already applied in service, but double-check for UI search)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((resource) =>
          resource.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          resource.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          resource.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Apply category filter
    if (_filterCategory != 'all') {
      filtered = filtered.where((resource) =>
          resource.category == _filterCategory
      ).toList();
    }

    return filtered;
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'presentation':
        return Icons.slideshow;
      case 'spreadsheet':
        return Icons.table_chart;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'archive':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'notes':
        return Colors.blue;
      case 'videos':
        return Colors.red;
      case 'pdfs':
        return Colors.orange;
      case 'slides':
        return Colors.green;
      case 'other':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  Future<void> _downloadResource(ResourceModel resource) async {
    try {
      debugPrint('🔄 Starting download for: ${resource.fileName}');

      // Request storage permissions
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        debugPrint('🔐 Requesting storage permission...');

        // Try modern permission first (Android 10+)
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Fallback to legacy permission
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
        debugPrint('✅ Storage permission granted');
      }

      // Check if file already exists
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final studentSphereDir = Directory('${downloadsDir.path}/StudentSphere');
      final filesDir = Directory('${studentSphereDir.path}/Files');
      final imagesDir = Directory('${studentSphereDir.path}/Images');
      
      String filePath;
      if (_isImageFile(resource.fileType)) {
        filePath = '${imagesDir.path}/${resource.fileName}';
      } else {
        filePath = '${filesDir.path}/${resource.fileName}';
      }

      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        debugPrint('📁 File already exists, opening directly: $filePath');
        await _openFile(filePath, resource.fileType);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File opened from storage'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting download...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Download file from Supabase storage
      debugPrint('📥 Downloading from: ${resource.fileUrl}');
      final response = await http.get(Uri.parse(resource.fileUrl));
      debugPrint('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Create StudentSphere folder in Downloads
        debugPrint('📂 Getting external Downloads directory...');
        if (!await downloadsDir.exists()) {
          debugPrint('📁 Creating external Downloads directory...');
          await downloadsDir.create(recursive: true);
          debugPrint('✅ External Downloads directory created');
        } else {
          debugPrint('ℹ️ External Downloads directory already exists');
        }

        // Create StudentSphere main folder
        if (!await studentSphereDir.exists()) {
          debugPrint('📁 Creating StudentSphere folder...');
          await studentSphereDir.create(recursive: true);
          debugPrint('✅ StudentSphere folder created');
        } else {
          debugPrint('ℹ️ StudentSphere folder already exists');
        }
        debugPrint('📂 StudentSphere directory: ${studentSphereDir.path}');

        if (_isImageFile(resource.fileType)) {
          // Create Images subfolder in StudentSphere
          debugPrint('🖼️ Creating Images folder in StudentSphere...');
          debugPrint('📂 Images directory path: ${imagesDir.path}');

          if (!await imagesDir.exists()) {
            debugPrint('📁 Creating Images directory...');
            await imagesDir.create(recursive: true);
            debugPrint('✅ Images directory created');
          } else {
            debugPrint('ℹ️ Images directory already exists');
          }
          filePath = '${imagesDir.path}/${resource.fileName}';
        } else {
          // Create Files subfolder for other file types
          debugPrint('📄 Creating Files folder in StudentSphere...');
          debugPrint('📂 Files directory path: ${filesDir.path}');

          if (!await filesDir.exists()) {
            debugPrint('📁 Creating Files directory...');
            await filesDir.create(recursive: true);
            debugPrint('✅ Files directory created');
          } else {
            debugPrint('ℹ️ Files directory already exists');
          }
          filePath = '${filesDir.path}/${resource.fileName}';
        }

        debugPrint('💾 Saving file to: $filePath');

        // Save file
        final file = await File(filePath).writeAsBytes(response.bodyBytes);
        debugPrint('✅ File saved successfully: ${file.path}');

        // Increment download count
        await ResourceService.incrementDownloadCount(resource.id);

        // Open the file after download
        await _openFile(filePath, resource.fileType);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isImageFile(resource.fileType)
                  ? 'Image downloaded and opened'
                  : 'File downloaded and opened'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isImageFile(String fileType) {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    final isImage = imageTypes.contains(fileType.toLowerCase());
    debugPrint('🖼️ File type: $fileType, Is image: $isImage');
    return isImage;
  }

  Future<bool> _isFileAlreadyDownloaded(ResourceModel resource) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final studentSphereDir = Directory('${downloadsDir.path}/StudentSphere');
      final filesDir = Directory('${studentSphereDir.path}/Files');
      final imagesDir = Directory('${studentSphereDir.path}/Images');
      
      String filePath;
      if (_isImageFile(resource.fileType)) {
        filePath = '${imagesDir.path}/${resource.fileName}';
      } else {
        filePath = '${filesDir.path}/${resource.fileName}';
      }

      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('❌ Error checking file existence: $e');
      return false;
    }
  }

  Future<void> _openFile(String filePath, String fileType) async {
    try {
      debugPrint('🔍 Attempting to open file: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ File does not exist: $filePath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found in storage'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Use open_file package which handles all the complexity
      debugPrint('🚀 Opening file with open_file package');
      final result = await OpenFile.open(filePath);
      
      debugPrint('📊 File open result: ${result.type}');
      debugPrint('📊 File open message: ${result.message}');
      
      if (result.type == ResultType.done) {
        debugPrint('✅ File opened successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File opened successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (result.type == ResultType.fileNotFound) {
        debugPrint('❌ File not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found in storage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (result.type == ResultType.noAppToOpen) {
        debugPrint('❌ No app available to open this file type');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No app available to open ${fileType.toUpperCase()} files'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (result.type == ResultType.permissionDenied) {
        debugPrint('❌ Permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied to open file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to open file: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open file: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResourceDetails(ResourceModel resource) async {
    // Increment view count when opening details
    await ResourceService.incrementViewCount(resource.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resource.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('By ${resource.uploaderName}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(resource.uploadedAt)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(resource.category.toUpperCase()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(resource.subject),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.book, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(resource.course),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.storage, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(resource.fileSizeFormatted),
                ],
              ),
              const SizedBox(height: 8),
              if (resource.tags.isNotEmpty) ...[
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: resource.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey.shade200,
                  )).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.visibility, color: Colors.blue.shade600),
                      const SizedBox(height: 4),
                      Text('${resource.viewCount}'),
                      const Text('Views', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.download, color: Colors.green.shade600),
                      const SizedBox(height: 4),
                      Text('${resource.downloadCount}'),
                      const Text('Downloads', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResource(resource);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Resources',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadResourceScreen(),
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
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search resources...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Category Filter
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _filterCategory == category;
                      return FilterChip(
                        label: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filterCategory = category;
                          });
                          _loadResources();
                        },
                        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        selectedColor: colorScheme.secondaryContainer,
                        side: BorderSide(
                          color: isSelected
                            ? colorScheme.secondary.withOpacity(0.3)
                            : Colors.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Resources List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResources.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 80,
                              color: colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _filterCategory != 'all'
                                  ? 'No resources found'
                                  : 'No resources available',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _filterCategory != 'all'
                                  ? 'Try adjusting your filters'
                                  : 'Be the first to share a resource',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadResources,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredResources.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final resource = _filteredResources[index];
                            return _buildResourceCard(resource, theme, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(ResourceModel resource, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(resource.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(resource.fileType),
                    color: _getCategoryColor(resource.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.uploaderName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(resource.uploadedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(resource.category).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              resource.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _getCategoryColor(resource.category),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () => _showResourceDetails(resource),
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resource.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Metadata Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetaChip(
                  icon: Icons.school_outlined,
                  label: resource.subject,
                  colorScheme: colorScheme,
                ),
                _buildMetaChip(
                  icon: Icons.book_outlined,
                  label: resource.course,
                  colorScheme: colorScheme,
                ),
                _buildMetaChip(
                  icon: Icons.storage_outlined,
                  label: resource.fileSizeFormatted,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          // Stats Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatItem(
                  icon: Icons.visibility_outlined,
                  count: resource.viewCount,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.download_outlined,
                  count: resource.downloadCount,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Download Button Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<bool>(
              future: _isFileAlreadyDownloaded(resource),
              builder: (context, snapshot) {
                final isDownloaded = snapshot.data ?? false;
                
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _downloadResource(resource),
                    icon: Icon(
                      isDownloaded ? Icons.open_in_new_rounded : Icons.download_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isDownloaded ? 'Open' : 'Download',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDownloaded ? Colors.blue : null,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

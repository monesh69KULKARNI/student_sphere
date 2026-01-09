import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
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
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          debugPrint('📁 Creating external Downloads directory...');
          await downloadsDir.create(recursive: true);
          debugPrint('✅ External Downloads directory created');
        } else {
          debugPrint('ℹ️ External Downloads directory already exists');
        }
        
        // Create StudentSphere main folder
        final studentSphereDir = Directory('${downloadsDir.path}/StudentSphere');
        if (!await studentSphereDir.exists()) {
          debugPrint('📁 Creating StudentSphere folder...');
          await studentSphereDir.create(recursive: true);
          debugPrint('✅ StudentSphere folder created');
        } else {
          debugPrint('ℹ️ StudentSphere folder already exists');
        }
        debugPrint('📂 StudentSphere directory: ${studentSphereDir.path}');
        
        String filePath;
        if (_isImageFile(resource.fileType)) {
          // Create Images subfolder in StudentSphere
          debugPrint('🖼️ Creating Images folder in StudentSphere...');
          final imagesDir = Directory('${studentSphereDir.path}/Images');
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
          final filesDir = Directory('${studentSphereDir.path}/Files');
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isImageFile(resource.fileType) 
                  ? 'Image saved to StudentSphere/Images folder' 
                  : 'File saved to StudentSphere/Files folder'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search resources...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Category Filter
                Row(
                  children: [
                    const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category.toUpperCase()),
                                selected: _filterCategory == category,
                                onSelected: (selected) {
                                  setState(() {
                                    _filterCategory = category;
                                  });
                                  _loadResources();
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: _getCategoryColor(category).withValues(alpha: 0.3),
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
                              Icons.folder_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _filterCategory != 'all'
                                  ? 'No resources found matching your criteria'
                                  : 'No resources available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadResources,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredResources.length,
                          itemBuilder: (context, index) {
                            final resource = _filteredResources[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(resource.category).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getFileIcon(resource.fileType),
                                    color: _getCategoryColor(resource.category),
                                  ),
                                ),
                                title: Text(
                                  resource.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      resource.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          resource.uploaderName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd').format(resource.uploadedAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(resource.category),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        resource.category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resource.fileSizeFormatted,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showResourceDetails(resource),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


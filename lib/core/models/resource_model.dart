class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String category; // notes, videos, pdfs, slides, other
  final String subject;
  final String course;
  final String uploaderId;
  final String uploaderName;
  final String fileUrl; // Supabase Storage URL
  final String fileName;
  final int fileSize; // in bytes
  final String fileType; // pdf, mp4, docx, etc.
  final DateTime uploadedAt;
  final bool isPublic;
  final List<String> tags;
  final int downloadCount;
  final int viewCount;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subject,
    required this.course,
    required this.uploaderId,
    required this.uploaderName,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
    this.isPublic = true,
    required this.tags,
    this.downloadCount = 0,
    this.viewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'subject': subject,
      'course': course,
      'uploader_id': uploaderId,
      'uploader_name': uploaderName,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
      'is_public': isPublic,
      'tags': tags,
      'download_count': downloadCount,
      'view_count': viewCount,
    };
  }

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      course: map['course']?.toString() ?? '',
      uploaderId: map['uploader_id']?.toString() ?? '',
      uploaderName: map['uploader_name']?.toString() ?? '',
      fileUrl: map['file_url']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? '',
      fileSize: (map['file_size'] as int?) ?? 0,
      fileType: map['file_type']?.toString() ?? '',
      uploadedAt: map['uploaded_at'] != null
          ? DateTime.parse(map['uploaded_at'] as String)
          : DateTime.now(),
      isPublic: map['is_public'] as bool? ?? true,
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      downloadCount: (map['download_count'] as int?) ?? 0,
      viewCount: (map['view_count'] as int?) ?? 0,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}


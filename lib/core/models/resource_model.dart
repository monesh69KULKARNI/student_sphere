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
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isPublic': isPublic,
      'tags': tags,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
    };
  }

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      subject: map['subject'] as String,
      course: map['course'] as String,
      uploaderId: map['uploaderId'] as String,
      uploaderName: map['uploaderName'] as String,
      fileUrl: map['fileUrl'] as String,
      fileName: map['fileName'] as String,
      fileSize: map['fileSize'] as int,
      fileType: map['fileType'] as String,
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      isPublic: map['isPublic'] as bool? ?? true,
      tags: List<String>.from(map['tags'] as List? ?? []),
      downloadCount: map['downloadCount'] as int? ?? 0,
      viewCount: map['viewCount'] as int? ?? 0,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}


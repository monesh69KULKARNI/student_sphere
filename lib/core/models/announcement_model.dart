class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final String? targetAudience; // all, students, faculty, specific_department
  final List<String> readBy;
  final String priority; // low, medium, high, urgent
  final String? attachmentUrl;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isPublic = true,
    this.targetAudience,
    required this.readBy,
    this.priority = 'medium',
    this.attachmentUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPublic': isPublic,
      'targetAudience': targetAudience,
      'readBy': readBy,
      'priority': priority,
      'attachmentUrl': attachmentUrl,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    print('🔍 AnnouncementModel.fromMap()');
    print('  Raw map keys: ${map.keys.toList()}');
    print('  Raw map values: ${map.entries.map((e) => '${e.key}: ${e.value} (${e.value.runtimeType})').toList()}');
    
    try {
      final announcement = AnnouncementModel(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        authorId: map['authorId']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
        isPublic: map['isPublic'] as bool? ?? true,
        targetAudience: map['targetAudience']?.toString(),
        readBy: (map['readBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
        priority: map['priority']?.toString() ?? 'medium',
        attachmentUrl: map['attachmentUrl']?.toString(),
      );
      
      print('  ✅ Successfully created AnnouncementModel');
      return announcement;
    } catch (e) {
      print('  ❌ Error creating AnnouncementModel: $e');
      print('  Problematic field values:');
      map.forEach((key, value) {
        print('    $key: $value (${value.runtimeType})');
      });
      rethrow;
    }
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}


class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String type; // academic, sports, cultural, leadership, volunteer
  final String studentId;
  final String studentName;
  final String awardedBy; // faculty/admin name
  final String awardedById;
  final DateTime awardedAt;
  final String? certificateUrl;
  final String? imageUrl;
  final String level; // college, state, national, international
  final bool isVerified;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.studentId,
    required this.studentName,
    required this.awardedBy,
    required this.awardedById,
    required this.awardedAt,
    this.certificateUrl,
    this.imageUrl,
    this.level = 'college',
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'studentId': studentId,
      'studentName': studentName,
      'awardedBy': awardedBy,
      'awardedById': awardedById,
      'awardedAt': awardedAt.toIso8601String(),
      'certificateUrl': certificateUrl,
      'imageUrl': imageUrl,
      'level': level,
      'isVerified': isVerified,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      awardedBy: map['awardedBy'] as String,
      awardedById: map['awardedById'] as String,
      awardedAt: DateTime.parse(map['awardedAt'] as String),
      certificateUrl: map['certificateUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
      level: map['level'] as String? ?? 'college',
      isVerified: map['isVerified'] as bool? ?? false,
    );
  }
}


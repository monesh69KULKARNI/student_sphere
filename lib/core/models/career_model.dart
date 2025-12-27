class CareerModel {
  final String id;
  final String title;
  final String description;
  final String type; // internship, job, workshop, seminar
  final String company;
  final String? location;
  final String? salary;
  final String? duration;
  final DateTime postedAt;
  final DateTime? deadline;
  final String postedBy; // faculty/admin name
  final String postedById;
  final List<String> requirements;
  final List<String> tags;
  final String? applicationLink;
  final String? contactEmail;
  final bool isActive;
  final int viewCount;
  final int applicationCount;

  CareerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.company,
    this.location,
    this.salary,
    this.duration,
    required this.postedAt,
    this.deadline,
    required this.postedBy,
    required this.postedById,
    required this.requirements,
    required this.tags,
    this.applicationLink,
    this.contactEmail,
    this.isActive = true,
    this.viewCount = 0,
    this.applicationCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'company': company,
      'location': location,
      'salary': salary,
      'duration': duration,
      'postedAt': postedAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'postedBy': postedBy,
      'postedById': postedById,
      'requirements': requirements,
      'tags': tags,
      'applicationLink': applicationLink,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
    };
  }

  factory CareerModel.fromMap(Map<String, dynamic> map) {
    return CareerModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      company: map['company'] as String,
      location: map['location'] as String?,
      salary: map['salary'] as String?,
      duration: map['duration'] as String?,
      postedAt: DateTime.parse(map['postedAt'] as String),
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      postedBy: map['postedBy'] as String,
      postedById: map['postedById'] as String,
      requirements: List<String>.from(map['requirements'] as List? ?? []),
      tags: List<String>.from(map['tags'] as List? ?? []),
      applicationLink: map['applicationLink'] as String?,
      contactEmail: map['contactEmail'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      viewCount: map['viewCount'] as int? ?? 0,
      applicationCount: map['applicationCount'] as int? ?? 0,
    );
  }

  bool get isExpired => deadline != null && deadline!.isBefore(DateTime.now());
}


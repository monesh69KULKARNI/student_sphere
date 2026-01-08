class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String organizerId;
  final String organizerName;
  final int maxParticipants;
  final List<String> registeredParticipants;
  final List<String> volunteers;
  final bool requiresVolunteers;
  final int maxVolunteers;
  final String? imageUrl;
  final bool isPublic;
  final String category; // academic, cultural, sports, workshop, etc.
  final List<String> allowedRoles; // Who can register: ['student', 'faculty', 'admin']
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    required this.maxParticipants,
    required this.registeredParticipants,
    required this.volunteers,
    required this.requiresVolunteers,
    this.maxVolunteers = 0,
    this.imageUrl,
    this.isPublic = true,
    required this.category,
    required this.allowedRoles,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'maxParticipants': maxParticipants,
      'registeredParticipants': registeredParticipants,
      'volunteers': volunteers,
      'requiresVolunteers': requiresVolunteers,
      'maxVolunteers': maxVolunteers,
      'imageUrl': imageUrl,
      'isPublic': isPublic,
      'category': category,
      'allowedRoles': allowedRoles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      location: map['location'] as String,
      organizerId: map['organizerId'] as String,
      organizerName: map['organizerName'] as String,
      maxParticipants: map['maxParticipants'] as int,
      registeredParticipants: List<String>.from(map['registeredParticipants'] as List? ?? []),
      volunteers: List<String>.from(map['volunteers'] as List? ?? []),
      requiresVolunteers: map['requiresVolunteers'] as bool? ?? false,
      maxVolunteers: map['maxVolunteers'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
      isPublic: map['isPublic'] as bool? ?? true,
      category: map['category'] as String? ?? 'general',
      allowedRoles: List<String>.from(map['allowedRoles'] as List? ?? ['student', 'faculty', 'admin']),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  bool get isFull => registeredParticipants.length >= maxParticipants;
  bool get volunteersFull => requiresVolunteers && volunteers.length >= maxVolunteers;
  int get availableSpots => maxParticipants - registeredParticipants.length;
  int get availableVolunteerSpots => requiresVolunteers ? maxVolunteers - volunteers.length : 0;
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isPast => endDate.isBefore(DateTime.now());

  // Check if a specific role is allowed to register
  bool isRoleAllowed(String role) {
    return allowedRoles.contains(role);
  }

  // Get display text for allowed roles
  String get allowedRolesDisplay {
    if (allowedRoles.length == 3) return 'All roles';
    if (allowedRoles.length == 1) return allowedRoles.first.capitalize();
    return allowedRoles.map((r) => r.capitalize()).join(' & ');
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}


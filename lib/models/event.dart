class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizer;
  final int maxParticipants;
  final List<String> registeredParticipants;
  final List<String> volunteers;
  final bool requiresVolunteers;
  final int maxVolunteers;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizer,
    required this.maxParticipants,
    required this.registeredParticipants,
    required this.volunteers,
    required this.requiresVolunteers,
    this.maxVolunteers = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'organizer': organizer,
      'maxParticipants': maxParticipants,
      'registeredParticipants': registeredParticipants,
      'volunteers': volunteers,
      'requiresVolunteers': requiresVolunteers,
      'maxVolunteers': maxVolunteers,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      organizer: json['organizer'] as String,
      maxParticipants: json['maxParticipants'] as int,
      registeredParticipants: List<String>.from(json['registeredParticipants'] as List),
      volunteers: List<String>.from(json['volunteers'] as List),
      requiresVolunteers: json['requiresVolunteers'] as bool,
      maxVolunteers: json['maxVolunteers'] as int? ?? 0,
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? organizer,
    int? maxParticipants,
    List<String>? registeredParticipants,
    List<String>? volunteers,
    bool? requiresVolunteers,
    int? maxVolunteers,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredParticipants: registeredParticipants ?? this.registeredParticipants,
      volunteers: volunteers ?? this.volunteers,
      requiresVolunteers: requiresVolunteers ?? this.requiresVolunteers,
      maxVolunteers: maxVolunteers ?? this.maxVolunteers,
    );
  }

  bool get isFull => registeredParticipants.length >= maxParticipants;
  bool get volunteersFull => requiresVolunteers && volunteers.length >= maxVolunteers;
  int get availableSpots => maxParticipants - registeredParticipants.length;
  int get availableVolunteerSpots => requiresVolunteers ? maxVolunteers - volunteers.length : 0;
}


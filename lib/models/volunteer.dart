class Volunteer {
  final String id;
  final String eventId;
  final String studentName;
  final String studentId;
  final String email;
  final String phone;
  final String role;
  final DateTime registeredAt;
  final String status; // 'pending', 'approved', 'rejected'

  Volunteer({
    required this.id,
    required this.eventId,
    required this.studentName,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.role,
    required this.registeredAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'studentName': studentName,
      'studentId': studentId,
      'email': email,
      'phone': phone,
      'role': role,
      'registeredAt': registeredAt.toIso8601String(),
      'status': status,
    };
  }

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      studentName: json['studentName'] as String,
      studentId: json['studentId'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Volunteer copyWith({
    String? id,
    String? eventId,
    String? studentName,
    String? studentId,
    String? email,
    String? phone,
    String? role,
    DateTime? registeredAt,
    String? status,
  }) {
    return Volunteer(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
    );
  }
}


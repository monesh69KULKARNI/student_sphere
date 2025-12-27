class User {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String department;
  final String year;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    required this.year,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'department': department,
      'year': year,
      'phone': phone,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      studentId: json['studentId'] as String,
      department: json['department'] as String,
      year: json['year'] as String,
      phone: json['phone'] as String?,
    );
  }
}


class Note {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final String subject;
  final String course;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int likes;
  final List<String> likedBy;
  final String? filePath;
  final String? fileName;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.subject,
    required this.course,
    required this.createdAt,
    this.updatedAt,
    required this.tags,
    this.likes = 0,
    required this.likedBy,
    this.filePath,
    this.fileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'authorId': authorId,
      'subject': subject,
      'course': course,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'likes': likes,
      'likedBy': likedBy,
      'filePath': filePath,
      'fileName': fileName,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      authorId: json['authorId'] as String,
      subject: json['subject'] as String,
      course: json['course'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      tags: List<String>.from(json['tags'] as List),
      likes: json['likes'] as int? ?? 0,
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? author,
    String? authorId,
    String? subject,
    String? course,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? likes,
    List<String>? likedBy,
    String? filePath,
    String? fileName,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      subject: subject ?? this.subject,
      course: course ?? this.course,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
    );
  }
}


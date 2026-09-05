/// Domain model for Teacher notes
class TeacherNote {
  final String id;
  final String lessonId;
  final int gradeClass;
  final String subject;
  final String title;
  final String hindiContent;
  final String santaliContent;
  final String? santaliOlChiki;
  final String author;
  final bool isDraft;
  final bool isApproved;
  final bool isPublished;
  final DateTime createdAt;

  TeacherNote({
    required this.id,
    required this.lessonId,
    this.gradeClass = 1,
    this.subject = 'Language',
    required this.title,
    required this.hindiContent,
    required this.santaliContent,
    this.santaliOlChiki,
    this.author = 'Teacher',
    this.isDraft = false,
    this.isApproved = false,
    this.isPublished = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TeacherNote.fromJson(
    Map<String, dynamic> json, {
    String? lessonId,
    int? gradeClass,
    String? subject,
  }) {
    return TeacherNote(
      id: json['id'] as String? ?? 'note_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: json['lessonId'] as String? ?? lessonId ?? 'curr_c1_lang_01',
      gradeClass: json['gradeClass'] as int? ?? gradeClass ?? 1,
      subject: json['subject'] as String? ?? subject ?? 'Language',
      title: json['title'] as String? ?? '',
      hindiContent: json['hindiContent'] as String? ?? '',
      santaliContent: json['santaliContent'] as String? ?? '',
      santaliOlChiki: json['santaliOlChiki'] as String?,
      author: json['author'] as String? ?? 'Teacher',
      isDraft: json['isDraft'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'gradeClass': gradeClass,
      'subject': subject,
      'title': title,
      'hindiContent': hindiContent,
      'santaliContent': santaliContent,
      'santaliOlChiki': santaliOlChiki,
      'author': author,
      'isDraft': isDraft,
      'isApproved': isApproved,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TeacherNote copyWith({
    String? id,
    String? lessonId,
    int? gradeClass,
    String? subject,
    String? title,
    String? hindiContent,
    String? santaliContent,
    String? santaliOlChiki,
    String? author,
    bool? isDraft,
    bool? isApproved,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return TeacherNote(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      gradeClass: gradeClass ?? this.gradeClass,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      hindiContent: hindiContent ?? this.hindiContent,
      santaliContent: santaliContent ?? this.santaliContent,
      santaliOlChiki: santaliOlChiki ?? this.santaliOlChiki,
      author: author ?? this.author,
      isDraft: isDraft ?? this.isDraft,
      isApproved: isApproved ?? this.isApproved,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

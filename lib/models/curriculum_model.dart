import 'note_model.dart';

/// Domain model for curriculum lesson across classes 1-5 and subjects
class CurriculumLesson {
  final String id;
  final int gradeClass; // 1, 2, 3, 4, 5
  final String subject; // Language, Mathematics, EVS / General Knowledge
  final String titleHindi;
  final String titleSantali;
  final String description;
  final List<TeacherNote> notes;

  CurriculumLesson({
    required this.id,
    required this.gradeClass,
    required this.subject,
    required this.titleHindi,
    required this.titleSantali,
    required this.description,
    this.notes = const [],
  });

  factory CurriculumLesson.fromJson(Map<String, dynamic> json) {
    var rawNotes = json['notes'] as List<dynamic>? ?? [];
    List<TeacherNote> parsedNotes = rawNotes
        .map((n) => TeacherNote.fromJson(
              n as Map<String, dynamic>,
              lessonId: json['id'] as String?,
              gradeClass: json['gradeClass'] as int?,
              subject: json['subject'] as String?,
            ))
        .toList();

    return CurriculumLesson(
      id: json['id'] as String? ?? '',
      gradeClass: json['gradeClass'] as int? ?? 1,
      subject: json['subject'] as String? ?? 'Language',
      titleHindi: json['titleHindi'] as String? ?? '',
      titleSantali: json['titleSantali'] as String? ?? '',
      description: json['description'] as String? ?? '',
      notes: parsedNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gradeClass': gradeClass,
      'subject': subject,
      'titleHindi': titleHindi,
      'titleSantali': titleSantali,
      'description': description,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }
}

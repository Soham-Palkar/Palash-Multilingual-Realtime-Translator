/// Worksheet question domain model
class WorksheetQuestion {
  final String id;
  final String questionHindi;
  final String questionSantali;
  final String? image;
  final List<String> optionsHindi;
  final List<String> optionsSantali;
  final int correctIndex;
  final String explanationHindi;
  final String explanationSantali;

  WorksheetQuestion({
    required this.id,
    required this.questionHindi,
    required this.questionSantali,
    this.image,
    required this.optionsHindi,
    required this.optionsSantali,
    required this.correctIndex,
    required this.explanationHindi,
    required this.explanationSantali,
  });

  factory WorksheetQuestion.fromJson(Map<String, dynamic> json) {
    return WorksheetQuestion(
      id: json['id'] as String? ?? 'wq_${DateTime.now().millisecondsSinceEpoch}',
      questionHindi: json['questionHindi'] as String? ?? '',
      questionSantali: json['questionSantali'] as String? ?? '',
      image: json['image'] as String?,
      optionsHindi: (json['optionsHindi'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      optionsSantali: (json['optionsSantali'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanationHindi: json['explanationHindi'] as String? ?? '',
      explanationSantali: json['explanationSantali'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionHindi': questionHindi,
      'questionSantali': questionSantali,
      'image': image,
      'optionsHindi': optionsHindi,
      'optionsSantali': optionsSantali,
      'correctIndex': correctIndex,
      'explanationHindi': explanationHindi,
      'explanationSantali': explanationSantali,
    };
  }
}

class WorksheetItem {
  final String id;
  final String titleHindi;
  final String titleSantali;
  final int gradeClass;
  final String subject;
  final List<WorksheetQuestion> questions;

  WorksheetItem({
    required this.id,
    required this.titleHindi,
    required this.titleSantali,
    required this.gradeClass,
    required this.subject,
    required this.questions,
  });

  factory WorksheetItem.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return WorksheetItem(
      id: json['id'] as String? ?? '',
      titleHindi: json['titleHindi'] as String? ?? '',
      titleSantali: json['titleSantali'] as String? ?? '',
      gradeClass: json['gradeClass'] as int? ?? 1,
      subject: json['subject'] as String? ?? 'General Knowledge',
      questions: rawQuestions
          .map((q) => WorksheetQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleHindi': titleHindi,
      'titleSantali': titleSantali,
      'gradeClass': gradeClass,
      'subject': subject,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

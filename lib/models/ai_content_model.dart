import 'flashcard_model.dart';

enum ContentState { draft, approved, published }

/// Generated AI content item wrapper for Teacher Studio review workflow
class AIGeneratedContent {
  final String id;
  final String noteId;
  final String noteTitle;
  final String explanationHindi;
  final String explanationSantali;
  final String translationSantali;
  final List<FlashcardItem> flashcards;
  final List<AIPracticeQuestion> practiceQuestions;
  final List<AIActivityIdea> activities;
  ContentState state;
  final DateTime createdAt;

  AIGeneratedContent({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.explanationHindi,
    required this.explanationSantali,
    required this.translationSantali,
    this.flashcards = const [],
    this.practiceQuestions = const [],
    this.activities = const [],
    this.state = ContentState.draft,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AIGeneratedContent copyWith({
    String? id,
    String? noteId,
    String? noteTitle,
    String? explanationHindi,
    String? explanationSantali,
    String? translationSantali,
    List<FlashcardItem>? flashcards,
    List<AIPracticeQuestion>? practiceQuestions,
    List<AIActivityIdea>? activities,
    ContentState? state,
    DateTime? createdAt,
  }) {
    return AIGeneratedContent(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      explanationHindi: explanationHindi ?? this.explanationHindi,
      explanationSantali: explanationSantali ?? this.explanationSantali,
      translationSantali: translationSantali ?? this.translationSantali,
      flashcards: flashcards ?? this.flashcards,
      practiceQuestions: practiceQuestions ?? this.practiceQuestions,
      activities: activities ?? this.activities,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AIPracticeQuestion {
  final String questionHindi;
  final String questionSantali;
  final List<String> optionsHindi;
  final List<String> optionsSantali;
  final int correctIndex;
  final String explanation;

  AIPracticeQuestion({
    required this.questionHindi,
    required this.questionSantali,
    required this.optionsHindi,
    required this.optionsSantali,
    required this.correctIndex,
    required this.explanation,
  });
}

class AIActivityIdea {
  final String titleHindi;
  final String titleSantali;
  final String descriptionHindi;
  final String descriptionSantali;

  AIActivityIdea({
    required this.titleHindi,
    required this.titleSantali,
    required this.descriptionHindi,
    required this.descriptionSantali,
  });
}

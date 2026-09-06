/// Unified content model for various educational items
library;

enum ContentType {
  flashcard,
  note,
  worksheet,
  game,
  activity,
  story,
  curriculum,
}

/// Base class that defines common fields for all content types.
abstract class ContentBase {
  final String id;
  final ContentType type;
  final bool isDraft;
  final bool isPublished;
  final DateTime createdAt;

  ContentBase({
    required this.id,
    required this.type,
    this.isDraft = false,
    this.isPublished = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson();
}

/// Helper mixin to add a title/description field for items that need it.
mixin TitledContent on ContentBase {
  String get title;
  String get description;
}
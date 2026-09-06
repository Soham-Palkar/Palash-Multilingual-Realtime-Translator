/// Domain model for flashcards (both default offline and teacher-created/AI-generated)
class FlashcardItem {
  final String id;
  final String category; // Language, Mathematics, General Knowledge
  final String subcategory; // Alphabets, Words, Numbers, Animals, etc.
  final String hindi;
  final String santali;
  final String? santaliOlChiki;
  final String? image;
  final String? iconName;
  final String? pronunciation;
  final String? linguistNote;
  final bool isDefault;
  final bool isTeacherCreated;
  final bool isPublished;
  final DateTime createdAt;

  FlashcardItem({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.hindi,
    required this.santali,
    this.santaliOlChiki,
    this.image,
    this.iconName,
    this.pronunciation,
    this.linguistNote,
    this.isDefault = true,
    this.isTeacherCreated = false,
    this.isPublished = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id'] as String? ?? 'fc_${DateTime.now().millisecondsSinceEpoch}',
      category: json['category'] as String? ?? 'General Knowledge',
      subcategory: json['subcategory'] as String? ?? 'Vocabulary',
      hindi: json['hindi'] as String? ?? '',
      santali: json['santali'] as String? ?? '',
      santaliOlChiki: json['santaliOlChiki'] as String?,
      image: json['image'] as String?,
      iconName: json['iconName'] as String?,
      pronunciation: json['pronunciation'] as String?,
      linguistNote: json['linguistNote'] as String?,
      isDefault: json['isDefault'] as bool? ?? true,
      isTeacherCreated: json['isTeacherCreated'] as bool? ?? false,
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'hindi': hindi,
      'santali': santali,
      'santaliOlChiki': santaliOlChiki,
      'image': image,
      'iconName': iconName,
      'pronunciation': pronunciation,
      'linguistNote': linguistNote,
      'isDefault': isDefault,
      'isTeacherCreated': isTeacherCreated,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FlashcardItem copyWith({
    String? id,
    String? category,
    String? subcategory,
    String? hindi,
    String? santali,
    String? santaliOlChiki,
    String? image,
    String? iconName,
    String? pronunciation,
    String? linguistNote,
    bool? isDefault,
    bool? isTeacherCreated,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return FlashcardItem(
      id: id ?? this.id,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      hindi: hindi ?? this.hindi,
      santali: santali ?? this.santali,
      santaliOlChiki: santaliOlChiki ?? this.santaliOlChiki,
      image: image ?? this.image,
      iconName: iconName ?? this.iconName,
      pronunciation: pronunciation ?? this.pronunciation,
      linguistNote: linguistNote ?? this.linguistNote,
      isDefault: isDefault ?? this.isDefault,
      isTeacherCreated: isTeacherCreated ?? this.isTeacherCreated,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

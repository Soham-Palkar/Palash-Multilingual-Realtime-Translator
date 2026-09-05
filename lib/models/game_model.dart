/// Domain models for Student Educational Games
class GameItem {
  final String id;
  final String category; // Language, Mathematics, Memory
  final String titleHindi;
  final String titleSantali;
  final String descriptionHindi;
  final String descriptionSantali;
  final String gameType; // match_word_image, letter_matching, arrange_sentence, listen_choose, count_objects, shape_matching, memory_cards
  final bool isAvailableOffline;
  final bool isComingSoon;
  final Map<String, dynamic> rawData;

  GameItem({
    required this.id,
    required this.category,
    required this.titleHindi,
    required this.titleSantali,
    required this.descriptionHindi,
    required this.descriptionSantali,
    required this.gameType,
    this.isAvailableOffline = true,
    this.isComingSoon = false,
    this.rawData = const {},
  });

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'Language',
      titleHindi: json['titleHindi'] as String? ?? '',
      titleSantali: json['titleSantali'] as String? ?? '',
      descriptionHindi: json['descriptionHindi'] as String? ?? '',
      descriptionSantali: json['descriptionSantali'] as String? ?? '',
      gameType: json['gameType'] as String? ?? '',
      isAvailableOffline: json['isAvailableOffline'] as bool? ?? true,
      isComingSoon: json['isComingSoon'] as bool? ?? false,
      rawData: json,
    );
  }
}

/// Domain models for Student Activities
class ActivityItem {
  final String id;
  final String titleHindi;
  final String titleSantali;
  final String category;
  final String type; // identify_object, match_concepts, arrange_objects
  final String instructionsHindi;
  final String instructionsSantali;
  final Map<String, dynamic> rawData;

  ActivityItem({
    required this.id,
    required this.titleHindi,
    required this.titleSantali,
    required this.category,
    required this.type,
    required this.instructionsHindi,
    required this.instructionsSantali,
    this.rawData = const {},
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String? ?? '',
      titleHindi: json['titleHindi'] as String? ?? '',
      titleSantali: json['titleSantali'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      type: json['type'] as String? ?? 'identify_object',
      instructionsHindi: json['instructionsHindi'] as String? ?? '',
      instructionsSantali: json['instructionsSantali'] as String? ?? '',
      rawData: json,
    );
  }
}

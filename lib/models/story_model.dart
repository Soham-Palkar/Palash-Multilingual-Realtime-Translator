/// Domain models for bilingual illustrated stories
class StoryPage {
  final int pageNumber;
  final String? image;
  final String hindiText;
  final String santaliText;
  final String? santaliPhonetic;

  StoryPage({
    required this.pageNumber,
    this.image,
    required this.hindiText,
    required this.santaliText,
    this.santaliPhonetic,
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      pageNumber: json['pageNumber'] as int? ?? 1,
      image: json['image'] as String?,
      hindiText: json['hindiText'] as String? ?? '',
      santaliText: json['santaliText'] as String? ?? '',
      santaliPhonetic: json['santaliPhonetic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'image': image,
      'hindiText': hindiText,
      'santaliText': santaliText,
      'santaliPhonetic': santaliPhonetic,
    };
  }
}

class StoryItem {
  final String id;
  final String titleHindi;
  final String titleSantali;
  final String coverImage;
  final String author;
  final List<StoryPage> pages;

  StoryItem({
    required this.id,
    required this.titleHindi,
    required this.titleSantali,
    required this.coverImage,
    required this.author,
    required this.pages,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    var rawPages = json['pages'] as List<dynamic>? ?? [];
    return StoryItem(
      id: json['id'] as String? ?? '',
      titleHindi: json['titleHindi'] as String? ?? '',
      titleSantali: json['titleSantali'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      author: json['author'] as String? ?? 'Palash Tales',
      pages: rawPages
          .map((p) => StoryPage.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleHindi': titleHindi,
      'titleSantali': titleSantali,
      'coverImage': coverImage,
      'author': author,
      'pages': pages.map((p) => p.toJson()).toList(),
    };
  }
}

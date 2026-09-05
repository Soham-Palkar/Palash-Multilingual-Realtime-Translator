/// Domain model for Live Translation requests and responses
class TranslationResult {
  final String sourceText;
  final String translatedSantali;
  final String? translatedOlChiki;
  final String? phoneticRoman;
  final double confidence;
  final bool isOffline;
  final DateTime timestamp;

  TranslationResult({
    required this.sourceText,
    required this.translatedSantali,
    this.translatedOlChiki,
    this.phoneticRoman,
    this.confidence = 0.95,
    this.isOffline = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class VoiceTranslationResult {
  final String transcribedHindi;
  final String translatedSantali;
  final String? translatedOlChiki;
  final String? phoneticRoman;
  final double confidence;

  VoiceTranslationResult({
    required this.transcribedHindi,
    required this.translatedSantali,
    this.translatedOlChiki,
    this.phoneticRoman,
    this.confidence = 0.92,
  });
}

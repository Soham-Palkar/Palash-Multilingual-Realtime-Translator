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

/// Domain model for Teacher Live Translation audio recordings
class TranslationRecording {
  final String id;
  final String audioPath;
  final String teacherId;
  final DateTime createdAt;

  TranslationRecording({
    required this.id,
    required this.audioPath,
    required this.teacherId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioPath': audioPath,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TranslationRecording.fromJson(Map<String, dynamic> json) {
    return TranslationRecording(
      id: json['id'] as String,
      audioPath: json['audioPath'] as String,
      teacherId: json['teacherId'] as String? ?? 'teacher',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

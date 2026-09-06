import '../models/translation_model.dart';
import 'translation_service.dart';

/// Mock Translation Service
/// Demonstrates the live speech & text translation flow with realistic Santali responses.
class MockTranslationService implements TranslationService {
  final List<TranslationResult> _sessionHistory = [];

  // Vernacular dictionary for instant realistic translation responses
  static const Map<String, Map<String, String>> _dictionary = {
    'नमस्ते': {
      'santali': 'ᱡᱚᱦᱟᱨ (Johar)',
      'olChiki': 'ᱡᱚᱦᱟᱨ',
      'phonetic': 'Johar',
    },
    'आप कैसे हैं': {
      'santali': 'ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱜ ᱵᱤᱱᱟ? (Ched leka menag bina?)',
      'olChiki': 'ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱜ ᱵᱤᱱᱟ?',
      'phonetic': 'Ched leka menag bina?',
    },
    'किताब खोलो': {
      'santali': 'ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡᱽ ᱢᱮ (Puthi jhij me)',
      'olChiki': 'ᱯᱩᱛᱷᱤ ᱡᱷᱤᱡᱽ ᱢᱮ',
      'phonetic': 'Puthi jhij me',
    },
    'बैठ जाइए': {
      'santali': 'ᱫᱩᱲᱩᱵᱽ ᱢᱮ / ᱫᱩᱲᱩᱵᱽ ᱵᱤᱱ (Durub me)',
      'olChiki': 'ᱫᱩᱲᱩᱵᱽ ᱢᱮ',
      'phonetic': 'Durub me',
    },
    'आज हम गणित सीखेंगे': {
      'santali': 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱪᱮᱫᱚᱜᱼᱟ (Tehen abo lekha bon chedog-a)',
      'olChiki': 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱞᱮᱠᱷᱟ ᱵᱚᱱ ᱪᱮᱫᱚᱜᱼᱟ',
      'phonetic': 'Tehen abo lekha bon chedog-a',
    },
    'पेड़ हमें फल और छाया देते हैं': {
      'santali': 'ᱫᱟᱨᱮ ᱟᱵᱚ ᱡᱚ ᱟᱨ ᱩᱢᱩᱞ ᱮᱢᱟᱵᱚᱱᱟ (Dare abo jo ar umul emabona)',
      'olChiki': 'ᱫᱟᱨᱮ ᱟᱵᱚ ᱡᱚ ᱟᱨ ᱩᱢᱩᱞ ᱮᱢᱟᱵᱚᱱᱟ',
      'phonetic': 'Dare abo jo ar umul emabona',
    },
    'पानी बचाना हमारा कर्तव्य है': {
      'santali': 'ᱫᱟᱜ ᱡᱚᱜᱟᱣ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱠᱟᱹᱢᱤ ᱠᱟᱱᱟ (Daah jogaw do abowag kami kana)',
      'olChiki': 'ᱫᱟᱜ ᱡᱚᱜᱟᱣ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱠᱟᱹᱢᱤ ᱠᱟᱱᱟ',
      'phonetic': 'Daah jogaw do abowag kami kana',
    },
  };

  @override
  Future<TranslationResult> translateText(String hindiText) async {
    // Realistic translation inference latency
    await Future.delayed(const Duration(milliseconds: 700));

    final trimmed = hindiText.trim();
    if (trimmed.isEmpty) {
      throw Exception('कृपया अनुवाद के लिए हिन्दी वाक्य दर्ज करें।');
    }

    String santaliText = 'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱚᱨᱡᱚᱢᱟ (Santali Translation for: "$trimmed")';
    String? olChiki;
    String? phonetic;

    for (var entry in _dictionary.entries) {
      if (trimmed.toLowerCase().contains(entry.key.toLowerCase())) {
        santaliText = entry.value['santali']!;
        olChiki = entry.value['olChiki'];
        phonetic = entry.value['phonetic'];
        break;
      }
    }

    final result = TranslationResult(
      sourceText: trimmed,
      translatedSantali: santaliText,
      translatedOlChiki: olChiki,
      phoneticRoman: phonetic,
      confidence: 0.96,
      isOffline: false,
    );

    _sessionHistory.insert(0, result);
    return result;
  }

  @override
  Future<VoiceTranslationResult> translateVoice(String promptContext) async {
    // Simulate ASR + IndicTrans latency
    await Future.delayed(const Duration(milliseconds: 1200));

    String transcribed = promptContext.isNotEmpty
        ? promptContext
        : 'आज हम सब मिलकर पाठ पढ़ेंगे';
    String translatedSantali =
        'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱡᱚᱛᱚ ᱦᱚᱲ ᱢᱮᱥᱟ ᱠᱟᱛᱮ ᱯᱟᱴᱷ ᱵᱚᱱ ᱯᱟᱲᱦᱟᱣᱟ';
    String olChiki = 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱡᱚᱛᱚ ᱦᱚᱲ ᱢᱮᱥᱟ ᱠᱟᱛᱮ ᱯᱟᱴᱷ ᱵᱚᱱ ᱯᱟᱲᱦᱟᱣᱟ';
    String phonetic = 'Tehen abo joto hor mesa kate path bon parhawa';

    final res = VoiceTranslationResult(
      transcribedHindi: transcribed,
      translatedSantali: translatedSantali,
      translatedOlChiki: olChiki,
      phoneticRoman: phonetic,
      confidence: 0.94,
    );

    _sessionHistory.insert(
      0,
      TranslationResult(
        sourceText: transcribed,
        translatedSantali: translatedSantali,
        translatedOlChiki: olChiki,
        phoneticRoman: phonetic,
        confidence: 0.94,
      ),
    );

    return res;
  }

  @override
  List<TranslationResult> getSessionHistory() => List.unmodifiable(_sessionHistory);

  @override
  void clearHistory() {
    _sessionHistory.clear();
  }
}

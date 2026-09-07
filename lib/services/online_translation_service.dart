import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/translation_model.dart';
import 'translation_service.dart';

/// Concrete implementation of [TranslationService] using an online API.
/// This prototype uses a public endpoint for Hindi to Santali translation.
class OnlineTranslationService implements TranslationService {
  final List<TranslationResult> _sessionHistory = [];

  // Placeholder for a real FastAPI / IndicTrans2 backend URL
  // You can change this to your deployed server URL.
  final String _apiBaseUrl = 'https://translate.googleapis.com/translate_a/single';

  @override
  Future<TranslationResult> translateText(String hindiText) async {
    if (hindiText.trim().isEmpty) {
      throw Exception('हिन्दी वाक्य खाली है। (Hindi text is empty.)');
    }

    try {
      // Using an unofficial Google Translate endpoint for the prototype
      final url = Uri.parse(
        '$_apiBaseUrl?client=gtx&sl=hi&tl=sat&dt=t&q=${Uri.encodeComponent(hindiText)}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Google Translate returns a nested list structure
        // data[0] is a list of segments, data[0][0][0] is the translated text
        String translatedText = '';
        if (data.isNotEmpty && data[0] is List) {
          for (var segment in data[0]) {
            if (segment is List && segment.isNotEmpty) {
              translatedText += segment[0].toString();
            }
          }
        }

        if (translatedText.isEmpty) {
          throw Exception('अनुवाद प्राप्त नहीं हुआ। (Translation not received.)');
        }

        final result = TranslationResult(
          sourceText: hindiText,
          translatedSantali: translatedText,
          translatedOlChiki: null, // Public API doesn't provide script variants easily
          phoneticRoman: null,
          confidence: 0.92,
          isOffline: false,
        );

        _sessionHistory.insert(0, result);
        return result;
      } else {
        throw Exception('सर्वर त्रुटि (Server Error): ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('ऑनलाइन अनुवाद विफल: $e');
    }
  }

  @override
  Future<VoiceTranslationResult> translateVoice(String promptContext) async {
    // In this prototype, STT is handled in the UI, so we just translate the transcribed text.
    final result = await translateText(promptContext);

    return VoiceTranslationResult(
      transcribedHindi: promptContext,
      translatedSantali: result.translatedSantali,
      confidence: result.confidence,
    );
  }

  @override
  List<TranslationResult> getSessionHistory() => List.unmodifiable(_sessionHistory);

  @override
  void clearHistory() {
    _sessionHistory.clear();
  }
}

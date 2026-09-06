import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palash_app/models/flashcard_model.dart';
import 'package:palash_app/models/note_model.dart';
import 'package:palash_app/models/ai_content_model.dart';
import 'package:palash_app/services/mock_auth_service.dart';
import 'package:palash_app/services/mock_ai_content_service.dart';
import 'package:palash_app/services/mock_translation_service.dart';
import 'package:palash_app/core/utils/script_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScriptHelper tests', () {
    test('Identifies Ol Chiki unicode script range', () {
      expect(ScriptHelper.containsOlChiki('ᱥᱟᱱᱛᱟᱲᱤ'), isTrue);
      expect(ScriptHelper.containsOlChiki('हिन्दी'), isFalse);
    });

    test('Identifies verified linguist marker', () {
      expect(ScriptHelper.isVerifiedContent('VERIFIED: Authentic Santali term'), isTrue);
      expect(ScriptHelper.isVerifiedContent('<!-- TODO: LINGUIST_VERIFICATION -->'), isFalse);
    });
  });

  group('AuthService Tests', () {
    test('MockAuthService email & password login', () async {
      final auth = MockAuthService();
      final user = await auth.signInWithEmailPassword('teacher@palash.edu.in', 'teacher123');
      expect(user.email, 'teacher@palash.edu.in');
      expect(auth.currentUser, isNotNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });

  group('AIContentService Tests', () {
    test('Generates draft learning content from teacher note', () async {
      final aiService = MockAIContentService();
      final note = TeacherNote(
        id: 'note_test_1',
        lessonId: 'curr_c1_lang_01',
        title: 'वर्णमाला ज्ञान',
        hindiContent: 'अ से अनार और क से कमल।',
        santaliContent: 'ᱚ ᱫᱟᱲᱤᱢ ᱟᱨ ᱠ ᱯᱩᱨᱩ᱾',
      );

      final result = await aiService.generateContent(
        note: note,
        selectedOptions: ['Lesson Explanation', 'Santali Translation', 'Flashcards', 'Worksheet', 'Activities'],
      );

      expect(result.state, ContentState.draft);
      expect(result.explanationHindi, isNotEmpty);
      expect(result.flashcards.length, greaterThanOrEqualTo(2));
      expect(result.practiceQuestions.length, greaterThanOrEqualTo(1));
      expect(result.activities.length, greaterThanOrEqualTo(1));
    });
  });

  group('TranslationService Tests', () {
    test('Translates vernacular classroom phrases with high confidence', () async {
      final transService = MockTranslationService();
      final res = await transService.translateText('नमस्ते');

      expect(res.translatedSantali.contains('ᱡᱚᱦᱟᱨ'), isTrue);
      expect(res.confidence, greaterThanOrEqualTo(0.9));
      expect(transService.getSessionHistory().length, 1);
    });
  });

  group('Model Serialization Tests', () {
    test('FlashcardItem serialization & deserialization', () {
      final card = FlashcardItem(
        id: 'fc_001',
        category: 'Language',
        subcategory: 'Words',
        hindi: 'पानी',
        santali: 'ᱫᱟᱜ (Daah)',
        santaliOlChiki: 'ᱫᱟᱜ',
      );

      final json = card.toJson();
      final fromJson = FlashcardItem.fromJson(json);

      expect(fromJson.id, 'fc_001');
      expect(fromJson.hindi, 'पानी');
      expect(fromJson.santali, 'ᱫᱟᱜ (Daah)');
      expect(fromJson.santaliOlChiki, 'ᱫᱟᱜ');
    });
  });
}

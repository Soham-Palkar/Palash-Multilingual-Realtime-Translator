import 'dart:math';
import '../models/ai_content_model.dart';
import '../models/flashcard_model.dart';
import '../models/note_model.dart';
import 'ai_content_service.dart';

/// Mock Implementation of AIContentService
/// Simulates intelligent vernacular generation from teacher's Hindi notes.
class MockAIContentService implements AIContentService {
  @override
  Future<AIGeneratedContent> generateContent({
    required TeacherNote note,
    required List<String> selectedOptions,
  }) async {
    // Simulate FastAPI & AI inference latency
    await Future.delayed(const Duration(milliseconds: 1400));

    final id = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Explanation
    String expHindi = 'इस पाठ में ${note.title} की मुख्य अवधारणाओं को प्राथमिक स्तर के विद्यार्थियों के लिए सरल उदाहरणों द्वारा समझाया गया है।';
    String expSantali = 'ᱱᱚᱣᱟ ᱯᱟᱴᱷ ᱨᱮ ${note.title} ᱨᱮᱭᱟᱜ ᱢᱩᱬᱩᱛ ᱠᱟᱛᱷᱟ ᱠᱚ ᱟᱞᱜᱟ ᱛᱮ ᱵᱩᱡᱷᱟᱹᱣ ᱦᱩᱭ ᱟᱠᱟᱱᱟ᱾';

    // 2. Santali Translation
    String transSantali = note.santaliContent.isNotEmpty
        ? note.santaliContent
        : 'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱚᱨᱡᱚᱢᱟ (Santali Vernacular Pedagogy Translation for: ${note.title})';

    // 3. AI Flashcards
    List<FlashcardItem> flashcards = [];
    if (selectedOptions.contains('Flashcards')) {
      flashcards = [
        FlashcardItem(
          id: 'fc_ai_1_${DateTime.now().millisecondsSinceEpoch}',
          category: note.subject,
          subcategory: 'AI Generated',
          hindi: '${note.title} - मुख्य शब्द',
          santali: 'ᱢᱩᱬᱩᱛ ᱥᱟᱵᱟᱫ (Key Term)',
          santaliOlChiki: 'ᱢᱩᱬᱩᱛ ᱥᱟᱵᱟᱫ',
          isDefault: false,
          isTeacherCreated: false,
          isPublished: false,
          linguistNote: 'Generated via Palash AI Pedagogy Engine',
        ),
        FlashcardItem(
          id: 'fc_ai_2_${DateTime.now().millisecondsSinceEpoch}',
          category: note.subject,
          subcategory: 'AI Generated',
          hindi: 'उदाहरण: प्रकृति एवं परिवेश',
          santali: 'ᱫᱟᱹᱭᱠᱟᱹ : ᱫᱷᱟᱹᱨᱛᱤ ᱟᱨ ᱥᱩᱨ-ᱥᱩᱯᱩᱨ (Nature & Surroundings)',
          santaliOlChiki: 'ᱫᱟᱹᱭᱠᱟᱹ : ᱫᱷᱟᱹᱨᱛᱤ',
          isDefault: false,
          isTeacherCreated: false,
          isPublished: false,
          linguistNote: 'Generated via Palash AI Pedagogy Engine',
        ),
      ];
    }

    // 4. Practice Questions & Worksheets
    List<AIPracticeQuestion> questions = [];
    if (selectedOptions.contains('Worksheet') || selectedOptions.contains('Practice Questions')) {
      questions = [
        AIPracticeQuestion(
          questionHindi: '${note.title} से संबंधित सही विकल्प चुनें:',
          questionSantali: '${note.title} ᱥᱟᱶ ᱡᱚᱲᱟᱣ ᱴᱷᱤᱠ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:',
          optionsHindi: ['सही उत्तर (क)', 'विकल्प (ख)', 'विकल्प (ग)'],
          optionsSantali: ['ᱴᱷᱤᱠ ᱛᱮᱞᱟ (A)', 'ᱮᱴᱟᱜ ᱛᱮᱞᱟ (B)', 'ᱮᱴᱟᱜ ᱛᱮᱞᱟ (C)'],
          correctIndex: 0,
          explanation: 'पाठ के अनुसार प्रथम विकल्प सही है।',
        ),
      ];
    }

    // 5. Activities
    List<AIActivityIdea> activities = [];
    if (selectedOptions.contains('Activities')) {
      activities = [
        AIActivityIdea(
          titleHindi: 'कक्षा समूह गतिविधि: चित्र पहचान एवं संताली उच्चारण',
          titleSantali: 'ᱠᱞᱟᱥ ᱜᱟᱫᱮᱞ ᱠᱟᱹᱢᱤ: ᱪᱤᱛᱟᱹᱨ ᱧᱮᱞ ᱟᱨ ᱥᱟᱱᱛᱟᱲᱤ ᱟᱲᱟᱝ',
          descriptionHindi: 'विद्यार्थी मिलकर बोर्ड पर बने चित्रों के संताली नाम बोलेंगे।',
          descriptionSantali: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱢᱮᱥᱟ ᱠᱟᱛᱮ ᱪᱤᱛᱟᱹᱨ ᱧᱮᱞ ᱠᱟᱛᱮ ᱥᱟᱱᱛᱟᱲᱤ ᱛᱮᱠᱚ ᱞᱟᱹᱭᱟ᱾',
        ),
      ];
    }

    return AIGeneratedContent(
      id: id,
      noteId: note.id,
      noteTitle: note.title,
      explanationHindi: expHindi,
      explanationSantali: expSantali,
      translationSantali: transSantali,
      flashcards: flashcards,
      practiceQuestions: questions,
      activities: activities,
      state: ContentState.draft,
    );
  }

  @override
  Future<AIGeneratedContent> regenerateContent({
    required AIGeneratedContent previousContent,
    required TeacherNote note,
    required String sectionToRegenerate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final randomSuffix = Random().nextInt(900) + 100;
    return previousContent.copyWith(
      explanationHindi: '${previousContent.explanationHindi} (पुनः उत्पन्न संस्करण #$randomSuffix)',
      translationSantali: '${previousContent.translationSantali} (ᱱᱟᱣᱟ ᱛᱮ ᱛᱚᱨᱡᱚᱢᱟ #$randomSuffix)',
    );
  }
}

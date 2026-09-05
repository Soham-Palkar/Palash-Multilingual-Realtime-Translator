import '../models/ai_content_model.dart';
import '../models/note_model.dart';

/// Abstract AI Content Service interface.
/// Allows clean future integration with FastAPI / LLM backend without altering UI.
abstract class AIContentService {
  Future<AIGeneratedContent> generateContent({
    required TeacherNote note,
    required List<String> selectedOptions,
  });

  Future<AIGeneratedContent> regenerateContent({
    required AIGeneratedContent previousContent,
    required TeacherNote note,
    required String sectionToRegenerate,
  });
}

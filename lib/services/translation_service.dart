import '../models/translation_model.dart';

/// Abstract Translation Service interface.
/// Clean integration boundary for future IndicTrans2 / FastAPI backend.
abstract class TranslationService {
  Future<TranslationResult> translateText(String hindiText);
  Future<VoiceTranslationResult> translateVoice(String promptContext);
  List<TranslationResult> getSessionHistory();
  void clearHistory();
}

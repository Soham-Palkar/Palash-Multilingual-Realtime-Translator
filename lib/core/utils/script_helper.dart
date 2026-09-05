/// Linguistic helpers for Hindi and Santali bilingual pedagogy
class ScriptHelper {
  /// Check if text contains Ol Chiki script Unicode range (U+1C50 to U+1C7F)
  static bool containsOlChiki(String text) {
    for (int i = 0; i < text.length; i++) {
      int code = text.codeUnitAt(i);
      if (code >= 0x1C50 && code <= 0x1C7F) {
        return true;
      }
    }
    return false;
  }

  /// Clean formatting for dual-script display
  static String formatBilingual(String hindi, String santali) {
    return '$hindi • $santali';
  }

  /// Marker for linguistic verification status
  static bool isVerifiedContent(String? note) {
    if (note == null) return false;
    return note.toUpperCase().contains('VERIFIED');
  }
}

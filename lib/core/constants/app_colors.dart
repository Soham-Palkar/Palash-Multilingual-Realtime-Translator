import 'package:flutter/material.dart';

/// PALASH Brand Color Palette
/// Designed for high contrast, child-friendly vibrancy, and culturally resonant
/// earthy tones (Palash / Flame of the Forest flower).
class AppColors {
  // Primary Palash Flame & Amber
  static const Color primary = Color(0xFFE64A19); // Palash Vermilion / Deep Orange
  static const Color primaryLight = Color(0xFFFF7D47);
  static const Color primaryDark = Color(0xFFAC0800);
  static const Color primaryContainer = Color(0xFFFFEBE5);
  static const Color onPrimaryContainer = Color(0xFF5D1200);

  // Secondary Warm Forest & Sage
  static const Color secondary = Color(0xFF2E7D32); // Forest Green
  static const Color secondaryLight = Color(0xFF60AD5E);
  static const Color secondaryContainer = Color(0xFFE8F5E9);
  static const Color onSecondaryContainer = Color(0xFF00390B);

  // Tertiary Saffron Gold & Sunshine
  static const Color tertiary = Color(0xFFF57F17); // Saffron Gold
  static const Color tertiaryLight = Color(0xFFFFB04C);
  static const Color tertiaryContainer = Color(0xFFFFF9C4);

  // Accent Colors for Student Modules
  static const Color moduleLanguage = Color(0xFFE65100); // Warm Orange
  static const Color moduleMath = Color(0xFF1565C0); // Royal Blue
  static const Color moduleGK = Color(0xFF2E7D32); // Leaf Green
  static const Color moduleWorksheets = Color(0xFF6A1B9A); // Rich Purple
  static const Color moduleGames = Color(0xFFD81B60); // Magenta Pink
  static const Color moduleActivities = Color(0xFF00838F); // Ocean Cyan
  static const Color moduleStories = Color(0xFFEF6C00); // Sunset Amber

  // Feedback Colors
  static const Color success = Color(0xFF2E7D32); // Correct answer green
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFC62828); // Incorrect / error red
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningContainer = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF0277BD);
  static const Color infoContainer = Color(0xFFE1F5FE);

  // Neutral Backgrounds & Surfaces (Soft warm tint for reduced eye strain)
  static const Color background = Color(0xFFFAF8F5); // Warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3EFEA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text & Icons
  static const Color textPrimary = Color(0xFF1E293B); // Deep slate
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);
}

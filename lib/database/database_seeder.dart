import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_assets.dart';
import '../data/master_santali_content.dart';
import '../models/flashcard_model.dart';
import '../models/curriculum_model.dart';
import '../models/worksheet_model.dart';
import '../models/game_model.dart';
import '../models/activity_model.dart';
import '../models/story_model.dart';
import 'app_database.dart';

/// Database Seeder: Seeds SQLite database on initial launch with bundled master content
class DatabaseSeeder {
  static const String _keySeeded = 'palash_database_seeded_v4';

  static Future<void> seedDatabaseIfNeeded(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool(_keySeeded) ?? false;

    if (!isSeeded) {
      try {
        await _seedFlashcards(db);
        await _seedCurriculum(db);
        await _seedWorksheets(db);
        await _seedGames(db);
        await _seedActivities(db);
        await _seedStories(db);

        await prefs.setBool(_keySeeded, true);
      } catch (e) {
        // Retry on subsequent launches if failed
        print('Database seed error: $e');
      }
    }
  }

  static Future<void> _seedFlashcards(AppDatabase db) async {
    // 1. Seed master flashcards from MasterSantaliContent
    for (var fc in MasterSantaliContent.masterFlashcards) {
      await db.insertFlashcard(fc);
    }

    // 2. Also seed legacy default bundled json flashcards if available
    try {
      final files = [
        AppAssets.jsonLanguageFlashcards,
        AppAssets.jsonMathFlashcards,
        AppAssets.jsonGkFlashcards,
      ];

      for (var file in files) {
        final jsonStr = await rootBundle.loadString(file);
        final list = jsonDecode(jsonStr) as List<dynamic>;
        for (var item in list) {
          final fc = FlashcardItem.fromJson(item as Map<String, dynamic>);
          await db.insertFlashcard(fc);
        }
      }
    } catch (_) {
      // Ignore if legacy asset json files are absent
    }
  }

  static Future<void> _seedCurriculum(AppDatabase db) async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonCurriculum);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (var item in list) {
        final lesson = CurriculumLesson.fromJson(item as Map<String, dynamic>);
        await db.insertCurriculumLesson(lesson);
      }
    } catch (_) {}
  }

  static Future<void> _seedWorksheets(AppDatabase db) async {
    // Seed master worksheets from MasterSantaliContent
    for (var ws in MasterSantaliContent.masterWorksheets) {
      await db.insertWorksheet(ws);
    }
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonWorksheets);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (var item in list) {
        final ws = WorksheetItem.fromJson(item as Map<String, dynamic>);
        await db.insertWorksheet(ws);
      }
    } catch (_) {}
  }

  static Future<void> _seedGames(AppDatabase db) async {
    // Seed master games from MasterSantaliContent
    for (var game in MasterSantaliContent.masterGames) {
      await db.insertGame(game);
    }
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonGames);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (var item in list) {
        final game = GameItem.fromJson(item as Map<String, dynamic>);
        await db.insertGame(game);
      }
    } catch (_) {}
  }

  static Future<void> _seedActivities(AppDatabase db) async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonActivities);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (var item in list) {
        final act = ActivityItem.fromJson(item as Map<String, dynamic>);
        await db.insertActivity(act);
      }
    } catch (_) {}
  }

  static Future<void> _seedStories(AppDatabase db) async {
    try {
      final jsonStr = await rootBundle.loadString(AppAssets.jsonStories);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (var item in list) {
        final story = StoryItem.fromJson(item as Map<String, dynamic>);
        await db.insertStory(story);
      }
    } catch (_) {}
  }
}

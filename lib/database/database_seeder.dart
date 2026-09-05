import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_assets.dart';
import '../models/flashcard_model.dart';
import '../models/curriculum_model.dart';
import '../models/worksheet_model.dart';
import '../models/game_model.dart';
import '../models/activity_model.dart';
import '../models/story_model.dart';
import 'app_database.dart';

/// Database Seeder: Seeds SQLite database on initial launch with bundled default content
class DatabaseSeeder {
  static const String _keySeeded = 'palash_database_seeded_v1';

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
  }

  static Future<void> _seedCurriculum(AppDatabase db) async {
    final jsonStr = await rootBundle.loadString(AppAssets.jsonCurriculum);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    for (var item in list) {
      final lesson = CurriculumLesson.fromJson(item as Map<String, dynamic>);
      await db.insertCurriculumLesson(lesson);
    }
  }

  static Future<void> _seedWorksheets(AppDatabase db) async {
    final jsonStr = await rootBundle.loadString(AppAssets.jsonWorksheets);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    for (var item in list) {
      final ws = WorksheetItem.fromJson(item as Map<String, dynamic>);
      await db.insertWorksheet(ws);
    }
  }

  static Future<void> _seedGames(AppDatabase db) async {
    final jsonStr = await rootBundle.loadString(AppAssets.jsonGames);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    for (var item in list) {
      final game = GameItem.fromJson(item as Map<String, dynamic>);
      await db.insertGame(game);
    }
  }

  static Future<void> _seedActivities(AppDatabase db) async {
    final jsonStr = await rootBundle.loadString(AppAssets.jsonActivities);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    for (var item in list) {
      final act = ActivityItem.fromJson(item as Map<String, dynamic>);
      await db.insertActivity(act);
    }
  }

  static Future<void> _seedStories(AppDatabase db) async {
    final jsonStr = await rootBundle.loadString(AppAssets.jsonStories);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    for (var item in list) {
      final story = StoryItem.fromJson(item as Map<String, dynamic>);
      await db.insertStory(story);
    }
  }
}

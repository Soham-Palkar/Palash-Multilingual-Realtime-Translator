import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/flashcard_model.dart';
import '../models/note_model.dart';
import '../models/curriculum_model.dart';
import '../models/worksheet_model.dart';
import '../models/game_model.dart';
import '../models/activity_model.dart';
import '../models/story_model.dart';

/// Central Content Repository for Student & Teacher learning materials.
/// Backed directly by the local SQLite database.
class ContentRepository extends ChangeNotifier {
  final AppDatabase _db;

  ContentRepository(this._db);

  // Flashcards
  Future<List<FlashcardItem>> getFlashcardsByCategory(String category) async {
    final all = await _db.getAllFlashcards();
    return all.where((f) => f.category.toLowerCase() == category.toLowerCase() && f.isPublished).toList();
  }

  Future<List<FlashcardItem>> getAllPublishedFlashcards() async {
    final all = await _db.getAllFlashcards();
    return all.where((f) => f.isPublished).toList();
  }

  // Published Notes
  Future<List<TeacherNote>> getPublishedNotes() async {
    final all = await _db.getAllNotes();
    return all.where((n) => n.isPublished).toList();
  }

  // Curriculum & Lessons
  Future<List<CurriculumLesson>> getCurriculumByClassAndSubject(int gradeClass, String subject) async {
    final all = await _db.getCurriculum();
    return all.where((l) => l.gradeClass == gradeClass && l.subject.toLowerCase() == subject.toLowerCase()).toList();
  }

  Future<List<CurriculumLesson>> getAllCurriculum() async {
    return await _db.getCurriculum();
  }

  // Worksheets
  Future<List<WorksheetItem>> getWorksheets() async {
    return await _db.getAllWorksheets();
  }

  // Games
  Future<List<GameItem>> getGames() async {
    return await _db.getAllGames();
  }

  Future<List<GameItem>> getGamesByCategory(String category) async {
    final all = await _db.getAllGames();
    return all.where((g) => g.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // Activities
  Future<List<ActivityItem>> getActivities() async {
    return await _db.getAllActivities();
  }

  // Stories
  Future<List<StoryItem>> getStories() async {
    return await _db.getAllStories();
  }
}

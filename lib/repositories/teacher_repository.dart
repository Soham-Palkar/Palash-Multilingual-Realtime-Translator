import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/ai_content_model.dart';
import '../models/flashcard_model.dart';
import '../models/note_model.dart';

/// Repository for Teacher actions, Notes management, and AI Generation workflow.
class TeacherRepository extends ChangeNotifier {
  final AppDatabase _db;

  TeacherRepository(this._db);

  // Notes Management
  Future<List<TeacherNote>> getAllNotes() async {
    return await _db.getAllNotes();
  }

  Future<void> saveNote(TeacherNote note) async {
    await _db.insertNote(note);
    notifyListeners();
  }

  Future<void> updateNote(TeacherNote note) async {
    await _db.updateNote(note);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _db.deleteNote(id);
    notifyListeners();
  }

  // AI Content Lifecycle
  Future<List<AIGeneratedContent>> getAIGeneratedContents() async {
    return await _db.getAllAIContents();
  }

  Future<void> saveAIContent(AIGeneratedContent content) async {
    await _db.insertAIContent(content);
    notifyListeners();
  }

  Future<void> approveAIContent(String id) async {
    await _db.updateAIContentState(id, ContentState.approved);
    notifyListeners();
  }

  Future<void> publishAIContent(AIGeneratedContent content) async {
    // 1. Update status to published
    await _db.updateAIContentState(content.id, ContentState.published);

    // 2. Publish any generated flashcards into student offline database
    for (var fc in content.flashcards) {
      final publishedFc = fc.copyWith(isPublished: true, isTeacherCreated: true);
      await _db.insertFlashcard(publishedFc);
    }

    notifyListeners();
  }

  // Teacher Flashcard Creator
  Future<void> createManualFlashcard(FlashcardItem item) async {
    await _db.insertFlashcard(item);
    notifyListeners();
  }

  Future<List<FlashcardItem>> getTeacherFlashcards() async {
    final all = await _db.getAllFlashcards();
    return all.where((f) => f.isTeacherCreated).toList();
  }

  // Dashboard Stats
  Future<Map<String, int>> getTeacherStats() async {
    final notes = await _db.getAllNotes();
    final aiContents = await _db.getAllAIContents();
    final flashcards = await _db.getAllFlashcards();

    int draftNotes = notes.where((n) => n.isDraft).length;
    int publishedNotes = notes.where((n) => n.isPublished).length;
    int draftAICount = aiContents.where((a) => a.state == ContentState.draft).length;
    int approvedAICount = aiContents.where((a) => a.state == ContentState.approved).length;
    int publishedAICount = aiContents.where((a) => a.state == ContentState.published).length;
    int teacherFlashcards = flashcards.where((f) => f.isTeacherCreated).length;

    return {
      'totalNotes': notes.length,
      'draftNotes': draftNotes,
      'publishedNotes': publishedNotes,
      'draftAI': draftAICount,
      'approvedAI': approvedAICount,
      'publishedAI': publishedAICount,
      'teacherFlashcards': teacherFlashcards,
    };
  }
}

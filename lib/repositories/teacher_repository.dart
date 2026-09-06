import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/ai_content_model.dart';
import '../models/note_model.dart';
import '../services/sync_service_factory.dart';
import '../services/sync_service.dart';
import '../models/flashcard_model.dart';

/// Repository for Teacher actions, Notes management, and AI Generation workflow.
class TeacherRepository extends ChangeNotifier {
  final AppDatabase _db;
  final SyncService _syncService = SyncServiceFactory.create();

  TeacherRepository(this._db);

  // Notes Management
  Future<List<TeacherNote>> getAllNotes() async {
    return await _db.getAllNotes();
  }

  // New method to publish a note (set isDraft false, isPublished true) and sync
  Future<void> publishNote(TeacherNote note) async {
    final published = note.copyWith(isDraft: false, isApproved: true, isPublished: true);
    await _db.updateNote(published);
    await _syncService.uploadNote(published);
    notifyListeners();
  }

  // Submit for review: mark as not draft, not approved, not published
  Future<void> submitForReview(TeacherNote note) async {
    final reviewed = note.copyWith(isDraft: false, isApproved: false, isPublished: false);
    await _db.updateNote(reviewed);
    await _syncService.uploadNote(reviewed);
    notifyListeners();
  }

  // Approve note: set approved flag
  Future<void> approveNote(TeacherNote note) async {
    // When approving, the note must transition out of draft state.
    // Firestore rules require isDraft = 0, isApproved = 1, isPublished = 0.
    final approved = note.copyWith(isDraft: false, isApproved: true);
    await _db.updateNote(approved);
    await _syncService.uploadNote(approved);
    notifyListeners();
  }

  Future<void> saveNote(TeacherNote note) async {
    await _db.insertNote(note);
    // Upload to Firestore for draft or published note
    await _syncService.uploadNote(note);
    notifyListeners();
  }

  Future<void> updateNote(TeacherNote note) async {
    await _db.updateNote(note);
    await _syncService.uploadNote(note);
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
    // 2. Upload the AI content with published state
    final publishedContent = content.copyWith(state: ContentState.published);
    await _syncService.uploadAIContent(publishedContent);

    // 3. Publish any generated flashcards into student offline database
    for (var fc in content.flashcards) {
      final publishedFc = fc.copyWith(isPublished: true, isTeacherCreated: true);
      await _db.insertFlashcard(publishedFc);
      await _syncService.uploadFlashcard(publishedFc);
    }

    notifyListeners();
  }

  // Teacher Flashcard Creator
  Future<void> createManualFlashcard(FlashcardItem item) async {
    // Ensure manual teacher-created flashcards have correct flags
    final adjusted = item.copyWith(isTeacherCreated: true, isPublished: false);
    await _db.insertFlashcard(adjusted);
    await _syncService.uploadFlashcard(adjusted);
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

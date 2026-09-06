/// Abstract Sync Service interface.
/// Encapsulates synchronization between local SQLite/Drift and future Firebase Firestore / Cloud backend.
import '../models/note_model.dart';
import '../models/flashcard_model.dart';
import '../models/ai_content_model.dart';
abstract class SyncService {
  Future<SyncStatusResult> syncContent();
  Stream<SyncStatusResult> get syncStatusStream;
  SyncStatusResult get currentStatus;

  Future<void> uploadNote(TeacherNote note);
  Future<void> uploadFlashcard(FlashcardItem flashcard);
  Future<void> uploadAIContent(AIGeneratedContent content);
}

class SyncStatusResult {
  final bool isSyncing;
  final bool isSuccess;
  final String message;
  final DateTime lastSyncedAt;
  final int syncedItemsCount;

  SyncStatusResult({
    this.isSyncing = false,
    this.isSuccess = true,
    this.message = 'All content up to date',
    DateTime? lastSyncedAt,
    this.syncedItemsCount = 0,
  }) : lastSyncedAt = lastSyncedAt ?? DateTime.now();
}

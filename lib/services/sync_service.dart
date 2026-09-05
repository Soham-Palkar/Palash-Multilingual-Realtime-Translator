/// Abstract Sync Service interface.
/// Encapsulates synchronization between local SQLite/Drift and future Firebase Firestore / Cloud backend.
abstract class SyncService {
  Future<SyncStatusResult> syncContent();
  Stream<SyncStatusResult> get syncStatusStream;
  SyncStatusResult get currentStatus;
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

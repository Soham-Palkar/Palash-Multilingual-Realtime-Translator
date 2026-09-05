// Factory for creating SyncService instances
import 'firebase_sync_service.dart';
import 'sync_service.dart';

class SyncServiceFactory {
  /// Returns a concrete [SyncService] implementation.
  /// Currently always returns [FirebaseSyncService] which syncs with
  /// Firestore. In the future this could be extended to return mock or
  /// alternative back‑ends based on configuration.
  static SyncService create() {
    return FirebaseSyncService();
  }
}

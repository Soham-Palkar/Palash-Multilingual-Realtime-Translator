import 'dart:async';
import 'sync_service.dart';

/// Mock Implementation of SyncService
class MockSyncService implements SyncService {
  final _controller = StreamController<SyncStatusResult>.broadcast();
  SyncStatusResult _currentStatus = SyncStatusResult(
    isSyncing: false,
    isSuccess: true,
    message: 'Local offline database synced',
    syncedItemsCount: 42,
  );

  @override
  SyncStatusResult get currentStatus => _currentStatus;

  @override
  Stream<SyncStatusResult> get syncStatusStream => _controller.stream;

  @override
  Future<SyncStatusResult> syncContent() async {
    _currentStatus = SyncStatusResult(
      isSyncing: true,
      message: 'Syncing with cloud repository...',
    );
    _controller.add(_currentStatus);

    await Future.delayed(const Duration(milliseconds: 1200));

    _currentStatus = SyncStatusResult(
      isSyncing: false,
      isSuccess: true,
      message: 'Cloud sync completed successfully',
      lastSyncedAt: DateTime.now(),
      syncedItemsCount: 45,
    );
    _controller.add(_currentStatus);
    return _currentStatus;
  }
}

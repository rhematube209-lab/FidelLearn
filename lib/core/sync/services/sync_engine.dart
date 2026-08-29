import 'dart:async';
import 'dart:math';

import '../../networking/connectivity_service.dart';
import '../models/sync_models.dart';
import '../repositories/sync_queue_repository.dart';

typedef SyncOperationHandler =
    Future<bool> Function(SyncOperation operation);

class SyncEngine {
  final ConnectivityService _connectivityService;
  final SyncQueueRepository _queueRepository;
  final Map<SyncOperationType, SyncOperationHandler> _handlers = {};

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.synced;
  bool _isSyncing = false;
  StreamSubscription<NetworkStatus>? _connectivitySub;

  SyncEngine({
    required ConnectivityService connectivityService,
    required SyncQueueRepository queueRepository,
  })  : _connectivityService = connectivityService,
        _queueRepository = queueRepository {
    _init();
  }

  void _init() {
    _connectivitySub = _connectivityService.onStatusChanged.listen((status) {
      if (status != NetworkStatus.offline) {
        // Auto-trigger sync on network restoration
        syncAll();
      } else {
        _updateStatus(SyncStatus.offline);
      }
    });
  }

  SyncStatus get currentStatus => _currentStatus;
  Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  void registerHandler(SyncOperationType type, SyncOperationHandler handler) {
    _handlers[type] = handler;
  }

  void _updateStatus(SyncStatus newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  /// Calculates bounded exponential backoff with jitter
  /// Delta_t = min(2^retryCount * 2s, 300s) + jitter
  static Duration calculateBackoff({
    required int retryCount,
    int baseSeconds = 2,
    int maxSeconds = 300,
    Random? random,
  }) {
    final rand = random ?? Random();
    final exponential = baseSeconds * pow(2, retryCount).toInt();
    final bounded = min(exponential, maxSeconds);
    final jitterMillis = rand.nextInt(1000); // 0-999ms jitter
    return Duration(seconds: bounded, milliseconds: jitterMillis);
  }

  /// Drains eligible pending operations from the local queue
  Future<int> syncAll() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      _updateStatus(SyncStatus.offline);
      _isSyncing = false;
      return 0;
    }

    final pendingCount = await _queueRepository.getPendingCount();
    if (pendingCount == 0) {
      _updateStatus(SyncStatus.synced);
      _isSyncing = false;
      return 0;
    }

    _updateStatus(SyncStatus.syncing);

    final operations = await _queueRepository.getPendingOperations(limit: 20);
    int syncedCount = 0;

    for (final op in operations) {
      final handler = _handlers[op.operationType];
      if (handler == null) {
        // Default success if no remote handler attached (e.g., local mock sync mode)
        await _queueRepository.markOperationSuccess(op.id);
        syncedCount++;
        continue;
      }

      try {
        final success = await handler(op);
        if (success) {
          await _queueRepository.markOperationSuccess(op.id);
          syncedCount++;
        } else {
          final delay = calculateBackoff(retryCount: op.retryCount);
          await _queueRepository.markOperationFailure(
            op.id,
            error: 'Handler returned false / failed validation',
            retryDelay: delay,
          );
        }
      } catch (e) {
        final delay = calculateBackoff(retryCount: op.retryCount);
        await _queueRepository.markOperationFailure(
          op.id,
          error: e.toString(),
          retryDelay: delay,
        );
      }
    }

    final remaining = await _queueRepository.getPendingCount();
    if (remaining == 0) {
      _updateStatus(SyncStatus.synced);
    } else {
      _updateStatus(SyncStatus.pending);
    }

    _isSyncing = false;
    return syncedCount;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }
}

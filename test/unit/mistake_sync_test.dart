import 'package:drift/native.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/core/sync/models/sync_models.dart';
import 'package:fidel_learn/core/sync/repositories/drift_sync_queue_repository.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/mistakes/domain/models/mistake_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftSyncQueueRepository syncQueue;
  late DriftMistakeRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    syncQueue = DriftSyncQueueRepository(db);
    repository = DriftMistakeRepository(db: db, syncQueue: syncQueue);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'Section 55: New local mistake sets pending syncStatus and queues sync operation',
      () async {
    const userId = 'sync_user_1';
    const questionId = 'q_sync_1';
    const attemptId = 'attempt_sync_1';

    // 1. Record local mistake
    await repository.recordMistake(
      userId: userId,
      questionId: questionId,
      subjectId: 'biology',
      attemptId: attemptId,
      selectedChoiceId: 'choice_b',
    );

    // 2. Verify local mistake has pending syncStatus
    final mistake =
        await repository.getMistakeById(userId: userId, questionId: questionId);
    expect(mistake, isNotNull);
    expect(mistake!.syncStatus, equals('pending'));
    expect(mistake.masteryStatus, equals(MasteryStatus.needsReview));

    // 3. Verify sync operation is queued
    final pendingOps = await syncQueue.getPendingOperations();
    expect(pendingOps.length, equals(1));
    final op = pendingOps.first;
    expect(op.operationType, equals(SyncOperationType.recordMistake));
    expect(op.payload['question_id'], equals(questionId));
    expect(op.payload['user_id'], equals(userId));
    expect(op.payload['mastery_status'], equals('needsReview'));

    // 4. Simulate remote failure: local mistake remains available and intact
    await syncQueue.markOperationFailure(op.id,
        error: 'Network unavailable', retryDelay: const Duration(minutes: 5));
    final localMistakes = await repository.getMistakes(userId);
    expect(localMistakes.length, equals(1));
    expect(localMistakes.first.questionId, equals(questionId));

    // 5. Remote success: queue item is cleared and sync status updated
    await syncQueue.markOperationSuccess(op.id);
    final remainingOps = await syncQueue.getPendingOperations();
    expect(remainingOps.isEmpty, isTrue);
  });
}

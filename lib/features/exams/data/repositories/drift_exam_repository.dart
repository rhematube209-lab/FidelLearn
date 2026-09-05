import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/models/sync_models.dart';
import '../../../../core/sync/repositories/sync_queue_repository.dart';
import '../../domain/models/exam_models.dart';
import '../../domain/repositories/exam_repository.dart';

class DriftExamRepository implements ExamRepository {
  final AppDatabase _db;
  final SyncQueueRepository? _syncQueue;

  DriftExamRepository({
    required AppDatabase db,
    SyncQueueRepository? syncQueue,
  })  : _db = db,
        _syncQueue = syncQueue;

  @override
  Future<void> saveActiveAttempt(ExamAttempt attempt) async {
    await _db.into(_db.dbActiveAttempts).insert(
          DbActiveAttempt(
            userId: attempt.userId,
            attemptJson: jsonEncode(attempt.toJson()),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<ExamAttempt?> getActiveAttempt(String userId) async {
    final row = await (_db.select(_db.dbActiveAttempts)
          ..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();

    if (row == null) return null;
    try {
      final json = jsonDecode(row.attemptJson) as Map<String, dynamic>;
      return ExamAttempt.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearActiveAttempt(String userId) async {
    await (_db.delete(_db.dbActiveAttempts)
          ..where((tbl) => tbl.userId.equals(userId)))
        .go();
  }

  @override
  Future<void> saveCompletedAttempt(ExamAttempt attempt) async {
    // 1. Clear active attempt from persistence
    await clearActiveAttempt(attempt.userId);

    // 2. Insert into SQLite attempts table
    final responsesMapJson = jsonEncode(
      attempt.responses.map((k, v) => MapEntry(k, v.toJson())),
    );

    await _db.into(_db.dbExamAttempts).insert(
          DbExamAttempt(
            id: attempt.id,
            userId: attempt.userId,
            examId: attempt.examId,
            examTitle: attempt.examTitle,
            subjectId: attempt.subjectId,
            startTime: attempt.startTime,
            endTime: attempt.endTime,
            durationSeconds: attempt.durationSeconds,
            totalQuestions: attempt.totalQuestions,
            score: attempt.score,
            percentage: attempt.percentage,
            correctCount: attempt.correctCount,
            incorrectCount: attempt.incorrectCount,
            skippedCount: attempt.skippedCount,
            isCompleted: attempt.isCompleted,
            syncStatus: attempt.syncStatus,
            responsesJson: responsesMapJson,
            createdAt: attempt.startTime,
          ),
          mode: InsertMode.insertOrReplace,
        );

    // 3. Register idempotent offline sync mutation
    final queue = _syncQueue;
    if (queue != null) {
      final op = SyncOperation(
        id: 'sync_${attempt.id}',
        operationType: SyncOperationType.submitAttempt,
        payload: attempt.toJson(),
        idempotencyKey: 'attempt_${attempt.id}',
        nextRetryAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await queue.enqueue(op);
    }
  }

  ExamAttempt _fromRow(DbExamAttempt row) {
    Map<String, UserResponse> responses = {};
    try {
      final raw = jsonDecode(row.responsesJson) as Map<String, dynamic>;
      responses = raw.map(
        (k, v) => MapEntry(k, UserResponse.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {}

    return ExamAttempt(
      id: row.id,
      userId: row.userId,
      examId: row.examId,
      examTitle: row.examTitle,
      subjectId: row.subjectId,
      startTime: row.startTime,
      endTime: row.endTime,
      durationSeconds: row.durationSeconds,
      totalQuestions: row.totalQuestions,
      score: row.score,
      percentage: row.percentage,
      correctCount: row.correctCount,
      incorrectCount: row.incorrectCount,
      skippedCount: row.skippedCount,
      isCompleted: row.isCompleted,
      responses: responses,
      syncStatus: row.syncStatus,
    );
  }

  @override
  Future<List<ExamAttempt>> getAttemptHistory(String userId) async {
    final rows = await (_db.select(_db.dbExamAttempts)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startTime)]))
        .get();

    return rows.map(_fromRow).toList();
  }

  @override
  Future<ExamAttempt?> getAttemptById(String attemptId) async {
    final row = await (_db.select(_db.dbExamAttempts)
          ..where((tbl) => tbl.id.equals(attemptId)))
        .getSingleOrNull();

    if (row == null) return null;
    return _fromRow(row);
  }
}

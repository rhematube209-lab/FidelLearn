import 'dart:async';

import '../../domain/models/mistake_model.dart';
import '../../domain/repositories/mistake_repository.dart';

class LocalMistakeRepository implements MistakeRepository {
  final Map<String, MistakeRecord> _mistakes = {}; // Key: "userId_questionId"
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  void _notify() {
    if (!_changeController.isClosed) {
      _changeController.add(null);
    }
  }

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? attemptId,
    String? selectedChoiceId,
  }) async {
    final key = '${userId}_$questionId';
    final existing = _mistakes[key];
    final now = DateTime.now();

    // Idempotency: skip if already processed for this attempt
    if (existing != null &&
        attemptId != null &&
        existing.lastAttemptId == attemptId) {
      if (selectedChoiceId != null &&
          existing.lastSelectedChoiceId != selectedChoiceId) {
        _mistakes[key] =
            existing.copyWith(lastSelectedChoiceId: selectedChoiceId);
        _notify();
      }
      return;
    }

    if (existing != null) {
      _mistakes[key] = existing.copyWith(
        unitId: unitId ?? existing.unitId,
        topicId: topicId ?? existing.topicId,
        lastAttemptId: attemptId,
        lastSelectedChoiceId: selectedChoiceId ?? existing.lastSelectedChoiceId,
        lastMissedAt: now,
        lastAttemptAt: now,
        missCount: existing.missCount + 1,
        correctRetryCount: 0,
        masteryStatus: MasteryStatus.needsReview,
        updatedAt: now,
      );
    } else {
      _mistakes[key] = MistakeRecord(
        id: 'mst_$key',
        userId: userId,
        questionId: questionId,
        subjectId: subjectId,
        unitId: unitId,
        topicId: topicId,
        lastAttemptId: attemptId,
        lastSelectedChoiceId: selectedChoiceId,
        firstMissedAt: now,
        lastMissedAt: now,
        lastAttemptAt: now,
        missCount: 1,
        retryCount: 0,
        correctRetryCount: 0,
        masteryStatus: MasteryStatus.needsReview,
        createdAt: now,
        updatedAt: now,
      );
    }
    _notify();
  }

  @override
  Future<void> recordRetryResult({
    required String userId,
    required String questionId,
    required bool isCorrect,
    required String attemptId,
    String? selectedChoiceId,
    String? subjectId,
  }) async {
    final key = '${userId}_$questionId';
    final existing = _mistakes[key];
    final now = DateTime.now();

    // Idempotency
    if (existing != null && existing.lastAttemptId == attemptId) {
      return;
    }

    if (existing != null) {
      if (!isCorrect) {
        _mistakes[key] = existing.copyWith(
          lastAttemptId: attemptId,
          lastSelectedChoiceId:
              selectedChoiceId ?? existing.lastSelectedChoiceId,
          lastMissedAt: now,
          lastAttemptAt: now,
          missCount: existing.missCount + 1,
          correctRetryCount: 0,
          masteryStatus: MasteryStatus.needsReview,
          updatedAt: now,
        );
      } else {
        final newRetryCount = existing.retryCount + 1;
        final newCorrectRetry = existing.correctRetryCount + 1;
        final newStatus = newCorrectRetry >= 2
            ? MasteryStatus.mastered
            : MasteryStatus.improving;
        _mistakes[key] = existing.copyWith(
          lastAttemptId: attemptId,
          lastSelectedChoiceId:
              selectedChoiceId ?? existing.lastSelectedChoiceId,
          lastAttemptAt: now,
          retryCount: newRetryCount,
          correctRetryCount: newCorrectRetry,
          masteryStatus: newStatus,
          updatedAt: now,
        );
      }
    } else {
      _mistakes[key] = MistakeRecord(
        id: 'mst_$key',
        userId: userId,
        questionId: questionId,
        subjectId: subjectId ?? 'general',
        lastAttemptId: attemptId,
        lastSelectedChoiceId: selectedChoiceId,
        firstMissedAt: now,
        lastMissedAt: now,
        lastAttemptAt: now,
        missCount: isCorrect ? 0 : 1,
        retryCount: isCorrect ? 1 : 0,
        correctRetryCount: isCorrect ? 1 : 0,
        masteryStatus:
            isCorrect ? MasteryStatus.improving : MasteryStatus.needsReview,
        createdAt: now,
        updatedAt: now,
      );
    }
    _notify();
  }

  @override
  Future<void> markMastered({
    required String userId,
    required String questionId,
  }) async {
    final key = '${userId}_$questionId';
    final existing = _mistakes[key];
    if (existing != null) {
      _mistakes[key] = existing.copyWith(
        masteryStatus: MasteryStatus.mastered,
        correctRetryCount:
            existing.correctRetryCount < 2 ? 2 : existing.correctRetryCount,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<List<MistakeRecord>> getMistakes(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) async {
    return _filterMistakes(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
      status: status,
      onlyUnmastered: onlyUnmastered,
    );
  }

  @override
  Stream<List<MistakeRecord>> watchMistakes(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) async* {
    yield _filterMistakes(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
      status: status,
      onlyUnmastered: onlyUnmastered,
    );
    await for (final _ in _changeController.stream) {
      yield _filterMistakes(
        userId,
        subjectId: subjectId,
        unitId: unitId,
        topicId: topicId,
        status: status,
        onlyUnmastered: onlyUnmastered,
      );
    }
  }

  List<MistakeRecord> _filterMistakes(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
    MasteryStatus? status,
    bool onlyUnmastered = false,
  }) {
    return _mistakes.values.where((m) {
      if (m.userId != userId) return false;
      if (subjectId != null && m.subjectId != subjectId) return false;
      if (unitId != null && m.unitId != unitId) return false;
      if (topicId != null && m.topicId != topicId) return false;
      if (status != null && m.masteryStatus != status) return false;
      if (onlyUnmastered && m.masteryStatus == MasteryStatus.mastered) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.lastMissedAt.compareTo(a.lastMissedAt));
  }

  @override
  Future<MistakeCounts> getMistakeCounts(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
  }) async {
    final all = _filterMistakes(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
    );
    return _calculateCounts(all);
  }

  @override
  Stream<MistakeCounts> watchMistakeCounts(
    String userId, {
    String? subjectId,
    String? unitId,
    String? topicId,
  }) async* {
    yield await getMistakeCounts(
      userId,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
    );
    await for (final _ in _changeController.stream) {
      yield await getMistakeCounts(
        userId,
        subjectId: subjectId,
        unitId: unitId,
        topicId: topicId,
      );
    }
  }

  MistakeCounts _calculateCounts(List<MistakeRecord> records) {
    int needsReview = 0;
    int improving = 0;
    int mastered = 0;

    for (final m in records) {
      switch (m.masteryStatus) {
        case MasteryStatus.improving:
          improving++;
          break;
        case MasteryStatus.mastered:
          mastered++;
          break;
        case MasteryStatus.needsReview:
          needsReview++;
          break;
      }
    }

    return MistakeCounts(
      total: records.length,
      needsReview: needsReview,
      improving: improving,
      mastered: mastered,
    );
  }

  @override
  Future<MistakeRecord?> getMistakeById({
    required String userId,
    required String questionId,
  }) async {
    return _mistakes['${userId}_$questionId'];
  }

  void dispose() {
    _changeController.close();
  }
}

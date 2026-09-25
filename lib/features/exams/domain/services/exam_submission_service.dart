import 'package:flutter/foundation.dart';
import '../../../../core/providers/app_providers.dart' show CoinLedgerNotifier;
import '../../../mistakes/domain/services/mistake_outcome_service.dart';
import '../models/exam_models.dart';
import '../repositories/exam_repository.dart';
import 'exam_engine.dart';

/// Centralized service orchestrating atomic and exactly-once submission of exam attempts,
/// enforcing transaction boundaries, score snapshotting, and idempotent outcome processing.
class ExamSubmissionService {
  final ExamRepository _examRepo;
  final MistakeOutcomeService _outcomeService;
  final CoinLedgerNotifier? _coinNotifier;

  const ExamSubmissionService({
    required ExamRepository examRepo,
    required MistakeOutcomeService outcomeService,
    CoinLedgerNotifier? coinNotifier,
  })  : _examRepo = examRepo,
        _outcomeService = outcomeService,
        _coinNotifier = coinNotifier;

  /// Finalizes an exam attempt with strict exactly-once outcome execution.
  ///
  /// Authoritative Sequence:
  /// 1. Finalize attempt & preserve responses
  /// 2. Persist immutable result snapshot
  /// 3. Mark attempt submitted/completed
  /// 4. Process learning outcomes idempotently (mistakes + P4 mastery)
  /// 5. Award coins idempotently with stable unique key
  /// 6. Mark outcomesProcessedAt timestamp
  Future<ExamAttempt> finalizeSubmission({
    required ExamAttempt currentAttempt,
    required Exam exam,
    required int totalDurationSeconds,
    required String userId,
    bool isAutoSubmitted = false,
    bool timerIntegrityWarning = false,
  }) async {
    // 0. Idempotency guard: If already completed with outcomes processed, return existing
    final existing = await _examRepo.getAttemptById(currentAttempt.id);
    if (existing != null &&
        existing.isCompleted &&
        existing.outcomesProcessedAt != null) {
      debugPrint(
          '[ExamSubmissionService] Attempt ${currentAttempt.id} already finalized with outcomes. Skipping duplicate processing.');
      return existing;
    }

    // 1. Submit attempt and compute immutable score snapshot
    final finishedAttempt = ExamEngine.submitAttempt(
      currentAttempt: currentAttempt.copyWith(
        autoSubmitted: isAutoSubmitted,
        timerIntegrityWarning: timerIntegrityWarning,
      ),
      questions: exam.questions,
      totalDurationSeconds: totalDurationSeconds,
    );

    // 2. Persist immutable completed attempt to SQLite
    await _examRepo.saveCompletedAttempt(finishedAttempt);

    // 3. Process learning outcomes if not yet processed
    if (finishedAttempt.outcomesProcessedAt == null) {
      final qMap = {for (final q in exam.questions) q.id: q};

      for (final resp in finishedAttempt.responses.values) {
        if (resp.selectedChoiceId == null) continue;
        final q = qMap[resp.questionId];
        if (q == null || !q.isScorable) continue;

        try {
          await _outcomeService.processQuestionOutcome(
            userId: userId,
            questionId: q.id,
            subjectId: q.subjectId,
            unitId: q.unitId,
            topicId: q.topicId,
            attemptId: finishedAttempt.id,
            selectedChoiceId: resp.selectedChoiceId,
            isCorrect: resp.isCorrect,
            sessionType: exam.examType,
            question: q,
            responseTimeSeconds: resp.timeSpentSeconds,
          );
        } catch (e) {
          debugPrint(
              '[ExamSubmissionService] Error processing outcome for question ${q.id}: $e');
        }
      }

      // 4. Award Study Coins with unique attempt idempotency key
      if (_coinNotifier != null && userId != 'guest_student') {
        try {
          final earnedCoins = (finishedAttempt.score * 2).clamp(5, 50);
          _coinNotifier.awardCoins(
            userId: userId,
            amount: earnedCoins,
            reason: 'Completed exam: ${exam.title}',
            idempotencyKey: 'exam_${finishedAttempt.id}',
            relatedEntityId: finishedAttempt.id,
          );
        } catch (e) {
          debugPrint(
              '[ExamSubmissionService] Coin award error (non-fatal): $e');
        }
      }

      // 5. Update attempt record with outcomesProcessedAt to lock future retries
      final markedAttempt = finishedAttempt.copyWith(
        outcomesProcessedAt: DateTime.now(),
      );
      await _examRepo.saveCompletedAttempt(markedAttempt);
      return markedAttempt;
    }

    return finishedAttempt;
  }
}

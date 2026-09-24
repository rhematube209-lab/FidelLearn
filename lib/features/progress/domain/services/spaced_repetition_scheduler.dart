import 'dart:math' as math;

import '../models/mastery_models.dart';
import '../models/study_plan_models.dart';

/// Calculation result containing updated scheduling and mastery metrics.
class SpacedScheduleResult {
  final MasteryState nextState;
  final double nextStability;
  final double nextDifficulty;
  final int nextIntervalDays;
  final DateTime nextReviewAt;
  final int reviewCount;
  final int lapseCount;
  final int consecutiveCorrect;

  const SpacedScheduleResult({
    required this.nextState,
    required this.nextStability,
    required this.nextDifficulty,
    required this.nextIntervalDays,
    required this.nextReviewAt,
    required this.reviewCount,
    required this.lapseCount,
    required this.consecutiveCorrect,
  });
}

/// Centralized, explainable, and deterministic spaced-repetition scheduler.
/// Algorithm: `fidel_spaced_v1.0`
class SpacedRepetitionScheduler {
  static const double minDifficulty = 1.0;
  static const double maxDifficulty = 3.0;
  static const double defaultDifficulty = 2.0;

  static const double minStability = 1.0;
  static const double maxStability = 90.0;
  static const double defaultStability = 1.0;

  const SpacedRepetitionScheduler();

  /// Normalizes raw difficulty to safely reside within [minDifficulty, maxDifficulty].
  /// Guards against 0, negative values, NaN, and Infinity.
  static double normalizeDifficulty(double? raw) {
    if (raw == null || raw.isNaN || raw.isInfinite || raw <= 0.0) {
      return defaultDifficulty;
    }
    return raw.clamp(minDifficulty, maxDifficulty);
  }

  /// Normalizes raw stability to safely reside within [minStability, maxStability].
  /// Guards against negative values, NaN, and Infinity.
  static double normalizeStability(double? raw) {
    if (raw == null || raw.isNaN || raw.isInfinite || raw < minStability) {
      return defaultStability;
    }
    return raw.clamp(minStability, maxStability);
  }

  /// Calculates the next schedule and mastery state after a question outcome or review.
  SpacedScheduleResult evaluateOutcome({
    required QuestionMasteryRecord currentRecord,
    required bool isCorrect,
    required DateTime eventTime,
    int responseTimeSeconds = 0,
    DateTime? targetExamDate,
  }) {
    final daysUntilExam =
        (targetExamDate != null && targetExamDate.isAfter(eventTime))
            ? targetExamDate.difference(eventTime).inDays
            : null;
    final examPhase = ExamPreparationPhase.fromDays(daysUntilExam);

    if (!isCorrect) {
      return _evaluateLapse(
        currentRecord: currentRecord,
        eventTime: eventTime,
        daysUntilExam: daysUntilExam,
        examPhase: examPhase,
      );
    } else {
      return _evaluateSuccess(
        currentRecord: currentRecord,
        eventTime: eventTime,
        responseTimeSeconds: responseTimeSeconds,
        daysUntilExam: daysUntilExam,
        examPhase: examPhase,
      );
    }
  }

  /// Evaluates an incorrect response (lapse or initial failure).
  SpacedScheduleResult _evaluateLapse({
    required QuestionMasteryRecord currentRecord,
    required DateTime eventTime,
    required int? daysUntilExam,
    required ExamPreparationPhase examPhase,
  }) {
    final wasMasteredOrImproving =
        currentRecord.masteryState == MasteryState.mastered ||
            currentRecord.masteryState == MasteryState.atRisk ||
            currentRecord.masteryState == MasteryState.improving;

    final nextState = wasMasteredOrImproving
        ? MasteryState.relearning
        : MasteryState.learning;

    final nextLapseCount = currentRecord.lapseCount + 1;

    final safeDifficulty = normalizeDifficulty(currentRecord.difficulty);
    final safeStability = normalizeStability(currentRecord.stability);

    // Stability contracts upon lapse; minimum floor of 1.0 day
    final nextStability = normalizeStability(safeStability * 0.5);

    // Harder difficulty adjustment on failure (max difficulty 3.0)
    final nextDifficulty = normalizeDifficulty(safeDifficulty + 0.2);

    // Lapse interval: immediate follow-up review in 1 day
    int intervalDays = 1;

    // Apply exam-proximity cap if in final review
    intervalDays = _capIntervalForExam(
      rawIntervalDays: intervalDays,
      daysUntilExam: daysUntilExam,
      examPhase: examPhase,
    );

    if (intervalDays < 1) intervalDays = 1;

    final nextReviewAt = eventTime.add(Duration(days: intervalDays));

    return SpacedScheduleResult(
      nextState: nextState,
      nextStability: nextStability,
      nextDifficulty: nextDifficulty,
      nextIntervalDays: intervalDays,
      nextReviewAt: nextReviewAt,
      reviewCount: currentRecord.reviewCount,
      lapseCount: nextLapseCount,
      consecutiveCorrect: 0,
    );
  }

  /// Evaluates a correct response (review retrieval or practice success).
  SpacedScheduleResult _evaluateSuccess({
    required QuestionMasteryRecord currentRecord,
    required DateTime eventTime,
    required int responseTimeSeconds,
    required int? daysUntilExam,
    required ExamPreparationPhase examPhase,
  }) {
    final nextConsecutive = currentRecord.consecutiveCorrect + 1;
    final nextReviewCount = currentRecord.reviewCount + 1;

    // Check if retrieval occurred across distinct days (Temporal Spacing Requirement)
    final bool hasTemporalSpacing;
    if (currentRecord.lastCorrectAt != null) {
      final hoursSinceLastCorrect =
          eventTime.difference(currentRecord.lastCorrectAt!).inHours;
      hasTemporalSpacing =
          hoursSinceLastCorrect >= 18; // At least across day boundaries
    } else {
      hasTemporalSpacing = false;
    }

    // Determine state transition
    MasteryState nextState;
    if (currentRecord.masteryState == MasteryState.relearning) {
      // Relearning items return to Mastered after 2 consecutive correct answers or 1 spaced retrieval
      if (nextConsecutive >= 2 || hasTemporalSpacing) {
        nextState = MasteryState.mastered;
      } else {
        nextState = MasteryState.relearning;
      }
    } else if (currentRecord.masteryState == MasteryState.mastered ||
        currentRecord.masteryState == MasteryState.atRisk) {
      nextState = MasteryState.mastered;
    } else if (currentRecord.masteryState == MasteryState.improving) {
      if (hasTemporalSpacing && nextConsecutive >= 2) {
        nextState = MasteryState.mastered;
      } else {
        nextState = MasteryState.improving;
      }
    } else {
      // newItem or learning
      if (nextConsecutive >= 2) {
        nextState = MasteryState.improving;
      } else {
        nextState = MasteryState.learning;
      }
    }

    final safeDifficulty = normalizeDifficulty(currentRecord.difficulty);
    final safeStability = normalizeStability(currentRecord.stability);

    // Difficulty slight reduction on fluent answer (< 30s response)
    double nextDifficulty = safeDifficulty;
    if (responseTimeSeconds > 0 && responseTimeSeconds < 30) {
      nextDifficulty = math.max(minDifficulty, nextDifficulty - 0.05);
    }
    nextDifficulty = normalizeDifficulty(nextDifficulty);

    // Stability progression factor based on difficulty
    // Easier items (D=1.0) increase stability faster than hard items (D=3.0)
    final stabilityMultiplier = 1.6 + (0.5 / nextDifficulty);
    final rawStability = currentRecord.masteryState == MasteryState.newItem
        ? 1.0
        : (safeStability * stabilityMultiplier);
    final nextStability = normalizeStability(rawStability);

    // Calculate base interval (in days)
    int intervalDays;
    if (nextState == MasteryState.mastered) {
      intervalDays = math.max(3, nextStability.round());
    } else if (nextState == MasteryState.improving) {
      intervalDays = 2;
    } else if (nextState == MasteryState.relearning) {
      intervalDays = 1;
    } else {
      intervalDays = 1;
    }

    // Phase-based interval compression for exam readiness
    intervalDays = _applyPhaseCompression(
      rawIntervalDays: intervalDays,
      examPhase: examPhase,
    );

    // Enforce exam-date capping (never schedule past the national exam date)
    intervalDays = _capIntervalForExam(
      rawIntervalDays: intervalDays,
      daysUntilExam: daysUntilExam,
      examPhase: examPhase,
    );

    if (intervalDays < 1) intervalDays = 1;

    final nextReviewAt = eventTime.add(Duration(days: intervalDays));

    return SpacedScheduleResult(
      nextState: nextState,
      nextStability: nextStability,
      nextDifficulty: nextDifficulty,
      nextIntervalDays: intervalDays,
      nextReviewAt: nextReviewAt,
      reviewCount: nextReviewCount,
      lapseCount: currentRecord.lapseCount,
      consecutiveCorrect: nextConsecutive,
    );
  }

  /// Compresses review intervals as the national exam date draws nearer.
  int _applyPhaseCompression({
    required int rawIntervalDays,
    required ExamPreparationPhase examPhase,
  }) {
    switch (examPhase) {
      case ExamPreparationPhase.foundation:
        return rawIntervalDays;
      case ExamPreparationPhase.consolidation:
        // 15% interval compression to build frequency
        return math.max(1, (rawIntervalDays * 0.85).round());
      case ExamPreparationPhase.intensive:
        // 30% interval compression
        return math.max(1, (rawIntervalDays * 0.70).round());
      case ExamPreparationPhase.finalReview:
        // Short intervals for rapid recall reinforcement
        return math.max(1, math.min(3, (rawIntervalDays * 0.40).round()));
    }
  }

  /// Strictly prevents scheduling reviews past the national exam date.
  int _capIntervalForExam({
    required int rawIntervalDays,
    required int? daysUntilExam,
    required ExamPreparationPhase examPhase,
  }) {
    if (daysUntilExam == null || daysUntilExam <= 0) {
      return rawIntervalDays;
    }

    // If national exam is within the scheduled interval, pull the review before the exam
    if (rawIntervalDays >= daysUntilExam) {
      return math.max(1, daysUntilExam - 1);
    }

    return rawIntervalDays;
  }
}

import 'package:uuid/uuid.dart';

import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../models/mastery_models.dart';
import '../repositories/mastery_repository.dart';
import 'mastery_aggregation_service.dart';
import 'spaced_repetition_scheduler.dart';

/// Centralized domain service that orchestrates question outcome processing,
/// spaced review scheduling, and target-level mastery aggregation.
class MasteryEngineService {
  final MasteryRepository _masteryRepo;
  final SpacedRepetitionScheduler _scheduler;
  final MasteryAggregationService _aggregationService;
  static const _uuid = Uuid();

  const MasteryEngineService({
    required MasteryRepository masteryRepo,
    SpacedRepetitionScheduler scheduler = const SpacedRepetitionScheduler(),
    MasteryAggregationService aggregationService =
        const MasteryAggregationService(),
  })  : _masteryRepo = masteryRepo,
        _scheduler = scheduler,
        _aggregationService = aggregationService;

  /// Central entry point for processing a question outcome.
  ///
  /// Evaluates spaced schedule, updates question mastery, logs review event,
  /// and updates target-level mastery.
  Future<QuestionMasteryRecord> processQuestionOutcome({
    required String userId,
    required Question question,
    required bool isCorrect,
    required String attemptId,
    int responseTimeSeconds = 0,
    DateTime? eventTime,
    DateTime? targetExamDate,
  }) async {
    final now = eventTime ?? DateTime.now();

    // 1. Fetch current question mastery or initialize new record
    final existing = await _masteryRepo.getQuestionMastery(userId, question.id);
    final initialDifficulty = _parseQuestionDifficulty(question.difficulty);

    final currentRecord = existing ??
        QuestionMasteryRecord(
          id: '${userId}_${question.id}',
          userId: userId,
          questionId: question.id,
          subjectId: question.subjectId,
          examVariant: question.examVariant,
          assessmentStructure: question.assessmentStructure,
          unitId: question.unitId.isNotEmpty ? question.unitId : null,
          topicId: question.topicId.isNotEmpty ? question.topicId : null,
          contentDomain: question.contentDomain,
          skill: question.skill,
          masteryState: MasteryState.newItem,
          difficulty: initialDifficulty,
          updatedAt: now,
        );

    // 2. Compute spaced schedule and next state via deterministic scheduler
    final scheduleResult = _scheduler.evaluateOutcome(
      currentRecord: currentRecord,
      isCorrect: isCorrect,
      eventTime: now,
      responseTimeSeconds: responseTimeSeconds,
      targetExamDate: targetExamDate,
    );

    // 3. Build updated question record
    final updatedRecord = currentRecord.copyWith(
      masteryState: scheduleResult.nextState,
      evidenceSource: EvidenceSource.native,
      attemptCount: currentRecord.attemptCount + 1,
      correctCount: isCorrect
          ? currentRecord.correctCount + 1
          : currentRecord.correctCount,
      incorrectCount: !isCorrect
          ? currentRecord.incorrectCount + 1
          : currentRecord.incorrectCount,
      consecutiveCorrect: scheduleResult.consecutiveCorrect,
      stability: scheduleResult.nextStability,
      difficulty: scheduleResult.nextDifficulty,
      reviewCount: scheduleResult.reviewCount,
      lapseCount: scheduleResult.lapseCount,
      lastSeenAt: now,
      lastCorrectAt: isCorrect ? now : currentRecord.lastCorrectAt,
      lastIncorrectAt: !isCorrect ? now : currentRecord.lastIncorrectAt,
      nextReviewAt: scheduleResult.nextReviewAt,
      updatedAt: now,
    );

    // 4. Persist updated question mastery
    await _masteryRepo.saveQuestionMastery(updatedRecord);

    // 5. Audit log review event
    final reviewEvent = ReviewEventRecord(
      id: _uuid.v4(),
      userId: userId,
      questionId: question.id,
      targetKey: _resolveTargetKey(question),
      subjectId: question.subjectId,
      examVariant: question.examVariant,
      reviewedAt: now,
      scheduledAt: currentRecord.nextReviewAt ?? now,
      isCorrect: isCorrect,
      timeSpentSeconds: responseTimeSeconds,
      previousState: currentRecord.masteryState,
      newState: scheduleResult.nextState,
      previousIntervalDays: currentRecord.stability.round(),
      newIntervalDays: scheduleResult.nextIntervalDays,
    );
    await _masteryRepo.recordReviewEvent(reviewEvent);

    return updatedRecord;
  }

  /// Incremental target-level mastery update after a set of questions are answered.
  Future<void> updateTargetMastery({
    required String userId,
    required String targetKey,
    required String subjectId,
    ExamVariantCode? examVariant,
    AssessmentStructure? assessmentStructure,
    String? unitId,
    String? topicId,
    String? contentDomain,
    String? skill,
    required String titleEn,
    required String titleAm,
    required List<Question> targetAvailableQuestions,
    DateTime? currentTime,
  }) async {
    final now = currentTime ?? DateTime.now();

    // Fetch question records for this subject/target
    final qRecords = await _masteryRepo.getQuestionMasteryList(
      userId,
      subjectId: subjectId,
      examVariant: examVariant,
    );

    final targetQIds = targetAvailableQuestions.map((q) => q.id).toSet();
    final targetQRecords =
        qRecords.where((r) => targetQIds.contains(r.questionId)).toList();

    final targetRecord = _aggregationService.aggregateTargetMastery(
      userId: userId,
      targetKey: targetKey,
      subjectId: subjectId,
      examVariant: examVariant,
      assessmentStructure: assessmentStructure,
      unitId: unitId,
      topicId: topicId,
      contentDomain: contentDomain,
      skill: skill,
      titleEn: titleEn,
      titleAm: titleAm,
      targetQuestionRecords: targetQRecords,
      targetAvailableQuestions: targetAvailableQuestions,
      currentTime: now,
    );

    await _masteryRepo.saveTargetMastery(targetRecord);
  }

  /// Fetches questions currently due for spaced review.
  Future<List<QuestionMasteryRecord>> getDueQuestionReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  }) async {
    return _masteryRepo.getDueQuestionReviews(
      userId,
      asOf: asOf ?? DateTime.now(),
      limit: limit,
    );
  }

  /// Fetches learning targets with reviews due.
  Future<List<LearningTargetMasteryRecord>> getDueTargetReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  }) async {
    return _masteryRepo.getDueTargetReviews(
      userId,
      asOf: asOf ?? DateTime.now(),
      limit: limit,
    );
  }

  /// Computes summary of mastery across a subject.
  Future<SubjectMasterySummary> getSubjectMasterySummary({
    required String userId,
    required String subjectId,
    ExamVariantCode? examVariant,
    DateTime? currentTime,
  }) async {
    final targets = await _masteryRepo.getTargetMasteryList(
      userId,
      subjectId: subjectId,
      examVariant: examVariant,
    );

    return _aggregationService.computeSubjectSummary(
      subjectId: subjectId,
      examVariant: examVariant,
      targetRecords: targets,
      currentTime: currentTime,
    );
  }

  /// Resolves the canonical learning-target key for a question.
  String _resolveTargetKey(Question q) {
    final rawTarget = q.topicId.isNotEmpty
        ? q.topicId
        : (q.skill ?? q.contentDomain ?? q.subjectId);
    return MasteryAggregationService.buildCanonicalTargetKey(
      subjectId: q.subjectId,
      examVariant: q.examVariant,
      unitId: q.unitId.isNotEmpty ? q.unitId : null,
      topicId: q.topicId.isNotEmpty ? q.topicId : null,
      contentDomain: q.contentDomain,
      skill: q.skill,
      rawTarget: rawTarget,
    );
  }

  /// Parses question difficulty string into a numeric weight (1.0 to 3.0).
  double _parseQuestionDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1.2;
      case 'hard':
        return 2.8;
      case 'medium':
      default:
        return 2.0;
    }
  }
}

import 'dart:math' as math;

import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../models/mastery_models.dart';

/// Service responsible for aggregating question-level mastery evidence
/// into curriculum-topic and skill-based learning-target mastery records.
class MasteryAggregationService {
  const MasteryAggregationService();

  /// Generates a globally unique, variant- and subject-qualified target key.
  /// Prevents any possible collision between Natural Math and Social Math,
  /// English domains, Aptitude skills, or across subjects with identical topic names.
  static String buildCanonicalTargetKey({
    required String subjectId,
    ExamVariantCode? examVariant,
    AssessmentStructure? assessmentStructure,
    String? unitId,
    String? topicId,
    String? contentDomain,
    String? skill,
    required String rawTarget,
  }) {
    final variantSegment = examVariant != null ? examVariant.name : 'shared';
    final prefix = '${subjectId}_$variantSegment';

    // If rawTarget is already fully qualified with subject and variant, return it
    if (rawTarget.startsWith(prefix)) {
      return rawTarget;
    }

    if (skill != null && skill.isNotEmpty) {
      final domainPart = (contentDomain != null && contentDomain.isNotEmpty)
          ? '${contentDomain}_'
          : '';
      return '${prefix}_$domainPart$skill';
    }

    if (contentDomain != null && contentDomain.isNotEmpty) {
      return '${prefix}_$contentDomain';
    }

    if (topicId != null && topicId.isNotEmpty) {
      final unitPart =
          (unitId != null && unitId.isNotEmpty) ? '${unitId}_' : '';
      return '${prefix}_$unitPart$topicId';
    }

    return '${prefix}_$rawTarget';
  }

  /// Aggregates question mastery records into a target mastery record.
  LearningTargetMasteryRecord aggregateTargetMastery({
    required String userId,
    required String targetKey,
    required String subjectId,
    required ExamVariantCode? examVariant,
    required AssessmentStructure? assessmentStructure,
    String? unitId,
    String? topicId,
    String? contentDomain,
    String? skill,
    required String titleEn,
    required String titleAm,
    required List<QuestionMasteryRecord> targetQuestionRecords,
    required List<Question> targetAvailableQuestions,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    final canonicalKey = buildCanonicalTargetKey(
      subjectId: subjectId,
      examVariant: examVariant,
      assessmentStructure: assessmentStructure,
      unitId: unitId,
      topicId: topicId,
      contentDomain: contentDomain,
      skill: skill,
      rawTarget: targetKey,
    );

    final totalAvailable = targetAvailableQuestions.length;
    final attemptedQuestions =
        targetQuestionRecords.where((r) => r.attemptCount > 0).toList();
    final coveredCount = attemptedQuestions.length;

    int totalAttempts = 0;
    int totalCorrect = 0;
    int masteredCount = 0;
    int atRiskCount = 0;
    int relearningCount = 0;
    DateTime? latestPracticed;
    DateTime? earliestNextReview;

    for (final qRecord in attemptedQuestions) {
      totalAttempts += qRecord.attemptCount;
      totalCorrect += qRecord.correctCount;

      if (qRecord.masteryState == MasteryState.mastered) {
        masteredCount++;
      } else if (qRecord.masteryState == MasteryState.atRisk) {
        atRiskCount++;
      } else if (qRecord.masteryState == MasteryState.relearning) {
        relearningCount++;
      }

      if (qRecord.lastSeenAt != null) {
        if (latestPracticed == null ||
            qRecord.lastSeenAt!.isAfter(latestPracticed)) {
          latestPracticed = qRecord.lastSeenAt;
        }
      }

      if (qRecord.nextReviewAt != null) {
        if (earliestNextReview == null ||
            qRecord.nextReviewAt!.isBefore(earliestNextReview)) {
          earliestNextReview = qRecord.nextReviewAt;
        }
      }
    }

    final double accuracy =
        totalAttempts > 0 ? ((totalCorrect / totalAttempts) * 100.0) : 0.0;

    // Determine target-level mastery state
    final MasteryState targetState;
    if (coveredCount == 0 || totalAttempts == 0) {
      targetState = MasteryState.newItem;
    } else if (relearningCount > 0) {
      targetState = MasteryState.relearning;
    } else if (atRiskCount > 0 ||
        (earliestNextReview != null && now.isAfter(earliestNextReview))) {
      targetState = MasteryState.atRisk;
    } else if (masteredCount >= 2 &&
        accuracy >= 75.0 &&
        (coveredCount >= math.min(3, totalAvailable))) {
      targetState = MasteryState.mastered;
    } else if ((masteredCount >= 1 || accuracy >= 65.0) && totalAttempts >= 2) {
      targetState = MasteryState.improving;
    } else {
      targetState = MasteryState.learning;
    }

    // Determine target evidence source provenance
    final hasNativeEvidence = attemptedQuestions.any(
      (r) => r.evidenceSource == EvidenceSource.native,
    );
    final targetEvidenceSource =
        (attemptedQuestions.isNotEmpty && !hasNativeEvidence)
            ? EvidenceSource.legacyMigration
            : EvidenceSource.native;

    return LearningTargetMasteryRecord(
      id: '${userId}_$canonicalKey',
      userId: userId,
      targetKey: canonicalKey,
      subjectId: subjectId,
      examVariant: examVariant,
      assessmentStructure: assessmentStructure,
      unitId: unitId,
      topicId: topicId,
      contentDomain: contentDomain,
      skill: skill,
      titleEn: titleEn,
      titleAm: titleAm,
      masteryState: targetState,
      evidenceSource: targetEvidenceSource,
      accuracyPercentage: double.parse(accuracy.toStringAsFixed(1)),
      totalAttempts: totalAttempts,
      masteredQuestionCount: masteredCount,
      coveredQuestionCount: coveredCount,
      totalAvailableQuestions: totalAvailable,
      nextReviewAt: earliestNextReview,
      lastPracticedAt: latestPracticed,
      updatedAt: now,
    );
  }

  /// Calculates high-level subject mastery summary.
  SubjectMasterySummary computeSubjectSummary({
    required String subjectId,
    required ExamVariantCode? examVariant,
    required List<LearningTargetMasteryRecord> targetRecords,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    int mastered = 0;
    int improving = 0;
    int atRisk = 0;
    int newItem = 0;
    int reviewsDue = 0;
    double totalAccuracy = 0.0;
    int attemptedTargets = 0;

    for (final target in targetRecords) {
      switch (target.masteryState) {
        case MasteryState.mastered:
          mastered++;
          break;
        case MasteryState.improving:
          improving++;
          break;
        case MasteryState.atRisk:
        case MasteryState.relearning:
          atRisk++;
          break;
        case MasteryState.newItem:
        case MasteryState.learning:
          newItem++;
          break;
      }

      if (target.nextReviewAt != null && now.isAfter(target.nextReviewAt!)) {
        reviewsDue++;
      }

      if (target.totalAttempts > 0) {
        totalAccuracy += target.accuracyPercentage;
        attemptedTargets++;
      }
    }

    final double avgAccuracy =
        attemptedTargets > 0 ? (totalAccuracy / attemptedTargets) : 0.0;

    return SubjectMasterySummary(
      subjectId: subjectId,
      examVariant: examVariant,
      masteredTargets: mastered,
      improvingTargets: improving,
      atRiskTargets: atRisk,
      newTargets: newItem,
      reviewsDue: reviewsDue,
      averageAccuracy: double.parse(avgAccuracy.toStringAsFixed(1)),
    );
  }
}

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/mastery_models.dart';
import '../../domain/repositories/mastery_repository.dart';

/// Drift/SQLite implementation of [MasteryRepository].
class DriftMasteryRepository implements MasteryRepository {
  final AppDatabase _db;

  const DriftMasteryRepository({required AppDatabase db}) : _db = db;

  QuestionMasteryRecord _toDomainQuestionMastery(DbQuestionMasteryRow r) {
    return QuestionMasteryRecord(
      id: r.id,
      userId: r.userId,
      questionId: r.questionId,
      subjectId: r.subjectId,
      examVariant: r.examVariant != null
          ? ExamVariantCode.fromString(r.examVariant!)
          : null,
      assessmentStructure: r.assessmentStructure != null
          ? AssessmentStructure.fromString(r.assessmentStructure!)
          : null,
      unitId: r.unitId,
      topicId: r.topicId,
      contentDomain: r.contentDomain,
      skill: r.skill,
      masteryState: MasteryState.fromString(r.masteryState),
      attemptCount: r.attemptCount,
      correctCount: r.correctCount,
      incorrectCount: r.incorrectCount,
      consecutiveCorrect: r.consecutiveCorrect,
      stability: r.stability,
      difficulty: r.difficulty,
      reviewCount: r.reviewCount,
      lapseCount: r.lapseCount,
      lastSeenAt: r.lastSeenAt,
      lastCorrectAt: r.lastCorrectAt,
      lastIncorrectAt: r.lastIncorrectAt,
      nextReviewAt: r.nextReviewAt,
      algorithmVersion: r.algorithmVersion,
      evidenceSource: EvidenceSource.fromString(r.evidenceSource),
      updatedAt: r.updatedAt,
    );
  }

  LearningTargetMasteryRecord _toDomainLearningTargetMastery(
      DbLearningTargetMasteryRow r) {
    return LearningTargetMasteryRecord(
      id: r.id,
      userId: r.userId,
      targetKey: r.targetKey,
      subjectId: r.subjectId,
      examVariant: r.examVariant != null
          ? ExamVariantCode.fromString(r.examVariant!)
          : null,
      assessmentStructure: r.assessmentStructure != null
          ? AssessmentStructure.fromString(r.assessmentStructure!)
          : null,
      unitId: r.unitId,
      topicId: r.topicId,
      contentDomain: r.contentDomain,
      skill: r.skill,
      titleEn: r.titleEn,
      titleAm: r.titleAm,
      masteryState: MasteryState.fromString(r.masteryState),
      evidenceSource: EvidenceSource.fromString(r.evidenceSource),
      accuracyPercentage: r.accuracyPercentage,
      totalAttempts: r.totalAttempts,
      masteredQuestionCount: r.masteredQuestionCount,
      coveredQuestionCount: r.coveredQuestionCount,
      totalAvailableQuestions: r.totalAvailableQuestions,
      nextReviewAt: r.nextReviewAt,
      lastPracticedAt: r.lastPracticedAt,
      updatedAt: r.updatedAt,
    );
  }

  ReviewEventRecord _toDomainReviewEvent(DbReviewEventRow r) {
    return ReviewEventRecord(
      id: r.id,
      userId: r.userId,
      questionId: r.questionId,
      targetKey: r.targetKey,
      subjectId: r.subjectId,
      examVariant: r.examVariant != null
          ? ExamVariantCode.fromString(r.examVariant!)
          : null,
      reviewedAt: r.reviewedAt,
      scheduledAt: r.scheduledAt,
      isCorrect: r.isCorrect,
      timeSpentSeconds: r.timeSpentSeconds,
      previousState: MasteryState.fromString(r.previousState),
      newState: MasteryState.fromString(r.newState),
      previousIntervalDays: r.previousIntervalDays,
      newIntervalDays: r.newIntervalDays,
      algorithmVersion: r.algorithmVersion,
    );
  }

  @override
  Future<QuestionMasteryRecord?> getQuestionMastery(
    String userId,
    String questionId,
  ) async {
    final query = _db.select(_db.dbQuestionMastery)
      ..where((tbl) =>
          tbl.userId.equals(userId) & tbl.questionId.equals(questionId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomainQuestionMastery(row);
  }

  @override
  Future<List<QuestionMasteryRecord>> getQuestionMasteryList(
    String userId, {
    String? subjectId,
    ExamVariantCode? examVariant,
  }) async {
    var query = _db.select(_db.dbQuestionMastery)
      ..where((tbl) => tbl.userId.equals(userId));

    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }
    if (examVariant != null) {
      query = query..where((tbl) => tbl.examVariant.equals(examVariant.name));
    }

    final rows = await query.get();
    return rows.map(_toDomainQuestionMastery).toList();
  }

  @override
  Future<void> saveQuestionMastery(QuestionMasteryRecord record) async {
    await _db.into(_db.dbQuestionMastery).insertOnConflictUpdate(
          DbQuestionMasteryCompanion(
            id: Value(record.id),
            userId: Value(record.userId),
            questionId: Value(record.questionId),
            subjectId: Value(record.subjectId),
            examVariant: Value(record.examVariant?.name),
            assessmentStructure: Value(record.assessmentStructure?.name),
            unitId: Value(record.unitId),
            topicId: Value(record.topicId),
            contentDomain: Value(record.contentDomain),
            skill: Value(record.skill),
            masteryState: Value(record.masteryState.toDbString()),
            attemptCount: Value(record.attemptCount),
            correctCount: Value(record.correctCount),
            incorrectCount: Value(record.incorrectCount),
            consecutiveCorrect: Value(record.consecutiveCorrect),
            stability: Value(record.stability),
            difficulty: Value(record.difficulty),
            reviewCount: Value(record.reviewCount),
            lapseCount: Value(record.lapseCount),
            lastSeenAt: Value(record.lastSeenAt),
            lastCorrectAt: Value(record.lastCorrectAt),
            lastIncorrectAt: Value(record.lastIncorrectAt),
            nextReviewAt: Value(record.nextReviewAt),
            algorithmVersion: Value(record.algorithmVersion),
            evidenceSource: Value(record.evidenceSource.toDbString()),
            updatedAt: Value(record.updatedAt),
          ),
        );
  }

  @override
  Future<void> saveQuestionMasteryBatch(
      List<QuestionMasteryRecord> records) async {
    if (records.isEmpty) return;
    await _db.batch((b) {
      for (final r in records) {
        b.insert(
          _db.dbQuestionMastery,
          DbQuestionMasteryCompanion(
            id: Value(r.id),
            userId: Value(r.userId),
            questionId: Value(r.questionId),
            subjectId: Value(r.subjectId),
            examVariant: Value(r.examVariant?.name),
            assessmentStructure: Value(r.assessmentStructure?.name),
            unitId: Value(r.unitId),
            topicId: Value(r.topicId),
            contentDomain: Value(r.contentDomain),
            skill: Value(r.skill),
            masteryState: Value(r.masteryState.toDbString()),
            attemptCount: Value(r.attemptCount),
            correctCount: Value(r.correctCount),
            incorrectCount: Value(r.incorrectCount),
            consecutiveCorrect: Value(r.consecutiveCorrect),
            stability: Value(r.stability),
            difficulty: Value(r.difficulty),
            reviewCount: Value(r.reviewCount),
            lapseCount: Value(r.lapseCount),
            lastSeenAt: Value(r.lastSeenAt),
            lastCorrectAt: Value(r.lastCorrectAt),
            lastIncorrectAt: Value(r.lastIncorrectAt),
            nextReviewAt: Value(r.nextReviewAt),
            algorithmVersion: Value(r.algorithmVersion),
            evidenceSource: Value(r.evidenceSource.toDbString()),
            updatedAt: Value(r.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<LearningTargetMasteryRecord?> getTargetMastery(
    String userId,
    String targetKey,
  ) async {
    final query = _db.select(_db.dbLearningTargetMastery)
      ..where(
          (tbl) => tbl.userId.equals(userId) & tbl.targetKey.equals(targetKey));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomainLearningTargetMastery(row);
  }

  @override
  Future<List<LearningTargetMasteryRecord>> getTargetMasteryList(
    String userId, {
    String? subjectId,
    ExamVariantCode? examVariant,
  }) async {
    var query = _db.select(_db.dbLearningTargetMastery)
      ..where((tbl) => tbl.userId.equals(userId));

    if (subjectId != null) {
      query = query..where((tbl) => tbl.subjectId.equals(subjectId));
    }
    if (examVariant != null) {
      query = query..where((tbl) => tbl.examVariant.equals(examVariant.name));
    }

    final rows = await query.get();
    return rows.map(_toDomainLearningTargetMastery).toList();
  }

  @override
  Future<void> saveTargetMastery(LearningTargetMasteryRecord record) async {
    await _db.into(_db.dbLearningTargetMastery).insertOnConflictUpdate(
          DbLearningTargetMasteryCompanion(
            id: Value(record.id),
            userId: Value(record.userId),
            targetKey: Value(record.targetKey),
            subjectId: Value(record.subjectId),
            examVariant: Value(record.examVariant?.name),
            assessmentStructure: Value(record.assessmentStructure?.name),
            unitId: Value(record.unitId),
            topicId: Value(record.topicId),
            contentDomain: Value(record.contentDomain),
            skill: Value(record.skill),
            titleEn: Value(record.titleEn),
            titleAm: Value(record.titleAm),
            masteryState: Value(record.masteryState.toDbString()),
            evidenceSource: Value(record.evidenceSource.toDbString()),
            accuracyPercentage: Value(record.accuracyPercentage),
            totalAttempts: Value(record.totalAttempts),
            masteredQuestionCount: Value(record.masteredQuestionCount),
            coveredQuestionCount: Value(record.coveredQuestionCount),
            totalAvailableQuestions: Value(record.totalAvailableQuestions),
            nextReviewAt: Value(record.nextReviewAt),
            lastPracticedAt: Value(record.lastPracticedAt),
            updatedAt: Value(record.updatedAt),
          ),
        );
  }

  @override
  Future<void> saveTargetMasteryBatch(
      List<LearningTargetMasteryRecord> records) async {
    if (records.isEmpty) return;
    await _db.batch((b) {
      for (final r in records) {
        b.insert(
          _db.dbLearningTargetMastery,
          DbLearningTargetMasteryCompanion(
            id: Value(r.id),
            userId: Value(r.userId),
            targetKey: Value(r.targetKey),
            subjectId: Value(r.subjectId),
            examVariant: Value(r.examVariant?.name),
            assessmentStructure: Value(r.assessmentStructure?.name),
            unitId: Value(r.unitId),
            topicId: Value(r.topicId),
            contentDomain: Value(r.contentDomain),
            skill: Value(r.skill),
            titleEn: Value(r.titleEn),
            titleAm: Value(r.titleAm),
            masteryState: Value(r.masteryState.toDbString()),
            evidenceSource: Value(r.evidenceSource.toDbString()),
            accuracyPercentage: Value(r.accuracyPercentage),
            totalAttempts: Value(r.totalAttempts),
            masteredQuestionCount: Value(r.masteredQuestionCount),
            coveredQuestionCount: Value(r.coveredQuestionCount),
            totalAvailableQuestions: Value(r.totalAvailableQuestions),
            nextReviewAt: Value(r.nextReviewAt),
            lastPracticedAt: Value(r.lastPracticedAt),
            updatedAt: Value(r.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<List<QuestionMasteryRecord>> getDueQuestionReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  }) async {
    final effectiveDate = asOf ?? DateTime.now();

    var query = _db.select(_db.dbQuestionMastery)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          tbl.nextReviewAt.isNotNull() &
          tbl.nextReviewAt.isSmallerOrEqualValue(effectiveDate))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.nextReviewAt),
      ]);

    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }

    final rows = await query.get();
    return rows.map(_toDomainQuestionMastery).toList();
  }

  @override
  Future<List<LearningTargetMasteryRecord>> getDueTargetReviews(
    String userId, {
    DateTime? asOf,
    int? limit,
  }) async {
    final effectiveDate = asOf ?? DateTime.now();

    var query = _db.select(_db.dbLearningTargetMastery)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          tbl.nextReviewAt.isNotNull() &
          tbl.nextReviewAt.isSmallerOrEqualValue(effectiveDate))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.nextReviewAt),
      ]);

    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }

    final rows = await query.get();
    return rows.map(_toDomainLearningTargetMastery).toList();
  }

  @override
  Future<void> recordReviewEvent(ReviewEventRecord event) async {
    await _db.into(_db.dbReviewEvents).insert(
          DbReviewEventsCompanion(
            id: Value(event.id),
            userId: Value(event.userId),
            questionId: Value(event.questionId),
            targetKey: Value(event.targetKey),
            subjectId: Value(event.subjectId),
            examVariant: Value(event.examVariant?.name),
            reviewedAt: Value(event.reviewedAt),
            scheduledAt: Value(event.scheduledAt),
            isCorrect: Value(event.isCorrect),
            timeSpentSeconds: Value(event.timeSpentSeconds),
            previousState: Value(event.previousState.toDbString()),
            newState: Value(event.newState.toDbString()),
            previousIntervalDays: Value(event.previousIntervalDays),
            newIntervalDays: Value(event.newIntervalDays),
            algorithmVersion: Value(event.algorithmVersion),
          ),
        );
  }

  @override
  Future<List<ReviewEventRecord>> getReviewEvents(
    String userId, {
    String? targetKey,
    int? limit,
  }) async {
    var query = _db.select(_db.dbReviewEvents)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.reviewedAt)]);

    if (targetKey != null) {
      query = query..where((tbl) => tbl.targetKey.equals(targetKey));
    }
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }

    final rows = await query.get();
    return rows.map(_toDomainReviewEvent).toList();
  }
}

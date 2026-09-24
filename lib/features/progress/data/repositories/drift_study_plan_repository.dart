import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/app_database.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../domain/models/study_plan_models.dart';
import '../../domain/repositories/study_plan_repository.dart';

class DriftStudyPlanRepository implements StudyPlanRepository {
  final AppDatabase _db;
  final SharedPreferences? _prefs;

  static const String _kSettingsPrefix = 'fidel_planner_settings_';

  DriftStudyPlanRepository({
    required AppDatabase db,
    SharedPreferences? prefs,
  })  : _db = db,
        _prefs = prefs;

  @override
  Future<StudyPlan?> getStudyPlan(String userId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final planQuery = _db.select(_db.dbStudyPlans)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          tbl.planDate.isBiggerOrEqualValue(startOfDay) &
          tbl.planDate.isSmallerThanValue(endOfDay))
      ..limit(1);

    final dbPlan = await planQuery.getSingleOrNull();
    if (dbPlan == null) return null;

    final sessionQuery = _db.select(_db.dbStudyPlanSessions)
      ..where((tbl) => tbl.planId.equals(dbPlan.id));

    final dbSessions = await sessionQuery.get();
    return _mapDbToDomain(dbPlan, dbSessions);
  }

  @override
  Stream<StudyPlan?> watchStudyPlan(String userId, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final startOfDay =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final planStream = (_db.select(_db.dbStudyPlans)
          ..where((tbl) =>
              tbl.userId.equals(userId) &
              tbl.planDate.isBiggerOrEqualValue(startOfDay) &
              tbl.planDate.isSmallerThanValue(endOfDay))
          ..limit(1))
        .watchSingleOrNull();

    return planStream.asyncMap((dbPlan) async {
      if (dbPlan == null) return null;
      final dbSessions = await (_db.select(_db.dbStudyPlanSessions)
            ..where((tbl) => tbl.planId.equals(dbPlan.id)))
          .get();
      return _mapDbToDomain(dbPlan, dbSessions);
    });
  }

  @override
  Future<void> saveStudyPlan(StudyPlan plan) async {
    await _db.transaction(() async {
      await _db.into(_db.dbStudyPlans).insertOnConflictUpdate(
            DbStudyPlansCompanion(
              id: Value(plan.id),
              userId: Value(plan.userId),
              planDate: Value(DateTime(
                  plan.planDate.year, plan.planDate.month, plan.planDate.day)),
              targetMinutes: Value(plan.targetMinutes),
              estimatedMinutes: Value(plan.estimatedMinutes),
              status: Value(plan.status.toDbString()),
              algorithmVersion: Value(plan.algorithmVersion),
              generatedAt: Value(plan.generatedAt),
            ),
          );

      for (final s in plan.sessions) {
        await _db.into(_db.dbStudyPlanSessions).insertOnConflictUpdate(
              DbStudyPlanSessionsCompanion(
                id: Value(s.id),
                planId: Value(s.planId),
                subjectId: Value(s.subjectId),
                unitId: Value(s.unitId),
                topicId: Value(s.topicId),
                examVariant: Value(s.examVariant?.name),
                assessmentStructure: Value(s.assessmentStructure?.name),
                contentDomain: Value(s.contentDomain),
                skill: Value(s.skill),
                sessionType: Value(s.sessionType.toDbString()),
                titleEn: Value(s.titleEn),
                titleAm: Value(s.titleAm),
                questionTarget: Value(s.questionTarget),
                estimatedMinutes: Value(s.estimatedMinutes),
                priorityScore: Value(s.priorityScore),
                reasonCode: Value(s.reasonCode.toDbString()),
                reasonDetailEn: Value(s.reasonDetailEn),
                reasonDetailAm: Value(s.reasonDetailAm),
                status: Value(s.status.toDbString()),
                questionIdsJson: Value(jsonEncode(s.questionIds)),
                completedAt: Value(s.completedAt),
                timeSpentSeconds: Value(s.timeSpentSeconds),
                scorePercentage: Value(s.scorePercentage),
              ),
            );
      }
    });
  }

  @override
  Future<void> updateSessionStatus({
    required String sessionId,
    required SessionCompletionStatus status,
    DateTime? completedAt,
    int? timeSpentSeconds,
    double? scorePercentage,
  }) async {
    await _db.transaction(() async {
      // 1. Fetch current session
      final sessionQuery = _db.select(_db.dbStudyPlanSessions)
        ..where((tbl) => tbl.id.equals(sessionId))
        ..limit(1);
      final session = await sessionQuery.getSingleOrNull();
      if (session == null) return;

      // 2. Update session
      await (_db.update(_db.dbStudyPlanSessions)
            ..where((tbl) => tbl.id.equals(sessionId)))
          .write(
        DbStudyPlanSessionsCompanion(
          status: Value(status.toDbString()),
          completedAt: Value(completedAt ?? DateTime.now()),
          timeSpentSeconds: timeSpentSeconds != null
              ? Value(timeSpentSeconds)
              : const Value.absent(),
          scorePercentage: scorePercentage != null
              ? Value(scorePercentage)
              : const Value.absent(),
        ),
      );

      // 3. Re-evaluate parent plan status
      final allSessions = await (_db.select(_db.dbStudyPlanSessions)
            ..where((tbl) => tbl.planId.equals(session.planId)))
          .get();

      final allCompleted = allSessions.every((s) {
        final sStatus = s.id == sessionId ? status.toDbString() : s.status;
        return sStatus == 'completed';
      });

      final anyStarted = allSessions.any((s) {
        final sStatus = s.id == sessionId ? status.toDbString() : s.status;
        return sStatus == 'in_progress' || sStatus == 'completed';
      });

      final newPlanStatus = allCompleted
          ? 'completed'
          : (anyStarted ? 'in_progress' : 'not_started');

      await (_db.update(_db.dbStudyPlans)
            ..where((tbl) => tbl.id.equals(session.planId)))
          .write(
        DbStudyPlansCompanion(
          status: Value(newPlanStatus),
        ),
      );
    });
  }

  final Map<String, String> _inMemorySettings = {};

  @override
  Future<PlannerSettings> getPlannerSettings(String userId) async {
    final cached = _inMemorySettings[userId];
    if (cached != null) {
      try {
        return PlannerSettings.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {}
    }
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString('$_kSettingsPrefix$userId');
      if (raw != null) {
        _inMemorySettings[userId] = raw;
        return PlannerSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}

    // Default target: 75 days out from today
    return PlannerSettings(
      dailyBudgetMinutes: 45,
      targetExamDate: DateTime.now().add(const Duration(days: 75)),
      includeWeekends: true,
    );
  }

  @override
  Future<void> savePlannerSettings(
      String userId, PlannerSettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    _inMemorySettings[userId] = encoded;
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString('$_kSettingsPrefix$userId', encoded);
    } catch (_) {}
  }

  StudyPlan _mapDbToDomain(
      DbStudyPlan plan, List<DbStudyPlanSession> dbSessions) {
    final domainSessions = dbSessions.map((s) {
      List<String> qIds = [];
      try {
        final decoded = jsonDecode(s.questionIdsJson) as List<dynamic>;
        qIds = decoded.map((e) => e.toString()).toList();
      } catch (_) {}

      ExamVariantCode? variant;
      if (s.examVariant != null) {
        variant = ExamVariantCode.values.firstWhere(
          (v) => v.name == s.examVariant,
          orElse: () => ExamVariantCode.shared,
        );
      } else {
        // Safe legacy fallback derivation for existing v3 sessions
        final sId = s.subjectId.toLowerCase();
        if (sId.contains('eng') || sId.contains('apt')) {
          variant = ExamVariantCode.shared;
        } else if (sId.contains('bio') ||
            sId.contains('phys') ||
            sId.contains('chem')) {
          variant = ExamVariantCode.naturalScience;
        } else if (sId.contains('hist') ||
            sId.contains('geo') ||
            sId.contains('econ')) {
          variant = ExamVariantCode.socialScience;
        }
        // Ambiguous Math legacy sessions are left null for safety
      }

      AssessmentStructure? structure;
      if (s.assessmentStructure != null) {
        structure = AssessmentStructure.values.firstWhere(
          (a) => a.name == s.assessmentStructure,
          orElse: () => AssessmentStructure.curriculum,
        );
      } else {
        final sId = s.subjectId.toLowerCase();
        if (sId.contains('apt')) {
          structure = AssessmentStructure.skillBased;
        } else if (sId.contains('eng')) {
          structure = AssessmentStructure.mixed;
        } else {
          structure = AssessmentStructure.curriculum;
        }
      }

      return StudyPlanSession(
        id: s.id,
        planId: s.planId,
        subjectId: s.subjectId,
        unitId: s.unitId,
        topicId: s.topicId,
        examVariant: variant,
        assessmentStructure: structure,
        contentDomain: s.contentDomain,
        skill: s.skill,
        sessionType: StudySessionType.fromString(s.sessionType),
        titleEn: s.titleEn,
        titleAm: s.titleAm,
        questionTarget: s.questionTarget,
        estimatedMinutes: s.estimatedMinutes,
        priorityScore: s.priorityScore,
        reasonCode: RecommendationReasonCode.fromString(s.reasonCode),
        reasonDetailEn: s.reasonDetailEn,
        reasonDetailAm: s.reasonDetailAm,
        status: SessionCompletionStatus.fromString(s.status),
        questionIds: qIds,
        completedAt: s.completedAt,
        timeSpentSeconds: s.timeSpentSeconds,
        scorePercentage: s.scorePercentage,
      );
    }).toList();

    return StudyPlan(
      id: plan.id,
      userId: plan.userId,
      planDate: plan.planDate,
      targetMinutes: plan.targetMinutes,
      estimatedMinutes: plan.estimatedMinutes,
      sessions: domainSessions,
      status: SessionCompletionStatus.fromString(plan.status),
      algorithmVersion: plan.algorithmVersion,
      generatedAt: plan.generatedAt,
    );
  }
}

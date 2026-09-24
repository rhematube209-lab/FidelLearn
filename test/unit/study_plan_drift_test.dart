import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_study_plan_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';

void main() {
  group('DriftStudyPlanRepository SQLite Contract Tests', () {
    late AppDatabase db;
    late DriftStudyPlanRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = DriftStudyPlanRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Saves and retrieves study plan and sessions', () async {
      final now = DateTime(2026, 9, 24);
      final plan = StudyPlan(
        id: 'plan_s1_2026-09-24',
        userId: 'student_001',
        planDate: now,
        targetMinutes: 45,
        estimatedMinutes: 42,
        sessions: const [
          StudyPlanSession(
            id: 'sess_1',
            planId: 'plan_s1_2026-09-24',
            subjectId: 'physics_g12',
            unitId: 'u_em',
            topicId: 't_ind',
            sessionType: StudySessionType.weakTopicPractice,
            titleEn: 'Physics: Electromagnetic Induction',
            titleAm: 'ፊዚክስ፦ ኤሌክትሮማግኔቲክ ኢንዳክሽን',
            questionTarget: 10,
            estimatedMinutes: 15,
            priorityScore: 82.5,
            reasonCode: RecommendationReasonCode.weakTopic,
            reasonDetailEn: 'Accuracy is 45% in this topic.',
            reasonDetailAm: 'በዚህ ርዕስ 45% ውጤት አስመዝግበዋል።',
            status: SessionCompletionStatus.notStarted,
            questionIds: ['q1', 'q2', 'q3'],
          ),
          StudyPlanSession(
            id: 'sess_2',
            planId: 'plan_s1_2026-09-24',
            subjectId: 'math_g12',
            unitId: 'u_calc',
            topicId: 't_lim',
            sessionType: StudySessionType.curriculumCoverage,
            titleEn: 'Math: Limits',
            titleAm: 'ሒሳብ፦ ሊሚቶች',
            questionTarget: 8,
            estimatedMinutes: 12,
            priorityScore: 60.0,
            reasonCode: RecommendationReasonCode.newCurriculum,
            reasonDetailEn: 'Unpracticed topic.',
            reasonDetailAm: 'እስካሁን ያልተሰራ ርዕስ።',
            status: SessionCompletionStatus.notStarted,
            questionIds: ['qm1', 'qm2'],
          ),
        ],
        status: SessionCompletionStatus.notStarted,
        algorithmVersion: 'adaptive_planner_v1',
        generatedAt: now,
      );

      // Save plan
      await repository.saveStudyPlan(plan);

      // Retrieve plan
      final retrieved = await repository.getStudyPlan('student_001', date: now);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, plan.id);
      expect(retrieved.sessions.length, 2);
      expect(retrieved.sessions[0].id, 'sess_1');
      expect(retrieved.sessions[0].questionIds, ['q1', 'q2', 'q3']);
      expect(retrieved.sessions[1].titleEn, 'Math: Limits');
    });

    test('2. Updates session status and updates plan status', () async {
      final now = DateTime(2026, 9, 24);
      final plan = StudyPlan(
        id: 'plan_s2_2026-09-24',
        userId: 'student_002',
        planDate: now,
        targetMinutes: 30,
        estimatedMinutes: 25,
        sessions: const [
          StudyPlanSession(
            id: 'sess_only',
            planId: 'plan_s2_2026-09-24',
            subjectId: 'chemistry_g12',
            sessionType: StudySessionType.weakTopicPractice,
            titleEn: 'Organic Chemistry',
            titleAm: 'ኦርጋኒክ ኬሚስትሪ',
            questionTarget: 10,
            estimatedMinutes: 15,
            priorityScore: 75.0,
            reasonCode: RecommendationReasonCode.weakTopic,
            reasonDetailEn: 'Low accuracy',
            reasonDetailAm: 'ዝቅተኛ ውጤት',
            status: SessionCompletionStatus.notStarted,
          ),
        ],
        status: SessionCompletionStatus.notStarted,
        generatedAt: now,
      );

      await repository.saveStudyPlan(plan);

      // Complete session
      await repository.updateSessionStatus(
        sessionId: 'sess_only',
        status: SessionCompletionStatus.completed,
        completedAt: now,
        timeSpentSeconds: 620,
        scorePercentage: 85.0,
      );

      final updated = await repository.getStudyPlan('student_002', date: now);
      expect(updated, isNotNull);
      expect(updated!.sessions.first.status, SessionCompletionStatus.completed);
      expect(updated.sessions.first.scorePercentage, 85.0);
      expect(updated.status, SessionCompletionStatus.completed);
      expect(updated.isFullyCompleted, isTrue);
    });

    test('3. Watch study plan stream emits reactive updates', () async {
      final now = DateTime(2026, 9, 24);
      final plan = StudyPlan(
        id: 'plan_stream_2026-09-24',
        userId: 'student_stream',
        planDate: now,
        targetMinutes: 45,
        estimatedMinutes: 30,
        sessions: const [
          StudyPlanSession(
            id: 'sess_stream_1',
            planId: 'plan_stream_2026-09-24',
            subjectId: 'physics_g12',
            sessionType: StudySessionType.curriculumCoverage,
            titleEn: 'Physics',
            titleAm: 'ፊዚክስ',
            questionTarget: 5,
            estimatedMinutes: 10,
            priorityScore: 50.0,
            reasonCode: RecommendationReasonCode.newCurriculum,
            reasonDetailEn: 'New',
            reasonDetailAm: 'አዲስ',
          ),
        ],
        generatedAt: now,
      );

      final stream = repository.watchStudyPlan('student_stream', date: now);

      // Initially null
      expect(await stream.first, isNull);

      // Save plan
      await repository.saveStudyPlan(plan);

      // Stream emits populated plan
      final emitted = await stream.firstWhere((p) => p != null);
      expect(emitted!.sessions.length, 1);
      expect(emitted.sessions.first.id, 'sess_stream_1');
    });

    test('4. Planner settings default and custom values', () async {
      // Default preferences
      final defaults = await repository.getPlannerSettings('student_pref');
      expect(defaults.dailyBudgetMinutes, 45);
      expect(defaults.includeWeekends, isTrue);

      // Save updated preferences
      final customDate = DateTime(2027, 6, 15);
      final custom = PlannerSettings(
        dailyBudgetMinutes: 90,
        targetExamDate: customDate,
        includeWeekends: false,
      );
      await repository.savePlannerSettings('student_pref', custom);

      final saved = await repository.getPlannerSettings('student_pref');
      expect(saved.dailyBudgetMinutes, 90);
      expect(saved.targetExamDate.year, 2027);
      expect(saved.includeWeekends, isFalse);
    });
  });
}

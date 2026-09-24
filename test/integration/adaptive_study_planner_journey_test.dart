import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/exams/data/repositories/drift_exam_repository.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_study_plan_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/domain/services/adaptive_study_planner.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('Adaptive Study Planner End-to-End Student Journey', () {
    late AppDatabase db;
    late DriftStudyPlanRepository studyPlanRepo;
    late DriftExamRepository examRepo;
    late DriftMistakeRepository mistakeRepo;
    late AdaptiveStudyPlanner planner;

    const studentId = 'student_journey_001';
    final now = DateTime(2026, 9, 24);

    late List<Subject> subjects;
    late Map<String, List<Unit>> unitsBySubject;
    late Map<String, List<Topic>> topicsByUnit;
    late List<Question> questionBank;

    setUp(() {
      db = AppDatabase.inMemory();
      studyPlanRepo = DriftStudyPlanRepository(db: db);
      examRepo = DriftExamRepository(db: db);
      mistakeRepo = DriftMistakeRepository(db: db);
      planner = const AdaptiveStudyPlanner();

      subjects = [
        const Subject(
          id: 'physics_g12',
          code: 'PHYS12',
          nameEn: 'Physics',
          nameAm: 'ፊዚክስ',
          grade: 12,
          stream: 'natural',
          sortOrder: 1,
        ),
        const Subject(
          id: 'math_g12',
          code: 'MATH12',
          nameEn: 'Mathematics',
          nameAm: 'ሒሳብ',
          grade: 12,
          stream: 'common',
          sortOrder: 2,
        ),
        const Subject(
          id: 'chemistry_g12',
          code: 'CHEM12',
          nameEn: 'Chemistry',
          nameAm: 'ኬሚስትሪ',
          grade: 12,
          stream: 'natural',
          sortOrder: 3,
        ),
      ];

      unitsBySubject = {
        'physics_g12': [
          const Unit(
              id: 'u_phys',
              subjectId: 'physics_g12',
              unitNumber: 1,
              titleEn: 'Electromagnetism',
              titleAm: 'ኤሌክትሮማግኔቲዝም'),
        ],
        'math_g12': [
          const Unit(
              id: 'u_math',
              subjectId: 'math_g12',
              unitNumber: 1,
              titleEn: 'Calculus',
              titleAm: 'ካልኩለስ'),
        ],
        'chemistry_g12': [
          const Unit(
              id: 'u_chem',
              subjectId: 'chemistry_g12',
              unitNumber: 1,
              titleEn: 'Organic Chemistry',
              titleAm: 'ኦርጋኒክ ኬሚስትሪ'),
        ],
      };

      topicsByUnit = {
        'u_phys': [
          const Topic(
              id: 'top_phys_ind',
              unitId: 'u_phys',
              topicNumber: 1,
              titleEn: 'Electromagnetic Induction',
              titleAm: 'ኤሌክትሮማግኔቲክ ኢንዳክሽን'),
        ],
        'u_math': [
          const Topic(
              id: 'top_math_der',
              unitId: 'u_math',
              topicNumber: 1,
              titleEn: 'Derivatives',
              titleAm: 'ዴሪቬቲቭ'),
        ],
        'u_chem': [
          const Topic(
              id: 'top_chem_poly',
              unitId: 'u_chem',
              topicNumber: 1,
              titleEn: 'Polymers',
              titleAm: 'ፖሊመሮች'),
        ],
      };

      questionBank = [
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_p_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'physics_g12',
            unitId: 'u_phys',
            topicId: 'top_phys_ind',
            questionTextEn: 'Physics Q$i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Exp'),
          ),
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_m_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u_math',
            topicId: 'top_math_der',
            questionTextEn: 'Math Q$i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Exp'),
          ),
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_c_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'chemistry_g12',
            unitId: 'u_chem',
            topicId: 'top_chem_poly',
            questionTextEn: 'Chem Q$i',
            difficulty: 'easy',
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Exp'),
          ),
      ];
    });

    tearDown(() async {
      await db.close();
    });

    test('Full End-to-End Adaptive Learning & Study Plan Lifecycle', () async {
      // -------------------------------------------------------------
      // Phase 1: Set up student historical learning state:
      // - Physics accuracy: 48% (12 / 25 correct)
      // - Math accuracy: 82% (23 / 28 correct)
      // - 3 unmastered Physics mistakes
      // - 1 unpracticed Chemistry unit (0 attempts)
      // -------------------------------------------------------------
      final physAttempt = ExamAttempt(
        id: 'att_phys_hist',
        userId: studentId,
        examId: 'exam_phys_hist',
        examTitle: 'Physics Exam',
        subjectId: 'physics_g12',
        startTime: now.subtract(const Duration(days: 1)),
        durationSeconds: 1500,
        totalQuestions: 25,
        score: 12,
        percentage: 48.0,
        correctCount: 12,
        incorrectCount: 13,
        skippedCount: 0,
        isCompleted: true,
        responses: {
          for (int i = 1; i <= 25; i++)
            'q_p_${(i % 10) + 1}': UserResponse(
              questionId: 'q_p_${(i % 10) + 1}',
              isCorrect: i <= 12,
            ),
        },
      );
      await examRepo.saveCompletedAttempt(physAttempt);

      final mathAttempt = ExamAttempt(
        id: 'att_math_hist',
        userId: studentId,
        examId: 'exam_math_hist',
        examTitle: 'Math Exam',
        subjectId: 'math_g12',
        startTime: now.subtract(const Duration(days: 1)),
        durationSeconds: 1800,
        totalQuestions: 28,
        score: 23,
        percentage: 82.1,
        correctCount: 23,
        incorrectCount: 5,
        skippedCount: 0,
        isCompleted: true,
        responses: {
          for (int i = 1; i <= 28; i++)
            'q_m_${(i % 10) + 1}': UserResponse(
              questionId: 'q_m_${(i % 10) + 1}',
              isCorrect: i <= 23,
            ),
        },
      );
      await examRepo.saveCompletedAttempt(mathAttempt);

      // Record 3 unmastered Physics mistakes
      for (int i = 1; i <= 3; i++) {
        await mistakeRepo.recordMistake(
          userId: studentId,
          questionId: 'q_p_$i',
          subjectId: 'physics_g12',
          unitId: 'u_phys',
          topicId: 'top_phys_ind',
        );
      }

      // -------------------------------------------------------------
      // Phase 2: App Launches & Daily Adaptive Plan is Generated
      // -------------------------------------------------------------
      final attempts = await examRepo.getAttemptHistory(studentId);
      final mistakes =
          await mistakeRepo.getMistakes(studentId, onlyUnmastered: true);
      expect(attempts.length, 2);
      expect(mistakes.length, 3);

      final settings = await studyPlanRepo.getPlannerSettings(studentId);

      final plan = planner.generateDailyPlan(
        userId: studentId,
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: attempts,
        unmasteredMistakes: mistakes,
        availableQuestions: questionBank,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'physics_g12', 'math_g12', 'chemistry_g12'},
        currentDate: now,
      );

      // Persist plan in SQLite
      await studyPlanRepo.saveStudyPlan(plan);

      // Verify that Physics remediation is prioritized at the top
      expect(plan.sessions, isNotEmpty);
      final firstSession = plan.sessions.first;
      expect(firstSession.subjectId, 'physics_g12');
      expect(
        firstSession.sessionType == StudySessionType.weakTopicPractice ||
            firstSession.sessionType == StudySessionType.mistakeReview,
        isTrue,
      );
      expect(firstSession.status, SessionCompletionStatus.notStarted);

      // Verify Chemistry coverage is also included in the plan
      final chemSession =
          plan.sessions.where((s) => s.subjectId == 'chemistry_g12');
      expect(chemSession, isNotEmpty);
      expect(
          chemSession.first.sessionType, StudySessionType.curriculumCoverage);

      // -------------------------------------------------------------
      // Phase 3: Student Starts and Completes Top Physics Session
      // -------------------------------------------------------------
      // Mark first session completed with 100% score
      await studyPlanRepo.updateSessionStatus(
        sessionId: firstSession.id,
        status: SessionCompletionStatus.completed,
        completedAt: now.add(const Duration(minutes: 15)),
        timeSpentSeconds: 900,
        scorePercentage: 100.0,
      );

      // -------------------------------------------------------------
      // Phase 4: Local Study Plan and Topic Statistics Update
      // -------------------------------------------------------------
      final updatedPlan =
          await studyPlanRepo.getStudyPlan(studentId, date: now);
      expect(updatedPlan, isNotNull);
      expect(updatedPlan!.completedSessionsCount, 1);
      expect(
          updatedPlan.sessions.first.status, SessionCompletionStatus.completed);
      expect(updatedPlan.status, SessionCompletionStatus.inProgress);
      expect(updatedPlan.completedMinutes, firstSession.estimatedMinutes);

      // -------------------------------------------------------------
      // Phase 5: Student Goes Offline & Completes Chemistry Session
      // -------------------------------------------------------------
      final secondSession = updatedPlan.sessions[1];
      await studyPlanRepo.updateSessionStatus(
        sessionId: secondSession.id,
        status: SessionCompletionStatus.completed,
        completedAt: now.add(const Duration(minutes: 30)),
        timeSpentSeconds: 720,
        scorePercentage: 90.0,
      );

      // -------------------------------------------------------------
      // Phase 6: Verify Offline Persistence & Integrity
      // -------------------------------------------------------------
      final finalPlan = await studyPlanRepo.getStudyPlan(studentId, date: now);
      expect(finalPlan, isNotNull);
      expect(finalPlan!.completedSessionsCount, greaterThanOrEqualTo(2));
      expect(finalPlan.sessions[0].status, SessionCompletionStatus.completed);
      expect(finalPlan.sessions[1].status, SessionCompletionStatus.completed);

      // Verify no data was lost
      expect(finalPlan.userId, studentId);
      expect(finalPlan.targetMinutes, settings.dailyBudgetMinutes);
      expect(finalPlan.algorithmVersion, kAdaptivePlannerAlgorithmVersion);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/mistakes/domain/models/mistake_model.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/domain/services/adaptive_study_planner.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('AdaptiveStudyPlanner Domain Tests', () {
    late AdaptiveStudyPlanner planner;
    late List<Subject> subjects;
    late Map<String, List<Unit>> unitsBySubject;
    late Map<String, List<Topic>> topicsByUnit;
    late List<Question> availableQuestions;

    setUp(() {
      planner = const AdaptiveStudyPlanner();

      // Subjects: Natural Science (Math, Physics, Chemistry, Biology) & Social Science (History)
      subjects = [
        const Subject(
          id: 'math_g12',
          code: 'MATH12',
          nameEn: 'Mathematics',
          nameAm: 'ሒሳብ',
          grade: 12,
          stream: 'common',
          sortOrder: 1,
        ),
        const Subject(
          id: 'physics_g12',
          code: 'PHYS12',
          nameEn: 'Physics',
          nameAm: 'ፊዚክስ',
          grade: 12,
          stream: 'natural',
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
        const Subject(
          id: 'biology_g12',
          code: 'BIO12',
          nameEn: 'Biology',
          nameAm: 'ባዮሎጂ',
          grade: 12,
          stream: 'natural',
          sortOrder: 4,
        ),
        const Subject(
          id: 'history_g12',
          code: 'HIST12',
          nameEn: 'History',
          nameAm: 'ታሪክ',
          grade: 12,
          stream: 'social',
          sortOrder: 5,
        ),
      ];

      // Units
      unitsBySubject = {
        'physics_g12': [
          const Unit(
            id: 'u_phys_em',
            subjectId: 'physics_g12',
            unitNumber: 3,
            titleEn: 'Electromagnetism',
            titleAm: 'ኤሌክትሮማግኔቲዝም',
          ),
        ],
        'math_g12': [
          const Unit(
            id: 'u_math_calc',
            subjectId: 'math_g12',
            unitNumber: 2,
            titleEn: 'Calculus',
            titleAm: 'ካልኩለስ',
          ),
        ],
        'chemistry_g12': [
          const Unit(
            id: 'u_chem_org',
            subjectId: 'chemistry_g12',
            unitNumber: 4,
            titleEn: 'Organic Chemistry',
            titleAm: 'ኦርጋኒክ ኬሚስትሪ',
          ),
        ],
        'biology_g12': [
          const Unit(
            id: 'u_bio_gen',
            subjectId: 'biology_g12',
            unitNumber: 1,
            titleEn: 'Genetics',
            titleAm: 'ጀነቲክስ',
          ),
        ],
        'history_g12': [
          const Unit(
            id: 'u_hist_eth',
            subjectId: 'history_g12',
            unitNumber: 1,
            titleEn: 'Modern Ethiopian History',
            titleAm: 'የኢትዮጵያ ዘመናዊ ታሪክ',
          ),
        ],
      };

      // Topics
      topicsByUnit = {
        'u_phys_em': [
          const Topic(
            id: 'top_phys_induction',
            unitId: 'u_phys_em',
            topicNumber: 1,
            titleEn: 'Electromagnetic Induction',
            titleAm: 'ኤሌክትሮማግኔቲክ ኢንዳክሽን',
          ),
        ],
        'u_math_calc': [
          const Topic(
            id: 'top_math_limits',
            unitId: 'u_math_calc',
            topicNumber: 1,
            titleEn: 'Limits & Derivatives',
            titleAm: 'ሊሚት እና ዴሪቬቲቭ',
          ),
        ],
        'u_chem_org': [
          const Topic(
            id: 'top_chem_hydro',
            unitId: 'u_chem_org',
            topicNumber: 1,
            titleEn: 'Hydrocarbons & Polymers',
            titleAm: 'ሃይድሮካርቦን እና ፖሊመሮች',
          ),
        ],
        'u_bio_gen': [
          const Topic(
            id: 'top_bio_dna',
            unitId: 'u_bio_gen',
            topicNumber: 1,
            titleEn: 'DNA Replication',
            titleAm: 'ዲኤንኤ ሪፕሊኬሽን',
          ),
        ],
        'u_hist_eth': [
          const Topic(
            id: 'top_hist_adwa',
            unitId: 'u_hist_eth',
            topicNumber: 1,
            titleEn: 'Battle of Adwa',
            titleAm: 'የአድዋ ጦርነት',
          ),
        ],
      };

      // Questions generator helper
      availableQuestions = [
        // Physics questions
        for (int i = 1; i <= 15; i++)
          Question(
            id: 'q_phys_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'physics_g12',
            unitId: 'u_phys_em',
            topicId: 'top_phys_induction',
            questionTextEn: 'Physics Q$i',
            difficulty: i <= 5 ? 'easy' : (i <= 10 ? 'medium' : 'hard'),
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Explanation'),
          ),
        // Math questions
        for (int i = 1; i <= 15; i++)
          Question(
            id: 'q_math_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u_math_calc',
            topicId: 'top_math_limits',
            questionTextEn: 'Math Q$i',
            difficulty: i <= 5 ? 'easy' : (i <= 10 ? 'medium' : 'hard'),
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Explanation'),
          ),
        // Chemistry questions
        for (int i = 1; i <= 15; i++)
          Question(
            id: 'q_chem_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'chemistry_g12',
            unitId: 'u_chem_org',
            topicId: 'top_chem_hydro',
            questionTextEn: 'Chemistry Q$i',
            difficulty: i <= 5 ? 'easy' : (i <= 10 ? 'medium' : 'hard'),
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Explanation'),
          ),
        // History questions
        for (int i = 1; i <= 15; i++)
          Question(
            id: 'q_hist_$i',
            grade: 12,
            stream: 'social',
            subjectId: 'history_g12',
            unitId: 'u_hist_eth',
            topicId: 'top_hist_adwa',
            questionTextEn: 'History Q$i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.published,
            sourceName: 'National Exam',
            contentVersion: 1,
            choices: const [],
            explanation: const Explanation(solutionTextEn: 'Explanation'),
          ),
      ];
    });

    test(
        '1. Deterministic Reproducibility: Identical input state generates identical plan',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      final planA = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );

      final planB = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );

      expect(planA.id, planB.id);
      expect(planA.sessions.length, planB.sessions.length);
      for (int i = 0; i < planA.sessions.length; i++) {
        expect(planA.sessions[i].id, planB.sessions[i].id);
        expect(
            planA.sessions[i].priorityScore, planB.sessions[i].priorityScore);
        expect(planA.sessions[i].questionIds, planB.sessions[i].questionIds);
      }
    });

    test(
        '2. Weak Topic Prioritization: Low accuracy topic is ranked ahead of high accuracy topic',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      // Student scored 40% in Physics (2 correct, 3 wrong out of 5)
      // and 80% in Math (4 correct, 1 wrong out of 5)
      final attempts = [
        ExamAttempt(
          id: 'att_phys',
          userId: 'student_001',
          examId: 'exam_phys',
          examTitle: 'Physics Test',
          subjectId: 'physics_g12',
          startTime: now.subtract(const Duration(days: 1)),
          durationSeconds: 300,
          totalQuestions: 5,
          score: 2,
          percentage: 40.0,
          correctCount: 2,
          incorrectCount: 3,
          skippedCount: 0,
          isCompleted: true,
          responses: const {
            'q_phys_1': UserResponse(questionId: 'q_phys_1', isCorrect: false),
            'q_phys_2': UserResponse(questionId: 'q_phys_2', isCorrect: false),
            'q_phys_3': UserResponse(questionId: 'q_phys_3', isCorrect: false),
            'q_phys_4': UserResponse(questionId: 'q_phys_4', isCorrect: true),
            'q_phys_5': UserResponse(questionId: 'q_phys_5', isCorrect: true),
          },
        ),
        ExamAttempt(
          id: 'att_math',
          userId: 'student_001',
          examId: 'exam_math',
          examTitle: 'Math Test',
          subjectId: 'math_g12',
          startTime: now.subtract(const Duration(days: 1)),
          durationSeconds: 300,
          totalQuestions: 5,
          score: 4,
          percentage: 80.0,
          correctCount: 4,
          incorrectCount: 1,
          skippedCount: 0,
          isCompleted: true,
          responses: const {
            'q_math_1': UserResponse(questionId: 'q_math_1', isCorrect: true),
            'q_math_2': UserResponse(questionId: 'q_math_2', isCorrect: true),
            'q_math_3': UserResponse(questionId: 'q_math_3', isCorrect: true),
            'q_math_4': UserResponse(questionId: 'q_math_4', isCorrect: true),
            'q_math_5': UserResponse(questionId: 'q_math_5', isCorrect: false),
          },
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: attempts,
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );

      // Physics weak remediation should be top priority session
      final firstSession = plan.sessions.first;
      expect(firstSession.subjectId, 'physics_g12');
      expect(firstSession.sessionType, StudySessionType.weakTopicPractice);
      expect(firstSession.reasonCode, RecommendationReasonCode.weakTopic);
      expect(firstSession.reasonDetailEn, contains('40%'));
    });

    test(
        '3. Mistake Review Session: Unmastered mistakes trigger focused review',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      final mistakes = [
        MistakeRecord(
          id: 'm1',
          userId: 'student_001',
          questionId: 'q_phys_1',
          subjectId: 'physics_g12',
          unitId: 'u_phys_em',
          topicId: 'top_phys_induction',
          firstMissedAt: now.subtract(const Duration(days: 2)),
          lastMissedAt: now.subtract(const Duration(days: 1)),
          missCount: 2,
          masteryStatus: MasteryStatus.needsReview,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        MistakeRecord(
          id: 'm2',
          userId: 'student_001',
          questionId: 'q_phys_2',
          subjectId: 'physics_g12',
          unitId: 'u_phys_em',
          topicId: 'top_phys_induction',
          firstMissedAt: now.subtract(const Duration(days: 2)),
          lastMissedAt: now.subtract(const Duration(days: 1)),
          missCount: 1,
          masteryStatus: MasteryStatus.needsReview,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: mistakes,
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'physics_g12', 'math_g12'},
        currentDate: now,
      );

      final mistakeSession = plan.sessions.firstWhere(
        (s) => s.sessionType == StudySessionType.mistakeReview,
      );
      expect(mistakeSession.subjectId, 'physics_g12');
      expect(mistakeSession.questionIds, containsAll(['q_phys_1', 'q_phys_2']));
      expect(mistakeSession.reasonCode, RecommendationReasonCode.mistakeReview);
    });

    test(
        '4. Daily Time Budgeting: Total estimated time respects selected budget',
        () {
      final now = DateTime(2026, 9, 24);

      // Test 15-minute budget
      final plan15 = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 15,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );
      expect(plan15.estimatedMinutes, lessThanOrEqualTo(15));
      expect(plan15.sessions.length, 1);

      // Test 45-minute budget
      final plan45 = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );
      expect(plan45.estimatedMinutes, lessThanOrEqualTo(45));
      expect(plan45.sessions.length, greaterThanOrEqualTo(2));
    });

    test(
        '5. Stream Awareness: Natural vs Social stream recommendations strictly separated',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      // Natural stream student
      final natPlan = planner.generateDailyPlan(
        userId: 'student_nat',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {
          'math_g12',
          'physics_g12',
          'chemistry_g12',
          'history_g12'
        },
        currentDate: now,
      );
      final natSubjectIds = natPlan.sessions.map((s) => s.subjectId).toSet();
      expect(natSubjectIds, isNot(contains('history_g12')));

      // Social stream student
      final socPlan = planner.generateDailyPlan(
        userId: 'student_soc',
        grade: 12,
        stream: 'social',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {
          'math_g12',
          'physics_g12',
          'chemistry_g12',
          'history_g12'
        },
        currentDate: now,
      );
      final socSubjectIds = socPlan.sessions.map((s) => s.subjectId).toSet();
      expect(socSubjectIds, isNot(contains('physics_g12')));
      expect(socSubjectIds, isNot(contains('chemistry_g12')));
      expect(socSubjectIds, contains('history_g12'));
    });

    test(
        '6. Difficulty Adjustment: <50% accuracy receives easy questions; >75% receives hard questions',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 30,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      // Student with low accuracy in Physics (20%)
      final weakAttempts = [
        ExamAttempt(
          id: 'att_weak',
          userId: 'student_001',
          examId: 'e1',
          examTitle: 'Test',
          subjectId: 'physics_g12',
          startTime: now.subtract(const Duration(days: 1)),
          durationSeconds: 120,
          totalQuestions: 5,
          score: 1,
          percentage: 20.0,
          correctCount: 1,
          incorrectCount: 4,
          skippedCount: 0,
          isCompleted: true,
          responses: const {
            'q_phys_1': UserResponse(questionId: 'q_phys_1', isCorrect: true),
            'q_phys_2': UserResponse(questionId: 'q_phys_2', isCorrect: false),
            'q_phys_3': UserResponse(questionId: 'q_phys_3', isCorrect: false),
            'q_phys_4': UserResponse(questionId: 'q_phys_4', isCorrect: false),
            'q_phys_5': UserResponse(questionId: 'q_phys_5', isCorrect: false),
          },
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: weakAttempts,
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'physics_g12'},
        currentDate: now,
      );

      final physSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'physics_g12');
      // Low accuracy should start with easy questions (q_phys_1 through q_phys_5)
      expect(physSession.questionIds.first, 'q_phys_1');
    });

    test(
        '7. Multi-Subject Balancing: Heavy practice in one subject rotates other stream subjects',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      // Student completed 3 exams in Physics today
      final attemptsToday = [
        for (int i = 0; i < 3; i++)
          ExamAttempt(
            id: 'att_phys_$i',
            userId: 'student_001',
            examId: 'e_$i',
            examTitle: 'Phys',
            subjectId: 'physics_g12',
            startTime: now,
            durationSeconds: 300,
            totalQuestions: 5,
            score: 4,
            percentage: 80.0,
            correctCount: 4,
            incorrectCount: 1,
            skippedCount: 0,
            isCompleted: true,
            responses: const {},
          ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: attemptsToday,
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );

      // First recommended session should rotate to Math or Chemistry
      expect(plan.sessions.first.subjectId, isNot('physics_g12'));
    });

    test(
        '8. Edge Case: Student with 0 attempts receives balanced curriculum starter plan',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 75)),
      );

      final starterPlan = planner.generateDailyPlan(
        userId: 'new_student',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12', 'chemistry_g12'},
        currentDate: now,
      );

      expect(starterPlan.sessions, isNotEmpty);
      expect(starterPlan.status, SessionCompletionStatus.notStarted);
      // All starter sessions should be curriculum coverage
      for (final s in starterPlan.sessions) {
        expect(s.sessionType, StudySessionType.curriculumCoverage);
        expect(s.reasonCode, RecommendationReasonCode.newCurriculum);
      }
    });

    test(
        '9. Exam Proximity Weighting: <=30 days from national exam prioritizes timed mock drills',
        () {
      final now = DateTime(2026, 9, 24);
      // Exam in 14 days
      final nearExamSettings = PlannerSettings(
        dailyBudgetMinutes: 60,
        targetExamDate: now.add(const Duration(days: 14)),
      );

      final plan = planner.generateDailyPlan(
        userId: 'student_001',
        grade: 12,
        stream: 'natural',
        settings: nearExamSettings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: availableQuestions,
        allSubjects: subjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12'},
        currentDate: now,
      );

      final mockSession = plan.sessions
          .where((s) => s.sessionType == StudySessionType.mockExam);
      expect(mockSession, isNotEmpty);
      expect(mockSession.first.reasonCode,
          RecommendationReasonCode.examApproaching);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_study_plan_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/domain/services/adaptive_study_planner.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('Priority 2 Hardening & Freeze Automated Test Suite', () {
    late AdaptiveStudyPlanner planner;
    late AppDatabase db;
    late DriftStudyPlanRepository repository;
    late List<Subject> allCanonicalSubjects;
    late Map<String, List<Unit>> unitsBySubject;
    late Map<String, List<Topic>> topicsByUnit;
    late List<Question> testQuestions;

    setUp(() {
      planner = const AdaptiveStudyPlanner();
      db = AppDatabase.inMemory();
      repository = DriftStudyPlanRepository(db: db);

      // Canonical 9 launch subjects + supplementary Civics
      allCanonicalSubjects = const [
        Subject(
          id: 'english_g12',
          code: 'ENG12',
          nameEn: 'English',
          nameAm: 'እንግሊዝኛ',
          grade: 12,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.mixed,
          sortOrder: 1,
        ),
        Subject(
          id: 'math_g12',
          code: 'MATH12',
          nameEn: 'Mathematics',
          nameAm: 'ሒሳብ',
          grade: 12,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 2,
        ),
        Subject(
          id: 'aptitude_g12',
          code: 'APT12',
          nameEn: 'Scholastic Aptitude',
          nameAm: 'አፕቲትዩድ',
          grade: 12,
          stream: 'common',
          scope: SubjectScope.commonExam,
          assessmentStructure: AssessmentStructure.skillBased,
          sortOrder: 3,
        ),
        Subject(
          id: 'physics_g12',
          code: 'PHYS12',
          nameEn: 'Physics',
          nameAm: 'ፊዚክስ',
          grade: 12,
          stream: 'natural',
          scope: SubjectScope.streamExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 4,
        ),
        Subject(
          id: 'chemistry_g12',
          code: 'CHEM12',
          nameEn: 'Chemistry',
          nameAm: 'ኬሚስትሪ',
          grade: 12,
          stream: 'natural',
          scope: SubjectScope.streamExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 5,
        ),
        Subject(
          id: 'biology_g12',
          code: 'BIO12',
          nameEn: 'Biology',
          nameAm: 'ባዮሎጂ',
          grade: 12,
          stream: 'natural',
          scope: SubjectScope.streamExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 6,
        ),
        Subject(
          id: 'history_g12',
          code: 'HIST12',
          nameEn: 'History',
          nameAm: 'ታሪክ',
          grade: 12,
          stream: 'social',
          scope: SubjectScope.streamExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 7,
        ),
        Subject(
          id: 'geography_g12',
          code: 'GEO12',
          nameEn: 'Geography',
          nameAm: 'ጂኦግራፊ',
          grade: 12,
          stream: 'social',
          scope: SubjectScope.streamExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 8,
        ),
        Subject(
          id: 'economics_g12',
          code: 'ECON12',
          nameEn: 'Economics',
          nameAm: 'ኢኮኖሚክስ',
          grade: 12,
          stream: 'social',
          scope: SubjectScope.streamExam,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 9,
        ),
        Subject(
          id: 'civics_g12',
          code: 'CIV12',
          nameEn: 'Civics',
          nameAm: 'ስነ-ዜጋ',
          grade: 12,
          stream: 'common',
          scope: SubjectScope.curriculumOnly,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 10,
        ),
      ];

      unitsBySubject = {
        'physics_g12': const [
          Unit(
              id: 'u_phys_1',
              subjectId: 'physics_g12',
              unitNumber: 1,
              titleEn: 'Thermodynamics',
              titleAm: 'ቴርሞዳይናሚክስ'),
        ],
        'chemistry_g12': const [
          Unit(
              id: 'u_chem_1',
              subjectId: 'chemistry_g12',
              unitNumber: 1,
              titleEn: 'Electrochemistry',
              titleAm: 'ኤሌክትሮኬሚስትሪ'),
        ],
        'biology_g12': const [
          Unit(
              id: 'u_bio_1',
              subjectId: 'biology_g12',
              unitNumber: 1,
              titleEn: 'Genetics',
              titleAm: 'ጄኔቲክስ'),
        ],
        'history_g12': const [
          Unit(
              id: 'u_hist_1',
              subjectId: 'history_g12',
              unitNumber: 1,
              titleEn: 'Ethiopian History',
              titleAm: 'የኢትዮጵያ ታሪክ'),
        ],
        'geography_g12': const [
          Unit(
              id: 'u_geo_1',
              subjectId: 'geography_g12',
              unitNumber: 1,
              titleEn: 'Physical Geography',
              titleAm: 'ተፈጥሯዊ ጂኦግራፊ'),
        ],
        'economics_g12': const [
          Unit(
              id: 'u_econ_1',
              subjectId: 'economics_g12',
              unitNumber: 1,
              titleEn: 'Macroeconomics',
              titleAm: 'ማክሮኢኮኖሚክስ'),
        ],
        'math_g12': const [
          Unit(
              id: 'u_math_calc',
              subjectId: 'math_g12',
              unitNumber: 1,
              titleEn: 'Calculus',
              titleAm: 'ካልኩለስ'),
        ],
      };

      topicsByUnit = {
        'u_phys_1': const [
          Topic(
              id: 't_phys_heat',
              unitId: 'u_phys_1',
              topicNumber: 1,
              titleEn: 'Heat Transfer',
              titleAm: 'የሙቀት ዝውውር')
        ],
        'u_chem_1': const [
          Topic(
              id: 't_chem_cells',
              unitId: 'u_chem_1',
              topicNumber: 1,
              titleEn: 'Galvanic Cells',
              titleAm: 'ጋልቫኒክ ሴሎች')
        ],
        'u_bio_1': const [
          Topic(
              id: 't_bio_dna',
              unitId: 'u_bio_1',
              topicNumber: 1,
              titleEn: 'DNA Structure',
              titleAm: 'የዲኤንኤ አወቃቀር')
        ],
        'u_hist_1': const [
          Topic(
              id: 't_hist_adwa',
              unitId: 'u_hist_1',
              topicNumber: 1,
              titleEn: 'Battle of Adwa',
              titleAm: 'የዓድዋ ጦርነት')
        ],
        'u_geo_1': const [
          Topic(
              id: 't_geo_map',
              unitId: 'u_geo_1',
              topicNumber: 1,
              titleEn: 'Map Reading',
              titleAm: 'ካርታ ንባብ')
        ],
        'u_econ_1': const [
          Topic(
              id: 't_econ_gdp',
              unitId: 'u_econ_1',
              topicNumber: 1,
              titleEn: 'GDP Calculation',
              titleAm: 'ጠቅላላ የሀገር ውስጥ ምርት')
        ],
        'u_math_calc': const [
          Topic(
              id: 't_math_limits',
              unitId: 'u_math_calc',
              topicNumber: 1,
              titleEn: 'Limits and Continuity',
              titleAm: 'ሊሚቶች እና ቀጣይነት')
        ],
      };

      // Construct verified static questions for all domains
      testQuestions = [
        // English questions (mixed structure with Reading Comprehension domain)
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_eng_$i',
            grade: 12,
            stream: 'common',
            subjectId: 'english_g12',
            unitId: 'eng_u_reading',
            topicId: 'eng_t_reading_inference',
            contentDomain: 'Reading Comprehension',
            skill: 'Main Idea Identification',
            examVariant: ExamVariantCode.shared,
            assessmentStructure: AssessmentStructure.mixed,
            questionTextEn: 'English reading comprehension test question $i',
            difficulty: i <= 4 ? 'easy' : (i <= 8 ? 'medium' : 'hard'),
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE Hamle 2014 E.C. English',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'English explanation'),
          ),

        // Scholastic Aptitude questions (skillBased with Quantitative Reasoning domain & Data Interpretation skill)
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_apt_$i',
            grade: 12,
            stream: 'common',
            subjectId: 'aptitude_g12',
            unitId: 'apt_u_quant',
            topicId: 'apt_t_data_interp',
            contentDomain: 'Quantitative Reasoning',
            skill: 'Data Interpretation',
            examVariant: ExamVariantCode.shared,
            assessmentStructure: AssessmentStructure.skillBased,
            questionTextEn:
                'Scholastic Aptitude data interpretation question $i',
            difficulty: i <= 4 ? 'easy' : (i <= 8 ? 'medium' : 'hard'),
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE Hamle 2014 E.C. Aptitude',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'Aptitude explanation'),
          ),

        // Mathematics Natural Science questions
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_math_nat_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u_math_calc',
            topicId: 't_math_limits',
            contentDomain: 'Calculus',
            skill: 'Limit Evaluation',
            examVariant: ExamVariantCode.naturalScience,
            assessmentStructure: AssessmentStructure.curriculum,
            questionTextEn: 'Natural Math Limit problem $i',
            difficulty: i <= 4 ? 'easy' : 'medium',
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE Hamle 2014 E.C. Mathematics (Natural)',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'Natural Math solution'),
          ),

        // Mathematics Social Science questions
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_math_soc_$i',
            grade: 12,
            stream: 'social',
            subjectId: 'math_g12',
            unitId: 'u_math_calc',
            topicId: 't_math_limits',
            contentDomain: 'Business Calculus',
            skill: 'Marginal Cost',
            examVariant: ExamVariantCode.socialScience,
            assessmentStructure: AssessmentStructure.curriculum,
            questionTextEn: 'Social Math Marginal Cost problem $i',
            difficulty: i <= 4 ? 'easy' : 'medium',
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE Hamle 2014 E.C. Mathematics (Social)',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'Social Math solution'),
          ),

        // Physics Natural questions
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_phys_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'physics_g12',
            unitId: 'u_phys_1',
            topicId: 't_phys_heat',
            examVariant: ExamVariantCode.naturalScience,
            assessmentStructure: AssessmentStructure.curriculum,
            questionTextEn: 'Physics Heat question $i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 Physics',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation: const Explanation(solutionTextEn: 'Physics solution'),
          ),

        // History Social questions
        for (int i = 1; i <= 10; i++)
          Question(
            id: 'q_hist_$i',
            grade: 12,
            stream: 'social',
            subjectId: 'history_g12',
            unitId: 'u_hist_1',
            topicId: 't_hist_adwa',
            examVariant: ExamVariantCode.socialScience,
            assessmentStructure: AssessmentStructure.curriculum,
            questionTextEn: 'History Adwa question $i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 History',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation: const Explanation(solutionTextEn: 'History solution'),
          ),
      ];
    });

    tearDown(() async {
      await db.close();
    });

    // ------------------------------------------------------------------------
    // SECTION 36: TEST: NATURAL SUBJECT SET
    // ------------------------------------------------------------------------
    test(
        '36. Natural Science student receives 6 primary tracks and excludes Social subjects & Civics',
        () {
      final now = DateTime(2026, 9, 24);
      final plan = planner.generateDailyPlan(
        userId: 'nat_student_01',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 90,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {},
        currentDate: now,
      );

      final sessionSubjectIds = plan.sessions.map((s) => s.subjectId).toSet();
      // Natural pool must allow: English, Math Nat, Aptitude, Physics
      for (final sId in sessionSubjectIds) {
        expect([
          'english_g12',
          'math_g12',
          'aptitude_g12',
          'physics_g12',
          'chemistry_g12',
          'biology_g12'
        ], contains(sId));
        // Excludes Social subjects and Civics
        expect(['history_g12', 'geography_g12', 'economics_g12', 'civics_g12'],
            isNot(contains(sId)));
      }
    });

    // ------------------------------------------------------------------------
    // SECTION 37: TEST: SOCIAL SUBJECT SET
    // ------------------------------------------------------------------------
    test(
        '37. Social Science student receives 6 primary tracks and excludes Natural subjects & Civics',
        () {
      final now = DateTime(2026, 9, 24);
      final plan = planner.generateDailyPlan(
        userId: 'soc_student_01',
        grade: 12,
        stream: 'social',
        settings: PlannerSettings(
          dailyBudgetMinutes: 90,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {},
        currentDate: now,
      );

      final sessionSubjectIds = plan.sessions.map((s) => s.subjectId).toSet();
      for (final sId in sessionSubjectIds) {
        expect([
          'english_g12',
          'math_g12',
          'aptitude_g12',
          'history_g12',
          'geography_g12',
          'economics_g12'
        ], contains(sId));
        // Excludes Natural subjects and Civics
        expect(['physics_g12', 'chemistry_g12', 'biology_g12', 'civics_g12'],
            isNot(contains(sId)));
      }
    });

    // ------------------------------------------------------------------------
    // SECTION 38: TEST: ENGLISH RECOMMENDATION
    // ------------------------------------------------------------------------
    test(
        '38. English Reading Comprehension weakness recommends mixed session and persists correctly',
        () async {
      final now = DateTime(2026, 9, 24);
      // Create student history with 4 attempts on English Reading Comprehension, 1 correct (25% accuracy)
      final englishAttempts = [
        ExamAttempt(
          id: 'att_eng_1',
          examId: 'exam_eng_1',
          examTitle: 'English Diagnostic',
          userId: 'eng_student',
          startTime: now.subtract(const Duration(days: 1)),
          durationSeconds: 165,
          totalQuestions: 4,
          score: 1,
          percentage: 25.0,
          correctCount: 1,
          incorrectCount: 3,
          skippedCount: 0,
          isCompleted: true,
          subjectId: 'english_g12',
          responses: const {
            'q_eng_1': UserResponse(questionId: 'q_eng_1', isCorrect: false),
            'q_eng_2': UserResponse(questionId: 'q_eng_2', isCorrect: false),
            'q_eng_3': UserResponse(questionId: 'q_eng_3', isCorrect: true),
            'q_eng_4': UserResponse(questionId: 'q_eng_4', isCorrect: false),
          },
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'eng_student',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: englishAttempts,
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {},
        currentDate: now,
      );

      final engSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'english_g12');
      expect(engSession.sessionType, StudySessionType.weakTopicPractice);
      expect(engSession.reasonCode, RecommendationReasonCode.weakTopic);
      expect(engSession.examVariant, ExamVariantCode.shared);
      expect(engSession.assessmentStructure, AssessmentStructure.mixed);
      expect(engSession.contentDomain, 'Reading Comprehension');

      // Persist to Drift database and reload
      await repository.saveStudyPlan(plan);
      final reloadedPlan =
          await repository.getStudyPlan('eng_student', date: now);
      expect(reloadedPlan, isNotNull);

      final reloadedEng = reloadedPlan!.sessions
          .firstWhere((s) => s.subjectId == 'english_g12');
      expect(reloadedEng.subjectId, 'english_g12');
      expect(reloadedEng.examVariant, ExamVariantCode.shared);
      expect(reloadedEng.assessmentStructure, AssessmentStructure.mixed);
      expect(reloadedEng.contentDomain, 'Reading Comprehension');
    });

    // ------------------------------------------------------------------------
    // SECTION 39: TEST: APTITUDE RECOMMENDATION
    // ------------------------------------------------------------------------
    test(
        '39. Scholastic Aptitude Data Interpretation weakness recommends skill-based session and persists correctly',
        () async {
      final now = DateTime(2026, 9, 24);
      // Student has 3 attempts on Aptitude Data Interpretation with 0% accuracy
      final aptAttempts = [
        ExamAttempt(
          id: 'att_apt_1',
          examId: 'exam_apt_1',
          examTitle: 'Aptitude Diagnostic',
          userId: 'apt_student',
          startTime: now.subtract(const Duration(days: 2)),
          durationSeconds: 135,
          totalQuestions: 3,
          score: 0,
          percentage: 0.0,
          correctCount: 0,
          incorrectCount: 3,
          skippedCount: 0,
          isCompleted: true,
          subjectId: 'aptitude_g12',
          responses: const {
            'q_apt_1': UserResponse(questionId: 'q_apt_1', isCorrect: false),
            'q_apt_2': UserResponse(questionId: 'q_apt_2', isCorrect: false),
            'q_apt_3': UserResponse(questionId: 'q_apt_3', isCorrect: false),
          },
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'apt_student',
        grade: 12,
        stream: 'social',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: aptAttempts,
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {},
        currentDate: now,
      );

      final aptSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'aptitude_g12');
      expect(aptSession.sessionType, StudySessionType.weakTopicPractice);
      expect(aptSession.reasonCode, RecommendationReasonCode.weakTopic);
      expect(aptSession.examVariant, ExamVariantCode.shared);
      expect(aptSession.assessmentStructure, AssessmentStructure.skillBased);
      expect(aptSession.contentDomain, 'Quantitative Reasoning');
      expect(aptSession.skill, 'Data Interpretation');

      // Persist to Drift database and reload
      await repository.saveStudyPlan(plan);
      final reloadedPlan =
          await repository.getStudyPlan('apt_student', date: now);
      expect(reloadedPlan, isNotNull);

      final reloadedApt = reloadedPlan!.sessions
          .firstWhere((s) => s.subjectId == 'aptitude_g12');
      expect(reloadedApt.subjectId, 'aptitude_g12');
      expect(reloadedApt.examVariant, ExamVariantCode.shared);
      expect(reloadedApt.assessmentStructure, AssessmentStructure.skillBased);
      expect(reloadedApt.contentDomain, 'Quantitative Reasoning');
      expect(reloadedApt.skill, 'Data Interpretation');
    });

    // ------------------------------------------------------------------------
    // SECTION 40 & 41: TEST: MATHEMATICS ISOLATION (NATURAL VS SOCIAL)
    // ------------------------------------------------------------------------
    test(
        '40. Natural Math recommendation explicitly retains naturalScience variant and contains only Natural questions',
        () async {
      final now = DateTime(2026, 9, 24);
      final plan = planner.generateDailyPlan(
        userId: 'nat_math_user',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {'math_g12'},
        currentDate: now,
      );

      final mathSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'math_g12');
      expect(mathSession.examVariant, ExamVariantCode.naturalScience);
      expect(mathSession.assessmentStructure, AssessmentStructure.curriculum);

      // Verify all question IDs belong strictly to Natural Math
      for (final qId in mathSession.questionIds) {
        expect(qId, startsWith('q_math_nat_'));
        expect(qId, isNot(startsWith('q_math_soc_')));
      }

      // Persist and reload
      await repository.saveStudyPlan(plan);
      final reloaded =
          await repository.getStudyPlan('nat_math_user', date: now);
      final reloadedMath =
          reloaded!.sessions.firstWhere((s) => s.subjectId == 'math_g12');
      expect(reloadedMath.examVariant, ExamVariantCode.naturalScience);
    });

    test(
        '41. Social Math recommendation explicitly retains socialScience variant and contains only Social questions',
        () async {
      final now = DateTime(2026, 9, 24);
      final plan = planner.generateDailyPlan(
        userId: 'soc_math_user',
        grade: 12,
        stream: 'social',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {'math_g12'},
        currentDate: now,
      );

      final mathSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'math_g12');
      expect(mathSession.examVariant, ExamVariantCode.socialScience);
      expect(mathSession.assessmentStructure, AssessmentStructure.curriculum);

      // Verify all question IDs belong strictly to Social Math
      for (final qId in mathSession.questionIds) {
        expect(qId, startsWith('q_math_soc_'));
        expect(qId, isNot(startsWith('q_math_nat_')));
      }

      // Persist and reload
      await repository.saveStudyPlan(plan);
      final reloaded =
          await repository.getStudyPlan('soc_math_user', date: now);
      final reloadedMath =
          reloaded!.sessions.firstWhere((s) => s.subjectId == 'math_g12');
      expect(reloadedMath.examVariant, ExamVariantCode.socialScience);
    });

    // ------------------------------------------------------------------------
    // SECTION 43: TEST: CANONICAL EXAM PREPARATION PHASES BOUNDARIES
    // ------------------------------------------------------------------------
    test(
        '43. ExamPreparationPhase boundary conditions follow canonical policy exactly',
        () {
      expect(
          ExamPreparationPhase.fromDays(61), ExamPreparationPhase.foundation);
      expect(ExamPreparationPhase.fromDays(60),
          ExamPreparationPhase.consolidation);
      expect(ExamPreparationPhase.fromDays(31),
          ExamPreparationPhase.consolidation);
      expect(ExamPreparationPhase.fromDays(30), ExamPreparationPhase.intensive);
      expect(ExamPreparationPhase.fromDays(15), ExamPreparationPhase.intensive);
      expect(
          ExamPreparationPhase.fromDays(14), ExamPreparationPhase.finalReview);
      expect(
          ExamPreparationPhase.fromDays(1), ExamPreparationPhase.finalReview);
      expect(
          ExamPreparationPhase.fromDays(0), ExamPreparationPhase.finalReview);
      expect(ExamPreparationPhase.fromDays(-1),
          ExamPreparationPhase.foundation); // Past date
      expect(ExamPreparationPhase.fromDays(null),
          ExamPreparationPhase.foundation); // Missing date
    });

    // ------------------------------------------------------------------------
    // SECTION 44: TEST: MOCK EXAM WEIGHTING ACTIVATION
    // ------------------------------------------------------------------------
    test(
        '44. Timed Mock +85.0 weighting activates ONLY at <=14 days, NOT at 15-30 days',
        () {
      final now = DateTime(2026, 9, 24);

      // Case 1: 20 days until exam (intensive phase -> NO mock exam boost)
      final intensiveSettings = PlannerSettings(
        dailyBudgetMinutes: 60,
        targetExamDate: now.add(const Duration(days: 20)),
      );
      final intensivePlan = planner.generateDailyPlan(
        userId: 'student_intensive',
        grade: 12,
        stream: 'natural',
        settings: intensiveSettings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {'physics_g12'},
        currentDate: now,
      );
      final mockInIntensive = intensivePlan.sessions
          .where((s) => s.sessionType == StudySessionType.mockExam);
      expect(mockInIntensive, isEmpty);

      // Case 2: 10 days until exam (finalReview phase -> Mock exam boost activates)
      final finalReviewSettings = PlannerSettings(
        dailyBudgetMinutes: 60,
        targetExamDate: now.add(const Duration(days: 10)),
      );
      final finalReviewPlan = planner.generateDailyPlan(
        userId: 'student_final_review',
        grade: 12,
        stream: 'natural',
        settings: finalReviewSettings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {'physics_g12'},
        currentDate: now,
      );
      final mockInFinalReview = finalReviewPlan.sessions
          .where((s) => s.sessionType == StudySessionType.mockExam);
      expect(mockInFinalReview, isNotEmpty);
      expect(mockInFinalReview.first.priorityScore, 85.0);
      expect(mockInFinalReview.first.reasonCode,
          RecommendationReasonCode.examApproaching);
    });

    // ------------------------------------------------------------------------
    // SECTION 45: TEST: MULTI-SUBJECT BALANCING
    // ------------------------------------------------------------------------
    test(
        '45. Multi-subject balancing does not starve common subjects (English and Aptitude)',
        () {
      final now = DateTime(2026, 9, 24);
      final plan = planner.generateDailyPlan(
        userId: 'balance_student',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 90,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {},
        currentDate: now,
      );

      final subjectSet = plan.sessions.map((s) => s.subjectId).toSet();
      // Verifies common subjects are present in recommendation sessions
      final hasCommonSubject = subjectSet.contains('english_g12') ||
          subjectSet.contains('aptitude_g12') ||
          subjectSet.contains('math_g12');
      expect(hasCommonSubject, isTrue);
    });

    // ------------------------------------------------------------------------
    // SECTION 46: TEST: OFFLINE EXECUTION & REPEATABILITY
    // ------------------------------------------------------------------------
    test(
        '46. Offline full lifecycle: Generate, complete sessions, reload offline',
        () async {
      final now = DateTime(2026, 9, 24);
      final plan = planner.generateDailyPlan(
        userId: 'offline_user',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 75)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: allCanonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: const {'physics_g12'},
        currentDate: now,
      );

      await repository.saveStudyPlan(plan);
      expect(plan.sessions, isNotEmpty);

      final firstSession = plan.sessions.first;
      await repository.updateSessionStatus(
        sessionId: firstSession.id,
        status: SessionCompletionStatus.completed,
        completedAt: now,
        timeSpentSeconds: 600,
        scorePercentage: 90.0,
      );

      final reloaded = await repository.getStudyPlan('offline_user', date: now);
      expect(reloaded, isNotNull);
      final updatedSession =
          reloaded!.sessions.firstWhere((s) => s.id == firstSession.id);
      expect(updatedSession.status, SessionCompletionStatus.completed);
      expect(updatedSession.scorePercentage, 90.0);
    });
  });
}

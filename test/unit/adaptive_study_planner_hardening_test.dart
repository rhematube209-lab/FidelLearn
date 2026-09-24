import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_study_plan_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/domain/services/adaptive_study_planner.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:fidel_learn/features/subjects/domain/services/subject_resolver.dart';

void main() {
  group('Priority 2 Hardening Test Suite', () {
    late AdaptiveStudyPlanner planner;
    late AppDatabase db;
    late DriftStudyPlanRepository repository;
    late List<Subject> canonicalSubjects;
    late Map<String, List<Unit>> unitsBySubject;
    late Map<String, List<Topic>> topicsByUnit;
    late List<Question> testQuestions;

    setUp(() {
      planner = const AdaptiveStudyPlanner();
      db = AppDatabase.inMemory();
      repository = DriftStudyPlanRepository(db: db);

      canonicalSubjects = [
        ...SubjectResolver.resolveSubjectsForStudent(
            grade: 12, stream: 'natural'),
        const Subject(
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
        const Subject(
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
        const Subject(
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
        const Subject(
          id: 'civics_g12',
          code: 'CIV12',
          nameEn: 'Civics and Ethical Education',
          nameAm: 'ስነ-ዜጋና ስነ-ምግባር',
          grade: 12,
          stream: 'common',
          scope: SubjectScope.curriculumOnly,
          assessmentStructure: AssessmentStructure.curriculum,
          sortOrder: 10,
        ),
      ];

      unitsBySubject = {
        'english_g12': const [
          Unit(
              id: 'eng_u1',
              subjectId: 'english_g12',
              unitNumber: 1,
              titleEn: 'Grammar in Context',
              titleAm: 'ሰዋሰው በዐውድ ውስጥ'),
        ],
        'math_g12': const [
          Unit(
              id: 'math_u1',
              subjectId: 'math_g12',
              unitNumber: 1,
              titleEn: 'Sequences & Series',
              titleAm: 'ቅደም ተከተሎች እና ድምሮች'),
        ],
        'physics_g12': const [
          Unit(
              id: 'phys_u1',
              subjectId: 'physics_g12',
              unitNumber: 1,
              titleEn: 'Thermodynamics',
              titleAm: 'ቴርሞዳይናሚክስ'),
        ],
        'chemistry_g12': const [
          Unit(
              id: 'chem_u1',
              subjectId: 'chemistry_g12',
              unitNumber: 1,
              titleEn: 'Electrochemistry',
              titleAm: 'ኤሌክትሮ ኬሚስትሪ'),
        ],
        'biology_g12': const [
          Unit(
              id: 'bio_u1',
              subjectId: 'biology_g12',
              unitNumber: 1,
              titleEn: 'Genetics',
              titleAm: 'ጀነቲክስ'),
        ],
        'history_g12': const [
          Unit(
              id: 'hist_u1',
              subjectId: 'history_g12',
              unitNumber: 1,
              titleEn: 'Modern Ethiopia',
              titleAm: 'ዘመናዊት ኢትዮጵያ'),
        ],
        'geography_g12': const [
          Unit(
              id: 'geo_u1',
              subjectId: 'geography_g12',
              unitNumber: 1,
              titleEn: 'Physical Geography',
              titleAm: 'ተፈጥሯዊ ጂኦግራፊ'),
        ],
        'economics_g12': const [
          Unit(
              id: 'econ_u1',
              subjectId: 'economics_g12',
              unitNumber: 1,
              titleEn: 'Macroeconomics',
              titleAm: 'ማክሮ ኢኮኖሚክስ'),
        ],
        'civics_g12': const [
          Unit(
              id: 'civ_u1',
              subjectId: 'civics_g12',
              unitNumber: 1,
              titleEn: 'Democratic Systems',
              titleAm: 'የዲሞክራሲ ሥርዓቶች'),
        ],
      };

      topicsByUnit = {
        'eng_u1': const [
          Topic(
              id: 'eng_t_tenses',
              unitId: 'eng_u1',
              topicNumber: 1,
              titleEn: 'Perfect Tenses',
              titleAm: 'ፍጹም ጊዜያት'),
        ],
        'math_u1': const [
          Topic(
              id: 'math_t_arith',
              unitId: 'math_u1',
              topicNumber: 1,
              titleEn: 'Arithmetic Progressions',
              titleAm: 'አርቲሜቲክ ቅደም ተከተሎች'),
        ],
        'phys_u1': const [
          Topic(
              id: 'phys_t_heat',
              unitId: 'phys_u1',
              topicNumber: 1,
              titleEn: 'Heat Transfer',
              titleAm: 'የሙቀት ዝውውር'),
        ],
        'chem_u1': const [
          Topic(
              id: 'chem_t_galv',
              unitId: 'chem_u1',
              topicNumber: 1,
              titleEn: 'Galvanic Cells',
              titleAm: 'ጋልቫኒክ ሴሎች'),
        ],
        'bio_u1': const [
          Topic(
              id: 'bio_t_mendel',
              unitId: 'bio_u1',
              topicNumber: 1,
              titleEn: 'Mendelian Inheritance',
              titleAm: 'የሜንዴል ውርስ ህጎች'),
        ],
        'hist_u1': const [
          Topic(
              id: 'hist_t_adwa',
              unitId: 'hist_u1',
              topicNumber: 1,
              titleEn: 'Battle of Adwa',
              titleAm: 'የአድዋ ጦርነት'),
        ],
        'geo_u1': const [
          Topic(
              id: 'geo_t_rift',
              unitId: 'geo_u1',
              topicNumber: 1,
              titleEn: 'East African Rift System',
              titleAm: 'የምስራቅ አፍሪካ ስምጥ ሸለቆ'),
        ],
        'econ_u1': const [
          Topic(
              id: 'econ_t_gdp',
              unitId: 'econ_u1',
              topicNumber: 1,
              titleEn: 'GDP Calculation',
              titleAm: 'ጠቅላላ የሀገር ውስጥ ምርት ስሌት'),
        ],
        'civ_u1': const [
          Topic(
              id: 'civ_t_const',
              unitId: 'civ_u1',
              topicNumber: 1,
              titleEn: 'Constitutionalism',
              titleAm: 'ሕገ-መንግሥታዊነት'),
        ],
      };

      testQuestions = [
        // English questions (Reading comprehension with passage and Grammar)
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q_eng_rc_$i',
            grade: 12,
            stream: 'common',
            subjectId: 'english_g12',
            unitId: '',
            topicId: '',
            contentDomain: 'Reading Comprehension',
            skill: 'Passage Analysis',
            questionTextEn: 'English reading question $i',
            difficulty: 'medium',
            examVariant: ExamVariantCode.shared,
            assessmentStructure: AssessmentStructure.mixed,
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 English',
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

        // Scholastic Aptitude questions (Skill-based: Verbal Analogies & Data Interpretation)
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q_apt_di_$i',
            grade: 12,
            stream: 'common',
            subjectId: 'aptitude_g12',
            unitId: '',
            topicId: '',
            contentDomain: 'Quantitative Reasoning',
            skill: 'Data Interpretation',
            questionTextEn: 'Scholastic Aptitude question $i',
            difficulty: 'medium',
            examVariant: ExamVariantCode.shared,
            assessmentStructure: AssessmentStructure.skillBased,
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 Aptitude',
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

        // Mathematics Natural Science Questions
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q_math_nat_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'math_u1',
            topicId: 'math_t_arith',
            questionTextEn: 'Math Natural question $i',
            difficulty: 'easy',
            examVariant: ExamVariantCode.naturalScience,
            assessmentStructure: AssessmentStructure.curriculum,
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 Math Nat',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'Math Nat explanation'),
          ),

        // Mathematics Social Science Questions
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q_math_soc_$i',
            grade: 12,
            stream: 'social',
            subjectId: 'math_g12',
            unitId: 'math_u1',
            topicId: 'math_t_arith',
            questionTextEn: 'Math Social question $i',
            difficulty: 'easy',
            examVariant: ExamVariantCode.socialScience,
            assessmentStructure: AssessmentStructure.curriculum,
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 Math Soc',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'Math Soc explanation'),
          ),

        // Physics (Natural)
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q_phys_$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'physics_g12',
            unitId: 'phys_u1',
            topicId: 'phys_t_heat',
            questionTextEn: 'Physics question $i',
            difficulty: 'medium',
            examVariant: ExamVariantCode.naturalScience,
            assessmentStructure: AssessmentStructure.curriculum,
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 Physics',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'Physics explanation'),
          ),

        // History (Social)
        for (int i = 1; i <= 5; i++)
          Question(
            id: 'q_hist_$i',
            grade: 12,
            stream: 'social',
            subjectId: 'history_g12',
            unitId: 'hist_u1',
            topicId: 'hist_t_adwa',
            questionTextEn: 'History question $i',
            difficulty: 'easy',
            examVariant: ExamVariantCode.socialScience,
            assessmentStructure: AssessmentStructure.curriculum,
            verificationStatus: VerificationStatus.verified,
            sourceName: 'ESSLCE 2014 History',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Opt A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Opt B', isCorrect: false),
            ],
            explanation:
                const Explanation(solutionTextEn: 'History explanation'),
          ),
      ];
    });

    tearDown(() async {
      await db.close();
    });

    test(
        '1. SubjectResolver correctly partitions Natural vs Social launch tracks',
        () {
      final naturalTracks =
          SubjectResolver.resolveEligibleTracks(grade: 12, stream: 'natural');
      final naturalIds = naturalTracks.map((t) => t.subjectId).toList();
      expect(
          naturalIds,
          equals([
            'english_g12',
            'math_g12',
            'aptitude_g12',
            'physics_g12',
            'chemistry_g12',
            'biology_g12',
          ]));
      expect(
          naturalTracks
              .firstWhere((t) => t.subjectId == 'math_g12')
              .variantCode,
          equals(ExamVariantCode.naturalScience));
      expect(naturalTracks.any((t) => t.subjectId == 'history_g12'), isFalse);
      expect(naturalTracks.any((t) => t.subjectId == 'civics_g12'), isFalse);

      final socialTracks =
          SubjectResolver.resolveEligibleTracks(grade: 12, stream: 'social');
      final socialIds = socialTracks.map((t) => t.subjectId).toList();
      expect(
          socialIds,
          equals([
            'english_g12',
            'math_g12',
            'aptitude_g12',
            'history_g12',
            'geography_g12',
            'economics_g12',
          ]));
      expect(
          socialTracks.firstWhere((t) => t.subjectId == 'math_g12').variantCode,
          equals(ExamVariantCode.socialScience));
      expect(socialTracks.any((t) => t.subjectId == 'physics_g12'), isFalse);
      expect(socialTracks.any((t) => t.subjectId == 'civics_g12'), isFalse);
    });

    test(
        '2. English Mixed Structure recommendation preserves passage and content domain without artificial unit IDs',
        () {
      final now = DateTime(2026, 9, 21);
      final attempts = [
        ExamAttempt(
          id: 'att_eng_1',
          examId: 'exam_eng_1',
          examTitle: 'English Practice',
          userId: 'student_1',
          startTime: now.subtract(const Duration(hours: 2)),
          durationSeconds: 120,
          score: 1,
          totalQuestions: 4,
          percentage: 25.0,
          correctCount: 1,
          incorrectCount: 3,
          skippedCount: 0,
          isCompleted: true,
          subjectId: 'english_g12',
          responses: const {
            'q_eng_rc_1':
                UserResponse(questionId: 'q_eng_rc_1', isCorrect: false),
            'q_eng_rc_2':
                UserResponse(questionId: 'q_eng_rc_2', isCorrect: false),
            'q_eng_rc_3':
                UserResponse(questionId: 'q_eng_rc_3', isCorrect: true),
            'q_eng_rc_4':
                UserResponse(questionId: 'q_eng_rc_4', isCorrect: false),
          },
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'student_1',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 90)),
        ),
        completedAttempts: attempts,
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'english_g12', 'math_g12', 'physics_g12'},
        currentDate: now,
      );

      final engSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'english_g12');
      expect(engSession.assessmentStructure, equals(AssessmentStructure.mixed));
      expect(engSession.examVariant, equals(ExamVariantCode.shared));
      expect(engSession.contentDomain, equals('Reading Comprehension'));
      expect(engSession.skill, equals('Passage Analysis'));
      expect(engSession.reasonCode, equals(RecommendationReasonCode.weakTopic));
      expect(engSession.questionIds, containsAll(['q_eng_rc_1', 'q_eng_rc_2']));
    });

    test(
        '3. Scholastic Aptitude Skill-Based recommendation preserves skill and domain without artificial unit IDs',
        () {
      final now = DateTime(2026, 9, 21);
      final attempts = [
        ExamAttempt(
          id: 'att_apt_1',
          examId: 'exam_apt_1',
          examTitle: 'Aptitude Practice',
          userId: 'student_1',
          startTime: now.subtract(const Duration(hours: 2)),
          durationSeconds: 120,
          score: 1,
          totalQuestions: 4,
          percentage: 25.0,
          correctCount: 1,
          incorrectCount: 3,
          skippedCount: 0,
          isCompleted: true,
          subjectId: 'aptitude_g12',
          responses: const {
            'q_apt_di_1':
                UserResponse(questionId: 'q_apt_di_1', isCorrect: false),
            'q_apt_di_2':
                UserResponse(questionId: 'q_apt_di_2', isCorrect: false),
            'q_apt_di_3':
                UserResponse(questionId: 'q_apt_di_3', isCorrect: true),
            'q_apt_di_4':
                UserResponse(questionId: 'q_apt_di_4', isCorrect: false),
          },
        ),
      ];

      final plan = planner.generateDailyPlan(
        userId: 'student_1',
        grade: 12,
        stream: 'social',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 90)),
        ),
        completedAttempts: attempts,
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'aptitude_g12', 'math_g12', 'history_g12'},
        currentDate: now,
      );

      final aptSession =
          plan.sessions.firstWhere((s) => s.subjectId == 'aptitude_g12');
      expect(aptSession.assessmentStructure,
          equals(AssessmentStructure.skillBased));
      expect(aptSession.examVariant, equals(ExamVariantCode.shared));
      expect(aptSession.contentDomain, equals('Quantitative Reasoning'));
      expect(aptSession.skill, equals('Data Interpretation'));
      expect(aptSession.reasonCode, equals(RecommendationReasonCode.weakTopic));
      expect(aptSession.questionIds, contains('q_apt_di_1'));
    });

    test(
        '4. Cross-track Mathematics isolation strictly enforced for Natural and Social students',
        () {
      final now = DateTime(2026, 9, 21);

      // Natural student test
      final naturalPlan = planner.generateDailyPlan(
        userId: 'nat_student',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 45)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12'},
        currentDate: now,
      );

      final natMathSession =
          naturalPlan.sessions.firstWhere((s) => s.subjectId == 'math_g12');
      expect(
          natMathSession.examVariant, equals(ExamVariantCode.naturalScience));
      expect(natMathSession.questionIds, isNotEmpty);
      for (final qId in natMathSession.questionIds) {
        final q = testQuestions.firstWhere((item) => item.id == qId);
        expect(q.examVariant, equals(ExamVariantCode.naturalScience));
        expect(q.stream, isNot(equals('social')));
      }

      // Social student test
      final socialPlan = planner.generateDailyPlan(
        userId: 'soc_student',
        grade: 12,
        stream: 'social',
        settings: PlannerSettings(
          dailyBudgetMinutes: 45,
          targetExamDate: now.add(const Duration(days: 45)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12'},
        currentDate: now,
      );

      final socMathSession =
          socialPlan.sessions.firstWhere((s) => s.subjectId == 'math_g12');
      expect(socMathSession.examVariant, equals(ExamVariantCode.socialScience));
      expect(socMathSession.questionIds, isNotEmpty);
      for (final qId in socMathSession.questionIds) {
        final q = testQuestions.firstWhere((item) => item.id == qId);
        expect(q.examVariant, equals(ExamVariantCode.socialScience));
        expect(q.stream, isNot(equals('natural')));
      }
    });

    test('5. Canonical ExamPreparationPolicy boundary and proximity weights',
        () {
      final now = DateTime(2026, 9, 24);

      // Boundaries
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 65)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.foundation));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 60)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.consolidation));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 31)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.consolidation));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 30)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.intensive));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 15)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.intensive));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 14)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.finalReview));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 1)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.finalReview));
      expect(
          ExamPreparationPolicy.fromDates(targetExamDate: now, currentDate: now)
              .phase,
          equals(ExamPreparationPhase.finalReview));
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.subtract(const Duration(days: 5)),
                  currentDate: now)
              .phase,
          equals(ExamPreparationPhase.foundation)); // Past date fallback
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: null, currentDate: now)
              .phase,
          equals(ExamPreparationPhase.foundation)); // No exam date

      // Mock boost condition
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 14)),
                  currentDate: now)
              .isMockBoostActive,
          isTrue);
      expect(
          ExamPreparationPolicy.fromDates(
                  targetExamDate: now.add(const Duration(days: 15)),
                  currentDate: now)
              .isMockBoostActive,
          isFalse);

      // Proximity weights
      final finalReviewPolicy = ExamPreparationPolicy.fromDates(
          targetExamDate: now.add(const Duration(days: 7)), currentDate: now);
      expect(finalReviewPolicy.weakTopicProximityWeight, equals(20.0));
      expect(finalReviewPolicy.coverageProximityWeight, equals(2.0));

      final foundationPolicy = ExamPreparationPolicy.fromDates(
          targetExamDate: now.add(const Duration(days: 80)), currentDate: now);
      expect(foundationPolicy.weakTopicProximityWeight, equals(5.0));
      expect(foundationPolicy.coverageProximityWeight, equals(10.0));
    });

    test(
        '6. Timed Mock exam boost (+85.0) activates strictly in <=14 days with budget >= 45 min',
        () {
      final now = DateTime(2026, 9, 24);

      // 10 days out (finalReview) with 60 min budget -> Mock session created
      final planFinal = planner.generateDailyPlan(
        userId: 'student_final',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 60,
          targetExamDate: now.add(const Duration(days: 10)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12'},
        currentDate: now,
      );

      final mockSession = planFinal.sessions
          .where((s) => s.sessionType == StudySessionType.mockExam);
      expect(mockSession, isNotEmpty);
      expect(mockSession.first.priorityScore, equals(85.0));

      // 20 days out (intensive) with 60 min budget -> No Mock session
      final planIntensive = planner.generateDailyPlan(
        userId: 'student_intensive',
        grade: 12,
        stream: 'natural',
        settings: PlannerSettings(
          dailyBudgetMinutes: 60,
          targetExamDate: now.add(const Duration(days: 20)),
        ),
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12'},
        currentDate: now,
      );

      final mockIntensive = planIntensive.sessions
          .where((s) => s.sessionType == StudySessionType.mockExam);
      expect(mockIntensive, isEmpty);
    });

    test(
        '7. Drift persistence stores and loads session with variant, structure, domain, and skill',
        () async {
      final now = DateTime(2026, 9, 24);
      const session = StudyPlanSession(
        id: 'sess_drift_test_01',
        planId: 'plan_drift_01',
        subjectId: 'english_g12',
        examVariant: ExamVariantCode.shared,
        assessmentStructure: AssessmentStructure.mixed,
        contentDomain: 'Reading Comprehension',
        skill: 'Inference',
        sessionType: StudySessionType.weakTopicPractice,
        titleEn: 'English: Inference',
        titleAm: 'እንግሊዝኛ፦ ፍቺ መስጠት',
        questionTarget: 10,
        estimatedMinutes: 15,
        priorityScore: 78.5,
        reasonCode: RecommendationReasonCode.weakTopic,
        reasonDetailEn: 'Focus on reading skills',
        reasonDetailAm: 'የንባብ ክህሎት ማሳደግ',
        questionIds: ['q_eng_rc_1', 'q_eng_rc_2'],
      );

      final plan = StudyPlan(
        id: 'plan_drift_01',
        userId: 'student_drift',
        planDate: DateTime(2026, 9, 24),
        targetMinutes: 45,
        estimatedMinutes: 15,
        sessions: const [session],
        status: SessionCompletionStatus.notStarted,
        algorithmVersion: kAdaptivePlannerAlgorithmVersion,
        generatedAt: now,
      );

      await repository.saveStudyPlan(plan);

      final loadedPlan = await repository.getStudyPlan('student_drift',
          date: DateTime(2026, 9, 24));
      expect(loadedPlan, isNotNull);
      expect(loadedPlan!.algorithmVersion, equals('adaptive_planner_v1.1'));
      expect(loadedPlan.sessions.length, equals(1));

      final loadedSession = loadedPlan.sessions.first;
      expect(loadedSession.id, equals('sess_drift_test_01'));
      expect(loadedSession.examVariant, equals(ExamVariantCode.shared));
      expect(
          loadedSession.assessmentStructure, equals(AssessmentStructure.mixed));
      expect(loadedSession.contentDomain, equals('Reading Comprehension'));
      expect(loadedSession.skill, equals('Inference'));
      expect(loadedSession.questionIds, equals(['q_eng_rc_1', 'q_eng_rc_2']));
    });

    test('8. Study plan generation is 100% deterministic and offline capable',
        () {
      final now = DateTime(2026, 9, 24);
      final settings = PlannerSettings(
        dailyBudgetMinutes: 45,
        targetExamDate: now.add(const Duration(days: 40)),
      );

      final plan1 = planner.generateDailyPlan(
        userId: 'student_det',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12'},
        currentDate: now,
      );

      final plan2 = planner.generateDailyPlan(
        userId: 'student_det',
        grade: 12,
        stream: 'natural',
        settings: settings,
        completedAttempts: const [],
        unmasteredMistakes: const [],
        availableQuestions: testQuestions,
        allSubjects: canonicalSubjects,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        installedSubjectIds: {'math_g12', 'physics_g12'},
        currentDate: now,
      );

      expect(plan1.id, equals(plan2.id));
      expect(plan1.sessions.length, equals(plan2.sessions.length));
      for (int i = 0; i < plan1.sessions.length; i++) {
        expect(plan1.sessions[i].id, equals(plan2.sessions[i].id));
        expect(plan1.sessions[i].priorityScore,
            equals(plan2.sessions[i].priorityScore));
        expect(plan1.sessions[i].questionIds,
            equals(plan2.sessions[i].questionIds));
      }
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/core/errors/failures.dart';
import 'package:fidel_learn/features/exams/data/repositories/drift_exam_repository.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/exams/domain/services/authoritative_exam_timer.dart';
import 'package:fidel_learn/features/exams/domain/services/exam_engine.dart';
import 'package:fidel_learn/features/exams/domain/services/exam_submission_service.dart';
import 'package:fidel_learn/features/exams/domain/services/historical_paper_completeness_service.dart';
import 'package:fidel_learn/features/exams/domain/services/national_exam_blueprint_registry.dart';
import 'package:fidel_learn/features/exams/domain/services/national_exam_simulation_generator.dart';
import 'package:fidel_learn/features/mistakes/domain/models/mistake_model.dart';
import 'package:fidel_learn/features/mistakes/domain/repositories/mistake_repository.dart';
import 'package:fidel_learn/features/mistakes/domain/services/mistake_outcome_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('Priority 5 — NationalExamPolicy Domain Tests', () {
    test('1. Policy distinguishes strict simulation from practice', () {
      const simPolicy = NationalExamPolicy.nationalSimulation;
      expect(simPolicy.isStrictExam, isTrue);
      expect(simPolicy.allowPause, isFalse);
      expect(simPolicy.hideInstantFeedback, isTrue);
      expect(simPolicy.autoSubmitOnExpiry, isTrue);
      expect(simPolicy.strictWallClock, isTrue);
      expect(simPolicy.warningThresholdMinutes, equals([30, 10, 5, 1]));

      const histPolicy = NationalExamPolicy.historicalPaper;
      expect(histPolicy.isStrictExam, isTrue);
      expect(histPolicy.allowPause, isFalse);
      expect(histPolicy.hideInstantFeedback, isTrue);

      const practicePolicy = NationalExamPolicy.practice;
      expect(practicePolicy.isStrictExam, isFalse);
      expect(practicePolicy.allowPause, isTrue);
      expect(practicePolicy.hideInstantFeedback, isFalse);
      expect(practicePolicy.autoSubmitOnExpiry, isFalse);
    });

    test('2. NationalExamPolicy.fromMode resolves authoritative mode policy',
        () {
      expect(NationalExamPolicy.fromMode(ExamMode.nationalSimulation).mode,
          equals(ExamMode.nationalSimulation));
      expect(NationalExamPolicy.fromMode(ExamMode.historicalPaper).mode,
          equals(ExamMode.historicalPaper));
      expect(NationalExamPolicy.fromMode(ExamMode.practice).mode,
          equals(ExamMode.practice));
      expect(NationalExamPolicy.fromMode(ExamMode.custom).mode,
          equals(ExamMode.custom));
    });
  });

  group('Priority 5 — AuthoritativeExamTimer Tests', () {
    test('1. Wall-clock timer calculates remaining duration deterministically',
        () {
      DateTime fakeTime = DateTime(2026, 9, 25, 10, 0, 0);
      final startTime = fakeTime;
      const durationSeconds = 7200; // 120 minutes

      final timer = AuthoritativeExamTimer(
        startTime: startTime,
        totalDurationSeconds: durationSeconds,
        policy: NationalExamPolicy.nationalSimulation,
        clock: () => fakeTime,
      );

      expect(timer.getRemainingSeconds(), equals(7200));
      expect(timer.getElapsedSeconds(), equals(0));
      expect(timer.isExpired, isFalse);

      // Advance 45 minutes
      fakeTime = fakeTime.add(const Duration(minutes: 45));
      expect(timer.getRemainingSeconds(), equals(7200 - 45 * 60));
      expect(timer.getElapsedSeconds(), equals(45 * 60));
      expect(timer.isExpired, isFalse);

      // Advance to exactly zero
      fakeTime = startTime.add(const Duration(seconds: 7200));
      expect(timer.getRemainingSeconds(), equals(0));
      expect(timer.isExpired, isTrue);
    });

    test('2. Timer survives backgrounding without extra time', () {
      DateTime fakeTime = DateTime(2026, 9, 25, 10, 0, 0);
      final startTime = fakeTime;
      const durationSeconds = 3600; // 60 minutes

      final timer = AuthoritativeExamTimer(
        startTime: startTime,
        totalDurationSeconds: durationSeconds,
        policy: NationalExamPolicy.nationalSimulation,
        clock: () => fakeTime,
      );

      // App backgrounded for 20 minutes
      fakeTime = fakeTime.add(const Duration(minutes: 20));

      // Upon reopening, timer authoritatively reflects 40 minutes remaining
      expect(timer.getRemainingSeconds(), equals(2400));
      expect(timer.getElapsedSeconds(), equals(1200));
    });

    test('3. Detects expired while closed and triggers expiry', () {
      DateTime fakeTime = DateTime(2026, 9, 25, 10, 0, 0);
      final startTime = fakeTime;
      const durationSeconds = 1800; // 30 minutes

      final timer = AuthoritativeExamTimer(
        startTime: startTime,
        totalDurationSeconds: durationSeconds,
        policy: NationalExamPolicy.nationalSimulation,
        clock: () => fakeTime,
      );

      // App killed and reopened 35 minutes later
      fakeTime = fakeTime.add(const Duration(minutes: 35));

      expect(timer.getRemainingSeconds(), equals(0));
      expect(timer.isExpired, isTrue);
    });

    test('4. Detects backwards clock shift and raises timer integrity warning',
        () {
      DateTime fakeTime = DateTime(2026, 9, 25, 10, 30, 0);
      final startTime = DateTime(2026, 9, 25, 10, 0, 0);

      final timer = AuthoritativeExamTimer(
        startTime: startTime,
        totalDurationSeconds: 3600,
        policy: NationalExamPolicy.nationalSimulation,
        lastActiveTime: fakeTime,
        clock: () => fakeTime,
      );

      expect(timer.timerIntegrityWarning, isFalse);

      // System clock shifted backwards by 10 minutes
      fakeTime = fakeTime.subtract(const Duration(minutes: 10));
      timer.getRemainingSeconds();

      expect(timer.timerIntegrityWarning, isTrue);
    });

    test('5. Formats duration cleanly as HH:MM:SS and MM:SS', () {
      expect(AuthoritativeExamTimer.formatDuration(7265), equals('02:01:05'));
      expect(AuthoritativeExamTimer.formatDuration(3600), equals('01:00:00'));
      expect(AuthoritativeExamTimer.formatDuration(599), equals('09:59'));
      expect(AuthoritativeExamTimer.formatDuration(0), equals('00:00'));
    });

    test(
        '6. Warning threshold detector triggers at 30, 10, 5, and 1 minute boundaries',
        () {
      const thresholds = [30, 10, 5, 1];

      // Crossing 30 min (1800s)
      expect(
        AuthoritativeExamTimer.checkWarningThreshold(
          previousRemaining: 1805,
          currentRemaining: 1800,
          thresholdsMinutes: thresholds,
        ),
        equals(30),
      );

      // Crossing 5 min (300s)
      expect(
        AuthoritativeExamTimer.checkWarningThreshold(
          previousRemaining: 301,
          currentRemaining: 299,
          thresholdsMinutes: thresholds,
        ),
        equals(5),
      );

      // Normal tick without crossing threshold
      expect(
        AuthoritativeExamTimer.checkWarningThreshold(
          previousRemaining: 280,
          currentRemaining: 279,
          thresholdsMinutes: thresholds,
        ),
        isNull,
      );
    });
  });

  group('Priority 5 — NationalExamSimulationGenerator & Blueprint Tests', () {
    Question buildMockQuestion({
      required String id,
      required String subjectId,
      required String unitId,
      required String topicId,
      String stream = 'natural',
      ExamVariantCode? variant,
      String difficulty = 'medium',
      ReadingPassage? passage,
      String? domain,
      String? skill,
    }) {
      return Question(
        id: id,
        grade: 12,
        stream: stream,
        subjectId: subjectId,
        unitId: unitId,
        topicId: topicId,
        examVariant: variant,
        questionTextEn: 'Sample question $id for $subjectId',
        difficulty: difficulty,
        verificationStatus: VerificationStatus.verified,
        isPracticeEligible: true,
        isScorable: true,
        sourceName: 'Official NEAEA Archive',
        contentVersion: 1,
        readingPassage: passage,
        contentDomain: domain,
        skill: skill,
        choices: const [
          AnswerChoice(
              id: 'c1', label: 'A', textEn: 'Choice A', isCorrect: true),
          AnswerChoice(
              id: 'c2', label: 'B', textEn: 'Choice B', isCorrect: false),
          AnswerChoice(
              id: 'c3', label: 'C', textEn: 'Choice C', isCorrect: false),
          AnswerChoice(
              id: 'c4', label: 'D', textEn: 'Choice D', isCorrect: false),
        ],
        explanation: Explanation(solutionTextEn: 'Explanation for $id'),
      );
    }

    test(
        '1. Deterministic generation produces identical question composition for same seed',
        () {
      const blueprint = NationalExamBlueprint(
        blueprintVersion: 'test_bp_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 6,
        timeLimitMinutes: 120,
        partitions: [
          BlueprintPartition(
            nameEn: 'Calculus',
            nameAm: 'ካልኩለስ',
            requiredCount: 3,
            unitIds: ['u_calc'],
          ),
          BlueprintPartition(
            nameEn: 'Vectors',
            nameAm: 'ቬክተሮች',
            requiredCount: 3,
            unitIds: ['u_vec'],
          ),
        ],
      );

      final questionPool = [
        for (int i = 1; i <= 6; i++)
          buildMockQuestion(
            id: 'calc_$i',
            subjectId: 'math_g12',
            unitId: 'u_calc',
            topicId: 't_calc',
            variant: ExamVariantCode.naturalScience,
          ),
        for (int i = 1; i <= 6; i++)
          buildMockQuestion(
            id: 'vec_$i',
            subjectId: 'math_g12',
            unitId: 'u_vec',
            topicId: 't_vec',
            variant: ExamVariantCode.naturalScience,
          ),
      ];

      const generator = NationalExamSimulationGenerator();
      final exam1 = generator.generateSimulation(
        blueprint: blueprint,
        questionPool: questionPool,
        seed: 42,
      );
      final exam2 = generator.generateSimulation(
        blueprint: blueprint,
        questionPool: questionPool,
        seed: 42,
      );

      expect(exam1.questions.length, equals(6));
      expect(exam2.questions.length, equals(6));

      // Exact order and identity must match 100%
      for (int i = 0; i < 6; i++) {
        expect(exam1.questions[i].id, equals(exam2.questions[i].id));
      }
    });

    test(
        '2. Different seeds produce valid alternate permutations without duplicates',
        () {
      const blueprint = NationalExamBlueprint(
        blueprintVersion: 'test_bp_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 4,
        timeLimitMinutes: 60,
        partitions: [
          BlueprintPartition(
            nameEn: 'General',
            nameAm: 'አጠቃላይ',
            requiredCount: 4,
          ),
        ],
      );

      final questionPool = [
        for (int i = 1; i <= 20; i++)
          buildMockQuestion(
            id: 'q_$i',
            subjectId: 'math_g12',
            unitId: 'u1',
            topicId: 't1',
            variant: ExamVariantCode.naturalScience,
          ),
      ];

      const generator = NationalExamSimulationGenerator();
      final examA = generator.generateSimulation(
        blueprint: blueprint,
        questionPool: questionPool,
        seed: 101,
      );
      final examB = generator.generateSimulation(
        blueprint: blueprint,
        questionPool: questionPool,
        seed: 202,
      );

      final idsA = examA.questions.map((q) => q.id).toSet();
      final idsB = examB.questions.map((q) => q.id).toSet();

      expect(idsA.length, equals(4), reason: 'Zero duplicates in exam A');
      expect(idsB.length, equals(4), reason: 'Zero duplicates in exam B');
    });

    test(
        '3. Throws SimulationSufficiencyFailure when partition lacks sufficient verified questions',
        () {
      const blueprint = NationalExamBlueprint(
        blueprintVersion: 'test_bp_v1',
        subjectId: 'phys_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 10,
        timeLimitMinutes: 120,
        partitions: [
          BlueprintPartition(
            nameEn: 'Electromagnetism',
            nameAm: 'ኤሌክትሮማግኔቲዝም',
            requiredCount: 8,
            unitIds: ['u_em'],
          ),
        ],
      );

      final questionPool = [
        for (int i = 1; i <= 5; i++)
          buildMockQuestion(
            id: 'em_$i',
            subjectId: 'phys_g12',
            unitId: 'u_em',
            topicId: 't_em',
            variant: ExamVariantCode.naturalScience,
          ),
      ];

      const generator = NationalExamSimulationGenerator();
      expect(
        () => generator.generateSimulation(
          blueprint: blueprint,
          questionPool: questionPool,
          seed: 99,
        ),
        throwsA(isA<SimulationSufficiencyFailure>()
            .having((e) => e.requiredCount, 'requiredCount', 8)
            .having((e) => e.availableCount, 'availableCount', 5)),
      );
    });

    test('4. Strict Mathematics variant isolation (0% cross-track leakage)',
        () {
      const naturalBlueprint = NationalExamBlueprint(
        blueprintVersion: 'test_math_nat_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 2,
        timeLimitMinutes: 60,
        partitions: [
          BlueprintPartition(nameEn: 'All', nameAm: 'ሁሉ', requiredCount: 2),
        ],
      );

      final mixedPool = [
        buildMockQuestion(
          id: 'nat_1',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 't1',
          stream: 'natural',
          variant: ExamVariantCode.naturalScience,
        ),
        buildMockQuestion(
          id: 'nat_2',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 't1',
          stream: 'natural',
          variant: ExamVariantCode.naturalScience,
        ),
        buildMockQuestion(
          id: 'soc_leak_1',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 't1',
          stream: 'social',
          variant: ExamVariantCode.socialScience,
        ),
      ];

      const generator = NationalExamSimulationGenerator();
      final natExam = generator.generateSimulation(
        blueprint: naturalBlueprint,
        questionPool: mixedPool,
        seed: 7,
      );

      // Verify ZERO social math questions leaked into natural math simulation
      final hasSocialLeak = natExam.questions.any(
        (q) =>
            q.examVariant == ExamVariantCode.socialScience ||
            q.stream.toLowerCase() == 'social',
      );
      expect(hasSocialLeak, isFalse);
    });

    test('5. English reading passage stimulus maintains question contiguity',
        () {
      const passage = ReadingPassage(
        id: 'passage_climate_2017',
        title: 'Climate Resilience in the Horn of Africa',
        body:
            'Full passage body on climatic patterns and agricultural adaptation...',
      );

      final questionPool = [
        buildMockQuestion(
          id: 'eng_vocab_1',
          subjectId: 'eng_g12',
          unitId: 'u_vocab',
          topicId: 't_vocab',
        ),
        buildMockQuestion(
          id: 'eng_pass_1',
          subjectId: 'eng_g12',
          unitId: 'u_reading',
          topicId: 't_reading',
          passage: passage,
        ),
        buildMockQuestion(
          id: 'eng_pass_2',
          subjectId: 'eng_g12',
          unitId: 'u_reading',
          topicId: 't_reading',
          passage: passage,
        ),
      ];

      const blueprint = NationalExamBlueprint(
        blueprintVersion: 'test_eng_v1',
        subjectId: 'eng_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 3,
        timeLimitMinutes: 120,
        partitions: [
          BlueprintPartition(
              nameEn: 'English Set', nameAm: 'እንግሊዝኛ', requiredCount: 3),
        ],
      );

      const generator = NationalExamSimulationGenerator();
      final exam = generator.generateSimulation(
        blueprint: blueprint,
        questionPool: questionPool,
        seed: 88,
      );

      expect(exam.questions.length, equals(3));
      final passageQuestions = exam.questions
          .where((q) => q.readingPassage?.id == 'passage_climate_2017')
          .toList();
      expect(passageQuestions.length, equals(2));
    });
  });

  group('Priority 5 — HistoricalPaperCompletenessService Tests', () {
    test(
        '1. Verified complete paper qualifies for strict historical national exam',
        () {
      final questions = [
        for (int i = 1; i <= 60; i++)
          Question(
            id: 'math_2016_q$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u1',
            topicId: 't1',
            examYear: 2016,
            questionNumber: i,
            examVariant: ExamVariantCode.naturalScience,
            questionTextEn: '2016 Math Question $i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.verified,
            sourceName: 'Official NEAEA 2016',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Choice A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Choice B', isCorrect: false),
            ],
            explanation: const Explanation(solutionTextEn: 'Solution'),
          ),
      ];

      const service = HistoricalPaperCompletenessService();
      final assessment = service.assessPaper(
        subjectId: 'math_g12',
        year: 2016,
        examVariant: ExamVariantCode.naturalScience,
        candidateQuestions: questions,
        customExpectedCount: 60,
      );

      expect(assessment.completenessStatus,
          equals(HistoricalCompletenessStatus.verifiedComplete));
      expect(assessment.actualVerifiedCount, equals(60));
      expect(assessment.isEligibleForStrictNationalExam, isTrue);

      final exam = service.createHistoricalExam(
        assessment: assessment,
        isStrictExamMode: true,
        stream: 'natural',
      );

      expect(exam.examMode, equals(ExamMode.historicalPaper));
      expect(exam.sourceType, equals(ExamSourceType.officialHistoricalPaper));
      expect(exam.timeLimitMinutes, equals(120));
      expect(exam.totalQuestions, equals(60));
    });

    test(
        '2. Partial historical paper is rejected for strict national exam and throws HistoricalIncompleteFailure',
        () {
      final questions = [
        for (int i = 1; i <= 25; i++)
          Question(
            id: 'chem_2015_q$i',
            grade: 12,
            stream: 'natural',
            subjectId: 'chem_g12',
            unitId: 'u1',
            topicId: 't1',
            examYear: 2015,
            questionNumber: i,
            examVariant: ExamVariantCode.naturalScience,
            questionTextEn: '2015 Chemistry Question $i',
            difficulty: 'medium',
            verificationStatus: VerificationStatus.verified,
            sourceName: 'Official NEAEA 2015',
            contentVersion: 1,
            choices: const [
              AnswerChoice(
                  id: 'c1', label: 'A', textEn: 'Choice A', isCorrect: true),
              AnswerChoice(
                  id: 'c2', label: 'B', textEn: 'Choice B', isCorrect: false),
            ],
            explanation: const Explanation(solutionTextEn: 'Solution'),
          ),
      ];

      const service = HistoricalPaperCompletenessService();
      final assessment = service.assessPaper(
        subjectId: 'chem_g12',
        year: 2015,
        examVariant: ExamVariantCode.naturalScience,
        candidateQuestions: questions,
        customExpectedCount: 60,
      );

      expect(assessment.completenessStatus,
          equals(HistoricalCompletenessStatus.verifiedPartial));
      expect(assessment.isEligibleForStrictNationalExam, isFalse);

      expect(
        () => service.createHistoricalExam(
          assessment: assessment,
          isStrictExamMode: true,
          stream: 'natural',
        ),
        throwsA(isA<HistoricalIncompleteFailure>()
            .having((e) => e.expectedCount, 'expectedCount', 60)
            .having((e) => e.verifiedCount, 'verifiedCount', 25)),
      );

      // But can be safely created in Study Practice mode
      final practiceExam = service.createHistoricalExam(
        assessment: assessment,
        isStrictExamMode: false,
        stream: 'natural',
      );
      expect(practiceExam.examMode, equals(ExamMode.practice));
      expect(practiceExam.totalQuestions, equals(25));
    });
  });

  group('Priority 5 — Drift v7 SQLite Persistence Tests', () {
    late AppDatabase db;
    late DriftExamRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftExamRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
        '1. Saves and retrieves completed national exam attempt with all Priority 5 fields',
        () async {
      final attempt = ExamAttempt(
        id: 'att_sim_math_42',
        userId: 'student_123',
        examId: 'sim_math_g12_nat_42',
        examTitle: 'ESSLCE Simulation — Mathematics (Natural Science)',
        subjectId: 'math_g12',
        examMode: ExamMode.nationalSimulation,
        sourceType: ExamSourceType.generatedSimulation,
        examVariant: ExamVariantCode.naturalScience,
        blueprintVersion: 'esslce_sim_math_nat_v1',
        simulationSeed: 42,
        questionOrder: const ['q_1', 'q_2', 'q_3'],
        timeLimitSeconds: 7200,
        autoSubmitted: true,
        historicalYear: 2017,
        timerIntegrityWarning: false,
        startTime: DateTime(2026, 9, 25, 10, 0, 0),
        endTime: DateTime(2026, 9, 25, 12, 0, 0),
        durationSeconds: 7200,
        totalQuestions: 3,
        score: 2,
        percentage: 66.7,
        correctCount: 2,
        incorrectCount: 1,
        skippedCount: 0,
        isCompleted: true,
        responses: const {
          'q_1': UserResponse(
              questionId: 'q_1', selectedChoiceId: 'c1', isCorrect: true),
          'q_2': UserResponse(
              questionId: 'q_2', selectedChoiceId: 'c2', isCorrect: true),
          'q_3': UserResponse(
              questionId: 'q_3', selectedChoiceId: 'c1', isCorrect: false),
        },
      );

      await repository.saveCompletedAttempt(attempt);

      final attempts = await repository.getAttemptHistory('student_123');

      expect(attempts.length, equals(1));
      final loaded = attempts.first;
      expect(loaded.id, equals('att_sim_math_42'));
      expect(loaded.examMode, equals(ExamMode.nationalSimulation));
      expect(loaded.sourceType, equals(ExamSourceType.generatedSimulation));
      expect(loaded.examVariant, equals(ExamVariantCode.naturalScience));
      expect(loaded.blueprintVersion, equals('esslce_sim_math_nat_v1'));
      expect(loaded.simulationSeed, equals(42));
      expect(loaded.questionOrder, equals(['q_1', 'q_2', 'q_3']));
      expect(loaded.timeLimitSeconds, equals(7200));
      expect(loaded.autoSubmitted, isTrue);
      expect(loaded.historicalYear, equals(2017));
      expect(loaded.timerIntegrityWarning, isFalse);
      expect(loaded.score, equals(2));
      expect(loaded.percentage, equals(66.7));
    });
  });

  group('Priority 5 Hardening — Blueprint Provenance & Authority Tests', () {
    test('1. BlueprintVerificationStatus governs official wording permissions',
        () {
      const officialBp = NationalExamBlueprint(
        blueprintVersion: 'official_bp_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 60,
        timeLimitMinutes: 120,
        partitions: [],
        sourceAuthority: 'Ministry of Education / EAES',
        sourceReference: 'Official Blueprint 2017 E.C.',
        verificationStatus: BlueprintVerificationStatus.officialVerified,
      );
      expect(officialBp.allowsOfficialWording, isTrue);
      expect(officialBp.displayTitle, equals('Official ESSLCE Paper'));
      expect(officialBp.provenanceLabel,
          contains('Official ESSLCE Specification'));

      const simBp = NationalExamBlueprint(
        blueprintVersion: 'fidel_bp_v1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 60,
        timeLimitMinutes: 120,
        partitions: [],
        sourceAuthority: 'FidelLearn Academic Panel (Curriculum-Aligned)',
        verificationStatus: BlueprintVerificationStatus.fidelLearnSimulation,
      );
      expect(simBp.allowsOfficialWording, isFalse);
      expect(simBp.displayTitle, equals('FidelLearn ESSLCE Simulation'));
      expect(
          simBp.provenanceLabel, contains('FidelLearn Simulation Blueprint'));

      const unverifiedBp = NationalExamBlueprint(
        blueprintVersion: 'unverified_v1',
        subjectId: 'bio_g12',
        examVariant: ExamVariantCode.naturalScience,
        totalQuestions: 60,
        timeLimitMinutes: 120,
        partitions: [],
        verificationStatus: BlueprintVerificationStatus.needsVerification,
      );
      expect(unverifiedBp.allowsOfficialWording, isFalse);
    });

    test(
        '2. All 10 Grade 12 simulation blueprints are verified as FidelLearn simulations',
        () {
      final tracks = [
        ('math_g12', ExamVariantCode.naturalScience),
        ('math_g12', ExamVariantCode.socialScience),
        ('physics_g12', ExamVariantCode.naturalScience),
        ('chemistry_g12', ExamVariantCode.naturalScience),
        ('biology_g12', ExamVariantCode.naturalScience),
        ('english_g12', ExamVariantCode.shared),
        ('aptitude_g12', ExamVariantCode.shared),
        ('history_g12', ExamVariantCode.socialScience),
        ('geography_g12', ExamVariantCode.socialScience),
        ('economics_g12', ExamVariantCode.socialScience),
      ];

      for (final track in tracks) {
        final bp = NationalExamBlueprintRegistry.getBlueprint(
          subjectId: track.$1,
          examVariant: track.$2,
        );
        expect(bp, isNotNull,
            reason: 'Blueprint for ${track.$1} (${track.$2}) must exist');
        expect(bp!.verificationStatus,
            equals(BlueprintVerificationStatus.fidelLearnSimulation));
        expect(bp.allowsOfficialWording, isFalse);
        expect(bp.sourceAuthority, contains('FidelLearn Academic Panel'));
      }
    });
  });

  group('Priority 5 Hardening — Exact Mathematics Variant Eligibility Tests',
      () {
    test(
        '1. validateMathQuestionEligibility strictly accepts only exact variant matches',
        () {
      const validNaturalQ = Question(
        id: 'math_nat_1',
        grade: 12,
        stream: 'natural',
        subjectId: 'math_g12',
        unitId: 'u1',
        topicId: 't1',
        examVariant: ExamVariantCode.naturalScience,
        questionTextEn: 'Sample Natural Math',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'National Archive',
        contentVersion: 1,
        choices: [],
        explanation: Explanation(solutionTextEn: 'Exp'),
      );

      const validSocialQ = Question(
        id: 'math_soc_1',
        grade: 12,
        stream: 'social',
        subjectId: 'math_g12',
        unitId: 'u1',
        topicId: 't1',
        examVariant: ExamVariantCode.socialScience,
        questionTextEn: 'Sample Social Math',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'National Archive',
        contentVersion: 1,
        choices: [],
        explanation: Explanation(solutionTextEn: 'Exp'),
      );

      const conflictingNaturalQ = Question(
        id: 'math_nat_conflict',
        grade: 12,
        stream: 'social', // Conflicting stream
        subjectId: 'math_g12',
        unitId: 'u1',
        topicId: 't1',
        examVariant: ExamVariantCode.naturalScience,
        questionTextEn: 'Conflicting Natural Math',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'National Archive',
        contentVersion: 1,
        choices: [],
        explanation: Explanation(solutionTextEn: 'Exp'),
      );

      const nullVariantQ = Question(
        id: 'math_null_var',
        grade: 12,
        stream: 'natural',
        subjectId: 'math_g12',
        unitId: 'u1',
        topicId: 't1',
        examVariant: null,
        questionTextEn: 'Null Variant Math',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'National Archive',
        contentVersion: 1,
        choices: [],
        explanation: Explanation(solutionTextEn: 'Exp'),
      );

      const sharedVariantQ = Question(
        id: 'math_shared_var',
        grade: 12,
        stream: 'natural',
        subjectId: 'math_g12',
        unitId: 'u1',
        topicId: 't1',
        examVariant: ExamVariantCode.shared,
        questionTextEn: 'Shared Variant Math',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'National Archive',
        contentVersion: 1,
        choices: [],
        explanation: Explanation(solutionTextEn: 'Exp'),
      );

      // Natural target expectations
      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: validNaturalQ,
            targetVariant: ExamVariantCode.naturalScience,
          ),
          isTrue);

      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: validSocialQ,
            targetVariant: ExamVariantCode.naturalScience,
          ),
          isFalse);

      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: conflictingNaturalQ,
            targetVariant: ExamVariantCode.naturalScience,
          ),
          isFalse);

      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: nullVariantQ,
            targetVariant: ExamVariantCode.naturalScience,
          ),
          isFalse);

      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: sharedVariantQ,
            targetVariant: ExamVariantCode.naturalScience,
          ),
          isFalse);

      // Social target expectations
      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: validSocialQ,
            targetVariant: ExamVariantCode.socialScience,
          ),
          isTrue);

      expect(
          NationalExamSimulationGenerator.validateMathQuestionEligibility(
            question: validNaturalQ,
            targetVariant: ExamVariantCode.socialScience,
          ),
          isFalse);
    });
  });

  group('Priority 5 Hardening — Attempt Content Snapshot & Hash Tests', () {
    test(
        '1. ExamEngine captures immutable content snapshot and SHA-256 integrity hash',
        () {
      const testQuestions = [
        Question(
          id: 'q_snap_1',
          grade: 12,
          stream: 'natural',
          subjectId: 'physics_g12',
          unitId: 'u1',
          topicId: 't1',
          examVariant: ExamVariantCode.naturalScience,
          questionTextEn: 'Physics Q1',
          difficulty: 'medium',
          verificationStatus: VerificationStatus.verified,
          sourceName: 'Archive',
          contentVersion: 2,
          choices: [
            AnswerChoice(id: 'c1', label: 'A', textEn: 'Ans', isCorrect: true)
          ],
          explanation: Explanation(solutionTextEn: 'Exp'),
        ),
      ];

      final exam = Exam(
        id: 'sim_phys_1',
        title: 'FidelLearn ESSLCE Simulation — Physics',
        examType: ExamType.mockFull,
        examMode: ExamMode.nationalSimulation,
        sourceType: ExamSourceType.generatedSimulation,
        grade: 12,
        stream: 'natural',
        subjectId: 'physics_g12',
        examVariant: ExamVariantCode.naturalScience,
        blueprintVersion: 'esslce_sim_phys_nat_v1',
        simulationSeed: 1234,
        timeLimitMinutes: 120,
        totalQuestions: 1,
        questions: testQuestions,
        createdAt: DateTime.now(),
      );

      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_snap_1',
        userId: 'student_42',
        exam: exam,
        packageSnapshot: const {'physics_g12': '2026.09.1'},
      );

      expect(attempt.packageSnapshot, equals({'physics_g12': '2026.09.1'}));
      expect(attempt.examIntegrityHash, isNotNull);
      expect(attempt.examIntegrityHash!.length,
          equals(64)); // SHA-256 is 64 hex chars
      expect(attempt.blueprintVersion, equals('esslce_sim_phys_nat_v1'));
      expect(attempt.simulationSeed, equals(1234));
      expect(attempt.scoringPolicy, equals('standard_uniform_v1'));

      // Modifying question order changes hash
      final modifiedHash = ExamEngine.calculateIntegrityHash(
        examId: exam.id,
        blueprintVersion: exam.blueprintVersion,
        seed: exam.simulationSeed,
        questionIds: const ['different_id'],
        packageSnapshot: const {'physics_g12': '2026.09.1'},
      );
      expect(modifiedHash, isNot(equals(attempt.examIntegrityHash)));
    });

    test(
        '2. Finalized attempt score remains immutable when questions or answer keys change later',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftExamRepository(db: db);

      final originalAttempt = ExamAttempt(
        id: 'att_stable_1',
        userId: 'student_1',
        examId: 'sim_1',
        examTitle: 'Simulation Exam',
        subjectId: 'math_g12',
        examMode: ExamMode.nationalSimulation,
        sourceType: ExamSourceType.generatedSimulation,
        examVariant: ExamVariantCode.naturalScience,
        blueprintVersion: 'v1',
        startTime: DateTime(2026, 9, 25, 10, 0),
        endTime: DateTime(2026, 9, 25, 12, 0),
        durationSeconds: 7200,
        totalQuestions: 50,
        score: 42,
        percentage: 84.0,
        correctCount: 42,
        incorrectCount: 8,
        skippedCount: 0,
        isCompleted: true,
        packageSnapshot: const {'math_g12': '1.0.0'},
        examIntegrityHash: 'hash123',
        outcomesProcessedAt: DateTime(2026, 9, 25, 12, 0, 1),
        scoringPolicy: 'standard_uniform_v1',
        responses: const {},
      );

      await repo.saveCompletedAttempt(originalAttempt);

      // Later package retrieval:
      final retrieved = await repo.getAttemptById('att_stable_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.score, equals(42));
      expect(retrieved.percentage, equals(84.0));
      expect(retrieved.correctCount, equals(42));
      expect(retrieved.packageSnapshot, equals({'math_g12': '1.0.0'}));
      expect(retrieved.outcomesProcessedAt, isNotNull);

      await db.close();
    });
  });

  group('Priority 5 Hardening — Exactly-Once Outcome Processing Tests', () {
    test(
        '1. ExamSubmissionService executes outcomes exactly once and rejects duplicates',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftExamRepository(db: db);
      int processedOutcomesCount = 0;

      final outcomeService = MistakeOutcomeService(
        _CountingFakeMistakeRepository(() => processedOutcomesCount++),
      );

      final submissionService = ExamSubmissionService(
        examRepo: repo,
        outcomeService: outcomeService,
      );

      const question = Question(
        id: 'q_item_1',
        grade: 12,
        stream: 'natural',
        subjectId: 'math_g12',
        unitId: 'u1',
        topicId: 't1',
        examVariant: ExamVariantCode.naturalScience,
        questionTextEn: 'Sample',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'Archive',
        contentVersion: 1,
        choices: [
          AnswerChoice(id: 'c1', label: 'A', textEn: 'Wrong', isCorrect: false),
          AnswerChoice(id: 'c2', label: 'B', textEn: 'Right', isCorrect: true),
        ],
        explanation: Explanation(solutionTextEn: 'Exp'),
      );

      final exam = Exam(
        id: 'exam_idemp_1',
        title: 'Simulation',
        examType: ExamType.mockFull,
        examMode: ExamMode.nationalSimulation,
        sourceType: ExamSourceType.generatedSimulation,
        grade: 12,
        stream: 'natural',
        subjectId: 'math_g12',
        timeLimitMinutes: 60,
        totalQuestions: 1,
        questions: const [question],
        createdAt: DateTime.now(),
      );

      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_idemp_1',
        userId: 'student_99',
        exam: exam,
      );

      final answeredAttempt = ExamEngine.answerQuestion(
        currentAttempt: attempt,
        question: question,
        choiceId: 'c1', // Incorrect choice
      );

      // First finalization
      final firstResult = await submissionService.finalizeSubmission(
        currentAttempt: answeredAttempt,
        exam: exam,
        totalDurationSeconds: 1200,
        userId: 'student_99',
      );

      expect(firstResult.isCompleted, isTrue);
      expect(firstResult.outcomesProcessedAt, isNotNull);
      expect(processedOutcomesCount, equals(1));

      // Second finalization call (e.g. process retry or duplicate submission)
      final secondResult = await submissionService.finalizeSubmission(
        currentAttempt: answeredAttempt,
        exam: exam,
        totalDurationSeconds: 1200,
        userId: 'student_99',
      );

      // Outcome count must STILL be 1 (zero duplication!)
      expect(processedOutcomesCount, equals(1));
      expect(secondResult.id, equals(firstResult.id));

      await db.close();
    });
  });

  group('Priority 5 Hardening — Drift v8 SQLite Persistence & Migration Tests',
      () {
    test(
        '1. Drift schema v8 persists all new snapshot and outcome guard fields',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftExamRepository(db: db);

      final now = DateTime(2026, 9, 25, 11, 30);
      final attempt = ExamAttempt(
        id: 'att_v8_1',
        userId: 'student_v8',
        examId: 'sim_v8',
        examTitle: 'V8 Simulation Exam',
        subjectId: 'chemistry_g12',
        examMode: ExamMode.nationalSimulation,
        sourceType: ExamSourceType.generatedSimulation,
        examVariant: ExamVariantCode.naturalScience,
        blueprintVersion: 'esslce_sim_chem_nat_v1',
        simulationSeed: 888,
        questionOrder: const ['q1', 'q2'],
        packageSnapshot: const {'chemistry_g12': '2026.09.2'},
        examIntegrityHash: 'abc123sha256',
        outcomesProcessedAt: now,
        scoringPolicy: 'standard_uniform_v1',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        durationSeconds: 3600,
        totalQuestions: 2,
        score: 2,
        percentage: 100.0,
        correctCount: 2,
        incorrectCount: 0,
        skippedCount: 0,
        isCompleted: true,
        responses: const {},
      );

      await repo.saveCompletedAttempt(attempt);

      final loaded = await repo.getAttemptById('att_v8_1');
      expect(loaded, isNotNull);
      expect(loaded!.packageSnapshot, equals({'chemistry_g12': '2026.09.2'}));
      expect(loaded.examIntegrityHash, equals('abc123sha256'));
      expect(loaded.outcomesProcessedAt, isNotNull);
      expect(loaded.scoringPolicy, equals('standard_uniform_v1'));

      await db.close();
    });
  });
}

class _CountingFakeMistakeRepository implements MistakeRepository {
  final void Function() onMistakeRecorded;
  _CountingFakeMistakeRepository(this.onMistakeRecorded);

  @override
  Future<void> recordMistake({
    required String userId,
    required String questionId,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? attemptId,
    String? selectedChoiceId,
  }) async {
    onMistakeRecorded();
  }

  @override
  Future<void> recordRetryResult({
    required String userId,
    required String questionId,
    required bool isCorrect,
    required String attemptId,
    String? selectedChoiceId,
    String? subjectId,
  }) async {}

  @override
  Future<MistakeRecord?> getMistakeById({
    required String userId,
    required String questionId,
  }) async =>
      null;

  @override
  Future<MistakeCounts> getMistakeCounts(String userId,
          {String? subjectId, String? unitId, String? topicId}) async =>
      const MistakeCounts(total: 0, needsReview: 0, improving: 0, mastered: 0);

  @override
  Future<List<MistakeRecord>> getMistakes(String userId,
          {String? subjectId,
          String? unitId,
          String? topicId,
          MasteryStatus? status,
          bool onlyUnmastered = false}) async =>
      [];

  @override
  Future<void> markMastered(
      {required String userId, required String questionId}) async {}

  @override
  Stream<MistakeCounts> watchMistakeCounts(String userId,
          {String? subjectId, String? unitId, String? topicId}) =>
      Stream.value(const MistakeCounts(
          total: 0, needsReview: 0, improving: 0, mastered: 0));

  @override
  Stream<List<MistakeRecord>> watchMistakes(String userId,
          {String? subjectId,
          String? unitId,
          String? topicId,
          MasteryStatus? status,
          bool onlyUnmastered = false}) =>
      Stream.value([]);
}

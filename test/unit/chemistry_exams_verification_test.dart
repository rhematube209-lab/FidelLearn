import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/exams/domain/services/exam_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repository;

  setUp(() async {
    repository = LocalContentRepository();
    await repository.initializeSeedData();
  });

  group('ESSLCE Chemistry Exam Integration Verification', () {
    test('Chemistry 2013 E.C. has exactly 80 recoverable questions', () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2013,
      );

      expect(questions.length, equals(80));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(80));
    });

    test(
        'Chemistry 2014 E.C. has exactly 70 recoverable questions (No fabricated Q71-Q80)',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2014,
      );

      // Must NOT fabricate missing questions 71-80
      expect(questions.length, isNot(equals(80)));
      expect(questions.length, equals(70));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(70));

      final qNumbers = questions.map((q) => q.questionNumber).toList();
      expect(qNumbers.contains(71), isFalse);
      expect(qNumbers.contains(80), isFalse);
    });

    test('Chemistry 2013 handles defective and special questions correctly',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2013,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      // Q5: Defective calculation item
      final q5 = qMap[5]!;
      expect(q5.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q5.isScorable, isFalse);
      expect(q5.isPracticeEligible, isFalse);
      expect(q5.choices.any((c) => c.isCorrect), isFalse);

      // Q23: Defective addition polymers item
      final q23 = qMap[23]!;
      expect(q23.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q23.isScorable, isFalse);
      expect(q23.isPracticeEligible, isFalse);

      // Q24: Multiple valid answers (B / D)
      final q24 = qMap[24]!;
      expect(q24.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      expect(q24.isScorable, isTrue);
      expect(q24.isPracticeEligible, isTrue);
      final q24Correct =
          q24.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q24Correct, equals({'B', 'D'}));

      // Q45: Intended answer (C intended)
      final q45 = qMap[45]!;
      expect(q45.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q45.isScorable, isTrue);
      expect(q45.isPracticeEligible, isTrue);
      expect(q45.correctChoice.label, equals('C'));

      // Q56: Multiple valid answers (B / C)
      final q56 = qMap[56]!;
      expect(q56.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      final q56Correct =
          q56.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q56Correct, equals({'B', 'C'}));

      // Q57, Q59, Q60: Defective items
      for (final qn in [57, 59, 60]) {
        final q = qMap[qn]!;
        expect(q.verificationStatus, equals(VerificationStatus.noValidOption));
        expect(q.isScorable, isFalse);
        expect(q.isPracticeEligible, isFalse);
      }

      // Q72: Image-dependent missing diagram
      final q72 = qMap[72]!;
      expect(q72.verificationStatus, equals(VerificationStatus.imageDependent));
      expect(q72.isScorable, isFalse);
      expect(q72.isPracticeEligible, isFalse);

      // Q75: Multiple valid answers (A / D)
      final q75 = qMap[75]!;
      expect(q75.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      final q75Correct =
          q75.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q75Correct, equals({'A', 'D'}));
    });

    test('Chemistry 2014 handles defective and special questions correctly',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2014,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      // Q15: Intended answer (B intended)
      final q15 = qMap[15]!;
      expect(q15.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q15.isScorable, isTrue);
      expect(q15.correctChoice.label, equals('B'));

      // Q23: Defective ground-state configuration of Cu
      final q23 = qMap[23]!;
      expect(q23.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q23.isScorable, isFalse);
      expect(q23.isPracticeEligible, isFalse);

      // Q27: Corrected source equation
      final q27 = qMap[27]!;
      expect(
          q27.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q27.isScorable, isTrue);
      expect(q27.correctChoice.label, equals('B'));

      // Q36: Defective conversion factor
      final q36 = qMap[36]!;
      expect(q36.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q36.isScorable, isFalse);
      expect(q36.isPracticeEligible, isFalse);

      // Q40: Intended/Best answer (D)
      final q40 = qMap[40]!;
      expect(q40.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q40.isScorable, isTrue);
      expect(q40.correctChoice.label, equals('D'));

      // Q46: Multiple valid answers (A / D)
      final q46 = qMap[46]!;
      expect(q46.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      final q46Correct =
          q46.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q46Correct, equals({'A', 'D'}));

      // Q65: Defective formula C4H9O2
      final q65 = qMap[65]!;
      expect(q65.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q65.isScorable, isFalse);
      expect(q65.isPracticeEligible, isFalse);

      // Q66: Multiple valid answers (A / D)
      final q66 = qMap[66]!;
      expect(q66.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      final q66Correct =
          q66.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q66Correct, equals({'A', 'D'}));

      // Q68: Intended/Best answer (A)
      final q68 = qMap[68]!;
      expect(q68.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q68.correctChoice.label, equals('A'));
    });

    test('Visual and diagram items are properly linked in 2013 and 2014',
        () async {
      final q13 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2013,
      );
      final q14 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2014,
      );

      final qMap13 = {for (var q in q13) q.questionNumber!: q};
      final qMap14 = {for (var q in q14) q.questionNumber!: q};

      expect(qMap13[22]!.diagramAsset, isNotNull);
      expect(qMap13[23]!.diagramAsset, isNotNull);

      expect(qMap14[3]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q03_heating_curve.png'));
      expect(qMap14[12]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q12_lewis_all.png'));
      expect(qMap14[26]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q26_coordinate_bonds.png'));
      expect(qMap14[70]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q70_sugars_all.png'));
    });

    test('Curriculum distribution spans Grades 9, 10, 11, and 12', () async {
      final allChem = await repository.getQuestions(
        subjectId: 'chemistry_g12',
      );

      final grades = allChem.map((q) => q.curriculumGrade).toSet();
      expect(grades, containsAll([9, 10, 11, 12]));

      // Check Grade 11 equilibrium specifically
      final eqQuestions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        unitId: 'chem_g11_u5',
      );
      expect(eqQuestions.isNotEmpty, isTrue);
      for (final q in eqQuestions) {
        expect(q.curriculumUnitId, equals('chem_g11_u5'));
      }
    });

    test('Custom Practice Builder filtering combinations work accurately',
        () async {
      // 1. Chemistry + Grade 11 + Chemical Equilibrium + 2013 + Medium
      final comb1 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 11,
        unitId: 'chem_g11_u5',
        examYear: 2013,
        difficulty: 'medium',
        practiceEligibleOnly: true,
      );
      expect(comb1.isNotEmpty, isTrue);
      for (final q in comb1) {
        expect(q.curriculumGrade, equals(11));
        expect(q.curriculumUnitId, equals('chem_g11_u5'));
        expect(q.examYear, equals(2013));
        expect(q.difficulty, equals('medium'));
        expect(q.isPracticeEligible, isTrue);
      }

      // 2. Chemistry + Grade 11 + Chemical Equilibrium + 2014
      final comb2 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 11,
        unitId: 'chem_g11_u5',
        examYear: 2014,
        practiceEligibleOnly: true,
      );
      expect(comb2.isNotEmpty, isTrue);
      for (final q in comb2) {
        expect(q.curriculumGrade, equals(11));
        expect(q.curriculumUnitId, equals('chem_g11_u5'));
        expect(q.examYear, equals(2014));
        expect(q.isPracticeEligible, isTrue);
      }

      // 3. Chemistry + All Years + All Difficulties
      final allQuestions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
      );
      expect(allQuestions.length, equals(150)); // 80 (2013) + 70 (2014)

      // 4. Practice eligible only excludes non-scorable defective questions
      final practiceQuestions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        practiceEligibleOnly: true,
      );
      // 74 in 2013 + 67 in 2014 = 141
      expect(practiceQuestions.length, equals(141));
      for (final q in practiceQuestions) {
        expect(q.isPracticeEligible, isTrue);
        expect(q.isScorable, isTrue);
      }
    });

    test(
        'Exam Engine scoring accurately scores multiple valid answers and skips non-scorable',
        () {
      // Create dummy questions matching exam conditions
      const qNormal = Question(
        id: 'test_norm',
        grade: 12,
        stream: 'natural',
        subjectId: 'chemistry_g12',
        unitId: 'chem_g11_u5',
        topicId: 'chem_t_g11_u5_equilibrium',
        examYear: 2013,
        questionNumber: 1,
        questionTextEn: 'Normal question',
        difficulty: 'easy',
        verificationStatus: VerificationStatus.verified,
        isScorable: true,
        sourceName: 'test',
        contentVersion: 1,
        choices: const [
          AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
          AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
        ],
        explanation: const Explanation(solutionTextEn: 'Explanation'),
      );

      const qMulti = Question(
        id: 'test_multi',
        grade: 12,
        stream: 'natural',
        subjectId: 'chemistry_g12',
        unitId: 'chem_g12_u4',
        topicId: 'chem_t_g12_u4_polymers',
        examYear: 2013,
        questionNumber: 24,
        questionTextEn: 'Multiple valid options question',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.multipleValidAnswers,
        isScorable: true,
        sourceName: 'test',
        contentVersion: 1,
        choices: const [
          AnswerChoice(id: 'c3', label: 'A', textEn: 'A', isCorrect: false),
          AnswerChoice(id: 'c4', label: 'B', textEn: 'B', isCorrect: true),
          AnswerChoice(id: 'c5', label: 'C', textEn: 'C', isCorrect: false),
          AnswerChoice(id: 'c6', label: 'D', textEn: 'D', isCorrect: true),
        ],
        explanation: const Explanation(solutionTextEn: 'Explanation'),
      );

      const qDefective = Question(
        id: 'test_defective',
        grade: 12,
        stream: 'natural',
        subjectId: 'chemistry_g12',
        unitId: 'chem_g11_u5',
        topicId: 'chem_t_g11_u5_equilibrium',
        examYear: 2013,
        questionNumber: 5,
        questionTextEn: 'Defective question',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.noValidOption,
        isScorable: false,
        sourceName: 'test',
        contentVersion: 1,
        choices: const [
          AnswerChoice(id: 'c7', label: 'A', textEn: 'A', isCorrect: false),
          AnswerChoice(id: 'c8', label: 'B', textEn: 'B', isCorrect: false),
        ],
        explanation: const Explanation(solutionTextEn: 'Explanation'),
      );

      final questions = [qNormal, qMulti, qDefective];
      final exam = Exam(
        id: 'exam_test',
        title: 'Chemistry Test',
        examType: ExamType.practice,
        grade: 12,
        stream: 'natural',
        subjectId: 'chemistry_g12',
        timeLimitMinutes: 0,
        totalQuestions: 3,
        questions: questions,
        createdAt: DateTime.now(),
      );

      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_1',
        userId: 'user_test',
        exam: exam,
      );

      // Answer normal correctly with A
      var a1 = ExamEngine.answerQuestion(
        currentAttempt: attempt,
        question: qNormal,
        choiceId: 'c1',
      );
      expect(a1.responses['test_norm']!.isCorrect, isTrue);

      // Answer multi correctly with D (second valid answer)
      var a2 = ExamEngine.answerQuestion(
        currentAttempt: a1,
        question: qMulti,
        choiceId: 'c6',
      );
      expect(a2.responses['test_multi']!.isCorrect, isTrue);

      // Answer defective with A
      var a3 = ExamEngine.answerQuestion(
        currentAttempt: a2,
        question: qDefective,
        choiceId: 'c7',
      );
      expect(a3.responses['test_defective']!.isCorrect, isFalse);

      final finalAttempt = ExamEngine.submitAttempt(
        currentAttempt: a3,
        questions: questions,
        totalDurationSeconds: 120,
      );

      // Out of 2 scorable questions, 2 are correct = 100%
      // Non-scorable defective question was not counted against the user in scorable count
      expect(finalAttempt.score, equals(2));
      expect(finalAttempt.correctCount, equals(2));
      expect(finalAttempt.incorrectCount, equals(0));
      expect(finalAttempt.percentage, equals(100.0));
    });
  });
}

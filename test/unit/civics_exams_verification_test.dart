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

  group('Civics & Ethical Education 2013/14 & 2014/15 Integration Verification',
      () {
    // Expected answer key for 2013 (100 questions) from PDF Page 41
    const expectedKey2013 = [
      'B', 'C', 'C', 'A', 'B', 'B', 'D', 'B', 'C', 'A', // 1-10
      'C', 'C', 'C', 'A', 'A', 'C', 'A', 'C', 'B', 'C', // 11-20
      'B', 'A', 'B', 'B', 'C', 'B', 'D', 'B', 'C', 'A', // 21-30
      'D', 'B', 'B', 'D', 'C', 'B', 'C', 'D', 'A', 'D', // 31-40
      'D', 'C', 'A', 'B', 'C', 'D', 'B', 'C', 'D', 'A', // 41-50
      'B', 'A', 'D', 'A', 'B', 'D', 'A', 'C', 'B', 'D', // 51-60
      'B', 'A', 'A', 'B', 'A', 'D', 'D', 'C', 'A', 'D', // 61-70
      'D', 'B', 'A', 'C', 'B', 'A', 'D', 'A', 'B', 'A', // 71-80
      'A', 'D', 'D', 'A', 'D', 'C', 'B', 'D', 'D', 'C', // 81-90
      'C', 'A', 'D', 'B', 'A', 'C', 'D', 'A', 'C', 'B', // 91-100
    ];

    // Expected answer key for 2014 (100 questions) from PDF Page 49
    const expectedKey2014 = [
      'B', 'C', 'A', 'A', 'B', 'B', 'A', 'B', 'D', 'B', // 1-10
      'A', 'D', 'A', 'B', 'C', 'A', 'B', 'A', 'B', 'D', // 11-20
      'C', 'D', 'A', 'C', 'B', 'D', 'A', 'B', 'A', 'C', // 21-30
      'A', 'B', 'D', 'B', 'C', 'C', 'D', 'A', 'B', 'D', // 31-40
      'A', 'D', 'B', 'A', 'B', 'A', 'C', 'A', 'D', 'C', // 41-50
      'B', 'B', 'A', 'B', 'D', 'A', 'B', 'D', 'B', 'C', // 51-60
      'C', 'A', 'B', 'D', 'A', 'C', 'D', 'D', 'C', 'B', // 61-70
      'B', 'C', 'D', 'B', 'A', 'B', 'D', 'C', 'B', 'C', // 71-80
      'D', 'A', 'D', 'B', 'D', 'B', 'D', 'A', 'B', 'D', // 81-90
      'A', 'B', 'A', 'C', 'B', 'A', 'A', 'A', 'A', 'C', // 91-100
    ];

    // Expected answer key for 2015 (100 questions) from PDF Page 44
    const expectedKey2015 = [
      'A', 'A', 'B', 'B', 'A', 'B', 'C', 'A', 'C', 'B', // 1-10
      'D', 'A', 'C', 'C', 'D', 'C', 'A', 'B', 'D', 'D', // 11-20
      'A', 'C', 'C', 'A', 'C', 'D', 'B', 'D', 'A', 'A', // 21-30
      'D', 'B', 'D', 'B', 'D', 'D', 'A', 'A', 'D', 'B', // 31-40
      'B', 'C', 'A', 'B', 'D', 'B', 'D', 'C', 'B', 'B', // 41-50
      'C', 'A', 'D', 'C', 'D', 'D', 'D', 'B', 'C', 'B', // 51-60
      'B', 'C', 'C', 'A', 'A', 'D', 'C', 'A', 'C', 'B', // 61-70
      'D', 'A', 'C', 'A', 'B', 'C', 'B', 'A', 'C', 'B', // 71-80
      'A', 'D', 'D', 'C', 'D', 'A', 'D', 'A', 'C', 'D', // 81-90
      'C', 'B', 'A', 'C', 'B', 'D', 'C', 'B', 'C', 'D', // 91-100
    ];

    test('Civics 2013 E.C. has exactly 100 recoverable questions', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );

      expect(questions.length, equals(100));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(100));

      final qNumbers = questions.map((q) => q.questionNumber).toSet();
      for (int i = 1; i <= 100; i++) {
        expect(qNumbers.contains(i), isTrue,
            reason: 'Question $i must exist in 2013');
      }
    });

    test('Civics 2014 E.C. has exactly 100 recoverable questions', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
      );

      expect(questions.length, equals(100));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(100));

      final qNumbers = questions.map((q) => q.questionNumber).toSet();
      for (int i = 1; i <= 100; i++) {
        expect(qNumbers.contains(i), isTrue,
            reason: 'Question $i must exist in 2014');
      }
    });

    test('Civics 2015 E.C. has exactly 100 recoverable questions', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );

      expect(questions.length, equals(100));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(100));

      final qNumbers = questions.map((q) => q.questionNumber).toSet();
      for (int i = 1; i <= 100; i++) {
        expect(qNumbers.contains(i), isTrue,
            reason: 'Question $i must exist in 2015');
      }
    });

    test('Civics 2013 100-item answer key matches PDF Page 41 table', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      for (int i = 1; i <= 100; i++) {
        final q = qMap[i]!;
        final correctLabels =
            q.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
        expect(correctLabels.contains(expectedKey2013[i - 1]), isTrue,
            reason:
                'Civics 2013 Q$i expected to have correct answer ${expectedKey2013[i - 1]}');
      }
    });

    test('Civics 2014 100-item answer key matches PDF Page 49 table', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      for (int i = 1; i <= 100; i++) {
        final q = qMap[i]!;
        final correctLabels =
            q.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
        expect(correctLabels.contains(expectedKey2014[i - 1]), isTrue,
            reason:
                'Civics 2014 Q$i expected to have correct answer ${expectedKey2014[i - 1]}');
      }
    });

    test('Civics 2015 100-item answer key matches PDF Page 44 table', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      for (int i = 1; i <= 100; i++) {
        final q = qMap[i]!;
        final correctLabels =
            q.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
        expect(correctLabels.contains(expectedKey2015[i - 1]), isTrue,
            reason:
                'Civics 2015 Q$i expected to have correct answer ${expectedKey2015[i - 1]}');
      }
    });

    test('Civics 2013 flagged questions, statuses, and review notes', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );
      final qMap = {for (var q in questions) q.questionNumber!: q};

      const flagged2013 = [6, 39, 54, 61, 66, 82, 85, 86];

      for (final qn in flagged2013) {
        final q = qMap[qn]!;
        expect(q.reviewNote, isNotNull,
            reason: '2013 Q$qn must have review note');
        expect(q.reviewNote!.isNotEmpty, isTrue,
            reason: '2013 Q$qn review note must not be empty');
      }

      // Q54: Defective amendment procedure item (FDRE Const Arts 104-105)
      final q54 = qMap[54]!;
      expect(q54.isScorable, isFalse);
      expect(q54.isPracticeEligible, isFalse);

      // Q61: Defective separation of state and religion item (FDRE Const Art 11)
      final q61 = qMap[61]!;
      expect(q61.isScorable, isFalse);
      expect(q61.isPracticeEligible, isFalse);

      // Other flagged items remain scorable and practice eligible
      for (final qn in [6, 39, 66, 82, 85, 86]) {
        final q = qMap[qn]!;
        expect(q.isScorable, isTrue);
        expect(q.isPracticeEligible, isTrue);
      }
    });

    test('Civics 2014 flagged questions, statuses, and review notes', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
      );
      final qMap = {for (var q in questions) q.questionNumber!: q};

      const flagged2014 = [2, 5, 20, 25, 30, 39, 43, 56, 66, 68, 84, 91];

      for (final qn in flagged2014) {
        final q = qMap[qn]!;
        expect(q.reviewNote, isNotNull,
            reason: '2014 Q$qn must have review note');
        expect(q.reviewNote!.isNotEmpty, isTrue,
            reason: '2014 Q$qn review note must not be empty');
      }

      // Q30: Defective corrupted question/choices on who should pay tax
      final q30 = qMap[30]!;
      expect(q30.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q30.isScorable, isFalse);
      expect(q30.isPracticeEligible, isFalse);

      // Q56: Underdetermined inference on Abebe's family budget
      final q56 = qMap[56]!;
      expect(
          q56.verificationStatus, equals(VerificationStatus.underdetermined));
      expect(q56.isScorable, isFalse);
      expect(q56.isPracticeEligible, isFalse);

      // Q25: Multiple valid answers (A and B both supportable)
      final q25 = qMap[25]!;
      expect(q25.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      expect(q25.isScorable, isTrue);
      expect(q25.isPracticeEligible, isTrue);
      final q25Correct =
          q25.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q25Correct, containsAll({'A', 'B'}));

      // Q68: Multiple valid answers (A, B, and D all contain historical truth)
      final q68 = qMap[68]!;
      expect(q68.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      expect(q68.isScorable, isTrue);
      expect(q68.isPracticeEligible, isTrue);
      final q68Correct =
          q68.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q68Correct, containsAll({'A', 'B', 'D'}));
    });

    test('Civics 2015 flagged questions, statuses, and review notes', () async {
      final questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );
      final qMap = {for (var q in questions) q.questionNumber!: q};

      const flagged2015 = [
        3,
        4,
        6,
        8,
        13,
        22,
        40,
        43,
        44,
        51,
        58,
        62,
        66,
        68,
        82,
        83,
        84,
        86,
        87,
        90,
        97
      ];

      for (final qn in flagged2015) {
        final q = qMap[qn]!;
        expect(q.reviewNote, isNotNull,
            reason: '2015 Q$qn must have review note');
        expect(q.reviewNote!.isNotEmpty, isTrue,
            reason: '2015 Q$qn review note must not be empty');
        expect(q.verificationStatus, equals(VerificationStatus.bestAnswer));
        expect(q.isScorable, isTrue);
        expect(q.isPracticeEligible, isTrue);
      }

      // Check unflagged questions have verified status and null review notes
      final unflagged2015 = List.generate(100, (i) => i + 1)
          .where((qn) => !flagged2015.contains(qn));
      for (final qn in unflagged2015) {
        final q = qMap[qn]!;
        expect(q.reviewNote, isNull);
        expect(q.verificationStatus, equals(VerificationStatus.verified));
        expect(q.isScorable, isTrue);
        expect(q.isPracticeEligible, isTrue);
      }
    });

    test('All 300 questions preserve study-guide provenance and metadata',
        () async {
      final q2013 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );
      final q2014 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
      );
      final q2015 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );

      final allQuestions = [...q2013, ...q2014, ...q2015];
      expect(allQuestions.length, equals(300));

      for (final q in allQuestions) {
        expect(q.officialAnswerKeyAvailable, isFalse,
            reason: '${q.id} must declare officialAnswerKeyAvailable as false');
        expect(q.answerKeySource, equals('curriculum_aligned_study_guide'),
            reason:
                '${q.id} must declare answerKeySource as curriculum_aligned_study_guide');
        expect(q.stream, equals('common'));
        expect(q.choices.length, equals(4));
        expect(q.explanation.solutionTextEn.isNotEmpty, isTrue);
      }
    });

    test(
        'Civics 2013, 2014, and 2015 curriculum grade distributions match spec',
        () async {
      final q2013 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );
      final q2014 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
      );
      final q2015 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );

      // 2013: Grade 9 (36), Grade 10 (42), Grade 11 (12), Grade 12 (10)
      final grades2013 = <int, int>{};
      for (final q in q2013) {
        grades2013[q.curriculumGrade!] =
            (grades2013[q.curriculumGrade!] ?? 0) + 1;
      }
      expect(grades2013[9], equals(36));
      expect(grades2013[10], equals(42));
      expect(grades2013[11], equals(12));
      expect(grades2013[12], equals(10));

      // 2014: Grade 9 (46), Grade 10 (32), Grade 11 (9), Grade 12 (13)
      final grades2014 = <int, int>{};
      for (final q in q2014) {
        grades2014[q.curriculumGrade!] =
            (grades2014[q.curriculumGrade!] ?? 0) + 1;
      }
      expect(grades2014[9], equals(46));
      expect(grades2014[10], equals(32));
      expect(grades2014[11], equals(9));
      expect(grades2014[12], equals(13));

      // 2015: Grade 9 (37), Grade 10 (48), Grade 11 (5), Grade 12 (10)
      final grades2015 = <int, int>{};
      for (final q in q2015) {
        grades2015[q.curriculumGrade!] =
            (grades2015[q.curriculumGrade!] ?? 0) + 1;
      }
      expect(grades2015[9], equals(37));
      expect(grades2015[10], equals(48));
      expect(grades2015[11], equals(5));
      expect(grades2015[12], equals(10));
    });

    test('Civics 2013, 2014, and 2015 difficulty distributions match spec',
        () async {
      final q2013 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );
      final q2014 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
      );
      final q2015 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );

      // 2013: Easy (49), Medium (40), Hard (11)
      final diff2013 = <String, int>{};
      for (final q in q2013) {
        diff2013[q.difficulty] = (diff2013[q.difficulty] ?? 0) + 1;
      }
      expect(diff2013['easy'], equals(49));
      expect(diff2013['medium'], equals(40));
      expect(diff2013['hard'], equals(11));

      // 2014: Easy (52), Medium (36), Hard (12)
      final diff2014 = <String, int>{};
      for (final q in q2014) {
        diff2014[q.difficulty] = (diff2014[q.difficulty] ?? 0) + 1;
      }
      expect(diff2014['easy'], equals(52));
      expect(diff2014['medium'], equals(36));
      expect(diff2014['hard'], equals(12));

      // 2015: Easy (54), Medium (33), Hard (13)
      final diff2015 = <String, int>{};
      for (final q in q2015) {
        diff2015[q.difficulty] = (diff2015[q.difficulty] ?? 0) + 1;
      }
      expect(diff2015['easy'], equals(54));
      expect(diff2015['medium'], equals(33));
      expect(diff2015['hard'], equals(13));
    });

    test('Subject & Units Resolution for Civics', () async {
      final subject12 =
          LocalContentRepository.resolveDefaultSubject('civics_g12');
      expect(subject12.code, equals('CIV12'));
      expect(subject12.stream, equals('common'));
      expect(subject12.nameEn, equals('Civics and Ethical Education'));
      expect(subject12.nameAm, equals('ስነ-ዜጋና ስነ-ምግባር'));

      final allSubjects = LocalContentRepository.getAllDefaultSubjects();
      final civicsFound = allSubjects
          .where((s) => s.code.startsWith('CIV') || s.id.contains('civics'));
      expect(civicsFound.isNotEmpty, isTrue);

      final unitsCivics = LocalContentRepository.getDefaultUnits('civics_g12');
      expect(unitsCivics.length, equals(29));
      expect(unitsCivics.where((u) => u.id.startsWith('civ_g9_')).length,
          equals(8));
      expect(unitsCivics.where((u) => u.id.startsWith('civ_g10_')).length,
          equals(7));
      expect(unitsCivics.where((u) => u.id.startsWith('civ_g11_')).length,
          equals(4));
      expect(unitsCivics.where((u) => u.id.startsWith('civ_g12_')).length,
          equals(10));
    });

    test('Scoring safety in ExamEngine for Civics with defective items',
        () async {
      final q2013 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
      );

      final exam = Exam(
        id: 'civics_2013_full_test',
        title: 'Civics 2013 Full Exam',
        examType: ExamType.mockFull,
        grade: 12,
        stream: 'common',
        subjectId: 'civics_g12',
        timeLimitMinutes: 120,
        totalQuestions: 100,
        questions: q2013,
        createdAt: DateTime.now(),
      );

      var attempt = ExamEngine.startAttempt(
        attemptId: 'att_civics_1',
        userId: 'student_1',
        exam: exam,
      );

      // Answer all 100 questions using the expected answers
      for (final q in q2013) {
        final correctChoice = q.choices.firstWhere(
          (c) => c.isCorrect,
          orElse: () => q.choices.first,
        );
        attempt = ExamEngine.answerQuestion(
          currentAttempt: attempt,
          question: q,
          choiceId: correctChoice.id,
        );
      }

      final submitted = ExamEngine.submitAttempt(
        currentAttempt: attempt,
        questions: q2013,
        totalDurationSeconds: 3600,
      );

      // Exactly 98 scorable questions (Q54 and Q61 excluded from denominator)
      expect(submitted.score, equals(98));
      expect(submitted.correctCount, equals(98));
      expect(submitted.incorrectCount, equals(0));
      expect(submitted.percentage, equals(100.0));
    });

    test('2014 Q25 and Q68 multiple-valid-answers behave correctly in engine',
        () async {
      final q25 = await repository.getQuestionById('q_civics_2014_025');
      final q68 = await repository.getQuestionById('q_civics_2014_068');

      expect(q25, isNotNull);
      expect(q68, isNotNull);

      final choice25A = q25!.choices.firstWhere((c) => c.label == 'A');
      final choice25B = q25.choices.firstWhere((c) => c.label == 'B');
      final choice25C = q25.choices.firstWhere((c) => c.label == 'C');

      final choice68A = q68!.choices.firstWhere((c) => c.label == 'A');
      final choice68B = q68.choices.firstWhere((c) => c.label == 'B');
      final choice68C = q68.choices.firstWhere((c) => c.label == 'C');
      final choice68D = q68.choices.firstWhere((c) => c.label == 'D');

      final exam = Exam(
        id: 'civics_multi_test',
        title: 'Multi Choice Test',
        examType: ExamType.practice,
        grade: 12,
        stream: 'common',
        subjectId: 'civics_g12',
        timeLimitMinutes: 10,
        totalQuestions: 2,
        questions: [q25, q68],
        createdAt: DateTime.now(),
      );

      // Attempt 1: answering with A and B
      final att1 = ExamEngine.startAttempt(
        attemptId: 'att_multi_1',
        userId: 'student_1',
        exam: exam,
      );
      final att1Q25 = ExamEngine.answerQuestion(
        currentAttempt: att1,
        question: q25,
        choiceId: choice25A.id,
      );
      final att1Q68 = ExamEngine.answerQuestion(
        currentAttempt: att1Q25,
        question: q68,
        choiceId: choice68A.id,
      );
      expect(att1Q68.responses[q25.id]!.isCorrect, isTrue);
      expect(att1Q68.responses[q68.id]!.isCorrect, isTrue);

      // Attempt 2: answering with B and B
      final att2 = ExamEngine.startAttempt(
        attemptId: 'att_multi_2',
        userId: 'student_1',
        exam: exam,
      );
      final att2Q25 = ExamEngine.answerQuestion(
        currentAttempt: att2,
        question: q25,
        choiceId: choice25B.id,
      );
      final att2Q68 = ExamEngine.answerQuestion(
        currentAttempt: att2Q25,
        question: q68,
        choiceId: choice68B.id,
      );
      expect(att2Q68.responses[q25.id]!.isCorrect, isTrue);
      expect(att2Q68.responses[q68.id]!.isCorrect, isTrue);

      // Attempt 2b: answering Q68 with D
      final att2b = ExamEngine.answerQuestion(
        currentAttempt: att2Q25,
        question: q68,
        choiceId: choice68D.id,
      );
      expect(att2b.responses[q68.id]!.isCorrect, isTrue);

      // Attempt 3: answering with C (incorrect for both)
      final att3 = ExamEngine.startAttempt(
        attemptId: 'att_multi_3',
        userId: 'student_1',
        exam: exam,
      );
      final att3Q25 = ExamEngine.answerQuestion(
        currentAttempt: att3,
        question: q25,
        choiceId: choice25C.id,
      );
      final att3Q68 = ExamEngine.answerQuestion(
        currentAttempt: att3Q25,
        question: q68,
        choiceId: choice68C.id,
      );
      expect(att3Q68.responses[q25.id]!.isCorrect, isFalse);
      expect(att3Q68.responses[q68.id]!.isCorrect, isFalse);
    });

    test('Scoring in ExamEngine for Civics 2015 full mock exam', () async {
      final q2015 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
      );

      final exam = Exam(
        id: 'civics_2015_full_test',
        title: 'Civics 2015 Full Exam',
        examType: ExamType.mockFull,
        grade: 12,
        stream: 'common',
        subjectId: 'civics_g12',
        timeLimitMinutes: 120,
        totalQuestions: 100,
        questions: q2015,
        createdAt: DateTime.now(),
      );

      var attempt = ExamEngine.startAttempt(
        attemptId: 'att_civics_2015_1',
        userId: 'student_1',
        exam: exam,
      );

      // Answer all 100 questions using the expected answers
      for (final q in q2015) {
        final correctChoice = q.choices.firstWhere(
          (c) => c.isCorrect,
          orElse: () => q.choices.first,
        );
        attempt = ExamEngine.answerQuestion(
          currentAttempt: attempt,
          question: q,
          choiceId: correctChoice.id,
        );
      }

      final submitted = ExamEngine.submitAttempt(
        currentAttempt: attempt,
        questions: q2015,
        totalDurationSeconds: 3600,
      );

      // All 100 questions are scorable and correctly answered
      expect(submitted.score, equals(100));
      expect(submitted.correctCount, equals(100));
      expect(submitted.incorrectCount, equals(0));
      expect(submitted.percentage, equals(100.0));
    });

    test('Custom Practice Builder filtering by Grade and Practice Eligibility',
        () async {
      // Filter for Grade 9 Civics questions
      final g9Questions = await repository.getQuestions(
        subjectId: 'civics_g12',
        grade: 9,
      );
      // 36 from 2013 + 46 from 2014 + 37 from 2015 = 119 Grade 9 Civics questions
      expect(g9Questions.length, equals(119));
      for (final q in g9Questions) {
        expect(q.curriculumGrade, equals(9));
      }

      // Filter for practice eligible questions in 2013
      final eligible2013 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2013,
        practiceEligibleOnly: true,
      );
      // Exactly 98 eligible questions (Q54 and Q61 excluded)
      expect(eligible2013.length, equals(98));
      final qNums2013 = eligible2013.map((q) => q.questionNumber).toSet();
      expect(qNums2013.contains(54), isFalse);
      expect(qNums2013.contains(61), isFalse);

      // Filter for practice eligible questions in 2014
      final eligible2014 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2014,
        practiceEligibleOnly: true,
      );
      // Exactly 98 eligible questions (Q30 and Q56 excluded)
      expect(eligible2014.length, equals(98));
      final qNums2014 = eligible2014.map((q) => q.questionNumber).toSet();
      expect(qNums2014.contains(30), isFalse);
      expect(qNums2014.contains(56), isFalse);

      // Filter for practice eligible questions in 2015
      final eligible2015 = await repository.getQuestions(
        subjectId: 'civics_g12',
        examYear: 2015,
        practiceEligibleOnly: true,
      );
      // All 100 questions eligible
      expect(eligible2015.length, equals(100));
    });
  });
}

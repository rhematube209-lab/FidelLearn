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
    test('VerificationStatus serialization regression tests', () {
      expect(VerificationStatus.fromString('best_answer'),
          equals(VerificationStatus.bestAnswer));
      expect(VerificationStatus.fromString('bestanswer'),
          equals(VerificationStatus.bestAnswer));
      expect(VerificationStatus.bestAnswer.toDbString(), equals('best_answer'));

      expect(VerificationStatus.fromString('underdetermined'),
          equals(VerificationStatus.underdetermined));
      expect(VerificationStatus.underdetermined.toDbString(),
          equals('underdetermined'));

      // Check existing statuses continue to deserialize correctly
      expect(VerificationStatus.fromString('verified'),
          equals(VerificationStatus.verified));
      expect(VerificationStatus.fromString('intended_answer'),
          equals(VerificationStatus.intendedAnswer));
      expect(VerificationStatus.fromString('no_valid_option'),
          equals(VerificationStatus.noValidOption));
      expect(VerificationStatus.fromString('image_dependent'),
          equals(VerificationStatus.imageDependent));
      expect(VerificationStatus.fromString('corrected_source'),
          equals(VerificationStatus.correctedSource));
      expect(VerificationStatus.fromString('multiple_valid_answers'),
          equals(VerificationStatus.multipleValidAnswers));
    });

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

    test(
        'Chemistry 2015 E.C. has exactly 78 recoverable questions (No fabricated Q79-Q80)',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2015,
      );

      // Header states 80, but archive has 78; Q79 and Q80 must NOT be created
      expect(questions.length, equals(78));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(78));

      final qNumbers = questions.map((q) => q.questionNumber).toList();
      expect(qNumbers.contains(78), isTrue);
      expect(qNumbers.contains(79), isFalse);
      expect(qNumbers.contains(80), isFalse);
    });

    test('Chemistry 2016 E.C. has exactly 80 recoverable questions', () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2016,
      );

      expect(questions.length, equals(80));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(80));
    });

    test(
        'Chemistry 2017 E.C. has exactly 78 recoverable questions (No fabricated Q79-Q80)',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2017,
      );

      // Header states 80, but archive has 78; Q79 and Q80 must NOT be created
      expect(questions.length, equals(78));
      expect(questions.first.questionNumber, equals(1));
      expect(questions.last.questionNumber, equals(78));

      final qNumbers = questions.map((q) => q.questionNumber).toList();
      expect(qNumbers.contains(78), isTrue);
      expect(qNumbers.contains(79), isFalse);
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
    });

    test('Chemistry 2015 handles special questions and answer states correctly',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2015,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      // Q18: Intended answer A with review note
      final q18 = qMap[18]!;
      expect(q18.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q18.correctChoice.label, equals('A'));
      expect(q18.isScorable, isTrue);
      expect(q18.reviewNote, contains('Option A is the intended mechanism'));

      // Q23: Corrected source with chlorine-35 repair note
      final q23 = qMap[23]!;
      expect(
          q23.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q23.correctChoice.label, equals('C'));
      expect(q23.isScorable, isTrue);
      expect(q23.reviewNote, contains('chlorine-35'));

      // Q64: Best answer A with imperfectly worded note
      final q64 = qMap[64]!;
      expect(q64.verificationStatus, equals(VerificationStatus.bestAnswer));
      expect(q64.correctChoice.label, equals('A'));
      expect(q64.isScorable, isTrue);
      expect(q64.reviewNote, contains('molecular geometry'));

      // Q70: Intended answer C with acid displacement note
      final q70 = qMap[70]!;
      expect(q70.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q70.correctChoice.label, equals('C'));
      expect(q70.isScorable, isTrue);
      expect(q70.reviewNote, contains('Formula defect in the source'));

      // Q75: Corrected source with restored fractions
      final q75 = qMap[75]!;
      expect(
          q75.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q75.correctChoice.label, equals('D'));
      expect(q75.isScorable, isTrue);
      expect(q75.reviewNote, contains('fraction formatting'));

      // Q78: Verified answer C
      final q78 = qMap[78]!;
      expect(q78.verificationStatus, equals(VerificationStatus.verified));
      expect(q78.correctChoice.label, equals('C'));
      expect(q78.isScorable, isTrue);
    });

    test(
        'Chemistry 2016 handles defective and special questions with scoring safety',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2016,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      // Q8: Image-dependent with missing option visuals (not invented)
      final q8 = qMap[8]!;
      expect(q8.verificationStatus, equals(VerificationStatus.imageDependent));
      expect(q8.isScorable, isFalse);
      expect(q8.isPracticeEligible, isFalse);
      expect(q8.reviewNote, contains('lacks visual options'));

      // Q19: No valid option (molecular orbital configuration)
      final q19 = qMap[19]!;
      expect(q19.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q19.isScorable, isFalse);
      expect(q19.isPracticeEligible, isFalse);
      expect(q19.choices.any((c) => c.isCorrect), isFalse);

      // Q41: Corrected source (rate determining step mechanism)
      final q41 = qMap[41]!;
      expect(
          q41.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q41.correctChoice.label, equals('D'));
      expect(q41.isScorable, isTrue);

      // Q42: No valid option (Kc = 0.08 not in choices)
      final q42 = qMap[42]!;
      expect(q42.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q42.isScorable, isFalse);
      expect(q42.isPracticeEligible, isFalse);

      // Q47: No valid option (electromagnetic radiation properties)
      final q47 = qMap[47]!;
      expect(q47.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q47.isScorable, isFalse);
      expect(q47.isPracticeEligible, isFalse);

      // Q53: Underdetermined (unidentified plant/leaf extract)
      final q53 = qMap[53]!;
      expect(
          q53.verificationStatus, equals(VerificationStatus.underdetermined));
      expect(q53.isScorable, isFalse);
      expect(q53.isPracticeEligible, isFalse);

      // Q55: No valid option (pH = 5 not in choices)
      final q55 = qMap[55]!;
      expect(q55.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q55.isScorable, isFalse);
      expect(q55.isPracticeEligible, isFalse);

      // Q74: Intended answer C (nitrogen cycle sequence)
      final q74 = qMap[74]!;
      expect(q74.verificationStatus, equals(VerificationStatus.intendedAnswer));
      expect(q74.correctChoice.label, equals('C'));
      expect(q74.isScorable, isTrue);

      // Q78: No valid option (scientific notation inconsistent)
      final q78 = qMap[78]!;
      expect(q78.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q78.isScorable, isFalse);
      expect(q78.isPracticeEligible, isFalse);

      // Q80: Verified answer B
      final q80 = qMap[80]!;
      expect(q80.verificationStatus, equals(VerificationStatus.verified));
      expect(q80.correctChoice.label, equals('B'));
      expect(q80.isScorable, isTrue);
      expect(q80.isPracticeEligible, isTrue);
    });

    test(
        'Chemistry 2017 handles defective and special questions with scoring safety',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2017,
      );

      final qMap = {for (var q in questions) q.questionNumber!: q};

      // Q1: Verified B
      final q1 = qMap[1]!;
      expect(q1.verificationStatus, equals(VerificationStatus.verified));
      expect(q1.correctChoice.label, equals('B'));
      expect(q1.isScorable, isTrue);

      // Q6: Corrected source D with MO review note
      final q6 = qMap[6]!;
      expect(q6.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q6.correctChoice.label, equals('D'));
      expect(q6.isScorable, isTrue);
      expect(q6.isPracticeEligible, isTrue);
      expect(q6.reviewNote, contains('electron counting'));

      // Q25: Corrected source A with Le Chatelier review note
      final q25 = qMap[25]!;
      expect(
          q25.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q25.correctChoice.label, equals('A'));
      expect(q25.isScorable, isTrue);
      expect(q25.isPracticeEligible, isTrue);
      expect(q25.reviewNote, contains('Le Chatelier'));

      // Q50: Multiple valid answers (A / C)
      final q50 = qMap[50]!;
      expect(q50.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));
      expect(q50.isScorable, isTrue);
      expect(q50.isPracticeEligible, isTrue);
      final q50Correct =
          q50.choices.where((c) => c.isCorrect).map((c) => c.label).toSet();
      expect(q50Correct, equals({'A', 'C'}));
      expect(q50.reviewNote, contains('Non-unique item'));

      // Q57: No valid option (unbalanced Kp calculation)
      final q57 = qMap[57]!;
      expect(q57.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q57.isScorable, isFalse);
      expect(q57.isPracticeEligible, isFalse);
      expect(q57.choices.any((c) => c.isCorrect), isFalse);
      expect(q57.reviewNote, contains('stated Kp value is 1.56'));

      // Q59: Corrected source D with stem defect note
      final q59 = qMap[59]!;
      expect(
          q59.verificationStatus, equals(VerificationStatus.correctedSource));
      expect(q59.correctChoice.label, equals('D'));
      expect(q59.isScorable, isTrue);
      expect(q59.isPracticeEligible, isTrue);
      expect(q59.reviewNote, contains('Stem defect'));

      // Q63: No valid option (unbalanced organic reaction atom economy)
      final q63 = qMap[63]!;
      expect(q63.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q63.isScorable, isFalse);
      expect(q63.isPracticeEligible, isFalse);
      expect(q63.choices.any((c) => c.isCorrect), isFalse);
      expect(
          q63.reviewNote, contains('printed organic reaction is not balanced'));

      // Q76: No valid option (dicarboxylic acid structure vs monocarboxylic choices)
      final q76 = qMap[76]!;
      expect(q76.verificationStatus, equals(VerificationStatus.noValidOption));
      expect(q76.isScorable, isFalse);
      expect(q76.isPracticeEligible, isFalse);
      expect(q76.choices.any((c) => c.isCorrect), isFalse);
      expect(q76.reviewNote, contains('dicarboxylic acid'));

      // Q78: Verified C
      final q78 = qMap[78]!;
      expect(q78.verificationStatus, equals(VerificationStatus.verified));
      expect(q78.correctChoice.label, equals('C'));
      expect(q78.isScorable, isTrue);
      expect(q78.isPracticeEligible, isTrue);
    });

    test('Chemistry 2017 complete answer key verification against official key',
        () async {
      final questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2017,
      );

      const expectedKey = {
        1: 'B',
        2: 'D',
        3: 'C',
        4: 'D',
        5: 'A',
        6: 'D',
        7: 'A',
        8: 'B',
        9: 'D',
        10: 'A',
        11: 'B',
        12: 'B',
        13: 'C',
        14: 'A',
        15: 'A',
        16: 'C',
        17: 'C',
        18: 'D',
        19: 'C',
        20: 'D',
        21: 'C',
        22: 'D',
        23: 'B',
        24: 'D',
        25: 'A',
        26: 'C',
        27: 'D',
        28: 'B',
        29: 'D',
        30: 'A',
        31: 'A',
        32: 'D',
        33: 'B',
        34: 'B',
        35: 'D',
        36: 'A',
        37: 'C',
        38: 'A',
        39: 'A',
        40: 'D',
        41: 'C',
        42: 'B',
        43: 'A',
        44: 'B',
        45: 'C',
        46: 'A',
        47: 'A',
        48: 'A',
        49: 'D',
        50: 'A/C',
        51: 'D',
        52: 'B',
        53: 'D',
        54: 'A',
        55: 'B',
        56: 'C',
        57: 'NONE',
        58: 'C',
        59: 'D',
        60: 'C',
        61: 'D',
        62: 'C',
        63: 'NONE',
        64: 'D',
        65: 'A',
        66: 'D',
        67: 'B',
        68: 'A',
        69: 'D',
        70: 'B',
        71: 'D',
        72: 'C',
        73: 'B',
        74: 'A',
        75: 'A',
        76: 'NONE',
        77: 'C',
        78: 'C'
      };

      for (final q in questions) {
        final qn = q.questionNumber!;
        final exp = expectedKey[qn]!;
        final correctLabels =
            q.choices.where((c) => c.isCorrect).map((c) => c.label).toList();

        if (exp == 'NONE') {
          expect(correctLabels, isEmpty,
              reason: 'Q$qn is defective and has no valid option');
        } else if (exp == 'A/C') {
          expect(correctLabels.toSet(), equals({'A', 'C'}),
              reason: 'Q$qn has multiple valid answers A and C');
        } else {
          expect(correctLabels, equals([exp]),
              reason: 'Q$qn expected correct answer $exp');
        }
      }
    });

    test(
        'Visual and diagram items are properly linked in 2013, 2014, 2015, 2016, and 2017',
        () async {
      final q13 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2013,
      );
      final q14 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2014,
      );
      final q15 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2015,
      );
      final q16 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2016,
      );
      final q17 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2017,
      );

      final qMap13 = {for (var q in q13) q.questionNumber!: q};
      final qMap14 = {for (var q in q14) q.questionNumber!: q};
      final qMap15 = {for (var q in q15) q.questionNumber!: q};
      final qMap16 = {for (var q in q16) q.questionNumber!: q};
      final qMap17 = {for (var q in q17) q.questionNumber!: q};

      // 2013
      expect(qMap13[22]!.diagramAsset, isNotNull);
      expect(qMap13[23]!.diagramAsset, isNotNull);

      // 2014
      expect(qMap14[3]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q03_heating_curve.png'));
      expect(qMap14[12]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q12_lewis_all.png'));
      expect(qMap14[26]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q26_coordinate_bonds.png'));
      expect(qMap14[70]!.diagramAsset,
          equals('assets/images/exams/chem_2014/q70_sugars_all.png'));

      // 2015
      expect(qMap15[9]!.diagramAsset,
          equals('assets/images/exams/chem_2015/q09_reaction_rate_graphs.png'));
      expect(
          qMap15[17]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2015/q17_fats_triglyceride_structure.png'));
      expect(
          qMap15[23]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2015/q23_chlorine_35_representations.png'));
      expect(
          qMap15[38]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2015/q38_h2o_hybridization_schemes.png'));
      expect(
          qMap15[60]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2015/q60_trimethylhexane_structure.png'));

      // 2016
      expect(qMap16[3]!.diagramAsset,
          equals('assets/images/exams/chem_2016/q03_benzene_structures.png'));
      expect(qMap16[6]!.diagramAsset,
          equals('assets/images/exams/chem_2016/q06_ester_structure.png'));
      expect(
          qMap16[32]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2016/q32_periodic_trends_chart.png'));
      expect(
          qMap16[44]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2016/q44_carboxylic_acid_structures.png'));
      expect(
          qMap16[57]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2016/q57_electrolytic_cell_diagram.png'));
      // 2016 Q8 intentionally has NO invented diagram
      expect(qMap16[8]!.diagramAsset, isNull);

      // 2017
      expect(qMap17[2]!.diagramAsset,
          equals('assets/images/exams/chem_2017/q02_galvanic_cell.png'));
      expect(
          qMap17[37]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2017/q37_polypropylene_structures.png'));
      expect(
          qMap17[38]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2017/q38_becl2_hybridization_schemes.png'));
      expect(qMap17[75]!.diagramAsset,
          equals('assets/images/exams/chem_2017/q75_alkane_structure.png'));
      expect(
          qMap17[76]!.diagramAsset,
          equals(
              'assets/images/exams/chem_2017/q76_carboxylic_acid_structure.png'));
      expect(qMap17[77]!.diagramAsset,
          equals('assets/images/exams/chem_2017/q77_alcohol_structure.png'));
      expect(qMap17[78]!.diagramAsset,
          equals('assets/images/exams/chem_2017/q78_cocl2_structure.png'));
    });

    test('Curriculum distribution spans Grades 9, 10, 11, and 12', () async {
      for (final yr in [2013, 2014, 2015, 2016, 2017]) {
        final yearQuestions = await repository.getQuestions(
          subjectId: 'chemistry_g12',
          examYear: yr,
        );
        final grades = yearQuestions.map((q) => q.curriculumGrade).toSet();
        expect(grades, containsAll([9, 10, 11, 12]),
            reason: 'Year $yr should have questions from Grades 9-12');
      }
    });

    test(
        'Chemistry 2017 exact curriculum grade and pedagogical difficulty distributions',
        () async {
      final q17 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2017,
      );

      final gradeCounts = <int, int>{};
      final diffCounts = <String, int>{};

      for (final q in q17) {
        expect(q.curriculumGrade, isNotNull);
        gradeCounts[q.curriculumGrade!] =
            (gradeCounts[q.curriculumGrade!] ?? 0) + 1;
        diffCounts[q.difficulty] = (diffCounts[q.difficulty] ?? 0) + 1;
        expect(q.difficultySource, equals('fidel_learn_assigned'));
      }

      // Approved Grade distribution: Grade 9 = 11, Grade 10 = 16, Grade 11 = 33, Grade 12 = 18
      expect(gradeCounts[9], equals(11));
      expect(gradeCounts[10], equals(16));
      expect(gradeCounts[11], equals(33));
      expect(gradeCounts[12], equals(18));
      expect(q17.length, equals(78));

      // Approved Difficulty distribution: Easy = 44, Medium = 26, Hard = 8
      expect(diffCounts['easy'], equals(44));
      expect(diffCounts['medium'], equals(26));
      expect(diffCounts['hard'], equals(8));
    });

    test(
        'Exam Level (12) vs Curriculum Grade (11) works in Custom Practice Builder',
        () async {
      // Questions have exam grade 12 but curriculumGrade 11
      final g11Questions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 11,
        examYear: 2015,
        practiceEligibleOnly: true,
      );

      expect(g11Questions.isNotEmpty, isTrue);
      for (final q in g11Questions) {
        expect(q.curriculumGrade, equals(11));
        expect(q.grade, equals(12)); // examLevel is 12
      }
    });

    test('Custom Practice Builder filtering combinations work accurately',
        () async {
      // 1. Chemistry + Grade 11 + Chemical Kinetics + 2015 + Medium
      final comb2015 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 11,
        unitId: 'chem_g11_u4',
        examYear: 2015,
        difficulty: 'medium',
        practiceEligibleOnly: true,
      );
      expect(comb2015.isNotEmpty, isTrue);
      for (final q in comb2015) {
        expect(q.curriculumGrade, equals(11));
        expect(q.curriculumUnitId, equals('chem_g11_u4'));
        expect(q.examYear, equals(2015));
        expect(q.difficulty, equals('medium'));
        expect(q.isPracticeEligible, isTrue);
      }

      // 2. Chemistry + Grade 10 + Hydrocarbons + 2016 + Easy
      final comb2016 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 10,
        unitId: 'chem_g10_u6',
        examYear: 2016,
        difficulty: 'easy',
        practiceEligibleOnly: true,
      );
      expect(comb2016.isNotEmpty, isTrue);
      for (final q in comb2016) {
        expect(q.curriculumGrade, equals(10));
        expect(q.curriculumUnitId, equals('chem_g10_u6'));
        expect(q.examYear, equals(2016));
        expect(q.difficulty, equals('easy'));
        expect(q.isPracticeEligible, isTrue);
      }

      // 3. Chemistry + Grade 11 + All Years + Hard
      final combAllYearsHard = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 11,
        difficulty: 'hard',
        practiceEligibleOnly: true,
      );
      expect(combAllYearsHard.isNotEmpty, isTrue);
      final yearsFound = combAllYearsHard.map((q) => q.examYear).toSet();
      expect(yearsFound.length, greaterThanOrEqualTo(2));
      for (final q in combAllYearsHard) {
        expect(q.curriculumGrade, equals(11));
        expect(q.difficulty, equals('hard'));
        expect(q.isPracticeEligible, isTrue);
      }

      // 4. Excluded defective questions stay OUT of Custom Practice
      final practiceQuestions2016 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2016,
        practiceEligibleOnly: true,
      );
      final p16Nums =
          practiceQuestions2016.map((q) => q.questionNumber).toSet();
      for (final defNum in [8, 19, 42, 47, 53, 55, 78]) {
        expect(p16Nums.contains(defNum), isFalse,
            reason: 'Defective 2016 Q$defNum must be excluded from practice');
      }

      final practiceQuestions2017 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        examYear: 2017,
        practiceEligibleOnly: true,
      );
      final p17Nums =
          practiceQuestions2017.map((q) => q.questionNumber).toSet();
      for (final defNum in [57, 63, 76]) {
        expect(p17Nums.contains(defNum), isFalse,
            reason: 'Defective 2017 Q$defNum must be excluded from practice');
      }

      // 5. Chemistry + Grade 11 + Chemical Equilibrium + 2017 + Medium
      final comb2017Equil = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 11,
        unitId: 'chem_g11_u5',
        examYear: 2017,
        difficulty: 'medium',
        practiceEligibleOnly: true,
      );
      expect(comb2017Equil.isNotEmpty, isTrue);
      for (final q in comb2017Equil) {
        expect(q.curriculumGrade, equals(11));
        expect(q.curriculumUnitId, equals('chem_g11_u5'));
        expect(q.examYear, equals(2017));
        expect(q.difficulty, equals('medium'));
        expect(q.isPracticeEligible, isTrue);
      }

      // 6. Chemistry + Grade 12 + Electrochemistry + 2017 + Hard
      final comb2017Electro = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 12,
        unitId: 'chem_g12_u2',
        examYear: 2017,
        difficulty: 'medium',
        practiceEligibleOnly: true,
      );
      expect(comb2017Electro.isNotEmpty, isTrue);
      for (final q in comb2017Electro) {
        expect(q.curriculumGrade, equals(12));
        expect(q.curriculumUnitId, equals('chem_g12_u2'));
        expect(q.examYear, equals(2017));
        expect(q.isPracticeEligible, isTrue);
      }

      // 7. Exam Level (12) vs Curriculum Grade (10) for 2017
      final g10Questions2017 = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        grade: 10,
        examYear: 2017,
        practiceEligibleOnly: true,
      );
      expect(g10Questions2017.isNotEmpty, isTrue);
      for (final q in g10Questions2017) {
        expect(q.curriculumGrade, equals(10));
        expect(q.grade, equals(12)); // examLevel is 12
      }

      // 8. Total counts across all 5 years: 80 + 70 + 78 + 80 + 78 = 386 questions
      final allQuestions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
      );
      expect(allQuestions.length, equals(386));
    });

    test('Every practice-eligible question has a valid pedagogical difficulty',
        () async {
      final practiceQuestions = await repository.getQuestions(
        subjectId: 'chemistry_g12',
        practiceEligibleOnly: true,
      );

      for (final q in practiceQuestions) {
        expect(['easy', 'medium', 'hard'], contains(q.difficulty));
        expect(q.difficultySource, equals('fidel_learn_assigned'));
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
        choices: [
          AnswerChoice(id: 'c1', label: 'A', textEn: 'A', isCorrect: true),
          AnswerChoice(id: 'c2', label: 'B', textEn: 'B', isCorrect: false),
        ],
        explanation: Explanation(solutionTextEn: 'Explanation'),
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
        choices: [
          AnswerChoice(id: 'c3', label: 'A', textEn: 'A', isCorrect: false),
          AnswerChoice(id: 'c4', label: 'B', textEn: 'B', isCorrect: true),
          AnswerChoice(id: 'c5', label: 'C', textEn: 'C', isCorrect: false),
          AnswerChoice(id: 'c6', label: 'D', textEn: 'D', isCorrect: true),
        ],
        explanation: Explanation(solutionTextEn: 'Explanation'),
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
        choices: [
          AnswerChoice(id: 'c7', label: 'A', textEn: 'A', isCorrect: false),
          AnswerChoice(id: 'c8', label: 'B', textEn: 'B', isCorrect: false),
        ],
        explanation: Explanation(solutionTextEn: 'Explanation'),
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

    test(
        'Chemistry 2017 Q50 accepts either A or C as correct and rejects B or D',
        () async {
      final q50 = await repository.getQuestionById('q_chem_2017_050');
      expect(q50, isNotNull);
      expect(q50!.verificationStatus,
          equals(VerificationStatus.multipleValidAnswers));

      final choiceA = q50.choices.firstWhere((c) => c.label == 'A');
      final choiceB = q50.choices.firstWhere((c) => c.label == 'B');
      final choiceC = q50.choices.firstWhere((c) => c.label == 'C');
      final choiceD = q50.choices.firstWhere((c) => c.label == 'D');

      expect(choiceA.isCorrect, isTrue);
      expect(choiceB.isCorrect, isFalse);
      expect(choiceC.isCorrect, isTrue);
      expect(choiceD.isCorrect, isFalse);

      final exam = Exam(
        id: 'exam_q50_test',
        title: 'Q50 Test',
        examType: ExamType.practice,
        grade: 12,
        stream: 'natural',
        subjectId: 'chemistry_g12',
        timeLimitMinutes: 0,
        totalQuestions: 1,
        questions: [q50],
        createdAt: DateTime.now(),
      );

      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_q50',
        userId: 'user_test',
        exam: exam,
      );

      // 1. Selecting A is correct
      final attemptWithA = ExamEngine.answerQuestion(
        currentAttempt: attempt,
        question: q50,
        choiceId: choiceA.id,
      );
      expect(attemptWithA.responses[q50.id]!.isCorrect, isTrue);

      // 2. Selecting C is correct
      final attemptWithC = ExamEngine.answerQuestion(
        currentAttempt: attempt,
        question: q50,
        choiceId: choiceC.id,
      );
      expect(attemptWithC.responses[q50.id]!.isCorrect, isTrue);

      // 3. Selecting B is incorrect
      final attemptWithB = ExamEngine.answerQuestion(
        currentAttempt: attempt,
        question: q50,
        choiceId: choiceB.id,
      );
      expect(attemptWithB.responses[q50.id]!.isCorrect, isFalse);

      // 4. Selecting D is incorrect
      final attemptWithD = ExamEngine.answerQuestion(
        currentAttempt: attempt,
        question: q50,
        choiceId: choiceD.id,
      );
      expect(attemptWithD.responses[q50.id]!.isCorrect, isFalse);
    });
  });
}

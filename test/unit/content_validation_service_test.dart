import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/diagram_models.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/question_bank/domain/services/content_validation_service.dart';

void main() {
  group('ContentValidationService - Duplicate & Integrity Detection', () {
    late ContentValidationService service;

    setUp(() {
      service = ContentValidationService();
    });

    const validQuestion1 = Question(
      id: 'q_test_1',
      subjectId: 'physics_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      grade: 12,
      stream: 'natural',
      difficulty: 'medium',
      questionTextEn:
          'What is the SI unit of electric capacitance in modern physics?',
      questionTextAm: 'በዘመናዊ ፊዚክስ የኤሌክትሪክ ካፓሲታንስ መለኪያ ምንድን ነው?',
      verificationStatus: VerificationStatus.published,
      sourceName: 'ESSLCE 2014 E.C.',
      contentVersion: 1,
      choices: [
        AnswerChoice(id: 'c1', label: 'A', textEn: 'Farad', isCorrect: true),
        AnswerChoice(id: 'c2', label: 'B', textEn: 'Henry', isCorrect: false),
        AnswerChoice(id: 'c3', label: 'C', textEn: 'Tesla', isCorrect: false),
        AnswerChoice(id: 'c4', label: 'D', textEn: 'Weber', isCorrect: false),
      ],
      explanation: Explanation(
        solutionTextEn: 'The SI unit of capacitance is the Farad (F).',
        keyConcept: 'Capacitance & Charge Storage',
      ),
    );

    test(
        'hashNormalizedText normalizes punctuation and casing deterministically',
        () {
      final hash1 = ContentValidationService.hashNormalizedText(
          'What is the SI unit of capacitance?');
      final hash2 = ContentValidationService.hashNormalizedText(
          '  what is the si unit of capacitance?!  ');
      expect(hash1, equals(hash2));
    });

    test('detects exact duplicates with identical normalized text', () {
      final duplicateQ = validQuestion1.copyWith(
        id: 'q_test_dup',
        questionTextEn:
            'what is the si unit of electric capacitance in modern physics?',
      );

      final exactDuplicates =
          service.detectExactDuplicates([validQuestion1, duplicateQ]);
      expect(exactDuplicates.length, equals(1));
      expect(exactDuplicates.first.questionIds.length, equals(2));
      expect(exactDuplicates.first.questionIds,
          containsAll(['q_test_1', 'q_test_dup']));
    });

    test('detects near-duplicate questions above similarity threshold', () {
      final nearDuplicateQ = validQuestion1.copyWith(
        id: 'q_test_near',
        questionTextEn:
            'What is the SI unit of electric capacitance in experimental physics?',
      );

      final nearDuplicates = service.detectNearDuplicates(
        [validQuestion1, nearDuplicateQ],
        threshold: 0.70,
      );

      expect(nearDuplicates.isNotEmpty, isTrue);
      expect(nearDuplicates.first.questionId1, equals('q_test_1'));
      expect(nearDuplicates.first.questionId2, equals('q_test_near'));
      expect(nearDuplicates.first.similarityScore, greaterThanOrEqualTo(0.70));
    });

    test(
        'validateQuestionBank passes clean question bank with zero critical errors',
        () {
      final report = service.validateQuestionBank(questions: [validQuestion1]);
      expect(report.errorCount, equals(0));
      expect(report.isClean, isTrue);
    });

    test('flags missing correct answer key as critical error', () {
      final invalidQ = validQuestion1.copyWith(
        id: 'q_no_correct',
        choices: const [
          AnswerChoice(id: 'c1', label: 'A', textEn: 'Farad', isCorrect: false),
          AnswerChoice(id: 'c2', label: 'B', textEn: 'Henry', isCorrect: false),
        ],
      );

      final report = service.validateQuestionBank(questions: [invalidQ]);
      expect(
          report.issues
              .any((i) => i.issueType == ValidationIssueType.missingAnswerKey),
          isTrue);
      expect(report.errorCount, greaterThan(0));
    });

    test('flags published status with empty text as error', () {
      final unverifiedPublished = validQuestion1.copyWith(
        id: 'q_unverified_pub',
        verificationStatus: VerificationStatus.published,
        questionTextEn: '   ',
      );

      final report =
          service.validateQuestionBank(questions: [unverifiedPublished]);
      expect(
          report.issues.any(
              (i) => i.issueType == ValidationIssueType.unverifiedPublished),
          isTrue);
    });

    test('flags duplicate question IDs as critical error', () {
      final qDupId = validQuestion1.copyWith(
        questionTextEn: 'A completely different question text but same id.',
      );

      final report =
          service.validateQuestionBank(questions: [validQuestion1, qDupId]);
      expect(
          report.issues
              .any((i) => i.issueType == ValidationIssueType.duplicateId),
          isTrue);
      expect(report.isClean, isFalse);
    });

    test('flags malformed LaTeX formula syntax as critical error', () {
      final malformedFormulaQ = validQuestion1.copyWith(
        id: 'q_bad_formula',
        questionTextEn:
            'Evaluate the integral \\( \\int_{0}^{1} \\frac{x^2}{dx \\) carefully.',
      );

      final report =
          service.validateQuestionBank(questions: [malformedFormulaQ]);
      expect(
        report.issues.any(
            (i) => i.issueType == ValidationIssueType.invalidFormulaSyntax),
        isTrue,
      );
      expect(report.errorCount, greaterThan(0));
    });

    test('flags unsupported diagram file format', () {
      final badAssetQ = validQuestion1.copyWith(
        id: 'q_bad_asset',
        diagramAsset: 'assets/diagrams/physics_circuit.bmp',
      );

      final report = service.validateQuestionBank(questions: [badAssetQ]);
      expect(
        report.issues
            .any((i) => i.issueType == ValidationIssueType.brokenDiagramAsset),
        isTrue,
      );
    });

    test('flags malformed SVG diagram markup', () {
      final badSvgQ = validQuestion1.copyWith(
        id: 'q_bad_svg',
        vectorDiagram: const VectorDiagram(
          id: 'v1',
          titleEn: 'Bad Diagram',
          rawSvgContent: '<div>Not an svg diagram</div>',
          viewBoxWidth: 100,
          viewBoxHeight: 100,
        ),
      );

      final report = service.validateQuestionBank(questions: [badSvgQ]);
      expect(
        report.issues
            .any((i) => i.issueType == ValidationIssueType.brokenDiagramAsset),
        isTrue,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/domain/services/delta_package_service.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  group('DeltaPackageService Tests', () {
    late DeltaPackageService deltaService;

    setUp(() {
      deltaService = DeltaPackageService();
    });

    const q1 = Question(
      id: 'q1',
      subjectId: 'math_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      grade: 12,
      stream: 'natural',
      difficulty: 'easy',
      questionTextEn: 'Initial question 1',
      verificationStatus: VerificationStatus.published,
      sourceName: 'FidelLearn Model Exam Prep',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Sol 1'),
    );

    const q2 = Question(
      id: 'q2',
      subjectId: 'math_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      grade: 12,
      stream: 'natural',
      difficulty: 'medium',
      questionTextEn: 'Initial question 2 (to be updated)',
      verificationStatus: VerificationStatus.published,
      sourceName: 'FidelLearn Model Exam Prep',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Sol 2'),
    );

    const q3 = Question(
      id: 'q3',
      subjectId: 'math_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      grade: 12,
      stream: 'natural',
      difficulty: 'hard',
      questionTextEn: 'Initial question 3 (to be deprecated)',
      verificationStatus: VerificationStatus.published,
      sourceName: 'FidelLearn Model Exam Prep',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Sol 3'),
    );

    const q2Updated = Question(
      id: 'q2',
      subjectId: 'math_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      grade: 12,
      stream: 'natural',
      difficulty: 'medium',
      questionTextEn: 'Updated corrected question 2 with LaTeX notation',
      verificationStatus: VerificationStatus.published,
      sourceName: 'FidelLearn Model Exam Prep',
      contentVersion: 2,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Corrected Sol 2'),
    );

    const q4New = Question(
      id: 'q4',
      subjectId: 'math_g12',
      unitId: 'unit_1',
      topicId: 'topic_1',
      grade: 12,
      stream: 'natural',
      difficulty: 'medium',
      questionTextEn: 'Brand new question 4',
      verificationStatus: VerificationStatus.published,
      sourceName: 'FidelLearn Model Exam Prep',
      contentVersion: 1,
      choices: [],
      explanation: Explanation(solutionTextEn: 'Sol 4'),
    );

    test('validates delta package version compatibility', () {
      final delta = PackageDelta(
        packageId: 'pkg_g12_math',
        fromVersion: '1.0.0',
        toVersion: '1.1.0',
        addedQuestions: const [q4New],
        updatedQuestions: const [q2Updated],
        deprecatedQuestionIds: const ['q3'],
        releaseDate: DateTime.now(),
      );

      expect(
        deltaService.isDeltaCompatible(currentVersion: '1.0.0', delta: delta),
        isTrue,
      );
      expect(
        deltaService.isDeltaCompatible(currentVersion: '0.9.0', delta: delta),
        isFalse,
      );
    });

    test(
        'applies delta patch by adding, updating, and removing deprecated questions',
        () {
      final delta = PackageDelta(
        packageId: 'pkg_g12_math',
        fromVersion: '1.0.0',
        toVersion: '1.1.0',
        addedQuestions: const [q4New],
        updatedQuestions: const [q2Updated],
        deprecatedQuestionIds: const ['q3'],
        releaseDate: DateTime.now(),
      );

      const List<Question> initialQuestions = [q1, q2, q3];
      final patched = deltaService.applyDeltaPatch(
        existingQuestions: initialQuestions,
        delta: delta,
      );

      expect(patched.length, 3); // q1 kept, q2 updated, q3 removed, q4 added
      expect(patched.any((q) => q.id == 'q3'), isFalse);
      expect(patched.any((q) => q.id == 'q4'), isTrue);

      final updatedQ2 = patched.firstWhere((q) => q.id == 'q2');
      expect(
          updatedQ2.questionTextEn, contains('Updated corrected question 2'));
      expect(updatedQ2.contentVersion, 2);
    });
  });
}

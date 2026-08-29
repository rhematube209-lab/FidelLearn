import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('LocalContentRepository Question Filtering Tests', () {
    late LocalContentRepository repository;

    setUp(() {
      repository = LocalContentRepository();
      repository.initializeWithData(
        packages: [
          const ContentPackage(
            packageId: 'p1',
            subjectId: 'math_g12',
            nameEn: 'Math',
            nameAm: 'ሂሳብ',
            grade: 12,
            stream: 'natural',
            version: 1,
            sizeBytes: 100,
            publisher: 'FidelLearn',
            license: 'demo',
            attribution: 'Demo',
            isDownloaded: true,
          ),
        ],
        subjects: [
          const Subject(
            id: 'math_g12',
            code: 'M12',
            nameEn: 'Math',
            nameAm: 'ሂሳብ',
            grade: 12,
            stream: 'natural',
            sortOrder: 1,
          ),
        ],
        units: [
          const Unit(
            id: 'u1',
            subjectId: 'math_g12',
            unitNumber: 1,
            titleEn: 'Unit 1',
            titleAm: 'ክፍል 1',
          ),
        ],
        topics: [
          const Topic(
            id: 't1',
            unitId: 'u1',
            topicNumber: 1,
            titleEn: 'Topic 1',
            titleAm: 'ርዕስ 1',
          ),
          const Topic(
            id: 't2',
            unitId: 'u1',
            topicNumber: 2,
            titleEn: 'Topic 2',
            titleAm: 'ርዕስ 2',
          ),
        ],
        questions: [
          const Question(
            id: 'q1',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u1',
            topicId: 't1',
            examYear: 2023,
            difficulty: 'easy',
            verificationStatus: VerificationStatus.published,
            sourceName: 'Demo',
            contentVersion: 1,
            questionTextEn: 'Q1',
            choices: [],
            explanation: Explanation(solutionTextEn: 'E1'),
          ),
          const Question(
            id: 'q2',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u1',
            topicId: 't2',
            examYear: 2022,
            difficulty: 'hard',
            verificationStatus: VerificationStatus.published,
            sourceName: 'Demo',
            contentVersion: 1,
            questionTextEn: 'Q2',
            choices: [],
            explanation: Explanation(solutionTextEn: 'E2'),
          ),
          const Question(
            id: 'q3_draft',
            grade: 12,
            stream: 'natural',
            subjectId: 'math_g12',
            unitId: 'u1',
            topicId: 't1',
            examYear: 2023,
            difficulty: 'easy',
            verificationStatus: VerificationStatus.draft, // Unapproved draft
            sourceName: 'Demo',
            contentVersion: 1,
            questionTextEn: 'Q3 Draft',
            choices: [],
            explanation: Explanation(solutionTextEn: 'E3'),
          ),
        ],
      );
    });

    test('excludes draft or unapproved questions from student queries', () async {
      final questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'math_g12',
      );

      expect(questions.length, 2);
      expect(questions.any((q) => q.id == 'q3_draft'), isFalse);
    });

    test('filters questions accurately by topic and difficulty', () async {
      final t1Questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'math_g12',
        topicId: 't1',
      );
      expect(t1Questions.length, 1);
      expect(t1Questions.first.id, 'q1');

      final hardQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'math_g12',
        difficulty: 'hard',
      );
      expect(hardQuestions.length, 1);
      expect(hardQuestions.first.id, 'q2');
    });

    test('limits query results correctly without memory overload', () async {
      final limited = await repository.getQuestions(
        grade: 12,
        subjectId: 'math_g12',
        limit: 1,
      );
      expect(limited.length, 1);
    });
  });
}

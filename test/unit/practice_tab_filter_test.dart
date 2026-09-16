import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Practice Tab Custom Exam Filter Tests', () {
    late LocalContentRepository contentRepo;

    setUp(() async {
      contentRepo = LocalContentRepository();
      await contentRepo.initializeSeedData();
    });

    test('retrieves Grade 9 Mathematics subject and units', () async {
      final g9Subjects = await contentRepo.getSubjects(
        grade: 9,
        stream: 'common',
      );
      expect(g9Subjects.isNotEmpty, isTrue);
      expect(g9Subjects.any((s) => s.id == 'math_g9'), isTrue);

      final g9MathUnits = await contentRepo.getUnits('math_g9');
      expect(g9MathUnits.length, greaterThanOrEqualTo(3));
      final unit3 = g9MathUnits.firstWhere((u) => u.unitNumber == 3);
      expect(unit3.id, 'math_g9_u3');
      expect(unit3.titleEn, contains('Relations and Functions'));
    });

    test(
        'retrieves Grade 9 Mathematics Unit 3 questions within year range 2013-2017',
        () async {
      final questions = await contentRepo.getQuestions(
        grade: 9,
        subjectId: 'math_g9',
        unitId: 'math_g9_u3',
        startYear: 2013,
        endYear: 2017,
      );

      expect(questions.isNotEmpty, isTrue);
      expect(questions.length, greaterThanOrEqualTo(5));

      // Check that all returned questions are Grade 9, Unit 3, and between 2013 and 2017
      for (final q in questions) {
        expect(q.grade, 9);
        expect(q.subjectId, 'math_g9');
        expect(q.unitId, 'math_g9_u3');
        expect(q.examYear, isNotNull);
        expect(q.examYear!, greaterThanOrEqualTo(2013));
        expect(q.examYear!, lessThanOrEqualTo(2017));
      }

      // Verify specific exam years exist in the result set
      final years = questions.map((q) => q.examYear).toSet();
      expect(years.contains(2013), isTrue);
      expect(years.contains(2014), isTrue);
      expect(years.contains(2015), isTrue);
      expect(years.contains(2016), isTrue);
      expect(years.contains(2017), isTrue);
    });

    test(
        'retrieves Grade 9 Mathematics Unit 3 questions for a single year (2014)',
        () async {
      final questions = await contentRepo.getQuestions(
        grade: 9,
        subjectId: 'math_g9',
        unitId: 'math_g9_u3',
        examYear: 2014,
      );

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.examYear, 2014);
        expect(q.grade, 9);
        expect(q.unitId, 'math_g9_u3');
      }
    });

    test('supports multi-grade secondary subject retrieval when grade is null',
        () async {
      final allSecondarySubjects = await contentRepo.getSubjects(
        grade: null,
        stream: 'natural',
      );

      expect(allSecondarySubjects.isNotEmpty, isTrue);
      final grades = allSecondarySubjects.map((s) => s.grade).toSet();
      expect(grades.contains(9), isTrue);
      expect(grades.contains(10), isTrue);
      expect(grades.contains(12), isTrue);
    });

    test(
        'verifies answer choices and step-by-step solutions for Grade 9 Unit 3 questions',
        () async {
      final questions = await contentRepo.getQuestions(
        grade: 9,
        subjectId: 'math_g9',
        unitId: 'math_g9_u3',
        examYear: 2013,
      );

      expect(questions.isNotEmpty, isTrue);
      final q2013 = questions.first;
      expect(q2013.choices.length, 4);
      expect(q2013.choices.any((c) => c.isCorrect), isTrue);
      expect(q2013.explanation.solutionTextEn, isNotEmpty);
      expect(q2013.explanation.keyConcept, isNotNull);
      expect(q2013.explanation.commonPitfall, isNotNull);
    });
  });
}

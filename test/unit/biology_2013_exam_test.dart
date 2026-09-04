import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ESSLCE Biology 2013 E.C. National Exam (100 Questions) Tests', () {
    late LocalContentRepository repository;

    setUp(() {
      repository = LocalContentRepository(
        seedAssetPaths: ['assets/seed/biology_2013_seed.json'],
      );
    });

    test('loads Grade 12 Biology package, subject, 7 units, and 18 topics',
        () async {
      await repository.initializeSeedData();

      final packages =
          await repository.getPackages(grade: 12, stream: 'natural');
      expect(
          packages.any((p) => p.packageId == 'pkg_g12_biology_2013'), isTrue);

      final subjects =
          await repository.getSubjects(grade: 12, stream: 'natural');
      final bio = subjects.firstWhere((s) => s.id == 'biology_g12');
      expect(bio.nameEn, 'Biology');

      final units = await repository.getUnits('biology_g12');
      expect(units.length, 7);
      expect(units.first.titleEn, contains('Biological Research'));

      final topics = await repository.getTopics('bio_u1');
      expect(topics.isNotEmpty, isTrue);
    });

    test(
        'verifies all 100 Biology questions are loaded with 4 choices and 1 correct answer',
        () async {
      await repository.initializeSeedData();

      final questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
      );
      expect(questions.length, 100);

      for (int i = 0; i < 100; i++) {
        final q = questions[i];
        expect(q.examYear, 2013);
        expect(q.choices.length, 4,
            reason: 'Question ${i + 1} must have 4 choices');
        final correctCount = q.choices.where((c) => c.isCorrect).length;
        expect(correctCount, 1,
            reason: 'Question ${i + 1} must have exactly 1 correct answer');
        expect(q.explanation.solutionTextEn.isNotEmpty, isTrue);
        expect(q.explanation.keyConcept?.isNotEmpty, isTrue);
      }
    });

    test(
        'verifies specific milestone questions and answer key accuracy from 2013 E.C. booklet',
        () async {
      await repository.initializeSeedData();

      final questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
      );

      // Q1: Lucy bipedalism before big brains (Choice C)
      final q1 = questions[0];
      expect(q1.questionTextEn, contains('importance of Lucy'));
      expect(q1.correctChoice.label, 'C');
      expect(q1.correctChoice.textEn, 'Bipedalism came before big brains.');

      // Q7: Bacteria shapes diagram (Choice D)
      final q7 = questions[6];
      expect(q7.correctChoice.label, 'D');
      expect(q7.correctChoice.textEn, 'Spirochaete, sphere, rod');
      expect(q7.vectorDiagram, isNotNull);
      expect(q7.vectorDiagram!.hotspots.length, 3);

      // Q11: Bacteriophage diagram DNA & protein coat (Choice D: 2 and 1)
      final q11 = questions[10];
      expect(q11.correctChoice.label, 'D');
      expect(q11.correctChoice.textEn, '2 and 1.');
      expect(q11.vectorDiagram, isNotNull);

      // Q45: Hybrid vigor bar chart (Choice B: X inbreeding, Z cross-breeding)
      final q45 = questions[44];
      expect(q45.correctChoice.label, 'B');
      expect(q45.correctChoice.textEn,
          'X involves inbreeding and Z involves cross-breeding');

      // Q78: Chloroplast photolysis & Calvin site (Choice D: F and E)
      final q78 = questions[77];
      expect(q78.correctChoice.label, 'D');
      expect(q78.correctChoice.textEn, 'F and E');

      // Q100: Cyclooxygenase-2 ibuprofen inhibitor (Choice A: Pain of the body is decreased)
      final q100 = questions[99];
      expect(q100.questionTextEn, contains('Cyclooxygenase-2'));
      expect(q100.correctChoice.label, 'A');
      expect(q100.correctChoice.textEn, 'Pain of the body is decreased.');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exam Builder Question Pool Verification', () {
    late LocalContentRepository repository;

    setUp(() async {
      repository = LocalContentRepository();
      await repository.initializeSeedData();
    });

    test('Biology 2013 questions match ExamBuilder default query', () async {
      // Range query 2013-2017 includes 2013
      final questionsRange = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
        startYear: 2013,
        endYear: 2017,
      );
      expect(questionsRange.length, 100);

      // Single year 2013 has all 100 questions
      final questions2013 = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
        examYear: 2013,
      );
      expect(questions2013.length, 100);

      // Single year 2014 has 0 questions for Biology
      final questions2014 = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
        examYear: 2014,
      );
      expect(questions2014.length, 0);
    });

    test('Physics 2014 questions match ExamBuilder default query', () async {
      final questionsRange = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        startYear: 2013,
        endYear: 2017,
      );
      expect(questionsRange.length, 32);

      final questions2014 = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        examYear: 2014,
      );
      expect(questions2014.length, 32);

      final questions2013 = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        examYear: 2013,
      );
      expect(questions2013.length, 0);
    });

    test('Unit filtering in Exam Builder for Biology and Physics', () async {
      final bioUnits = await repository.getUnits('biology_g12');
      expect(bioUnits.isNotEmpty, isTrue);
      final bioU2Questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
        unitId: 'bio_u2',
      );
      expect(bioU2Questions.length, 31);

      final physUnits = await repository.getUnits('physics_g12');
      expect(physUnits.isNotEmpty, isTrue);
      final physG10U1Questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        unitId: 'phys_g10_u1',
      );
      expect(physG10U1Questions.length, 3);
    });

    test('What happens when Grade 9, 10, or 11 is selected in Exam Builder?',
        () async {
      // Grade 11 mapping for Biology has 46 questions mapped to Grade 11 in curriculum
      final bioG11 = await repository.getQuestions(
        grade: 11,
        subjectId: 'biology_g12',
      );
      expect(bioG11.length, 46);

      // Grade 10 curriculum grade questions for Physics
      final physG10 = await repository.getQuestions(
        grade: 10,
        subjectId: 'physics_g12',
      );
      expect(physG10.length, 13);
    });

    test('ExamAvailability dynamic indexing and querying', () async {
      // Biology availability
      final bioAvail = await repository.getExamAvailabilities('biology_g12');
      expect(bioAvail.length, 1);
      expect(bioAvail.first.year, 2013);
      expect(bioAvail.first.totalQuestions, 100);
      expect(bioAvail.first.unitCounts['bio_u2'], 31);
      expect(bioAvail.first.unitCounts['bio_u6'], 18);

      final bioYears = await repository.getAvailableExamYears('biology_g12');
      expect(bioYears, [2013]);

      // Physics availability
      final physAvail = await repository.getExamAvailabilities('physics_g12');
      expect(physAvail.length, 1);
      expect(physAvail.first.year, 2014);
      expect(physAvail.first.totalQuestions, 32);
      expect(physAvail.first.unitCounts['phys_g10_u1'], 3);

      final physYears = await repository.getAvailableExamYears('physics_g12');
      expect(physYears, [2014]);

      // Unit question counts query
      final bioUnitCounts = await repository.getUnitQuestionCounts(
        subjectId: 'biology_g12',
        examYear: 2013,
      );
      expect(bioUnitCounts['bio_u2'], 31);
      expect(bioUnitCounts['bio_u1'], 7);

      final physUnitCounts = await repository.getUnitQuestionCounts(
        subjectId: 'physics_g12',
        examYear: 2014,
      );
      expect(physUnitCounts['phys_g10_u1'], 3);
      expect(physUnitCounts['phys_g11_u6'], 4);
    });
  });
}

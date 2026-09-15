import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Curriculum Classification & Customization Tests', () {
    late LocalContentRepository repository;

    setUp(() async {
      repository = LocalContentRepository();
      await repository.initializeSeedData();
    });

    test('retrieves Biology questions mapped to Grade 9 New Curriculum', () async {
      final g9BioQuestions = await repository.getQuestions(
        grade: 9,
        subjectId: 'biology_g9',
      );

      expect(g9BioQuestions.isNotEmpty, isTrue);
      expect(g9BioQuestions.length, greaterThanOrEqualTo(10));
      for (final q in g9BioQuestions) {
        expect(q.curriculumGrade, 9);
        expect(q.curriculumFramework, 'new_curriculum_2023');
      }
    });

    test('filters 2013 Biology questions by Grade 9 Unit 5 (Human Health)', () async {
      final healthQuestions = await repository.getQuestions(
        grade: 9,
        subjectId: 'biology_g9',
        unitId: 'bio_g9_u5',
      );

      expect(healthQuestions.isNotEmpty, isTrue);
      for (final q in healthQuestions) {
        expect(q.curriculumGrade, 9);
        expect(q.curriculumUnitId, 'bio_g9_u5');
      }
    });

    test('filters 2013 Biology questions by Grade 11 Unit 4 (Photosynthesis & Respiration)', () async {
      final energyQuestions = await repository.getQuestions(
        grade: 11,
        subjectId: 'biology_g11',
        unitId: 'bio_g11_u4',
      );

      expect(energyQuestions.isNotEmpty, isTrue);
      expect(energyQuestions.length, greaterThanOrEqualTo(5));
      for (final q in energyQuestions) {
        expect(q.curriculumGrade, 11);
        expect(q.curriculumUnitId, 'bio_g11_u4');
      }
    });

    test('filters 2013 Biology questions by Grade 12 Unit 2 (Evolution & Behavior)', () async {
      final evoQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
        unitId: 'bio_g12_u2',
      );

      expect(evoQuestions.isNotEmpty, isTrue);
      for (final q in evoQuestions) {
        expect(q.curriculumGrade, 12);
        expect(q.curriculumUnitId, 'bio_g12_u2');
      }
    });

    test('retrieves all 100 questions when practicing full 2013 exam paper', () async {
      final fullExamQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'biology_g12',
        examYear: 2013,
      );

      expect(fullExamQuestions.length, 100);
    });
  });
}

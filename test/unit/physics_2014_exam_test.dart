import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ESSLCE Physics 2014 E.C. (Natural Science, 32 Questions) Tests', () {
    late LocalContentRepository repository;

    setUp(() {
      repository = LocalContentRepository(
        seedAssetPaths: ['assets/seed/physics_2014_seed.json'],
      );
    });

    test('loads Grade 12 Physics package, subject, 13 units, and 32 topics',
        () async {
      await repository.initializeSeedData();

      final packages =
          await repository.getPackages(grade: 12, stream: 'natural');
      expect(
          packages.any((p) => p.packageId == 'pkg_g12_physics_2014'), isTrue);

      final subjects =
          await repository.getSubjects(grade: 12, stream: 'natural');
      final phys = subjects.firstWhere((s) => s.id == 'physics_g12');
      expect(phys.nameEn, 'Physics');

      final units = await repository.getUnits('physics_g12');
      expect(units.length, 13);
      expect(units.any((u) => u.id == 'phys_g10_u1'), isTrue);
      expect(units.any((u) => u.id == 'phys_g11_u4'), isTrue);
      expect(units.any((u) => u.id == 'phys_g12_u4'), isTrue);

      final vectorTopics = await repository.getTopics('phys_g10_u1');
      expect(vectorTopics.length, 3);
    });

    test(
        'verifies all 32 Physics 2014 questions have 4 choices, 1 correct answer, and solutions',
        () async {
      await repository.initializeSeedData();

      final questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        examYear: 2014,
      );
      expect(questions.length, 32);

      // Verified answer key from PDF page 1:
      // 1-A, 2-C, 3-A, 4-D, 5-B, 6-C, 7-D, 8-A, 9-D, 10-C
      // 11-B, 12-D, 13-A, 14-D, 15-D, 16-B, 17-A, 18-C, 19-C, 20-D
      // 21-B, 22-C, 23-A, 24-C, 25-C, 26-B, 27-B, 28-A, 29-A, 30-B
      // 31-D, 32-D
      final expectedKeys = [
        'A', 'C', 'A', 'D', 'B', 'C', 'D', 'A', 'D', 'C',
        'B', 'D', 'A', 'D', 'D', 'B', 'A', 'C', 'C', 'D',
        'B', 'C', 'A', 'C', 'C', 'B', 'B', 'A', 'A', 'B',
        'D', 'D'
      ];

      for (int i = 0; i < 32; i++) {
        final q = questions[i];
        expect(q.examYear, 2014);
        expect(q.choices.length, 4,
            reason: 'Question ${i + 1} must have 4 choices');
        final correctChoice = q.choices.firstWhere((c) => c.isCorrect);
        expect(correctChoice.label, expectedKeys[i],
            reason: 'Question ${i + 1} correct answer must match key');
        expect(q.explanation.solutionTextEn.isNotEmpty, isTrue);
        expect(q.explanation.keyConcept?.isNotEmpty, isTrue);
        expect(q.explanation.commonPitfall?.isNotEmpty, isTrue);
      }
    });

    test('verifies curriculum unit customization mapping for practice builder',
        () async {
      await repository.initializeSeedData();

      // Test Vector Quantities (Grade 10 Unit 1): Q3, Q4, Q31
      final vectorQs = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        unitId: 'phys_g10_u1',
      );
      expect(vectorQs.length, 3);
      expect(vectorQs.map((q) => q.questionTextEn).toList(), [
        contains('unit vector in the direction of'),
        contains('vectors are collinear'),
        contains('Three forces, each having equal magnitudes of 10 N'),
      ]);

      // Test Dynamics (Grade 11 Unit 4): Q8, Q9, Q10
      final dynamicsQs = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        unitId: 'phys_g11_u4',
      );
      expect(dynamicsQs.length, 3);

      // Test Electromagnetism (Grade 12 Unit 4): Q17, Q18, Q29
      final emQs = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
        unitId: 'phys_g12_u4',
      );
      expect(emQs.length, 3);
      expect(emQs.map((q) => q.questionTextEn).toList(), [
        contains('law of electromagnetic induction'),
        contains('average power dissipated in series the RLC circuit'),
        contains('primary coil of a transformer has 250 turns'),
      ]);
    });

    test('verifies questions with diagrams have valid diagram asset paths',
        () async {
      await repository.initializeSeedData();

      final questions = await repository.getQuestions(
        grade: 12,
        subjectId: 'physics_g12',
      );

      // Q1: Plane mirror
      expect(questions[0].diagramAsset,
          'assets/images/exams/phys_2014/q01_plane_mirror_reflection.png');

      // Q8: Inclined block force
      expect(questions[7].diagramAsset,
          'assets/images/exams/phys_2014/q08_block_inclined_force_friction.png');

      // Q9: Bouncing ball
      expect(questions[8].diagramAsset,
          'assets/images/exams/phys_2014/q09_ball_collision_momentum.png');

      // Q15: Resistor network
      expect(questions[14].diagramAsset,
          'assets/images/exams/phys_2014/q15_resistor_circuit_combination.png');

      // Q27: Ohm\'s law setups
      expect(questions[26].diagramAsset,
          'assets/images/exams/phys_2014/q27_ohms_law_circuit_setups.png');

      // Q28: Charged particle paths in magnetic field
      expect(questions[27].diagramAsset,
          'assets/images/exams/phys_2014/q28_charges_magnetic_field_paths.png');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/curriculum_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Grade Curriculum & Content Repository Tests', () {
    late LocalContentRepository repository;

    setUp(() {
      repository = LocalContentRepository();
    });

    test('validates GradeLevel enum properties and numeric mapping', () {
      expect(GradeLevel.fromInt(6), GradeLevel.grade6);
      expect(GradeLevel.fromInt(8), GradeLevel.grade8);
      expect(GradeLevel.fromInt(12), GradeLevel.grade12);

      expect(GradeLevel.grade6.numericValue, 6);
      expect(GradeLevel.grade8.numericValue, 8);
      expect(GradeLevel.grade12.numericValue, 12);

      expect(GradeLevel.grade6.supportedStreams, contains('general'));
      expect(GradeLevel.grade12.supportedStreams, contains('natural'));
      expect(GradeLevel.grade12.supportedStreams, contains('social'));
    });

    test('retrieves Grade 6 and Grade 8 subject packages from repository',
        () async {
      await repository.initializeSeedData();

      final g6Packages =
          await repository.getPackages(grade: 6, stream: 'general');
      expect(g6Packages.isNotEmpty, isTrue);
      expect(g6Packages.any((p) => p.subjectId == 'math_g6'), isTrue);
      expect(g6Packages.any((p) => p.subjectId == 'science_g6'), isTrue);

      final g8Packages =
          await repository.getPackages(grade: 8, stream: 'general');
      expect(g8Packages.isNotEmpty, isTrue);
      expect(g8Packages.any((p) => p.subjectId == 'math_g8'), isTrue);
      expect(g8Packages.any((p) => p.subjectId == 'science_g8'), isTrue);
    });

    test('retrieves Grade 12 Social Science subjects and questions', () async {
      await repository.initializeSeedData();

      final socialSubjects =
          await repository.getSubjects(grade: 12, stream: 'social');
      expect(socialSubjects.isNotEmpty, isTrue);
      expect(socialSubjects.any((s) => s.id == 'history_g12'), isTrue);
      expect(socialSubjects.any((s) => s.id == 'economics_g12'), isTrue);

      final historyQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'history_g12',
      );
      expect(historyQuestions.isNotEmpty, isTrue);
      expect(
          historyQuestions.first.questionTextEn, contains('Treaty of Wuchale'));
    });

    test(
        'verifies vector diagrams attached to questions across Grade 8 and Grade 12',
        () async {
      await repository.initializeSeedData();

      final g8Questions = await repository.getQuestions(
        grade: 8,
        subjectId: 'math_g8',
      );
      expect(g8Questions.isNotEmpty, isTrue);
      final g8DiagQ = g8Questions.firstWhere((q) => q.vectorDiagram != null);
      expect(g8DiagQ.vectorDiagram!.titleEn, contains('Right-Angled Triangle'));
      expect(g8DiagQ.vectorDiagram!.hotspots.length, 3);
      expect(g8DiagQ.vectorDiagram!.hotspots.first.label, 'A');

      final econQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'economics_g12',
      );
      expect(econQuestions.isNotEmpty, isTrue);
      final econDiagQ =
          econQuestions.firstWhere((q) => q.vectorDiagram != null);
      expect(econDiagQ.vectorDiagram!.hotspots.any((h) => h.label == 'E1'),
          isTrue);
    });
  });
}

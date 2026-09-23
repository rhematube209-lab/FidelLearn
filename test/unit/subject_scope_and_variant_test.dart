import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:fidel_learn/features/subjects/domain/services/curriculum_manifest_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repository;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final String assetKey = utf8.decode(message!.buffer.asUint8List());
      final file = File(assetKey);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return ByteData.view(bytes.buffer);
      }
      return null;
    });

    repository = LocalContentRepository();
    await repository.initializeSeedData();
  });

  group('P0 Launch Matrix & Subject Architecture', () {
    test(
        'Launch matrix contains 9 primary subjects across 10 assessment tracks',
        () {
      const catalog = CurriculumManifestCatalog.allManifests;
      // 10 launch track manifests + 1 supplementary Civics manifest = 11 total
      expect(catalog.length, equals(11));

      final primaryManifests =
          catalog.where((m) => m.scope != SubjectScope.curriculumOnly).toList();
      expect(primaryManifests.length, equals(10));

      // Unique canonical subject IDs across primary manifests
      final uniqueSubjectIds =
          primaryManifests.map((m) => m.canonicalSubjectId).toSet();
      expect(uniqueSubjectIds.length, equals(9),
          reason:
              'Must have exactly 9 unique canonical subjects because Mathematics has 2 tracks');
      expect(
          uniqueSubjectIds,
          containsAll([
            'english_g12',
            'math_g12',
            'aptitude_g12',
            'physics_g12',
            'chemistry_g12',
            'biology_g12',
            'history_g12',
            'geography_g12',
            'economics_g12',
          ]));
    });

    test(
        'Mathematics is modelled as ONE canonical subject with separate variant records',
        () async {
      final math =
          LocalContentRepository.resolveDefaultSubject('math_g12', grade: 12);
      expect(math.id, equals('math_g12'));
      expect(math.code, equals('MATH12'));
      expect(math.scope, equals(SubjectScope.commonExam));
      expect(math.availableVariants.length, equals(2));

      final natVariant = math.resolveVariant('natural');
      expect(natVariant, isNotNull);
      expect(natVariant!.variantCode, equals(ExamVariantCode.naturalScience));
      expect(natVariant.streamEligibility, equals('natural'));

      final socVariant = math.resolveVariant('social');
      expect(socVariant, isNotNull);
      expect(socVariant!.variantCode, equals(ExamVariantCode.socialScience));
      expect(socVariant.streamEligibility, equals('social'));
    });

    test('Common subjects English & Aptitude appear in both streams', () async {
      final natSubjects =
          await repository.getSubjects(grade: 12, stream: 'natural');
      final socSubjects =
          await repository.getSubjects(grade: 12, stream: 'social');

      final natIds = natSubjects.map((s) => s.id).toSet();
      final socIds = socSubjects.map((s) => s.id).toSet();

      expect(natIds, contains('english_g12'));
      expect(socIds, contains('english_g12'));
      expect(natIds, contains('aptitude_g12'));
      expect(socIds, contains('aptitude_g12'));

      // Both streams have access to canonical math_g12
      expect(natIds, contains('math_g12'));
      expect(socIds, contains('math_g12'));
    });

    test('Strict cross-stream question isolation for Mathematics variants',
        () async {
      // Natural Science queries only return Natural variant questions
      final natMathQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'math_g12',
        stream: 'natural',
        examVariant: ExamVariantCode.naturalScience,
      );
      expect(natMathQuestions.isNotEmpty, isTrue);
      for (final q in natMathQuestions) {
        expect(q.examVariant, isNot(equals(ExamVariantCode.socialScience)),
            reason:
                'Natural stream must never receive Social Science math questions');
      }

      // Social Science queries only return Social variant questions
      final socMathQuestions = await repository.getQuestions(
        grade: 12,
        subjectId: 'math_g12',
        stream: 'social',
        examVariant: ExamVariantCode.socialScience,
      );
      expect(socMathQuestions.isNotEmpty, isTrue);
      for (final q in socMathQuestions) {
        expect(q.examVariant, isNot(equals(ExamVariantCode.naturalScience)),
            reason:
                'Social stream must never receive Natural Science math questions');
      }
    });

    test('Civics is preserved as supplementary Grade 12 curriculum', () {
      final civicsManifest =
          CurriculumManifestCatalog.findManifest('civics_g12');
      expect(civicsManifest, isNotNull);
      expect(civicsManifest!.scope, equals(SubjectScope.curriculumOnly));
      expect(civicsManifest.unitsOrDomains.length, equals(11));
      expect(civicsManifest.isSupplementary, isTrue);
    });
  });
}

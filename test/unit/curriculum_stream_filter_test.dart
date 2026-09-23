import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repository;

  setUp(() async {
    // Intercept rootBundle to load JSON seed files from the local filesystem
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

  group('Grade 12 Stream & Launch Subject Isolation', () {
    test(
        'Natural Science returns Math, Biology, Physics, Chemistry and excludes Social subjects',
        () async {
      final subjects =
          await repository.getSubjects(grade: 12, stream: 'natural');
      final names = subjects.map((s) => s.nameEn.toLowerCase()).toList();
      final ids = subjects.map((s) => s.id.toLowerCase()).toList();

      // Must contain core Natural Science subjects
      expect(names.any((n) => n.contains('math')), isTrue);
      expect(names.any((n) => n.contains('bio')), isTrue);
      expect(names.any((n) => n.contains('phys')), isTrue);
      expect(names.any((n) => n.contains('chem')), isTrue);

      // Must strictly exclude Social Science specific subjects
      expect(names.any((n) => n.contains('history')), isFalse);
      expect(names.any((n) => n.contains('geography')), isFalse);
      expect(names.any((n) => n.contains('economics')), isFalse);
      expect(ids.any((id) => id.contains('hist')), isFalse);
      expect(ids.any((id) => id.contains('geo')), isFalse);
      expect(ids.any((id) => id.contains('econ')), isFalse);
    });

    test(
        'Social Science returns Math, History, Geography, Economics and excludes Natural subjects',
        () async {
      final subjects =
          await repository.getSubjects(grade: 12, stream: 'social');
      final names = subjects.map((s) => s.nameEn.toLowerCase()).toList();
      final ids = subjects.map((s) => s.id.toLowerCase()).toList();

      // Must contain core Social Science subjects
      expect(names.any((n) => n.contains('math')), isTrue);
      expect(names.any((n) => n.contains('history')), isTrue);
      expect(names.any((n) => n.contains('geography')), isTrue);
      expect(names.any((n) => n.contains('economics')), isTrue);

      // Must strictly exclude Natural Science specific subjects
      expect(names.any((n) => n.contains('biology')), isFalse);
      expect(names.any((n) => n.contains('physics')), isFalse);
      expect(names.any((n) => n.contains('chemistry')), isFalse);
      expect(ids.any((id) => id.contains('bio')), isFalse);
      expect(ids.any((id) => id.contains('phys')), isFalse);
      expect(ids.any((id) => id.contains('chem')), isFalse);
    });

    test('Packages are properly segmented by stream', () async {
      final naturalPackages =
          await repository.getPackages(grade: 12, stream: 'natural');
      final naturalPackageIds =
          naturalPackages.map((p) => p.packageId).toList();

      expect(naturalPackageIds, contains('pkg_g12_math_nat_2026'));
      expect(naturalPackageIds, contains('pkg_g12_bio_2026'));
      expect(naturalPackageIds, contains('pkg_g12_physics_2026'));
      expect(naturalPackageIds, contains('pkg_g12_chem_2026'));
      expect(naturalPackageIds.contains('pkg_g12_history_2026'), isFalse);
      expect(naturalPackageIds.contains('pkg_g12_geography_2026'), isFalse);

      final socialPackages =
          await repository.getPackages(grade: 12, stream: 'social');
      final socialPackageIds = socialPackages.map((p) => p.packageId).toList();

      expect(socialPackageIds, contains('pkg_g12_history_2026'));
      expect(socialPackageIds, contains('pkg_g12_geography_2026'));
      expect(socialPackageIds, contains('pkg_g12_economics_2026'));
      expect(socialPackageIds, contains('pkg_g12_math_soc_2026'));
      expect(socialPackageIds.contains('pkg_g12_physics_2026'), isFalse);
      expect(socialPackageIds.contains('pkg_g12_bio_2026'), isFalse);
    });

    test(
        'Retrieves verified Grade 12 History questions with bilingual rationales',
        () async {
      final questions =
          await repository.getQuestions(grade: 12, subjectId: 'history_g12');
      expect(questions.isNotEmpty, isTrue);

      final q = questions.first;
      expect(q.subjectId, equals('history_g12'));
      expect(q.choices.length, equals(4));
      expect(q.choices.where((c) => c.isCorrect).length, equals(1));
      expect(q.explanation.solutionTextEn.trim().isNotEmpty, isTrue);
      expect(q.verificationStatus, equals(VerificationStatus.published));
    });

    test(
        'Retrieves verified Grade 12 Geography questions with bilingual rationales',
        () async {
      final questions =
          await repository.getQuestions(grade: 12, subjectId: 'geography_g12');
      expect(questions.isNotEmpty, isTrue);

      final q = questions.first;
      expect(q.subjectId, equals('geography_g12'));
      expect(q.choices.length, equals(4));
      expect(q.choices.where((c) => c.isCorrect).length, equals(1));
      expect(q.explanation.solutionTextEn.trim().isNotEmpty, isTrue);
      expect(q.verificationStatus, equals(VerificationStatus.published));
    });

    test(
        'Retrieves verified Grade 12 Economics questions with bilingual rationales',
        () async {
      final questions =
          await repository.getQuestions(grade: 12, subjectId: 'economics_g12');
      expect(questions.isNotEmpty, isTrue);

      final q = questions.first;
      expect(q.subjectId, equals('economics_g12'));
      expect(q.choices.length, equals(4));
      expect(q.choices.where((c) => c.isCorrect).length, equals(1));
      expect(q.explanation.solutionTextEn.trim().isNotEmpty, isTrue);
      expect(q.verificationStatus, equals(VerificationStatus.published));
    });
  });
}

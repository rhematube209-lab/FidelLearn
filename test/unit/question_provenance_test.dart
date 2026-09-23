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

  group('Question Provenance & Audit Integrity', () {
    test('Official past exam questions have explicit provenance metadata',
        () async {
      final englishQuestions =
          await repository.getQuestions(grade: 12, subjectId: 'english_g12');
      expect(englishQuestions.isNotEmpty, isTrue);

      for (final q in englishQuestions) {
        expect(q.provenance, isNotNull);
        expect(q.provenance!.provenanceType,
            equals(SourceProvenanceType.officialNeaeaPaper));
        expect(q.provenance!.verifiedBy, contains('EAES'));
        expect(q.provenance!.examYear, isNotNull);
        expect(q.provenance!.bookletCode, isNotEmpty);
        expect(q.provenance!.questionNumber, isNotNull);
        expect(q.isAuthoritativeVerifiedPastExam, isTrue);
      }
    });

    test('All published past-exam items have authoritative provenance evidence',
        () async {
      final allQuestions = [
        ...await repository.getQuestions(grade: 12, subjectId: 'english_g12'),
        ...await repository.getQuestions(grade: 12, subjectId: 'aptitude_g12'),
        ...await repository.getQuestions(
            grade: 12, subjectId: 'math_g12', stream: 'social'),
        ...await repository.getQuestions(grade: 12, subjectId: 'history_g12'),
        ...await repository.getQuestions(grade: 12, subjectId: 'geography_g12'),
        ...await repository.getQuestions(grade: 12, subjectId: 'economics_g12'),
      ];

      for (final q in allQuestions) {
        if (q.verificationStatus == VerificationStatus.published) {
          if (q.provenance != null) {
            expect(
              q.provenance!.isAuthoritativePastExam,
              isTrue,
              reason:
                  'Question ${q.id} cannot be published as official ESSLCE without authoritative past exam provenance',
            );
            expect(
              q.provenance!.sourceDocument.isNotEmpty,
              isTrue,
              reason:
                  'Question ${q.id} must cite its authoritative source document',
            );
          }
        }
      }
    });

    test('English comprehension questions link to ReadingPassage stimulus',
        () async {
      final englishQuestions =
          await repository.getQuestions(grade: 12, subjectId: 'english_g12');
      final readingQuestions = englishQuestions
          .where((q) =>
              q.topicId.contains('reading') ||
              (q.skill != null && q.skill!.contains('reading')))
          .toList();

      expect(readingQuestions.isNotEmpty, isTrue);
      for (final q in readingQuestions) {
        expect(q.readingPassage, isNotNull);
        expect(q.readingPassage!.id.isNotEmpty, isTrue);
        expect(q.readingPassage!.title.isNotEmpty, isTrue);
        expect(q.readingPassage!.body.isNotEmpty, isTrue);
      }
    });

    test('Aptitude questions map to cognitive reasoning domains and skills',
        () async {
      final aptQuestions =
          await repository.getQuestions(grade: 12, subjectId: 'aptitude_g12');
      expect(aptQuestions.isNotEmpty, isTrue);

      final verbalQs = aptQuestions
          .where(
              (q) => q.contentDomain?.toLowerCase().contains('verbal') == true)
          .toList();
      final quantQs = aptQuestions
          .where(
              (q) => q.contentDomain?.toLowerCase().contains('quant') == true)
          .toList();

      expect(verbalQs.isNotEmpty, isTrue);
      expect(quantQs.isNotEmpty, isTrue);

      for (final q in aptQuestions) {
        expect(q.skill, isNotNull);
        expect(q.skill!.isNotEmpty, isTrue);
      }
    });
  });
}

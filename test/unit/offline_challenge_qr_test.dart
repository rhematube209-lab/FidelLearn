import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/challenges/domain/services/offline_challenge_qr_service.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';

void main() {
  group('OfflineChallengeQrService Tests', () {
    late OfflineChallengeQrService qrService;

    setUp(() {
      qrService = OfflineChallengeQrService();
    });

    test('encodes and decodes exam attempt into compact QR payload', () {
      final now = DateTime.now();
      final attempt = ExamAttempt(
        id: 'att_test_100',
        userId: 'usr_student_1',
        examId: 'exam_math_g12_model',
        examTitle: 'Grade 12 Mathematics Model Exam',
        subjectId: 'math_g12',
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now,
        durationSeconds: 900,
        totalQuestions: 20,
        score: 18,
        percentage: 90.0,
        correctCount: 18,
        incorrectCount: 2,
        skippedCount: 0,
        isCompleted: true,
        responses: const {
          'q1': UserResponse(
            questionId: 'q1',
            selectedChoiceId: 'c1',
            isCorrect: true,
            timeSpentSeconds: 45,
          ),
          'q2': UserResponse(
            questionId: 'q2',
            selectedChoiceId: 'c3',
            isCorrect: false,
            timeSpentSeconds: 60,
          ),
        },
        syncStatus: 'synced',
      );

      final qrText = qrService.encodeAttemptToQrPayload(
        attempt: attempt,
        studentDisplayName: 'Yohannes Bekele',
      );

      expect(qrText.startsWith('FIDEL_GHOST:v1:'), isTrue);

      final decoded = qrService.decodeQrPayloadToGhost(qrText);
      expect(decoded, isNotNull);
      expect(decoded!.studentDisplayName, 'Yohannes Bekele');
      expect(decoded.score, 18);
      expect(decoded.totalQuestions, 20);
      expect(decoded.durationSeconds, 900);
      expect(decoded.percentage, 90.0);
      expect(decoded.responses.length, 2);
      expect(decoded.responses['q1']?.isCorrect, isTrue);
      expect(decoded.responses['q2']?.isCorrect, isFalse);

      final reconstructedAttempt = decoded.toExamAttempt();
      expect(reconstructedAttempt.score, 18);
      expect(reconstructedAttempt.isCompleted, isTrue);
    });

    test('returns null when parsing invalid or corrupted QR text', () {
      expect(qrService.decodeQrPayloadToGhost('INVALID_PAYLOAD'), isNull);
      expect(
          qrService
              .decodeQrPayloadToGhost('FIDEL_GHOST:v1:corrupted_base64_!@#'),
          isNull);
    });
  });
}

import 'dart:convert';

import '../../../exams/domain/models/exam_models.dart';

class OfflineGhostPayload {
  final String attemptId;
  final String studentDisplayName;
  final String examId;
  final String examTitle;
  final String subjectId;
  final int totalQuestions;
  final int score;
  final double percentage;
  final int durationSeconds;
  final int correctCount;
  final DateTime completedAt;
  final Map<String, UserResponse> responses;

  const OfflineGhostPayload({
    required this.attemptId,
    required this.studentDisplayName,
    required this.examId,
    required this.examTitle,
    required this.subjectId,
    required this.totalQuestions,
    required this.score,
    required this.percentage,
    required this.durationSeconds,
    required this.correctCount,
    required this.completedAt,
    required this.responses,
  });

  ExamAttempt toExamAttempt({String fallbackUserId = 'ghost_peer'}) {
    return ExamAttempt(
      id: attemptId,
      userId: fallbackUserId,
      examId: examId,
      examTitle: examTitle,
      subjectId: subjectId,
      startTime: completedAt.subtract(Duration(seconds: durationSeconds)),
      endTime: completedAt,
      durationSeconds: durationSeconds,
      totalQuestions: totalQuestions,
      score: score,
      percentage: percentage,
      correctCount: correctCount,
      incorrectCount: totalQuestions - correctCount,
      skippedCount: 0,
      isCompleted: true,
      responses: responses,
      syncStatus: 'synced',
    );
  }
}

class OfflineChallengeQrService {
  static const String prefix = 'FIDEL_GHOST:v1:';

  String encodeAttemptToQrPayload({
    required ExamAttempt attempt,
    required String studentDisplayName,
  }) {
    final Map<String, dynamic> compactJson = {
      'aid': attempt.id,
      'name': studentDisplayName,
      'eid': attempt.examId,
      'et': attempt.examTitle,
      'sub': attempt.subjectId,
      'tq': attempt.totalQuestions,
      'sc': attempt.score,
      'pct': attempt.percentage,
      'dur': attempt.durationSeconds,
      'cor': attempt.correctCount,
      'ts': (attempt.endTime ?? DateTime.now()).millisecondsSinceEpoch,
      'res': attempt.responses.map(
        (key, value) => MapEntry(key, {
          'cid': value.selectedChoiceId,
          'ok': value.isCorrect ? 1 : 0,
          'sec': value.timeSpentSeconds,
        }),
      ),
    };

    final jsonString = jsonEncode(compactJson);
    final base64String = base64Url.encode(utf8.encode(jsonString));
    return '$prefix$base64String';
  }

  OfflineGhostPayload? decodeQrPayloadToGhost(String qrText) {
    if (!qrText.startsWith(prefix)) {
      return null;
    }

    try {
      final base64Part = qrText.substring(prefix.length).trim();
      final decodedJsonString = utf8.decode(base64Url.decode(base64Part));
      final Map<String, dynamic> map =
          jsonDecode(decodedJsonString) as Map<String, dynamic>;

      final rawResponses = map['res'] as Map<String, dynamic>? ?? {};
      final Map<String, UserResponse> responses = {};

      rawResponses.forEach((qId, val) {
        if (val is Map<String, dynamic>) {
          responses[qId] = UserResponse(
            questionId: qId,
            selectedChoiceId: val['cid'] as String?,
            isCorrect: (val['ok'] as int? ?? 0) == 1,
            timeSpentSeconds: val['sec'] as int? ?? 0,
          );
        }
      });

      return OfflineGhostPayload(
        attemptId: map['aid'] as String? ?? 'ghost_${DateTime.now().millisecondsSinceEpoch}',
        studentDisplayName: map['name'] as String? ?? 'Peer Student',
        examId: map['eid'] as String? ?? '',
        examTitle: map['et'] as String? ?? 'National Exam Practice',
        subjectId: map['sub'] as String? ?? 'math_g12',
        totalQuestions: map['tq'] as int? ?? 0,
        score: map['sc'] as int? ?? 0,
        percentage: (map['pct'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: map['dur'] as int? ?? 0,
        correctCount: map['cor'] as int? ?? 0,
        completedAt: DateTime.fromMillisecondsSinceEpoch(
          map['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
        responses: responses,
      );
    } catch (_) {
      return null;
    }
  }
}

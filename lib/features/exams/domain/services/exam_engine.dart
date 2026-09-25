import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../models/exam_models.dart';

class ExamEngine {
  ExamEngine._();

  /// Calculates a deterministic SHA-256 fingerprint for the exam composition and content snapshot
  static String calculateIntegrityHash({
    required String examId,
    required String? blueprintVersion,
    required int? seed,
    required List<String> questionIds,
    Map<String, String>? packageSnapshot,
    Map<String, int>? contentVersions,
  }) {
    final payload = [
      examId,
      blueprintVersion ?? 'unversioned',
      seed?.toString() ?? 'none',
      questionIds.join(','),
      packageSnapshot?.entries.map((e) => '${e.key}:${e.value}').join(';') ??
          '',
      contentVersions?.entries.map((e) => '${e.key}:${e.value}').join(';') ??
          '',
    ].join('|');
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Starts a new active attempt with an immutable content snapshot
  static ExamAttempt startAttempt({
    required String attemptId,
    required String userId,
    required Exam exam,
    Map<String, String>? packageSnapshot,
  }) {
    final Map<String, UserResponse> initialResponses = {};
    final questionIds = <String>[];
    final Map<String, int> contentVersions = {};

    for (final q in exam.questions) {
      questionIds.add(q.id);
      contentVersions[q.id] = q.contentVersion;
      initialResponses[q.id] = UserResponse(
        questionId: q.id,
        selectedChoiceId: null,
        isCorrect: false,
        timeSpentSeconds: 0,
        isFlagged: false,
      );
    }

    final resolvedPkgSnapshot = packageSnapshot ??
        {
          if (exam.subjectId != null) exam.subjectId!: '1.0.0',
        };

    final integrityHash = calculateIntegrityHash(
      examId: exam.id,
      blueprintVersion: exam.blueprintVersion,
      seed: exam.simulationSeed,
      questionIds: questionIds,
      packageSnapshot: resolvedPkgSnapshot,
      contentVersions: contentVersions,
    );

    return ExamAttempt(
      id: attemptId,
      userId: userId,
      examId: exam.id,
      examTitle: exam.title,
      subjectId: exam.subjectId ?? 'unknown',
      examMode: exam.examMode,
      sourceType: exam.sourceType,
      examVariant: exam.examVariant,
      blueprintVersion: exam.blueprintVersion,
      simulationSeed: exam.simulationSeed,
      questionOrder: questionIds,
      timeLimitSeconds: exam.isTimed ? exam.timeLimitMinutes * 60 : 0,
      autoSubmitted: false,
      historicalYear: exam.historicalYear,
      timerIntegrityWarning: false,
      packageSnapshot: resolvedPkgSnapshot,
      examIntegrityHash: integrityHash,
      scoringPolicy: 'standard_uniform_v1',
      startTime: DateTime.now(),
      durationSeconds: 0,
      totalQuestions: exam.totalQuestions,
      score: 0,
      percentage: 0.0,
      correctCount: 0,
      incorrectCount: 0,
      skippedCount: exam.totalQuestions,
      isCompleted: false,
      responses: initialResponses,
    );
  }

  /// Records an answer choice for a question
  static ExamAttempt answerQuestion({
    required ExamAttempt currentAttempt,
    required Question question,
    required String choiceId,
    int timeSpentDeltaSeconds = 0,
  }) {
    if (currentAttempt.isCompleted) return currentAttempt;

    final selectedChoice = question.choices.firstWhere(
      (c) => c.id == choiceId,
      orElse: () => question.choices.first,
    );

    final existingResp = currentAttempt.responses[question.id] ??
        UserResponse(questionId: question.id, isCorrect: false);

    final updatedResp = existingResp.copyWith(
      selectedChoiceId: choiceId,
      isCorrect: question.isScorable && selectedChoice.isCorrect,
      timeSpentSeconds: existingResp.timeSpentSeconds + timeSpentDeltaSeconds,
    );

    final updatedMap = Map<String, UserResponse>.from(currentAttempt.responses);
    updatedMap[question.id] = updatedResp;

    return currentAttempt.copyWith(responses: updatedMap);
  }

  /// Toggles question flag for review
  static ExamAttempt toggleFlag({
    required ExamAttempt currentAttempt,
    required String questionId,
  }) {
    final existingResp = currentAttempt.responses[questionId];
    if (existingResp == null) return currentAttempt;

    final updatedResp = existingResp.copyWith(
      isFlagged: !existingResp.isFlagged,
    );
    final updatedMap = Map<String, UserResponse>.from(currentAttempt.responses);
    updatedMap[questionId] = updatedResp;

    return currentAttempt.copyWith(responses: updatedMap);
  }

  /// Submits and calculates final score and metrics
  static ExamAttempt submitAttempt({
    required ExamAttempt currentAttempt,
    required List<Question> questions,
    required int totalDurationSeconds,
  }) {
    if (currentAttempt.isCompleted) return currentAttempt;

    int correct = 0;
    int incorrect = 0;
    int skipped = 0;
    int scorableCount = 0;

    final Map<String, UserResponse> validatedResponses = {};

    for (final q in questions) {
      if (q.isScorable) scorableCount++;
      final resp = currentAttempt.responses[q.id];
      if (resp == null || resp.selectedChoiceId == null) {
        skipped++;
        validatedResponses[q.id] = UserResponse(
          questionId: q.id,
          selectedChoiceId: null,
          isCorrect: false,
          timeSpentSeconds: resp?.timeSpentSeconds ?? 0,
          isFlagged: resp?.isFlagged ?? false,
        );
      } else {
        final selectedChoice = q.choices.firstWhere(
          (c) => c.id == resp.selectedChoiceId,
          orElse: () => q.choices.first,
        );
        final isCorrect = q.isScorable && selectedChoice.isCorrect;
        if (isCorrect) {
          correct++;
        } else {
          if (q.isScorable) {
            incorrect++;
          }
        }
        validatedResponses[q.id] = resp.copyWith(isCorrect: isCorrect);
      }
    }

    final total = scorableCount > 0
        ? scorableCount
        : (questions.isNotEmpty
            ? questions.length
            : currentAttempt.totalQuestions);
    final percentage = total > 0 ? (correct / total) * 100.0 : 0.0;

    return currentAttempt.copyWith(
      endTime: DateTime.now(),
      durationSeconds: totalDurationSeconds,
      score: correct,
      percentage: double.parse(percentage.toStringAsFixed(1)),
      correctCount: correct,
      incorrectCount: incorrect,
      skippedCount: skipped,
      isCompleted: true,
      responses: validatedResponses,
    );
  }
}

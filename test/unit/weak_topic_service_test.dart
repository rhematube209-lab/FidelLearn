import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/progress/domain/services/weak_topic_detector.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  group('WeakTopicDetector & Readiness Tests', () {
    late Map<String, Question> questionMap;
    late Map<String, String> topicTitleMap;

    setUp(() {
      questionMap = {
        'q_limit_1': const Question(
          id: 'q_limit_1',
          grade: 12,
          stream: 'natural',
          subjectId: 'math_g12',
          unitId: 'u2',
          topicId: 'math_limits',
          questionTextEn: 'Limit question 1',
          difficulty: 'medium',
          verificationStatus: VerificationStatus.published,
          sourceName: 'Demo',
          contentVersion: 1,
          choices: [],
          explanation: Explanation(solutionTextEn: 'Exp'),
        ),
        'q_limit_2': const Question(
          id: 'q_limit_2',
          grade: 12,
          stream: 'natural',
          subjectId: 'math_g12',
          unitId: 'u2',
          topicId: 'math_limits',
          questionTextEn: 'Limit question 2',
          difficulty: 'medium',
          verificationStatus: VerificationStatus.published,
          sourceName: 'Demo',
          contentVersion: 1,
          choices: [],
          explanation: Explanation(solutionTextEn: 'Exp'),
        ),
        'q_seq_1': const Question(
          id: 'q_seq_1',
          grade: 12,
          stream: 'natural',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 'math_sequences',
          questionTextEn: 'Seq question 1',
          difficulty: 'easy',
          verificationStatus: VerificationStatus.published,
          sourceName: 'Demo',
          contentVersion: 1,
          choices: [],
          explanation: Explanation(solutionTextEn: 'Exp'),
        ),
      };

      topicTitleMap = {
        'math_limits': 'Limits at Infinity',
        'math_sequences': 'Arithmetic Sequences',
      };
    });

    test('ignores topic with insufficient sample data below threshold', () {
      const detector = WeakTopicDetector(
        minAttemptsThreshold: 3,
        weakAccuracyThreshold: 60.0,
      );

      // Only 1 attempt on limits with incorrect answer
      final attempt = ExamAttempt(
        id: 'att_1',
        userId: 'user_1',
        examId: 'exam_1',
        examTitle: 'Math 1',
        subjectId: 'math_g12',
        startTime: DateTime.now(),
        durationSeconds: 60,
        totalQuestions: 1,
        score: 0,
        percentage: 0.0,
        correctCount: 0,
        incorrectCount: 1,
        skippedCount: 0,
        isCompleted: true,
        responses: const {
          'q_limit_1': UserResponse(
            questionId: 'q_limit_1',
            selectedChoiceId: 'wrong',
            isCorrect: false,
          ),
        },
      );

      final weakTopics = detector.detectWeakTopics(
        completedAttempts: [attempt],
        questionMap: questionMap,
        topicTitleMap: topicTitleMap,
      );

      // Should be empty because minAttemptsThreshold = 3
      expect(weakTopics, isEmpty);
    });

    test('correctly flags weak topic when attempts >= threshold and accuracy < 60%', () {
      const detector = WeakTopicDetector(
        minAttemptsThreshold: 2,
        weakAccuracyThreshold: 60.0,
      );

      // 2 attempts on limits, both wrong (0% accuracy)
      final attempt1 = ExamAttempt(
        id: 'att_1',
        userId: 'user_1',
        examId: 'exam_1',
        examTitle: 'Math 1',
        subjectId: 'math_g12',
        startTime: DateTime.now(),
        durationSeconds: 60,
        totalQuestions: 2,
        score: 0,
        percentage: 0.0,
        correctCount: 0,
        incorrectCount: 2,
        skippedCount: 0,
        isCompleted: true,
        responses: const {
          'q_limit_1': UserResponse(
            questionId: 'q_limit_1',
            selectedChoiceId: 'c_wrong',
            isCorrect: false,
          ),
          'q_limit_2': UserResponse(
            questionId: 'q_limit_2',
            selectedChoiceId: 'c_wrong',
            isCorrect: false,
          ),
        },
      );

      final weakTopics = detector.detectWeakTopics(
        completedAttempts: [attempt1],
        questionMap: questionMap,
        topicTitleMap: topicTitleMap,
      );

      expect(weakTopics.length, 1);
      expect(weakTopics.first.topicId, 'math_limits');
      expect(weakTopics.first.topicTitleEn, 'Limits at Infinity');
      expect(weakTopics.first.accuracyPercentage, 0.0);
      expect(weakTopics.first.urgencyLevel, 'high');
    });

    test('calculateReadinessScore bounds result between 0 and 100 with accurate weights', () {
      final zeroScore = WeakTopicDetector.calculateReadinessScore(
        totalExamsCompleted: 0,
        averageScorePercentage: 0.0,
        weakTopicCount: 0,
        studyStreakDays: 0,
      );
      expect(zeroScore, 0.0);

      final highReadiness = WeakTopicDetector.calculateReadinessScore(
        totalExamsCompleted: 20,
        averageScorePercentage: 90.0,
        weakTopicCount: 0,
        studyStreakDays: 15,
      );
      // 90*0.5 (45) + 25 + 15 - 0 = 85.0
      expect(highReadiness, 85.0);
    });
  });
}

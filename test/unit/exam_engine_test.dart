import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/exams/domain/services/exam_engine.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  group('ExamEngine Scoring & State Machine Tests', () {
    late List<Question> testQuestions;
    late Exam testExam;

    setUp(() {
      testQuestions = [
        const Question(
          id: 'q1',
          grade: 12,
          stream: 'natural',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 't1',
          questionTextEn: 'What is 2 + 2?',
          difficulty: 'easy',
          verificationStatus: VerificationStatus.published,
          sourceName: 'FidelLearn Demo',
          contentVersion: 1,
          choices: [
            AnswerChoice(id: 'c1_a', label: 'A', textEn: '3', isCorrect: false),
            AnswerChoice(id: 'c1_b', label: 'B', textEn: '4', isCorrect: true),
          ],
          explanation: Explanation(solutionTextEn: '2 + 2 = 4'),
        ),
        const Question(
          id: 'q2',
          grade: 12,
          stream: 'natural',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 't1',
          questionTextEn: 'What is 5 * 5?',
          difficulty: 'easy',
          verificationStatus: VerificationStatus.published,
          sourceName: 'FidelLearn Demo',
          contentVersion: 1,
          choices: [
            AnswerChoice(id: 'c2_a', label: 'A', textEn: '25', isCorrect: true),
            AnswerChoice(
              id: 'c2_b',
              label: 'B',
              textEn: '20',
              isCorrect: false,
            ),
          ],
          explanation: Explanation(solutionTextEn: '5 * 5 = 25'),
        ),
      ];

      testExam = Exam(
        id: 'exam_test_1',
        title: 'Math Test',
        examType: ExamType.practice,
        grade: 12,
        stream: 'natural',
        subjectId: 'math_g12',
        timeLimitMinutes: 10,
        totalQuestions: 2,
        questions: testQuestions,
        createdAt: DateTime.now(),
      );
    });

    test('startAttempt initializes clean exam attempt state', () {
      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_1',
        userId: 'user_1',
        exam: testExam,
      );

      expect(attempt.id, 'att_1');
      expect(attempt.totalQuestions, 2);
      expect(attempt.isCompleted, isFalse);
      expect(attempt.score, 0);
      expect(attempt.responses.length, 2);
      expect(attempt.responses['q1']?.selectedChoiceId, isNull);
      expect(attempt.responses['q2']?.selectedChoiceId, isNull);
    });

    test('answerQuestion updates selected choice and correctness', () {
      final initialAttempt = ExamEngine.startAttempt(
        attemptId: 'att_1',
        userId: 'user_1',
        exam: testExam,
      );

      // Answer q1 correctly
      final updated1 = ExamEngine.answerQuestion(
        currentAttempt: initialAttempt,
        question: testQuestions[0],
        choiceId: 'c1_b',
      );

      expect(updated1.responses['q1']?.selectedChoiceId, 'c1_b');
      expect(updated1.responses['q1']?.isCorrect, isTrue);

      // Answer q2 incorrectly
      final updated2 = ExamEngine.answerQuestion(
        currentAttempt: updated1,
        question: testQuestions[1],
        choiceId: 'c2_b',
      );

      expect(updated2.responses['q2']?.selectedChoiceId, 'c2_b');
      expect(updated2.responses['q2']?.isCorrect, isFalse);
    });

    test('toggleFlag correctly toggles question review flag', () {
      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_1',
        userId: 'user_1',
        exam: testExam,
      );

      final flagged = ExamEngine.toggleFlag(
        currentAttempt: attempt,
        questionId: 'q1',
      );
      expect(flagged.responses['q1']?.isFlagged, isTrue);

      final unflagged = ExamEngine.toggleFlag(
        currentAttempt: flagged,
        questionId: 'q1',
      );
      expect(unflagged.responses['q1']?.isFlagged, isFalse);
    });

    test('submitAttempt computes correct percentage, score, and counts', () {
      final initialAttempt = ExamEngine.startAttempt(
        attemptId: 'att_1',
        userId: 'user_1',
        exam: testExam,
      );

      final answeredAttempt = ExamEngine.answerQuestion(
        currentAttempt: initialAttempt,
        question: testQuestions[0],
        choiceId: 'c1_b', // correct
      );
      // q2 left skipped

      final finalAttempt = ExamEngine.submitAttempt(
        currentAttempt: answeredAttempt,
        questions: testQuestions,
        totalDurationSeconds: 120,
      );

      expect(finalAttempt.isCompleted, isTrue);
      expect(finalAttempt.score, 1);
      expect(finalAttempt.correctCount, 1);
      expect(finalAttempt.incorrectCount, 0);
      expect(finalAttempt.skippedCount, 1);
      expect(finalAttempt.percentage, 50.0);
      expect(finalAttempt.durationSeconds, 120);
    });
  });
}

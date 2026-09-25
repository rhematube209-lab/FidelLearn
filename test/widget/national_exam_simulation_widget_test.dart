import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/exams/presentation/screens/exam_runner_screen.dart';
import 'package:fidel_learn/features/exams/presentation/screens/pre_exam_check_screen.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  const testQuestions = [
    Question(
      id: 'sim_q1',
      grade: 12,
      stream: 'natural',
      subjectId: 'math_g12',
      unitId: 'math_nat_u1',
      topicId: 'vectors',
      examVariant: ExamVariantCode.naturalScience,
      questionTextEn:
          'Calculate the magnitude of vector \\vec{v} = 3\\hat{i} + 4\\hat{j}.',
      difficulty: 'medium',
      verificationStatus: VerificationStatus.verified,
      sourceName: 'Official NEAEA Archive',
      contentVersion: 1,
      choices: [
        AnswerChoice(id: 'c1', label: 'A', textEn: '5 units', isCorrect: true),
        AnswerChoice(id: 'c2', label: 'B', textEn: '7 units', isCorrect: false),
        AnswerChoice(
            id: 'c3', label: 'C', textEn: '12 units', isCorrect: false),
        AnswerChoice(
            id: 'c4', label: 'D', textEn: '25 units', isCorrect: false),
      ],
      explanation: Explanation(
        solutionTextEn: '|v| = \\sqrt{3^2 + 4^2} = \\sqrt{9 + 16} = 5',
      ),
    ),
    Question(
      id: 'sim_q2',
      grade: 12,
      stream: 'natural',
      subjectId: 'math_g12',
      unitId: 'math_nat_u2',
      topicId: 'calculus',
      examVariant: ExamVariantCode.naturalScience,
      questionTextEn: 'Find \\lim_{x \\to 0} \\frac{\\sin x}{x}.',
      difficulty: 'easy',
      verificationStatus: VerificationStatus.verified,
      sourceName: 'Official NEAEA Archive',
      contentVersion: 1,
      choices: [
        AnswerChoice(id: 'c1', label: 'A', textEn: '0', isCorrect: false),
        AnswerChoice(id: 'c2', label: 'B', textEn: '1', isCorrect: true),
        AnswerChoice(id: 'c3', label: 'C', textEn: '\\infty', isCorrect: false),
        AnswerChoice(
            id: 'c4', label: 'D', textEn: 'Undefined', isCorrect: false),
      ],
      explanation: Explanation(
        solutionTextEn: 'Standard trigonometric limit evaluates to 1.',
      ),
    ),
  ];

  final testExam = Exam(
    id: 'sim_math_g12_nat_test',
    title: 'ESSLCE Simulation — MATHEMATICS (Natural Science)',
    examType: ExamType.mockFull,
    examMode: ExamMode.nationalSimulation,
    sourceType: ExamSourceType.generatedSimulation,
    grade: 12,
    stream: 'natural',
    subjectId: 'math_g12',
    examVariant: ExamVariantCode.naturalScience,
    blueprintVersion: 'esslce_sim_math_nat_v1',
    simulationSeed: 777,
    timeLimitMinutes: 120,
    totalQuestions: 2,
    questions: testQuestions,
    createdAt: DateTime.now(),
  );

  final testAttempt = ExamAttempt(
    id: 'att_sim_test_1',
    userId: 'student_1',
    examId: testExam.id,
    examTitle: testExam.title,
    subjectId: 'math_g12',
    examMode: ExamMode.nationalSimulation,
    sourceType: ExamSourceType.generatedSimulation,
    examVariant: ExamVariantCode.naturalScience,
    blueprintVersion: 'esslce_sim_math_nat_v1',
    simulationSeed: 777,
    timeLimitSeconds: 7200,
    startTime: DateTime.now(),
    durationSeconds: 0,
    totalQuestions: 2,
    score: 0,
    percentage: 0,
    correctCount: 0,
    incorrectCount: 0,
    skippedCount: 0,
    isCompleted: false,
    responses: const {},
  );

  group('Priority 5 — PreExamCheckScreen Widget Tests', () {
    testWidgets(
        '1. Renders exam specifications, rules, and confirmation dialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PreExamCheckScreen(
              exam: testExam,
              policy: NationalExamPolicy.nationalSimulation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and badges
      expect(find.text('FidelLearn ESSLCE Simulation'), findsOneWidget);
      expect(find.text(testExam.title), findsOneWidget);
      expect(find.text('2 Items'), findsOneWidget);
      expect(find.text('120 Min'), findsOneWidget);
      expect(find.text('100% Ready'), findsOneWidget);

      // Check Rules
      expect(find.text('Examination Rules & Integrity'), findsOneWidget);
      expect(find.text('Start Examination'), findsOneWidget);

      // Tap start button to open confirmation dialog
      await tester.tap(find.text('Start Examination'));
      await tester.pumpAndSettle();

      expect(find.text('Begin National Exam?'), findsOneWidget);
      expect(find.text('I am Ready — Begin'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Begin National Exam?'), findsNothing);
    });
  });

  group('Priority 5 — ExamRunnerScreen National Exam Policy Widget Tests', () {
    testWidgets(
        '2. In strict national exam mode, instant feedback explanations remain completely hidden',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ExamRunnerScreen(
              exam: testExam,
              initialAttempt: testAttempt,
              policy: NationalExamPolicy.nationalSimulation,
              showInstantFeedback: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify question is displayed
      expect(find.textContaining('Calculate the magnitude of vector'),
          findsOneWidget);
      expect(find.text('5 units'), findsOneWidget);
      expect(find.text('7 units'), findsOneWidget);

      // Tap option choice 'A'
      await tester.tap(find.text('5 units'));
      await tester.pumpAndSettle();

      // VERIFY: Instant explanation card and solution text MUST NOT appear
      expect(find.textContaining('|v| = \\sqrt{3^2 + 4^2}'), findsNothing);
      expect(find.text('Explanation'), findsNothing);
      expect(find.text('Solution & Explanation'), findsNothing);
    });
  });
}

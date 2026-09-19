import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/exams/data/repositories/local_exam_repository.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/exams/domain/services/exam_engine.dart';
import 'package:fidel_learn/features/exams/presentation/screens/exam_runner_screen.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleQuestions = [
    const Question(
      id: 'q_bio_1',
      grade: 12,
      stream: 'natural',
      subjectId: 'biology_g12',
      unitId: 'u1',
      topicId: 't1',
      examYear: 2013,
      questionTextEn:
          'Which one of the following is true about the importance of Lucy in resolving debates about human evolution?',
      difficulty: 'easy',
      verificationStatus: VerificationStatus.published,
      sourceName: 'ESSLCE 2013',
      contentVersion: 1,
      choices: [
        AnswerChoice(
          id: 'c1',
          label: 'A',
          textEn: 'Big brains came before bipedalism.',
          isCorrect: false,
        ),
        AnswerChoice(
          id: 'c2',
          label: 'B',
          textEn: 'Lucy had a brain size of 1.8% of her body mass.',
          isCorrect: false,
        ),
        AnswerChoice(
          id: 'c3',
          label: 'C',
          textEn: 'Bipedalism came before big brains.',
          isCorrect: true,
        ),
        AnswerChoice(
          id: 'c4',
          label: 'D',
          textEn: 'Lucy was partially an arboreal primate.',
          isCorrect: false,
        ),
      ],
      explanation: Explanation(
        solutionTextEn:
            'Lucy proved that bipedalism evolved before large brain expansion.',
        simplerExplanationEn: 'Bipedalism happened first.',
        keyConcept: 'Human evolution milestones',
      ),
    ),
    const Question(
      id: 'q_bio_2',
      grade: 12,
      stream: 'natural',
      subjectId: 'biology_g12',
      unitId: 'u1',
      topicId: 't1',
      examYear: 2013,
      questionTextEn:
          'What is the primary cellular organelle responsible for ATP generation during aerobic respiration?',
      difficulty: 'medium',
      verificationStatus: VerificationStatus.published,
      sourceName: 'ESSLCE 2013',
      contentVersion: 1,
      choices: [
        AnswerChoice(
          id: 'c2_1',
          label: 'A',
          textEn: 'Ribosome',
          isCorrect: false,
        ),
        AnswerChoice(
          id: 'c2_2',
          label: 'B',
          textEn: 'Mitochondrion',
          isCorrect: true,
        ),
      ],
      explanation: Explanation(
        solutionTextEn: 'The mitochondrion is the powerhouse of the cell.',
        simplerExplanationEn: 'Mitochondria make ATP.',
        keyConcept: 'Cellular respiration',
      ),
    ),
  ];

  final sampleExam = Exam(
    id: 'exam_bio_2013',
    title: 'Biology 2013 E.C. National Exam',
    examType: ExamType.mockFull,
    subjectId: 'biology_g12',
    grade: 12,
    stream: 'natural',
    timeLimitMinutes: 120,
    totalQuestions: sampleQuestions.length,
    questions: sampleQuestions,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createSubjectUnderTest() {
    final initialAttempt = ExamEngine.startAttempt(
      attemptId: 'attempt_test_1',
      userId: 'test_student_1',
      exam: sampleExam,
    );

    final storage = AuthSessionStorage();
    final mockUser = UserProfile(
      id: 'test_student_1',
      phoneNumber: '+251911000000',
      displayName: 'Abebe Bikila',
      role: UserRole.student,
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      createdAt: DateTime(2026, 1, 1),
    );

    final authRepo = MockAuthRepository(
      sessionStorage: storage,
      initialUser: mockUser,
    );

    final examRepo = LocalExamRepository();

    return ProviderScope(
      overrides: [
        authSessionStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(authRepo),
        examRepositoryProvider.overrideWithValue(examRepo),
      ],
      child: MaterialApp(
        home: ExamRunnerScreen(
          exam: sampleExam,
          initialAttempt: initialAttempt,
        ),
      ),
    );
  }

  testWidgets('ExamRunnerScreen renders simplified header and working footer',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubjectUnderTest());
    await tester.pumpAndSettle();

    // 1. Check Simplified Header
    // Back button
    expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);
    // Timer pill badge (e.g. 119:59 or 120:00)
    expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    expect(find.textContaining(':'), findsWidgets);
    // Flag action
    expect(find.byIcon(Icons.outlined_flag), findsOneWidget);
    // Grid action
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    // Finish Exam button in header
    expect(find.widgetWithText(ElevatedButton, 'Finish Exam'), findsOneWidget);

    // 2. Check Question Statement Card
    expect(find.text('DIFFICULTY: EASY'), findsOneWidget);
    expect(find.text('ESSLCE 2013 E.C.'), findsOneWidget);
    expect(
      find.textContaining('importance of Lucy in resolving debates'),
      findsOneWidget,
    );
    expect(find.text('Select the single best answer:'), findsOneWidget);

    // 3. Check Choices
    expect(find.text('Big brains came before bipedalism.'), findsOneWidget);
    expect(find.text('Bipedalism came before big brains.'), findsOneWidget);

    // 4. Check Working Footer
    // Previous button should be disabled on Question 1
    final prevButtonFinder =
        find.widgetWithText(OutlinedButton, 'Previous');
    expect(prevButtonFinder, findsOneWidget);
    final OutlinedButton prevButton = tester.widget(prevButtonFinder);
    expect(prevButton.onPressed, isNull);

    // Centered question counter should show "1/2"
    expect(find.text('1/2'), findsOneWidget);

    // Next Question button
    final nextButtonFinder =
        find.widgetWithText(ElevatedButton, 'Next Question');
    expect(nextButtonFinder, findsOneWidget);

    // 5. Select a choice
    await tester.tap(find.text('Bipedalism came before big brains.'));
    await tester.pumpAndSettle();

    // 6. Tap Next Question -> should navigate to Question 2
    await tester.tap(nextButtonFinder);
    await tester.pumpAndSettle();

    // Now question 2 is active
    expect(find.text('DIFFICULTY: MEDIUM'), findsOneWidget);
    expect(
      find.textContaining('ATP generation during aerobic respiration'),
      findsOneWidget,
    );

    // Footer question counter should now be "2/2"
    expect(find.text('2/2'), findsOneWidget);

    // On question 2 (last question), Next Question becomes Finish Exam
    expect(find.widgetWithText(ElevatedButton, 'Finish Exam'), findsNWidgets(2));

    // Previous button should now be enabled
    final OutlinedButton prevButtonQ2 =
        tester.widget(find.widgetWithText(OutlinedButton, 'Previous'));
    expect(prevButtonQ2.onPressed, isNotNull);

    // 7. Test Footer Question Counter Interactivity (Tap to open Jump Picker)
    await tester.tap(find.text('2/2'));
    await tester.pumpAndSettle();

    // Question Navigator Bottom Sheet should appear
    expect(find.text('Question Navigator'), findsOneWidget);
    expect(find.textContaining('Answered'), findsWidgets);

    // Tap Question 1 in the jump picker to jump back
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();

    // We should be back on Question 1
    expect(find.text('1/2'), findsOneWidget);
    expect(
      find.textContaining('importance of Lucy in resolving debates'),
      findsOneWidget,
    );
  });
}

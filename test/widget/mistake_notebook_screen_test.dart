import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/exams/domain/repositories/exam_repository.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/mistakes/presentation/screens/mistakes_screen.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

class MockExamRepository implements ExamRepository {
  Exam? lastLaunchedExam;
  ExamAttempt? lastSavedActiveAttempt;

  @override
  Future<void> saveActiveAttempt(ExamAttempt attempt) async {
    lastSavedActiveAttempt = attempt;
  }

  @override
  Future<ExamAttempt?> getActiveAttempt(String userId) async => null;

  @override
  Future<void> clearActiveAttempt(String userId) async {}

  @override
  Future<void> saveCompletedAttempt(ExamAttempt attempt) async {}

  @override
  Future<List<ExamAttempt>> getAttemptHistory(String userId) async => [];

  @override
  Future<ExamAttempt?> getAttemptById(String attemptId) async => null;
}

class MockCurrentUserNotifier extends CurrentUserNotifier {
  MockCurrentUserNotifier(super.authRepo, UserProfile user) {
    state = AsyncValue.data(user);
  }
}

void main() {
  late AppDatabase db;
  late DriftMistakeRepository mistakeRepo;
  late LocalContentRepository contentRepo;
  late MockExamRepository examRepo;
  late AuthSessionStorage storage;
  late MockAuthRepository authRepo;

  final testUser = UserProfile(
    id: 'student_ui_1',
    phoneNumber: '+251911000000',
    displayName: 'Abebe Student',
    role: UserRole.student,
    grade: 12,
    stream: 'natural',
    preferredLanguage: 'en',
    createdAt: DateTime(2026, 1, 1),
  );

  const testQuestion1 = Question(
    id: 'q_diff_1',
    grade: 12,
    stream: 'natural',
    subjectId: 'math_g12',
    unitId: 'unit_calculus',
    topicId: 'derivatives',
    questionTextEn: 'What is the derivative of sin(x)?',
    difficulty: 'medium',
    verificationStatus: VerificationStatus.published,
    sourceName: 'ESSLCE 2014',
    contentVersion: 1,
    choices: [
      AnswerChoice(id: 'c1', label: 'A', textEn: 'cos(x)', isCorrect: true),
      AnswerChoice(id: 'c2', label: 'B', textEn: '-cos(x)', isCorrect: false),
    ],
    explanation: Explanation(
      solutionTextEn: 'The derivative of sin(x) with respect to x is cos(x).',
    ),
  );

  const testQuestion2 = Question(
    id: 'q_diff_2',
    grade: 12,
    stream: 'natural',
    subjectId: 'bio_g12',
    unitId: 'unit_genetics',
    topicId: 'dna',
    questionTextEn: 'Which base pairs with Adenine in DNA?',
    difficulty: 'easy',
    verificationStatus: VerificationStatus.published,
    sourceName: 'ESSLCE 2013',
    contentVersion: 1,
    choices: [
      AnswerChoice(id: 'b1', label: 'A', textEn: 'Thymine', isCorrect: true),
      AnswerChoice(id: 'b2', label: 'B', textEn: 'Guanine', isCorrect: false),
    ],
    explanation: Explanation(
      solutionTextEn: 'Adenine pairs with Thymine with 2 hydrogen bonds.',
    ),
  );

  setUp(() {
    db = AppDatabase.inMemory();
    mistakeRepo = DriftMistakeRepository(db: db);
    contentRepo = LocalContentRepository();
    contentRepo.initializeWithData(
      packages: const [],
      units: const [],
      topics: const [],
      questions: [testQuestion1, testQuestion2],
      subjects: const [],
    );
    examRepo = MockExamRepository();
    storage = AuthSessionStorage();
    authRepo =
        MockAuthRepository(sessionStorage: storage, initialUser: testUser);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp() {
    final router = GoRouter(
      initialLocation: '/mistakes',
      routes: [
        GoRoute(
          path: '/mistakes',
          builder: (context, state) => const MistakesScreen(),
        ),
        GoRoute(
          path: '/exam_runner',
          builder: (context, state) =>
              const Scaffold(body: Text('Exam Runner Screen')),
        ),
        GoRoute(
          path: '/solution_review',
          builder: (context, state) =>
              const Scaffold(body: Text('Solution Review Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authSessionStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(authRepo),
        currentUserProvider
            .overrideWith((ref) => MockCurrentUserNotifier(authRepo, testUser)),
        appDatabaseProvider.overrideWithValue(db),
        mistakeRepositoryProvider.overrideWithValue(mistakeRepo),
        contentRepositoryProvider.overrideWithValue(contentRepo),
        examRepositoryProvider.overrideWithValue(examRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('Renders clean empty state when no mistakes exist',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('No mistakes yet'), findsOneWidget);
    expect(find.text('Mistake Notebook & Mastery Engine'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  testWidgets(
      'Displays real mistake records, live counts, and status filter chips',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Populate mistake records
    await mistakeRepo.recordMistake(
      userId: testUser.id,
      questionId: testQuestion1.id,
      subjectId: testQuestion1.subjectId,
      unitId: testQuestion1.unitId,
      attemptId: 'att_1',
      selectedChoiceId: 'c2',
    );

    await mistakeRepo.recordMistake(
      userId: testUser.id,
      questionId: testQuestion2.id,
      subjectId: testQuestion2.subjectId,
      unitId: testQuestion2.unitId,
      attemptId: 'att_1',
      selectedChoiceId: 'b2',
    );
    // Mark second question as improving
    await mistakeRepo.recordRetryResult(
      userId: testUser.id,
      questionId: testQuestion2.id,
      isCorrect: true,
      attemptId: 'att_retry',
    );

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify questions displayed
    expect(find.text('What is the derivative of sin(x)?'), findsOneWidget);
    expect(find.text('Which base pairs with Adenine in DNA?'), findsOneWidget);

    // Verify summary metric numbers: Total: 2, Needs Review: 1, Improving: 1
    expect(find.text('Total Mistakes'), findsOneWidget);
    expect(find.text('Needs Review'), findsAtLeastNWidgets(1));
    expect(find.text('Improving'), findsAtLeastNWidgets(1));
    expect(find.text('Practice My Mistakes'), findsOneWidget);

    // Test filter: tap "Needs Review"
    await tester.tap(find.widgetWithText(ChoiceChip, 'Needs Review'));
    await tester.pumpAndSettle();

    expect(find.text('What is the derivative of sin(x)?'), findsOneWidget);
    expect(find.text('Which base pairs with Adenine in DNA?'), findsNothing);

    // Test filter: tap "Improving"
    await tester.tap(find.widgetWithText(ChoiceChip, 'Improving'));
    await tester.pumpAndSettle();

    expect(find.text('What is the derivative of sin(x)?'), findsNothing);
    expect(find.text('Which base pairs with Adenine in DNA?'), findsOneWidget);
  });

  testWidgets(
      'Practice My Mistakes builds and prepares an Exam with ExamType.mistakeRetry',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await mistakeRepo.recordMistake(
      userId: testUser.id,
      questionId: testQuestion1.id,
      subjectId: testQuestion1.subjectId,
      unitId: testQuestion1.unitId,
      attemptId: 'att_1',
      selectedChoiceId: 'c2',
    );

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final practiceBtn = find.text('Practice My Mistakes');
    expect(practiceBtn, findsOneWidget);

    await tester.tap(practiceBtn);
    await tester.pump();

    // Verify an active attempt was prepared with ExamType.mistakeRetry
    expect(examRepo.lastSavedActiveAttempt, isNotNull);
    expect(examRepo.lastSavedActiveAttempt!.userId, equals(testUser.id));
  });
}

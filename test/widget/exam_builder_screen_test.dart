import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/bookmarks/data/repositories/local_bookmark_repository.dart';
import 'package:fidel_learn/features/exams/data/repositories/local_exam_repository.dart';
import 'package:fidel_learn/features/exams/presentation/screens/exam_builder_screen.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/local_mistake_repository.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('ExamBuilderScreen UI Specification Tests', () {
    testWidgets('renders all custom national exam practice UI sections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: LocalContentRepository.getAllDefaultSubjects(grade: 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Edge-to-Edge Hero Card (Corner Back Button & MoE Verification Badge)
      expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);
      expect(find.text('MoE Verified'), findsOneWidget);

      // Page Title & Mode Switcher
      expect(find.text('Custom Exam Practice'), findsOneWidget);
      expect(find.text('EUEE'), findsOneWidget);
      expect(find.text('Self-Paced'), findsOneWidget);
      expect(find.text('Timed Exam'), findsOneWidget);

      // Step 1: Curriculum Scope
      expect(find.text('Curriculum Scope'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Target Grade Level'), findsOneWidget);
      expect(find.text('Unit Coverage'), findsOneWidget);

      // Step 2: Past Papers Archive
      expect(find.text('Past Papers'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Year Range'), findsOneWidget);
      expect(find.text('Single Year'), findsOneWidget);
      expect(find.text('From Year'), findsOneWidget);
      expect(find.text('To Year'), findsOneWidget);
      expect(find.text('Recent (2015-2017)'), findsOneWidget);
      expect(find.text('5-Year Archive'), findsOneWidget);

      // Step 3 / Parameters & Summary
      expect(find.text('Exam Parameters'), findsOneWidget);
      expect(find.text('Your Practice'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);

      // Sticky CTA & Offline Badges
      expect(find.text('Start Practice Exam'), findsOneWidget);
      expect(find.text('Available offline'), findsOneWidget);
      expect(find.text('Auto-saved to device'), findsOneWidget);

      // 4-Tab Bottom Nav Bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('switching mode to Timed Exam updates state and CTA',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: LocalContentRepository.getAllDefaultSubjects(grade: 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Timed Exam
      await tester.tap(find.text('Timed Exam'));
      await tester.pumpAndSettle();

      // Verify Timed CTA and Time Limit Slider
      expect(find.text('Start Timed Mock Exam'), findsOneWidget);
      expect(find.text('Time Limit'), findsOneWidget);
    });

    testWidgets(
        'adapts branding and pre-selects Mathematics when arriving from math_g12',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: const [
          Subject(
            id: 'math_g12',
            code: 'MATH12',
            nameEn: 'Mathematics',
            nameAm: 'ሒሳብ',
            grade: 12,
            stream: 'natural',
            sortOrder: 1,
          ),
          Subject(
            id: 'biology_g12',
            code: 'BIO12',
            nameEn: 'Biology',
            nameAm: 'ሥነ-ህይወት',
            grade: 12,
            stream: 'natural',
            sortOrder: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'math_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Mathematics branding and emblem
      expect(find.text('Mathematics'), findsWidgets);
      expect(find.text('∑'), findsWidgets);
    });

    testWidgets(
        'adapts branding and pre-selects Biology when arriving from biology_g12',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: const [
          Subject(
            id: 'math_g12',
            code: 'MATH12',
            nameEn: 'Mathematics',
            nameAm: 'ሒሳብ',
            grade: 12,
            stream: 'natural',
            sortOrder: 1,
          ),
          Subject(
            id: 'biology_g12',
            code: 'BIO12',
            nameEn: 'Biology',
            nameAm: 'ሥነ-ህይወት',
            grade: 12,
            stream: 'natural',
            sortOrder: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'biology_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Biology branding and emblem
      expect(find.text('Biology'), findsWidgets);
      expect(find.text('🧬'), findsWidgets);
    });

    testWidgets(
        'adapts branding and pre-selects Physics when arriving from physics_g12',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: LocalContentRepository.getAllDefaultSubjects(grade: 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'physics_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Physics branding and emblem
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('⚡'), findsWidgets);
    });

    testWidgets(
        'adapts branding and pre-selects Chemistry when arriving from chemistry_g12',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: LocalContentRepository.getAllDefaultSubjects(grade: 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'chemistry_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Chemistry branding and emblem
      expect(find.text('Chemistry'), findsWidgets);
      expect(find.text('🧪'), findsWidgets);
    });

    testWidgets(
        'adapts branding to History when arriving from history_g12 even if user is natural stream',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: LocalContentRepository.getAllDefaultSubjects(grade: 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'history_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify History branding and emblem
      expect(find.text('History'), findsWidgets);
      expect(find.text('🏛️'), findsWidgets);
    });

    testWidgets(
        'dynamically updates subject branding when widget initialSubjectId updates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Abebe Bikila',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );

      final authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: LocalContentRepository.getAllDefaultSubjects(grade: 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'biology_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Biology'), findsWidgets);
      expect(find.text('🧬'), findsWidgets);

      // Now update widget in-place to Physics
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'physics_g12'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('⚡'), findsWidgets);
    });
  });
}

import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/exams/presentation/screens/subject_exams_hub_screen.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SubjectExamsHubScreen renders previous years exams and custom builder option',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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

    final mockRepo = LocalContentRepository();
    mockRepo.initializeWithData(
      packages: const [],
      units: const [],
      topics: const [],
      questions: const [],
      subjects: [
        const Subject(
          id: 'math_g12',
          code: 'MATH12',
          nameEn: 'Mathematics',
          nameAm: 'ሒሳብ',
          grade: 12,
          stream: 'natural',
          sortOrder: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(authRepo),
          contentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: SubjectExamsHubScreen(subjectId: 'math_g12'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Check Header
    expect(find.textContaining('Mathematics'), findsWidgets);
    expect(find.textContaining('Grade 12'), findsWidgets);

    // 2. Check Pathway B: Fully Customize Practice CTA
    expect(find.text('Fully Customize Practice'), findsOneWidget);
    expect(find.text('Build'), findsOneWidget);

    // 3. Check Pathway A: Previous Years National Exams
    expect(find.text('Previous Years National Exams'), findsOneWidget);
    expect(find.text('2016 E.C.'), findsOneWidget);
    expect(find.text('2015 E.C.'), findsOneWidget);
    expect(find.text('2014 E.C.'), findsOneWidget);
    expect(find.text('LATEST'), findsOneWidget);
    expect(find.text('Start Exam'), findsWidgets);
    expect(find.text('Download (1.8MB)'), findsWidgets);

    // 4. Check Offline Sync Bar & Batch Download button
    expect(find.textContaining('ready offline'), findsOneWidget);
    expect(find.textContaining('Download All'), findsOneWidget);

    // 5. Check Timer Toggle
    expect(find.text('Timed (120m)'), findsOneWidget);
    expect(find.text('Untimed'), findsOneWidget);

    // Switch to Untimed
    await tester.tap(find.text('Untimed'));
    await tester.pumpAndSettle();
    expect(find.text('Untimed'), findsWidgets);
  });

  testWidgets('SubjectExamsHubScreen downloading past exam transitions card to Offline Ready',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = AuthSessionStorage();
    final mockUser = UserProfile(
      id: 'test_student_2',
      phoneNumber: '+251911000001',
      displayName: 'Derartu Tulu',
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

    final mockRepo = LocalContentRepository();
    mockRepo.initializeWithData(
      packages: const [],
      units: const [],
      topics: const [],
      questions: const [],
      subjects: [
        const Subject(
          id: 'physics_g12',
          code: 'PHYS12',
          nameEn: 'Physics',
          nameAm: 'ፊዚክስ',
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
          contentRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: SubjectExamsHubScreen(subjectId: 'physics_g12'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial state: at least one Download (1.8MB) button exists
    final downloadButtons = find.text('Download (1.8MB)');
    expect(downloadButtons, findsWidgets);

    // Tap the first download button (for 2015 E.C.)
    await tester.tap(downloadButtons.first);
    await tester.pump(); // Enter downloading state

    // Advance time for simulated download completion
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify success snackbar notification
    expect(find.textContaining('downloaded & verified for offline practice'), findsOneWidget);
  });
}

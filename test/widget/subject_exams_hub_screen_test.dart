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
  testWidgets(
      'SubjectExamsHubScreen renders separate Download buttons initially',
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

    // 1. Check Header & Navigation embedded in Hero Card
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsWidgets);
    expect(find.textContaining('Mathematics'), findsWidgets);
    expect(find.textContaining('Grade 12'), findsWidgets);
    expect(find.text('Official Years'), findsOneWidget);
    expect(find.text('Verified Questions'), findsOneWidget);
    expect(find.text('Completed Tests'), findsOneWidget);

    // 2. Check Pathway B: Fully Customize Practice CTA
    expect(find.text('Fully Customize Practice'), findsOneWidget);
    expect(
      find.text(
          'Select specific year, syllabus units & question count on your own'),
      findsOneWidget,
    );
    expect(find.text('Build'), findsOneWidget);

    // 3. Check Pathway A: Previous Years National Exams
    expect(find.text('Previous Years National Exams'), findsOneWidget);
    expect(
      find.text('Practice complete official exams by selecting a year.'),
      findsOneWidget,
    );
    expect(find.text('2016 E.C.'), findsOneWidget);
    expect(find.text('2015 E.C.'), findsOneWidget);
    expect(find.text('2014 E.C.'), findsOneWidget);
    expect(find.text('LATEST'), findsOneWidget);

    // Each exam starts with separate Download button
    expect(find.text('Download'), findsNWidgets(6));
    expect(find.text('Start Exam'), findsNothing);

    // 4. Check Timer Toggle
    expect(find.text('Timed (120m)'), findsOneWidget);
    expect(find.text('Untimed'), findsOneWidget);

    // Switch to Untimed
    await tester.tap(find.text('Untimed'));
    await tester.pumpAndSettle();
    expect(find.text('Untimed'), findsWidgets);
  });

  testWidgets(
      'Tapping Download on an exam year downloads it and transitions button to Start Exam',
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
          id: 'chem_g12',
          code: 'CHEM12',
          nameEn: 'Chemistry',
          nameAm: 'ኬሚስትሪ',
          grade: 12,
          stream: 'natural',
          sortOrder: 4,
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
          home: SubjectExamsHubScreen(subjectId: 'chem_g12'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Chemistry 2013, 2014, 2015, and 2016 are bundled as pre-downloaded verified offline archives.
    // Verified archives show 'Start (N Qs)' labels, not 'Start Exam'.
    // So 2 years remain as 'Download' (2012, 2011)
    // and 4 years show 'Start (80 Qs)' / 'Start (78 Qs)' / 'Start (70 Qs)' (2016, 2015, 2014, 2013 verified archives).
    expect(find.text('Download'), findsNWidgets(2));
    expect(find.textContaining('Start ('), findsNWidgets(4));
    expect(find.text('Start Exam'), findsNothing);

    // Tap the first download button (for 2012 E.C.)
    await tester.tap(find.text('Download').first);
    await tester.pump(); // Enter downloading state

    // Advance time for simulated download completion
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 2012 is a generic (non-verified-archive) year: shows 'Start Exam'
    expect(find.text('Start Exam'), findsOneWidget);
    // Still 4 verified archives showing 'Start (N Qs)'
    expect(find.textContaining('Start ('), findsNWidgets(4));
    expect(find.text('Download'), findsNWidgets(1));

    // Verify success snackbar notification
    expect(find.textContaining('downloaded & verified for offline practice'),
        findsOneWidget);
  });

  testWidgets(
      'SubjectExamsHubScreen displays Booklet 12 • 100 Qs for Biology 2013 E.C.',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = AuthSessionStorage();
    final mockUser = UserProfile(
      id: 'test_student_bio',
      phoneNumber: '+251911000000',
      displayName: 'Aster Aweke',
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
          id: 'biology_g12',
          code: 'BIO12',
          nameEn: 'Biology',
          nameAm: 'ባዮሎጂ',
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
          home: SubjectExamsHubScreen(subjectId: 'bio_g12'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Biology 2013 card specifically shows 'Booklet 12 • 100 Qs'
    expect(find.text('Booklet 12 • 100 Qs'), findsOneWidget);
    expect(find.text('2013 E.C.'), findsOneWidget);
  });

  testWidgets(
      'Tapping Start Exam opens Official Briefing Dialog with General Information table and 2 feedback options',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = AuthSessionStorage();
    final mockUser = UserProfile(
      id: 'test_student_dialog',
      phoneNumber: '+251911000000',
      displayName: 'Kenisa Bekele',
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
          id: 'biology_g12',
          code: 'BIO12',
          nameEn: 'Biology',
          nameAm: 'ባዮሎጂ',
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
          home: SubjectExamsHubScreen(subjectId: 'bio_g12'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Biology 2013 E.C. is pre-downloaded and verified offline!
    final startExamBtn = find.widgetWithText(ElevatedButton, 'Start (100 Qs)');
    expect(startExamBtn, findsWidgets);

    // 2. Tap 'Start (100 Qs)' to open the Official Briefing Dialog
    await tester.ensureVisible(startExamBtn.first);
    await tester.pumpAndSettle();
    await tester.tap(startExamBtn.first);
    await tester.pumpAndSettle();

    // 3. Verify Official ESSLCE Header
    expect(
      find.textContaining('ETHIOPIAN SECONDARY SCHOOL'),
      findsOneWidget,
    );
    expect(
      find.textContaining('LEAVING CERTIFICATE EXAMINATION'),
      findsOneWidget,
    );
    expect(
      find.text('Biology for Natural Science Stream'),
      findsOneWidget,
    );
    expect(
      find.text(
          '2013 E.C. / 2020–2021 G.C. — 100 Questions with Correct Answers'),
      findsOneWidget,
    );

    // 5. Verify Official Specification Table (Matching user's attached picture)
    expect(find.text('Number of Items: 100'), findsOneWidget);
    expect(find.text('Booklet Code: 12'), findsOneWidget);
    expect(find.text('Subject Code: 06'), findsOneWidget);
    expect(find.text('Time Allowed: 2 Hours'), findsOneWidget);
    expect(find.text('Format: Questions, options, answers'), findsOneWidget);

    // 6. Verify the Two Answer Display Options
    expect(
      find.text('Show answer immediately after choice is selected'),
      findsOneWidget,
    );
    expect(
      find.text('Show answer after finishing all questions'),
      findsOneWidget,
    );

    // 7. Verify switching feedback modes works
    await tester
        .tap(find.text('Show answer immediately after choice is selected'));
    await tester.pumpAndSettle();

    // 8. Verify Start Exam CTA is present inside dialog
    expect(find.text('Start Exam Now'), findsOneWidget);
  });

  testWidgets(
      'Physics 2014 E.C. starts 32-question exam from grid and shows Reference Constants in briefing dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final storage = AuthSessionStorage();
    final mockUser = UserProfile(
      id: 'test_student_phys',
      phoneNumber: '+251911000000',
      displayName: 'Haile Gebrselassie',
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
          sortOrder: 3,
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

    // 1. Verify Unnecessary Hero Spotlight Card is REMOVED
    expect(find.text('OFFICIAL VERIFIED EXAM'), findsNothing);

    // 2. In grid, 2014 E.C. is pinned with 'OFFICIAL 32 Qs' badge and 'Start (32 Qs)' button
    expect(find.text('OFFICIAL 32 Qs'), findsOneWidget);
    final startBtn = find.widgetWithText(ElevatedButton, 'Start (32 Qs)');
    expect(startBtn, findsOneWidget);

    // 3. Tap 'Start (32 Qs)' to open the Official Briefing Dialog
    await tester.ensureVisible(startBtn);
    await tester.pumpAndSettle();
    await tester.tap(startBtn);
    await tester.pumpAndSettle();

    // 4. Verify briefing dialog displays specifications and official Reference Constants
    expect(find.text('Physics for Natural Science Stream'), findsOneWidget);
    expect(find.text('Number of Items: 32'), findsOneWidget);
    expect(find.text('Booklet Code: 11'), findsOneWidget);
    expect(find.text('Time Allowed: 1 Hour 15 Min'), findsOneWidget);

    // 5. Verify official Reference Constants section from Document Page 1
    expect(find.text('Reference Constants'), findsOneWidget);
    expect(find.text('PAGE 1 SPEC'), findsOneWidget);
    expect(find.text('Acceleration due to gravity'), findsOneWidget);
    expect(find.text('Mass of the Earth'), findsOneWidget);
    expect(find.text('Charge of electron'), findsOneWidget);
    expect(
        find.textContaining('Trig: sin 30° = cos 60° = 0.5'), findsOneWidget);

    // 6. Verify Start Exam CTA
    expect(find.text('Start Exam Now'), findsOneWidget);
  });
}

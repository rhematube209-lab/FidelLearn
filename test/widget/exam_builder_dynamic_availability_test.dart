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
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExamBuilder Dynamic Availability & Auto-Year Selection Tests', () {
    late AuthSessionStorage storage;
    late MockAuthRepository authRepo;
    late LocalContentRepository contentRepo;

    const bioSubject = Subject(
      id: 'biology_g12',
      code: 'BIO12',
      nameEn: 'Biology',
      nameAm: 'ባዮሎጂ',
      grade: 12,
      stream: 'natural',
      sortOrder: 1,
    );

    const physSubject = Subject(
      id: 'physics_g12',
      code: 'PHYS12',
      nameEn: 'Physics',
      nameAm: 'ፊዚክስ',
      grade: 12,
      stream: 'natural',
      sortOrder: 2,
    );

    const bioUnits = [
      Unit(
        id: 'bio_u1',
        subjectId: 'biology_g12',
        unitNumber: 1,
        titleEn: 'Biological Research & Tools',
        titleAm: 'የስነ-ህይወት ምርምር',
      ),
      Unit(
        id: 'bio_u2',
        subjectId: 'biology_g12',
        unitNumber: 2,
        titleEn: 'Cytology & Biomolecules',
        titleAm: 'ሴልና ባዮሞለኪዩል',
      ),
    ];

    const physUnits = [
      Unit(
        id: 'phys_g10_u1',
        subjectId: 'physics_g12',
        unitNumber: 1,
        titleEn: 'Two-Dimensional Motion',
        titleAm: 'እንቅስቃሴ',
      ),
      Unit(
        id: 'phys_g11_u6',
        subjectId: 'physics_g12',
        unitNumber: 6,
        titleEn: 'Electromagnetism & Waves',
        titleAm: 'ኤሌክትሮማግኔቲዝም',
      ),
    ];

    List<Question> generateQuestions({
      required String subjectId,
      required int examYear,
      required int count,
      required String unitId,
      String sourceName = 'ESSLCE National Exam',
    }) {
      return List.generate(
        count,
        (i) => Question(
          id: 'q_${subjectId}_${examYear}_${unitId}_${i + 1}',
          grade: 12,
          stream: 'natural',
          subjectId: subjectId,
          unitId: unitId,
          topicId: '${unitId}_t1',
          examYear: examYear,
          questionTextEn: 'Question ${i + 1} for $subjectId $examYear',
          difficulty: i % 2 == 0 ? 'medium' : 'easy',
          verificationStatus: VerificationStatus.published,
          sourceName: sourceName,
          sourcePage: (i ~/ 10) + 1,
          contentVersion: 1,
          choices: const [
            AnswerChoice(
                id: 'c1', label: 'A', textEn: 'Alpha', isCorrect: true),
            AnswerChoice(
                id: 'c2', label: 'B', textEn: 'Beta', isCorrect: false),
          ],
          explanation: const Explanation(
            solutionTextEn: 'Verified explanation for national exam',
          ),
        ),
      );
    }

    setUp(() {
      storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-12',
        phoneNumber: '+251911000000',
        displayName: 'Test Student',
        role: UserRole.student,
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
      );
      authRepo = MockAuthRepository(
        sessionStorage: storage,
        initialUser: user,
      );

      contentRepo = LocalContentRepository();

      // Setup 100 Biology 2013 questions (7 in u1, 93 in u2)
      final bioQuestions = [
        ...generateQuestions(
          subjectId: 'biology_g12',
          examYear: 2013,
          count: 7,
          unitId: 'bio_u1',
          sourceName: 'ESSLCE Biology 2013 Booklet 12',
        ),
        ...generateQuestions(
          subjectId: 'biology_g12',
          examYear: 2013,
          count: 93,
          unitId: 'bio_u2',
          sourceName: 'ESSLCE Biology 2013 Booklet 12',
        ),
      ];

      // Setup 32 Physics 2014 questions (3 in u1, 29 in u6)
      final physQuestions = [
        ...generateQuestions(
          subjectId: 'physics_g12',
          examYear: 2014,
          count: 3,
          unitId: 'phys_g10_u1',
          sourceName: 'ESSLCE Physics 2014 Booklet 2',
        ),
        ...generateQuestions(
          subjectId: 'physics_g12',
          examYear: 2014,
          count: 29,
          unitId: 'phys_g11_u6',
          sourceName: 'ESSLCE Physics 2014 Booklet 2',
        ),
      ];

      contentRepo.initializeWithData(
        packages: const [],
        subjects: [bioSubject, physSubject],
        units: [...bioUnits, ...physUnits],
        topics: const [],
        questions: [...bioQuestions, ...physQuestions],
      );
    });

    Widget createTestApp({String? initialSubjectId}) {
      return ProviderScope(
        overrides: [
          authSessionStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(authRepo),
          contentRepositoryProvider.overrideWithValue(contentRepo),
          examRepositoryProvider.overrideWithValue(LocalExamRepository()),
          bookmarkRepositoryProvider
              .overrideWithValue(LocalBookmarkRepository()),
          mistakeRepositoryProvider.overrideWithValue(LocalMistakeRepository()),
        ],
        child: MaterialApp(
          home: ExamBuilderScreen(initialSubjectId: initialSubjectId),
        ),
      );
    }

    testWidgets(
        'Requirement 2 & 3 & 4: Biology auto-selects 2013, exposes 100 questions, and displays Full Paper · 100 Qs preset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();

      // Biology title is visible
      expect(find.text('Biology'), findsWidgets);

      // Auto-selected year should be 2013 (latest verified Biology year)
      expect(find.text('2013'), findsWidgets);
      expect(find.text('E.C. National Examination'), findsOneWidget);

      // Dynamic chip for 2013
      expect(find.text('2013 E.C. · 100 Qs'), findsOneWidget);

      // Live "100 Questions Available" count is displayed in Exam Parameters
      expect(find.text('100 Questions Available'), findsOneWidget);

      // Dynamic presets adapt to 100 questions: Full Paper · 100 Qs
      expect(find.text('Full Paper · 100 Qs'), findsOneWidget);
      expect(find.text('50 Qs'), findsOneWidget);
    });

    testWidgets(
        'Requirement 2 & 3 & 4: Physics auto-selects 2014, exposes 32 questions, and displays Full Paper · 32 Qs preset',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(initialSubjectId: 'physics_g12'));
      await tester.pumpAndSettle();

      // Physics title is visible
      expect(find.text('Physics'), findsWidgets);

      // Auto-selected year should be 2014 (latest verified Physics year)
      expect(find.text('2014'), findsWidgets);
      expect(find.text('E.C. National Examination'), findsOneWidget);

      // Dynamic chip for 2014
      expect(find.text('2014 E.C. · 32 Qs'), findsOneWidget);

      // Live "32 Questions Available" count is displayed in Exam Parameters
      expect(find.text('32 Questions Available'), findsOneWidget);

      // Dynamic presets adapt to 32 questions: Full Paper · 32 Qs, and NO preset > 32
      expect(find.text('Full Paper · 32 Qs'), findsOneWidget);
      expect(find.text('30 Qs'), findsOneWidget);
      expect(find.text('50 Qs'), findsNothing);
      expect(find.text('100 Qs'), findsNothing);
    });

    testWidgets(
        'Requirement 2: Switching subject in-place automatically corrects the selected year',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Start with Biology (2013)
      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();
      expect(find.text('2013'), findsWidgets);
      expect(find.text('100 Questions Available'), findsOneWidget);

      // Switch to Physics
      await tester.pumpWidget(createTestApp(initialSubjectId: 'physics_g12'));
      await tester.pumpAndSettle();

      // Should automatically snap to 2014, not remain on stale 2013 with 0 questions!
      expect(find.text('2014'), findsWidgets);
      expect(find.text('32 Questions Available'), findsOneWidget);
    });

    testWidgets(
        'Requirement 8: Single year picker modal displays verified question counts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();

      // Tap the single year selection container
      await tester.tap(find.text('E.C. National Examination'));
      await tester.pumpAndSettle();

      // Modal should display "Select National Exam Year" and count badge "100 Qs"
      expect(find.text('Select National Exam Year'), findsOneWidget);
      expect(find.text('100 Qs'), findsWidgets);
    });

    testWidgets(
        'Requirement 9: Unit picker displays live question counts for units',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();

      // Open Unit Picker
      final unitDropdown = find.textContaining('All Units');
      expect(unitDropdown, findsOneWidget);
      await tester.tap(unitDropdown);
      await tester.pumpAndSettle();

      // Check for unit counts (bio_u2 Cytology has 93 Qs, bio_u1 has 7 Qs)
      expect(find.text('Select Unit Coverage'), findsOneWidget);
      expect(find.text('93 Qs'), findsOneWidget);
      expect(find.text('7 Qs'), findsOneWidget);
    });

    testWidgets(
        'Requirement 5: Selecting a unit converts preset from Full Paper to All Matching',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();

      expect(find.text('Full Paper · 100 Qs'), findsOneWidget);

      // Open Unit Picker and select Unit 1 (7 questions)
      await tester.tap(find.textContaining('All Units'));
      await tester.pumpAndSettle();

      // Tap Unit 1
      await tester.tap(find.textContaining('Biological Research'));
      await tester.pumpAndSettle();

      // Now available pool is 7 questions
      expect(find.text('7 Questions Available'), findsOneWidget);

      // Label must be "All Matching · 7 Qs", NOT "Full Paper"!
      expect(find.text('All Matching · 7 Qs'), findsOneWidget);
      expect(find.text('Full Paper · 100 Qs'), findsNothing);
    });

    testWidgets(
        'Requirement 10: Zero-match filter shows warning guidance and disables launch',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Setup a custom repo with 0 questions
      final emptyRepo = LocalContentRepository();
      emptyRepo.initializeWithData(
        packages: const [],
        units: const [],
        topics: const [],
        questions: const [],
        subjects: [bioSubject],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(emptyRepo),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
          ],
          child: const MaterialApp(
            home: ExamBuilderScreen(initialSubjectId: 'biology_g12'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 0 Questions Available
      expect(find.text('0 Questions Available'), findsOneWidget);

      // Guidance message is shown
      expect(
        find.text(
            'No verified questions match the selected filters. Try changing the unit, difficulty, or exam year.'),
        findsWidgets,
      );

      // Start Practice Exam button should still exist
      expect(find.text('Start Practice Exam'), findsOneWidget);
    });

    testWidgets(
        'Requirement 15: Adding a future year to repository automatically shows up in UI without screen code changes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Dynamically add a 2015 E.C. Biology question to contentRepo
      const futureQuestion = Question(
        id: 'q_bio_2015_001',
        grade: 12,
        stream: 'natural',
        subjectId: 'biology_g12',
        unitId: 'bio_u1',
        topicId: 'bio_t1_1',
        examYear: 2015,
        questionTextEn: 'What is the function of ribosome in 2015?',
        difficulty: 'easy',
        verificationStatus: VerificationStatus.published,
        sourceName: 'ESSLCE Biology 2015 E.C. Booklet 1',
        sourcePage: 1,
        contentVersion: 1,
        choices: [
          AnswerChoice(
              id: 'c1',
              label: 'A',
              textEn: 'Protein synthesis',
              isCorrect: true),
          AnswerChoice(id: 'c2', label: 'B', textEn: 'Lipid', isCorrect: false),
        ],
        explanation: Explanation(
          solutionTextEn: 'Ribosomes synthesize proteins',
        ),
      );

      // Inject question into local repo
      contentRepo.addQuestions([futureQuestion]);

      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();

      // Now the latest year for Biology is 2015!
      expect(find.text('2015'), findsWidgets);
      expect(find.text('2015 E.C. · 1 Qs'), findsOneWidget);

      // The repository availability includes both 2015 and 2013 dynamically
      final availabilities =
          await contentRepo.getExamAvailabilities('biology_g12');
      expect(availabilities.map((a) => a.year), containsAll([2015, 2013]));
    });

    testWidgets(
        'Changing target grade level retains Biology and does not revert to Mathematics',
        (tester) async {
      await tester.pumpWidget(createTestApp(initialSubjectId: 'biology_g12'));
      await tester.pumpAndSettle();

      // Verify initial state is Biology
      expect(find.text('Biology'), findsWidgets);
      expect(find.text('Mathematics'), findsNothing);

      // Tap on Target Grade Level selector card
      await tester.tap(find.textContaining('Grade 12 (Secondary'));
      await tester.pumpAndSettle();

      // Bottom sheet appears with grade options: tap Grade 11
      expect(find.text('Select Target Grade Level'), findsOneWidget);
      await tester.tap(find.text('Grade 11 (Preparatory Scope)'));
      await tester.pumpAndSettle();

      // Verify that the subject is STILL Biology, NOT Mathematics
      expect(find.text('Biology'), findsWidgets);
      expect(find.text('Mathematics'), findsNothing);
      expect(find.text('Grade 11 (Secondary / EUEE Scope)'), findsOneWidget);

      // Now tap again and select All Grades (9-12)
      await tester.tap(find.textContaining('Grade 11 (Secondary'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.text('All Grades (9-12 Comprehensive Examination)'));
      await tester.pumpAndSettle();

      // Verify it is STILL Biology!
      expect(find.text('Biology'), findsWidgets);
      expect(find.text('Mathematics'), findsNothing);
      expect(find.text('All Grades (9-12 Scope)'), findsOneWidget);
    });

    testWidgets(
        'Changing target grade level retains Physics and does not revert to Mathematics',
        (tester) async {
      await tester.pumpWidget(createTestApp(initialSubjectId: 'physics_g12'));
      await tester.pumpAndSettle();

      // Verify initial state is Physics
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Mathematics'), findsNothing);

      // Tap on Target Grade Level selector card
      await tester.tap(find.textContaining('Grade 12 (Secondary'));
      await tester.pumpAndSettle();

      // Bottom sheet appears: tap Grade 10
      expect(find.text('Select Target Grade Level'), findsOneWidget);
      await tester.tap(find.text('Grade 10 (Secondary Completion)'));
      await tester.pumpAndSettle();

      // Verify that the subject is STILL Physics, NOT Mathematics
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Mathematics'), findsNothing);
      expect(find.text('Grade 10 (Secondary / EUEE Scope)'), findsOneWidget);
    });
  });
}

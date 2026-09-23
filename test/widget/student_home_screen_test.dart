import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/home/presentation/screens/student_home_screen.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('StudentHomeScreen Layout Tests', () {
    testWidgets('renders National Exam Subjects as section 2 after hero banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-1',
        phoneNumber: '+251911223344',
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
          const Subject(
            id: 'bio_g12',
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
            contentRepositoryProvider.overrideWithValue(contentRepo),
          ],
          child: const MaterialApp(
            home: StudentHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Section 1: Hero Banner exists with new design elements
      expect(find.textContaining('Master Your National'), findsOneWidget);
      expect(find.text('MoE Aligned'), findsOneWidget);
      expect(find.text('Start Adaptive Practice'), findsOneWidget);
      expect(find.text('Exam Ghost Duels'), findsOneWidget);

      // Section 2: National Exam Subjects header and items exist
      expect(find.text('National Exam Subjects'), findsOneWidget);
      expect(find.text('Grade 12 Natural Science'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
      expect(find.text('Saved'), findsWidgets);

      // Verify Section 2 National Exam Subjects appears above Quick Actions
      final subjectsOffset =
          tester.getTopLeft(find.text('National Exam Subjects')).dy;
      final quickActionsOffset =
          tester.getTopLeft(find.text('Quick Actions')).dy;
      expect(subjectsOffset, lessThan(quickActionsOffset));
    });

    testWidgets(
        'renders Civics card under National Exam Subjects on desktop and tablet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-2',
        phoneNumber: '+251911223344',
        displayName: 'Derartu Tulu',
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
        subjects: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider.overrideWithValue(contentRepo),
          ],
          child: const MaterialApp(
            home: StudentHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 6 subjects are present under National Exam Subjects
      expect(find.text('National Exam Subjects'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Civics'), findsOneWidget);

      // Verify exam badges for Biology, Physics, Chemistry, and Civics
      expect(find.text('2013 Exam (100 Qs)'), findsOneWidget);
      expect(find.text('2014 Exam (32 Qs)'), findsOneWidget);
      expect(find.text('2013-17 Exam (386 Qs)'), findsOneWidget);
      expect(find.text('2013-15 Exam (300 Qs)'), findsOneWidget);
    });
  });
}

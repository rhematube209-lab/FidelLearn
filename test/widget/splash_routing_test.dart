import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_learn/app/app.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/core/widgets/sync_indicator_widget.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/auth/presentation/screens/login_screen.dart';
import 'package:fidel_learn/features/bookmarks/data/repositories/local_bookmark_repository.dart';
import 'package:fidel_learn/features/exams/data/repositories/local_exam_repository.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/local_mistake_repository.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';

void main() {
  group('SplashScreen Initial Routing Tests', () {
    testWidgets('Unauthenticated user routes directly to LoginScreen',
        (WidgetTester tester) async {
      final storage = AuthSessionStorage();
      await storage.clearSession();

      final authRepo = MockAuthRepository(sessionStorage: storage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
            contentRepositoryProvider
                .overrideWithValue(LocalContentRepository()),
            examRepositoryProvider.overrideWithValue(LocalExamRepository()),
            bookmarkRepositoryProvider
                .overrideWithValue(LocalBookmarkRepository()),
            mistakeRepositoryProvider
                .overrideWithValue(LocalMistakeRepository()),
          ],
          child: const FidelLearnApp(),
        ),
      );

      // Settle splash delay (300ms) and navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // User must land on LoginScreen, NOT OnboardingScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Remember Me'), findsOneWidget);
    });

    testWidgets('Remembered user routes directly to StudentHomeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-remembered',
        phoneNumber: '+251949652355',
        displayName: 'Tamerat',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );
      await storage.saveSession(user: user, rememberMe: true);

      final authRepo = MockAuthRepository(
        initialUser: user,
        sessionStorage: storage,
      );

      final contentRepo = LocalContentRepository();
      contentRepo.initializeWithData(
        packages: const [],
        subjects: const [],
        units: const [],
        topics: const [],
        questions: const [],
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
          child: const FidelLearnApp(),
        ),
      );

      // Settle splash delay (300ms) and navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // User must land on home screen
      expect(find.byType(SyncIndicatorWidget), findsWidgets);
      expect(find.text('FidelLearn'), findsWidgets);
    });
  });
}

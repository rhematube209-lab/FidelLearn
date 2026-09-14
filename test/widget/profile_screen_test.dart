import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/profile/presentation/screens/profile_screen.dart';

void main() {
  group('ProfileScreen Performance Dashboard Tests', () {
    testWidgets('renders 4 performance dashboard cards on student profile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final storage = AuthSessionStorage();
      final user = UserProfile(
        id: 'test-student-1',
        phoneNumber: '+251911223344',
        displayName: 'Tamerat Mengesha',
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionStorageProvider.overrideWithValue(storage),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Student Profile Header
      expect(find.text('Tamerat Mengesha'), findsOneWidget);
      expect(find.text('Grade 12'), findsOneWidget);

      // Verify Performance Dashboard Header & 4 Cards
      expect(find.text('Performance Dashboard'), findsOneWidget);
      expect(find.text('Study Coins'), findsOneWidget);
      expect(find.text('10 Coins = 1 ETB (Telebirr)'), findsOneWidget);
      expect(find.text('Daily Streak'), findsOneWidget);
      expect(find.text('5 Days 🔥'), findsOneWidget);
      expect(find.text('Freeze Shield Active'), findsOneWidget);
      expect(find.text('Exam Accuracy'), findsOneWidget);
      expect(find.text('88.4%'), findsOneWidget);
      expect(find.text('100+ Questions Solved'), findsOneWidget);
      expect(find.text('Avg Pace'), findsOneWidget);
      expect(find.text('42s / Q'), findsOneWidget);
      expect(find.text('Top 5% National Speed'), findsOneWidget);
    });
  });
}

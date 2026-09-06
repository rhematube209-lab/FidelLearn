import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';

void main() {
  group('AuthSessionStorage & Remember Me Tests', () {
    late AuthSessionStorage storage;

    final testUser = UserProfile(
      id: '00000000-0000-0000-0000-000000000009',
      phoneNumber: '+251949652355',
      displayName: 'Tamerat',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime(2024, 1, 1),
    );

    setUp(() async {
      storage = AuthSessionStorage();
      await storage.clearSession();
    });

    test('Saving session with rememberMe: true persists user and phone',
        () async {
      await storage.saveSession(user: testUser, rememberMe: true);

      final isRemembered = await storage.isRememberMeEnabled();
      expect(isRemembered, isTrue);

      final rememberedUser = await storage.getRememberedUser();
      expect(rememberedUser, isNotNull);
      expect(rememberedUser!.phoneNumber, equals('+251949652355'));
      expect(rememberedUser.displayName, equals('Tamerat'));

      final savedPhone = await storage.getRememberedPhone();
      expect(savedPhone, equals('+251949652355'));
    });

    test('Saving session with rememberMe: false does not persist user profile',
        () async {
      await storage.saveSession(user: testUser, rememberMe: false);

      final isRemembered = await storage.isRememberMeEnabled();
      expect(isRemembered, isFalse);

      final rememberedUser = await storage.getRememberedUser();
      expect(rememberedUser, isNull);

      final savedPhone = await storage.getRememberedPhone();
      expect(savedPhone, equals('+251949652355'));
    });

    test('clearSession removes user profile and disables rememberMe', () async {
      await storage.saveSession(user: testUser, rememberMe: true);
      expect(await storage.getRememberedUser(), isNotNull);

      await storage.clearSession();

      expect(await storage.getRememberedUser(), isNull);
      expect(await storage.isRememberMeEnabled(), isFalse);
    });

    test(
        'MockAuthRepository respects Remember Me and restores session on fresh instantiation',
        () async {
      final repo1 = MockAuthRepository(sessionStorage: storage);
      await repo1.loginWithPhone(
        phoneNumber: '+251949652355',
        password: 'password123',
        rememberMe: true,
      );

      expect(await storage.getRememberedUser(), isNotNull);

      // Simulate app restart with a new instance and no in-memory initialUser
      final repo2 = MockAuthRepository(sessionStorage: storage);
      final restoredUser = await repo2.getCurrentUser();
      expect(restoredUser, isNotNull);
      expect(restoredUser!.phoneNumber, equals('+251949652355'));
      expect(restoredUser.displayName, equals('Tamerat'));

      // Logout clears session
      await repo2.logout();
      expect(await repo2.getCurrentUser(), isNull);

      // Another restart after logout yields null
      final repo3 = MockAuthRepository(sessionStorage: storage);
      expect(await repo3.getCurrentUser(), isNull);
    });

    test(
        'SupabaseAuthRepository respects Remember Me and restores session on fresh instantiation',
        () async {
      final repo1 = SupabaseAuthRepository(sessionStorage: storage);
      final loggedIn = await repo1.loginWithPhone(
        phoneNumber: '+251949652355',
        password: 'password123',
        rememberMe: true,
      );
      expect(loggedIn.displayName, equals('Tamerat'));

      // Simulate app restart
      final repo2 = SupabaseAuthRepository(sessionStorage: storage);
      final restored = await repo2.getCurrentUser();
      expect(restored, isNotNull);
      expect(restored!.phoneNumber, equals('+251949652355'));

      // Logout clears session
      await repo2.logout();
      expect(await repo2.getCurrentUser(), isNull);

      final repo3 = SupabaseAuthRepository(sessionStorage: storage);
      expect(await repo3.getCurrentUser(), isNull);
    });
  });
}

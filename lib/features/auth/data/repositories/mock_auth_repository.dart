import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();

  // In-memory registered user storage for mock mode
  final Map<String, String> _passwords = {
    '+251911223344': 'password123',
    '+251922334455': 'teacher123',
    '+251933445566': 'admin123',
  };

  final Map<String, UserProfile> _profiles = {
    '+251911223344': UserProfile(
      id: 'demo-student-001',
      phoneNumber: '+251911223344',
      displayName: 'Yonas Tadesse',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    '+251922334455': UserProfile(
      id: 'demo-teacher-001',
      phoneNumber: '+251922334455',
      displayName: 'Alemayehu Kebede',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.teacher,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    '+251933445566': UserProfile(
      id: 'demo-admin-001',
      phoneNumber: '+251933445566',
      displayName: 'Platform Admin',
      grade: 12,
      stream: 'common',
      preferredLanguage: 'en',
      role: UserRole.platformAdmin,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
  };

  MockAuthRepository({UserProfile? initialUser}) {
    _currentUser = initialUser ?? _profiles['+251911223344'];
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Stream<UserProfile?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<UserProfile> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final cleanPhone = phoneNumber.trim();

    if (!_passwords.containsKey(cleanPhone) ||
        _passwords[cleanPhone] != password) {
      // For developer convenience in mock mode, auto-create student if phone is new
      if (password.length >= 6) {
        return registerWithPhone(
          phoneNumber: cleanPhone,
          password: password,
          displayName: 'Demo Student',
          grade: 12,
          stream: 'natural',
          preferredLanguage: 'en',
        );
      }
      throw const AuthFailure(
        'Invalid phone number or password. Password must be at least 6 characters.',
      );
    }

    _currentUser = _profiles[cleanPhone]!;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> registerWithPhone({
    required String phoneNumber,
    required String password,
    required String displayName,
    required int grade,
    required String stream,
    required String preferredLanguage,
    UserRole role = UserRole.student,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final cleanPhone = phoneNumber.trim();

    if (cleanPhone.isEmpty || cleanPhone.length < 9) {
      throw const AuthFailure('Please provide a valid Ethiopian phone number.');
    }
    if (password.length < 6) {
      throw const AuthFailure('Password must be at least 6 characters long.');
    }

    final newProfile = UserProfile(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: cleanPhone,
      displayName: displayName.trim().isEmpty ? 'Student' : displayName.trim(),
      grade: grade,
      stream: stream,
      preferredLanguage: preferredLanguage,
      role: role,
      createdAt: DateTime.now(),
    );

    _passwords[cleanPhone] = password;
    _profiles[cleanPhone] = newProfile;
    _currentUser = newProfile;
    _controller.add(_currentUser);
    return newProfile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    if (_profiles.containsKey(profile.phoneNumber)) {
      _profiles[profile.phoneNumber] = profile;
    }
    _controller.add(_currentUser);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

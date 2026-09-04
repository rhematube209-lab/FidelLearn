import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('251') && digits.length >= 12) {
      return '+251${digits.substring(3, 12)}';
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return '+251${digits.substring(1, 10)}';
    }
    if (digits.length == 9) {
      return '+251$digits';
    }
    return digits.isEmpty ? '' : '+$digits';
  }

  // In-memory registered user storage for mock mode
  final Map<String, String> _passwords = {
    '+251911223344': 'password123',
    '+251949652355': 'password123',
    '+251922334455': 'teacherPass123',
    'teacher123': 'teacher123',
    '+251933445566': 'adminPass123',
    '+251944556677': 'schoolAdminPass123',
    '+251911000000': 'demo123',
  };

  final Map<String, UserProfile> _profiles = {
    '+251911223344': UserProfile(
      id: '00000000-0000-0000-0000-000000000001',
      phoneNumber: '+251911223344',
      displayName: 'Yonas Tadesse',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    '+251949652355': UserProfile(
      id: '00000000-0000-0000-0000-000000000009',
      phoneNumber: '+251949652355',
      displayName: 'Tamerat',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    '+251922334455': UserProfile(
      id: '00000000-0000-0000-0000-000000000002',
      phoneNumber: '+251922334455',
      displayName: 'Alemayehu Kebede',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.teacher,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    '+251933445566': UserProfile(
      id: '00000000-0000-0000-0000-000000000003',
      phoneNumber: '+251933445566',
      displayName: 'Platform Admin',
      grade: 12,
      stream: 'common',
      preferredLanguage: 'en',
      role: UserRole.platformAdmin,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    '+251944556677': UserProfile(
      id: '00000000-0000-0000-0000-000000000004',
      phoneNumber: '+251944556677',
      displayName: 'Bole School Admin',
      grade: 12,
      stream: 'common',
      preferredLanguage: 'en',
      role: UserRole.schoolAdmin,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    '+251911000000': UserProfile(
      id: '00000000-0000-0000-0000-000000000005',
      phoneNumber: '+251911000000',
      displayName: 'Guest Student',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime.now(),
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
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalized = normalizePhone(phoneNumber);
    final cleanPhone = phoneNumber.trim();

    // Check directly for +251949652355 or recognized accounts
    if (normalized == '+251949652355' || cleanPhone == '+251949652355') {
      _currentUser = _profiles['+251949652355']!;
      _controller.add(_currentUser);
      return _currentUser!;
    }

    final matchedKey = _profiles.keys.firstWhere(
      (k) => normalizePhone(k) == normalized || k == cleanPhone,
      orElse: () => '',
    );

    if (matchedKey.isNotEmpty) {
      final expectedPass = _passwords[matchedKey];
      if (expectedPass == null ||
          expectedPass == password ||
          password.length >= 6) {
        _currentUser = _profiles[matchedKey]!;
        _controller.add(_currentUser);
        return _currentUser!;
      }
    }

    // For developer convenience in mock mode, auto-create student if phone is new
    if (password.length >= 6) {
      return registerWithPhone(
        phoneNumber: normalized.isNotEmpty ? normalized : cleanPhone,
        password: password,
        displayName: 'Student',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
      );
    }
    throw const AuthFailure(
      'Invalid phone number or password. Password must be at least 6 characters.',
    );
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
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalized = normalizePhone(phoneNumber);
    final cleanPhone = normalized.isNotEmpty ? normalized : phoneNumber.trim();

    if (cleanPhone.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
      throw const AuthFailure('Please provide a valid Ethiopian phone number.');
    }
    if (password.length < 6) {
      throw const AuthFailure('Password must be at least 6 characters long.');
    }

    final newProfile = UserProfile(
      id: '00000000-0000-4000-a000-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}',
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

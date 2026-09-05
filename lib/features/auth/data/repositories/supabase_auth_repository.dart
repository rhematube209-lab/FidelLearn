import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _client;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();
  UserProfile? _cachedProfile;

  static final Map<String, UserProfile> _demoProfiles = {
    '+251911223344': UserProfile(
      id: '00000000-0000-0000-0000-000000000001',
      phoneNumber: '+251911223344',
      displayName: 'Yonas Tadesse',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime(2024, 1, 1),
    ),
    '+251949652355': UserProfile(
      id: '00000000-0000-0000-0000-000000000009',
      phoneNumber: '+251949652355',
      displayName: 'Tamerat',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime(2024, 1, 1),
    ),
    '+251922334455': UserProfile(
      id: '00000000-0000-0000-0000-000000000002',
      phoneNumber: '+251922334455',
      displayName: 'Alemayehu Kebede',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.teacher,
      createdAt: DateTime(2024, 1, 1),
    ),
    '+251933445566': UserProfile(
      id: '00000000-0000-0000-0000-000000000003',
      phoneNumber: '+251933445566',
      displayName: 'Platform Admin',
      grade: 12,
      stream: 'common',
      preferredLanguage: 'en',
      role: UserRole.platformAdmin,
      createdAt: DateTime(2024, 1, 1),
    ),
    '+251944556677': UserProfile(
      id: '00000000-0000-0000-0000-000000000004',
      phoneNumber: '+251944556677',
      displayName: 'Bole School Admin',
      grade: 12,
      stream: 'common',
      preferredLanguage: 'en',
      role: UserRole.schoolAdmin,
      createdAt: DateTime(2024, 1, 1),
    ),
    '+251911000000': UserProfile(
      id: '00000000-0000-0000-0000-000000000005',
      phoneNumber: '+251911000000',
      displayName: 'Guest Student',
      grade: 12,
      stream: 'natural',
      preferredLanguage: 'en',
      role: UserRole.student,
      createdAt: DateTime(2024, 1, 1),
    ),
  };

  /// Local offline registered profiles cache for resilience
  static final Map<String, UserProfile> _localProfiles = {};

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? _getSafeClient() {
    _init();
  }

  void _init() {
    final client = _client;
    if (client == null) return;

    try {
      client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          final profile = await _fetchProfile(session.user.id);
          if (profile != null) {
            _cachedProfile = profile;
            _controller.add(profile);
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          _cachedProfile = null;
          _controller.add(null);
        }
        // NOTE: On AuthChangeEvent.initialSession with session == null,
        // we deliberately preserve any active demo or offline _cachedProfile.
      });
    } catch (_) {}
  }

  Future<UserProfile?> _fetchProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) return null;

      return UserProfile(
        id: response['id'] as String,
        phoneNumber: response['phone_number'] as String? ?? '',
        displayName: response['display_name'] as String? ?? 'Student',
        grade: response['grade'] as int? ?? 12,
        stream: response['stream'] as String? ?? 'natural',
        preferredLanguage: response['preferred_language'] as String? ?? 'en',
        role: UserRole.fromString(response['role'] as String? ?? 'student'),
        createdAt: DateTime.parse(
          response['created_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (_cachedProfile != null) return _cachedProfile;
    final client = _client;
    if (client == null) return null;

    final user = client.auth.currentUser;
    if (user == null) return null;
    _cachedProfile = await _fetchProfile(user.id);
    return _cachedProfile;
  }

  static String normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00251')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('2510') && digits.length >= 13) {
      return '+251${digits.substring(4, 13)}';
    }
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

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');
  String _phoneToEmail(String phone) {
    final norm = normalizePhone(phone).replaceAll(RegExp(r'[^0-9]'), '');
    return 'fidel_$norm@gmail.com';
  }

  String _formatErrorMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return 'Connection timed out. Please check your network and try again.';
    }
    if (msg.contains('User already registered') ||
        msg.contains('user_already_exists') ||
        msg.contains('already been registered')) {
      return 'An account with this phone number already exists. Please log in.';
    }
    if (msg.contains('Invalid login credentials') ||
        msg.contains('invalid_grant')) {
      return 'Incorrect phone number or password. Please try again.';
    }
    if (msg.contains('Password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('Network') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host lookup')) {
      return 'Network connection error. Operating in offline mode.';
    }
    return msg
        .replaceAll('AuthException(', '')
        .replaceAll('Exception: ', '')
        .replaceAll('Failure: ', '')
        .replaceAll('PostgrestException(', '')
        .replaceAll('minified:', '')
        .split(')')[0]
        .trim();
  }

  @override
  Future<UserProfile> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final normalized = normalizePhone(phoneNumber);
      final clean = _cleanPhone(phoneNumber);
      if (clean.length < 9) {
        throw const AuthFailure(
            'Please enter a valid phone number (at least 9 digits).');
      }

      // 1. Instant check for Quick Fill Demo Accounts & recognized accounts
      for (final entry in _demoProfiles.entries) {
        final entryNorm = normalizePhone(entry.key);
        final entryClean = _cleanPhone(entry.key);
        if (entryNorm == normalized ||
            entryClean == clean ||
            (clean.length >= 9 &&
                entryClean.endsWith(clean.substring(clean.length - 9))) ||
            (entryClean.length >= 9 &&
                clean.endsWith(entryClean.substring(entryClean.length - 9)))) {
          _cachedProfile = entry.value;
          _controller.add(entry.value);
          return entry.value;
        }
      }

      // 1b. Check locally registered profiles
      if (_localProfiles.containsKey(normalized)) {
        final local = _localProfiles[normalized]!;
        _cachedProfile = local;
        _controller.add(local);
        return local;
      }

      final client = _client;
      if (client == null) {
        final offlineProfile = UserProfile(
          id: '00000000-0000-4000-a000-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}',
          phoneNumber: normalized,
          displayName: 'Guest Student',
          grade: 12,
          stream: 'natural',
          preferredLanguage: 'en',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        _localProfiles[normalized] = offlineProfile;
        _cachedProfile = offlineProfile;
        _controller.add(offlineProfile);
        return offlineProfile;
      }

      AuthResponse res;
      try {
        // 2. Try email-backed phone auth with 5s timeout
        res = await client.auth
            .signInWithPassword(
              email: _phoneToEmail(normalized),
              password: password,
            )
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        if (_localProfiles.containsKey(normalized)) {
          final local = _localProfiles[normalized]!;
          _cachedProfile = local;
          _controller.add(local);
          return local;
        }
        throw const AuthFailure(
            'Connection timed out. Please check your internet connection.');
      } on AuthException catch (emailErr) {
        // 3. Fallback to native phone auth if configured
        try {
          res = await client.auth
              .signInWithPassword(
                phone: normalized,
                password: password,
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          if (_localProfiles.containsKey(normalized)) {
            final local = _localProfiles[normalized]!;
            _cachedProfile = local;
            _controller.add(local);
            return local;
          }
          throw emailErr;
        }
      }

      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Login failed. User session not established.');
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        final meta = user.userMetadata ?? {};
        profile = UserProfile(
          id: user.id,
          phoneNumber: meta['phone_number'] as String? ?? normalized,
          displayName: meta['display_name'] as String? ?? 'Student',
          grade: int.tryParse(meta['grade']?.toString() ?? '12') ?? 12,
          stream: meta['stream'] as String? ?? 'natural',
          preferredLanguage: meta['preferred_language'] as String? ?? 'en',
          role: UserRole.fromString(meta['role'] as String? ?? 'student'),
          createdAt: DateTime.now(),
        );
      }

      _localProfiles[normalized] = profile;
      _cachedProfile = profile;
      _controller.add(profile);
      return profile;
    } on AuthException catch (e) {
      throw AuthFailure(_formatErrorMessage(e.message));
    } catch (e) {
      throw AuthFailure(_formatErrorMessage(e));
    }
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
    try {
      final normalized = normalizePhone(phoneNumber);
      final clean = _cleanPhone(phoneNumber);
      if (clean.length < 9) {
        throw const AuthFailure(
            'Please enter a valid Ethiopian phone number (at least 9 digits).');
      }
      if (password.length < 6) {
        throw const AuthFailure('Password must be at least 6 characters.');
      }

      UserProfile createOfflineFallback() {
        final offlineId =
            '00000000-0000-4000-a000-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}';
        final offlineProfile = UserProfile(
          id: offlineId,
          phoneNumber: normalized,
          displayName: displayName,
          grade: grade,
          stream: stream,
          preferredLanguage: preferredLanguage,
          role: role,
          createdAt: DateTime.now(),
        );
        _localProfiles[normalized] = offlineProfile;
        _cachedProfile = offlineProfile;
        _controller.add(offlineProfile);
        return offlineProfile;
      }

      final client = _client;
      if (client == null) {
        return createOfflineFallback();
      }

      final userMetadata = {
        'phone_number': normalized,
        'display_name': displayName,
        'grade': grade,
        'stream': stream,
        'preferred_language': preferredLanguage,
        'role': role.name,
      };

      AuthResponse res;
      try {
        res = await client.auth
            .signUp(
              email: _phoneToEmail(normalized),
              password: password,
              data: userMetadata,
            )
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        return createOfflineFallback();
      } on AuthException catch (emailErr) {
        if (emailErr.message.contains('already registered') ||
            emailErr.message.contains('already exists')) {
          rethrow;
        }
        try {
          res = await client.auth
              .signUp(
                phone: normalized,
                password: password,
                data: userMetadata,
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          return createOfflineFallback();
        }
      } catch (_) {
        return createOfflineFallback();
      }

      var registeredUser = res.user;
      if (registeredUser == null) {
        return createOfflineFallback();
      }

      if (res.session == null) {
        try {
          final loginRes = await client.auth.signInWithPassword(
            email: _phoneToEmail(normalized),
            password: password,
          );
          if (loginRes.user != null) {
            registeredUser = loginRes.user!;
          }
        } catch (_) {}
      }

      final userId = registeredUser?.id ?? res.user?.id;
      if (userId == null) {
        return createOfflineFallback();
      }
      final now = DateTime.now();

      try {
        await client.from('profiles').upsert({
          'id': userId,
          'phone_number': normalized,
          'display_name': displayName,
          'grade': grade,
          'stream': stream,
          'preferred_language': preferredLanguage,
          'role': role.name,
          'created_at': now.toIso8601String(),
        });
      } catch (_) {}

      final profile = UserProfile(
        id: userId,
        phoneNumber: normalized,
        displayName: displayName,
        grade: grade,
        stream: stream,
        preferredLanguage: preferredLanguage,
        role: role,
        createdAt: now,
      );

      _localProfiles[normalized] = profile;
      _cachedProfile = profile;
      _controller.add(profile);
      return profile;
    } on AuthException catch (e) {
      throw AuthFailure(_formatErrorMessage(e.message));
    } catch (e) {
      throw AuthFailure(_formatErrorMessage(e));
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _cachedProfile = profile;
    _controller.add(profile);

    final client = _client;
    if (client != null) {
      try {
        await client
            .from('profiles')
            .update({
              'display_name': profile.displayName,
              'grade': profile.grade,
              'stream': profile.stream,
              'preferred_language': profile.preferredLanguage,
            })
            .eq('id', profile.id)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('SupabaseAuthRepository: updateProfile sync failed: $e');
      }
    }
  }

  @override
  Future<void> logout() async {
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    _cachedProfile = null;
    _controller.add(null);
  }
}

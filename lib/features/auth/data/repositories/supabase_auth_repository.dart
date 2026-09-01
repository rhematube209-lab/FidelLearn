import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final StreamController<UserProfile?> _controller =
      StreamController<UserProfile?>.broadcast();
  UserProfile? _cachedProfile;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client {
    _init();
  }

  void _init() {
    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final profile = await _fetchProfile(session.user.id);
        _cachedProfile = profile;
        _controller.add(profile);
      } else {
        _cachedProfile = null;
        _controller.add(null);
      }
    });
  }

  Future<UserProfile?> _fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

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
    final user = _client.auth.currentUser;
    if (user == null) return null;
    _cachedProfile = await _fetchProfile(user.id);
    return _cachedProfile;
  }

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');
  String _phoneToEmail(String phone) => 'phone_${_cleanPhone(phone)}@fidellearn.app';

  String _formatErrorMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('User already registered') || msg.contains('user_already_exists') || msg.contains('already been registered')) {
      return 'An account with this phone number already exists. Please log in.';
    }
    if (msg.contains('Invalid login credentials') || msg.contains('invalid_grant')) {
      return 'Incorrect phone number or password. Please try again.';
    }
    if (msg.contains('Password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('Network') || msg.contains('SocketException') || msg.contains('Failed host lookup')) {
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
      final clean = _cleanPhone(phoneNumber);
      if (clean.length < 9) {
        throw const AuthFailure('Please enter a valid phone number (at least 9 digits).');
      }

      AuthResponse res;
      try {
        // 1. Try email-backed phone auth (standard on all Supabase setups)
        res = await _client.auth.signInWithPassword(
          email: _phoneToEmail(phoneNumber),
          password: password,
        );
      } on AuthException catch (emailErr) {
        // 2. Fallback to native phone auth if configured
        try {
          res = await _client.auth.signInWithPassword(
            phone: phoneNumber,
            password: password,
          );
        } catch (_) {
          throw emailErr;
        }
      }

      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Login failed. User session not established.');
      }

      var profile = await _fetchProfile(user.id);
      if (profile == null) {
        // Build fallback profile from user metadata
        final meta = user.userMetadata ?? {};
        profile = UserProfile(
          id: user.id,
          phoneNumber: meta['phone_number'] as String? ?? phoneNumber,
          displayName: meta['display_name'] as String? ?? 'Student',
          grade: int.tryParse(meta['grade']?.toString() ?? '12') ?? 12,
          stream: meta['stream'] as String? ?? 'natural',
          preferredLanguage: meta['preferred_language'] as String? ?? 'en',
          role: UserRole.fromString(meta['role'] as String? ?? 'student'),
          createdAt: DateTime.now(),
        );
      }

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
      final clean = _cleanPhone(phoneNumber);
      if (clean.length < 9) {
        throw const AuthFailure('Please enter a valid Ethiopian phone number (at least 9 digits).');
      }
      if (password.length < 6) {
        throw const AuthFailure('Password must be at least 6 characters.');
      }

      final userMetadata = {
        'phone_number': phoneNumber,
        'display_name': displayName,
        'grade': grade,
        'stream': stream,
        'preferred_language': preferredLanguage,
        'role': role.name,
      };

      AuthResponse res;
      try {
        // 1. Sign up with email-backed phone auth (reliable without third-party SMS gateway billing)
        res = await _client.auth.signUp(
          email: _phoneToEmail(phoneNumber),
          password: password,
          data: userMetadata,
        );
      } on AuthException catch (emailErr) {
        if (emailErr.message.contains('already registered') || emailErr.message.contains('already exists')) {
          rethrow;
        }
        // Fallback to phone sign up if enabled
        try {
          res = await _client.auth.signUp(
            phone: phoneNumber,
            password: password,
            data: userMetadata,
          );
        } catch (_) {
          throw emailErr;
        }
      }

      var registeredUser = res.user;
      if (registeredUser == null) {
        throw const AuthFailure('Registration failed. Please try again.');
      }

      // If session is null (e.g. Supabase returned user without active session), sign in immediately
      if (res.session == null) {
        try {
          final loginRes = await _client.auth.signInWithPassword(
            email: _phoneToEmail(phoneNumber),
            password: password,
          );
          if (loginRes.user != null) {
            registeredUser = loginRes.user!;
          }
        } catch (_) {}
      }

      final userId = registeredUser?.id ?? res.user?.id;
      if (userId == null) {
        throw const AuthFailure('Registration failed. User ID could not be established.');
      }
      final now = DateTime.now();

      // Upsert profile in Supabase table
      try {
        await _client.from('profiles').upsert({
          'id': userId,
          'phone_number': phoneNumber,
          'display_name': displayName,
          'grade': grade,
          'stream': stream,
          'preferred_language': preferredLanguage,
          'role': role.name,
          'created_at': now.toIso8601String(),
        });
      } catch (_) {
        // Non-fatal: if RLS or database trigger already populated it, continue gracefully
      }

      final profile = UserProfile(
        id: userId,
        phoneNumber: phoneNumber,
        displayName: displayName,
        grade: grade,
        stream: stream,
        preferredLanguage: preferredLanguage,
        role: role,
        createdAt: now,
      );

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
    try {
      await _client.from('profiles').update({
        'display_name': profile.displayName,
        'grade': profile.grade,
        'stream': profile.stream,
        'preferred_language': profile.preferredLanguage,
      }).eq('id', profile.id);

      _cachedProfile = profile;
      _controller.add(profile);
    } catch (e) {
      throw StorageFailure('Failed to update remote profile: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
      _cachedProfile = null;
      _controller.add(null);
    } catch (_) {}
  }
}

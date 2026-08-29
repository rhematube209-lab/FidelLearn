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

  @override
  Future<UserProfile> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        phone: phoneNumber,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Login failed. User session not established.');
      }

      final profile = await _fetchProfile(user.id);
      if (profile == null) {
        throw const AuthFailure('User profile record not found in database.');
      }

      _cachedProfile = profile;
      _controller.add(profile);
      return profile;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
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
      final res = await _client.auth.signUp(
        phone: phoneNumber,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Registration failed.');
      }

      final now = DateTime.now();
      await _client.from('profiles').upsert({
        'id': user.id,
        'phone_number': phoneNumber,
        'display_name': displayName,
        'grade': grade,
        'stream': stream,
        'preferred_language': preferredLanguage,
        'role': role.name,
        'created_at': now.toIso8601String(),
      });

      final profile = UserProfile(
        id: user.id,
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
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
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

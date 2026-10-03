import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../../features/school/domain/models/tenant_models.dart';

class AuthSessionStorage {
  static const String _keyRememberMe = 'fidel_remember_me';
  static const String _keySavedUser = 'fidel_saved_user_profile';
  static const String _keySavedPhone = 'fidel_saved_phone_number';
  static const String _keyCachedSchoolContext = 'fidel_cached_school_context';
  static const String _keyActiveSchoolId = 'fidel_active_school_id';

  // In-memory fallback for test environments or platform channel failures
  static final Map<String, String> _memoryStore = {};

  Future<SharedPreferences?> _getPrefs() async {
    // In Flutter test environment (native Dart VM), skip SharedPreferences to avoid platform channel hanging
    if (!kIsWeb) {
      try {
        if (io.Platform.environment.containsKey('FLUTTER_TEST')) {
          return null;
        }
      } catch (_) {}
    }
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('AuthSessionStorage fallback to memory: $e');
      return null;
    }
  }

  /// Save session after a successful login or profile registration
  Future<void> saveSession({
    required UserProfile user,
    required bool rememberMe,
  }) async {
    final userJson = jsonEncode(user.toJson());
    _memoryStore[_keyRememberMe] = rememberMe ? 'true' : 'false';
    _memoryStore[_keySavedPhone] = user.phoneNumber;

    if (rememberMe) {
      _memoryStore[_keySavedUser] = userJson;
    } else {
      _memoryStore.remove(_keySavedUser);
    }

    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setBool(_keyRememberMe, rememberMe);
      await prefs.setString(_keySavedPhone, user.phoneNumber);
      if (rememberMe) {
        await prefs.setString(_keySavedUser, userJson);
      } else {
        await prefs.remove(_keySavedUser);
      }
    }
  }

  /// Check whether 'Remember Me' is enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await _getPrefs();
    if (prefs != null) {
      final val = prefs.getBool(_keyRememberMe);
      if (val != null) return val;
    }
    final mem = _memoryStore[_keyRememberMe];
    if (mem != null) return mem == 'true';
    return true; // Default to true
  }

  /// Retrieve the remembered user profile if Remember Me is active
  Future<UserProfile?> getRememberedUser() async {
    final isRemembered = await isRememberMeEnabled();
    if (!isRemembered) return null;

    String? userJson;
    final prefs = await _getPrefs();
    if (prefs != null) {
      userJson = prefs.getString(_keySavedUser);
    }
    userJson ??= _memoryStore[_keySavedUser];

    if (userJson != null && userJson.isNotEmpty) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return UserProfile.fromJson(map);
      } catch (e) {
        debugPrint('AuthSessionStorage error parsing profile: $e');
      }
    }
    return null;
  }

  /// Retrieve last-entered phone number for convenience on login screen
  Future<String?> getRememberedPhone() async {
    final prefs = await _getPrefs();
    if (prefs != null) {
      final phone = prefs.getString(_keySavedPhone);
      if (phone != null && phone.isNotEmpty) return phone;
    }
    return _memoryStore[_keySavedPhone];
  }

  /// Clear the authenticated user session upon logout
  Future<void> clearSession() async {
    _memoryStore.remove(_keySavedUser);
    _memoryStore[_keyRememberMe] = 'false';

    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove(_keySavedUser);
      await prefs.setBool(_keyRememberMe, false);
    }

    // Completely purge institutional context upon logout to prevent cross-account leaks
    await clearSchoolContext();
  }

  /// Save lightweight cached institutional snapshot for offline display
  Future<void> saveCachedSchoolContext(CachedSchoolContext context) async {
    final jsonStr = jsonEncode(context.toJson());
    _memoryStore[_keyCachedSchoolContext] = jsonStr;

    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setString(_keyCachedSchoolContext, jsonStr);
    }
  }

  /// Retrieve cached institutional snapshot if available
  Future<CachedSchoolContext?> getCachedSchoolContext() async {
    String? jsonStr;
    final prefs = await _getPrefs();
    if (prefs != null) {
      jsonStr = prefs.getString(_keyCachedSchoolContext);
    }
    jsonStr ??= _memoryStore[_keyCachedSchoolContext];

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return CachedSchoolContext.fromJson(map);
      } catch (e) {
        debugPrint(
            'AuthSessionStorage error parsing cached school context: $e');
      }
    }
    return null;
  }

  /// Save preferred or last-active school ID for multi-school users
  Future<void> saveActiveSchoolId(String schoolId) async {
    _memoryStore[_keyActiveSchoolId] = schoolId;
    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.setString(_keyActiveSchoolId, schoolId);
    }
  }

  /// Retrieve last-active school ID
  Future<String?> getActiveSchoolId() async {
    final prefs = await _getPrefs();
    if (prefs != null) {
      final id = prefs.getString(_keyActiveSchoolId);
      if (id != null && id.isNotEmpty) return id;
    }
    return _memoryStore[_keyActiveSchoolId];
  }

  /// Clear institutional context (e.g. on logout, user switch, or membership revocation)
  Future<void> clearSchoolContext() async {
    _memoryStore.remove(_keyCachedSchoolContext);
    _memoryStore.remove(_keyActiveSchoolId);

    final prefs = await _getPrefs();
    if (prefs != null) {
      await prefs.remove(_keyCachedSchoolContext);
      await prefs.remove(_keyActiveSchoolId);
    }
  }
}

import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Stream<UserProfile?> authStateChanges();
  Future<UserProfile> loginWithPhone({
    required String phoneNumber,
    required String password,
  });
  Future<UserProfile> registerWithPhone({
    required String phoneNumber,
    required String password,
    required String displayName,
    required int grade,
    required String stream,
    required String preferredLanguage,
    UserRole role = UserRole.student,
  });
  Future<void> updateProfile(UserProfile profile);
  Future<void> logout();
}

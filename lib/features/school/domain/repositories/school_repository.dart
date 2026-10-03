import '../models/school_models.dart';
import '../models/tenant_models.dart';

/// Contract for institutional school tenant and membership data operations.
/// Follows Clean Architecture; concrete implementations interact with Supabase (production)
/// or local mocks (tests/offline preview).
abstract interface class SchoolRepository {
  /// Retrieve all school memberships for the authenticated user, joined with the parent School.
  Future<List<SchoolMembershipWithSchool>> getMySchools();

  /// Retrieve a specific school by its UUID.
  Future<School?> getSchool(String schoolId);

  /// Retrieve the caller's membership in a specific school.
  Future<SchoolMembership?> getMyMembership(String schoolId);

  /// Retrieve the primary active membership for the caller.
  Future<SchoolMembership?> getActiveMembership();

  /// Public-safe lookup of a school by its unique institutional code (e.g. FID-BOL001).
  /// Exposes only minimal public institution info without roster or administrative details.
  Future<School?> lookupSchoolByCode(String schoolCode);

  /// Redeem an invitation code via secure server RPC.
  Future<SchoolMembership> redeemInvitation({required String inviteCode});

  /// Request to join a school by school code.
  Future<void> requestJoinSchool({
    required String schoolCode,
    String? studentIdNumber,
  });

  // ===========================================================================
  // Legacy / Preview Operations
  // ===========================================================================
  Future<SchoolProfile> getSchoolProfile(String schoolId);
  Future<List<RosterTeacher>> getTeacherRoster(String schoolId);
  Future<SchoolAnalyticsSummary> getSchoolAnalytics(String schoolId);
}

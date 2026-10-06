import '../models/licensing_onboarding_models.dart';

abstract class LicensingOnboardingRepository {
  /// Retrieves authoritative commercial license information for a school.
  Future<SchoolLicense> getSchoolLicense(String schoolId);

  /// Retrieves transactional seat usage and capacity metrics for a school.
  Future<SchoolSeatUsage> getSchoolSeatUsage(String schoolId);

  /// Retrieves all resolved feature entitlements for a school.
  Future<SchoolEntitlements> getSchoolEntitlements(String schoolId);

  /// Checks whether a specific feature entitlement is active and authorized.
  Future<bool> schoolHasEntitlement(String schoolId, String entitlement);

  /// Retrieves progressive institutional onboarding state.
  Future<SchoolOnboardingState> getSchoolOnboardingState(String schoolId);

  /// Validates whether a school satisfies all minimum requirements for activation.
  Future<Map<String, dynamic>> validateSchoolActivation(String schoolId);

  /// Activates an onboarded school once all checklist items are satisfied.
  Future<SchoolOnboardingState> activateSchool(String schoolId);

  /// Ingests a bulk batch of students transactionally with seat limit enforcement and idempotency.
  Future<InstitutionalImportRun> executeBulkStudentEnrollment({
    required String schoolId,
    required String classroomId,
    required List<Map<String, dynamic>> students,
    required String idempotencyKey,
  });

  /// Updates classroom member status (e.g. deactivate student to release seat).
  Future<void> updateClassroomMemberStatus({
    required String classroomId,
    required String userId,
    required String status,
  });

  /// Lists all available institutional subscription plans.
  Future<List<InstitutionalPlan>> getInstitutionalPlans();
}

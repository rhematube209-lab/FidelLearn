import '../../domain/models/licensing_onboarding_models.dart';
import '../../domain/repositories/licensing_onboarding_repository.dart';
import 'supabase_licensing_onboarding_repository.dart';

/// In-memory/local mock repository for P11 licensing, seats, and onboarding.
/// Provides offline and test resilience in adherence to Clean Architecture
/// and repository-pattern requirements.
class LocalLicensingOnboardingRepository
    implements LicensingOnboardingRepository {
  final Map<String, SchoolLicense> _licenses = {};
  final Map<String, SchoolSeatUsage> _seatUsage = {};
  final Map<String, SchoolOnboardingState> _onboardingStates = {};
  final List<InstitutionalPlan> _plans = [];

  LocalLicensingOnboardingRepository() {
    _initDemoData();
  }

  void _initDemoData() {
    _plans.addAll([
      const InstitutionalPlan(
        planCode: 'school_standard',
        displayName: 'School Standard',
        defaultStudentSeatLimit: 500,
        billingInterval: BillingInterval.annual,
        isActive: true,
        defaultEntitlements: {
          'student_learning': true,
          'teacher_portal': true,
          'leadership_dashboard': true,
          'assignments_interventions': true,
          'institutional_reporting': true,
          'national_exam_simulation': true,
        },
      ),
      const InstitutionalPlan(
        planCode: 'school_premium',
        displayName: 'School Premium Enterprise',
        defaultStudentSeatLimit: 1500,
        billingInterval: BillingInterval.annual,
        isActive: true,
        defaultEntitlements: {
          'student_learning': true,
          'teacher_portal': true,
          'leadership_dashboard': true,
          'assignments_interventions': true,
          'institutional_reporting': true,
          'national_exam_simulation': true,
          'sms_parent_notifications': true,
          'api_integration': true,
        },
      ),
    ]);
  }

  SchoolLicense _getOrCreateDemoLicense(String schoolId) {
    return _licenses.putIfAbsent(
      schoolId,
      () => SchoolLicense(
        id: 'lic-demo-$schoolId',
        schoolId: schoolId,
        planCode: 'school_standard',
        status: LicenseStatus.active,
        startsAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
        endsAt: DateTime.now().toUtc().add(const Duration(days: 335)),
        graceEndsAt: null,
        studentSeatLimit: 500,
        featureEntitlements: const {
          'student_learning': true,
          'teacher_portal': true,
          'leadership_dashboard': true,
          'assignments_interventions': true,
          'institutional_reporting': true,
          'national_exam_simulation': true,
        },
        billingCustomerRef: 'cus_demo_$schoolId',
        billingSubscriptionRef: 'sub_demo_$schoolId',
        source: 'telebirr',
        createdBy: 'platform-admin',
        createdAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
      ),
    );
  }

  @override
  Future<SchoolLicense> getSchoolLicense(String schoolId) async {
    return _getOrCreateDemoLicense(schoolId);
  }

  @override
  Future<SchoolSeatUsage> getSchoolSeatUsage(String schoolId) async {
    return _seatUsage.putIfAbsent(
      schoolId,
      () => const SchoolSeatUsage(
        schoolId: 'sch-001',
        licenseStatus: LicenseStatus.active,
        studentSeatLimit: 500,
        occupiedSeats: 320,
        availableSeats: 180,
        seatUtilizationPct: 64.0,
        isOverCapacity: false,
        warningLevel: 'none',
      ),
    );
  }

  @override
  Future<SchoolEntitlements> getSchoolEntitlements(String schoolId) async {
    final license = await getSchoolLicense(schoolId);
    return SchoolEntitlements.fromJson({
      'school_id': schoolId,
      'license_status': license.status.toDbString(),
      'entitlements': license.featureEntitlements,
    });
  }

  @override
  Future<bool> schoolHasEntitlement(String schoolId, String entitlement) async {
    final entitlements = await getSchoolEntitlements(schoolId);
    return entitlements.has(entitlement);
  }

  @override
  Future<SchoolOnboardingState> getSchoolOnboardingState(
      String schoolId) async {
    return _onboardingStates.putIfAbsent(
      schoolId,
      () => SchoolOnboardingState(
        schoolId: schoolId,
        status: OnboardingStatus.completed,
        schoolCreated: true,
        licenseConfigured: true,
        academicYearConfigured: true,
        classesConfigured: true,
        adminConfigured: true,
        teachersConfigured: true,
        teacherAssignmentsConfigured: true,
        studentsConfigured: true,
        coverageValidated: true,
        activationReady: true,
        activatedAt: DateTime.now().toUtc().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().toUtc().subtract(const Duration(days: 20)),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> validateSchoolActivation(String schoolId) async {
    final state = await getSchoolOnboardingState(schoolId);
    return {
      'school_id': schoolId,
      'is_ready': state.activationReady,
      'errors': <String>[],
      'warnings': <String>[],
      'validation_details': {
        'admin_configured': state.adminConfigured,
        'teachers_configured': state.teachersConfigured,
        'classes_configured': state.classesConfigured,
        'students_configured': state.studentsConfigured,
        'license_configured': state.licenseConfigured,
      },
    };
  }

  @override
  Future<SchoolOnboardingState> activateSchool(String schoolId) async {
    final updated = SchoolOnboardingState(
      schoolId: schoolId,
      status: OnboardingStatus.completed,
      schoolCreated: true,
      licenseConfigured: true,
      academicYearConfigured: true,
      classesConfigured: true,
      adminConfigured: true,
      teachersConfigured: true,
      teacherAssignmentsConfigured: true,
      studentsConfigured: true,
      coverageValidated: true,
      activationReady: true,
      activatedAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _onboardingStates[schoolId] = updated;
    return updated;
  }

  @override
  Future<InstitutionalImportRun> executeBulkStudentEnrollment({
    required String schoolId,
    required String classroomId,
    required List<Map<String, dynamic>> students,
    required String idempotencyKey,
  }) async {
    final seatUsage = await getSchoolSeatUsage(schoolId);
    if (seatUsage.occupiedSeats + students.length >
        seatUsage.studentSeatLimit) {
      throw SeatLimitExceededException(
        'SEAT_LIMIT_EXCEEDED: Cannot enroll ${students.length} students. '
        'Occupied: ${seatUsage.occupiedSeats}, Limit: ${seatUsage.studentSeatLimit}',
      );
    }

    return InstitutionalImportRun(
      id: 'run-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: schoolId,
      importType: 'students',
      requestedBy: 'current-admin',
      status: ImportRunStatus.completed,
      totalRows: students.length,
      validRows: students.length,
      invalidRows: 0,
      createdCount: students.length,
      existingCount: 0,
      errorCount: 0,
      idempotencyKey: idempotencyKey,
      errors: const [],
      createdAt: DateTime.now().toUtc(),
      completedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> updateClassroomMemberStatus({
    required String classroomId,
    required String userId,
    required String status,
  }) async {
    // In-memory mock status update
  }

  @override
  Future<List<InstitutionalPlan>> getInstitutionalPlans() async {
    return List.unmodifiable(_plans);
  }
}

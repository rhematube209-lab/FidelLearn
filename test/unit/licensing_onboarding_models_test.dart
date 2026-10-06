import 'package:fidel_learn/features/school/domain/models/licensing_onboarding_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P11 Licensing & Seats Domain Models Unit Tests', () {
    test('SchoolLicense parses correctly and evaluates entitlements by status',
        () {
      final json = {
        'id': 'lic-123',
        'school_id': 'sch-456',
        'plan_code': 'school_standard',
        'status': 'active',
        'starts_at': '2026-09-01T00:00:00Z',
        'ends_at': '2027-08-31T23:59:59Z',
        'grace_ends_at': null,
        'student_seat_limit': 500,
        'feature_entitlements': {
          'student_learning': true,
          'teacher_portal': true,
          'leadership_dashboard': true,
          'assignments_interventions': true,
          'institutional_reporting': true,
          'national_exam_simulation': true,
        },
        'billing_customer_ref': 'cus_123',
        'billing_subscription_ref': 'sub_456',
        'source': 'telebirr',
        'created_by': 'admin-uuid',
        'created_at': '2026-09-01T00:00:00Z',
        'updated_at': '2026-09-01T00:00:00Z',
      };

      final license = SchoolLicense.fromJson(json);

      expect(license.id, 'lic-123');
      expect(license.schoolId, 'sch-456');
      expect(license.planCode, 'school_standard');
      expect(license.status, LicenseStatus.active);
      expect(license.studentSeatLimit, 500);
      expect(license.hasEntitlement('institutional_reporting'), isTrue);
      expect(license.hasEntitlement('non_existent_feature'), isFalse);

      // Verify that suspended license denies all entitlements
      final suspendedJson = Map<String, dynamic>.from(json);
      suspendedJson['status'] = 'suspended';
      final suspendedLicense = SchoolLicense.fromJson(suspendedJson);
      expect(suspendedLicense.status, LicenseStatus.suspended);
      expect(
          suspendedLicense.hasEntitlement('institutional_reporting'), isFalse);

      // Verify that grace period retains operational entitlements
      final graceJson = Map<String, dynamic>.from(json);
      graceJson['status'] = 'grace';
      final graceLicense = SchoolLicense.fromJson(graceJson);
      expect(graceLicense.status, LicenseStatus.grace);
      expect(graceLicense.hasEntitlement('institutional_reporting'), isTrue);
    });

    test('SchoolSeatUsage calculates utilization and triggers warnings', () {
      // Normal 50% utilization
      final normal = SchoolSeatUsage.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'active',
        'student_seat_limit': 100,
        'occupied_seats': 50,
        'available_seats': 50,
        'seat_utilization_pct': 50.0,
        'is_over_capacity': false,
      });
      expect(normal.seatUtilizationPct, 50.0);
      expect(normal.warningLevel, 'none');
      expect(normal.isOverCapacity, isFalse);

      // 85% warning threshold
      final warn80 = SchoolSeatUsage.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'active',
        'student_seat_limit': 100,
        'occupied_seats': 85,
        'available_seats': 15,
        'seat_utilization_pct': 85.0,
        'is_over_capacity': false,
      });
      expect(warn80.warningLevel, 'warning_80');

      // 95% warning threshold
      final warn90 = SchoolSeatUsage.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'active',
        'student_seat_limit': 100,
        'occupied_seats': 95,
        'available_seats': 5,
        'seat_utilization_pct': 95.0,
        'is_over_capacity': false,
      });
      expect(warn90.warningLevel, 'warning_90');

      // 100% capacity threshold
      final crit = SchoolSeatUsage.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'active',
        'student_seat_limit': 100,
        'occupied_seats': 100,
        'available_seats': 0,
        'seat_utilization_pct': 100.0,
        'is_over_capacity': false,
      });
      expect(crit.warningLevel, 'critical_100');

      // Over capacity (e.g. seat limit decrease)
      final overCap = SchoolSeatUsage.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'active',
        'student_seat_limit': 100,
        'occupied_seats': 110,
        'available_seats': -10,
        'seat_utilization_pct': 110.0,
        'is_over_capacity': true,
      });
      expect(overCap.isOverCapacity, isTrue);
      expect(overCap.warningLevel, 'critical_100');
    });

    test('SchoolEntitlements model evaluates canonical feature boundaries', () {
      final active = SchoolEntitlements.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'active',
        'entitlements': {
          'student_learning': true,
          'teacher_portal': true,
          'leadership_dashboard': true,
          'assignments_interventions': true,
          'institutional_reporting': true,
          'national_exam_simulation': true,
        },
      });

      expect(active.studentLearning, isTrue);
      expect(active.teacherPortal, isTrue);
      expect(active.leadershipDashboard, isTrue);
      expect(active.assignmentsInterventions, isTrue);
      expect(active.institutionalReporting, isTrue);
      expect(active.nationalExamSimulation, isTrue);
      expect(active.has('institutional_reporting'), isTrue);

      final expired = SchoolEntitlements.fromJson(const {
        'school_id': 'sch-1',
        'license_status': 'expired',
        'entitlements': {
          'student_learning': true,
          'institutional_reporting': true,
        },
      });

      expect(expired.has('institutional_reporting'), isFalse);
    });

    test('SchoolOnboardingState computes progress and steps correctly', () {
      final state = SchoolOnboardingState(
        schoolId: 'sch-1',
        status: OnboardingStatus.inProgress,
        schoolCreated: true,
        licenseConfigured: true,
        academicYearConfigured: true,
        classesConfigured: true,
        adminConfigured: true,
        teachersConfigured: false,
        teacherAssignmentsConfigured: false,
        studentsConfigured: false,
        coverageValidated: false,
        activationReady: false,
        updatedAt: DateTime(2026, 9, 1),
      );

      expect(state.completedStepsCount, 5);
      expect(state.progressPct, 50.0);
    });

    test('InstitutionalImportRun serializes and tracks counts', () {
      final json = {
        'id': 'run-1',
        'school_id': 'sch-1',
        'import_type': 'students',
        'requested_by': 'admin-1',
        'status': 'completed',
        'total_rows': 25,
        'valid_rows': 25,
        'invalid_rows': 0,
        'created_count': 25,
        'existing_count': 0,
        'error_count': 0,
        'idempotency_key': 'key-abc-123',
        'errors': <dynamic>[],
        'created_at': '2026-09-01T00:00:00Z',
      };

      final run = InstitutionalImportRun.fromJson(json);
      expect(run.totalRows, 25);
      expect(run.createdCount, 25);
      expect(run.status, ImportRunStatus.completed);
      expect(run.idempotencyKey, 'key-abc-123');
    });
  });
}

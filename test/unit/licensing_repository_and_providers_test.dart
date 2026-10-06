import 'package:fidel_learn/features/school/data/repositories/local_licensing_onboarding_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/supabase_licensing_onboarding_repository.dart';
import 'package:fidel_learn/features/school/domain/models/licensing_onboarding_models.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/licensing_onboarding_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P11 Local Licensing Repository & Riverpod Providers Tests', () {
    late LocalLicensingOnboardingRepository repo;

    setUp(() {
      repo = LocalLicensingOnboardingRepository();
    });

    test('getSchoolLicense returns valid active license with entitlements',
        () async {
      final license = await repo.getSchoolLicense('sch-001');
      expect(license.schoolId, 'sch-001');
      expect(license.status, LicenseStatus.active);
      expect(license.studentSeatLimit, 500);
      expect(license.hasEntitlement('institutional_reporting'), isTrue);
      expect(license.hasEntitlement('nonexistent'), isFalse);
    });

    test(
        'getSchoolSeatUsage accurately computes available seats and utilization',
        () async {
      final usage = await repo.getSchoolSeatUsage('sch-001');
      expect(usage.studentSeatLimit, 500);
      expect(usage.occupiedSeats, 320);
      expect(usage.availableSeats, 180);
      expect(usage.seatUtilizationPct, 64.0);
      expect(usage.isOverCapacity, isFalse);
    });

    test('schoolHasEntitlement correctly evaluates active entitlements',
        () async {
      final hasReporting =
          await repo.schoolHasEntitlement('sch-001', 'institutional_reporting');
      expect(hasReporting, isTrue);

      final hasInvalid =
          await repo.schoolHasEntitlement('sch-001', 'invalid_flag');
      expect(hasInvalid, isFalse);
    });

    test(
        'getSchoolOnboardingState and activateSchool manage checklist lifecycle',
        () async {
      final state = await repo.getSchoolOnboardingState('sch-001');
      expect(state.activationReady, isTrue);
      expect(state.status, OnboardingStatus.completed);
      expect(state.progressPct, 100.0);

      final activated = await repo.activateSchool('sch-001');
      expect(activated.activationReady, isTrue);
      expect(activated.status, OnboardingStatus.completed);
    });

    test('executeBulkStudentEnrollment succeeds within seat capacity',
        () async {
      final students = [
        {'student_identifier': 'S001', 'display_name': 'Abebe'},
        {'student_identifier': 'S002', 'display_name': 'Kebede'},
      ];

      final run = await repo.executeBulkStudentEnrollment(
        schoolId: 'sch-001',
        classroomId: 'cls-001',
        students: students,
        idempotencyKey: 'batch-unit-test-1',
      );

      expect(run.status, ImportRunStatus.completed);
      expect(run.validRows, 2);
      expect(run.createdCount, 2);
    });

    test(
        'executeBulkStudentEnrollment throws SeatLimitExceededException when over limit',
        () async {
      final hugeBatch = List.generate(
        250,
        (i) => {'student_identifier': 'BIG_$i', 'display_name': 'Student $i'},
      );

      expect(
        () => repo.executeBulkStudentEnrollment(
          schoolId: 'sch-001',
          classroomId: 'cls-001',
          students: hugeBatch,
          idempotencyKey: 'batch-overflow',
        ),
        throwsA(isA<SeatLimitExceededException>()),
      );
    });

    test('getInstitutionalPlans returns preconfigured plans', () async {
      final plans = await repo.getInstitutionalPlans();
      expect(plans.length, 2);
      expect(plans.first.planCode, 'school_standard');
      expect(plans.last.planCode, 'school_premium');
    });

    test(
        'Riverpod container resolves fallback repository without crashing when offline',
        () async {
      final container = ProviderContainer(
        overrides: [
          licensingOnboardingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final resolvedRepo =
          container.read(licensingOnboardingRepositoryProvider);
      expect(resolvedRepo, isA<LocalLicensingOnboardingRepository>());

      final license =
          await container.read(schoolLicenseFamilyProvider('sch-001').future);
      expect(license.schoolId, 'sch-001');
      expect(license.status, LicenseStatus.active);

      final usage =
          await container.read(schoolSeatUsageFamilyProvider('sch-001').future);
      expect(usage.occupiedSeats, 320);

      final plans = await container.read(institutionalPlansProvider.future);
      expect(plans.isNotEmpty, isTrue);
    });

    test(
        'Switching active school context invalidates license and seat usage providers to new tenant',
        () async {
      final now = DateTime.now();
      final schoolA = School(
        id: 'sch-001',
        name: 'School A',
        schoolCode: 'SCH-A',
        createdAt: now,
        updatedAt: now,
      );
      final schoolB = School(
        id: 'sch-002',
        name: 'School B',
        schoolCode: 'SCH-B',
        createdAt: now,
        updatedAt: now,
      );

      final testNotifier = FakeActiveSchoolContextNotifier(
        ActiveSchoolContext(
          status: ActiveSchoolContextStatus.active,
          school: schoolA,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          licensingOnboardingRepositoryProvider.overrideWithValue(repo),
          activeSchoolContextProvider.overrideWith((ref) => testNotifier),
        ],
      );
      addTearDown(container.dispose);

      // 1. Initial resolution binds to School A
      final licenseA =
          await container.read(currentSchoolLicenseProvider.future);
      final usageA =
          await container.read(currentSchoolSeatUsageProvider.future);
      expect(licenseA?.schoolId, 'sch-001');
      expect(usageA?.occupiedSeats, 320);

      // 2. Switch context to School B
      testNotifier.setContext(
        ActiveSchoolContext(
          status: ActiveSchoolContextStatus.active,
          school: schoolB,
        ),
      );

      // 3. Current license rebinds to School B
      final licenseB =
          await container.read(currentSchoolLicenseProvider.future);
      expect(licenseB?.schoolId, 'sch-002');

      // 4. Invalidate/clear context to independent/null
      testNotifier.setContext(const ActiveSchoolContext.independent());
      final licenseNone =
          await container.read(currentSchoolLicenseProvider.future);
      expect(licenseNone, isNull);
    });
  });
}

class FakeActiveSchoolContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  FakeActiveSchoolContextNotifier(super.state);

  void setContext(ActiveSchoolContext ctx) {
    state = ctx;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

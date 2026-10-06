import 'package:fidel_learn/features/school/domain/models/licensing_onboarding_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/licensing_onboarding_providers.dart';
import 'package:fidel_learn/features/school/presentation/screens/school_license_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolLicenseScreen Widget Tests', () {
    testWidgets('renders license details, seat capacity and entitlements',
        (tester) async {
      final dummyLicense = SchoolLicense(
        id: 'lic-1',
        schoolId: 'sch-1',
        planCode: 'school_standard',
        status: LicenseStatus.active,
        startsAt: DateTime(2026, 9, 1),
        endsAt: DateTime(2027, 8, 31),
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
        source: 'manual_contract',
        createdBy: 'admin-uuid',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      const dummySeats = SchoolSeatUsage(
        schoolId: 'sch-1',
        licenseStatus: LicenseStatus.active,
        studentSeatLimit: 500,
        occupiedSeats: 430,
        availableSeats: 70,
        seatUtilizationPct: 86.0,
        isOverCapacity: false,
        warningLevel: 'warning_80',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolLicenseFamilyProvider('sch-1').overrideWith(
              (ref) => dummyLicense,
            ),
            schoolSeatUsageFamilyProvider('sch-1').overrideWith(
              (ref) => dummySeats,
            ),
          ],
          child: const MaterialApp(
            home: SchoolLicenseScreen(schoolId: 'sch-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify License Info
      expect(find.text('School License & Seats'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('SCHOOL_STANDARD'), findsOneWidget);
      expect(find.text('Source: MANUAL CONTRACT'), findsOneWidget);

      // Verify Seat Info
      expect(find.text('430 / 500 seats'), findsOneWidget);
      expect(find.text('86.0% used'), findsOneWidget);
      expect(find.text('Available Seats: 70'), findsOneWidget);

      // Verify Entitlements
      expect(find.text('Student Learning Platform'), findsOneWidget);
      expect(find.text('Teacher Portal (P7)'), findsOneWidget);
      expect(find.text('Leadership Dashboard (P8)'), findsOneWidget);
      expect(find.text('Institutional Analytics & Reporting (P10)'),
          findsOneWidget);
      expect(find.text('ESSLCE National Exam Simulation (P5)'), findsOneWidget);
    });

    testWidgets('renders critical seat limit alert when at 100% capacity',
        (tester) async {
      final dummyLicense = SchoolLicense(
        id: 'lic-1',
        schoolId: 'sch-1',
        planCode: 'school_standard',
        status: LicenseStatus.active,
        startsAt: DateTime(2026, 9, 1),
        endsAt: DateTime(2027, 8, 31),
        studentSeatLimit: 100,
        featureEntitlements: const {'student_learning': true},
        source: 'telebirr',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      const dummySeats = SchoolSeatUsage(
        schoolId: 'sch-1',
        licenseStatus: LicenseStatus.active,
        studentSeatLimit: 100,
        occupiedSeats: 100,
        availableSeats: 0,
        seatUtilizationPct: 100.0,
        isOverCapacity: false,
        warningLevel: 'critical_100',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolLicenseFamilyProvider('sch-1').overrideWith(
              (ref) => dummyLicense,
            ),
            schoolSeatUsageFamilyProvider('sch-1').overrideWith(
              (ref) => dummySeats,
            ),
          ],
          child: const MaterialApp(
            home: SchoolLicenseScreen(schoolId: 'sch-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('100 / 100 seats'), findsOneWidget);
      expect(find.text('100.0% used'), findsOneWidget);
      expect(find.text('Available Seats: 0'), findsOneWidget);
      expect(find.textContaining('Student seat limit reached'), findsOneWidget);
    });
  });
}

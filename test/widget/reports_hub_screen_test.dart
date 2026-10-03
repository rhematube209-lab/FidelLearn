import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/data/repositories/local_institutional_reporting_repository.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/institutional_reporting_providers.dart';
import 'package:fidel_learn/features/school/presentation/screens/reports_hub_screen.dart';

class _FakeSchoolContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  _FakeSchoolContextNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ReportsHubScreen renders tabs, KPIs, and non-causal banners',
      (tester) async {
    final school = School(
      id: 'demo-school-id',
      name: 'Bole Secondary School',
      schoolCode: 'BOLE-01',
      status: SchoolStatus.active,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final membership = SchoolMembership(
      id: 'demo-mem-id',
      schoolId: school.id,
      userId: 'admin-user',
      role: SchoolMemberRole.schoolAdmin,
      status: SchoolMembershipStatus.active,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final activeContext = ActiveSchoolContext(
      status: ActiveSchoolContextStatus.active,
      school: school,
      membership: membership,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => _FakeSchoolContextNotifier(activeContext),
          ),
          institutionalReportingRepositoryProvider.overrideWithValue(
            LocalInstitutionalReportingRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ReportsHubScreen(isTeacherView: false),
        ),
      ),
    );

    // Pump and advance timers for future providers
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify title and school name
    expect(find.text('Institutional Reports Hub'), findsOneWidget);
    expect(find.textContaining('Bole Secondary School'), findsOneWidget);

    // Verify Tab headers
    expect(find.text('Executive KPIs'), findsOneWidget);
    expect(find.text('Subject Evidence'), findsOneWidget);
    expect(find.text('Assignments & Interventions'), findsOneWidget);
    expect(find.text('Report History'), findsOneWidget);

    // Verify Executive KPIs
    expect(find.text('Key Institutional Metrics'), findsOneWidget);
    expect(find.text('Active Enrolled'), findsOneWidget);
    expect(find.text('1200'), findsOneWidget);
    expect(find.text('Assessment Participation'), findsOneWidget);
    expect(find.text('81.67%'), findsOneWidget);
    expect(find.text('Simulation Average'), findsOneWidget);
    expect(find.text('Assignment Completion'), findsOneWidget);
    expect(find.text('85.19%'), findsOneWidget);

    // Verify Disclaimers and Caveats
    expect(find.textContaining('institutional_analytics_v1'), findsOneWidget);
    expect(find.textContaining('Causation is not established'), findsOneWidget);
    expect(find.textContaining('NOT absence of offline student study'),
        findsOneWidget);
  });
}

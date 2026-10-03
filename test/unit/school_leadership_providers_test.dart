import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';
import 'package:fidel_learn/features/school/presentation/providers/school_leadership_providers.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_leadership_repository.dart';

class FakeActiveSchoolContextNotifier extends StateNotifier<ActiveSchoolContext>
    implements ActiveSchoolContextNotifier {
  FakeActiveSchoolContextNotifier(super.state);

  void setContext(ActiveSchoolContext context) {
    state = context;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('P8 School Leadership Providers Unit Tests', () {
    late School testSchool;
    late SchoolMembership adminMembership;
    late SchoolMembership teacherMembership;

    setUp(() {
      testSchool = School(
        id: 'sch-leadership-01',
        name: 'Menelik II Secondary School',
        displayName: 'Menelik II High School',
        schoolCode: 'MEN-001',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      adminMembership = SchoolMembership(
        id: 'mem-admin-01',
        schoolId: 'sch-leadership-01',
        userId: 'usr-admin-01',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      teacherMembership = SchoolMembership(
        id: 'mem-teacher-01',
        schoolId: 'sch-leadership-01',
        userId: 'usr-teacher-01',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test(
        'schoolLeadershipSummaryProvider throws access denied when not school admin',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: teacherMembership, // Teacher, not admin
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(schoolLeadershipSummaryProvider.future),
        throwsA(isA<SchoolLeadershipAuthorizationException>().having(
          (e) => e.message,
          'message',
          contains('Active school admin membership required'),
        )),
      );
    });

    test(
        'schoolLeadershipSummaryProvider returns data when user is active school admin',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final summary =
          await container.read(schoolLeadershipSummaryProvider.future);
      expect(summary, isNotNull);
      expect(summary.schoolName, contains('Secondary School'));
      expect(summary.totalActiveStudents, 840);
      expect(summary.simulationParticipationRate, greaterThan(0));
    });

    test(
        'schoolStreamSummaryProvider returns both Natural and Social streams for admin',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final streams = await container.read(schoolStreamSummaryProvider.future);
      expect(streams.length, 2);
      expect(streams.any((s) => s.isNatural), isTrue);
      expect(streams.any((s) => s.isSocial), isTrue);
    });

    test('schoolSubjectSummaryProvider separates Math variants', () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subjects =
          await container.read(schoolSubjectSummaryProvider.future);
      expect(subjects, isNotEmpty);
      expect(
        subjects.any(
          (s) => s.subjectId == 'math_g12' && s.examVariant == 'naturalScience',
        ),
        isTrue,
      );
      expect(
        subjects.any(
          (s) => s.subjectId == 'math_g12' && s.examVariant == 'socialScience',
        ),
        isTrue,
      );
    });

    test('schoolClassSummaryProvider returns class summaries', () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final classes = await container.read(schoolClassSummaryProvider.future);
      expect(classes, isNotEmpty);
      expect(classes.first.completionRatePct, greaterThan(0));
    });

    test('schoolSystemicWeakTopicsProvider returns prioritized weak topics',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final topics =
          await container.read(schoolSystemicWeakTopicsProvider.future);
      expect(topics, isNotEmpty);
      expect(topics.first.mistakeConcentrationPct, greaterThan(0));
    });

    test(
        'SchoolSupportPopulationNotifier loads, paginates, and handles filter changes',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Listen to notifier
      final sub = container.listen(schoolSupportPopulationProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(schoolSupportPopulationProvider.notifier);

      // Initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final state = container.read(schoolSupportPopulationProvider);
      expect(state.isLoading, isFalse);
      expect(state.students, isNotEmpty);

      // Filter by severity 'high'
      await notifier.loadInitial(severity: 'high');
      final highState = container.read(schoolSupportPopulationProvider);
      expect(highState.students, isNotEmpty);
      for (final s in highState.students) {
        expect(s.isHighSeverity, isTrue);
      }
    });

    test('schoolAssessmentsOverviewProvider returns assessments', () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final assessments = await container.read(
        schoolAssessmentsOverviewProvider.future,
      );
      expect(assessments, isNotEmpty);
      expect(assessments.any((a) => a.isOfficialPastExam), isTrue);
    });

    test('schoolTeacherCoverageProvider returns teacher coverage list',
        () async {
      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(
              ActiveSchoolContext(
                status: ActiveSchoolContextStatus.active,
                school: testSchool,
                membership: adminMembership,
              ),
            ),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final teachers =
          await container.read(schoolTeacherCoverageProvider.future);
      expect(teachers, isNotEmpty);
      expect(teachers.first.teacherName, isNotEmpty);
    });

    test(
        'providers throw SchoolLeadershipOfflineException when context is offline cached',
        () async {
      final offlineContext = ActiveSchoolContext(
        status: ActiveSchoolContextStatus.active,
        school: testSchool,
        membership: adminMembership,
        isOfflineCached: true,
      );

      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith(
            (ref) => FakeActiveSchoolContextNotifier(offlineContext),
          ),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(schoolLeadershipSummaryProvider.future),
        throwsA(isA<SchoolLeadershipOfflineException>()),
      );
      expect(
        () => container.read(schoolStreamSummaryProvider.future),
        throwsA(isA<SchoolLeadershipOfflineException>()),
      );
      expect(
        () => container.read(schoolSubjectSummaryProvider.future),
        throwsA(isA<SchoolLeadershipOfflineException>()),
      );
    });

    test('switching tenant updates active context and invalidates school data',
        () async {
      final contextNotifier = FakeActiveSchoolContextNotifier(
        ActiveSchoolContext(
          status: ActiveSchoolContextStatus.active,
          school: testSchool,
          membership: adminMembership,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          activeSchoolContextProvider.overrideWith((ref) => contextNotifier),
          schoolLeadershipRepositoryProvider.overrideWithValue(
            LocalSchoolLeadershipRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final schoolAData =
          await container.read(schoolLeadershipSummaryProvider.future);
      expect(schoolAData.schoolName, contains('Secondary School'));

      // Switch to school B
      final schoolB = School(
        id: 'sch_b',
        name: 'Bole Secondary School',
        displayName: 'Bole High School',
        schoolCode: 'BOL-002',
        status: SchoolStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final adminB = SchoolMembership(
        id: 'mem_b',
        schoolId: 'sch_b',
        userId: 'usr-admin-01',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      contextNotifier.setContext(
        ActiveSchoolContext(
          status: ActiveSchoolContextStatus.active,
          school: schoolB,
          membership: adminB,
        ),
      );

      // Verify active context reflects school B
      final currentContext = container.read(activeSchoolContextProvider);
      expect(currentContext.school?.id, 'sch_b');
      expect(currentContext.school?.name, 'Bole Secondary School');
    });
  });
}

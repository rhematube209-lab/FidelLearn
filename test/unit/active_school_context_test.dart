import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/security/auth_session_storage.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/school/data/repositories/local_school_repository.dart';
import 'package:fidel_learn/features/school/data/repositories/mock_classroom_repository.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/school/presentation/providers/active_school_context_provider.dart';

void main() {
  group('P6 Stage 2 ActiveSchoolContext & Affiliation Lifecycle Tests', () {
    late AuthSessionStorage storage;
    late School schoolA;
    late School schoolB;

    setUp(() async {
      storage = AuthSessionStorage();
      await storage.clearSession();
      await storage.clearSchoolContext();

      schoolA = School(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Bole Senior Secondary School',
        displayName: 'Bole Secondary',
        schoolCode: 'FID-BOL001',
        status: SchoolStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      schoolB = School(
        id: '22222222-2222-2222-2222-222222222222',
        name: 'Hawassa Comprehensive Secondary School',
        displayName: 'Hawassa Secondary',
        schoolCode: 'FID-HAW002',
        status: SchoolStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    });

    test('1. Zero memberships resolves to Independent Student context',
        () async {
      final mockSchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA],
        initialMemberships: [], // Empty: 0 memberships
      );
      final mockClassroomRepo = MockClassroomRepository();

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(mockSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(mockClassroomRepo),
        ],
      );
      addTearDown(container.dispose);

      // Authenticate user
      final user = UserProfile(
        id: 'u-independent',
        phoneNumber: '+251911000001',
        displayName: 'Independent Student',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(user);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      final context = container.read(activeSchoolContextProvider);
      expect(context.isIndependent, isTrue);
      expect(context.hasActiveSchool, isFalse);
      expect(context.status, equals(ActiveSchoolContextStatus.independent));
    });

    test('2. Single active membership auto-selects school and loads classrooms',
        () async {
      final membershipA = SchoolMembership(
        id: 'sm-a1',
        schoolId: schoolA.id,
        userId: 'u-student-1',
        role: SchoolMemberRole.student,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'STU-BOL-101',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final classA = Classroom(
        id: 'cls-a1',
        schoolId: schoolA.id,
        name: 'Grade 12 Natural - Section A',
        grade: 12,
        stream: 'naturalScience',
        academicYear: '2026/27',
        studentCount: 45,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockSchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA],
        initialMemberships: [membershipA],
      );
      final mockClassroomRepo = MockClassroomRepository(
        initialClassrooms: [classA],
      );

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(mockSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(mockClassroomRepo),
        ],
      );
      addTearDown(container.dispose);

      final user = UserProfile(
        id: 'u-student-1',
        phoneNumber: '+251911000002',
        displayName: 'Student One',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(user);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      final context = container.read(activeSchoolContextProvider);
      expect(context.hasActiveSchool, isTrue);
      expect(context.school?.id, equals(schoolA.id));
      expect(context.membership?.role, equals(SchoolMemberRole.student));
      expect(context.selectedClassroom?.id, equals('cls-a1'));
      expect(context.isStudent, isTrue);
      expect(context.isTeacher, isFalse);

      // Verify cached snapshot was written locally
      final cached = await storage.getCachedSchoolContext();
      expect(cached, isNotNull);
      expect(cached!.schoolId, equals(schoolA.id));
      expect(cached.membershipRole, equals(SchoolMemberRole.student));
    });

    test(
        '3. Multiple memberships: deterministic selection and manual school switcher',
        () async {
      final membershipA = SchoolMembership(
        id: 'sm-ta',
        schoolId: schoolA.id,
        userId: 'u-teacher-x',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'EMP-BOL-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final membershipB = SchoolMembership(
        id: 'sm-tb',
        schoolId: schoolB.id,
        userId: 'u-teacher-x',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'EMP-HAW-01',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final classA = Classroom(
        id: 'cls-a1',
        schoolId: schoolA.id,
        name: 'Grade 12 Natural - Section A',
        grade: 12,
        academicYear: '2026/27',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final classB = Classroom(
        id: 'cls-b1',
        schoolId: schoolB.id,
        name: 'Grade 12 Social - Section B',
        grade: 12,
        academicYear: '2026/27',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockSchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA, schoolB],
        initialMemberships: [membershipA, membershipB],
      );
      final mockClassroomRepo = MockClassroomRepository(
        initialClassrooms: [classA, classB],
      );

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(mockSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(mockClassroomRepo),
        ],
      );
      addTearDown(container.dispose);

      final teacherUser = UserProfile(
        id: 'u-teacher-x',
        phoneNumber: '+251911999999',
        displayName: 'Teacher X',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
      );

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(teacherUser);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      // Initially selects schoolA deterministically
      var context = container.read(activeSchoolContextProvider);
      expect(context.school?.id, equals(schoolA.id));
      expect(context.isTeacher, isTrue);

      // Now switch active school to School B
      await container
          .read(activeSchoolContextProvider.notifier)
          .selectSchool(schoolB.id);

      context = container.read(activeSchoolContextProvider);
      expect(context.school?.id, equals(schoolB.id));
      expect(context.school?.name,
          equals('Hawassa Comprehensive Secondary School'));
      expect(context.selectedClassroom?.id, equals('cls-b1'));

      // Check saved activeSchoolId
      final savedId = await storage.getActiveSchoolId();
      expect(savedId, equals(schoolB.id));
    });

    test('4. Inactive membership revokes active institutional context',
        () async {
      final inactiveMembership = SchoolMembership(
        id: 'sm-revoked',
        schoolId: schoolA.id,
        userId: 'u-departed',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.inactive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockSchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA],
        initialMemberships: [inactiveMembership],
      );
      final mockClassroomRepo = MockClassroomRepository();

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(mockSchoolRepo),
          classroomRepositoryProvider.overrideWithValue(mockClassroomRepo),
        ],
      );
      addTearDown(container.dispose);

      final user = UserProfile(
        id: 'u-departed',
        phoneNumber: '+251911000003',
        displayName: 'Departed Staff',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
      );

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(user);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      final context = container.read(activeSchoolContextProvider);
      expect(context.hasActiveSchool, isFalse);
      expect(context.isTeacher, isFalse);
      expect(
          context.status, equals(ActiveSchoolContextStatus.permissionRevoked));

      // Cached context must have been cleared
      final cached = await storage.getCachedSchoolContext();
      expect(cached, isNull);
    });

    test('5. Sign-out clears context and prevents cross-user state leaks',
        () async {
      final membership = SchoolMembership(
        id: 'sm-a1',
        schoolId: schoolA.id,
        userId: 'user-a',
        role: SchoolMemberRole.schoolAdmin,
        status: SchoolMembershipStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockSchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA],
        initialMemberships: [membership],
      );

      final container = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(mockSchoolRepo),
          classroomRepositoryProvider
              .overrideWithValue(MockClassroomRepository()),
        ],
      );
      addTearDown(container.dispose);

      // User A signs in
      final userA = UserProfile(
        id: 'user-a',
        phoneNumber: '+251911111111',
        displayName: 'Admin A',
        grade: 12,
        stream: 'common',
        preferredLanguage: 'en',
        role: UserRole.schoolAdmin,
        createdAt: DateTime.now(),
      );

      container.read(currentUserProvider.notifier).state =
          AsyncValue.data(userA);
      await container.read(activeSchoolContextProvider.notifier).refresh();

      expect(container.read(activeSchoolContextProvider).isSchoolAdmin, isTrue);

      // Sign out
      container.read(currentUserProvider.notifier).state =
          const AsyncValue.data(null);
      await container.pump();

      // State is immediately independent and cleared
      final contextAfterSignOut = container.read(activeSchoolContextProvider);
      expect(contextAfterSignOut.isIndependent, isTrue);
      expect(contextAfterSignOut.hasActiveSchool, isFalse);

      final cachedAfterLogout = await storage.getCachedSchoolContext();
      expect(cachedAfterLogout, isNull);

      // User B (Independent student) signs in
      final userB = UserProfile(
        id: 'user-b',
        phoneNumber: '+251922222222',
        displayName: 'Student B',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      final emptySchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA],
        initialMemberships: [], // User B has 0 memberships
      );

      final containerB = ProviderContainer(
        overrides: [
          schoolRepositoryProvider.overrideWithValue(emptySchoolRepo),
          classroomRepositoryProvider
              .overrideWithValue(MockClassroomRepository()),
        ],
      );
      addTearDown(containerB.dispose);

      containerB.read(currentUserProvider.notifier).state =
          AsyncValue.data(userB);
      await containerB.read(activeSchoolContextProvider.notifier).refresh();

      final contextB = containerB.read(activeSchoolContextProvider);
      expect(contextB.isIndependent, isTrue);
      expect(contextB.isSchoolAdmin, isFalse); // Zero User A admin leakage!
    });

    test('6. Regression: schoolId parameter is strictly honored in queries',
        () async {
      final mockSchoolRepo = LocalSchoolRepository(
        initialSchools: [schoolA, schoolB],
      );

      // Verify getSchool honors distinct IDs
      final foundA = await mockSchoolRepo.getSchool(schoolA.id);
      final foundB = await mockSchoolRepo.getSchool(schoolB.id);
      final foundMissing = await mockSchoolRepo.getSchool('non-existent-id');

      expect(foundA?.id, equals(schoolA.id));
      expect(foundA?.name, equals('Bole Senior Secondary School'));
      expect(foundB?.id, equals(schoolB.id));
      expect(foundB?.name, equals('Hawassa Comprehensive Secondary School'));
      expect(foundMissing, isNull);
    });
  });
}

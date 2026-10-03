import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('P6 Stage 2 Domain Models & Enum Forward Compatibility Tests', () {
    test('School model serialization, deserialization, and status parsing', () {
      final now = DateTime.now();
      final school = School(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Bole Senior Secondary School',
        displayName: 'Bole Secondary',
        schoolCode: 'FID-BOL001',
        status: SchoolStatus.active,
        city: 'Addis Ababa',
        region: 'Addis Ababa',
        timezone: 'Africa/Addis_Ababa',
        logoUrl: 'https://example.com/logo.png',
        createdBy: 'p0000000-0000-0000-0000-000000000000',
        createdAt: now,
        updatedAt: now,
      );

      final json = school.toJson();
      expect(json['id'], equals('11111111-1111-1111-1111-111111111111'));
      expect(json['status'], equals('active'));

      final fromJson = School.fromJson(json);
      expect(fromJson.id, equals(school.id));
      expect(fromJson.status, equals(SchoolStatus.active));
      expect(fromJson.isActive, isTrue);
      expect(fromJson.isSuspended, isFalse);

      // Forward compatibility: unknown future status parses to unknown (not active)
      expect(SchoolStatus.fromString('some_future_status'),
          equals(SchoolStatus.unknown));
      expect(SchoolStatus.fromString(null), equals(SchoolStatus.unknown));
      expect(
          SchoolStatus.fromString('suspended'), equals(SchoolStatus.suspended));
      expect(
          SchoolStatus.fromString('archived'), equals(SchoolStatus.archived));
    });

    test('SchoolMemberRole and SchoolMembershipStatus forward compatibility',
        () {
      expect(SchoolMemberRole.fromString('student'),
          equals(SchoolMemberRole.student));
      expect(SchoolMemberRole.fromString('teacher'),
          equals(SchoolMemberRole.teacher));
      expect(SchoolMemberRole.fromString('school_admin'),
          equals(SchoolMemberRole.schoolAdmin));
      expect(SchoolMemberRole.fromString('unknown_role'),
          equals(SchoolMemberRole.unknown));
      expect(
          SchoolMemberRole.fromString(null), equals(SchoolMemberRole.unknown));

      expect(SchoolMembershipStatus.fromString('invited'),
          equals(SchoolMembershipStatus.invited));
      expect(SchoolMembershipStatus.fromString('active'),
          equals(SchoolMembershipStatus.active));
      expect(SchoolMembershipStatus.fromString('inactive'),
          equals(SchoolMembershipStatus.inactive));
      expect(SchoolMembershipStatus.fromString('removed'),
          equals(SchoolMembershipStatus.removed));
      expect(SchoolMembershipStatus.fromString('unrecognized'),
          equals(SchoolMembershipStatus.unknown));
    });

    test('SchoolMembership model lifecycle and helpers', () {
      final now = DateTime.now();
      final activeTeacher = SchoolMembership(
        id: 'sm-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'u-teacher-1',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
        schoolStudentId: 'EMP-01',
        createdAt: now,
        updatedAt: now,
      );

      expect(activeTeacher.isActive, isTrue);
      expect(activeTeacher.isTeacher, isTrue);
      expect(activeTeacher.isSchoolAdmin, isFalse);
      expect(activeTeacher.isStudent, isFalse);

      final inactiveTeacher = SchoolMembership(
        id: 'sm-2',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'u-teacher-1',
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.inactive,
        createdAt: now,
        updatedAt: now,
      );

      expect(inactiveTeacher.isActive, isFalse);
      expect(inactiveTeacher.isTeacher,
          isFalse); // Inactive revokes teacher authority
    });

    test('SchoolMembershipWithSchool relational aggregate', () {
      final now = DateTime.now();
      final school = School(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Bole Senior Secondary School',
        schoolCode: 'FID-BOL001',
        status: SchoolStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final membership = SchoolMembership(
        id: 'sm-1',
        schoolId: school.id,
        userId: 'u-1',
        role: SchoolMemberRole.student,
        status: SchoolMembershipStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final aggregate = SchoolMembershipWithSchool(
        membership: membership,
        school: school,
      );

      expect(aggregate.isActive, isTrue);

      final json = aggregate.toJson();
      expect(json['schools'], isNotNull);
      final fromJson = SchoolMembershipWithSchool.fromJson(json);
      expect(fromJson.school.name, equals('Bole Senior Secondary School'));
      expect(fromJson.membership.id, equals('sm-1'));
    });

    test('Classroom model: no teacherId assumption & stream normalization', () {
      final now = DateTime.now();
      final classroom = Classroom(
        id: 'cls-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        name: 'Grade 12 Natural - Section A',
        grade: 12,
        stream: Classroom.normalizeStream('natural'),
        section: 'A',
        academicYear: '2026/27',
        studentCount: 48,
        createdAt: now,
        updatedAt: now,
      );

      expect(classroom.stream, equals('naturalScience'));
      expect(Classroom.normalizeStream('social'), equals('socialScience'));
      expect(Classroom.normalizeStream('common'), equals('common'));
      expect(classroom.studentCount, equals(48));

      final json = classroom.toJson();
      expect(json.containsKey('teacher_id'),
          isFalse); // Proves single teacherId assumption is removed

      final fromJson = Classroom.fromJson(json);
      expect(fromJson.name, equals('Grade 12 Natural - Section A'));
      expect(fromJson.stream, equals('naturalScience'));
    });

    test('TeacherSubjectAssignment using ExamVariantCode', () {
      final now = DateTime.now();
      final assignment = TeacherSubjectAssignment(
        id: 'tsa-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        teacherUserId: 't-1',
        classroomId: 'cls-1',
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.naturalScience,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      expect(assignment.examVariant, equals(ExamVariantCode.naturalScience));
      final json = assignment.toJson();
      expect(json['exam_variant'], equals('naturalScience'));

      final fromJson = TeacherSubjectAssignment.fromJson(json);
      expect(fromJson.examVariant, equals(ExamVariantCode.naturalScience));
    });

    test('CachedSchoolContext serialization and deserialization', () {
      final now = DateTime.now();
      final cached = CachedSchoolContext(
        schoolId: '11111111-1111-1111-1111-111111111111',
        schoolName: 'Bole Secondary',
        schoolCode: 'FID-BOL001',
        membershipId: 'sm-1',
        membershipRole: SchoolMemberRole.student,
        membershipStatus: SchoolMembershipStatus.active,
        activeClassroomId: 'cls-1',
        activeClassroomName: 'Grade 12 Natural - Section A',
        cachedAt: now,
      );

      final json = cached.toJson();
      final fromJson = CachedSchoolContext.fromJson(json);

      expect(fromJson.schoolId, equals(cached.schoolId));
      expect(fromJson.schoolName, equals('Bole Secondary'));
      expect(fromJson.membershipRole, equals(SchoolMemberRole.student));
      expect(fromJson.activeClassroomId, equals('cls-1'));
    });

    test('ActiveSchoolContext state machine and role helpers', () {
      const independent = ActiveSchoolContext.independent();
      expect(independent.isIndependent, isTrue);
      expect(independent.hasActiveSchool, isFalse);

      const loading = ActiveSchoolContext.loading();
      expect(loading.status, equals(ActiveSchoolContextStatus.loading));

      final active = ActiveSchoolContext(
        status: ActiveSchoolContextStatus.active,
        school: School(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Bole Senior Secondary School',
          schoolCode: 'FID-BOL001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        membership: SchoolMembership(
          id: 'sm-1',
          schoolId: '11111111-1111-1111-1111-111111111111',
          userId: 'u-1',
          role: SchoolMemberRole.teacher,
          status: SchoolMembershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(active.hasActiveSchool, isTrue);
      expect(active.isTeacher, isTrue);
      expect(active.isSchoolAdmin, isFalse);
      expect(active.isStudent, isFalse);
      expect(active.displaySchoolName, equals('Bole Senior Secondary School'));
    });

    test('InstitutionalAccess UI helper calculation', () {
      const teacherAccess = InstitutionalAccess(
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.active,
      );
      expect(teacherAccess.canTeach, isTrue);
      expect(teacherAccess.canAdministerSchool, isFalse);

      const inactiveTeacher = InstitutionalAccess(
        role: SchoolMemberRole.teacher,
        status: SchoolMembershipStatus.inactive,
      );
      expect(inactiveTeacher.canTeach,
          isFalse); // Inactive status revokes canTeach
    });
  });
}

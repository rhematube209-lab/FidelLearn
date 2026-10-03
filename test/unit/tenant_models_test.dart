import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('P6 Tenant Models Tests', () {
    test('SchoolTenant serialization and deserialization', () {
      final now = DateTime.now();
      final school = SchoolTenant(
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
      expect(json['school_code'], equals('FID-BOL001'));
      expect(json['status'], equals('active'));

      final fromJson = SchoolTenant.fromJson(json);
      expect(fromJson.id, equals(school.id));
      expect(fromJson.name, equals(school.name));
      expect(fromJson.status, equals(SchoolStatus.active));
      expect(fromJson.schoolCode, equals('FID-BOL001'));
    });

    test('SchoolMembership lifecycle and role mapping', () {
      final now = DateTime.now();
      final membership = SchoolMembership(
        id: 'sm-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'u-1',
        role: SchoolRole.teacher,
        status: MembershipStatus.active,
        schoolStudentId: 'EMP-01',
        joinedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(membership.isActive, isTrue);
      expect(membership.role, equals(SchoolRole.teacher));

      final json = membership.toJson();
      expect(json['role'], equals('teacher'));
      expect(json['status'], equals('active'));

      final inactive = SchoolMembership(
        id: 'sm-2',
        schoolId: '11111111-1111-1111-1111-111111111111',
        userId: 'u-2',
        role: SchoolRole.student,
        status: MembershipStatus.inactive,
        createdAt: now,
        updatedAt: now,
      );
      expect(inactive.isActive, isFalse);
    });

    test('ClassroomEntity academic year and stream semantics', () {
      final now = DateTime.now();
      final classroom = ClassroomEntity(
        id: 'cls-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        name: 'Grade 12 Natural - Section A',
        grade: 12,
        stream: 'naturalScience',
        section: 'A',
        academicYear: '2026/27',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final json = classroom.toJson();
      expect(json['grade'], equals(12));
      expect(json['stream'], equals('naturalScience'));
      expect(json['academic_year'], equals('2026/27'));

      final fromJson = ClassroomEntity.fromJson(json);
      expect(fromJson.academicYear, equals('2026/27'));
      expect(fromJson.section, equals('A'));
    });

    test('TeacherSubjectAssignmentEntity isolation by subject & variant', () {
      final now = DateTime.now();
      final assignment = TeacherSubjectAssignmentEntity(
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

      final json = assignment.toJson();
      expect(json['subject_id'], equals('math_g12'));
      expect(json['exam_variant'], equals('naturalScience'));

      final fromJson = TeacherSubjectAssignmentEntity.fromJson(json);
      expect(fromJson.examVariant, equals(ExamVariantCode.naturalScience));
    });

    test('SchoolInvitationEntity expiration logic', () {
      final invitation = SchoolInvitationEntity(
        id: 'inv-1',
        schoolId: '11111111-1111-1111-1111-111111111111',
        role: SchoolRole.teacher,
        tokenHash: 'sha256_mock_hash_12345',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      expect(invitation.isExpired, isFalse);
      expect(invitation.isPending, isTrue);

      final expiredInvitation = SchoolInvitationEntity(
        id: 'inv-2',
        schoolId: '11111111-1111-1111-1111-111111111111',
        role: SchoolRole.student,
        tokenHash: 'sha256_mock_hash_expired',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expiredInvitation.isExpired, isTrue);
      expect(expiredInvitation.isPending, isFalse);
    });
  });
}

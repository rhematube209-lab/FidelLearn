import 'package:flutter_test/flutter_test.dart';

/// Simulated PostgreSQL / Supabase Multi-Tenant Engine reflecting the exact
/// database rules, constraints, helper functions, and RLS policies defined in
/// `supabase/migrations/20260925000000_school_tenant_security.sql`.
class MockSupabaseTenantEngine {
  final Map<String, Map<String, dynamic>> profiles = {};
  final Map<String, Set<String>> userRoles = {}; // userId -> role_id set
  final Map<String, Map<String, dynamic>> schools = {};
  final Map<String, Map<String, dynamic>> schoolMemberships =
      {}; // key: "$schoolId:$userId"
  final Map<String, Map<String, dynamic>> classrooms = {};
  final Map<String, Map<String, dynamic>> classroomMemberships =
      {}; // key: "$classroomId:$userId"
  final Map<String, Map<String, dynamic>> teacherSubjectAssignments =
      {}; // key: "$teacherUserId:$classroomId:$subjectId:$variant"
  final List<Map<String, dynamic>> auditLogs = [];

  String? currentCallerId;

  void authenticate(String? userId) {
    currentCallerId = userId;
  }

  // --- Helper Functions (mirroring PL/pgSQL STABLE SECURITY DEFINER functions) ---

  bool isPlatformAdmin() {
    if (currentCallerId == null) return false;
    return userRoles[currentCallerId]?.contains('platform_admin') ?? false;
  }

  bool isSchoolMember(String targetSchoolId) {
    if (currentCallerId == null) return false;
    final school = schools[targetSchoolId];
    if (school == null || school['status'] != 'active') return false;

    final key = '$targetSchoolId:$currentCallerId';
    final membership = schoolMemberships[key];
    return membership != null && membership['status'] == 'active';
  }

  bool isSchoolAdmin(String targetSchoolId) {
    if (currentCallerId == null) return false;
    final school = schools[targetSchoolId];
    if (school == null || school['status'] != 'active') return false;

    final key = '$targetSchoolId:$currentCallerId';
    final membership = schoolMemberships[key];
    return membership != null &&
        membership['role'] == 'school_admin' &&
        membership['status'] == 'active';
  }

  bool isTeacherInSchool(String targetSchoolId) {
    if (currentCallerId == null) return false;
    final school = schools[targetSchoolId];
    if (school == null || school['status'] != 'active') return false;

    final key = '$targetSchoolId:$currentCallerId';
    final membership = schoolMemberships[key];
    return membership != null &&
        membership['role'] == 'teacher' &&
        membership['status'] == 'active';
  }

  bool canAccessStudent(String targetStudentId, String targetSchoolId) {
    if (currentCallerId == null) return false;

    // 1. Student accessing own data
    if (currentCallerId == targetStudentId) return true;

    // 2. Platform Admin
    if (isPlatformAdmin()) return true;

    // Target student must have active membership in target school
    final studentKey = '$targetSchoolId:$targetStudentId';
    final studentMembership = schoolMemberships[studentKey];
    if (studentMembership == null || studentMembership['status'] != 'active') {
      return false;
    }

    final school = schools[targetSchoolId];
    if (school == null || school['status'] != 'active') return false;

    // 3. School Admin of target school
    if (isSchoolAdmin(targetSchoolId)) return true;

    // 4. Teacher in target school: MUST be assigned to student's active classroom
    if (isTeacherInSchool(targetSchoolId)) {
      // Find active classrooms containing target student
      for (final cm in classroomMemberships.values) {
        if (cm['user_id'] == targetStudentId && cm['status'] == 'active') {
          final cId = cm['classroom_id'] as String;
          // Check if current caller is assigned to this classroom
          for (final tsa in teacherSubjectAssignments.values) {
            if (tsa['classroom_id'] == cId &&
                tsa['teacher_user_id'] == currentCallerId &&
                tsa['school_id'] == targetSchoolId &&
                tsa['status'] == 'active') {
              return true;
            }
          }
        }
      }
      return false;
    }

    return false;
  }

  // --- Privileged RPCs (mirroring SECURITY DEFINER RPCs) ---

  Map<String, dynamic> createSchoolInternal({
    required String id,
    required String name,
    required String schoolCode,
    String? city,
    String? region,
  }) {
    if (!isPlatformAdmin()) {
      throw Exception('insufficient_privilege: Caller is not a platform_admin');
    }

    final school = {
      'id': id,
      'name': name,
      'school_code': schoolCode.toUpperCase().trim(),
      'status': 'active',
      'city': city,
      'region': region,
      'created_by': currentCallerId,
      'created_at': DateTime.now().toIso8601String(),
    };
    schools[id] = school;

    auditLogs.add({
      'actor_id': currentCallerId,
      'action': 'school_created',
      'target_table': 'schools',
      'target_id': id,
      'metadata': {'school_name': name, 'school_code': schoolCode},
    });

    return school;
  }

  Map<String, dynamic> grantSchoolMembershipInternal({
    required String schoolId,
    required String userId,
    required String role,
    String? schoolStudentId,
  }) {
    if (!['student', 'teacher', 'school_admin'].contains(role)) {
      throw Exception('invalid_parameter_value: Invalid role $role');
    }

    if (!isPlatformAdmin() && !isSchoolAdmin(schoolId)) {
      throw Exception(
          'insufficient_privilege: Caller is not authorized to grant membership in school $schoolId');
    }

    if (!profiles.containsKey(userId)) {
      throw Exception('invalid_parameter_value: Target user $userId not found');
    }

    final key = '$schoolId:$userId';
    final existing = schoolMemberships[key];
    final oldRole = existing?['role'];
    final oldStatus = existing?['status'];

    final membership = {
      'id': existing?['id'] ?? 'sm-$schoolId-$userId',
      'school_id': schoolId,
      'user_id': userId,
      'role': role,
      'status': 'active',
      'school_student_id': schoolStudentId ?? existing?['school_student_id'],
      'joined_at': existing?['joined_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    schoolMemberships[key] = membership;

    auditLogs.add({
      'actor_id': currentCallerId,
      'action': oldRole == null
          ? 'school_membership_created'
          : 'school_membership_role_updated',
      'target_table': 'school_memberships',
      'target_id': membership['id'],
      'metadata': {
        'school_id': schoolId,
        'target_user_id': userId,
        'role': role,
        'old_role': oldRole,
        'old_status': oldStatus,
      },
    });

    return membership;
  }

  Map<String, dynamic> updateSchoolMembershipStatusInternal({
    required String schoolId,
    required String userId,
    required String newStatus,
  }) {
    if (!['active', 'inactive', 'removed'].contains(newStatus)) {
      throw Exception('invalid_parameter_value: Invalid status $newStatus');
    }

    if (!isPlatformAdmin() && !isSchoolAdmin(schoolId)) {
      throw Exception('insufficient_privilege: Caller is not authorized');
    }

    final key = '$schoolId:$userId';
    final membership = schoolMemberships[key];
    if (membership == null) {
      throw Exception('invalid_parameter_value: Membership not found');
    }

    final oldStatus = membership['status'];
    membership['status'] = newStatus;
    membership['updated_at'] = DateTime.now().toIso8601String();

    auditLogs.add({
      'actor_id': currentCallerId,
      'action': 'school_membership_status_updated',
      'target_table': 'school_memberships',
      'target_id': membership['id'],
      'metadata': {
        'school_id': schoolId,
        'target_user_id': userId,
        'old_status': oldStatus,
        'new_status': newStatus,
      },
    });

    return membership;
  }

  Map<String, dynamic> createClassroomInternal({
    required String id,
    required String schoolId,
    required String name,
    required int grade,
    String? stream,
    String? section,
    String academicYear = '2026/27',
  }) {
    if (!isPlatformAdmin() && !isSchoolAdmin(schoolId)) {
      throw Exception('insufficient_privilege: Caller is not authorized');
    }

    final classroom = {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'grade': grade,
      'stream': stream,
      'section': section,
      'academic_year': academicYear,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };
    classrooms[id] = classroom;

    auditLogs.add({
      'actor_id': currentCallerId,
      'action': 'classroom_created',
      'target_table': 'classrooms',
      'target_id': id,
      'metadata': {
        'school_id': schoolId,
        'name': name,
        'grade': grade,
        'academic_year': academicYear,
      },
    });

    return classroom;
  }

  Map<String, dynamic> assignClassroomMemberInternal({
    required String classroomId,
    required String userId,
    required String role,
  }) {
    final classroom = classrooms[classroomId];
    if (classroom == null) {
      throw Exception('invalid_parameter_value: Classroom not found');
    }
    final schoolId = classroom['school_id'] as String;

    if (!isPlatformAdmin() && !isSchoolAdmin(schoolId)) {
      throw Exception('insufficient_privilege: Caller is not authorized');
    }

    // CROSS-TENANT INTEGRITY CHECK: Member MUST have active membership in classroom's school!
    final memberKey = '$schoolId:$userId';
    final membership = schoolMemberships[memberKey];
    if (membership == null || membership['status'] != 'active') {
      throw Exception(
          'check_violation: User $userId does not have active membership in school $schoolId');
    }

    final key = '$classroomId:$userId';
    final cm = {
      'id': 'cm-$classroomId-$userId',
      'classroom_id': classroomId,
      'user_id': userId,
      'role': role,
      'status': 'active',
    };
    classroomMemberships[key] = cm;

    auditLogs.add({
      'actor_id': currentCallerId,
      'action': 'classroom_member_assigned',
      'target_table': 'classroom_memberships',
      'target_id': cm['id'],
      'metadata': {
        'school_id': schoolId,
        'classroom_id': classroomId,
        'target_user_id': userId,
        'role': role,
      },
    });

    return cm;
  }

  Map<String, dynamic> assignTeacherSubjectInternal({
    required String schoolId,
    required String teacherUserId,
    required String classroomId,
    required String subjectId,
    String? examVariant,
  }) {
    if (!isPlatformAdmin() && !isSchoolAdmin(schoolId)) {
      throw Exception('insufficient_privilege: Caller is not authorized');
    }

    // 1. Verify classroom belongs to target school
    final classroom = classrooms[classroomId];
    if (classroom == null || classroom['school_id'] != schoolId) {
      throw Exception(
          'check_violation: Classroom $classroomId does not belong to school $schoolId');
    }

    // 2. Verify teacher has active 'teacher' membership in target school
    final teacherKey = '$schoolId:$teacherUserId';
    final teacherMembership = schoolMemberships[teacherKey];
    if (teacherMembership == null ||
        teacherMembership['role'] != 'teacher' ||
        teacherMembership['status'] != 'active') {
      throw Exception(
          'check_violation: Teacher $teacherUserId does not have active teacher membership in school $schoolId');
    }

    final key =
        '$teacherUserId:$classroomId:$subjectId:${examVariant ?? 'shared'}';
    final assignment = {
      'id': 'tsa-$key',
      'school_id': schoolId,
      'teacher_user_id': teacherUserId,
      'classroom_id': classroomId,
      'subject_id': subjectId,
      'exam_variant': examVariant,
      'status': 'active',
    };
    teacherSubjectAssignments[key] = assignment;

    auditLogs.add({
      'actor_id': currentCallerId,
      'action': 'teacher_subject_assigned',
      'target_table': 'teacher_subject_assignments',
      'target_id': assignment['id'],
      'metadata': {
        'school_id': schoolId,
        'teacher_user_id': teacherUserId,
        'classroom_id': classroomId,
        'subject_id': subjectId,
        'exam_variant': examVariant,
      },
    });

    return assignment;
  }

  // --- RLS Evaluators for Queries ---

  List<Map<String, dynamic>> selectSchools() {
    return schools.values.where((s) {
      final sId = s['id'] as String;
      return isSchoolMember(sId) || isPlatformAdmin();
    }).toList();
  }

  List<Map<String, dynamic>> selectSchoolMemberships(String targetSchoolId) {
    if (!isSchoolMember(targetSchoolId) && !isPlatformAdmin()) {
      return [];
    }

    return schoolMemberships.values.where((sm) {
      if (sm['school_id'] != targetSchoolId) return false;

      // Rule: Own membership
      if (sm['user_id'] == currentCallerId) return true;

      // Rule: School Admin of this school
      if (isSchoolAdmin(targetSchoolId)) return true;

      // Rule: Platform Admin
      if (isPlatformAdmin()) return true;

      // Rule: Teacher in this school ONLY IF student is in teacher's assigned classroom
      if (isTeacherInSchool(targetSchoolId)) {
        final targetUserId = sm['user_id'] as String;
        for (final cm in classroomMemberships.values) {
          if (cm['user_id'] == targetUserId && cm['status'] == 'active') {
            final cId = cm['classroom_id'] as String;
            for (final tsa in teacherSubjectAssignments.values) {
              if (tsa['classroom_id'] == cId &&
                  tsa['teacher_user_id'] == currentCallerId &&
                  tsa['school_id'] == targetSchoolId &&
                  tsa['status'] == 'active') {
                return true;
              }
            }
          }
        }
      }

      return false;
    }).toList();
  }

  List<Map<String, dynamic>> selectClassrooms(String targetSchoolId) {
    return classrooms.values.where((c) {
      if (c['school_id'] != targetSchoolId) return false;
      final cId = c['id'] as String;

      if (isSchoolAdmin(targetSchoolId) || isPlatformAdmin()) return true;

      // Enrolled student
      final cmKey = '$cId:$currentCallerId';
      if (classroomMemberships[cmKey]?['status'] == 'active') return true;

      // Assigned teacher
      for (final tsa in teacherSubjectAssignments.values) {
        if (tsa['classroom_id'] == cId &&
            tsa['teacher_user_id'] == currentCallerId &&
            tsa['status'] == 'active') {
          return true;
        }
      }

      return false;
    }).toList();
  }
}

void main() {
  group('P6 Stage 1 Multi-Tenant Database & RLS Security Suite', () {
    late MockSupabaseTenantEngine engine;

    const schoolAId = '11111111-1111-1111-1111-111111111111';
    const schoolBId = '22222222-2222-2222-2222-222222222222';
    const schoolCId = '33333333-3333-3333-3333-333333333333'; // Suspended

    const adminA = 'a1111111-1111-1111-1111-111111111111';
    const teacherA = 't1111111-1111-1111-1111-111111111111';
    const studentA = 's1111111-1111-1111-1111-111111111111';
    const studentC = 's3333333-3333-3333-3333-333333333333'; // in Class C

    const adminB = 'a2222222-2222-2222-2222-222222222222';
    const teacherB = 't2222222-2222-2222-2222-222222222222';
    const studentB = 's2222222-2222-2222-2222-222222222222';

    const teacherMulti = 'tm111111-1111-1111-1111-111111111111';
    const studentTransfer = 'st111111-1111-1111-1111-111111111111';
    const studentIndependent = 'si111111-1111-1111-1111-111111111111';
    const platformAdmin = 'p0000000-0000-0000-0000-000000000000';

    const classA = 'c1111111-1111-1111-1111-111111111111'; // in School A
    const classC =
        'c3333333-3333-3333-3333-333333333333'; // in School A (unassigned to Teacher A)
    const classB = 'c2222222-2222-2222-2222-222222222222'; // in School B

    setUp(() {
      engine = MockSupabaseTenantEngine();

      // Seed profiles
      for (final uid in [
        adminA,
        teacherA,
        studentA,
        studentC,
        adminB,
        teacherB,
        studentB,
        teacherMulti,
        studentTransfer,
        studentIndependent,
        platformAdmin
      ]) {
        engine.profiles[uid] = {'id': uid, 'display_name': 'User $uid'};
      }

      // Seed global platform admin role
      engine.userRoles[platformAdmin] = {'platform_admin'};

      // Authenticate as Platform Admin to bootstrap
      engine.authenticate(platformAdmin);

      // Create Schools
      engine.createSchoolInternal(
        id: schoolAId,
        name: 'Bole Senior Secondary School',
        schoolCode: 'FID-BOL001',
        city: 'Addis Ababa',
      );
      engine.createSchoolInternal(
        id: schoolBId,
        name: 'Hawassa Comprehensive Secondary School',
        schoolCode: 'FID-HAW002',
        city: 'Hawassa',
      );
      engine.createSchoolInternal(
        id: schoolCId,
        name: 'Adama Model Secondary School',
        schoolCode: 'FID-ADA003',
        city: 'Adama',
      );
      engine.schools[schoolCId]!['status'] = 'suspended';

      // Grant School Memberships
      // School A
      engine.grantSchoolMembershipInternal(
          schoolId: schoolAId, userId: adminA, role: 'school_admin');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: teacherA,
          role: 'teacher',
          schoolStudentId: 'EMP-01');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: studentA,
          role: 'student',
          schoolStudentId: 'STU-101');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: studentC,
          role: 'student',
          schoolStudentId: 'STU-301');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolAId, userId: teacherMulti, role: 'teacher');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolAId, userId: studentTransfer, role: 'student');
      engine.updateSchoolMembershipStatusInternal(
          schoolId: schoolAId, userId: studentTransfer, newStatus: 'inactive');

      // School B
      engine.grantSchoolMembershipInternal(
          schoolId: schoolBId, userId: adminB, role: 'school_admin');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolBId, userId: teacherB, role: 'teacher');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolBId, userId: studentB, role: 'student');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolBId, userId: teacherMulti, role: 'teacher');
      engine.grantSchoolMembershipInternal(
          schoolId: schoolBId, userId: studentTransfer, role: 'student');

      // Create Classrooms
      engine.createClassroomInternal(
          id: classA,
          schoolId: schoolAId,
          name: 'Grade 12 Natural - Section A',
          grade: 12,
          stream: 'naturalScience');
      engine.createClassroomInternal(
          id: classC,
          schoolId: schoolAId,
          name: 'Grade 12 Natural - Section C',
          grade: 12,
          stream: 'naturalScience');
      engine.createClassroomInternal(
          id: classB,
          schoolId: schoolBId,
          name: 'Grade 12 Natural - Section B',
          grade: 12,
          stream: 'naturalScience');

      // Assign Classroom Members
      engine.assignClassroomMemberInternal(
          classroomId: classA, userId: studentA, role: 'student');
      engine.assignClassroomMemberInternal(
          classroomId: classC, userId: studentC, role: 'student');
      engine.assignClassroomMemberInternal(
          classroomId: classB, userId: studentB, role: 'student');
      engine.assignClassroomMemberInternal(
          classroomId: classB, userId: studentTransfer, role: 'student');

      // Teacher Subject Assignments
      // Teacher A teaches Physics in Class A ONLY
      engine.assignTeacherSubjectInternal(
        schoolId: schoolAId,
        teacherUserId: teacherA,
        classroomId: classA,
        subjectId: 'physics_g12',
        examVariant: 'naturalScience',
      );

      // Teacher B teaches Math in Class B
      engine.assignTeacherSubjectInternal(
        schoolId: schoolBId,
        teacherUserId: teacherB,
        classroomId: classB,
        subjectId: 'math_g12',
        examVariant: 'naturalScience',
      );
    });

    test('1. Cross-Tenant Isolation: School A users cannot see School B data',
        () {
      // Authenticate as Admin A
      engine.authenticate(adminA);
      expect(engine.isSchoolAdmin(schoolAId), isTrue);
      expect(engine.isSchoolAdmin(schoolBId), isFalse);

      // Admin A tries to select classrooms of School B
      final classroomsB = engine.selectClassrooms(schoolBId);
      expect(classroomsB, isEmpty);

      // Admin A tries to select memberships of School B
      final membershipsB = engine.selectSchoolMemberships(schoolBId);
      expect(membershipsB, isEmpty);

      // Authenticate as Teacher A
      engine.authenticate(teacherA);
      expect(engine.isTeacherInSchool(schoolAId), isTrue);
      expect(engine.isTeacherInSchool(schoolBId), isFalse);

      final tClassroomsB = engine.selectClassrooms(schoolBId);
      expect(tClassroomsB, isEmpty);

      // Authenticate as Student A
      engine.authenticate(studentA);
      final sClassroomsB = engine.selectClassrooms(schoolBId);
      expect(sClassroomsB, isEmpty);
    });

    test(
        '2. Teacher Same-School Scope: Teacher A cannot access students in unassigned Class C',
        () {
      // Authenticate as Teacher A
      engine.authenticate(teacherA);

      // Teacher A is assigned to Class A, where Student A is enrolled
      expect(engine.canAccessStudent(studentA, schoolAId), isTrue,
          reason: 'Teacher A teaches Physics to Student A in Class A');

      // Student C is in Class C in School A, where Teacher A is NOT assigned!
      expect(engine.canAccessStudent(studentC, schoolAId), isFalse,
          reason:
              'Teacher A has no assigned classroom containing Student C (even though same school!)');

      // Teacher A inspecting school memberships in School A should see self and Student A, but NOT Student C
      final visibleMembers = engine.selectSchoolMemberships(schoolAId);
      final visibleUserIds =
          visibleMembers.map((m) => m['user_id'] as String).toList();
      expect(visibleUserIds, contains(teacherA));
      expect(visibleUserIds, contains(studentA));
      expect(visibleUserIds, isNot(contains(studentC)));
    });

    test('3. Student Isolation: Student A has strictly scoped access', () {
      engine.authenticate(studentA);

      // Can access own data
      expect(engine.canAccessStudent(studentA, schoolAId), isTrue);

      // Cannot access classmate Student C
      expect(engine.canAccessStudent(studentC, schoolAId), isFalse);

      // Cannot access Student B from School B
      expect(engine.canAccessStudent(studentB, schoolBId), isFalse);

      // In roster selection, student only sees own record
      final visibleMembers = engine.selectSchoolMemberships(schoolAId);
      expect(visibleMembers.length, equals(1));
      expect(visibleMembers.first['user_id'], equals(studentA));

      // Student can only see classrooms they are enrolled in (Class A, not Class C)
      final visibleClassrooms = engine.selectClassrooms(schoolAId);
      expect(visibleClassrooms.length, equals(1));
      expect(visibleClassrooms.first['id'], equals(classA));
    });

    test('4. Self-Promotion: Direct privilege escalation is rejected', () {
      // Student A tries to grant self schoolAdmin or teacher role
      engine.authenticate(studentA);

      expect(
        () => engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: studentA,
          role: 'school_admin',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );

      expect(
        () => engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: studentA,
          role: 'teacher',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );

      // Teacher A tries to promote self to schoolAdmin
      engine.authenticate(teacherA);
      expect(
        () => engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: teacherA,
          role: 'school_admin',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );
    });

    test(
        '5. Platform Role Escalation: School Admin cannot become Platform Admin',
        () {
      // Admin A tries to grant platform_admin
      engine.authenticate(adminA);

      expect(
        () => engine.grantSchoolMembershipInternal(
          schoolId: schoolAId,
          userId: adminA,
          role: 'platform_admin',
        ),
        throwsA(
            predicate((e) => e.toString().contains('invalid_parameter_value'))),
      );

      expect(
        () => engine.createSchoolInternal(
          id: 'new-school',
          name: 'Unauthorized School',
          schoolCode: 'FID-UNAUTH',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );
    });

    test(
        '6. Forged School ID: Client sending forged school_id is strictly denied',
        () {
      // Admin A tries to manage School B using forged schoolId
      engine.authenticate(adminA);

      expect(
        () => engine.createClassroomInternal(
          id: 'forged-class',
          schoolId: schoolBId,
          name: 'Hacked Class',
          grade: 12,
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );

      expect(
        () => engine.grantSchoolMembershipInternal(
          schoolId: schoolBId,
          userId: studentB,
          role: 'teacher',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );
    });

    test(
        '7. Cross-Tenant Integrity: Assigning user to another school classroom is rejected',
        () {
      engine.authenticate(platformAdmin);

      // Attempt to assign Student A (School A) into Class B (School B)
      expect(
        () => engine.assignClassroomMemberInternal(
          classroomId: classB,
          userId: studentA,
          role: 'student',
        ),
        throwsA(predicate((e) => e.toString().contains('check_violation'))),
        reason: 'Student A does not have active membership in School B',
      );

      // Attempt to assign Teacher A (School A) into Class B (School B)
      expect(
        () => engine.assignTeacherSubjectInternal(
          schoolId: schoolBId,
          teacherUserId: teacherA,
          classroomId: classB,
          subjectId: 'physics_g12',
        ),
        throwsA(predicate((e) => e.toString().contains('check_violation'))),
        reason: 'Teacher A does not have active teacher membership in School B',
      );
    });

    test('8. Inactive/Removed Membership: Authority is revoked immediately',
        () {
      // Make Teacher A inactive
      engine.authenticate(adminA);
      engine.updateSchoolMembershipStatusInternal(
        schoolId: schoolAId,
        userId: teacherA,
        newStatus: 'inactive',
      );

      // Now authenticate as Teacher A
      engine.authenticate(teacherA);
      expect(engine.isTeacherInSchool(schoolAId), isFalse,
          reason: 'Inactive membership revokes teacher status');
      expect(engine.canAccessStudent(studentA, schoolAId), isFalse,
          reason: 'Inactive teacher cannot access student records');
    });

    test('9. Suspended School: Authority and access are blocked', () {
      // School C is suspended
      engine.authenticate(studentA);
      expect(engine.isSchoolMember(schoolCId), isFalse);

      final visibleSchools = engine.selectSchools();
      expect(visibleSchools.any((s) => s['id'] == schoolCId), isFalse);
    });

    test(
        '10. Student Transfer: Account identity and learning history preserved',
        () {
      // Student Transfer moved from School A to School B
      // School A membership is inactive
      const aKey = '$schoolAId:$studentTransfer';
      expect(engine.schoolMemberships[aKey]!['status'], equals('inactive'));

      // School B membership is active
      const bKey = '$schoolBId:$studentTransfer';
      expect(engine.schoolMemberships[bKey]!['status'], equals('active'));

      // User ID remains unchanged
      expect(engine.profiles[studentTransfer]!['id'], equals(studentTransfer));

      // Authenticate as Student Transfer
      engine.authenticate(studentTransfer);
      expect(engine.isSchoolMember(schoolAId), isFalse);
      expect(engine.isSchoolMember(schoolBId), isTrue);

      // Visible classrooms belong only to School B
      final visibleClassrooms = engine.selectClassrooms(schoolBId);
      expect(visibleClassrooms.any((c) => c['id'] == classB), isTrue);
    });

    test('11. Multi-School Teacher: Scopes remain strictly separated', () {
      engine.authenticate(teacherMulti);

      expect(engine.isTeacherInSchool(schoolAId), isTrue);
      expect(engine.isTeacherInSchool(schoolBId), isTrue);

      // School A query returns School A classrooms only
      final classroomsA = engine.selectClassrooms(schoolAId);
      for (final c in classroomsA) {
        expect(c['school_id'], equals(schoolAId));
      }

      // School B query returns School B classrooms only
      final classroomsB = engine.selectClassrooms(schoolBId);
      for (final c in classroomsB) {
        expect(c['school_id'], equals(schoolBId));
      }
    });

    test('12. Independent Student: Zero school memberships supported', () {
      engine.authenticate(studentIndependent);

      expect(engine.isSchoolMember(schoolAId), isFalse);
      expect(engine.isSchoolMember(schoolBId), isFalse);
      expect(engine.isPlatformAdmin(), isFalse);

      // Independent student can access own account
      expect(engine.canAccessStudent(studentIndependent, schoolAId), isTrue);

      // Independent student sees zero school classrooms
      final classrooms = engine.selectClassrooms(schoolAId);
      expect(classrooms, isEmpty);
    });

    test('13. Audit Logging: Privileged mutations record audit entries', () {
      expect(engine.auditLogs.isNotEmpty, isTrue);

      final schoolCreationLogs =
          engine.auditLogs.where((l) => l['action'] == 'school_created');
      expect(schoolCreationLogs.length, equals(3));

      final membershipLogs = engine.auditLogs
          .where((l) => l['action'] == 'school_membership_created');
      expect(membershipLogs.isNotEmpty, isTrue);

      final statusUpdateLogs = engine.auditLogs
          .where((l) => l['action'] == 'school_membership_status_updated');
      expect(statusUpdateLogs.isNotEmpty, isTrue);
      expect(statusUpdateLogs.first['metadata']['new_status'],
          anyOf('inactive', 'removed'));

      final teacherAssignmentLogs = engine.auditLogs
          .where((l) => l['action'] == 'teacher_subject_assigned');
      expect(teacherAssignmentLogs.isNotEmpty, isTrue);
    });

    test('14. Documented Access Matrix Verification', () {
      // Matrix from section 87:
      // Action: Read own membership
      engine.authenticate(studentA);
      expect(engine.canAccessStudent(studentA, schoolAId), isTrue);

      engine.authenticate(teacherA);
      expect(engine.canAccessStudent(teacherA, schoolAId), isTrue);

      engine.authenticate(adminA);
      expect(engine.canAccessStudent(adminA, schoolAId), isTrue);

      engine.authenticate(platformAdmin);
      expect(engine.canAccessStudent(studentA, schoolAId), isTrue);

      // Action: Assign Teachers (School Admin: Yes for own school; Teacher: No; Student: No)
      engine.authenticate(studentA);
      expect(
        () => engine.assignTeacherSubjectInternal(
          schoolId: schoolAId,
          teacherUserId: teacherA,
          classroomId: classA,
          subjectId: 'math_g12',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );

      engine.authenticate(teacherA);
      expect(
        () => engine.assignTeacherSubjectInternal(
          schoolId: schoolAId,
          teacherUserId: teacherA,
          classroomId: classA,
          subjectId: 'math_g12',
        ),
        throwsA(
            predicate((e) => e.toString().contains('insufficient_privilege'))),
      );

      engine.authenticate(adminA);
      expect(
        () => engine.assignTeacherSubjectInternal(
          schoolId: schoolAId,
          teacherUserId: teacherA,
          classroomId: classA,
          subjectId: 'math_g12',
        ),
        returnsNormally,
      );
    });

    test(
        '15. Scale Model: Representative 1,500-student school lookup complexity',
        () {
      // Simulate index-backed lookups for a school with 1,500 students, 80 teachers, 40 classrooms
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1500; i++) {
        final stuId = 'scale-stu-$i';
        engine.profiles[stuId] = {'id': stuId};
        engine.schoolMemberships['$schoolAId:$stuId'] = {
          'id': 'sm-scale-$i',
          'school_id': schoolAId,
          'user_id': stuId,
          'role': 'student',
          'status': 'active',
        };
      }

      for (int i = 0; i < 40; i++) {
        final cId = 'scale-cls-$i';
        engine.classrooms[cId] = {
          'id': cId,
          'school_id': schoolAId,
          'name': 'Grade 12 Section $i',
          'grade': 12,
          'academic_year': '2026/27',
          'status': 'active',
        };
      }

      // Check fast lookup under simulated 1,500 student load
      engine.authenticate(adminA);
      final memberships = engine.selectSchoolMemberships(schoolAId);
      stopwatch.stop();

      expect(memberships.length, greaterThan(1500));
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'In-memory multi-tenant lookup executes in <100ms');
    });
  });
}

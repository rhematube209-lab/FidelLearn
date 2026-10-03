import '../../domain/models/tenant_models.dart';
import '../../../../core/errors/failures.dart';

/// Data Transfer Object for School records from Supabase PostgREST.
class SchoolDto {
  final Map<String, dynamic> raw;

  const SchoolDto(this.raw);

  School toDomain() {
    return School.fromJson(raw);
  }

  static List<School> fromList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => School.fromJson(m))
        .toList();
  }
}

/// Data Transfer Object for SchoolMembership records from Supabase PostgREST.
class SchoolMembershipDto {
  final Map<String, dynamic> raw;

  const SchoolMembershipDto(this.raw);

  SchoolMembership toDomain() {
    return SchoolMembership.fromJson(raw);
  }

  SchoolMembershipWithSchool? toWithSchool() {
    final schoolJson = raw['schools'] as Map<String, dynamic>? ??
        raw['school'] as Map<String, dynamic>?;
    if (schoolJson == null) return null;
    return SchoolMembershipWithSchool(
      membership: toDomain(),
      school: School.fromJson(schoolJson),
    );
  }

  static List<SchoolMembershipWithSchool> fromWithSchoolList(
      List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => SchoolMembershipDto(m).toWithSchool())
        .whereType<SchoolMembershipWithSchool>()
        .toList();
  }
}

/// Data Transfer Object for Classroom records from Supabase PostgREST.
class ClassroomDto {
  final Map<String, dynamic> raw;

  const ClassroomDto(this.raw);

  Classroom toDomain() {
    return Classroom.fromJson(raw);
  }

  static List<Classroom> fromList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => Classroom.fromJson(m))
        .toList();
  }
}

/// Data Transfer Object for ClassroomMembership records from Supabase PostgREST.
class ClassroomMembershipDto {
  final Map<String, dynamic> raw;

  const ClassroomMembershipDto(this.raw);

  ClassroomMembership toDomain() {
    return ClassroomMembership.fromJson(raw);
  }

  static List<ClassroomMembership> fromList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => ClassroomMembership.fromJson(m))
        .toList();
  }
}

/// Data Transfer Object for TeacherSubjectAssignment records from Supabase PostgREST.
class TeacherSubjectAssignmentDto {
  final Map<String, dynamic> raw;

  const TeacherSubjectAssignmentDto(this.raw);

  TeacherSubjectAssignment toDomain() {
    return TeacherSubjectAssignment.fromJson(raw);
  }

  static List<TeacherSubjectAssignment> fromList(List<dynamic> list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => TeacherSubjectAssignment.fromJson(m))
        .toList();
  }
}

/// Error mapper converting Supabase/PostgREST exceptions to typed FidelLearn domain failures.
Failure mapSupabaseError(dynamic error) {
  final errorStr = error.toString().toLowerCase();

  // PostgreSQL 42501 / insufficient privilege / RLS denial
  if (errorStr.contains('42501') ||
      errorStr.contains('insufficient_privilege') ||
      errorStr.contains('permission denied') ||
      errorStr.contains('violates row-level security')) {
    return const PermissionDeniedFailure(
      'Access denied by institutional security policy.',
    );
  }

  // Network / socket / timeout
  if (errorStr.contains('socketexception') ||
      errorStr.contains('clientexception') ||
      errorStr.contains('connection refused') ||
      errorStr.contains('network is unreachable') ||
      errorStr.contains('timed out') ||
      errorStr.contains('timeout')) {
    return const NetworkFailure(
        'Network connection failed. Operating in offline mode.');
  }

  // Membership status / integrity
  if (errorStr.contains('membership_inactive') ||
      errorStr.contains('inactive membership')) {
    return const MembershipInactiveFailure('inactive');
  }

  if (errorStr.contains('not found') || errorStr.contains('pgrst116')) {
    return const NotFoundFailure('Requested institutional record not found.');
  }

  return ServerFailure('Institutional service error: $error', 'SUPABASE_ERROR');
}

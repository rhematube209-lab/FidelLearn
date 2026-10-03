import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/tenant_models.dart';
import '../../domain/repositories/classroom_repository.dart';
import '../models/school_dtos.dart';

/// Production Supabase implementation of ClassroomRepository.
/// Strictly relies on Stage 1 Row Level Security (RLS) as the security boundary.
class SupabaseClassroomRepository implements ClassroomRepository {
  final SupabaseClient? _client;

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClassroomRepository({SupabaseClient? client})
      : _client = client ?? _getSafeClient();

  String? get _currentUserId => _client?.auth.currentUser?.id;

  @override
  Future<List<Classroom>> getMyClassrooms({String? schoolId}) async {
    final client = _client;
    if (client == null || _currentUserId == null) return const [];

    try {
      dynamic query = client.from('classrooms').select();
      if (schoolId != null && schoolId.trim().isNotEmpty) {
        query = query.eq('school_id', schoolId.trim());
      }

      final response = await query
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 10));

      return ClassroomDto.fromList(response as List<dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Classroom?> getClassroom(String classroomId) async {
    if (classroomId.trim().isEmpty) return null;
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('classrooms')
          .select()
          .eq('id', classroomId.trim())
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (response == null) return null;
      return ClassroomDto(response).toDomain();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<ClassroomMembership>> getMyClassroomMemberships({
    String? classroomId,
  }) async {
    final client = _client;
    final userId = _currentUserId;
    if (client == null || userId == null) return const [];

    try {
      dynamic query =
          client.from('classroom_memberships').select().eq('user_id', userId);

      if (classroomId != null && classroomId.trim().isNotEmpty) {
        query = query.eq('classroom_id', classroomId.trim());
      }

      final response = await query.timeout(const Duration(seconds: 10));
      return ClassroomMembershipDto.fromList(response as List<dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<TeacherSubjectAssignment>> getMyTeacherAssignments({
    String? schoolId,
  }) async {
    final client = _client;
    final userId = _currentUserId;
    if (client == null || userId == null) return const [];

    try {
      dynamic query = client
          .from('teacher_subject_assignments')
          .select()
          .eq('teacher_user_id', userId);

      if (schoolId != null && schoolId.trim().isNotEmpty) {
        query = query.eq('school_id', schoolId.trim());
      }

      final response = await query.timeout(const Duration(seconds: 10));
      return TeacherSubjectAssignmentDto.fromList(response as List<dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<TeacherSubjectAssignment>> getAssignmentsForClassroom(
    String classroomId,
  ) async {
    if (classroomId.trim().isEmpty) return const [];
    final client = _client;
    if (client == null) return const [];

    try {
      final response = await client
          .from('teacher_subject_assignments')
          .select()
          .eq('classroom_id', classroomId.trim())
          .timeout(const Duration(seconds: 10));

      return TeacherSubjectAssignmentDto.fromList(response as List<dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/teacher_portal_models.dart';
import '../../domain/repositories/teacher_portal_repository.dart';
import '../../../school/domain/models/tenant_models.dart';

/// Production Supabase implementation of [TeacherPortalRepository].
///
/// All data is fetched via SECURITY DEFINER PostgreSQL functions defined in
/// migration 20260925010000_p7_teacher_portal.sql.
///
/// Authorization is enforced server-side. This class is a thin adapter.
///
/// Error handling:
///   - PostgreSQL NOT_AUTHORIZED exceptions are rethrown as [TeacherAuthorizationException].
///   - Network errors are rethrown for the caller to handle.
///   - Unexpected data shapes are logged and return empty / null.
class SupabaseTeacherPortalRepository implements TeacherPortalRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<TeacherAssignedClass>> getAssignedClasses({
    required String schoolId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_assigned_classes',
        params: {'p_school_id': schoolId},
      );

      if (rows is! List) return [];

      return rows.map<TeacherAssignedClass>((row) {
        final m = row as Map<String, dynamic>;
        final classroom = Classroom(
          id: m['classroom_id'] as String,
          schoolId: schoolId,
          name: m['classroom_name'] as String,
          grade: m['classroom_grade'] as int,
          stream: m['classroom_stream'] as String? ?? '',
          section: m['classroom_section'] as String? ?? '',
          academicYear: m['classroom_academic_year'] as String? ?? '',
          studentCount: m['enrolled_student_count'] as int? ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: m['classroom_status'] as String? ?? 'active',
        );
        return TeacherAssignedClass(
          assignmentId: m['assignment_id'] as String,
          classroom: classroom,
          subjectId: m['subject_id'] as String,
          subjectName:
              m['subject_id'] as String, // resolved by content repo in provider
          examVariant: m['exam_variant'] as String?,
          enrolledStudentCount: m['enrolled_student_count'] as int? ?? 0,
        );
      }).toList();
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_AUTHORIZED')) {
        throw TeacherAuthorizationException(
          'get_teacher_assigned_classes: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('SupabaseTeacherPortalRepository.getAssignedClasses: $e');
      return [];
    }
  }

  @override
  Future<ClassRosterPage> getClassRoster({
    required String classroomId,
    required String subjectId,
    int pageSize = 25,
    int offset = 0,
    String? search,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_class_roster',
        params: {
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_limit': pageSize,
          'p_offset': offset,
          if (search != null && search.isNotEmpty) 'p_search': search,
        },
      );

      if (rows is! List || rows.isEmpty) {
        return ClassRosterPage(
          students: const [],
          totalCount: 0,
          currentOffset: offset,
          pageSize: pageSize,
        );
      }

      final totalCount =
          (rows.first as Map<String, dynamic>)['total_count'] as int? ??
              rows.length;

      final students = rows.map<ClassRosterStudent>((row) {
        final m = row as Map<String, dynamic>;
        return ClassRosterStudent(
          userId: m['user_id'] as String,
          displayName: m['display_name'] as String,
          schoolStudentId: m['school_student_id'] as String?,
          recentAttemptCount: m['recent_attempt_count'] as int? ?? 0,
          recentAvgPercentage: (m['recent_avg_percentage'] as num?)?.toDouble(),
          activeMistakeCount: m['active_mistake_count'] as int? ?? 0,
          lastActivityAt: m['last_activity_at'] != null
              ? DateTime.parse(m['last_activity_at'] as String)
              : null,
        );
      }).toList();

      return ClassRosterPage(
        students: students,
        totalCount: totalCount,
        currentOffset: offset,
        pageSize: pageSize,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_AUTHORIZED')) {
        throw TeacherAuthorizationException(
          'get_teacher_class_roster: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('SupabaseTeacherPortalRepository.getClassRoster: $e');
      return ClassRosterPage(
        students: const [],
        totalCount: 0,
        currentOffset: offset,
        pageSize: pageSize,
      );
    }
  }

  @override
  Future<List<ClassWeakTopic>> getClassWeakTopics({
    required String classroomId,
    required String subjectId,
    int limit = 10,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_class_weak_topics',
        params: {
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_limit': limit,
        },
      );

      if (rows is! List) return [];
      return rows
          .map((r) => ClassWeakTopic.fromJson(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_AUTHORIZED')) {
        throw TeacherAuthorizationException(
          'get_teacher_class_weak_topics: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('SupabaseTeacherPortalRepository.getClassWeakTopics: $e');
      return [];
    }
  }

  @override
  Future<List<ClassExamSummary>> getClassExamSummary({
    required String classroomId,
    required String subjectId,
    int limit = 5,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_class_exam_summary',
        params: {
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_limit': limit,
        },
      );

      if (rows is! List) return [];
      return rows
          .map((r) => ClassExamSummary.fromJson(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_AUTHORIZED')) {
        throw TeacherAuthorizationException(
          'get_teacher_class_exam_summary: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('SupabaseTeacherPortalRepository.getClassExamSummary: $e');
      return [];
    }
  }

  @override
  Future<AttentionPage> getAttentionStudents({
    required String classroomId,
    required String subjectId,
    int pageSize = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_attention_students',
        params: {
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_limit': pageSize,
          'p_offset': offset,
        },
      );

      if (rows is! List || rows.isEmpty) {
        return AttentionPage(
          items: const [],
          totalCount: 0,
          currentOffset: offset,
          pageSize: pageSize,
        );
      }

      final totalCount =
          (rows.first as Map<String, dynamic>)['total_count'] as int? ??
              rows.length;

      final items = rows
          .map((r) => StudentAttentionItem.fromJson(
              r as Map<String, dynamic>, subjectId))
          .toList();

      return AttentionPage(
        items: items,
        totalCount: totalCount,
        currentOffset: offset,
        pageSize: pageSize,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_AUTHORIZED')) {
        throw TeacherAuthorizationException(
          'get_teacher_attention_students: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('SupabaseTeacherPortalRepository.getAttentionStudents: $e');
      return AttentionPage(
        items: const [],
        totalCount: 0,
        currentOffset: offset,
        pageSize: pageSize,
      );
    }
  }

  @override
  Future<StudentAcademicSummary?> getStudentSummary({
    required String studentId,
    required String classroomId,
    required String subjectId,
    required String subjectName,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_student_summary',
        params: {
          'p_student_id': studentId,
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
        },
      );

      if (rows is! List || rows.isEmpty) return null;

      final m = {
        ...rows.first as Map<String, dynamic>,
        'subject_id': subjectId,
      };
      return StudentAcademicSummary.fromJson(m, subjectName);
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_AUTHORIZED')) {
        throw TeacherAuthorizationException(
          'get_teacher_student_summary: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('SupabaseTeacherPortalRepository.getStudentSummary: $e');
      return null;
    }
  }
}

/// Thrown when the server rejects a teacher portal request due to authorization.
/// Callers should handle this by redirecting to the school selector or home.
class TeacherAuthorizationException implements Exception {
  final String message;
  const TeacherAuthorizationException(this.message);

  @override
  String toString() => 'TeacherAuthorizationException: $message';
}

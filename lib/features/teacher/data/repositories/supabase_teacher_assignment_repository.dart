import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/assignment_models.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';

/// Production Supabase implementation of [TeacherAssignmentRepository].
/// All mutations and queries invoke Security Definer PostgreSQL RPCs.
class SupabaseTeacherAssignmentRepository
    implements TeacherAssignmentRepository {
  final SupabaseClient? _customClient;

  SupabaseTeacherAssignmentRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<LearningAssignment>> getTeacherAssignments({
    required String schoolId,
    String? classroomId,
    String? subjectId,
    AssignmentStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_assignments',
        params: {
          'p_school_id': schoolId,
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_status': status?.dbValue,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<LearningAssignment>(
              (r) => LearningAssignment.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] getTeacherAssignments error: $e');
      rethrow;
    }
  }

  @override
  Future<AssignmentProgressSummary> getAssignmentProgress({
    required String assignmentId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_assignment_progress',
        params: {
          'p_assignment_id': assignmentId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final recipients = (rows is List)
          ? rows
              .map<AssignmentRecipient>((r) =>
                  AssignmentRecipient.fromJson(r as Map<String, dynamic>))
              .toList()
          : <AssignmentRecipient>[];

      // Fetch assignment metadata row
      final assignRows = await _client
          .from('learning_assignments')
          .select()
          .eq('id', assignmentId)
          .limit(1);

      final assignment = assignRows.isNotEmpty
          ? LearningAssignment.fromJson(assignRows.first)
          : LearningAssignment(
              id: assignmentId,
              schoolId: '',
              classroomId: '',
              teacherUserId: '',
              subjectId: '',
              title: 'Assignment',
              assignmentType: AssignmentType.targetedPractice,
              status: AssignmentStatus.published,
              totalQuestions: 0,
              createdAt: DateTime.now(),
            );

      final notStarted = recipients
          .where((r) => r.status == AssignmentRecipientStatus.assigned)
          .length;
      final inProgress = recipients
          .where((r) => r.status == AssignmentRecipientStatus.inProgress)
          .length;
      final submitted = recipients
          .where((r) =>
              r.status == AssignmentRecipientStatus.submitted ||
              r.status == AssignmentRecipientStatus.completed)
          .length;
      final lateCount = recipients
          .where((r) => r.status == AssignmentRecipientStatus.late)
          .length;
      final excused = recipients
          .where((r) => r.status == AssignmentRecipientStatus.excused)
          .length;

      return AssignmentProgressSummary(
        assignment: assignment,
        recipients: recipients,
        totalAssigned: recipients.length,
        notStartedCount: notStarted,
        inProgressCount: inProgress,
        submittedCount: submitted,
        lateCount: lateCount,
        excusedCount: excused,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] getAssignmentProgress error: $e');
      rethrow;
    }
  }

  @override
  Future<String> createAssignmentDraft({
    required String schoolId,
    required String classroomId,
    required String subjectId,
    String? examVariant,
    required String title,
    String? instructions,
    required AssignmentType assignmentType,
    int timeLimitMinutes = 0,
    DateTime? dueAt,
    bool allowLateSubmission = true,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'create_learning_assignment',
        params: {
          'p_school_id': schoolId,
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_exam_variant': examVariant,
          'p_title': title,
          'p_instructions': instructions,
          'p_assignment_type': assignmentType.dbValue,
          'p_time_limit_minutes': timeLimitMinutes,
          'p_due_at': dueAt?.toIso8601String(),
          'p_allow_late_submission': allowLateSubmission,
        },
      );

      return res as String;
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] createAssignmentDraft error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateAssignmentDraft({
    required String assignmentId,
    required String title,
    String? instructions,
    int? timeLimitMinutes,
    DateTime? dueAt,
    bool? allowLateSubmission,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'update_learning_assignment_draft',
        params: {
          'p_assignment_id': assignmentId,
          'p_title': title,
          'p_instructions': instructions,
          'p_time_limit_minutes': timeLimitMinutes,
          'p_due_at': dueAt?.toIso8601String(),
          'p_allow_late_submission': allowLateSubmission,
        },
      );
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] updateAssignmentDraft error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> publishAssignment({
    required String assignmentId,
    required List<String> questionIds,
    List<String>? recipientStudentIds,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'publish_learning_assignment',
        params: {
          'p_assignment_id': assignmentId,
          'p_question_ids': questionIds,
          'p_recipient_student_ids': recipientStudentIds,
        },
      );

      return (res is Map<String, dynamic>) ? res : <String, dynamic>{};
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] publishAssignment error: $e');
      rethrow;
    }
  }

  @override
  Future<void> closeAssignment(String assignmentId) async {
    try {
      await _client.rpc<dynamic>(
        'close_learning_assignment',
        params: {'p_assignment_id': assignmentId},
      );
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] closeAssignment error: $e');
      rethrow;
    }
  }

  @override
  Future<void> archiveAssignment(String assignmentId) async {
    try {
      await _client.rpc<dynamic>(
        'archive_learning_assignment',
        params: {'p_assignment_id': assignmentId},
      );
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] archiveAssignment error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addRecipient({
    required String assignmentId,
    required String studentUserId,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'add_assignment_recipient',
        params: {
          'p_assignment_id': assignmentId,
          'p_student_user_id': studentUserId,
        },
      );
    } catch (e) {
      debugPrint(
          '[SupabaseTeacherAssignmentRepository] addRecipient error: $e');
      rethrow;
    }
  }
}

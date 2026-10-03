import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/assignment_models.dart';
import '../../domain/repositories/intervention_repository.dart';

/// Production Supabase implementation of [InterventionRepository].
class SupabaseInterventionRepository implements InterventionRepository {
  final SupabaseClient? _customClient;

  SupabaseInterventionRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<StudentIntervention>> getTeacherInterventions({
    required String schoolId,
    String? classroomId,
    String? subjectId,
    InterventionStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_teacher_interventions',
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
          .map<StudentIntervention>(
              (r) => StudentIntervention.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          '[SupabaseInterventionRepository] getTeacherInterventions error: $e');
      rethrow;
    }
  }

  @override
  Future<String> createIntervention({
    required String schoolId,
    required String classroomId,
    required String subjectId,
    String? examVariant,
    required String studentUserId,
    required InterventionSource source,
    required List<String> sourceReasonCodes,
    String? severityAtCreation,
    required InterventionActionType actionType,
    String? linkedAssignmentId,
    String? teacherNote,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'create_student_intervention',
        params: {
          'p_school_id': schoolId,
          'p_classroom_id': classroomId,
          'p_subject_id': subjectId,
          'p_exam_variant': examVariant,
          'p_student_user_id': studentUserId,
          'p_source': source.dbValue,
          'p_source_reason_codes': sourceReasonCodes,
          'p_severity_at_creation': severityAtCreation,
          'p_action_type': actionType.dbValue,
          'p_linked_assignment_id': linkedAssignmentId,
          'p_teacher_note': teacherNote,
        },
      );

      return res as String;
    } catch (e) {
      debugPrint(
          '[SupabaseInterventionRepository] createIntervention error: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeIntervention(String interventionId) async {
    try {
      await _client.rpc<dynamic>(
        'complete_student_intervention',
        params: {'p_intervention_id': interventionId},
      );
    } catch (e) {
      debugPrint(
          '[SupabaseInterventionRepository] completeIntervention error: $e');
      rethrow;
    }
  }

  @override
  Future<void> closeIntervention(String interventionId) async {
    try {
      await _client.rpc<dynamic>(
        'close_student_intervention',
        params: {'p_intervention_id': interventionId},
      );
    } catch (e) {
      debugPrint(
          '[SupabaseInterventionRepository] closeIntervention error: $e');
      rethrow;
    }
  }
}

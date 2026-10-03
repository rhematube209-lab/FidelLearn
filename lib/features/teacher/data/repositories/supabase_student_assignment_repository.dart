import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/assignment_models.dart';
import '../../domain/repositories/student_assignment_repository.dart';

/// Production Supabase implementation of [StudentAssignmentRepository].
class SupabaseStudentAssignmentRepository
    implements StudentAssignmentRepository {
  final SupabaseClient? _customClient;

  SupabaseStudentAssignmentRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<StudentAssignment>> getStudentAssignments({
    AssignmentRecipientStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_student_assignments',
        params: {
          'p_status': status?.dbValue,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<StudentAssignment>(
              (r) => StudentAssignment.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          '[SupabaseStudentAssignmentRepository] getStudentAssignments error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getAssignmentDetail(String assignmentId) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_student_assignment_detail',
        params: {'p_assignment_id': assignmentId},
      );

      return (res is Map<String, dynamic>) ? res : <String, dynamic>{};
    } catch (e) {
      debugPrint(
          '[SupabaseStudentAssignmentRepository] getAssignmentDetail error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> submitAssignment({
    required String assignmentId,
    required String attemptId,
    required int score,
    required double percentage,
    DateTime? submittedAt,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'submit_student_assignment',
        params: {
          'p_assignment_id': assignmentId,
          'p_attempt_id': attemptId,
          'p_score': score,
          'p_percentage': percentage,
          'p_submitted_at': submittedAt?.toIso8601String(),
        },
      );

      return (res is Map<String, dynamic>) ? res : <String, dynamic>{};
    } catch (e) {
      debugPrint(
          '[SupabaseStudentAssignmentRepository] submitAssignment error: $e');
      rethrow;
    }
  }
}

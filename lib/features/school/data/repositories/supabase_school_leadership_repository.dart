import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/school_leadership_models.dart';
import '../../domain/repositories/school_leadership_repository.dart';

/// Exception thrown when the caller is not authorized as a school admin.
class SchoolLeadershipAuthorizationException implements Exception {
  final String message;
  const SchoolLeadershipAuthorizationException(this.message);

  @override
  String toString() => 'SchoolLeadershipAuthorizationException: $message';
}

/// Exception thrown when leadership analytics cannot be loaded because the device is offline
/// or cloud connectivity is unavailable.
class SchoolLeadershipOfflineException implements Exception {
  final String message;
  const SchoolLeadershipOfflineException([
    this.message =
        'Leadership analytics require an internet connection. Reconnect to load current school analytics.',
  ]);

  @override
  String toString() => message;
}

/// Production Supabase implementation of [SchoolLeadershipRepository].
///
/// All aggregations are performed server-side via SECURITY DEFINER PostgreSQL
/// functions defined in migration `20260925020000_p8_school_leadership.sql`.
///
/// Authorization is strictly enforced server-side.
class SupabaseSchoolLeadershipRepository implements SchoolLeadershipRepository {
  final SupabaseClient? _customClient;

  SupabaseSchoolLeadershipRepository([this._customClient]);

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Never _handleError(String caller, Object error) {
    debugPrint('SupabaseSchoolLeadershipRepository.$caller: $error');
    if (error is PostgrestException) {
      if (error.message.contains('NOT_AUTHORIZED')) {
        throw SchoolLeadershipAuthorizationException(error.message);
      }
      throw error;
    }
    if (error is SchoolLeadershipAuthorizationException) {
      throw error;
    }
    throw const SchoolLeadershipOfflineException();
  }

  @override
  Future<SchoolLeadershipSummary> getLeadershipSummary({
    required String schoolId,
    String? academicYear,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_leadership_summary',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
        },
      );

      if (rows is List && rows.isNotEmpty) {
        return SchoolLeadershipSummary.fromJson(
            rows.first as Map<String, dynamic>);
      }
      if (rows is Map<String, dynamic>) {
        return SchoolLeadershipSummary.fromJson(rows);
      }
      throw Exception('Empty or invalid response from server');
    } catch (e) {
      _handleError('getLeadershipSummary', e);
    }
  }

  @override
  Future<List<SchoolStreamSummary>> getStreamSummary({
    required String schoolId,
    String? academicYear,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_stream_summary',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolStreamSummary>(
              (e) => SchoolStreamSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getStreamSummary', e);
    }
  }

  @override
  Future<List<SchoolSubjectSummary>> getSubjectSummary({
    required String schoolId,
    String? academicYear,
    String? stream,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_subject_summary',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (stream != null) 'p_stream': stream,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolSubjectSummary>(
              (e) => SchoolSubjectSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getSubjectSummary', e);
    }
  }

  @override
  Future<List<SchoolClassSummary>> getClassSummary({
    required String schoolId,
    String? academicYear,
    String? stream,
    String? subjectId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_class_summary',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (stream != null) 'p_stream': stream,
          if (subjectId != null) 'p_subject_id': subjectId,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolClassSummary>(
              (e) => SchoolClassSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getClassSummary', e);
    }
  }

  @override
  Future<List<SchoolSystemicWeakTopic>> getSystemicWeakTopics({
    required String schoolId,
    String? academicYear,
    String? subjectId,
    int limit = 10,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_systemic_weak_topics',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (subjectId != null) 'p_subject_id': subjectId,
          'p_limit': limit,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolSystemicWeakTopic>((e) =>
              SchoolSystemicWeakTopic.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getSystemicWeakTopics', e);
    }
  }

  @override
  Future<List<SchoolSupportStudent>> getSupportPopulation({
    required String schoolId,
    String? academicYear,
    String? severity,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_support_population',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (severity != null) 'p_severity': severity,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolSupportStudent>(
              (e) => SchoolSupportStudent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getSupportPopulation', e);
    }
  }

  @override
  Future<List<SchoolAssessmentSummary>> getAssessmentsOverview({
    required String schoolId,
    String? academicYear,
    int limit = 15,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_assessments_overview',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          'p_limit': limit,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolAssessmentSummary>((e) =>
              SchoolAssessmentSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getAssessmentsOverview', e);
    }
  }

  @override
  Future<List<SchoolTeacherCoverageSlot>> getTeacherCoverage({
    required String schoolId,
    String? academicYear,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_teacher_coverage',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SchoolTeacherCoverageSlot>((e) =>
              SchoolTeacherCoverageSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getTeacherCoverage', e);
    }
  }

  @override
  Future<SchoolStudentAcademicDetail> getStudentAcademicSummary({
    required String schoolId,
    required String studentId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_school_student_academic_summary',
        params: {
          'p_school_id': schoolId,
          'p_student_id': studentId,
        },
      );

      if (rows is List && rows.isNotEmpty) {
        return SchoolStudentAcademicDetail.fromJson(
            rows.first as Map<String, dynamic>);
      }
      if (rows is Map<String, dynamic>) {
        return SchoolStudentAcademicDetail.fromJson(rows);
      }
      throw Exception('Student summary not found or unauthorized');
    } catch (e) {
      _handleError('getStudentAcademicSummary', e);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/institutional_reporting_models.dart';
import '../../domain/repositories/institutional_reporting_repository.dart';

/// Exception thrown when caller is not authorized for institutional reporting.
class ReportingAuthorizationException implements Exception {
  final String message;
  const ReportingAuthorizationException(this.message);

  @override
  String toString() => 'ReportingAuthorizationException: $message';
}

/// Exception thrown when reporting data cannot be loaded offline.
class ReportingOfflineException implements Exception {
  final String message;
  const ReportingOfflineException([
    this.message =
        'Institutional reports require an internet connection. Reconnect to load current synchronized analytics.',
  ]);

  @override
  String toString() => message;
}

/// Production Supabase implementation of [InstitutionalReportingRepository].
/// All aggregations execute via SECURITY DEFINER PostgreSQL functions.
class SupabaseInstitutionalReportingRepository
    implements InstitutionalReportingRepository {
  final SupabaseClient? _customClient;

  SupabaseInstitutionalReportingRepository([this._customClient]);

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Never _handleError(String caller, Object error) {
    debugPrint('SupabaseInstitutionalReportingRepository.$caller: $error');
    if (error is PostgrestException) {
      if (error.message.contains('NOT_AUTHORIZED') || error.code == '42501') {
        throw ReportingAuthorizationException(error.message);
      }
      throw error;
    }
    if (error is ReportingAuthorizationException) {
      throw error;
    }
    throw const ReportingOfflineException();
  }

  @override
  Future<InstitutionalReportRun> createReportRun({
    required String schoolId,
    required InstitutionalReportType reportType,
    required String academicYear,
    required DateTime periodStart,
    required DateTime periodEnd,
    Map<String, dynamic> filters = const {},
    String fileFormat = 'csv',
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'create_institutional_report_run',
        params: {
          'p_school_id': schoolId,
          'p_report_type': reportType.dbValue,
          'p_academic_year': academicYear,
          'p_period_start': periodStart.toIso8601String(),
          'p_period_end': periodEnd.toIso8601String(),
          'p_filters': filters,
          'p_file_format': fileFormat,
        },
      );

      final map = res is Map<String, dynamic>
          ? res
          : (res is List && res.isNotEmpty
              ? res.first as Map<String, dynamic>
              : <String, dynamic>{});

      return InstitutionalReportRun(
        id: map['run_id'] as String? ?? 'local_run',
        schoolId: schoolId,
        requestedBy: _client.auth.currentUser?.id ?? 'user',
        requestedByName: 'Staff Member',
        reportType: reportType,
        status: ReportRunStatus.fromString(map['status'] as String?),
        academicYear: academicYear,
        periodStart: periodStart,
        periodEnd: periodEnd,
        filtersJson: filters,
        analyticsVersion: kInstitutionalAnalyticsVersion,
        reportSchemaVersion: kInstitutionalReportSchemaVersion,
        dataAsOf: DateTime.now().toUtc(),
        fileFormat: fileFormat,
        createdAt: DateTime.now().toUtc(),
      );
    } catch (e) {
      _handleError('createReportRun', e);
    }
  }

  @override
  Future<List<InstitutionalReportRun>> getReportRuns({
    required String schoolId,
    InstitutionalReportType? reportType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_institutional_report_runs',
        params: {
          'p_school_id': schoolId,
          if (reportType != null) 'p_report_type': reportType.dbValue,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<InstitutionalReportRun>(
              (e) => InstitutionalReportRun.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getReportRuns', e);
    }
  }

  @override
  Future<ExecutiveReport> getExecutiveReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_institutional_executive_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
        },
      );

      final map = res is Map<String, dynamic>
          ? res
          : (res is List && res.isNotEmpty
              ? res.first as Map<String, dynamic>
              : <String, dynamic>{});
      return ExecutiveReport.fromJson(map);
    } catch (e) {
      _handleError('getExecutiveReport', e);
    }
  }

  @override
  Future<List<SubjectPerformanceRow>> getSubjectPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? stream,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_subject_performance_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
          if (stream != null) 'p_stream': stream,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<SubjectPerformanceRow>(
              (e) => SubjectPerformanceRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getSubjectPerformanceReport', e);
    }
  }

  @override
  Future<List<StreamPerformanceRow>> getStreamPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_stream_performance_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
        },
      );

      if (rows is! List) return [];
      return rows
          .map<StreamPerformanceRow>(
              (e) => StreamPerformanceRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getStreamPerformanceReport', e);
    }
  }

  @override
  Future<List<ClassPerformanceRow>> getClassPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_class_performance_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
          if (classroomId != null) 'p_classroom_id': classroomId,
          if (subjectId != null) 'p_subject_id': subjectId,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<ClassPerformanceRow>(
              (e) => ClassPerformanceRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getClassPerformanceReport', e);
    }
  }

  @override
  Future<List<AssessmentReportRow>> getAssessmentReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? subjectId,
    String? examId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_assessment_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
          if (subjectId != null) 'p_subject_id': subjectId,
          if (examId != null) 'p_exam_id': examId,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<AssessmentReportRow>(
              (e) => AssessmentReportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getAssessmentReport', e);
    }
  }

  @override
  Future<List<AssignmentOutcomeRow>> getAssignmentOutcomesReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_assignment_outcomes_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
          if (classroomId != null) 'p_classroom_id': classroomId,
          if (subjectId != null) 'p_subject_id': subjectId,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<AssignmentOutcomeRow>(
              (e) => AssignmentOutcomeRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getAssignmentOutcomesReport', e);
    }
  }

  @override
  Future<List<InterventionFollowUpRow>> getInterventionFollowUpReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_intervention_followup_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
          if (classroomId != null) 'p_classroom_id': classroomId,
          if (subjectId != null) 'p_subject_id': subjectId,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<InterventionFollowUpRow>((e) =>
              InterventionFollowUpRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getInterventionFollowUpReport', e);
    }
  }

  @override
  Future<List<StudentSupportRow>> getStudentSupportReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
    String? severity,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>(
        'get_student_support_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
          if (classroomId != null) 'p_classroom_id': classroomId,
          if (subjectId != null) 'p_subject_id': subjectId,
          if (severity != null) 'p_severity': severity,
        },
      );

      if (rows is! List) return [];
      return rows
          .map<StudentSupportRow>(
              (e) => StudentSupportRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError('getStudentSupportReport', e);
    }
  }

  @override
  Future<DataCoverageReport> getDataCoverageReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_data_coverage_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
        },
      );

      final map = res is Map<String, dynamic>
          ? res
          : (res is List && res.isNotEmpty
              ? res.first as Map<String, dynamic>
              : <String, dynamic>{});
      return DataCoverageReport.fromJson(map);
    } catch (e) {
      _handleError('getDataCoverageReport', e);
    }
  }

  @override
  Future<StudentAcademicReport> getStudentAcademicReport({
    required String schoolId,
    required String studentId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_student_academic_report',
        params: {
          'p_school_id': schoolId,
          'p_student_id': studentId,
          if (academicYear != null) 'p_academic_year': academicYear,
          if (periodStart != null)
            'p_period_start': periodStart.toIso8601String(),
          if (periodEnd != null) 'p_period_end': periodEnd.toIso8601String(),
        },
      );

      final map = res is Map<String, dynamic>
          ? res
          : (res is List && res.isNotEmpty
              ? res.first as Map<String, dynamic>
              : <String, dynamic>{});
      return StudentAcademicReport.fromJson(map);
    } catch (e) {
      _handleError('getStudentAcademicReport', e);
    }
  }

  @override
  Future<TeacherCoverageReport> getTeacherCoverageReport({
    required String schoolId,
    String? academicYear,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_teacher_coverage_report',
        params: {
          'p_school_id': schoolId,
          if (academicYear != null) 'p_academic_year': academicYear,
        },
      );

      final map = res is Map<String, dynamic>
          ? res
          : (res is List && res.isNotEmpty
              ? res.first as Map<String, dynamic>
              : <String, dynamic>{});
      return TeacherCoverageReport.fromJson(map);
    } catch (e) {
      _handleError('getTeacherCoverageReport', e);
    }
  }
}

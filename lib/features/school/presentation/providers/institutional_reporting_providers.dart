import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../data/repositories/local_institutional_reporting_repository.dart';
import '../../data/repositories/supabase_institutional_reporting_repository.dart';
import '../../domain/models/institutional_reporting_models.dart';
import '../../domain/repositories/institutional_reporting_repository.dart';
import 'active_school_context_provider.dart';

/// Provider for the [InstitutionalReportingRepository].
/// Uses Supabase in production and falls back to Local only in local dev when Supabase is unconfigured.
final institutionalReportingRepositoryProvider =
    Provider<InstitutionalReportingRepository>((ref) {
  if (EnvConfig.isProductionLike) {
    return SupabaseInstitutionalReportingRepository();
  }
  try {
    return SupabaseInstitutionalReportingRepository();
  } catch (_) {
    return LocalInstitutionalReportingRepository();
  }
});

/// Provider for historical report runs.
final institutionalReportRunsProvider = FutureProvider.family<
    List<InstitutionalReportRun>,
    ({String schoolId, InstitutionalReportType? type})>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getReportRuns(
        schoolId: params.schoolId, reportType: params.type);
  },
);

/// Provider for the School Executive Institutional Report.
final schoolExecutiveReportProvider = FutureProvider.family<ExecutiveReport,
    ({String schoolId, String? academicYear, DateTime? start, DateTime? end})>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getExecutiveReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
    );
  },
);

/// Provider for the Subject Performance Report.
final subjectPerformanceReportProvider = FutureProvider.family<
    List<SubjectPerformanceRow>,
    ({
      String schoolId,
      String? academicYear,
      DateTime? start,
      DateTime? end,
      String? stream
    })>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getSubjectPerformanceReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
      stream: params.stream,
    );
  },
);

/// Provider for the Stream Performance Report.
final streamPerformanceReportProvider = FutureProvider.family<
    List<StreamPerformanceRow>,
    ({String schoolId, String? academicYear, DateTime? start, DateTime? end})>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getStreamPerformanceReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
    );
  },
);

/// Provider for the Class Performance Report.
final classPerformanceReportProvider = FutureProvider.family<
    List<ClassPerformanceRow>,
    ({
      String schoolId,
      String? academicYear,
      DateTime? start,
      DateTime? end,
      String? classroomId,
      String? subjectId
    })>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getClassPerformanceReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
      classroomId: params.classroomId,
      subjectId: params.subjectId,
    );
  },
);

/// Provider for the Assessment & Simulation Report.
final assessmentReportProvider = FutureProvider.family<
    List<AssessmentReportRow>,
    ({
      String schoolId,
      String? academicYear,
      DateTime? start,
      DateTime? end,
      String? subjectId,
      String? examId
    })>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getAssessmentReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
      subjectId: params.subjectId,
      examId: params.examId,
    );
  },
);

/// Provider for the Assignment Outcomes Report.
final assignmentOutcomesReportProvider = FutureProvider.family<
    List<AssignmentOutcomeRow>,
    ({
      String schoolId,
      String? academicYear,
      DateTime? start,
      DateTime? end,
      String? classroomId,
      String? subjectId
    })>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getAssignmentOutcomesReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
      classroomId: params.classroomId,
      subjectId: params.subjectId,
    );
  },
);

/// Provider for the Intervention Follow-Up Report.
final interventionFollowUpReportProvider = FutureProvider.family<
    List<InterventionFollowUpRow>,
    ({
      String schoolId,
      String? academicYear,
      DateTime? start,
      DateTime? end,
      String? classroomId,
      String? subjectId
    })>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getInterventionFollowUpReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
      classroomId: params.classroomId,
      subjectId: params.subjectId,
    );
  },
);

/// Provider for the Student Support Report.
final studentSupportReportProvider = FutureProvider.family<
    List<StudentSupportRow>,
    ({
      String schoolId,
      String? academicYear,
      DateTime? start,
      DateTime? end,
      String? classroomId,
      String? subjectId,
      String? severity
    })>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getStudentSupportReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
      classroomId: params.classroomId,
      subjectId: params.subjectId,
      severity: params.severity,
    );
  },
);

/// Provider for the Data Coverage & Freshness Report.
final dataCoverageReportProvider = FutureProvider.family<DataCoverageReport,
    ({String schoolId, String? academicYear, DateTime? start, DateTime? end})>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getDataCoverageReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
      periodStart: params.start,
      periodEnd: params.end,
    );
  },
);

/// Provider for the Teacher Coverage Report.
final teacherCoverageReportProvider = FutureProvider.family<
    TeacherCoverageReport, ({String schoolId, String? academicYear})>(
  (ref, params) async {
    final repo = ref.watch(institutionalReportingRepositoryProvider);
    return repo.getTeacherCoverageReport(
      schoolId: params.schoolId,
      academicYear: params.academicYear,
    );
  },
);

/// Provider for the active school context report scope.
final activeSchoolReportingScopeProvider = Provider<String?>((ref) {
  final context = ref.watch(activeSchoolContextProvider);
  return context.school?.id;
});

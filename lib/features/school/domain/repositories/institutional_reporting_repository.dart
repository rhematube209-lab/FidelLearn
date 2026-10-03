import '../models/institutional_reporting_models.dart';

/// Abstract repository contract for Institutional Analytics & Reporting.
abstract class InstitutionalReportingRepository {
  /// Create or request a persistent institutional report run.
  Future<InstitutionalReportRun> createReportRun({
    required String schoolId,
    required InstitutionalReportType reportType,
    required String academicYear,
    required DateTime periodStart,
    required DateTime periodEnd,
    Map<String, dynamic> filters = const {},
    String fileFormat = 'csv',
  });

  /// Retrieve historical report runs for the active school.
  Future<List<InstitutionalReportRun>> getReportRuns({
    required String schoolId,
    InstitutionalReportType? reportType,
    int limit = 50,
    int offset = 0,
  });

  /// Retrieve the School Executive Institutional Report.
  Future<ExecutiveReport> getExecutiveReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  });

  /// Retrieve the Subject Performance Report.
  Future<List<SubjectPerformanceRow>> getSubjectPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? stream,
  });

  /// Retrieve the Stream Performance Report (Natural vs Social).
  Future<List<StreamPerformanceRow>> getStreamPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  });

  /// Retrieve the Class / Section Performance Report.
  Future<List<ClassPerformanceRow>> getClassPerformanceReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  });

  /// Retrieve the Assessment & Simulation Report with P5 provenance.
  Future<List<AssessmentReportRow>> getAssessmentReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? subjectId,
    String? examId,
  });

  /// Retrieve the Assignment Outcomes Report.
  Future<List<AssignmentOutcomeRow>> getAssignmentOutcomesReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  });

  /// Retrieve the Intervention Follow-Up Report with comparable before/after evidence.
  Future<List<InterventionFollowUpRow>> getInterventionFollowUpReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
  });

  /// Retrieve the Student Support Report for authorized staff.
  Future<List<StudentSupportRow>> getStudentSupportReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? classroomId,
    String? subjectId,
    String? severity,
  });

  /// Retrieve the Data Coverage & Freshness Report.
  Future<DataCoverageReport> getDataCoverageReport({
    required String schoolId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  });

  /// Retrieve the authorized individual Student Academic Report.
  Future<StudentAcademicReport> getStudentAcademicReport({
    required String schoolId,
    required String studentId,
    String? academicYear,
    DateTime? periodStart,
    DateTime? periodEnd,
  });

  /// Retrieve the Teacher Coverage Report.
  Future<TeacherCoverageReport> getTeacherCoverageReport({
    required String schoolId,
    String? academicYear,
  });
}

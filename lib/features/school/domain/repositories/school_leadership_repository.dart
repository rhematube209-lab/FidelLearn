import '../models/school_leadership_models.dart';

// =============================================================================
// FidelLearn — P8 School Leadership Repository Contract
// Authoritative interface for all School Leadership Dashboard analytics.
// =============================================================================

abstract class SchoolLeadershipRepository {
  /// Executive KPI summary for Leadership Home.
  Future<SchoolLeadershipSummary> getLeadershipSummary({
    required String schoolId,
    String? academicYear,
  });

  /// Comparison of Natural Science vs Social Science cohorts.
  Future<List<SchoolStreamSummary>> getStreamSummary({
    required String schoolId,
    String? academicYear,
  });

  /// Subject performance, mistake concentration, and Math variant isolation.
  Future<List<SchoolSubjectSummary>> getSubjectSummary({
    required String schoolId,
    String? academicYear,
    String? stream,
  });

  /// Section-level comparison without rankings.
  Future<List<SchoolClassSummary>> getClassSummary({
    required String schoolId,
    String? academicYear,
    String? stream,
    String? subjectId,
  });

  /// School-wide systemic weak topics derived from mistake records.
  Future<List<SchoolSystemicWeakTopic>> getSystemicWeakTopics({
    required String schoolId,
    String? academicYear,
    String? subjectId,
    int limit = 10,
  });

  /// Students needing academic support with transparent reasons.
  Future<List<SchoolSupportStudent>> getSupportPopulation({
    required String schoolId,
    String? academicYear,
    String? severity,
    int limit = 25,
    int offset = 0,
  });

  /// Recent school-wide assessments preserving P5 provenance.
  Future<List<SchoolAssessmentSummary>> getAssessmentsOverview({
    required String schoolId,
    String? academicYear,
    int limit = 15,
  });

  /// Teacher subject assignment coverage oversight across all sections.
  Future<List<SchoolTeacherCoverageSlot>> getTeacherCoverage({
    required String schoolId,
    String? academicYear,
  });

  /// Individual student academic standing drill-down.
  Future<SchoolStudentAcademicDetail> getStudentAcademicSummary({
    required String schoolId,
    required String studentId,
  });
}

import 'package:equatable/equatable.dart';

import '../../../exams/domain/models/exam_mode.dart';

// =============================================================================
// FidelLearn — P10 Institutional Analytics & Reporting Models
// Pure Dart models for institutional longitudinal evidence, metric dictionary,
// report run persistence, and deterministic export generation.
//
// Critical Analytical Principle:
// Observed changes after an intervention must NEVER be reported as caused by
// the intervention. FidelLearn reports observed evidence, not unproven causality.
// =============================================================================

const String kInstitutionalAnalyticsVersion = 'institutional_analytics_v1';
const String kInstitutionalReportSchemaVersion =
    'institutional_report_schema_v1';
const String kInterventionFollowUpVersion = 'intervention_followup_v1';

/// Canonical report types supported by the Institutional Reports Hub.
enum InstitutionalReportType {
  executive,
  subjectPerformance,
  streamPerformance,
  classPerformance,
  assessment,
  assignmentOutcomes,
  interventionFollowUp,
  studentSupport,
  dataCoverage,
  teacherCoverage,
  studentAcademic;

  String get dbValue {
    switch (this) {
      case InstitutionalReportType.executive:
        return 'executive';
      case InstitutionalReportType.subjectPerformance:
        return 'subject_performance';
      case InstitutionalReportType.streamPerformance:
        return 'stream_performance';
      case InstitutionalReportType.classPerformance:
        return 'class_performance';
      case InstitutionalReportType.assessment:
        return 'assessment';
      case InstitutionalReportType.assignmentOutcomes:
        return 'assignment_outcomes';
      case InstitutionalReportType.interventionFollowUp:
        return 'intervention_followup';
      case InstitutionalReportType.studentSupport:
        return 'student_support';
      case InstitutionalReportType.dataCoverage:
        return 'data_coverage';
      case InstitutionalReportType.teacherCoverage:
        return 'teacher_coverage';
      case InstitutionalReportType.studentAcademic:
        return 'student_academic';
    }
  }

  String get titleEn {
    switch (this) {
      case InstitutionalReportType.executive:
        return 'School Executive Report';
      case InstitutionalReportType.subjectPerformance:
        return 'Subject Performance Report';
      case InstitutionalReportType.streamPerformance:
        return 'Stream Performance Report';
      case InstitutionalReportType.classPerformance:
        return 'Class / Section Report';
      case InstitutionalReportType.assessment:
        return 'Assessment & Simulation Report';
      case InstitutionalReportType.assignmentOutcomes:
        return 'Assignment Outcomes Report';
      case InstitutionalReportType.interventionFollowUp:
        return 'Intervention Follow-Up Report';
      case InstitutionalReportType.studentSupport:
        return 'Student Support Report';
      case InstitutionalReportType.dataCoverage:
        return 'Data Coverage & Freshness Report';
      case InstitutionalReportType.teacherCoverage:
        return 'Teacher Coverage Report';
      case InstitutionalReportType.studentAcademic:
        return 'Student Academic Report';
    }
  }

  String get titleAm {
    switch (this) {
      case InstitutionalReportType.executive:
        return 'የትምህርት ቤት አመራር ሪፖርት';
      case InstitutionalReportType.subjectPerformance:
        return 'የትምህርት አይነት ውጤት ሪፖርት';
      case InstitutionalReportType.streamPerformance:
        return 'የስትሪም ንጽጽር ሪፖርት';
      case InstitutionalReportType.classPerformance:
        return 'የክፍል / ሴክሽን ሪፖርት';
      case InstitutionalReportType.assessment:
        return 'የፈተና እና ሲሙሌሽን ሪፖርት';
      case InstitutionalReportType.assignmentOutcomes:
        return 'የተግባር ስራ ውጤቶች ሪፖርት';
      case InstitutionalReportType.interventionFollowUp:
        return 'የድጋፍ ክትትል ማስረጃ ሪፖርት';
      case InstitutionalReportType.studentSupport:
        return 'ተጨማሪ ድጋፍ የሚሹ ተማሪዎች ሪፖርት';
      case InstitutionalReportType.dataCoverage:
        return 'የዳታ ሽፋን እና የሰዓት ትክክለኛነት ሪፖርት';
      case InstitutionalReportType.teacherCoverage:
        return 'የመምህራን ምደባ ሽፋን ሪፖርት';
      case InstitutionalReportType.studentAcademic:
        return 'የተማሪ ግላዊ የትምህርት ሪፖርት';
    }
  }

  static InstitutionalReportType fromString(String? val) {
    if (val == null) return InstitutionalReportType.executive;
    switch (val.toLowerCase().replaceAll('-', '_').trim()) {
      case 'subject_performance':
      case 'subject':
        return InstitutionalReportType.subjectPerformance;
      case 'stream_performance':
      case 'stream':
        return InstitutionalReportType.streamPerformance;
      case 'class_performance':
      case 'class':
        return InstitutionalReportType.classPerformance;
      case 'assessment':
      case 'assessments':
        return InstitutionalReportType.assessment;
      case 'assignment_outcomes':
      case 'assignments':
        return InstitutionalReportType.assignmentOutcomes;
      case 'intervention_followup':
      case 'interventions':
        return InstitutionalReportType.interventionFollowUp;
      case 'student_support':
      case 'support':
        return InstitutionalReportType.studentSupport;
      case 'data_coverage':
      case 'freshness':
        return InstitutionalReportType.dataCoverage;
      case 'teacher_coverage':
        return InstitutionalReportType.teacherCoverage;
      case 'student_academic':
        return InstitutionalReportType.studentAcademic;
      case 'executive':
      default:
        return InstitutionalReportType.executive;
    }
  }
}

/// Status of an asynchronous or on-demand report run.
enum ReportRunStatus {
  pending,
  processing,
  completed,
  failed,
  expired;

  static ReportRunStatus fromString(String? val) {
    if (val == null) return ReportRunStatus.pending;
    switch (val.toLowerCase().trim()) {
      case 'processing':
        return ReportRunStatus.processing;
      case 'completed':
        return ReportRunStatus.completed;
      case 'failed':
        return ReportRunStatus.failed;
      case 'expired':
        return ReportRunStatus.expired;
      case 'pending':
      default:
        return ReportRunStatus.pending;
    }
  }
}

// =============================================================================
// Centralized Metric Registry
// =============================================================================

/// Formal specification of an institutional metric according to institutional_analytics_v1.
class MetricDefinition extends Equatable {
  final String id;
  final String displayName;
  final String definition;
  final String numerator;
  final String denominator;
  final String timeWindow;
  final String population;
  final String dataSource;
  final String minimumEvidence;
  final String freshnessRequirement;
  final String exclusions;
  final String version;

  const MetricDefinition({
    required this.id,
    required this.displayName,
    required this.definition,
    required this.numerator,
    required this.denominator,
    required this.timeWindow,
    required this.population,
    required this.dataSource,
    required this.minimumEvidence,
    required this.freshnessRequirement,
    required this.exclusions,
    this.version = kInstitutionalAnalyticsVersion,
  });

  @override
  List<Object?> get props => [
        id,
        displayName,
        definition,
        numerator,
        denominator,
        timeWindow,
        population,
        dataSource,
        minimumEvidence,
        freshnessRequirement,
        exclusions,
        version,
      ];
}

/// Central metric dictionary ensuring all reports share identical definitions.
class InstitutionalMetricDictionary {
  static const List<MetricDefinition> allMetrics = [
    MetricDefinition(
      id: 'active_enrolled_students',
      displayName: 'Active Enrolled Students',
      definition:
          'Count of active student memberships enrolled within the active school tenant.',
      numerator: 'Active student memberships in school_memberships',
      denominator: 'Total enrolled students',
      timeWindow: 'Current academic year',
      population: 'Enrolled students',
      dataSource: 'public.school_memberships',
      minimumEvidence: 'Active membership record',
      freshnessRequirement: 'None',
      exclusions: 'Archived, deleted, or transferred students',
    ),
    MetricDefinition(
      id: 'students_with_academic_evidence',
      displayName: 'Students with Academic Evidence',
      definition:
          'Count of active enrolled students with at least one synchronized assessment attempt recorded during the period.',
      numerator: 'Distinct students with >= 1 completed attempt',
      denominator: 'Active enrolled students',
      timeWindow: 'Configured period',
      population: 'Enrolled students',
      dataSource: 'public.attempts join public.school_memberships',
      minimumEvidence: '1 completed attempt',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Students with zero synchronized attempts',
    ),
    MetricDefinition(
      id: 'active_students',
      displayName: 'Active Students',
      definition:
          'Canonical active enrolled student count. Alias for active_enrolled_students.',
      numerator: 'Active student memberships in school_memberships',
      denominator: 'Total enrolled students',
      timeWindow: 'Current academic year',
      population: 'Enrolled students',
      dataSource: 'public.school_memberships',
      minimumEvidence: 'Active membership record',
      freshnessRequirement: 'None',
      exclusions: 'Archived, deleted, or transferred students',
    ),
    MetricDefinition(
      id: 'assessment_participation_rate',
      displayName: 'Assessment Participation Rate',
      definition:
          'Percentage of eligible students who completed at least one assessment within reporting window.',
      numerator: 'Unique students with >= 1 completed attempt',
      denominator: 'Total active students in cohort',
      timeWindow: 'Configured period (e.g. 30/90 days)',
      population: 'Active students',
      dataSource: 'public.attempts',
      minimumEvidence: '1 completed attempt (is_completed = true)',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Incomplete / abandoned attempts',
    ),
    MetricDefinition(
      id: 'recent_assessment_average',
      displayName: 'Recent Assessment Average',
      definition:
          'Arithmetic mean percentage score on the latest completed attempt per student per exam.',
      numerator:
          'Sum of percentages from deduplicated latest completed attempts',
      denominator: 'Count of deduplicated latest completed attempts',
      timeWindow: 'Configured period (e.g. 30/90 days)',
      population: 'Participating students',
      dataSource: 'public.attempts',
      minimumEvidence: 'Latest completed attempt per student/exam',
      freshnessRequirement: 'Synchronized within report window',
      exclusions:
          'Historical retakes (only latest completed attempt is counted)',
    ),
    MetricDefinition(
      id: 'recent_assessment_median',
      displayName: 'Recent Assessment Median',
      definition:
          '50th percentile score on deduplicated latest completed attempts to prevent extreme score distortion.',
      numerator: 'Median value of sorted percentages',
      denominator: 'Count of deduplicated latest completed attempts',
      timeWindow: 'Configured period',
      population: 'Participating students',
      dataSource: 'public.attempts',
      minimumEvidence: 'At least 1 completed attempt',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Earlier attempts before latest completed retake',
    ),
    MetricDefinition(
      id: 'simulation_participation_rate',
      displayName: 'Simulation Participation Rate',
      definition:
          'Percentage of active students who completed a full national exam simulation.',
      numerator: 'Unique students completing a national simulation',
      denominator: 'Total active students in cohort',
      timeWindow: 'Configured period',
      population: 'Grade 12 students',
      dataSource: 'public.attempts join public.exams',
      minimumEvidence: '1 completed simulation attempt',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Topic practices, custom builds, and incomplete simulations',
    ),
    MetricDefinition(
      id: 'simulation_average',
      displayName: 'Simulation Average Score',
      definition:
          'Mean percentage score on finalized national exam simulations.',
      numerator: 'Sum of simulation percentages',
      denominator: 'Total completed simulation attempts (latest per student)',
      timeWindow: 'Configured period',
      population: 'Participating simulation students',
      dataSource: 'public.attempts',
      minimumEvidence: 'Completed full simulation',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Retake attempts prior to student latest attempt',
    ),
    MetricDefinition(
      id: 'simulation_median',
      displayName: 'Simulation Median Score',
      definition:
          '50th percentile of finalized national exam simulation scores.',
      numerator: '50th percentile value',
      denominator: 'Total completed simulations',
      timeWindow: 'Configured period',
      population: 'Participating simulation students',
      dataSource: 'public.attempts',
      minimumEvidence: 'Completed full simulation',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Earlier retakes',
    ),
    MetricDefinition(
      id: 'assignment_completion_rate',
      displayName: 'Assignment Completion Rate',
      definition:
          'Proportion of required assignment recipients who completed the assignment.',
      numerator: 'Count of submitted and completed recipients',
      denominator:
          'requiredForCompletion = original_cohort + post_publish_additions - excused',
      timeWindow: 'Assignment lifecycle within period',
      population: 'Assigned classroom students',
      dataSource: 'public.learning_assignment_recipients',
      minimumEvidence: 'Recipient status in (submitted, completed, late)',
      freshnessRequirement: 'Synchronized assignment status',
      exclusions: 'Excused students',
    ),
    MetricDefinition(
      id: 'assignment_on_time_rate_verified',
      displayName: 'Verified On-Time Submission Rate',
      definition:
          'Percentage of verified submissions submitted before deadline. Denominator strictly excludes unverified timing.',
      numerator:
          'Recipients with status in ("submitted", "completed") and deadline_integrity = "verified" and submitted_at <= due_date',
      denominator:
          'Total submissions with deadline_integrity = "verified" (on-time + late)',
      timeWindow: 'Configured period',
      population: 'Submitted students with verified timing',
      dataSource: 'public.learning_assignment_recipients',
      minimumEvidence: 'Verified timing anchor and monotonic continuity',
      freshnessRequirement: 'Synchronized submission',
      exclusions: 'Timing unverified or clock anomaly submissions',
    ),
    MetricDefinition(
      id: 'assignment_late_rate_verified',
      displayName: 'Verified Late Submission Rate',
      definition:
          'Percentage of submissions conclusively verified as submitted past deadline. Denominator strictly excludes unverified timing.',
      numerator:
          'Recipients with status = "late" and deadline_integrity = "verified"',
      denominator:
          'Total submissions with deadline_integrity = "verified" (on-time + late)',
      timeWindow: 'Configured period',
      population: 'Submitted students with verified timing',
      dataSource: 'public.learning_assignment_recipients',
      minimumEvidence: 'Verified timing anchor',
      freshnessRequirement: 'Synchronized submission',
      exclusions: 'Timing unverified or clock anomaly submissions',
    ),
    MetricDefinition(
      id: 'score_50_plus_rate',
      displayName: '50%+ Score Rate',
      definition:
          'Proportion of completed assessments achieving 50% or higher. Descriptive analytical threshold, not an official Ethiopian national exam passing standard.',
      numerator: 'Attempts with score >= 50%',
      denominator: 'Total completed attempts',
      timeWindow: 'Configured period',
      population: 'Participating students',
      dataSource: 'public.attempts',
      minimumEvidence: '1 completed attempt',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Incomplete attempts',
    ),
    MetricDefinition(
      id: 'score_75_plus_rate',
      displayName: '75%+ Score Rate',
      definition:
          'Proportion of completed assessments achieving 75% or higher. Descriptive high-performance analytical threshold.',
      numerator: 'Attempts with score >= 75%',
      denominator: 'Total completed attempts',
      timeWindow: 'Configured period',
      population: 'Participating students',
      dataSource: 'public.attempts',
      minimumEvidence: '1 completed attempt',
      freshnessRequirement: 'Synchronized within report window',
      exclusions: 'Incomplete attempts',
    ),
    MetricDefinition(
      id: 'assignment_timing_unverified_count',
      displayName: 'Timing Unverified Submissions',
      definition:
          'Count of submissions where device clock drift or missing network anchor prevented deadline verification.',
      numerator: 'Recipients with deadline_integrity = "unverified"',
      denominator: 'N/A (discrete count)',
      timeWindow: 'Configured period',
      population: 'Submitted students',
      dataSource: 'public.learning_assignment_recipients',
      minimumEvidence: 'Clock drift detected or unanchored offline attempt',
      freshnessRequirement: 'Synchronized submission',
      exclusions: 'Verified on-time and verified late submissions',
    ),
    MetricDefinition(
      id: 'interventions_created',
      displayName: 'Interventions Created',
      definition:
          'Total formal academic intervention actions registered by teachers.',
      numerator: 'Count of rows in public.student_interventions',
      denominator: 'N/A (discrete count)',
      timeWindow: 'Configured period',
      population: 'School classrooms',
      dataSource: 'public.student_interventions',
      minimumEvidence: 'Created intervention record',
      freshnessRequirement: 'None',
      exclusions: 'None',
    ),
    MetricDefinition(
      id: 'interventions_completed',
      displayName: 'Interventions Completed',
      definition:
          'Interventions formally marked as completed by the assigning teacher.',
      numerator: 'Count of interventions with status = "completed"',
      denominator: 'Total interventions created',
      timeWindow: 'Configured period',
      population: 'School classrooms',
      dataSource: 'public.student_interventions',
      minimumEvidence: 'status = completed and completed_at IS NOT NULL',
      freshnessRequirement: 'None',
      exclusions: 'Open or active interventions',
    ),
    MetricDefinition(
      id: 'interventions_with_followup_evidence',
      displayName: 'Interventions with Follow-Up Evidence',
      definition:
          'Completed interventions having comparable assessment evidence recorded within 30 days post-completion.',
      numerator: 'Interventions with qualifying pre- and post-evidence',
      denominator: 'Completed interventions',
      timeWindow:
          'Pre: 30 days before created_at; Post: 30 days after completed_at',
      population: 'Students with completed interventions',
      dataSource: 'public.student_interventions & public.attempts',
      minimumEvidence: 'At least 1 comparable attempt in both windows',
      freshnessRequirement: 'Synchronized attempts',
      exclusions:
          'Incomparable assessment types (e.g. topic drill vs simulation)',
    ),
    MetricDefinition(
      id: 'fresh_data_coverage',
      displayName: 'Fresh Data Coverage',
      definition:
          'Percentage of active students with synchronized attempts within the last 14 days.',
      numerator: 'Active students with sync timestamp <= 14 days',
      denominator: 'Total active students',
      timeWindow: 'Last 14 days',
      population: 'Active students',
      dataSource: 'public.profiles & public.attempts',
      minimumEvidence: 'Last sync or attempt timestamp',
      freshnessRequirement: 'Current timestamp comparison',
      exclusions: 'None',
    ),
    MetricDefinition(
      id: 'teacher_assignment_coverage',
      displayName: 'Teacher Assignment Coverage',
      definition:
          'Percentage of required subject-classroom instructional slots that have an active assigned teacher.',
      numerator: 'Active assigned classroom-subject pairings',
      denominator: 'Total active classrooms multiplied by curriculum subjects',
      timeWindow: 'Current academic year',
      population: 'School classrooms',
      dataSource: 'public.teacher_subject_assignments',
      minimumEvidence: 'Active assignment record',
      freshnessRequirement: 'Current configuration',
      exclusions: 'Civics (supplementary non-national curriculum)',
    ),
  ];

  static MetricDefinition? getById(String id) {
    for (final m in allMetrics) {
      if (m.id == id) return m;
    }
    return null;
  }
}

// =============================================================================
// Report Run Entity
// =============================================================================

/// Persistent record of an institutional report generation run.
class InstitutionalReportRun extends Equatable {
  final String id;
  final String schoolId;
  final String requestedBy;
  final String requestedByName;
  final InstitutionalReportType reportType;
  final ReportRunStatus status;
  final String academicYear;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> filtersJson;
  final String analyticsVersion;
  final String reportSchemaVersion;
  final DateTime dataAsOf;
  final DateTime? generatedAt;
  final DateTime? completedAt;
  final String? storagePath;
  final String? fileFormat;
  final String? sha256;
  final int? rowCount;
  final String? errorCode;
  final DateTime createdAt;

  const InstitutionalReportRun({
    required this.id,
    required this.schoolId,
    required this.requestedBy,
    required this.requestedByName,
    required this.reportType,
    required this.status,
    required this.academicYear,
    required this.periodStart,
    required this.periodEnd,
    required this.filtersJson,
    required this.analyticsVersion,
    required this.reportSchemaVersion,
    required this.dataAsOf,
    this.generatedAt,
    this.completedAt,
    this.storagePath,
    this.fileFormat,
    this.sha256,
    this.rowCount,
    this.errorCode,
    required this.createdAt,
  });

  factory InstitutionalReportRun.fromJson(Map<String, dynamic> json) {
    return InstitutionalReportRun(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      requestedBy: json['requested_by'] as String,
      requestedByName: json['requested_by_name'] as String? ?? 'Staff Member',
      reportType:
          InstitutionalReportType.fromString(json['report_type'] as String?),
      status: ReportRunStatus.fromString(json['status'] as String?),
      academicYear: json['academic_year'] as String? ?? '2026/27',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      filtersJson: json['filters_json'] is Map<String, dynamic>
          ? json['filters_json'] as Map<String, dynamic>
          : {},
      analyticsVersion: json['analytics_version'] as String? ??
          kInstitutionalAnalyticsVersion,
      reportSchemaVersion: json['report_schema_version'] as String? ??
          kInstitutionalReportSchemaVersion,
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      storagePath: json['storage_path'] as String?,
      fileFormat: json['file_format'] as String?,
      sha256: json['sha256'] as String?,
      rowCount: json['row_count'] as int?,
      errorCode: json['error_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        requestedBy,
        requestedByName,
        reportType,
        status,
        academicYear,
        periodStart,
        periodEnd,
        filtersJson,
        analyticsVersion,
        reportSchemaVersion,
        dataAsOf,
        storagePath,
        fileFormat,
        sha256,
        rowCount,
        errorCode,
        createdAt,
      ];
}

// =============================================================================
// Canonical Report Domain Models
// =============================================================================

/// Canonical School Executive Institutional Report.
class ExecutiveReport extends Equatable {
  final String schoolId;
  final String schoolName;
  final String academicYear;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dataAsOf;
  final String analyticsVersion;
  final String reportSchemaVersion;

  // Populations
  final int studentPopulation;
  final int activeEnrolledStudents;
  final int studentsWithAcademicEvidence;
  final int naturalStreamStudents;
  final int socialStreamStudents;
  final int teacherPopulation;
  final int classPopulation;

  // Assessment & Simulation Performance
  final int assessmentEligibleStudents;
  final int assessmentParticipants;
  final double assessmentParticipationRate;
  final double recentAssessmentAverage;
  final double recentAssessmentMedian;

  final int simulationParticipants;
  final double simulationParticipationRate;
  final double simulationAverage;
  final double simulationMedian;

  // Assignment Follow-Through
  final int requiredForCompletion;
  final int submittedCount;
  final int completedCount;
  final double completionRate;
  final int verifiedLateCount;
  final double lateRateVerified;
  final double verifiedOnTimeRate;
  final int timingUnverifiedCount;
  final int clockAnomalyCount;

  // Intervention Follow-Up
  final int interventionsCreated;
  final int interventionsCompleted;
  final int interventionsWithFollowupEvidence;
  final String interventionMethodologyVersion;
  final String nonCausalNotice;

  // Coverage & Data Quality
  final double teacherCoverageRate;
  final int freshSyncCount;
  final int moderateSyncCount;
  final int staleSyncCount;
  final int veryStaleSyncCount;
  final double freshDataCoverageRate;
  final String freshnessCaveat;

  const ExecutiveReport({
    required this.schoolId,
    required this.schoolName,
    required this.academicYear,
    required this.periodStart,
    required this.periodEnd,
    required this.dataAsOf,
    this.analyticsVersion = kInstitutionalAnalyticsVersion,
    this.reportSchemaVersion = kInstitutionalReportSchemaVersion,
    required this.studentPopulation,
    int? activeEnrolledStudents,
    int? studentsWithAcademicEvidence,
    required this.naturalStreamStudents,
    required this.socialStreamStudents,
    required this.teacherPopulation,
    required this.classPopulation,
    required this.assessmentEligibleStudents,
    required this.assessmentParticipants,
    required this.assessmentParticipationRate,
    required this.recentAssessmentAverage,
    required this.recentAssessmentMedian,
    required this.simulationParticipants,
    required this.simulationParticipationRate,
    required this.simulationAverage,
    required this.simulationMedian,
    required this.requiredForCompletion,
    required this.submittedCount,
    required this.completedCount,
    required this.completionRate,
    required this.verifiedLateCount,
    required this.lateRateVerified,
    double? verifiedOnTimeRate,
    required this.timingUnverifiedCount,
    required this.clockAnomalyCount,
    required this.interventionsCreated,
    required this.interventionsCompleted,
    required this.interventionsWithFollowupEvidence,
    this.interventionMethodologyVersion = kInterventionFollowUpVersion,
    this.nonCausalNotice =
        'Observed change reflects academic performance recorded after intervention completion. Causation is not established.',
    required this.teacherCoverageRate,
    required this.freshSyncCount,
    required this.moderateSyncCount,
    required this.staleSyncCount,
    required this.veryStaleSyncCount,
    required this.freshDataCoverageRate,
    this.freshnessCaveat =
        'Stale synchronization indicates lack of recent device connectivity, NOT absence of offline student study.',
  })  : activeEnrolledStudents = activeEnrolledStudents ?? studentPopulation,
        studentsWithAcademicEvidence =
            studentsWithAcademicEvidence ?? assessmentParticipants,
        verifiedOnTimeRate = verifiedOnTimeRate ?? (100.0 - lateRateVerified);

  factory ExecutiveReport.fromJson(Map<String, dynamic> json) {
    final pops = json['populations'] as Map<String, dynamic>? ?? {};
    final prep =
        json['national_exam_preparation'] as Map<String, dynamic>? ?? {};
    final assign =
        json['assignment_follow_through'] as Map<String, dynamic>? ?? {};
    final interv =
        json['intervention_follow_up'] as Map<String, dynamic>? ?? {};
    final cov = json['data_coverage'] as Map<String, dynamic>? ?? {};
    final teach =
        json['teacher_assignment_coverage'] as Map<String, dynamic>? ?? {};

    final verifiedLateCount = assign['verified_late_count'] as int? ?? 0;
    final verifiedOnTimeCount = assign['verified_on_time_count'] as int? ??
        ((assign['submitted_count'] as int? ?? 0) - verifiedLateCount);
    final verifiedTimingTotal = verifiedOnTimeCount + verifiedLateCount;
    final verifiedLateRate =
        (assign['verified_late_rate'] as num?)?.toDouble() ??
            (assign['late_rate_verified'] as num?)?.toDouble() ??
            (verifiedTimingTotal > 0
                ? (verifiedLateCount / verifiedTimingTotal) * 100.0
                : 0.0);
    final verifiedOnTimeRate =
        (assign['verified_on_time_rate'] as num?)?.toDouble() ??
            (verifiedTimingTotal > 0
                ? (verifiedOnTimeCount / verifiedTimingTotal) * 100.0
                : 0.0);

    final enrolled = pops['active_enrolled_students'] as int? ??
        pops['student_population'] as int? ??
        0;
    final evidenceStudents = pops['students_with_academic_evidence'] as int? ??
        prep['assessment_participants'] as int? ??
        0;

    return ExecutiveReport(
      schoolId: json['school_id'] as String,
      schoolName: json['school_name'] as String? ?? 'School',
      academicYear: json['academic_year'] as String? ?? '2026/27',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
      analyticsVersion: json['analytics_version'] as String? ??
          kInstitutionalAnalyticsVersion,
      reportSchemaVersion: json['report_schema_version'] as String? ??
          kInstitutionalReportSchemaVersion,
      studentPopulation: enrolled,
      activeEnrolledStudents: enrolled,
      studentsWithAcademicEvidence: evidenceStudents,
      naturalStreamStudents: pops['natural_stream_students'] as int? ?? 0,
      socialStreamStudents: pops['social_stream_students'] as int? ?? 0,
      teacherPopulation: pops['teacher_population'] as int? ?? 0,
      classPopulation: pops['class_population'] as int? ?? 0,
      assessmentEligibleStudents:
          prep['assessment_eligible_students'] as int? ?? 0,
      assessmentParticipants: prep['assessment_participants'] as int? ?? 0,
      assessmentParticipationRate:
          (prep['assessment_participation_rate'] as num?)?.toDouble() ?? 0.0,
      recentAssessmentAverage:
          (prep['recent_assessment_average'] as num?)?.toDouble() ?? 0.0,
      recentAssessmentMedian:
          (prep['recent_assessment_median'] as num?)?.toDouble() ?? 0.0,
      simulationParticipants: prep['simulation_participants'] as int? ?? 0,
      simulationParticipationRate:
          (prep['simulation_participation_rate'] as num?)?.toDouble() ?? 0.0,
      simulationAverage:
          (prep['simulation_average'] as num?)?.toDouble() ?? 0.0,
      simulationMedian: (prep['simulation_median'] as num?)?.toDouble() ?? 0.0,
      requiredForCompletion: assign['required_for_completion'] as int? ?? 0,
      submittedCount: assign['submitted_count'] as int? ?? 0,
      completedCount: assign['completed_count'] as int? ?? 0,
      completionRate: (assign['completion_rate'] as num?)?.toDouble() ?? 0.0,
      verifiedLateCount: verifiedLateCount,
      lateRateVerified: verifiedLateRate,
      verifiedOnTimeRate: verifiedOnTimeRate,
      timingUnverifiedCount: assign['timing_unverified_count'] as int? ?? 0,
      clockAnomalyCount: assign['clock_anomaly_count'] as int? ?? 0,
      interventionsCreated: interv['interventions_created'] as int? ?? 0,
      interventionsCompleted: interv['interventions_completed'] as int? ?? 0,
      interventionsWithFollowupEvidence:
          interv['interventions_with_followup_evidence'] as int? ?? 0,
      interventionMethodologyVersion:
          interv['methodology_version'] as String? ??
              kInterventionFollowUpVersion,
      nonCausalNotice: interv['non_causal_notice'] as String? ??
          'Observed change reflects academic performance recorded after intervention completion. Causation is not established.',
      teacherCoverageRate:
          (teach['coverage_rate'] as num?)?.toDouble() ?? 100.0,
      freshSyncCount: cov['fresh_count'] as int? ?? 0,
      moderateSyncCount: cov['moderate_count'] as int? ?? 0,
      staleSyncCount: cov['stale_count'] as int? ?? 0,
      veryStaleSyncCount: cov['very_stale_count'] as int? ?? 0,
      freshDataCoverageRate:
          (cov['fresh_data_coverage_rate'] as num?)?.toDouble() ?? 0.0,
      freshnessCaveat: cov['freshness_caveat'] as String? ??
          'Stale synchronization indicates lack of recent device connectivity, NOT absence of offline student study.',
    );
  }

  @override
  List<Object?> get props => [
        schoolId,
        schoolName,
        academicYear,
        periodStart,
        periodEnd,
        dataAsOf,
        studentPopulation,
        activeEnrolledStudents,
        studentsWithAcademicEvidence,
        assessmentParticipationRate,
        recentAssessmentAverage,
        simulationParticipationRate,
        completionRate,
        verifiedOnTimeRate,
        lateRateVerified,
        interventionsWithFollowupEvidence,
        freshDataCoverageRate,
      ];
}

/// A row in the Subject Performance Report.
class SubjectPerformanceRow extends Equatable {
  final String subjectId;
  final String subjectName;
  final String? examVariant;
  final String stream;
  final int eligibleStudents;
  final int participants;
  final double participationRate;
  final int attemptCount;
  final double? averageScore;
  final double? medianScore;
  final int affectedStudents;
  final int activeMistakes;
  final double assignmentCompletion;
  final int interventionsCount;
  final DateTime dataAsOf;
  final bool privacySuppressed;

  const SubjectPerformanceRow({
    required this.subjectId,
    required this.subjectName,
    this.examVariant,
    required this.stream,
    required this.eligibleStudents,
    required this.participants,
    required this.participationRate,
    required this.attemptCount,
    this.averageScore,
    this.medianScore,
    required this.affectedStudents,
    required this.activeMistakes,
    required this.assignmentCompletion,
    required this.interventionsCount,
    required this.dataAsOf,
    required this.privacySuppressed,
  });

  factory SubjectPerformanceRow.fromJson(Map<String, dynamic> json) {
    return SubjectPerformanceRow(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      examVariant: json['exam_variant'] as String?,
      stream: json['stream'] as String? ?? 'common',
      eligibleStudents: json['eligible_students'] as int? ?? 0,
      participants: json['participants'] as int? ?? 0,
      participationRate:
          (json['participation_rate'] as num?)?.toDouble() ?? 0.0,
      attemptCount: json['attempt_count'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      medianScore: (json['median_score'] as num?)?.toDouble(),
      affectedStudents: json['affected_students'] as int? ?? 0,
      activeMistakes: json['active_mistakes'] as int? ?? 0,
      assignmentCompletion:
          (json['assignment_completion'] as num?)?.toDouble() ?? 0.0,
      interventionsCount: json['interventions_count'] as int? ?? 0,
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
      privacySuppressed: json['privacy_suppressed'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        examVariant,
        stream,
        eligibleStudents,
        participants,
        participationRate,
        attemptCount,
        averageScore,
        medianScore,
        affectedStudents,
        activeMistakes,
        privacySuppressed,
      ];
}

/// A row in the Stream Performance Report.
class StreamPerformanceRow extends Equatable {
  final String stream;
  final String streamLabel;
  final int studentCount;
  final int activeClassrooms;
  final int assessmentParticipants;
  final double assessmentParticipation;
  final double assessmentAverage;
  final double assessmentMedian;
  final int simulationParticipants;
  final double simulationParticipation;
  final double simulationAverage;
  final double simulationMedian;
  final double assignmentCompletion;
  final int interventionsCount;
  final double freshDataCoverage;
  final DateTime dataAsOf;

  const StreamPerformanceRow({
    required this.stream,
    required this.streamLabel,
    required this.studentCount,
    required this.activeClassrooms,
    required this.assessmentParticipants,
    required this.assessmentParticipation,
    required this.assessmentAverage,
    required this.assessmentMedian,
    required this.simulationParticipants,
    required this.simulationParticipation,
    required this.simulationAverage,
    required this.simulationMedian,
    required this.assignmentCompletion,
    required this.interventionsCount,
    required this.freshDataCoverage,
    required this.dataAsOf,
  });

  factory StreamPerformanceRow.fromJson(Map<String, dynamic> json) {
    return StreamPerformanceRow(
      stream: json['stream'] as String,
      streamLabel: json['stream_label'] as String,
      studentCount: json['student_count'] as int? ?? 0,
      activeClassrooms: json['active_classrooms'] as int? ?? 0,
      assessmentParticipants: json['assessment_participants'] as int? ?? 0,
      assessmentParticipation:
          (json['assessment_participation'] as num?)?.toDouble() ?? 0.0,
      assessmentAverage:
          (json['assessment_average'] as num?)?.toDouble() ?? 0.0,
      assessmentMedian: (json['assessment_median'] as num?)?.toDouble() ?? 0.0,
      simulationParticipants: json['simulation_participants'] as int? ?? 0,
      simulationParticipation:
          (json['simulation_participation'] as num?)?.toDouble() ?? 0.0,
      simulationAverage:
          (json['simulation_average'] as num?)?.toDouble() ?? 0.0,
      simulationMedian: (json['simulation_median'] as num?)?.toDouble() ?? 0.0,
      assignmentCompletion:
          (json['assignment_completion'] as num?)?.toDouble() ?? 0.0,
      interventionsCount: json['interventions_count'] as int? ?? 0,
      freshDataCoverage:
          (json['fresh_data_coverage'] as num?)?.toDouble() ?? 0.0,
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
    );
  }

  @override
  List<Object?> get props => [
        stream,
        studentCount,
        assessmentParticipation,
        assessmentAverage,
        simulationParticipation,
        simulationAverage,
      ];
}

/// A row in the Class / Section Report.
class ClassPerformanceRow extends Equatable {
  final String classroomId;
  final String classroomName;
  final int grade;
  final String stream;
  final int enrolledStudents;
  final String subjectId;
  final String subjectName;
  final String? assignedTeacherId;
  final String assignedTeacherName;
  final int participants;
  final double participationRate;
  final double averageScore;
  final double medianScore;
  final int mistakeCount;
  final double assignmentCompletion;
  final int supportStudentsCount;
  final DateTime dataAsOf;

  const ClassPerformanceRow({
    required this.classroomId,
    required this.classroomName,
    required this.grade,
    required this.stream,
    required this.enrolledStudents,
    required this.subjectId,
    required this.subjectName,
    this.assignedTeacherId,
    required this.assignedTeacherName,
    required this.participants,
    required this.participationRate,
    required this.averageScore,
    required this.medianScore,
    required this.mistakeCount,
    required this.assignmentCompletion,
    required this.supportStudentsCount,
    required this.dataAsOf,
  });

  factory ClassPerformanceRow.fromJson(Map<String, dynamic> json) {
    return ClassPerformanceRow(
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String,
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'natural',
      enrolledStudents: json['enrolled_students'] as int? ?? 0,
      subjectId: json['subject_id'] as String? ?? 'all',
      subjectName: json['subject_name'] as String? ?? 'All Subjects',
      assignedTeacherId: json['assigned_teacher_id'] as String?,
      assignedTeacherName:
          json['assigned_teacher_name'] as String? ?? 'Unassigned',
      participants: json['participants'] as int? ?? 0,
      participationRate:
          (json['participation_rate'] as num?)?.toDouble() ?? 0.0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      medianScore: (json['median_score'] as num?)?.toDouble() ?? 0.0,
      mistakeCount: json['mistake_count'] as int? ?? 0,
      assignmentCompletion:
          (json['assignment_completion'] as num?)?.toDouble() ?? 0.0,
      supportStudentsCount: json['support_students_count'] as int? ?? 0,
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
    );
  }

  @override
  List<Object?> get props => [
        classroomId,
        classroomName,
        enrolledStudents,
        subjectId,
        participants,
        averageScore,
        medianScore,
        supportStudentsCount,
      ];
}

/// A row in the Assessment Report preserving P5 provenance.
class AssessmentReportRow extends Equatable {
  final String examId;
  final String examTitle;
  final String subjectId;
  final String? examVariant;
  final String? sourceType;
  final String examMode;
  final String examType;
  final int eligibleStudents;
  final int participants;
  final double participationRate;
  final int attemptCount;
  final double averageScore;
  final double medianScore;
  final int bandBelow50;
  final int band50to59;
  final int band60to69;
  final int band70to79;
  final int band80to89;
  final int band90Plus;
  final DateTime dataAsOf;

  const AssessmentReportRow({
    required this.examId,
    required this.examTitle,
    required this.subjectId,
    this.examVariant,
    this.sourceType,
    required this.examMode,
    required this.examType,
    required this.eligibleStudents,
    required this.participants,
    required this.participationRate,
    required this.attemptCount,
    required this.averageScore,
    required this.medianScore,
    required this.bandBelow50,
    required this.band50to59,
    required this.band60to69,
    required this.band70to79,
    required this.band80to89,
    required this.band90Plus,
    required this.dataAsOf,
  });

  factory AssessmentReportRow.fromJson(Map<String, dynamic> json) {
    return AssessmentReportRow(
      examId: json['exam_id'] as String,
      examTitle: json['exam_title'] as String,
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] as String?,
      sourceType: json['source_type'] as String?,
      examMode: json['exam_mode'] as String? ?? 'practice',
      examType: json['exam_type'] as String? ?? 'practice',
      eligibleStudents: json['eligible_students'] as int? ?? 0,
      participants: json['participants'] as int? ?? 0,
      participationRate:
          (json['participation_rate'] as num?)?.toDouble() ?? 0.0,
      attemptCount: json['attempt_count'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      medianScore: (json['median_score'] as num?)?.toDouble() ?? 0.0,
      bandBelow50: json['band_below_50'] as int? ?? 0,
      band50to59: json['band_50_to_59'] as int? ?? 0,
      band60to69: json['band_60_to_69'] as int? ?? 0,
      band70to79: json['band_70_to_79'] as int? ?? 0,
      band80to89: json['band_80_to_89'] as int? ?? 0,
      band90Plus: json['band_90_plus'] as int? ?? 0,
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
    );
  }

  String get provenanceLabel => ExamProvenanceHelper.resolveProvenanceLabel(
        sourceType: sourceType,
        examMode: examMode,
        examType: examType,
      );

  @override
  List<Object?> get props => [
        examId,
        examTitle,
        subjectId,
        examVariant,
        sourceType,
        examMode,
        participants,
        averageScore,
        medianScore,
      ];
}

/// A row in the Assignment Outcomes Report adhering to frozen P9 denominator rules.
class AssignmentOutcomeRow extends Equatable {
  final String assignmentId;
  final String assignmentTitle;
  final String assignmentType;
  final String classroomId;
  final String classroomName;
  final String subjectId;
  final String? examVariant;
  final String teacherName;
  final int publicationCohort;
  final int requiredDenominator;
  final int submittedCount;
  final int completedCount;
  final int excusedCount;
  final int verifiedOnTimeCount;
  final int verifiedLateCount;
  final int timingUnverifiedCount;
  final int clockAnomalyCount;
  final double completionRate;
  final double verifiedOnTimeRate;
  final double verifiedLateRate;
  final double averageScore;
  final double medianScore;
  final DateTime dataAsOf;

  const AssignmentOutcomeRow({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.assignmentType,
    required this.classroomId,
    required this.classroomName,
    required this.subjectId,
    this.examVariant,
    required this.teacherName,
    required this.publicationCohort,
    required this.requiredDenominator,
    required this.submittedCount,
    required this.completedCount,
    required this.excusedCount,
    required this.verifiedOnTimeCount,
    required this.verifiedLateCount,
    required this.timingUnverifiedCount,
    required this.clockAnomalyCount,
    required this.completionRate,
    double? verifiedOnTimeRate,
    double? verifiedLateRate,
    required this.averageScore,
    required this.medianScore,
    required this.dataAsOf,
  })  : verifiedOnTimeRate = verifiedOnTimeRate ??
            ((verifiedOnTimeCount + verifiedLateCount) > 0
                ? (verifiedOnTimeCount /
                        (verifiedOnTimeCount + verifiedLateCount)) *
                    100.0
                : 0.0),
        verifiedLateRate = verifiedLateRate ??
            ((verifiedOnTimeCount + verifiedLateCount) > 0
                ? (verifiedLateCount /
                        (verifiedOnTimeCount + verifiedLateCount)) *
                    100.0
                : 0.0);

  factory AssignmentOutcomeRow.fromJson(Map<String, dynamic> json) {
    final onTime = json['verified_on_time_count'] as int? ?? 0;
    final late = json['verified_late_count'] as int? ?? 0;
    final verifiedTimingTotal = onTime + late;
    final onTimeRate = (json['verified_on_time_rate'] as num?)?.toDouble() ??
        (verifiedTimingTotal > 0
            ? (onTime / verifiedTimingTotal) * 100.0
            : 0.0);
    final lateRate = (json['verified_late_rate'] as num?)?.toDouble() ??
        (verifiedTimingTotal > 0 ? (late / verifiedTimingTotal) * 100.0 : 0.0);

    return AssignmentOutcomeRow(
      assignmentId: json['assignment_id'] as String,
      assignmentTitle: json['assignment_title'] as String,
      assignmentType: json['assignment_type'] as String,
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String,
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] as String?,
      teacherName: json['teacher_name'] as String? ?? 'Teacher',
      publicationCohort: json['publication_cohort'] as int? ?? 0,
      requiredDenominator: json['required_denominator'] as int? ?? 0,
      submittedCount: json['submitted_count'] as int? ?? 0,
      completedCount: json['completed_count'] as int? ?? 0,
      excusedCount: json['excused_count'] as int? ?? 0,
      verifiedOnTimeCount: onTime,
      verifiedLateCount: late,
      timingUnverifiedCount: json['timing_unverified_count'] as int? ?? 0,
      clockAnomalyCount: json['clock_anomaly_count'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      verifiedOnTimeRate: onTimeRate,
      verifiedLateRate: lateRate,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      medianScore: (json['median_score'] as num?)?.toDouble() ?? 0.0,
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
    );
  }

  @override
  List<Object?> get props => [
        assignmentId,
        assignmentTitle,
        requiredDenominator,
        submittedCount,
        completedCount,
        verifiedOnTimeCount,
        verifiedLateCount,
        verifiedOnTimeRate,
        verifiedLateRate,
        timingUnverifiedCount,
        completionRate,
      ];
}

/// A row in the Intervention Follow-Up Report under intervention_followup_v1.
class InterventionFollowUpRow extends Equatable {
  final String interventionId;
  final String studentId;
  final String studentName;
  final String classroomId;
  final String classroomName;
  final String subjectId;
  final String? examVariant;
  final String teacherName;
  final String source;
  final String? severityAtCreation;
  final List<String> reasonCodes;
  final String actionType;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? baselineAccuracy;
  final double? followupAccuracy;
  final double? observedChangePp;
  final String evidenceStatus;
  final String evidenceInterpretation;
  final int evidenceCountPre;
  final int evidenceCountPost;
  final String confidence;
  final DateTime dataAsOf;

  const InterventionFollowUpRow({
    required this.interventionId,
    required this.studentId,
    required this.studentName,
    required this.classroomId,
    required this.classroomName,
    required this.subjectId,
    this.examVariant,
    required this.teacherName,
    required this.source,
    this.severityAtCreation,
    required this.reasonCodes,
    required this.actionType,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.baselineAccuracy,
    this.followupAccuracy,
    this.observedChangePp,
    required this.evidenceStatus,
    required this.evidenceInterpretation,
    int? evidenceCountPre,
    int? evidenceCountPost,
    String? confidence,
    required this.dataAsOf,
  })  : evidenceCountPre =
            evidenceCountPre ?? (baselineAccuracy != null ? 1 : 0),
        evidenceCountPost =
            evidenceCountPost ?? (followupAccuracy != null ? 1 : 0),
        confidence = confidence ??
            ((baselineAccuracy != null && followupAccuracy != null)
                ? 'limited'
                : 'insufficient');

  factory InterventionFollowUpRow.fromJson(Map<String, dynamic> json) {
    List<String> reasons = [];
    if (json['reason_codes_json'] is List) {
      reasons =
          (json['reason_codes_json'] as List).map((e) => e.toString()).toList();
    }

    return InterventionFollowUpRow(
      interventionId: json['intervention_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? 'Student',
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String? ?? 'Classroom',
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] as String?,
      teacherName: json['teacher_name'] as String? ?? 'Teacher',
      source: json['source'] as String,
      severityAtCreation: json['severity_at_creation'] as String?,
      reasonCodes: reasons,
      actionType: json['action_type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      baselineAccuracy: (json['baseline_accuracy'] as num?)?.toDouble(),
      followupAccuracy: (json['followup_accuracy'] as num?)?.toDouble(),
      observedChangePp: (json['observed_change_pp'] as num?)?.toDouble(),
      evidenceStatus:
          json['evidence_status'] as String? ?? 'insufficient_evidence',
      evidenceInterpretation: json['evidence_interpretation'] as String? ??
          'Awaiting comparable evidence',
      evidenceCountPre: json['evidence_count_pre'] as int? ??
          (json['baseline_accuracy'] != null ? 1 : 0),
      evidenceCountPost: json['evidence_count_post'] as int? ??
          (json['followup_accuracy'] != null ? 1 : 0),
      confidence: json['confidence'] as String? ?? 'insufficient',
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
    );
  }

  @override
  List<Object?> get props => [
        interventionId,
        studentId,
        studentName,
        subjectId,
        examVariant,
        status,
        baselineAccuracy,
        followupAccuracy,
        observedChangePp,
        evidenceStatus,
        evidenceCountPre,
        evidenceCountPost,
        confidence,
      ];
}

/// A row in the Student Support Report.
class StudentSupportRow extends Equatable {
  final String studentId;
  final String studentName;
  final String classroomId;
  final String classroomName;
  final String subjectId;
  final String severity;
  final List<String> attentionReasons;
  final double? recentAccuracy;
  final int activeMistakes;
  final int openInterventions;
  final String dataFreshness;
  final DateTime dataAsOf;

  const StudentSupportRow({
    required this.studentId,
    required this.studentName,
    required this.classroomId,
    required this.classroomName,
    required this.subjectId,
    required this.severity,
    required this.attentionReasons,
    this.recentAccuracy,
    required this.activeMistakes,
    required this.openInterventions,
    required this.dataFreshness,
    required this.dataAsOf,
  });

  factory StudentSupportRow.fromJson(Map<String, dynamic> json) {
    List<String> reasons = [];
    if (json['attention_reasons'] is List) {
      reasons =
          (json['attention_reasons'] as List).map((e) => e.toString()).toList();
    }

    return StudentSupportRow(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String,
      subjectId: json['subject_id'] as String? ?? 'all',
      severity: json['severity'] as String? ?? 'low',
      attentionReasons: reasons,
      recentAccuracy: (json['recent_accuracy'] as num?)?.toDouble(),
      activeMistakes: json['active_mistakes'] as int? ?? 0,
      openInterventions: json['open_interventions'] as int? ?? 0,
      dataFreshness: json['data_freshness'] as String? ?? 'fresh',
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        classroomId,
        subjectId,
        severity,
        activeMistakes,
        openInterventions,
      ];
}

/// Data Coverage and Synchronization Freshness Report.
class DataCoverageReport extends Equatable {
  final String schoolId;
  final String academicYear;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dataAsOf;
  final int totalActiveStudents;
  final int freshSyncCount;
  final int moderateSyncCount;
  final int staleSyncCount;
  final int veryStaleSyncCount;
  final double freshCoverageRate;
  final int timingUnverifiedCount;
  final int clockAnomalyCount;
  final String methodologicalNotice;

  const DataCoverageReport({
    required this.schoolId,
    required this.academicYear,
    required this.periodStart,
    required this.periodEnd,
    required this.dataAsOf,
    required this.totalActiveStudents,
    required this.freshSyncCount,
    required this.moderateSyncCount,
    required this.staleSyncCount,
    required this.veryStaleSyncCount,
    required this.freshCoverageRate,
    required this.timingUnverifiedCount,
    required this.clockAnomalyCount,
    this.methodologicalNotice =
        'Stale synchronization reflects offline mobile usage patterns in network-constrained environments. Missing cloud evidence must not be interpreted as lack of study.',
  });

  factory DataCoverageReport.fromJson(Map<String, dynamic> json) {
    return DataCoverageReport(
      schoolId: json['school_id'] as String,
      academicYear: json['academic_year'] as String? ?? '2026/27',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
      totalActiveStudents: json['total_active_students'] as int? ?? 0,
      freshSyncCount: json['fresh_sync_count'] as int? ?? 0,
      moderateSyncCount: json['moderate_sync_count'] as int? ?? 0,
      staleSyncCount: json['stale_sync_count'] as int? ?? 0,
      veryStaleSyncCount: json['very_stale_sync_count'] as int? ?? 0,
      freshCoverageRate:
          (json['fresh_coverage_rate'] as num?)?.toDouble() ?? 0.0,
      timingUnverifiedCount: json['timing_unverified_count'] as int? ?? 0,
      clockAnomalyCount: json['clock_anomaly_count'] as int? ?? 0,
      methodologicalNotice: json['methodological_notice'] as String? ??
          'Stale synchronization reflects offline mobile usage patterns in network-constrained environments. Missing cloud evidence must not be interpreted as lack of study.',
    );
  }

  @override
  List<Object?> get props => [
        schoolId,
        academicYear,
        totalActiveStudents,
        freshSyncCount,
        staleSyncCount,
        freshCoverageRate,
        timingUnverifiedCount,
      ];
}

/// Authorized individual student academic summary.
class StudentAcademicReport extends Equatable {
  final String studentId;
  final String studentName;
  final int grade;
  final String stream;
  final String classroomName;
  final String academicYear;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dataAsOf;
  final int totalAttempts;
  final double averageScore;
  final double medianScore;
  final int activeMistakes;
  final int assignmentsAssigned;
  final int assignmentsCompleted;
  final int interventionsReceived;
  final DateTime? lastSyncTimestamp;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastCloudAcademicActivity;
  final String syncFreshness;
  final String p4MasteryNotice;

  const StudentAcademicReport({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.stream,
    required this.classroomName,
    required this.academicYear,
    required this.periodStart,
    required this.periodEnd,
    required this.dataAsOf,
    required this.totalAttempts,
    required this.averageScore,
    required this.medianScore,
    required this.activeMistakes,
    required this.assignmentsAssigned,
    required this.assignmentsCompleted,
    required this.interventionsReceived,
    this.lastSyncTimestamp,
    this.lastSuccessfulSync,
    this.lastCloudAcademicActivity,
    this.syncFreshness = 'unknown',
    this.p4MasteryNotice =
        'FidelLearn P4 adaptive spaced mastery and composite national readiness are device-local and not synchronized to institutional cloud reports.',
  });

  factory StudentAcademicReport.fromJson(Map<String, dynamic> json) {
    return StudentAcademicReport(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'natural',
      classroomName: json['classroom_name'] as String? ?? 'Unassigned Class',
      academicYear: json['academic_year'] as String? ?? '2026/27',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
      totalAttempts: json['total_attempts'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      medianScore: (json['median_score'] as num?)?.toDouble() ?? 0.0,
      activeMistakes: json['active_mistakes'] as int? ?? 0,
      assignmentsAssigned: json['assignments_assigned'] as int? ?? 0,
      assignmentsCompleted: json['assignments_completed'] as int? ?? 0,
      interventionsReceived: json['interventions_received'] as int? ?? 0,
      lastSyncTimestamp: json['last_sync_timestamp'] != null
          ? DateTime.tryParse(json['last_sync_timestamp'] as String)
          : null,
      lastSuccessfulSync: json['last_successful_sync'] != null
          ? DateTime.tryParse(json['last_successful_sync'] as String)
          : (json['last_sync_timestamp'] != null
              ? DateTime.tryParse(json['last_sync_timestamp'] as String)
              : null),
      lastCloudAcademicActivity: json['last_cloud_academic_activity'] != null
          ? DateTime.tryParse(json['last_cloud_academic_activity'] as String)
          : null,
      syncFreshness: json['sync_freshness'] as String? ?? 'unknown',
      p4MasteryNotice: json['p4_mastery_notice'] as String? ??
          'FidelLearn P4 adaptive spaced mastery and composite national readiness are device-local and not synchronized to institutional cloud reports.',
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        totalAttempts,
        averageScore,
        medianScore,
        activeMistakes,
        assignmentsCompleted,
        interventionsReceived,
        lastSyncTimestamp,
        lastSuccessfulSync,
        lastCloudAcademicActivity,
        syncFreshness,
      ];
}

/// A row representing an instructional classroom-subject assignment slot.
class TeacherCoverageSlotRow extends Equatable {
  final String classroomId;
  final String classroomName;
  final int grade;
  final String stream;
  final String subjectId;
  final String subjectName;
  final bool isAssigned;
  final String? teacherId;
  final String? teacherName;

  const TeacherCoverageSlotRow({
    required this.classroomId,
    required this.classroomName,
    required this.grade,
    required this.stream,
    required this.subjectId,
    required this.subjectName,
    required this.isAssigned,
    this.teacherId,
    this.teacherName,
  });

  factory TeacherCoverageSlotRow.fromJson(Map<String, dynamic> json) {
    return TeacherCoverageSlotRow(
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String,
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'natural',
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      isAssigned: json['is_assigned'] as bool? ?? false,
      teacherId: json['teacher_id'] as String?,
      teacherName: json['teacher_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        classroomId,
        classroomName,
        grade,
        stream,
        subjectId,
        subjectName,
        isAssigned,
        teacherId,
        teacherName,
      ];
}

/// Teacher Coverage Report derived from canonical teacher_subject_assignments.
class TeacherCoverageReport extends Equatable {
  final String schoolId;
  final String academicYear;
  final DateTime dataAsOf;
  final int totalClassrooms;
  final int totalSubjects;
  final int totalRequiredSlots;
  final int assignedSlots;
  final int unassignedSlots;
  final double coveragePercentage;
  final List<TeacherCoverageSlotRow> slots;

  const TeacherCoverageReport({
    required this.schoolId,
    required this.academicYear,
    required this.dataAsOf,
    required this.totalClassrooms,
    required this.totalSubjects,
    required this.totalRequiredSlots,
    required this.assignedSlots,
    required this.unassignedSlots,
    required this.coveragePercentage,
    required this.slots,
  });

  factory TeacherCoverageReport.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    final slots = rawSlots
        .map((s) => TeacherCoverageSlotRow.fromJson(s as Map<String, dynamic>))
        .toList();

    return TeacherCoverageReport(
      schoolId: json['school_id'] as String,
      academicYear: json['academic_year'] as String? ?? '2026/27',
      dataAsOf: DateTime.parse(json['data_as_of'] as String),
      totalClassrooms: json['total_classrooms'] as int? ?? 0,
      totalSubjects: json['total_subjects'] as int? ?? 0,
      totalRequiredSlots: json['total_required_slots'] as int? ?? 0,
      assignedSlots: json['assigned_slots'] as int? ?? 0,
      unassignedSlots: json['unassigned_slots'] as int? ?? 0,
      coveragePercentage:
          (json['coverage_percentage'] as num?)?.toDouble() ?? 0.0,
      slots: slots,
    );
  }

  @override
  List<Object?> get props => [
        schoolId,
        academicYear,
        dataAsOf,
        totalClassrooms,
        totalSubjects,
        totalRequiredSlots,
        assignedSlots,
        unassignedSlots,
        coveragePercentage,
        slots,
      ];
}

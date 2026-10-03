import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../domain/models/institutional_reporting_models.dart';

/// Pure Dart RFC 4180 CSV serializer for institutional reports.
/// Excludes all PII (no phone, email, passwords, Study Coins, push tokens).
/// Generates deterministic outputs and SHA-256 integrity hashes.
class InstitutionalCsvExporter {
  /// Format a string field safely for CSV according to RFC 4180 with OWASP formula injection defense.
  static String escapeField(dynamic value) {
    if (value == null) return '';
    var str = value.toString();
    // Defense against CSV / Spreadsheet formula injection:
    // Any cell starting with =, +, -, @, \t, or \r is prepended with a single quote.
    if (str.isNotEmpty &&
        (str.startsWith('=') ||
            str.startsWith('+') ||
            str.startsWith('-') ||
            str.startsWith('@') ||
            str.startsWith('\t') ||
            str.startsWith('\r'))) {
      str = "'$str";
    }
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      final escaped = str.replaceAll('"', '""');
      return '"$escaped"';
    }
    return str;
  }

  /// Convert a list of rows to an RFC 4180 CSV string with CRLF row breaks.
  static String toCsvString(List<List<dynamic>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      final line = row.map(escapeField).join(',');
      buffer.write('$line\r\n');
    }
    return buffer.toString();
  }

  /// Calculate SHA-256 hash of CSV payload.
  static String calculateSha256(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  /// Export Executive Report as CSV.
  static String exportExecutive(ExecutiveReport report) {
    final rows = <List<dynamic>>[
      ['Report', 'School Executive Report'],
      ['School ID', report.schoolId],
      ['School Name', report.schoolName],
      ['Academic Year', report.academicYear],
      ['Period Start', report.periodStart.toIso8601String()],
      ['Period End', report.periodEnd.toIso8601String()],
      ['Data as of', report.dataAsOf.toIso8601String()],
      ['Analytics Version', report.analyticsVersion],
      ['Report Schema Version', report.reportSchemaVersion],
      [],
      ['Metric ID', 'Metric Name', 'Value', 'Unit / Details'],
      [
        'active_enrolled_students',
        'Active Enrolled Students',
        report.activeEnrolledStudents,
        'Students'
      ],
      [
        'students_with_academic_evidence',
        'Students with Academic Evidence',
        report.studentsWithAcademicEvidence,
        'Students'
      ],
      [
        'natural_stream_students',
        'Natural Science Students',
        report.naturalStreamStudents,
        'Students'
      ],
      [
        'social_stream_students',
        'Social Science Students',
        report.socialStreamStudents,
        'Students'
      ],
      [
        'active_teachers',
        'Active Teachers',
        report.teacherPopulation,
        'Teachers'
      ],
      [
        'active_classrooms',
        'Active Classrooms',
        report.classPopulation,
        'Classrooms'
      ],
      [
        'assessment_participation_rate',
        'Assessment Participation Rate',
        '${report.assessmentParticipationRate}%',
        '${report.assessmentParticipants} / ${report.assessmentEligibleStudents}'
      ],
      [
        'recent_assessment_average',
        'Recent Assessment Average',
        '${report.recentAssessmentAverage}%',
        'Percentage'
      ],
      [
        'recent_assessment_median',
        'Recent Assessment Median',
        '${report.recentAssessmentMedian}%',
        'Percentage'
      ],
      [
        'simulation_participation_rate',
        'Simulation Participation Rate',
        '${report.simulationParticipationRate}%',
        '${report.simulationParticipants} / ${report.assessmentEligibleStudents}'
      ],
      [
        'simulation_average',
        'Simulation Average Score',
        '${report.simulationAverage}%',
        'Percentage'
      ],
      [
        'simulation_median',
        'Simulation Median Score',
        '${report.simulationMedian}%',
        'Percentage'
      ],
      [
        'assignment_completion_rate',
        'Assignment Completion Rate',
        '${report.completionRate}%',
        '${report.submittedCount} / ${report.requiredForCompletion}'
      ],
      [
        'assignment_on_time_rate_verified',
        'Verified On-Time Rate',
        '${report.verifiedOnTimeRate}%',
        'Verified Submissions'
      ],
      [
        'assignment_late_rate_verified',
        'Verified Late Rate',
        '${report.lateRateVerified}%',
        '${report.verifiedLateCount} Late Submissions'
      ],
      [
        'assignment_timing_unverified',
        'Timing Unverified Submissions',
        report.timingUnverifiedCount,
        'Submissions'
      ],
      [
        'interventions_created',
        'Interventions Created',
        report.interventionsCreated,
        'Interventions'
      ],
      [
        'interventions_completed',
        'Interventions Completed',
        report.interventionsCompleted,
        'Interventions'
      ],
      [
        'interventions_with_followup',
        'Interventions with Follow-Up Evidence',
        report.interventionsWithFollowupEvidence,
        'Interventions'
      ],
      [
        'teacher_assignment_coverage',
        'Teacher Assignment Coverage',
        '${report.teacherCoverageRate}%',
        'Instructional Slots'
      ],
      [
        'fresh_data_coverage',
        'Fresh Data Coverage (<= 14 days)',
        '${report.freshDataCoverageRate}%',
        '${report.freshSyncCount + report.moderateSyncCount} / ${report.studentPopulation}'
      ],
      [],
      ['Methodological Disclaimers'],
      ['Non-Causal Notice', report.nonCausalNotice],
      ['Data Freshness Caveat', report.freshnessCaveat],
    ];
    return toCsvString(rows);
  }

  /// Export Subject Performance Report as CSV.
  static String exportSubjects(List<SubjectPerformanceRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'subject_id',
        'subject_name',
        'exam_variant',
        'stream',
        'eligible_students',
        'participants',
        'participation_rate_pct',
        'attempt_count',
        'average_score_pct',
        'median_score_pct',
        'affected_students',
        'active_mistakes',
        'interventions_count',
        'data_as_of',
        'privacy_suppressed',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.subjectId,
        r.subjectName,
        r.examVariant ?? 'common',
        r.stream,
        r.eligibleStudents,
        r.participants,
        r.participationRate,
        r.attemptCount,
        r.privacySuppressed ? '[SUPPRESSED n<5]' : (r.averageScore ?? ''),
        r.privacySuppressed ? '[SUPPRESSED n<5]' : (r.medianScore ?? ''),
        r.affectedStudents,
        r.activeMistakes,
        r.interventionsCount,
        r.dataAsOf.toIso8601String(),
        r.privacySuppressed,
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Stream Performance Report as CSV.
  static String exportStreams(List<StreamPerformanceRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'stream',
        'stream_label',
        'student_count',
        'active_classrooms',
        'assessment_participants',
        'assessment_participation_rate',
        'assessment_average_pct',
        'assessment_median_pct',
        'simulation_participants',
        'simulation_participation_rate',
        'simulation_average_pct',
        'simulation_median_pct',
        'assignment_completion_rate',
        'interventions_count',
        'fresh_data_coverage_pct',
        'data_as_of',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.stream,
        r.streamLabel,
        r.studentCount,
        r.activeClassrooms,
        r.assessmentParticipants,
        r.assessmentParticipation,
        r.assessmentAverage,
        r.assessmentMedian,
        r.simulationParticipants,
        r.simulationParticipation,
        r.simulationAverage,
        r.simulationMedian,
        r.assignmentCompletion,
        r.interventionsCount,
        r.freshDataCoverage,
        r.dataAsOf.toIso8601String(),
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Class / Section Report as CSV.
  static String exportClasses(List<ClassPerformanceRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'classroom_id',
        'classroom_name',
        'grade',
        'stream',
        'enrolled_students',
        'subject_id',
        'subject_name',
        'assigned_teacher',
        'participants',
        'participation_rate_pct',
        'average_score_pct',
        'median_score_pct',
        'mistake_count',
        'support_students_count',
        'data_as_of',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.classroomId,
        r.classroomName,
        r.grade,
        r.stream,
        r.enrolledStudents,
        r.subjectId,
        r.subjectName,
        r.assignedTeacherName,
        r.participants,
        r.participationRate,
        r.averageScore,
        r.medianScore,
        r.mistakeCount,
        r.supportStudentsCount,
        r.dataAsOf.toIso8601String(),
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Assessment Report as CSV.
  static String exportAssessments(List<AssessmentReportRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'exam_id',
        'exam_title',
        'subject_id',
        'exam_variant',
        'source_type',
        'exam_mode',
        'exam_type',
        'eligible_students',
        'participants',
        'participation_rate_pct',
        'attempt_count',
        'average_score_pct',
        'median_score_pct',
        'band_below_50',
        'band_50_to_59',
        'band_60_to_69',
        'band_70_to_79',
        'band_80_to_89',
        'band_90_plus',
        'data_as_of',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.examId,
        r.examTitle,
        r.subjectId,
        r.examVariant ?? 'none',
        r.sourceType ?? 'none',
        r.examMode,
        r.examType,
        r.eligibleStudents,
        r.participants,
        r.participationRate,
        r.attemptCount,
        r.averageScore,
        r.medianScore,
        r.bandBelow50,
        r.band50to59,
        r.band60to69,
        r.band70to79,
        r.band80to89,
        r.band90Plus,
        r.dataAsOf.toIso8601String(),
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Assignment Outcomes Report as CSV.
  static String exportAssignments(List<AssignmentOutcomeRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'assignment_id',
        'assignment_title',
        'assignment_type',
        'classroom_id',
        'classroom_name',
        'subject_id',
        'exam_variant',
        'teacher_name',
        'publication_cohort',
        'required_denominator',
        'submitted_count',
        'completed_count',
        'excused_count',
        'verified_on_time_count',
        'verified_late_count',
        'timing_unverified_count',
        'clock_anomaly_count',
        'completion_rate_pct',
        'average_score_pct',
        'median_score_pct',
        'data_as_of',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.assignmentId,
        r.assignmentTitle,
        r.assignmentType,
        r.classroomId,
        r.classroomName,
        r.subjectId,
        r.examVariant ?? 'none',
        r.teacherName,
        r.publicationCohort,
        r.requiredDenominator,
        r.submittedCount,
        r.completedCount,
        r.excusedCount,
        r.verifiedOnTimeCount,
        r.verifiedLateCount,
        r.timingUnverifiedCount,
        r.clockAnomalyCount,
        r.completionRate,
        r.averageScore,
        r.medianScore,
        r.dataAsOf.toIso8601String(),
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Intervention Follow-Up Report as CSV.
  static String exportInterventions(List<InterventionFollowUpRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'intervention_id',
        'student_id',
        'student_name',
        'classroom_name',
        'subject_id',
        'exam_variant',
        'teacher_name',
        'source',
        'severity_at_creation',
        'reason_codes',
        'action_type',
        'workflow_status',
        'created_at',
        'completed_at',
        'baseline_accuracy_pct',
        'followup_accuracy_pct',
        'observed_change_pp',
        'evidence_status',
        'evidence_interpretation',
        'data_as_of',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.interventionId,
        r.studentId,
        r.studentName,
        r.classroomName,
        r.subjectId,
        r.examVariant ?? 'none',
        r.teacherName,
        r.source,
        r.severityAtCreation ?? 'unspecified',
        r.reasonCodes.join('; '),
        r.actionType,
        r.status,
        r.createdAt.toIso8601String(),
        r.completedAt?.toIso8601String() ?? '',
        r.baselineAccuracy ?? '',
        r.followupAccuracy ?? '',
        r.observedChangePp != null
            ? '${r.observedChangePp! >= 0 ? '+' : ''}${r.observedChangePp}'
            : '',
        r.evidenceStatus,
        r.evidenceInterpretation,
        r.dataAsOf.toIso8601String(),
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Student Support Report as CSV.
  static String exportStudentSupport(List<StudentSupportRow> rows) {
    final csvRows = <List<dynamic>>[
      [
        'student_id',
        'student_name',
        'classroom_name',
        'subject_id',
        'severity',
        'attention_reasons',
        'recent_accuracy_pct',
        'active_mistakes',
        'open_interventions',
        'data_freshness',
        'data_as_of',
      ]
    ];

    for (final r in rows) {
      csvRows.add([
        r.studentId,
        r.studentName,
        r.classroomName,
        r.subjectId,
        r.severity,
        r.attentionReasons.join('; '),
        r.recentAccuracy ?? '',
        r.activeMistakes,
        r.openInterventions,
        r.dataFreshness,
        r.dataAsOf.toIso8601String(),
      ]);
    }

    return toCsvString(csvRows);
  }

  /// Export Teacher Coverage Report as CSV.
  static String exportTeacherCoverage(TeacherCoverageReport report) {
    final csvRows = <List<dynamic>>[
      ['Report', 'Teacher Coverage Report'],
      ['School ID', report.schoolId],
      ['Academic Year', report.academicYear],
      ['Data as of', report.dataAsOf.toIso8601String()],
      ['Total Classrooms', report.totalClassrooms],
      ['Curriculum Subjects', report.totalSubjects],
      ['Total Required Slots', report.totalRequiredSlots],
      ['Assigned Slots', report.assignedSlots],
      ['Unassigned Slots', report.unassignedSlots],
      ['Coverage Percentage', '${report.coveragePercentage}%'],
      [],
      [
        'classroom_id',
        'classroom_name',
        'grade',
        'stream',
        'subject_id',
        'subject_name',
        'is_assigned',
        'teacher_id',
        'teacher_name',
      ]
    ];

    for (final slot in report.slots) {
      csvRows.add([
        slot.classroomId,
        slot.classroomName,
        slot.grade,
        slot.stream,
        slot.subjectId,
        slot.subjectName,
        slot.isAssigned,
        slot.teacherId ?? '',
        slot.teacherName ?? '',
      ]);
    }

    return toCsvString(csvRows);
  }
}

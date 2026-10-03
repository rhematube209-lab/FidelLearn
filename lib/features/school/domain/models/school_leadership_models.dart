import 'package:equatable/equatable.dart';

import '../../../exams/domain/models/exam_mode.dart';
import '../../../teacher/domain/models/teacher_portal_models.dart';
export '../../../teacher/domain/models/teacher_portal_models.dart'
    show AttentionSeverity;

// =============================================================================
// FidelLearn — P8 School Leadership Domain Models
// Pure Dart models for School Leadership (Principals, Academic Directors,
// Vice Principals, School Admins).
// =============================================================================

/// Executive KPI overview for School Leadership Home.
class SchoolLeadershipSummary extends Equatable {
  final String schoolId;
  final String schoolName;
  final String academicYear;
  final int totalActiveStudents;
  final int naturalStreamStudents;
  final int socialStreamStudents;
  final int totalActiveTeachers;
  final int totalActiveClassrooms;
  final int recentSimulationCount;
  final double recentSimulationAvgPct;
  final double recentSimulationMedianPct;
  final double simulationParticipationRate;
  final int uniqueStudentsNeedingHelp;
  final int highSeverityStudentCount;
  final int staleSyncStudentCount;
  final String? topWeakSubjectName;
  final int topWeakSubjectMistakes;
  final double teacherAssignmentCoverage;
  final int unassignedSubjectSlots;
  final double freshDataCoverageRate;

  const SchoolLeadershipSummary({
    required this.schoolId,
    required this.schoolName,
    required this.academicYear,
    required this.totalActiveStudents,
    required this.naturalStreamStudents,
    required this.socialStreamStudents,
    required this.totalActiveTeachers,
    required this.totalActiveClassrooms,
    required this.recentSimulationCount,
    required this.recentSimulationAvgPct,
    required this.recentSimulationMedianPct,
    required this.simulationParticipationRate,
    required this.uniqueStudentsNeedingHelp,
    required this.highSeverityStudentCount,
    required this.staleSyncStudentCount,
    this.topWeakSubjectName,
    required this.topWeakSubjectMistakes,
    required this.teacherAssignmentCoverage,
    required this.unassignedSubjectSlots,
    required this.freshDataCoverageRate,
  });

  factory SchoolLeadershipSummary.fromJson(Map<String, dynamic> json) {
    return SchoolLeadershipSummary(
      schoolId: json['school_id'] as String,
      schoolName: json['school_name'] as String? ?? 'School',
      academicYear: json['academic_year'] as String? ?? '2026/27',
      totalActiveStudents: json['total_active_students'] as int? ?? 0,
      naturalStreamStudents: json['natural_stream_students'] as int? ?? 0,
      socialStreamStudents: json['social_stream_students'] as int? ?? 0,
      totalActiveTeachers: json['total_active_teachers'] as int? ?? 0,
      totalActiveClassrooms: json['total_active_classrooms'] as int? ?? 0,
      recentSimulationCount: json['recent_simulation_count'] as int? ?? 0,
      recentSimulationAvgPct:
          (json['recent_simulation_avg_pct'] as num?)?.toDouble() ?? 0.0,
      recentSimulationMedianPct:
          (json['recent_simulation_median_pct'] as num?)?.toDouble() ?? 0.0,
      simulationParticipationRate:
          (json['simulation_participation_rate'] as num?)?.toDouble() ?? 0.0,
      uniqueStudentsNeedingHelp:
          json['unique_students_needing_help'] as int? ?? 0,
      highSeverityStudentCount:
          json['high_severity_student_count'] as int? ?? 0,
      staleSyncStudentCount: json['stale_sync_student_count'] as int? ?? 0,
      topWeakSubjectName: json['top_weak_subject_name'] as String?,
      topWeakSubjectMistakes: json['top_weak_subject_mistakes'] as int? ?? 0,
      teacherAssignmentCoverage:
          (json['teacher_assignment_coverage'] as num?)?.toDouble() ?? 0.0,
      unassignedSubjectSlots: json['unassigned_subject_slots'] as int? ?? 0,
      freshDataCoverageRate:
          (json['fresh_data_coverage_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        schoolId,
        schoolName,
        academicYear,
        totalActiveStudents,
        naturalStreamStudents,
        socialStreamStudents,
        totalActiveTeachers,
        totalActiveClassrooms,
        recentSimulationCount,
        recentSimulationAvgPct,
        recentSimulationMedianPct,
        simulationParticipationRate,
        uniqueStudentsNeedingHelp,
        highSeverityStudentCount,
        staleSyncStudentCount,
        topWeakSubjectName,
        topWeakSubjectMistakes,
        teacherAssignmentCoverage,
        unassignedSubjectSlots,
        freshDataCoverageRate,
      ];
}

/// Comparison between Natural Science and Social Science cohorts.
class SchoolStreamSummary extends Equatable {
  final String stream;
  final String streamLabel;
  final int enrolledStudents;
  final int activeClassrooms;
  final double recentSimulationAvgPct;
  final double recentSimulationMedianPct;
  final double simulationParticipationRate;
  final int activeMistakeCount;
  final double freshDataCoverageRate;

  const SchoolStreamSummary({
    required this.stream,
    required this.streamLabel,
    required this.enrolledStudents,
    required this.activeClassrooms,
    required this.recentSimulationAvgPct,
    required this.recentSimulationMedianPct,
    required this.simulationParticipationRate,
    required this.activeMistakeCount,
    required this.freshDataCoverageRate,
  });

  bool get isNatural => stream.toLowerCase().contains('nat');
  bool get isSocial => stream.toLowerCase().contains('soc');
  double get participationRate => simulationParticipationRate;

  factory SchoolStreamSummary.fromJson(Map<String, dynamic> json) {
    return SchoolStreamSummary(
      stream: json['stream'] as String,
      streamLabel: json['stream_label'] as String? ??
          ((json['stream'] as String? ?? '').toLowerCase().contains('nat')
              ? 'Natural Science'
              : ((json['stream'] as String? ?? '').toLowerCase().contains('soc')
                  ? 'Social Science'
                  : 'Stream')),
      enrolledStudents: json['enrolled_students'] as int? ?? 0,
      activeClassrooms: json['active_classrooms'] as int? ?? 0,
      recentSimulationAvgPct:
          (json['recent_simulation_avg_pct'] as num?)?.toDouble() ?? 0.0,
      recentSimulationMedianPct:
          (json['recent_simulation_median_pct'] as num?)?.toDouble() ?? 0.0,
      simulationParticipationRate: ((json['simulation_participation_rate'] ??
                  json['participation_rate']) as num?)
              ?.toDouble() ??
          0.0,
      activeMistakeCount: json['active_mistake_count'] as int? ?? 0,
      freshDataCoverageRate:
          (json['fresh_data_coverage_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        stream,
        streamLabel,
        enrolledStudents,
        activeClassrooms,
        recentSimulationAvgPct,
        recentSimulationMedianPct,
        simulationParticipationRate,
        activeMistakeCount,
        freshDataCoverageRate,
      ];
}

/// Subject performance and mistake concentration across the school.
class SchoolSubjectSummary extends Equatable {
  final String subjectId;
  final String subjectName;
  final String? examVariant;
  final String displayName;
  final String stream;
  final int enrolledStudentCount;
  final int attemptCount;
  final int participantCount;
  final double participationRate;
  final double avgPercentage;
  final double medianPercentage;
  final int activeMistakeCount;
  final int affectedStudentCount;
  final int teacherAssignedCount;
  final bool hasTeacherCoverage;

  const SchoolSubjectSummary({
    required this.subjectId,
    required this.subjectName,
    this.examVariant,
    required this.displayName,
    required this.stream,
    required this.enrolledStudentCount,
    required this.attemptCount,
    required this.participantCount,
    required this.participationRate,
    required this.avgPercentage,
    required this.medianPercentage,
    required this.activeMistakeCount,
    required this.affectedStudentCount,
    required this.teacherAssignedCount,
    required this.hasTeacherCoverage,
  });

  factory SchoolSubjectSummary.fromJson(Map<String, dynamic> json) {
    return SchoolSubjectSummary(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Subject',
      examVariant: json['exam_variant'] as String?,
      displayName: json['display_name'] as String? ?? 'Subject',
      stream: json['stream'] as String? ?? 'common',
      enrolledStudentCount: json['enrolled_student_count'] as int? ?? 0,
      attemptCount: json['attempt_count'] as int? ?? 0,
      participantCount: json['participant_count'] as int? ?? 0,
      participationRate:
          (json['participation_rate'] as num?)?.toDouble() ?? 0.0,
      avgPercentage: (json['avg_percentage'] as num?)?.toDouble() ?? 0.0,
      medianPercentage: (json['median_percentage'] as num?)?.toDouble() ?? 0.0,
      activeMistakeCount: json['active_mistake_count'] as int? ?? 0,
      affectedStudentCount: json['affected_student_count'] as int? ?? 0,
      teacherAssignedCount: json['teacher_assigned_count'] as int? ?? 0,
      hasTeacherCoverage: json['has_teacher_coverage'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        examVariant,
        displayName,
        stream,
        enrolledStudentCount,
        attemptCount,
        participantCount,
        participationRate,
        avgPercentage,
        medianPercentage,
        activeMistakeCount,
        affectedStudentCount,
        teacherAssignedCount,
        hasTeacherCoverage,
      ];
}

/// Classroom section comparative metrics.
class SchoolClassSummary extends Equatable {
  final String classroomId;
  final String classroomName;
  final int grade;
  final String stream;
  final String section;
  final int enrolledStudents;
  final int recentAttemptCount;
  final int participantCount;
  final double participationRate;
  final double avgPercentage;
  final double medianPercentage;
  final int activeMistakeCount;
  final int assignedTeacherCount;
  final double freshDataCoverageRate;

  const SchoolClassSummary({
    required this.classroomId,
    required this.classroomName,
    required this.grade,
    required this.stream,
    required this.section,
    required this.enrolledStudents,
    required this.recentAttemptCount,
    required this.participantCount,
    required this.participationRate,
    required this.avgPercentage,
    required this.medianPercentage,
    required this.activeMistakeCount,
    required this.assignedTeacherCount,
    required this.freshDataCoverageRate,
  });

  double get completionRatePct => participationRate;
  double get avgScorePct => avgPercentage;

  factory SchoolClassSummary.fromJson(Map<String, dynamic> json) {
    final partRate =
        ((json['participation_rate'] ?? json['completion_rate_pct']) as num?)
                ?.toDouble() ??
            0.0;
    final avgPct = ((json['avg_percentage'] ?? json['avg_score_pct']) as num?)
            ?.toDouble() ??
        0.0;
    return SchoolClassSummary(
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String? ?? 'Class',
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'common',
      section: json['section'] as String? ?? '',
      enrolledStudents: json['enrolled_students'] as int? ?? 0,
      recentAttemptCount: (json['recent_attempt_count'] ??
              json['completed_assessments']) as int? ??
          0,
      participantCount:
          (json['participant_count'] ?? json['active_students']) as int? ?? 0,
      participationRate: partRate,
      avgPercentage: avgPct,
      medianPercentage: (json['median_percentage'] as num?)?.toDouble() ?? 0.0,
      activeMistakeCount: (json['active_mistake_count'] ??
              json['students_needing_help']) as int? ??
          0,
      assignedTeacherCount: (json['assigned_teacher_count'] ??
              json['assigned_teacher_count']) as int? ??
          0,
      freshDataCoverageRate:
          (json['fresh_data_coverage_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        classroomId,
        classroomName,
        grade,
        stream,
        section,
        enrolledStudents,
        recentAttemptCount,
        participantCount,
        participationRate,
        avgPercentage,
        medianPercentage,
        activeMistakeCount,
        assignedTeacherCount,
        freshDataCoverageRate,
      ];
}

/// Mistake-based systemic weak topic across the school.
class SchoolSystemicWeakTopic extends Equatable {
  final String topicId;
  final String topicNameEn;
  final String unitId;
  final String unitNameEn;
  final String subjectId;
  final String subjectName;
  final int affectedStudentCount;
  final int activeMistakeCount;

  const SchoolSystemicWeakTopic({
    required this.topicId,
    required this.topicNameEn,
    required this.unitId,
    required this.unitNameEn,
    required this.subjectId,
    required this.subjectName,
    required this.affectedStudentCount,
    required this.activeMistakeCount,
  });

  double get mistakeConcentrationPct =>
      activeMistakeCount > 0 ? activeMistakeCount.toDouble() : 0.0;

  factory SchoolSystemicWeakTopic.fromJson(Map<String, dynamic> json) {
    return SchoolSystemicWeakTopic(
      topicId: json['topic_id'] as String,
      topicNameEn: json['topic_name_en'] as String? ?? 'Topic',
      unitId: json['unit_id'] as String,
      unitNameEn: json['unit_name_en'] as String? ?? 'Unit',
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Subject',
      affectedStudentCount: json['affected_student_count'] as int? ?? 0,
      activeMistakeCount: json['active_mistake_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        topicId,
        topicNameEn,
        unitId,
        unitNameEn,
        subjectId,
        subjectName,
        affectedStudentCount,
        activeMistakeCount,
      ];
}

/// Student flagged for intervention in the school support population.
class SchoolSupportStudent extends Equatable {
  final String userId;
  final String displayName;
  final String? schoolStudentId;
  final String classroomName;
  final String stream;
  final double? recentAccuracyPercentage;
  final int activeMistakeCount;
  final int recentAttemptCount;
  final DateTime? lastActivityAt;
  final DateTime? lastSyncedAt;
  final String syncFreshness;
  final AttentionSeverity severity;
  final List<AttentionReasonCode> reasonCodes;
  final int totalCount;

  const SchoolSupportStudent({
    required this.userId,
    required this.displayName,
    this.schoolStudentId,
    required this.classroomName,
    required this.stream,
    this.recentAccuracyPercentage,
    required this.activeMistakeCount,
    required this.recentAttemptCount,
    this.lastActivityAt,
    this.lastSyncedAt,
    this.syncFreshness = 'unknown',
    required this.severity,
    required this.reasonCodes,
    required this.totalCount,
  });

  String get studentId => userId;
  bool get isHighSeverity => severity == AttentionSeverity.high;
  bool get isMediumSeverity => severity == AttentionSeverity.medium;
  bool get isLowSeverity => severity == AttentionSeverity.low;

  List<String> get reasonExplanations => reasonCodes.map((code) {
        return code.toExplanation(
          accuracy: recentAccuracyPercentage,
          mistakeCount: activeMistakeCount,
          lastActivity: lastActivityAt,
        );
      }).toList();

  factory SchoolSupportStudent.fromJson(Map<String, dynamic> json) {
    final rawReasons = (json['reason_codes'] as List<dynamic>?)
            ?.map((e) => AttentionReasonCode.fromString(e as String?))
            .toList() ??
        [];
    return SchoolSupportStudent(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Student',
      schoolStudentId: json['school_student_id'] as String?,
      classroomName: json['classroom_name'] as String? ?? 'Class',
      stream: json['stream'] as String? ?? 'common',
      recentAccuracyPercentage:
          (json['recent_accuracy_percentage'] as num?)?.toDouble(),
      activeMistakeCount: json['active_mistake_count'] as int? ?? 0,
      recentAttemptCount: json['recent_attempt_count'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      syncFreshness: json['sync_freshness'] as String? ?? 'unknown',
      severity: AttentionSeverity.fromString(json['severity'] as String?),
      reasonCodes: rawReasons,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        schoolStudentId,
        classroomName,
        stream,
        recentAccuracyPercentage,
        activeMistakeCount,
        recentAttemptCount,
        lastActivityAt,
        lastSyncedAt,
        syncFreshness,
        severity,
        reasonCodes,
        totalCount,
      ];
}

/// Recent school assessment overview with P5 provenance.
class SchoolAssessmentSummary extends Equatable {
  final String examId;
  final String examTitle;
  final String subjectId;
  final String subjectName;
  final String examType;
  final String examMode;
  final String sourceType;
  final int totalQuestions;
  final int participantCount;
  final int eligibleCount;
  final double participationPct;
  final double avgPercentage;
  final double medianPercentage;
  final DateTime? latestAttemptAt;

  const SchoolAssessmentSummary({
    required this.examId,
    required this.examTitle,
    required this.subjectId,
    required this.subjectName,
    required this.examType,
    this.examMode = 'practice',
    this.sourceType = 'generatedSimulation',
    required this.totalQuestions,
    required this.participantCount,
    required this.eligibleCount,
    required this.participationPct,
    required this.avgPercentage,
    required this.medianPercentage,
    this.latestAttemptAt,
  });

  /// Canonical P5 provenance label distinguishing all 5 categories.
  String get provenanceLabel => ExamProvenanceHelper.resolveProvenanceLabel(
        sourceType: sourceType,
        examMode: examMode,
        examType: examType,
      );

  String get provenance => sourceType;
  bool get isOfficialPastExam =>
      sourceType.toLowerCase().contains('official') ||
      examMode == 'historicalPaper';
  bool get isModelExam => sourceType.toLowerCase().contains('model');
  bool get isTeacherCustom =>
      examType == 'teacher_assigned' ||
      examMode == 'custom' ||
      sourceType.toLowerCase().contains('teacher');

  factory SchoolAssessmentSummary.fromJson(Map<String, dynamic> json) {
    final sType = (json['source_type'] ?? json['provenance']) as String? ??
        'generatedSimulation';
    return SchoolAssessmentSummary(
      examId: (json['exam_id'] ?? json['assessment_id']) as String? ?? '',
      examTitle:
          (json['exam_title'] ?? json['title']) as String? ?? 'Assessment',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? 'Subject',
      examType: json['exam_type'] as String? ?? 'practice',
      examMode: json['exam_mode'] as String? ?? 'practice',
      sourceType: sType,
      totalQuestions:
          (json['total_questions'] ?? json['submission_count']) as int? ?? 0,
      participantCount:
          (json['participant_count'] ?? json['submission_count']) as int? ?? 0,
      eligibleCount: json['eligible_count'] as int? ?? 0,
      participationPct: (json['participation_pct'] as num?)?.toDouble() ?? 0.0,
      avgPercentage: (json['avg_percentage'] as num?)?.toDouble() ?? 0.0,
      medianPercentage: (json['median_percentage'] as num?)?.toDouble() ?? 0.0,
      latestAttemptAt: json['latest_attempt_at'] != null
          ? DateTime.parse(json['latest_attempt_at'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null),
    );
  }

  @override
  List<Object?> get props => [
        examId,
        examTitle,
        subjectId,
        subjectName,
        examType,
        examMode,
        sourceType,
        totalQuestions,
        participantCount,
        eligibleCount,
        participationPct,
        avgPercentage,
        medianPercentage,
        latestAttemptAt,
      ];
}

/// Backward compatibility typedef for SchoolAssessmentOverview
typedef SchoolAssessmentOverview = SchoolAssessmentSummary;

/// Operational teacher assignment slot per classroom and subject.
class SchoolTeacherCoverageSlot extends Equatable {
  final String classroomId;
  final String classroomName;
  final int grade;
  final String stream;
  final String section;
  final String subjectId;
  final String subjectName;
  final String? examVariant;
  final String? teacherUserId;
  final String? teacherName;
  final bool isAssigned;

  const SchoolTeacherCoverageSlot({
    required this.classroomId,
    required this.classroomName,
    required this.grade,
    required this.stream,
    required this.section,
    required this.subjectId,
    required this.subjectName,
    this.examVariant,
    this.teacherUserId,
    this.teacherName,
    required this.isAssigned,
  });

  int get totalActiveAssignments => isAssigned ? 1 : 0;

  factory SchoolTeacherCoverageSlot.fromJson(Map<String, dynamic> json) {
    return SchoolTeacherCoverageSlot(
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String? ?? 'Class',
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'common',
      section: json['section'] as String? ?? '',
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Subject',
      examVariant: json['exam_variant'] as String?,
      teacherUserId: json['teacher_user_id'] as String?,
      teacherName: json['teacher_name'] as String?,
      isAssigned: json['is_assigned'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        classroomId,
        classroomName,
        grade,
        stream,
        section,
        subjectId,
        subjectName,
        examVariant,
        teacherUserId,
        teacherName,
        isAssigned,
      ];
}

/// Detailed student academic standing drill-down for leadership.
class SchoolStudentAcademicDetail extends Equatable {
  final String studentId;
  final String displayName;
  final String? schoolStudentId;
  final String classroomName;
  final int grade;
  final String stream;
  final int totalAttempts;
  final double? recentAvgPercentage;
  final double? overallAccuracyPct;
  final DateTime? lastActivityAt;
  final DateTime? lastSyncedAt;
  final String syncFreshness;
  final int totalMistakes;
  final int masteredMistakes;
  final List<ClassWeakTopic> weakTopics;
  final List<StudentExamResult> recentExams;
  final String masteryAvailabilityNote;

  const SchoolStudentAcademicDetail({
    required this.studentId,
    required this.displayName,
    this.schoolStudentId,
    required this.classroomName,
    required this.grade,
    required this.stream,
    required this.totalAttempts,
    this.recentAvgPercentage,
    this.overallAccuracyPct,
    this.lastActivityAt,
    this.lastSyncedAt,
    this.syncFreshness = 'unknown',
    required this.totalMistakes,
    required this.masteredMistakes,
    required this.weakTopics,
    required this.recentExams,
    required this.masteryAvailabilityNote,
  });

  int get activeMistakes => totalMistakes - masteredMistakes;
  List<StudentExamResult> get recentAssessments => recentExams;

  factory SchoolStudentAcademicDetail.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['weak_topics'] as List<dynamic>? ?? [];
    final rawExams = json['recent_exams'] as List<dynamic>? ?? [];

    return SchoolStudentAcademicDetail(
      studentId: json['student_id'] as String,
      displayName: json['display_name'] as String? ?? 'Student',
      schoolStudentId: json['school_student_id'] as String?,
      classroomName: json['classroom_name'] as String? ?? 'Class',
      grade: json['grade'] as int? ?? 12,
      stream: json['stream'] as String? ?? 'common',
      totalAttempts: json['total_attempts'] as int? ?? 0,
      recentAvgPercentage: (json['recent_avg_percentage'] as num?)?.toDouble(),
      overallAccuracyPct: (json['overall_accuracy_pct'] as num?)?.toDouble(),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      syncFreshness: json['sync_freshness'] as String? ?? 'unknown',
      totalMistakes: json['total_mistakes'] as int? ?? 0,
      masteredMistakes: json['mastered_mistakes'] as int? ?? 0,
      weakTopics: rawTopics
          .map((e) => ClassWeakTopic.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentExams: rawExams
          .map((e) => StudentExamResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      masteryAvailabilityNote: json['mastery_availability_note'] as String? ??
          'Mastery data is device-local.',
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        displayName,
        schoolStudentId,
        classroomName,
        grade,
        stream,
        totalAttempts,
        recentAvgPercentage,
        overallAccuracyPct,
        lastActivityAt,
        lastSyncedAt,
        syncFreshness,
        totalMistakes,
        masteredMistakes,
        weakTopics,
        recentExams,
        masteryAvailabilityNote,
      ];
}

import 'package:equatable/equatable.dart';

import '../../../exams/domain/models/exam_mode.dart';
import '../../../school/domain/models/tenant_models.dart';

// =============================================================================
// Attention Severity & Reason
// =============================================================================

/// Three-level severity scale for teacher intervention priority.
/// Thresholds are centralized in the PostgreSQL RPC and mirrored here.
///
/// HIGH:   recent_avg < 50%  OR  active_mistakes >= 5
/// MEDIUM: recent_avg < 70%  OR  active_mistakes >= 3  OR  no activity 14d
/// LOW:    active_mistakes >= 1  OR  no activity 7d
enum AttentionSeverity {
  high,
  medium,
  low;

  static AttentionSeverity fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'high':
        return AttentionSeverity.high;
      case 'medium':
        return AttentionSeverity.medium;
      default:
        return AttentionSeverity.low;
    }
  }

  /// Teacher-facing neutral label (avoids "worst"/"bottom" language).
  String get displayLabel {
    switch (this) {
      case AttentionSeverity.high:
        return 'Needs Immediate Support';
      case AttentionSeverity.medium:
        return 'Needs Attention';
      case AttentionSeverity.low:
        return 'Monitor';
    }
  }
}

/// Machine-readable reason codes (server-generated).
/// Client uses these to build human-readable descriptions.
enum AttentionReasonCode {
  lowRecentAccuracy,
  highMistakeCount,
  elevatedMistakeCount,
  activeMistakesPresent,
  noRecentActivity,
  overduePractice,
  noPracticeData,
  borderlineAccuracy,
  unknown;

  static AttentionReasonCode fromString(String? val) {
    switch (val) {
      case 'low_recent_accuracy':
        return AttentionReasonCode.lowRecentAccuracy;
      case 'high_mistake_count':
        return AttentionReasonCode.highMistakeCount;
      case 'elevated_mistake_count':
        return AttentionReasonCode.elevatedMistakeCount;
      case 'active_mistakes_present':
        return AttentionReasonCode.activeMistakesPresent;
      case 'no_recent_activity':
        return AttentionReasonCode.noRecentActivity;
      case 'overdue_practice':
        return AttentionReasonCode.overduePractice;
      case 'no_practice_data':
        return AttentionReasonCode.noPracticeData;
      case 'borderline_accuracy':
        return AttentionReasonCode.borderlineAccuracy;
      default:
        return AttentionReasonCode.unknown;
    }
  }

  /// Returns a human-readable explanation suitable for teacher display.
  String toExplanation({
    double? accuracy,
    int? mistakeCount,
    DateTime? lastActivity,
  }) {
    switch (this) {
      case AttentionReasonCode.lowRecentAccuracy:
        final pct =
            accuracy != null ? '${accuracy.toStringAsFixed(0)}%' : 'low';
        return '$pct average accuracy on recent practice (last 30 days).';
      case AttentionReasonCode.highMistakeCount:
        final mc = mistakeCount ?? 0;
        return '$mc active unmastered mistakes recorded.';
      case AttentionReasonCode.elevatedMistakeCount:
        final mc = mistakeCount ?? 0;
        return '$mc active mistakes. Review of these topics is overdue.';
      case AttentionReasonCode.activeMistakesPresent:
        final mc = mistakeCount ?? 0;
        return '$mc active mistakes recorded on assigned topics.';
      case AttentionReasonCode.noRecentActivity:
        final days = lastActivity == null
            ? 'several'
            : DateTime.now().difference(lastActivity).inDays.toString();
        return 'No practice activity in the last $days days.';
      case AttentionReasonCode.overduePractice:
        return 'Practice is overdue — student has been inactive for over a week.';
      case AttentionReasonCode.noPracticeData:
        return 'No practice attempts recorded yet.';
      case AttentionReasonCode.borderlineAccuracy:
        return 'Accuracy is borderline — additional practice may improve retention.';
      case AttentionReasonCode.unknown:
        return 'Academic performance indicator flagged for review.';
    }
  }
}

// =============================================================================
// Teacher Assigned Class
// =============================================================================

/// A classroom + subject combination assigned to the authenticated teacher.
/// This is the primary unit of teacher authority in P7.
class TeacherAssignedClass extends Equatable {
  final String assignmentId;
  final Classroom classroom;
  final String subjectId;
  final String subjectName;
  final String? examVariant;
  final int enrolledStudentCount;
  // Lightweight cloud-available metrics (may be null if no data yet)
  final int? attentionCount;
  final double? recentExamAvgPercentage;
  final int? activeMistakeCount;

  const TeacherAssignedClass({
    required this.assignmentId,
    required this.classroom,
    required this.subjectId,
    required this.subjectName,
    this.examVariant,
    required this.enrolledStudentCount,
    this.attentionCount,
    this.recentExamAvgPercentage,
    this.activeMistakeCount,
  });

  /// Subject+stream display string for teacher-facing labels.
  String get subjectDisplayLabel {
    if (examVariant == null) return subjectName;
    final variantLabel = examVariant == 'naturalScience'
        ? 'Natural Science'
        : examVariant == 'socialScience'
            ? 'Social Science'
            : examVariant!;
    return '$subjectName — $variantLabel';
  }

  @override
  List<Object?> get props => [
        assignmentId,
        classroom,
        subjectId,
        subjectName,
        examVariant,
        enrolledStudentCount,
        attentionCount,
        recentExamAvgPercentage,
        activeMistakeCount,
      ];
}

// =============================================================================
// Teacher Dashboard Summary
// =============================================================================

/// Aggregate top-level summary for the teacher home screen.
class TeacherDashboardSummary extends Equatable {
  final String schoolId;
  final String schoolName;
  final List<TeacherAssignedClass> assignedClasses;
  final int totalStudents;
  final int totalAttentionCount;
  final bool isOfflineCached;
  final DateTime loadedAt;

  const TeacherDashboardSummary({
    required this.schoolId,
    required this.schoolName,
    required this.assignedClasses,
    required this.totalStudents,
    required this.totalAttentionCount,
    required this.isOfflineCached,
    required this.loadedAt,
  });

  bool get hasClasses => assignedClasses.isNotEmpty;

  @override
  List<Object?> get props => [
        schoolId,
        schoolName,
        assignedClasses,
        totalStudents,
        totalAttentionCount,
        isOfflineCached,
        loadedAt,
      ];
}

// =============================================================================
// Class Roster
// =============================================================================

/// One student in the teacher's authorized class roster.
/// Exposes only academically relevant information.
class ClassRosterStudent extends Equatable {
  final String userId;
  final String displayName;
  final String? schoolStudentId;
  final int recentAttemptCount;
  final double? recentAvgPercentage;
  final int activeMistakeCount;
  final DateTime? lastActivityAt;

  const ClassRosterStudent({
    required this.userId,
    required this.displayName,
    this.schoolStudentId,
    required this.recentAttemptCount,
    this.recentAvgPercentage,
    required this.activeMistakeCount,
    this.lastActivityAt,
  });

  bool get hasAttention =>
      activeMistakeCount >= 3 ||
      (recentAvgPercentage != null && recentAvgPercentage! < 70);

  @override
  List<Object?> get props => [
        userId,
        displayName,
        schoolStudentId,
        recentAttemptCount,
        recentAvgPercentage,
        activeMistakeCount,
        lastActivityAt,
      ];
}

/// Paginated roster result.
class ClassRosterPage extends Equatable {
  final List<ClassRosterStudent> students;
  final int totalCount;
  final int currentOffset;
  final int pageSize;

  const ClassRosterPage({
    required this.students,
    required this.totalCount,
    required this.currentOffset,
    required this.pageSize,
  });

  bool get hasMore => currentOffset + pageSize < totalCount;
  bool get isEmpty => students.isEmpty;

  @override
  List<Object?> get props => [students, totalCount, currentOffset, pageSize];
}

// =============================================================================
// Class Exam Summary
// =============================================================================

/// Aggregate exam performance summary for the teacher's class.
/// P5 exam_type provenance is preserved unchanged.
class ClassExamSummary extends Equatable {
  final String examId;
  final String examTitle;

  /// Raw P5 exam_type string: 'practice', 'unit_test', 'mock_full',
  /// 'custom_builder', 'teacher_assigned'. Preserved as-is for teacher display.
  final String examType;
  final String examMode;
  final String sourceType;
  final int totalQuestions;
  final int participantCount;
  final int enrolledCount;
  final double avgPercentage;
  final double medianPercentage;
  final int notSubmitted;
  final DateTime examCreatedAt;

  const ClassExamSummary({
    required this.examId,
    required this.examTitle,
    required this.examType,
    this.examMode = 'practice',
    this.sourceType = 'generatedSimulation',
    required this.totalQuestions,
    required this.participantCount,
    required this.enrolledCount,
    required this.avgPercentage,
    required this.medianPercentage,
    required this.notSubmitted,
    required this.examCreatedAt,
  });

  double get participationRate =>
      enrolledCount > 0 ? participantCount / enrolledCount : 0.0;

  /// Human-readable provenance label mapping canonical P5 source categories & exam modes.
  String get provenanceLabel => ExamProvenanceHelper.resolveProvenanceLabel(
        sourceType: sourceType,
        examMode: examMode,
        examType: examType,
      );

  factory ClassExamSummary.fromJson(Map<String, dynamic> json) {
    return ClassExamSummary(
      examId: json['exam_id'] as String,
      examTitle: json['exam_title'] as String,
      examType: json['exam_type'] as String? ?? 'practice',
      examMode: json['exam_mode'] as String? ?? 'practice',
      sourceType: json['source_type'] as String? ?? 'generatedSimulation',
      totalQuestions: json['total_questions'] as int? ?? 0,
      participantCount: json['participant_count'] as int? ?? 0,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      avgPercentage: (json['avg_percentage'] as num?)?.toDouble() ?? 0.0,
      medianPercentage: (json['median_percentage'] as num?)?.toDouble() ?? 0.0,
      notSubmitted: json['not_submitted'] as int? ?? 0,
      examCreatedAt: json['exam_created_at'] != null
          ? DateTime.parse(json['exam_created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        examId,
        examTitle,
        examType,
        examMode,
        sourceType,
        totalQuestions,
        participantCount,
        enrolledCount,
        avgPercentage,
        medianPercentage,
        notSubmitted,
        examCreatedAt,
      ];
}

// =============================================================================
// Class Weak Topic
// =============================================================================

/// Topic where students in the class have active unmastered mistakes.
/// Derived from cloud-synced mistake_records. NOT from local P4 mastery.
/// Distinction: coverage ≠ mastery. affectedStudentCount is the key signal.
class ClassWeakTopic extends Equatable {
  final String topicId;
  final String topicName;
  final String? unitId;
  final String? unitName;
  final int affectedStudentCount;
  final int activeMistakeCount;

  const ClassWeakTopic({
    required this.topicId,
    required this.topicName,
    this.unitId,
    this.unitName,
    required this.affectedStudentCount,
    required this.activeMistakeCount,
  });

  bool get isWeakArea => affectedStudentCount >= 2;

  factory ClassWeakTopic.fromJson(Map<String, dynamic> json) {
    return ClassWeakTopic(
      topicId: json['topic_id'] as String,
      topicName: json['topic_name_en'] as String? ??
          json['topic_name'] as String? ??
          'Unknown Topic',
      unitId: json['unit_id'] as String?,
      unitName: json['unit_name_en'] as String? ?? json['unit_name'] as String?,
      affectedStudentCount: json['affected_student_count'] as int? ?? 0,
      activeMistakeCount: json['active_mistake_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        topicId,
        topicName,
        unitId,
        unitName,
        affectedStudentCount,
        activeMistakeCount,
      ];
}

// =============================================================================
// Class Summary
// =============================================================================

/// Full class-level summary for the Class Detail screen.
class ClassSummary extends Equatable {
  final Classroom classroom;
  final String subjectId;
  final String subjectName;
  final String? examVariant;
  final int enrolledStudentCount;
  final int attentionCount;
  final List<ClassWeakTopic> weakTopics;
  final List<ClassExamSummary> recentExams;
  // Mastery gap disclosure
  final String masteryAvailabilityNote;
  final DateTime loadedAt;

  const ClassSummary({
    required this.classroom,
    required this.subjectId,
    required this.subjectName,
    this.examVariant,
    required this.enrolledStudentCount,
    required this.attentionCount,
    required this.weakTopics,
    required this.recentExams,
    this.masteryAvailabilityNote =
        'Mastery distribution is device-local and not yet cloud-queryable. '
            'It will appear here once cloud sync is implemented.',
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [
        classroom,
        subjectId,
        subjectName,
        examVariant,
        enrolledStudentCount,
        attentionCount,
        weakTopics,
        recentExams,
        masteryAvailabilityNote,
        loadedAt,
      ];
}

// =============================================================================
// Student Attention Item
// =============================================================================

/// A single student flagged for teacher intervention.
/// Every item explains WHY the student is flagged (no opaque scores).
class StudentAttentionItem extends Equatable {
  final String studentId;
  final String studentName;
  final String? schoolStudentId;
  final String subjectId;
  final AttentionSeverity severity;
  final List<AttentionReasonCode> reasonCodes;
  final double? recentAccuracyPercentage;
  final int activeMistakeCount;
  final int recentAttemptCount;
  final DateTime? lastActivityAt;
  final DateTime? lastSyncedAt;
  final String syncFreshness;

  const StudentAttentionItem({
    required this.studentId,
    required this.studentName,
    this.schoolStudentId,
    required this.subjectId,
    required this.severity,
    required this.reasonCodes,
    this.recentAccuracyPercentage,
    required this.activeMistakeCount,
    required this.recentAttemptCount,
    this.lastActivityAt,
    this.lastSyncedAt,
    this.syncFreshness = 'unknown',
  });

  /// Human-readable explanation for each reason code.
  List<String> get reasonExplanations => reasonCodes.map((code) {
        return code.toExplanation(
          accuracy: recentAccuracyPercentage,
          mistakeCount: activeMistakeCount,
          lastActivity: lastActivityAt,
        );
      }).toList();

  /// Simple recommended action derived from available evidence.
  String get recommendedAction {
    if (activeMistakeCount >= 5) {
      return 'Review mistake notebook — multiple topics need attention.';
    }
    if (recentAccuracyPercentage != null && recentAccuracyPercentage! < 50) {
      return 'Assign focused 15-question practice on weak topics.';
    }
    if (recentAttemptCount == 0) {
      return 'Check in with student — no recent practice recorded.';
    }
    if (activeMistakeCount >= 3) {
      return 'Revisit practice on flagged topics before next assessment.';
    }
    return 'Monitor progress over next 7 days.';
  }

  factory StudentAttentionItem.fromJson(
      Map<String, dynamic> json, String subjectId) {
    final rawReasons = (json['reason_codes'] as List<dynamic>?)
            ?.map((e) => AttentionReasonCode.fromString(e as String?))
            .toList() ??
        [];
    return StudentAttentionItem(
      studentId: json['user_id'] as String,
      studentName: json['display_name'] as String,
      schoolStudentId: json['school_student_id'] as String?,
      subjectId: subjectId,
      severity: AttentionSeverity.fromString(json['severity'] as String?),
      reasonCodes: rawReasons,
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
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        schoolStudentId,
        subjectId,
        severity,
        reasonCodes,
        recentAccuracyPercentage,
        activeMistakeCount,
        recentAttemptCount,
        lastActivityAt,
        lastSyncedAt,
        syncFreshness,
      ];
}

// =============================================================================
// Student Academic Summary (Teacher View)
// =============================================================================

/// One student's recent exam result in the teacher's view.
class StudentExamResult extends Equatable {
  final String examId;
  final String examTitle;
  final String examType;
  final String examMode;
  final String sourceType;
  final int totalQuestions;
  final double percentage;
  final DateTime? completedAt;

  const StudentExamResult({
    required this.examId,
    required this.examTitle,
    required this.examType,
    this.examMode = 'practice',
    this.sourceType = 'generatedSimulation',
    required this.totalQuestions,
    required this.percentage,
    this.completedAt,
  });

  String get provenanceLabel => ExamProvenanceHelper.resolveProvenanceLabel(
        sourceType: sourceType,
        examMode: examMode,
        examType: examType,
      );

  factory StudentExamResult.fromJson(Map<String, dynamic> json) {
    return StudentExamResult(
      examId: json['exam_id'] as String,
      examTitle: json['exam_title'] as String? ?? 'Exam',
      examType: json['exam_type'] as String? ?? 'practice',
      examMode: json['exam_mode'] as String? ?? 'practice',
      sourceType: json['source_type'] as String? ?? 'generatedSimulation',
      totalQuestions: json['total_questions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        examId,
        examTitle,
        examType,
        examMode,
        sourceType,
        totalQuestions,
        percentage,
        completedAt,
      ];
}

/// Teacher-facing student academic summary.
/// Exposes only education-relevant data.
/// Coin ledger, private settings, and auth metadata are NEVER included.
class StudentAcademicSummary extends Equatable {
  final String studentId;
  final String displayName;
  final String? schoolStudentId;
  final String subjectId;
  final String subjectName;
  // Attempt-derived (cloud-synced)
  final int totalAttempts;
  final double? recentAvgPercentage; // last 30 days
  final double? overallAccuracyPercentage;
  final DateTime? lastActivityAt;
  final DateTime? lastSyncedAt;
  final String syncFreshness;
  // Mistake-derived (cloud-synced)
  final int totalMistakes;
  final int masteredMistakes;
  final List<ClassWeakTopic> weakTopics;
  // Recent exams
  final List<StudentExamResult> recentExams;
  // Mastery availability
  final String masteryAvailabilityNote;

  const StudentAcademicSummary({
    required this.studentId,
    required this.displayName,
    this.schoolStudentId,
    required this.subjectId,
    required this.subjectName,
    required this.totalAttempts,
    this.recentAvgPercentage,
    this.overallAccuracyPercentage,
    this.lastActivityAt,
    this.lastSyncedAt,
    this.syncFreshness = 'unknown',
    required this.totalMistakes,
    required this.masteredMistakes,
    required this.weakTopics,
    required this.recentExams,
    this.masteryAvailabilityNote =
        'Mastery data is device-local. It will appear here once cloud sync '
            'is implemented.',
  });

  int get activeMistakes => totalMistakes - masteredMistakes;

  /// Recommended action based on available cloud evidence.
  String get recommendedAction {
    if (activeMistakes >= 5) {
      return 'Student has $activeMistakes active unmastered mistakes — '
          'review mistake notebook together.';
    }
    if (recentAvgPercentage != null && recentAvgPercentage! < 50) {
      return 'Assign 15-question targeted practice on weakest topics.';
    }
    if (lastActivityAt == null ||
        DateTime.now().difference(lastActivityAt!).inDays > 14) {
      return 'No recent activity — check in with student to resume practice.';
    }
    if (activeMistakes >= 3) {
      return 'Schedule a review session focused on flagged topics.';
    }
    return 'Student is progressing. Monitor for the next 7 days.';
  }

  factory StudentAcademicSummary.fromJson(
      Map<String, dynamic> json, String subjectName) {
    final rawExams = json['recent_exams'] as List<dynamic>? ?? [];
    final rawTopics = json['weak_topics'] as List<dynamic>? ?? [];
    return StudentAcademicSummary(
      studentId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      schoolStudentId: json['school_student_id'] as String?,
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: subjectName,
      totalAttempts: json['total_attempts'] as int? ?? 0,
      recentAvgPercentage: (json['recent_avg_percentage'] as num?)?.toDouble(),
      overallAccuracyPercentage:
          (json['overall_accuracy_percentage'] as num?)?.toDouble(),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      syncFreshness: json['sync_freshness'] as String? ?? 'unknown',
      totalMistakes: json['total_mistakes'] as int? ?? 0,
      masteredMistakes: json['mastered_mistakes'] as int? ?? 0,
      recentExams: rawExams
          .map((e) => StudentExamResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      weakTopics: rawTopics.map((e) {
        final m = e as Map<String, dynamic>;
        return ClassWeakTopic(
          topicId: m['topic_id'] as String,
          topicName: m['topic_name'] as String? ?? 'Unknown',
          unitName: m['unit_name'] as String?,
          affectedStudentCount: 1,
          activeMistakeCount: m['mistake_count'] as int? ?? 0,
        );
      }).toList(),
      masteryAvailabilityNote: json['mastery_availability_note'] as String? ??
          'Mastery data is device-local.',
    );
  }

  @override
  List<Object?> get props => [
        studentId,
        displayName,
        schoolStudentId,
        subjectId,
        subjectName,
        totalAttempts,
        recentAvgPercentage,
        overallAccuracyPercentage,
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

// =============================================================================
// Paginated Attention Result
// =============================================================================

class AttentionPage extends Equatable {
  final List<StudentAttentionItem> items;
  final int totalCount;
  final int currentOffset;
  final int pageSize;

  const AttentionPage({
    required this.items,
    required this.totalCount,
    required this.currentOffset,
    required this.pageSize,
  });

  bool get hasMore => currentOffset + pageSize < totalCount;
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, totalCount, currentOffset, pageSize];
}

import 'package:equatable/equatable.dart';

import 'deadline_integrity_models.dart';

export 'deadline_integrity_models.dart';

/// Taxonomy of assignments supported in FidelLearn P9.
enum AssignmentType {
  targetedPractice,
  customQuestionSet,
  simulation;

  static AssignmentType fromString(String? val) {
    if (val == null) return AssignmentType.targetedPractice;
    switch (val) {
      case 'customQuestionSet':
      case 'custom_question_set':
        return AssignmentType.customQuestionSet;
      case 'simulation':
        return AssignmentType.simulation;
      case 'targetedPractice':
      case 'targeted_practice':
      default:
        return AssignmentType.targetedPractice;
    }
  }

  String get dbValue {
    switch (this) {
      case AssignmentType.targetedPractice:
        return 'targetedPractice';
      case AssignmentType.customQuestionSet:
        return 'customQuestionSet';
      case AssignmentType.simulation:
        return 'simulation';
    }
  }

  String get displayLabel => labelEn;

  String get labelEn {
    switch (this) {
      case AssignmentType.targetedPractice:
        return 'Targeted Practice';
      case AssignmentType.customQuestionSet:
        return 'Selected Question Set';
      case AssignmentType.simulation:
        return 'ESSLCE Exam Simulation';
    }
  }

  String get labelAm {
    switch (this) {
      case AssignmentType.targetedPractice:
        return 'የተመረጠ የተግባር ልምምድ';
      case AssignmentType.customQuestionSet:
        return 'የተመረጡ የጥያቄዎች ስብስብ';
      case AssignmentType.simulation:
        return 'የብሔራዊ ፈተና አስመስሎ';
    }
  }
}

/// Lifecycle status for teacher assignments.
enum AssignmentStatus {
  draft,
  published,
  closed,
  archived;

  static AssignmentStatus fromString(String? val) {
    if (val == null) return AssignmentStatus.draft;
    switch (val.toLowerCase()) {
      case 'published':
        return AssignmentStatus.published;
      case 'closed':
        return AssignmentStatus.closed;
      case 'archived':
        return AssignmentStatus.archived;
      case 'draft':
      default:
        return AssignmentStatus.draft;
    }
  }

  String get dbValue => name;
  String get displayLabel => labelEn;

  String get labelEn {
    switch (this) {
      case AssignmentStatus.draft:
        return 'Draft';
      case AssignmentStatus.published:
        return 'Active';
      case AssignmentStatus.closed:
        return 'Closed';
      case AssignmentStatus.archived:
        return 'Archived';
    }
  }

  String get labelAm {
    switch (this) {
      case AssignmentStatus.draft:
        return 'ረቂቅ';
      case AssignmentStatus.published:
        return 'ንቁ';
      case AssignmentStatus.closed:
        return 'የተዘጋ';
      case AssignmentStatus.archived:
        return 'የተመዘገበ';
    }
  }
}

/// Recipient status for individual students.
enum AssignmentRecipientStatus {
  assigned,
  inProgress,
  submitted,
  completed,
  late,
  excused;

  static AssignmentRecipientStatus fromString(String? val) {
    if (val == null) return AssignmentRecipientStatus.assigned;
    switch (val) {
      case 'inProgress':
      case 'in_progress':
        return AssignmentRecipientStatus.inProgress;
      case 'submitted':
        return AssignmentRecipientStatus.submitted;
      case 'completed':
        return AssignmentRecipientStatus.completed;
      case 'late':
        return AssignmentRecipientStatus.late;
      case 'excused':
        return AssignmentRecipientStatus.excused;
      case 'assigned':
      default:
        return AssignmentRecipientStatus.assigned;
    }
  }

  String get dbValue {
    switch (this) {
      case AssignmentRecipientStatus.inProgress:
        return 'inProgress';
      default:
        return name;
    }
  }

  String get labelEn {
    switch (this) {
      case AssignmentRecipientStatus.assigned:
        return 'Not Started';
      case AssignmentRecipientStatus.inProgress:
        return 'In Progress';
      case AssignmentRecipientStatus.submitted:
        return 'Submitted';
      case AssignmentRecipientStatus.completed:
        return 'Completed';
      case AssignmentRecipientStatus.late:
        return 'Late Submission';
      case AssignmentRecipientStatus.excused:
        return 'Excused';
    }
  }

  String get labelAm {
    switch (this) {
      case AssignmentRecipientStatus.assigned:
        return 'አልተጀመረም';
      case AssignmentRecipientStatus.inProgress:
        return 'በሂደት ላይ';
      case AssignmentRecipientStatus.submitted:
        return 'የተላከ';
      case AssignmentRecipientStatus.completed:
        return 'የተጠናቀቀ';
      case AssignmentRecipientStatus.late:
        return 'ዘግይቶ የቀረበ';
      case AssignmentRecipientStatus.excused:
        return 'ይቅርታ የተደረገለት';
    }
  }
}

/// A teacher learning assignment entity.
class LearningAssignment extends Equatable {
  final String id;
  final String schoolId;
  final String classroomId;
  final String? classroomName;
  final String teacherUserId;
  final String subjectId;
  final String? examVariant;
  final String title;
  final String? instructions;
  final AssignmentType assignmentType;
  final AssignmentStatus status;
  final DateTime? dueAt;
  final bool allowLateSubmission;
  final int timeLimitMinutes;
  final int totalQuestions;
  final String? contentHash;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  final int recipientCount;
  final int submittedCount;
  final double avgScorePercentage;

  const LearningAssignment({
    required this.id,
    required this.schoolId,
    required this.classroomId,
    this.classroomName,
    required this.teacherUserId,
    required this.subjectId,
    this.examVariant,
    required this.title,
    this.instructions,
    required this.assignmentType,
    required this.status,
    this.dueAt,
    this.allowLateSubmission = true,
    this.timeLimitMinutes = 0,
    required this.totalQuestions,
    this.contentHash,
    required this.createdAt,
    this.publishedAt,
    this.closedAt,
    this.recipientCount = 0,
    this.submittedCount = 0,
    this.avgScorePercentage = 0.0,
  });

  bool get isTimed => timeLimitMinutes > 0;
  bool get isDraft => status == AssignmentStatus.draft;
  bool get isPublished => status == AssignmentStatus.published;
  bool get isClosed => status == AssignmentStatus.closed;

  double get completionRate => recipientCount > 0
      ? (submittedCount / recipientCount).clamp(0.0, 1.0)
      : 0.0;

  bool get isOverdue {
    if (dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  bool get isMathNatural =>
      subjectId == 'math_g12' &&
      (examVariant == 'naturalScience' || examVariant == 'math_natural');

  bool get isMathSocial =>
      subjectId == 'math_g12' &&
      (examVariant == 'socialScience' || examVariant == 'math_social');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'classroom_id': classroomId,
      'classroom_name': classroomName,
      'teacher_user_id': teacherUserId,
      'subject_id': subjectId,
      'exam_variant': examVariant,
      'title': title,
      'instructions': instructions,
      'assignment_type': assignmentType.dbValue,
      'status': status.dbValue,
      'due_at': dueAt?.toIso8601String(),
      'allow_late_submission': allowLateSubmission,
      'time_limit_minutes': timeLimitMinutes,
      'total_questions': totalQuestions,
      'content_hash': contentHash,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'recipient_count': recipientCount,
      'submitted_count': submittedCount,
      'avg_score_percentage': avgScorePercentage,
    };
  }

  factory LearningAssignment.fromJson(Map<String, dynamic> json) {
    return LearningAssignment(
      id: json['assignment_id'] as String? ?? json['id'] as String,
      schoolId: json['school_id'] as String,
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String?,
      teacherUserId: json['teacher_user_id'] as String? ?? '',
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] as String?,
      title: json['title'] as String,
      instructions: json['instructions'] as String?,
      assignmentType: AssignmentType.fromString(
        json['assignment_type'] as String? ?? 'targetedPractice',
      ),
      status: AssignmentStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
      dueAt: json['due_at'] != null
          ? DateTime.parse(json['due_at'] as String)
          : null,
      allowLateSubmission: json['allow_late_submission'] as bool? ?? true,
      timeLimitMinutes: json['time_limit_minutes'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      contentHash: json['content_hash'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      recipientCount: (json['recipient_count'] as num?)?.toInt() ?? 0,
      submittedCount: (json['submitted_count'] as num?)?.toInt() ?? 0,
      avgScorePercentage:
          (json['avg_score_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        classroomId,
        classroomName,
        teacherUserId,
        subjectId,
        examVariant,
        title,
        instructions,
        assignmentType,
        status,
        dueAt,
        allowLateSubmission,
        timeLimitMinutes,
        totalQuestions,
        contentHash,
        createdAt,
        publishedAt,
        closedAt,
        recipientCount,
        submittedCount,
        avgScorePercentage,
      ];
}

/// Represents one student recipient of an assignment.
class AssignmentRecipient extends Equatable {
  final String id;
  final String assignmentId;
  final String studentUserId;
  final String? studentName;
  final String? schoolStudentId;
  final DateTime assignedAt;
  final AssignmentRecipientStatus status;
  final DeadlineIntegrityLevel deadlineIntegrity;
  final String? attemptId;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final int? score;
  final double? percentage;

  const AssignmentRecipient({
    required this.id,
    required this.assignmentId,
    required this.studentUserId,
    this.studentName,
    this.schoolStudentId,
    required this.assignedAt,
    required this.status,
    this.deadlineIntegrity = DeadlineIntegrityLevel.verified,
    this.attemptId,
    this.startedAt,
    this.submittedAt,
    this.score,
    this.percentage,
  });

  bool get isSubmitted =>
      status == AssignmentRecipientStatus.submitted ||
      status == AssignmentRecipientStatus.completed ||
      status == AssignmentRecipientStatus.late;

  bool get isCompleted => isSubmitted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'student_user_id': studentUserId,
      'student_name': studentName,
      'school_student_id': schoolStudentId,
      'assigned_at': assignedAt.toIso8601String(),
      'status': status.dbValue,
      'deadline_integrity': deadlineIntegrity.dbValue,
      'attempt_id': attemptId,
      'started_at': startedAt?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'score': score,
      'percentage': percentage,
    };
  }

  factory AssignmentRecipient.fromJson(Map<String, dynamic> json) {
    return AssignmentRecipient(
      id: json['recipient_id'] as String? ?? json['id'] as String,
      assignmentId: json['assignment_id'] as String? ?? '',
      studentUserId: json['student_user_id'] as String,
      studentName: json['student_name'] as String?,
      schoolStudentId: json['school_student_id'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : DateTime.now(),
      status: AssignmentRecipientStatus.fromString(
        json['status'] as String? ?? 'assigned',
      ),
      deadlineIntegrity: DeadlineIntegrityLevel.fromString(
        json['deadline_integrity'] as String?,
      ),
      attemptId: json['attempt_id'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      score: (json['score'] as num?)?.toInt(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        assignmentId,
        studentUserId,
        studentName,
        schoolStudentId,
        assignedAt,
        status,
        deadlineIntegrity,
        attemptId,
        startedAt,
        submittedAt,
        score,
        percentage,
      ];
}

/// Aggregate progress summary for a teacher viewing an assignment.
class AssignmentProgressSummary extends Equatable {
  final LearningAssignment assignment;
  final List<AssignmentRecipient> recipients;
  final int totalAssigned;
  final int notStartedCount;
  final int inProgressCount;
  final int submittedCount;
  final int lateCount;
  final int excusedCount;
  final DateTime lastSyncedAt;

  const AssignmentProgressSummary({
    required this.assignment,
    required this.recipients,
    required this.totalAssigned,
    required this.notStartedCount,
    required this.inProgressCount,
    required this.submittedCount,
    required this.lateCount,
    required this.excusedCount,
    required this.lastSyncedAt,
  });

  double get completionPercentage => totalAssigned > 0
      ? ((submittedCount + lateCount) / totalAssigned) * 100
      : 0.0;

  double get completionRate => completionPercentage;
  int get pendingCount => notStartedCount + inProgressCount;
  int get overdueCount =>
      (totalAssigned - (submittedCount + lateCount + excusedCount))
          .clamp(0, totalAssigned);

  @override
  List<Object?> get props => [
        assignment,
        recipients,
        totalAssigned,
        notStartedCount,
        inProgressCount,
        submittedCount,
        lateCount,
        excusedCount,
        lastSyncedAt,
      ];
}

/// Student-facing assignment card model for Assignment Inbox.
class StudentAssignment extends Equatable {
  final String assignmentId;
  final String recipientId;
  final String schoolId;
  final String classroomId;
  final String classroomName;
  final String teacherName;
  final String subjectId;
  final String? examVariant;
  final String title;
  final String? instructions;
  final AssignmentType assignmentType;
  final AssignmentStatus assignmentStatus;
  final AssignmentRecipientStatus studentStatus;
  final DateTime? dueAt;
  final bool allowLateSubmission;
  final int timeLimitMinutes;
  final int totalQuestions;
  final String? attemptId;
  final int? score;
  final double? percentage;
  final DateTime? submittedAt;
  final bool isOfflineReady;
  final DeadlineIntegrityLevel deadlineIntegrity;

  const StudentAssignment({
    required this.assignmentId,
    required this.recipientId,
    required this.schoolId,
    required this.classroomId,
    required this.classroomName,
    required this.teacherName,
    required this.subjectId,
    this.examVariant,
    required this.title,
    this.instructions,
    required this.assignmentType,
    required this.assignmentStatus,
    required this.studentStatus,
    this.dueAt,
    this.allowLateSubmission = true,
    this.timeLimitMinutes = 0,
    required this.totalQuestions,
    this.attemptId,
    this.score,
    this.percentage,
    this.submittedAt,
    this.isOfflineReady = false,
    this.deadlineIntegrity = DeadlineIntegrityLevel.verified,
  });

  bool get isTimed => timeLimitMinutes > 0;
  bool get isCompleted =>
      studentStatus == AssignmentRecipientStatus.submitted ||
      studentStatus == AssignmentRecipientStatus.completed ||
      studentStatus == AssignmentRecipientStatus.late;

  bool get isOverdue {
    if (isCompleted || dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  bool get canStartOrResume =>
      !isCompleted && (!isOverdue || allowLateSubmission);

  bool get isPastDueWithGrace => isOverdue && allowLateSubmission;

  bool get isLockedDueToDeadline => isOverdue && !allowLateSubmission;
  bool get isLockedDueToPastGrace => isLockedDueToDeadline;

  StudentAssignment copyWith({
    bool? isOfflineReady,
    AssignmentRecipientStatus? studentStatus,
    DeadlineIntegrityLevel? deadlineIntegrity,
    String? attemptId,
    int? score,
    double? percentage,
    DateTime? submittedAt,
  }) {
    return StudentAssignment(
      assignmentId: assignmentId,
      recipientId: recipientId,
      schoolId: schoolId,
      classroomId: classroomId,
      classroomName: classroomName,
      teacherName: teacherName,
      subjectId: subjectId,
      examVariant: examVariant,
      title: title,
      instructions: instructions,
      assignmentType: assignmentType,
      assignmentStatus: assignmentStatus,
      studentStatus: studentStatus ?? this.studentStatus,
      deadlineIntegrity: deadlineIntegrity ?? this.deadlineIntegrity,
      dueAt: dueAt,
      allowLateSubmission: allowLateSubmission,
      timeLimitMinutes: timeLimitMinutes,
      totalQuestions: totalQuestions,
      attemptId: attemptId ?? this.attemptId,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      submittedAt: submittedAt ?? this.submittedAt,
      isOfflineReady: isOfflineReady ?? this.isOfflineReady,
    );
  }

  factory StudentAssignment.fromJson(Map<String, dynamic> json) {
    return StudentAssignment(
      assignmentId: json['assignment_id'] as String,
      recipientId: json['recipient_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classroomId: json['classroom_id'] as String? ?? '',
      classroomName: json['classroom_name'] as String? ?? 'Classroom',
      teacherName: json['teacher_name'] as String? ?? 'Teacher',
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] as String?,
      title: json['title'] as String,
      instructions: json['instructions'] as String?,
      assignmentType: AssignmentType.fromString(
        json['assignment_type'] as String? ?? 'targetedPractice',
      ),
      assignmentStatus: AssignmentStatus.fromString(
        json['assignment_status'] as String? ?? 'published',
      ),
      studentStatus: AssignmentRecipientStatus.fromString(
        json['student_status'] as String? ?? 'assigned',
      ),
      deadlineIntegrity: DeadlineIntegrityLevel.fromString(
        json['deadline_integrity'] as String?,
      ),
      dueAt: json['due_at'] != null
          ? DateTime.parse(json['due_at'] as String)
          : null,
      allowLateSubmission: json['allow_late_submission'] as bool? ?? true,
      timeLimitMinutes: json['time_limit_minutes'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      attemptId: json['attempt_id'] as String?,
      score: (json['score'] as num?)?.toInt(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      isOfflineReady: false,
    );
  }

  @override
  List<Object?> get props => [
        assignmentId,
        recipientId,
        schoolId,
        classroomId,
        classroomName,
        teacherName,
        subjectId,
        examVariant,
        title,
        instructions,
        assignmentType,
        assignmentStatus,
        studentStatus,
        deadlineIntegrity,
        dueAt,
        allowLateSubmission,
        timeLimitMinutes,
        totalQuestions,
        attemptId,
        score,
        percentage,
        submittedAt,
        isOfflineReady,
      ];
}

// =============================================================================
// Interventions Domain Models
// =============================================================================

enum InterventionSource {
  p7Attention,
  teacherObservation,
  assessmentReview,
  mistakeReview;

  static InterventionSource fromString(String val) {
    switch (val) {
      case 'teacherObservation':
        return InterventionSource.teacherObservation;
      case 'assessmentReview':
        return InterventionSource.assessmentReview;
      case 'mistakeReview':
        return InterventionSource.mistakeReview;
      case 'p7Attention':
      default:
        return InterventionSource.p7Attention;
    }
  }

  String get dbValue => name;

  String get labelEn {
    switch (this) {
      case InterventionSource.p7Attention:
        return 'P7 Attention Engine';
      case InterventionSource.teacherObservation:
        return 'Teacher Classroom Observation';
      case InterventionSource.assessmentReview:
        return 'Exam Assessment Review';
      case InterventionSource.mistakeReview:
        return 'Mistake Notebook Review';
    }
  }
}

enum InterventionActionType {
  targetedPractice,
  reviewMistakes,
  simulation,
  teacherFollowUp;

  static InterventionActionType fromString(String val) {
    switch (val) {
      case 'reviewMistakes':
        return InterventionActionType.reviewMistakes;
      case 'simulation':
        return InterventionActionType.simulation;
      case 'teacherFollowUp':
        return InterventionActionType.teacherFollowUp;
      case 'targetedPractice':
      default:
        return InterventionActionType.targetedPractice;
    }
  }

  String get dbValue => name;

  String get labelEn {
    switch (this) {
      case InterventionActionType.targetedPractice:
        return 'Targeted Practice Assignment';
      case InterventionActionType.reviewMistakes:
        return 'Mistake Notebook Review';
      case InterventionActionType.simulation:
        return 'Diagnostic Exam Simulation';
      case InterventionActionType.teacherFollowUp:
        return 'Direct 1-on-1 Academic Follow-up';
    }
  }

  String get labelAm {
    switch (this) {
      case InterventionActionType.targetedPractice:
        return 'የተመረጠ የተግባር ልምምድ';
      case InterventionActionType.reviewMistakes:
        return 'የስህተት ማስታወሻ ክለሳ';
      case InterventionActionType.simulation:
        return 'የአቅም መፈተሻ አስመስሎ';
      case InterventionActionType.teacherFollowUp:
        return 'የአንድ ለአንድ ክትትል';
    }
  }
}

enum InterventionStatus {
  open,
  active,
  completed,
  closed;

  static InterventionStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'active':
        return InterventionStatus.active;
      case 'completed':
        return InterventionStatus.completed;
      case 'closed':
        return InterventionStatus.closed;
      case 'open':
      default:
        return InterventionStatus.open;
    }
  }

  String get dbValue => name;

  String get labelEn {
    switch (this) {
      case InterventionStatus.open:
        return 'Open / Planned';
      case InterventionStatus.active:
        return 'In Progress';
      case InterventionStatus.completed:
        return 'Completed';
      case InterventionStatus.closed:
        return 'Concluded';
    }
  }

  String get labelAm {
    switch (this) {
      case InterventionStatus.open:
        return 'ክፍት / የታቀደ';
      case InterventionStatus.active:
        return 'በሂደት ላይ';
      case InterventionStatus.completed:
        return 'የተጠናቀቀ';
      case InterventionStatus.closed:
        return 'የተዘጋ';
    }
  }
}

/// Represents an academic intervention record.
class StudentIntervention extends Equatable {
  final String id;
  final String schoolId;
  final String classroomId;
  final String classroomName;
  final String subjectId;
  final String? examVariant;
  final String studentUserId;
  final String studentName;
  final String? schoolStudentId;
  final String teacherUserId;
  final InterventionSource source;
  final List<String> sourceReasonCodes;
  final String? severityAtCreation;
  final InterventionActionType actionType;
  final String? linkedAssignmentId;
  final String? linkedAssignmentTitle;
  final InterventionStatus status;
  final String? teacherNote;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? closedAt;

  const StudentIntervention({
    required this.id,
    required this.schoolId,
    required this.classroomId,
    required this.classroomName,
    required this.subjectId,
    this.examVariant,
    required this.studentUserId,
    required this.studentName,
    this.schoolStudentId,
    required this.teacherUserId,
    required this.source,
    required this.sourceReasonCodes,
    this.severityAtCreation,
    required this.actionType,
    this.linkedAssignmentId,
    this.linkedAssignmentTitle,
    required this.status,
    this.teacherNote,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.closedAt,
  });

  factory StudentIntervention.fromJson(Map<String, dynamic> json) {
    final rawReasons = (json['source_reason_codes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return StudentIntervention(
      id: json['intervention_id'] as String? ?? json['id'] as String,
      schoolId: json['school_id'] as String,
      classroomId: json['classroom_id'] as String,
      classroomName: json['classroom_name'] as String? ?? 'Classroom',
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] as String?,
      studentUserId: json['student_user_id'] as String,
      studentName: json['student_name'] as String? ?? 'Student',
      schoolStudentId: json['school_student_id'] as String?,
      teacherUserId: json['teacher_user_id'] as String? ?? '',
      source: InterventionSource.fromString(
        json['source'] as String? ?? 'p7Attention',
      ),
      sourceReasonCodes: rawReasons,
      severityAtCreation: json['severity_at_creation'] as String?,
      actionType: InterventionActionType.fromString(
        json['action_type'] as String? ?? 'targetedPractice',
      ),
      linkedAssignmentId: json['linked_assignment_id'] as String?,
      linkedAssignmentTitle: json['linked_assignment_title'] as String?,
      status: InterventionStatus.fromString(
        json['status'] as String? ?? 'open',
      ),
      teacherNote: json['teacher_note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  bool get isCompleted => status == InterventionStatus.completed;
  bool get isOpen => status == InterventionStatus.open;
  bool get isActive => status == InterventionStatus.active;
  bool get isClosed => status == InterventionStatus.closed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'classroom_id': classroomId,
      'classroom_name': classroomName,
      'subject_id': subjectId,
      'exam_variant': examVariant,
      'student_user_id': studentUserId,
      'student_name': studentName,
      'school_student_id': schoolStudentId,
      'teacher_user_id': teacherUserId,
      'source': source.dbValue,
      'source_reason_codes': sourceReasonCodes,
      'severity_at_creation': severityAtCreation,
      'action_type': actionType.dbValue,
      'linked_assignment_id': linkedAssignmentId,
      'linked_assignment_title': linkedAssignmentTitle,
      'status': status.dbValue,
      'teacher_note': teacherNote,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        classroomId,
        classroomName,
        subjectId,
        examVariant,
        studentUserId,
        studentName,
        schoolStudentId,
        teacherUserId,
        source,
        sourceReasonCodes,
        severityAtCreation,
        actionType,
        linkedAssignmentId,
        linkedAssignmentTitle,
        status,
        teacherNote,
        createdAt,
        startedAt,
        completedAt,
        closedAt,
      ];
}

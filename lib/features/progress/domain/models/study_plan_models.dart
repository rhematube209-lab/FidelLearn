import 'package:equatable/equatable.dart';

import '../../../subjects/domain/models/subject_models.dart';

export '../services/exam_preparation_policy.dart'
    show ExamPreparationPhase, ExamPreparationPolicy;

const String kAdaptivePlannerAlgorithmVersion = 'adaptive_planner_v1.1';

enum StudySessionType {
  weakTopicPractice,
  curriculumCoverage,
  mistakeReview,
  masteryMaintenance,
  timedPractice,
  mockExam;

  static StudySessionType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'curriculum_coverage':
      case 'curriculumcoverage':
        return StudySessionType.curriculumCoverage;
      case 'mistake_review':
      case 'mistakereview':
        return StudySessionType.mistakeReview;
      case 'mastery_maintenance':
      case 'masterymaintenance':
        return StudySessionType.masteryMaintenance;
      case 'timed_practice':
      case 'timedpractice':
        return StudySessionType.timedPractice;
      case 'mock_exam':
      case 'mockexam':
        return StudySessionType.mockExam;
      case 'weak_topic_practice':
      case 'weaktopicpractice':
      default:
        return StudySessionType.weakTopicPractice;
    }
  }

  String toDbString() {
    switch (this) {
      case StudySessionType.weakTopicPractice:
        return 'weak_topic_practice';
      case StudySessionType.curriculumCoverage:
        return 'curriculum_coverage';
      case StudySessionType.mistakeReview:
        return 'mistake_review';
      case StudySessionType.masteryMaintenance:
        return 'mastery_maintenance';
      case StudySessionType.timedPractice:
        return 'timed_practice';
      case StudySessionType.mockExam:
        return 'mock_exam';
    }
  }

  String get displayNameEn {
    switch (this) {
      case StudySessionType.weakTopicPractice:
        return 'Weak Topic Remediation';
      case StudySessionType.curriculumCoverage:
        return 'Curriculum Coverage';
      case StudySessionType.mistakeReview:
        return 'Mistake Review';
      case StudySessionType.masteryMaintenance:
        return 'Mastery Recall';
      case StudySessionType.timedPractice:
        return 'Timed Practice Drill';
      case StudySessionType.mockExam:
        return 'National Mock Simulation';
    }
  }

  String get displayNameAm {
    switch (this) {
      case StudySessionType.weakTopicPractice:
        return 'ትኩረት የሚሻ ርዕስ ልምምድ';
      case StudySessionType.curriculumCoverage:
        return 'አዲስ የትምህርት ይዘት ሽፋን';
      case StudySessionType.mistakeReview:
        return 'የስህተት ማስታወሻ ክለሳ';
      case StudySessionType.masteryMaintenance:
        return 'የተካኑበትን ርዕስ ማስታወስ';
      case StudySessionType.timedPractice:
        return 'ባለጊዜ የልምምድ ፈተና';
      case StudySessionType.mockExam:
        return 'ሙሉ የሞዴል ፈተና';
    }
  }
}

enum SessionCompletionStatus {
  notStarted,
  inProgress,
  completed,
  skipped;

  static SessionCompletionStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
        return SessionCompletionStatus.inProgress;
      case 'completed':
        return SessionCompletionStatus.completed;
      case 'skipped':
        return SessionCompletionStatus.skipped;
      case 'not_started':
      case 'notstarted':
      default:
        return SessionCompletionStatus.notStarted;
    }
  }

  String toDbString() {
    switch (this) {
      case SessionCompletionStatus.notStarted:
        return 'not_started';
      case SessionCompletionStatus.inProgress:
        return 'in_progress';
      case SessionCompletionStatus.completed:
        return 'completed';
      case SessionCompletionStatus.skipped:
        return 'skipped';
    }
  }

  String get displayNameEn {
    switch (this) {
      case SessionCompletionStatus.notStarted:
        return 'Not Started';
      case SessionCompletionStatus.inProgress:
        return 'In Progress';
      case SessionCompletionStatus.completed:
        return 'Completed';
      case SessionCompletionStatus.skipped:
        return 'Skipped';
    }
  }

  String get displayNameAm {
    switch (this) {
      case SessionCompletionStatus.notStarted:
        return 'አልተጀመረም';
      case SessionCompletionStatus.inProgress:
        return 'በሂደት ላይ';
      case SessionCompletionStatus.completed:
        return 'ተጠናቋል';
      case SessionCompletionStatus.skipped:
        return 'የታለፈ';
    }
  }
}

enum RecommendationReasonCode {
  weakTopic,
  lowRecentAccuracy,
  newCurriculum,
  mistakeReview,
  reviewOverdue,
  masteryMaintenance,
  examApproaching,
  mockDue,
  masteryReviewDue,
  masteryAtRisk,
  relearningNeeded,
  longTermRecall;

  static RecommendationReasonCode fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'low_recent_accuracy':
      case 'lowrecentaccuracy':
        return RecommendationReasonCode.lowRecentAccuracy;
      case 'new_curriculum':
      case 'newcurriculum':
        return RecommendationReasonCode.newCurriculum;
      case 'mistake_review':
      case 'mistakereview':
        return RecommendationReasonCode.mistakeReview;
      case 'review_overdue':
      case 'reviewoverdue':
        return RecommendationReasonCode.reviewOverdue;
      case 'mastery_maintenance':
      case 'masterymaintenance':
        return RecommendationReasonCode.masteryMaintenance;
      case 'mastery_review_due':
      case 'masteryreviewdue':
        return RecommendationReasonCode.masteryReviewDue;
      case 'mastery_at_risk':
      case 'masteryatrisk':
        return RecommendationReasonCode.masteryAtRisk;
      case 'relearning_needed':
      case 'relearningneeded':
        return RecommendationReasonCode.relearningNeeded;
      case 'long_term_recall':
      case 'longtermrecall':
        return RecommendationReasonCode.longTermRecall;
      case 'exam_approaching':
      case 'examapproaching':
        return RecommendationReasonCode.examApproaching;
      case 'mock_due':
      case 'mockdue':
        return RecommendationReasonCode.mockDue;
      case 'weak_topic':
      case 'weaktopic':
      default:
        return RecommendationReasonCode.weakTopic;
    }
  }

  String toDbString() {
    switch (this) {
      case RecommendationReasonCode.weakTopic:
        return 'weak_topic';
      case RecommendationReasonCode.lowRecentAccuracy:
        return 'low_recent_accuracy';
      case RecommendationReasonCode.newCurriculum:
        return 'new_curriculum';
      case RecommendationReasonCode.mistakeReview:
        return 'mistake_review';
      case RecommendationReasonCode.reviewOverdue:
        return 'review_overdue';
      case RecommendationReasonCode.masteryMaintenance:
        return 'mastery_maintenance';
      case RecommendationReasonCode.masteryReviewDue:
        return 'mastery_review_due';
      case RecommendationReasonCode.masteryAtRisk:
        return 'mastery_at_risk';
      case RecommendationReasonCode.relearningNeeded:
        return 'relearning_needed';
      case RecommendationReasonCode.longTermRecall:
        return 'long_term_recall';
      case RecommendationReasonCode.examApproaching:
        return 'exam_approaching';
      case RecommendationReasonCode.mockDue:
        return 'mock_due';
    }
  }

  String get labelEn {
    switch (this) {
      case RecommendationReasonCode.weakTopic:
        return 'Weak Topic';
      case RecommendationReasonCode.lowRecentAccuracy:
        return 'Low Accuracy';
      case RecommendationReasonCode.newCurriculum:
        return 'New Curriculum';
      case RecommendationReasonCode.mistakeReview:
        return 'Mistake Review';
      case RecommendationReasonCode.reviewOverdue:
        return 'Overdue Review';
      case RecommendationReasonCode.masteryMaintenance:
        return 'Mastery Check';
      case RecommendationReasonCode.masteryReviewDue:
        return 'Spaced Review Due';
      case RecommendationReasonCode.masteryAtRisk:
        return 'Mastery At Risk';
      case RecommendationReasonCode.relearningNeeded:
        return 'Relearning Needed';
      case RecommendationReasonCode.longTermRecall:
        return 'Long-Term Recall';
      case RecommendationReasonCode.examApproaching:
        return 'Exam Approaching';
      case RecommendationReasonCode.mockDue:
        return 'Mock Exam Due';
    }
  }

  String get labelAm {
    switch (this) {
      case RecommendationReasonCode.weakTopic:
        return 'ትኩረት የሚሻ ርዕስ';
      case RecommendationReasonCode.lowRecentAccuracy:
        return 'ዝቅተኛ ውጤት';
      case RecommendationReasonCode.newCurriculum:
        return 'አዲስ ይዘት';
      case RecommendationReasonCode.mistakeReview:
        return 'የስህተት ክለሳ';
      case RecommendationReasonCode.reviewOverdue:
        return 'ያለፈበት ክለሳ';
      case RecommendationReasonCode.masteryMaintenance:
        return 'የብቃት ማረጋገጫ';
      case RecommendationReasonCode.masteryReviewDue:
        return 'የተቀጠረ የክለሳ ጊዜ ደርሷል';
      case RecommendationReasonCode.masteryAtRisk:
        return 'ክለሳ የሚሻ ብቃት';
      case RecommendationReasonCode.relearningNeeded:
        return 'እንደገና መማር የሚያስፈልግ';
      case RecommendationReasonCode.longTermRecall:
        return 'የረጅም ጊዜ ማስታወስ';
      case RecommendationReasonCode.examApproaching:
        return 'ፈተና እየደረሰ ነው';
      case RecommendationReasonCode.mockDue:
        return 'የሞዴል ፈተና ጊዜ';
    }
  }
}

class StudyPlanSession extends Equatable {
  final String id;
  final String planId;
  final String subjectId;
  final String? unitId;
  final String? topicId;
  final ExamVariantCode? examVariant;
  final AssessmentStructure? assessmentStructure;
  final String? contentDomain;
  final String? skill;
  final StudySessionType sessionType;
  final String titleEn;
  final String titleAm;
  final int questionTarget;
  final int estimatedMinutes;
  final double priorityScore;
  final RecommendationReasonCode reasonCode;
  final String reasonDetailEn;
  final String reasonDetailAm;
  final SessionCompletionStatus status;
  final List<String> questionIds;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final double? scorePercentage;

  const StudyPlanSession({
    required this.id,
    required this.planId,
    required this.subjectId,
    this.unitId,
    this.topicId,
    this.examVariant,
    this.assessmentStructure,
    this.contentDomain,
    this.skill,
    required this.sessionType,
    required this.titleEn,
    required this.titleAm,
    required this.questionTarget,
    required this.estimatedMinutes,
    required this.priorityScore,
    required this.reasonCode,
    required this.reasonDetailEn,
    required this.reasonDetailAm,
    this.status = SessionCompletionStatus.notStarted,
    this.questionIds = const [],
    this.completedAt,
    this.timeSpentSeconds = 0,
    this.scorePercentage,
  });

  bool get isCompleted => status == SessionCompletionStatus.completed;

  StudyPlanSession copyWith({
    String? subjectId,
    String? unitId,
    String? topicId,
    ExamVariantCode? examVariant,
    AssessmentStructure? assessmentStructure,
    String? contentDomain,
    String? skill,
    StudySessionType? sessionType,
    String? titleEn,
    String? titleAm,
    int? questionTarget,
    int? estimatedMinutes,
    double? priorityScore,
    RecommendationReasonCode? reasonCode,
    String? reasonDetailEn,
    String? reasonDetailAm,
    SessionCompletionStatus? status,
    List<String>? questionIds,
    DateTime? completedAt,
    int? timeSpentSeconds,
    double? scorePercentage,
  }) {
    return StudyPlanSession(
      id: id,
      planId: planId,
      subjectId: subjectId ?? this.subjectId,
      unitId: unitId ?? this.unitId,
      topicId: topicId ?? this.topicId,
      examVariant: examVariant ?? this.examVariant,
      assessmentStructure: assessmentStructure ?? this.assessmentStructure,
      contentDomain: contentDomain ?? this.contentDomain,
      skill: skill ?? this.skill,
      sessionType: sessionType ?? this.sessionType,
      titleEn: titleEn ?? this.titleEn,
      titleAm: titleAm ?? this.titleAm,
      questionTarget: questionTarget ?? this.questionTarget,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      priorityScore: priorityScore ?? this.priorityScore,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonDetailEn: reasonDetailEn ?? this.reasonDetailEn,
      reasonDetailAm: reasonDetailAm ?? this.reasonDetailAm,
      status: status ?? this.status,
      questionIds: questionIds ?? this.questionIds,
      completedAt: completedAt ?? this.completedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      scorePercentage: scorePercentage ?? this.scorePercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'subject_id': subjectId,
      'unit_id': unitId,
      'topic_id': topicId,
      'exam_variant': examVariant?.name,
      'assessment_structure': assessmentStructure?.name,
      'content_domain': contentDomain,
      'skill': skill,
      'session_type': sessionType.toDbString(),
      'title_en': titleEn,
      'title_am': titleAm,
      'question_target': questionTarget,
      'estimated_minutes': estimatedMinutes,
      'priority_score': priorityScore,
      'reason_code': reasonCode.toDbString(),
      'reason_detail_en': reasonDetailEn,
      'reason_detail_am': reasonDetailAm,
      'status': status.toDbString(),
      'question_ids': questionIds,
      'completed_at': completedAt?.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
      'score_percentage': scorePercentage,
    };
  }

  factory StudyPlanSession.fromJson(Map<String, dynamic> json) {
    final rawVariant = json['exam_variant']?.toString();
    ExamVariantCode? resolvedVariant;
    if (rawVariant != null) {
      final vName = rawVariant.toLowerCase().replaceAll('-', '_');
      if (vName.contains('nat')) {
        resolvedVariant = ExamVariantCode.naturalScience;
      } else if (vName.contains('soc')) {
        resolvedVariant = ExamVariantCode.socialScience;
      } else {
        resolvedVariant = ExamVariantCode.shared;
      }
    }

    final rawStructure = json['assessment_structure']?.toString();
    AssessmentStructure? resolvedStructure;
    if (rawStructure != null) {
      final sName = rawStructure.toLowerCase().replaceAll('-', '_');
      if (sName.contains('skill')) {
        resolvedStructure = AssessmentStructure.skillBased;
      } else if (sName.contains('mix')) {
        resolvedStructure = AssessmentStructure.mixed;
      } else {
        resolvedStructure = AssessmentStructure.curriculum;
      }
    }

    return StudyPlanSession(
      id: json['id'] as String,
      planId: json['plan_id'] as String? ?? '',
      subjectId: json['subject_id'] as String,
      unitId: json['unit_id'] as String?,
      topicId: json['topic_id'] as String?,
      examVariant: resolvedVariant,
      assessmentStructure: resolvedStructure,
      contentDomain: json['content_domain'] as String?,
      skill: json['skill'] as String?,
      sessionType: StudySessionType.fromString(json['session_type'] as String?),
      titleEn: json['title_en'] as String? ?? '',
      titleAm: json['title_am'] as String? ?? '',
      questionTarget: (json['question_target'] as num?)?.toInt() ?? 10,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 15,
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.0,
      reasonCode:
          RecommendationReasonCode.fromString(json['reason_code'] as String?),
      reasonDetailEn: json['reason_detail_en'] as String? ?? '',
      reasonDetailAm: json['reason_detail_am'] as String? ?? '',
      status: SessionCompletionStatus.fromString(json['status'] as String?),
      questionIds: (json['question_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
      scorePercentage: (json['score_percentage'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        planId,
        subjectId,
        unitId,
        topicId,
        examVariant,
        assessmentStructure,
        contentDomain,
        skill,
        sessionType,
        titleEn,
        titleAm,
        questionTarget,
        estimatedMinutes,
        priorityScore,
        reasonCode,
        reasonDetailEn,
        reasonDetailAm,
        status,
        questionIds,
        completedAt,
        timeSpentSeconds,
        scorePercentage,
      ];
}

class StudyPlan extends Equatable {
  final String id;
  final String userId;
  final DateTime planDate;
  final int targetMinutes;
  final int estimatedMinutes;
  final List<StudyPlanSession> sessions;
  final SessionCompletionStatus status;
  final String algorithmVersion;
  final DateTime generatedAt;

  const StudyPlan({
    required this.id,
    required this.userId,
    required this.planDate,
    required this.targetMinutes,
    required this.estimatedMinutes,
    required this.sessions,
    this.status = SessionCompletionStatus.notStarted,
    this.algorithmVersion = kAdaptivePlannerAlgorithmVersion,
    required this.generatedAt,
  });

  int get completedMinutes => sessions
      .where((s) => s.status == SessionCompletionStatus.completed)
      .fold<int>(0, (sum, s) => sum + s.estimatedMinutes);

  int get completedSessionsCount => sessions
      .where((s) => s.status == SessionCompletionStatus.completed)
      .length;

  double get completionPercentage {
    if (sessions.isEmpty) return 0.0;
    return (completedSessionsCount / sessions.length) * 100.0;
  }

  bool get isFullyCompleted =>
      sessions.isNotEmpty &&
      sessions.every((s) => s.status == SessionCompletionStatus.completed);

  StudyPlan copyWith({
    int? targetMinutes,
    int? estimatedMinutes,
    List<StudyPlanSession>? sessions,
    SessionCompletionStatus? status,
    DateTime? generatedAt,
  }) {
    return StudyPlan(
      id: id,
      userId: userId,
      planDate: planDate,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      sessions: sessions ?? this.sessions,
      status: status ?? this.status,
      algorithmVersion: algorithmVersion,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_date': planDate.toIso8601String().substring(0, 10),
      'target_minutes': targetMinutes,
      'estimated_minutes': estimatedMinutes,
      'status': status.toDbString(),
      'algorithm_version': algorithmVersion,
      'generated_at': generatedAt.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final rawSessions = (json['sessions'] as List<dynamic>?) ?? [];
    return StudyPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planDate: DateTime.parse(json['plan_date'] as String),
      targetMinutes: (json['target_minutes'] as num?)?.toInt() ?? 45,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 45,
      status: SessionCompletionStatus.fromString(json['status'] as String?),
      algorithmVersion: json['algorithm_version'] as String? ??
          kAdaptivePlannerAlgorithmVersion,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      sessions: rawSessions
          .map((s) => StudyPlanSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        planDate,
        targetMinutes,
        estimatedMinutes,
        sessions,
        status,
        algorithmVersion,
        generatedAt,
      ];
}

class PlannerSettings extends Equatable {
  final int dailyBudgetMinutes;
  final DateTime targetExamDate;
  final bool includeWeekends;

  const PlannerSettings({
    this.dailyBudgetMinutes = 45,
    required this.targetExamDate,
    this.includeWeekends = true,
  });

  PlannerSettings copyWith({
    int? dailyBudgetMinutes,
    DateTime? targetExamDate,
    bool? includeWeekends,
  }) {
    return PlannerSettings(
      dailyBudgetMinutes: dailyBudgetMinutes ?? this.dailyBudgetMinutes,
      targetExamDate: targetExamDate ?? this.targetExamDate,
      includeWeekends: includeWeekends ?? this.includeWeekends,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_budget_minutes': dailyBudgetMinutes,
      'target_exam_date': targetExamDate.toIso8601String(),
      'include_weekends': includeWeekends,
    };
  }

  factory PlannerSettings.fromJson(Map<String, dynamic> json) {
    return PlannerSettings(
      dailyBudgetMinutes: (json['daily_budget_minutes'] as num?)?.toInt() ?? 45,
      targetExamDate: json['target_exam_date'] != null
          ? DateTime.parse(json['target_exam_date'] as String)
          : DateTime.now().add(const Duration(days: 75)),
      includeWeekends: json['include_weekends'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props =>
      [dailyBudgetMinutes, targetExamDate, includeWeekends];
}

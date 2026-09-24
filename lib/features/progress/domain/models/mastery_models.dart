import 'package:equatable/equatable.dart';

import '../../../subjects/domain/models/subject_models.dart';

/// Version identifier for the deterministic mastery and spaced repetition engine.
const String kMasteryEngineAlgorithmVersion = 'mastery_engine_v1.0';

/// Provenance of the mastery evidence (native spaced repetition vs legacy migration).
enum EvidenceSource {
  native,
  legacyMigration;

  String toDbString() =>
      this == legacyMigration ? 'legacy_migration' : 'native';

  static EvidenceSource fromString(String? val) {
    if (val == 'legacy_migration' || val == 'legacyMigration') {
      return EvidenceSource.legacyMigration;
    }
    return EvidenceSource.native;
  }
}

/// Canonical lifecycle states of learning mastery.
enum MasteryState {
  newItem, // No meaningful attempt evidence yet
  learning, // Inconsistent performance (<70% accuracy or <2 correct)
  improving, // Positive trend (>=70% accuracy or 2 consecutive correct) without temporal spacing
  mastered, // Durable retrieval across spaced intervals with stability >= 1.0
  atRisk, // Previously mastered, but review is overdue or retrieval decayed
  relearning; // Previously mastered, but failed during review/practice (lapse)

  static MasteryState fromString(String? val) {
    switch (val?.toLowerCase().replaceAll('_', '')) {
      case 'learning':
        return MasteryState.learning;
      case 'improving':
        return MasteryState.improving;
      case 'mastered':
        return MasteryState.mastered;
      case 'atrisk':
        return MasteryState.atRisk;
      case 'relearning':
        return MasteryState.relearning;
      case 'newitem':
      case 'new':
      default:
        return MasteryState.newItem;
    }
  }

  String toDbString() {
    switch (this) {
      case MasteryState.newItem:
        return 'new';
      case MasteryState.learning:
        return 'learning';
      case MasteryState.improving:
        return 'improving';
      case MasteryState.mastered:
        return 'mastered';
      case MasteryState.atRisk:
        return 'at_risk';
      case MasteryState.relearning:
        return 'relearning';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MasteryState.newItem:
        return 'New';
      case MasteryState.learning:
        return 'Learning';
      case MasteryState.improving:
        return 'Improving';
      case MasteryState.mastered:
        return 'Mastered';
      case MasteryState.atRisk:
        return 'At Risk';
      case MasteryState.relearning:
        return 'Relearning';
    }
  }

  String get displayNameAm {
    switch (this) {
      case MasteryState.newItem:
        return 'አዲስ';
      case MasteryState.learning:
        return 'በመማር ላይ';
      case MasteryState.improving:
        return 'እየተሻሻለ';
      case MasteryState.mastered:
        return 'የተካኑበት';
      case MasteryState.atRisk:
        return 'ክለሳ የሚሻ';
      case MasteryState.relearning:
        return 'እንደገና መማር';
    }
  }
}

/// Question-level mastery tracking record.
class QuestionMasteryRecord extends Equatable {
  final String id; // userId_questionId
  final String userId;
  final String questionId;
  final String subjectId;
  final ExamVariantCode? examVariant;
  final AssessmentStructure? assessmentStructure;
  final String? unitId;
  final String? topicId;
  final String? contentDomain;
  final String? skill;

  final MasteryState masteryState;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int consecutiveCorrect;

  final double stability; // Estimated memory strength in days
  final double
      difficulty; // Item difficulty weight (1.0 = easy, 2.0 = medium, 3.0 = hard)

  final int reviewCount;
  final int lapseCount;

  final DateTime? lastSeenAt;
  final DateTime? lastCorrectAt;
  final DateTime? lastIncorrectAt;
  final DateTime? nextReviewAt;

  final String algorithmVersion;
  final EvidenceSource evidenceSource;
  final DateTime updatedAt;

  const QuestionMasteryRecord({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.subjectId,
    this.examVariant,
    this.assessmentStructure,
    this.unitId,
    this.topicId,
    this.contentDomain,
    this.skill,
    this.masteryState = MasteryState.newItem,
    this.attemptCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.consecutiveCorrect = 0,
    this.stability = 1.0,
    this.difficulty = 2.0,
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.lastSeenAt,
    this.lastCorrectAt,
    this.lastIncorrectAt,
    this.nextReviewAt,
    this.algorithmVersion = kMasteryEngineAlgorithmVersion,
    this.evidenceSource = EvidenceSource.native,
    required this.updatedAt,
  });

  bool get isDueForReview {
    if (nextReviewAt == null) return false;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  QuestionMasteryRecord copyWith({
    MasteryState? masteryState,
    int? attemptCount,
    int? correctCount,
    int? incorrectCount,
    int? consecutiveCorrect,
    double? stability,
    double? difficulty,
    int? reviewCount,
    int? lapseCount,
    DateTime? lastSeenAt,
    DateTime? lastCorrectAt,
    DateTime? lastIncorrectAt,
    DateTime? nextReviewAt,
    String? algorithmVersion,
    EvidenceSource? evidenceSource,
    DateTime? updatedAt,
  }) {
    return QuestionMasteryRecord(
      id: id,
      userId: userId,
      questionId: questionId,
      subjectId: subjectId,
      examVariant: examVariant,
      assessmentStructure: assessmentStructure,
      unitId: unitId,
      topicId: topicId,
      contentDomain: contentDomain,
      skill: skill,
      masteryState: masteryState ?? this.masteryState,
      attemptCount: attemptCount ?? this.attemptCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastCorrectAt: lastCorrectAt ?? this.lastCorrectAt,
      lastIncorrectAt: lastIncorrectAt ?? this.lastIncorrectAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      evidenceSource: evidenceSource ?? this.evidenceSource,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'subject_id': subjectId,
      'exam_variant': examVariant?.name,
      'assessment_structure': assessmentStructure?.name,
      'unit_id': unitId,
      'topic_id': topicId,
      'content_domain': contentDomain,
      'skill': skill,
      'mastery_state': masteryState.toDbString(),
      'attempt_count': attemptCount,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
      'consecutive_correct': consecutiveCorrect,
      'stability': stability,
      'difficulty': difficulty,
      'review_count': reviewCount,
      'lapse_count': lapseCount,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'last_correct_at': lastCorrectAt?.toIso8601String(),
      'last_incorrect_at': lastIncorrectAt?.toIso8601String(),
      'next_review_at': nextReviewAt?.toIso8601String(),
      'algorithm_version': algorithmVersion,
      'evidence_source': evidenceSource.toDbString(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory QuestionMasteryRecord.fromJson(Map<String, dynamic> json) {
    return QuestionMasteryRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      subjectId: json['subject_id'] as String,
      examVariant: json['exam_variant'] != null
          ? ExamVariantCode.fromString(json['exam_variant'] as String)
          : null,
      assessmentStructure: json['assessment_structure'] != null
          ? AssessmentStructure.fromString(
              json['assessment_structure'] as String)
          : null,
      unitId: json['unit_id'] as String?,
      topicId: json['topic_id'] as String?,
      contentDomain: json['content_domain'] as String?,
      skill: json['skill'] as String?,
      masteryState: MasteryState.fromString(json['mastery_state'] as String?),
      attemptCount: json['attempt_count'] as int? ?? 0,
      correctCount: json['correct_count'] as int? ?? 0,
      incorrectCount: json['incorrect_count'] as int? ?? 0,
      consecutiveCorrect: json['consecutive_correct'] as int? ?? 0,
      stability: (json['stability'] as num?)?.toDouble() ?? 1.0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 2.0,
      reviewCount: json['review_count'] as int? ?? 0,
      lapseCount: json['lapse_count'] as int? ?? 0,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      lastCorrectAt: json['last_correct_at'] != null
          ? DateTime.parse(json['last_correct_at'] as String)
          : null,
      lastIncorrectAt: json['last_incorrect_at'] != null
          ? DateTime.parse(json['last_incorrect_at'] as String)
          : null,
      nextReviewAt: json['next_review_at'] != null
          ? DateTime.parse(json['next_review_at'] as String)
          : null,
      algorithmVersion: json['algorithm_version'] as String? ??
          kMasteryEngineAlgorithmVersion,
      evidenceSource:
          EvidenceSource.fromString(json['evidence_source'] as String?),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questionId,
        subjectId,
        examVariant,
        masteryState,
        attemptCount,
        correctCount,
        consecutiveCorrect,
        stability,
        reviewCount,
        lapseCount,
        nextReviewAt,
        evidenceSource,
      ];
}

/// Learning-target level mastery tracking record (Topic / Domain / Skill).
class LearningTargetMasteryRecord extends Equatable {
  final String id; // userId_targetKey
  final String userId;
  final String targetKey;
  final String subjectId;
  final ExamVariantCode? examVariant;
  final AssessmentStructure? assessmentStructure;
  final String? unitId;
  final String? topicId;
  final String? contentDomain;
  final String? skill;

  final String titleEn;
  final String titleAm;

  final MasteryState masteryState;
  final EvidenceSource evidenceSource;
  final double accuracyPercentage;
  final int totalAttempts;
  final int masteredQuestionCount;
  final int coveredQuestionCount;
  final int totalAvailableQuestions;

  final DateTime? nextReviewAt;
  final DateTime? lastPracticedAt;
  final DateTime updatedAt;

  const LearningTargetMasteryRecord({
    required this.id,
    required this.userId,
    required this.targetKey,
    required this.subjectId,
    this.examVariant,
    this.assessmentStructure,
    this.unitId,
    this.topicId,
    this.contentDomain,
    this.skill,
    required this.titleEn,
    required this.titleAm,
    this.masteryState = MasteryState.newItem,
    this.evidenceSource = EvidenceSource.native,
    this.accuracyPercentage = 0.0,
    this.totalAttempts = 0,
    this.masteredQuestionCount = 0,
    this.coveredQuestionCount = 0,
    this.totalAvailableQuestions = 0,
    this.nextReviewAt,
    this.lastPracticedAt,
    required this.updatedAt,
  });

  /// Coverage ratio of the target (0.0 to 1.0).
  double get coverageRatio {
    if (totalAvailableQuestions <= 0) return 0.0;
    return (coveredQuestionCount / totalAvailableQuestions).clamp(0.0, 1.0);
  }

  /// Mastery ratio of attempted material (0.0 to 1.0).
  double get masteryRatio {
    if (coveredQuestionCount <= 0) return 0.0;
    return (masteredQuestionCount / coveredQuestionCount).clamp(0.0, 1.0);
  }

  bool get isDueForReview {
    if (nextReviewAt == null) return false;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  LearningTargetMasteryRecord copyWith({
    MasteryState? masteryState,
    EvidenceSource? evidenceSource,
    double? accuracyPercentage,
    int? totalAttempts,
    int? masteredQuestionCount,
    int? coveredQuestionCount,
    int? totalAvailableQuestions,
    DateTime? nextReviewAt,
    DateTime? lastPracticedAt,
    DateTime? updatedAt,
  }) {
    return LearningTargetMasteryRecord(
      id: id,
      userId: userId,
      targetKey: targetKey,
      subjectId: subjectId,
      examVariant: examVariant,
      assessmentStructure: assessmentStructure,
      unitId: unitId,
      topicId: topicId,
      contentDomain: contentDomain,
      skill: skill,
      titleEn: titleEn,
      titleAm: titleAm,
      masteryState: masteryState ?? this.masteryState,
      evidenceSource: evidenceSource ?? this.evidenceSource,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      masteredQuestionCount:
          masteredQuestionCount ?? this.masteredQuestionCount,
      coveredQuestionCount: coveredQuestionCount ?? this.coveredQuestionCount,
      totalAvailableQuestions:
          totalAvailableQuestions ?? this.totalAvailableQuestions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        targetKey,
        subjectId,
        examVariant,
        masteryState,
        evidenceSource,
        accuracyPercentage,
        totalAttempts,
        masteredQuestionCount,
        coveredQuestionCount,
        nextReviewAt,
      ];
}

/// Immutable record of a review event for auditability and sync.
class ReviewEventRecord extends Equatable {
  final String id;
  final String userId;
  final String questionId;
  final String targetKey;
  final String? subjectId;
  final ExamVariantCode? examVariant;
  final DateTime reviewedAt;
  final DateTime scheduledAt;
  final bool isCorrect;
  final int timeSpentSeconds;
  final MasteryState previousState;
  final MasteryState newState;
  final int previousIntervalDays;
  final int newIntervalDays;
  final String algorithmVersion;

  const ReviewEventRecord({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.targetKey,
    this.subjectId,
    this.examVariant,
    required this.reviewedAt,
    required this.scheduledAt,
    required this.isCorrect,
    this.timeSpentSeconds = 0,
    required this.previousState,
    required this.newState,
    required this.previousIntervalDays,
    required this.newIntervalDays,
    this.algorithmVersion = kMasteryEngineAlgorithmVersion,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        questionId,
        targetKey,
        subjectId,
        examVariant,
        reviewedAt,
        isCorrect,
        previousState,
        newState,
        newIntervalDays,
      ];
}

/// Aggregate summary of mastery across a subject.
class SubjectMasterySummary extends Equatable {
  final String subjectId;
  final ExamVariantCode? examVariant;
  final int masteredTargets;
  final int improvingTargets;
  final int atRiskTargets;
  final int newTargets;
  final int reviewsDue;
  final double averageAccuracy;

  const SubjectMasterySummary({
    required this.subjectId,
    this.examVariant,
    required this.masteredTargets,
    required this.improvingTargets,
    required this.atRiskTargets,
    required this.newTargets,
    required this.reviewsDue,
    required this.averageAccuracy,
  });

  int get totalTargets =>
      masteredTargets + improvingTargets + atRiskTargets + newTargets;

  @override
  List<Object?> get props => [
        subjectId,
        examVariant,
        masteredTargets,
        improvingTargets,
        atRiskTargets,
        newTargets,
        reviewsDue,
        averageAccuracy,
      ];
}

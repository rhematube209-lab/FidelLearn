import 'package:equatable/equatable.dart';

enum MasteryStatus {
  needsReview,
  improving,
  mastered;

  static MasteryStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'improving':
        return MasteryStatus.improving;
      case 'mastered':
        return MasteryStatus.mastered;
      case 'needsreview':
      case 'needs_review':
      default:
        return MasteryStatus.needsReview;
    }
  }

  String toDbString() {
    switch (this) {
      case MasteryStatus.needsReview:
        return 'needsReview';
      case MasteryStatus.improving:
        return 'improving';
      case MasteryStatus.mastered:
        return 'mastered';
    }
  }

  String get displayNameEn {
    switch (this) {
      case MasteryStatus.needsReview:
        return 'Needs Review';
      case MasteryStatus.improving:
        return 'Improving';
      case MasteryStatus.mastered:
        return 'Mastered';
    }
  }
}

class MistakeCounts extends Equatable {
  final int total;
  final int needsReview;
  final int improving;
  final int mastered;

  const MistakeCounts({
    required this.total,
    required this.needsReview,
    required this.improving,
    required this.mastered,
  });

  const MistakeCounts.empty()
      : total = 0,
        needsReview = 0,
        improving = 0,
        mastered = 0;

  @override
  List<Object?> get props => [total, needsReview, improving, mastered];
}

class MistakeRecord extends Equatable {
  final String id;
  final String userId;
  final String questionId;
  final String subjectId;
  final String? unitId;
  final String? topicId;
  final String? lastAttemptId;
  final String? lastSelectedChoiceId;

  final DateTime firstMissedAt;
  final DateTime lastMissedAt;
  final DateTime? lastAttemptAt;

  final int missCount;
  final int retryCount;
  final int correctRetryCount;

  final MasteryStatus masteryStatus;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;

  const MistakeRecord({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.subjectId,
    this.unitId,
    this.topicId,
    this.lastAttemptId,
    this.lastSelectedChoiceId,
    required this.firstMissedAt,
    required this.lastMissedAt,
    this.lastAttemptAt,
    required this.missCount,
    this.retryCount = 0,
    this.correctRetryCount = 0,
    this.masteryStatus = MasteryStatus.needsReview,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  // Legacy field getters for backward compatibility
  int get mistakeCount => missCount;
  bool get isMastered => masteryStatus == MasteryStatus.mastered;
  DateTime get lastFailedAt => lastMissedAt;
  DateTime? get masteredAt =>
      masteryStatus == MasteryStatus.mastered ? updatedAt : null;

  MistakeRecord copyWith({
    String? subjectId,
    String? unitId,
    String? topicId,
    String? lastAttemptId,
    String? lastSelectedChoiceId,
    DateTime? firstMissedAt,
    DateTime? lastMissedAt,
    DateTime? lastAttemptAt,
    int? missCount,
    int? retryCount,
    int? correctRetryCount,
    MasteryStatus? masteryStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return MistakeRecord(
      id: id,
      userId: userId,
      questionId: questionId,
      subjectId: subjectId ?? this.subjectId,
      unitId: unitId ?? this.unitId,
      topicId: topicId ?? this.topicId,
      lastAttemptId: lastAttemptId ?? this.lastAttemptId,
      lastSelectedChoiceId: lastSelectedChoiceId ?? this.lastSelectedChoiceId,
      firstMissedAt: firstMissedAt ?? this.firstMissedAt,
      lastMissedAt: lastMissedAt ?? this.lastMissedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      missCount: missCount ?? this.missCount,
      retryCount: retryCount ?? this.retryCount,
      correctRetryCount: correctRetryCount ?? this.correctRetryCount,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'subject_id': subjectId,
      'unit_id': unitId,
      'topic_id': topicId,
      'last_attempt_id': lastAttemptId,
      'last_selected_choice_id': lastSelectedChoiceId,
      'first_missed_at': firstMissedAt.toIso8601String(),
      'last_missed_at': lastMissedAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'miss_count': missCount,
      'retry_count': retryCount,
      'correct_retry_count': correctRetryCount,
      'mastery_status': masteryStatus.toDbString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      // Legacy compatibility
      'mistake_count': missCount,
      'is_mastered': isMastered,
      'last_failed_at': lastMissedAt.toIso8601String(),
      'mastered_at': masteredAt?.toIso8601String(),
    };
  }

  factory MistakeRecord.fromJson(Map<String, dynamic> json) {
    final rawLastFailed = json['last_failed_at'] as String?;
    final legacyLastFailed =
        rawLastFailed != null ? DateTime.parse(rawLastFailed) : DateTime.now();

    final rawFirstMissed = json['first_missed_at'] as String?;
    final firstMissed = rawFirstMissed != null
        ? DateTime.parse(rawFirstMissed)
        : legacyLastFailed;

    final rawLastMissed = json['last_missed_at'] as String?;
    final lastMissed = rawLastMissed != null
        ? DateTime.parse(rawLastMissed)
        : legacyLastFailed;

    final rawLastAttempt = json['last_attempt_at'] as String?;
    final lastAttempt =
        rawLastAttempt != null ? DateTime.parse(rawLastAttempt) : null;

    final rawCreatedAt = json['created_at'] as String?;
    final createdAt =
        rawCreatedAt != null ? DateTime.parse(rawCreatedAt) : firstMissed;

    final rawUpdatedAt = json['updated_at'] as String?;
    final updatedAt =
        rawUpdatedAt != null ? DateTime.parse(rawUpdatedAt) : lastMissed;

    final isMasteredLegacy = json['is_mastered'] as bool? ?? false;
    final rawStatus = json['mastery_status'] as String?;
    final status = rawStatus != null
        ? MasteryStatus.fromString(rawStatus)
        : (isMasteredLegacy
            ? MasteryStatus.mastered
            : MasteryStatus.needsReview);

    final legacyCount = json['mistake_count'] as int? ?? 1;
    final missCount = json['miss_count'] as int? ?? legacyCount;

    return MistakeRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as String,
      subjectId: json['subject_id'] as String? ?? 'general',
      unitId: json['unit_id'] as String?,
      topicId: json['topic_id'] as String?,
      lastAttemptId: json['last_attempt_id'] as String?,
      lastSelectedChoiceId: json['last_selected_choice_id'] as String?,
      firstMissedAt: firstMissed,
      lastMissedAt: lastMissed,
      lastAttemptAt: lastAttempt,
      missCount: missCount,
      retryCount: json['retry_count'] as int? ?? (isMasteredLegacy ? 2 : 0),
      correctRetryCount:
          json['correct_retry_count'] as int? ?? (isMasteredLegacy ? 2 : 0),
      masteryStatus: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: json['sync_status'] as String? ?? 'synced',
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questionId,
        subjectId,
        unitId,
        topicId,
        lastAttemptId,
        lastSelectedChoiceId,
        firstMissedAt,
        lastMissedAt,
        lastAttemptAt,
        missCount,
        retryCount,
        correctRetryCount,
        masteryStatus,
        createdAt,
        updatedAt,
        syncStatus,
      ];
}

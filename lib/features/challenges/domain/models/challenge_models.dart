import 'package:equatable/equatable.dart';

enum ChallengeType {
  friend,
  sponsored;

  String get labelEn {
    switch (this) {
      case ChallengeType.friend:
        return 'Friend Duel';
      case ChallengeType.sponsored:
        return 'Sponsored Championship';
    }
  }
}

enum ChallengeStatus {
  active,
  upcoming,
  completed;
}

class ChallengeParticipant extends Equatable {
  final String userId;
  final String displayName;
  final int score;
  final int durationSeconds;
  final double percentage;
  final bool hasCompleted;
  final DateTime? completedAt;

  const ChallengeParticipant({
    required this.userId,
    required this.displayName,
    this.score = 0,
    this.durationSeconds = 0,
    this.percentage = 0.0,
    this.hasCompleted = false,
    this.completedAt,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipant(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? 'Student',
      score: json['score'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      hasCompleted: json['has_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'score': score,
      'duration_seconds': durationSeconds,
      'percentage': percentage,
      'has_completed': hasCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    userId,
    displayName,
    score,
    durationSeconds,
    percentage,
    hasCompleted,
    completedAt,
  ];
}

class Challenge extends Equatable {
  final String id;
  final String titleEn;
  final String titleAm;
  final String descriptionEn;
  final String descriptionAm;
  final ChallengeType challengeType;
  final ChallengeStatus status;
  final String subjectId;
  final String subjectName;
  final int grade;
  final int totalQuestions;
  final int timeLimitMinutes;
  final int prizeCoinPool;
  final String? sponsorName;
  final String? sponsorLogoAsset;
  final String? inviteCode;
  final List<ChallengeParticipant> participants;
  final DateTime startTime;
  final DateTime endTime;

  const Challenge({
    required this.id,
    required this.titleEn,
    required this.titleAm,
    required this.descriptionEn,
    required this.descriptionAm,
    required this.challengeType,
    required this.status,
    required this.subjectId,
    required this.subjectName,
    required this.grade,
    required this.totalQuestions,
    required this.timeLimitMinutes,
    required this.prizeCoinPool,
    this.sponsorName,
    this.sponsorLogoAsset,
    this.inviteCode,
    required this.participants,
    required this.startTime,
    required this.endTime,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      titleEn: json['title_en'] as String,
      titleAm: json['title_am'] as String? ?? json['title_en'] as String,
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionAm: json['description_am'] as String? ?? '',
      challengeType: json['challenge_type'] == 'sponsored'
          ? ChallengeType.sponsored
          : ChallengeType.friend,
      status: json['status'] == 'completed'
          ? ChallengeStatus.completed
          : (json['status'] == 'upcoming'
              ? ChallengeStatus.upcoming
              : ChallengeStatus.active),
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Mathematics',
      grade: json['grade'] as int? ?? 12,
      totalQuestions: json['total_questions'] as int? ?? 10,
      timeLimitMinutes: json['time_limit_minutes'] as int? ?? 15,
      prizeCoinPool: json['prize_coin_pool'] as int? ?? 100,
      sponsorName: json['sponsor_name'] as String?,
      sponsorLogoAsset: json['sponsor_logo_asset'] as String?,
      inviteCode: json['invite_code'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => ChallengeParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
    );
  }

  Challenge copyWith({
    List<ChallengeParticipant>? participants,
    ChallengeStatus? status,
  }) {
    return Challenge(
      id: id,
      titleEn: titleEn,
      titleAm: titleAm,
      descriptionEn: descriptionEn,
      descriptionAm: descriptionAm,
      challengeType: challengeType,
      status: status ?? this.status,
      subjectId: subjectId,
      subjectName: subjectName,
      grade: grade,
      totalQuestions: totalQuestions,
      timeLimitMinutes: timeLimitMinutes,
      prizeCoinPool: prizeCoinPool,
      sponsorName: sponsorName,
      sponsorLogoAsset: sponsorLogoAsset,
      inviteCode: inviteCode,
      participants: participants ?? this.participants,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  List<Object?> get props => [
    id,
    titleEn,
    titleAm,
    descriptionEn,
    descriptionAm,
    challengeType,
    status,
    subjectId,
    subjectName,
    grade,
    totalQuestions,
    timeLimitMinutes,
    prizeCoinPool,
    sponsorName,
    sponsorLogoAsset,
    inviteCode,
    participants,
    startTime,
    endTime,
  ];
}

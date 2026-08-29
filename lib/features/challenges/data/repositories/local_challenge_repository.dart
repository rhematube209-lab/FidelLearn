import 'dart:math';

import '../../../../core/errors/failures.dart';
import '../../domain/models/challenge_models.dart';
import '../../domain/repositories/challenge_repository.dart';

class LocalChallengeRepository implements ChallengeRepository {
  final List<Challenge> _challenges = [];

  LocalChallengeRepository() {
    _seedInitialChallenges();
  }

  void _seedInitialChallenges() {
    final now = DateTime.now();
    _challenges.addAll([
      Challenge(
        id: 'chal_sponsored_1',
        titleEn: 'Ethio Telecom STEM Cup 2026',
        titleAm: 'የኢትዮ ቴሌኮም ሳይንስ እና ቴክኖሎጂ ዋንጫ 2026',
        descriptionEn:
            'Compete nationwide in Grade 12 Advanced Mathematics. Top 50 scorers share a 5,000 Study Coin reward pool!',
        descriptionAm:
            'በ12ኛ ክፍል ከፍተኛ ሂሳብ ሀገር አቀፍ ውድድር ላይ ይሳተፉ። ከፍተኛ ውጤት ላስመዘገቡ 5,000 ሳንቲሞች ይሸለማሉ!',
        challengeType: ChallengeType.sponsored,
        status: ChallengeStatus.active,
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        grade: 12,
        totalQuestions: 10,
        timeLimitMinutes: 15,
        prizeCoinPool: 5000,
        sponsorName: 'Ethio Telecom Education Initiative',
        participants: [
          ChallengeParticipant(
            userId: 'user_bot_1',
            displayName: 'Bethlehem T.',
            score: 10,
            durationSeconds: 420,
            percentage: 100.0,
            hasCompleted: true,
            completedAt: now.subtract(const Duration(hours: 2)),
          ),
          ChallengeParticipant(
            userId: 'user_bot_2',
            displayName: 'Yonas M.',
            score: 9,
            durationSeconds: 480,
            percentage: 90.0,
            hasCompleted: true,
            completedAt: now.subtract(const Duration(hours: 5)),
          ),
        ],
        startTime: now.subtract(const Duration(days: 2)),
        endTime: now.add(const Duration(days: 5)),
      ),
      Challenge(
        id: 'chal_friend_demo',
        titleEn: 'Aptitude Speed Duel',
        titleAm: 'የአጠቃላይ ችሎታ የፍጥነት ውድድር',
        descriptionEn:
            'Timed 10-question Scholastic Aptitude challenge created by classmate Dawit.',
        descriptionAm: 'በጓደኛዎ የተዘጋጀ የ10 ጥያቄዎች የአጠቃላይ ችሎታ ውድድር።',
        challengeType: ChallengeType.friend,
        status: ChallengeStatus.active,
        subjectId: 'aptitude_g12',
        subjectName: 'Scholastic Aptitude',
        grade: 12,
        totalQuestions: 10,
        timeLimitMinutes: 10,
        prizeCoinPool: 200,
        inviteCode: 'FIDEL99',
        participants: [
          ChallengeParticipant(
            userId: 'user_dawit',
            displayName: 'Dawit K.',
            score: 8,
            durationSeconds: 340,
            percentage: 80.0,
            hasCompleted: true,
            completedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.add(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Future<List<Challenge>> getActiveChallenges({
    required int grade,
    ChallengeType? type,
  }) async {
    return _challenges.where((c) {
      if (c.grade != grade) return false;
      if (type != null && c.challengeType != type) return false;
      return c.status == ChallengeStatus.active;
    }).toList();
  }

  @override
  Future<Challenge?> getChallengeById(String challengeId) async {
    try {
      return _challenges.firstWhere((c) => c.id == challengeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Challenge?> getChallengeByInviteCode(String inviteCode) async {
    try {
      final code = inviteCode.trim().toUpperCase();
      return _challenges.firstWhere(
        (c) => c.inviteCode?.toUpperCase() == code,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Challenge> createFriendChallenge({
    required String creatorUserId,
    required String creatorName,
    required String title,
    required String subjectId,
    required String subjectName,
    required int grade,
    required int totalQuestions,
    required int timeLimitMinutes,
  }) async {
    final now = DateTime.now();
    final randomCode =
        'F${Random().nextInt(9000) + 1000}'; // e.g. F4829

    final newChallenge = Challenge(
      id: 'chal_friend_${now.millisecondsSinceEpoch}',
      titleEn: title,
      titleAm: title,
      descriptionEn: 'Friend challenge created by $creatorName',
      descriptionAm: 'በ$creatorName የተዘጋጀ የጓደኛ ውድድር',
      challengeType: ChallengeType.friend,
      status: ChallengeStatus.active,
      subjectId: subjectId,
      subjectName: subjectName,
      grade: grade,
      totalQuestions: totalQuestions,
      timeLimitMinutes: timeLimitMinutes,
      prizeCoinPool: 100,
      inviteCode: randomCode,
      participants: [
        ChallengeParticipant(
          userId: creatorUserId,
          displayName: creatorName,
        ),
      ],
      startTime: now,
      endTime: now.add(const Duration(days: 3)),
    );

    _challenges.insert(0, newChallenge);
    return newChallenge;
  }

  @override
  Future<void> joinChallenge({
    required String challengeId,
    required String userId,
    required String displayName,
  }) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) {
      throw const NotFoundFailure('Challenge not found.');
    }

    final challenge = _challenges[index];
    final alreadyJoined =
        challenge.participants.any((p) => p.userId == userId);
    if (alreadyJoined) return;

    final updatedParticipants = [
      ...challenge.participants,
      ChallengeParticipant(userId: userId, displayName: displayName),
    ];

    _challenges[index] = challenge.copyWith(participants: updatedParticipants);
  }

  @override
  Future<void> submitChallengeAttempt({
    required String challengeId,
    required String userId,
    required int score,
    required int durationSeconds,
    required double percentage,
  }) async {
    final index = _challenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return;

    final challenge = _challenges[index];
    final updatedParticipants = challenge.participants.map((p) {
      if (p.userId == userId) {
        return ChallengeParticipant(
          userId: userId,
          displayName: p.displayName,
          score: score,
          durationSeconds: durationSeconds,
          percentage: percentage,
          hasCompleted: true,
          completedAt: DateTime.now(),
        );
      }
      return p;
    }).toList();

    _challenges[index] = challenge.copyWith(participants: updatedParticipants);
  }
}

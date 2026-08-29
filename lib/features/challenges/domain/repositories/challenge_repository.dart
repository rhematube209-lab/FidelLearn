import '../models/challenge_models.dart';

abstract class ChallengeRepository {
  Future<List<Challenge>> getActiveChallenges({
    required int grade,
    ChallengeType? type,
  });
  Future<Challenge?> getChallengeById(String challengeId);
  Future<Challenge?> getChallengeByInviteCode(String inviteCode);
  Future<Challenge> createFriendChallenge({
    required String creatorUserId,
    required String creatorName,
    required String title,
    required String subjectId,
    required String subjectName,
    required int grade,
    required int totalQuestions,
    required int timeLimitMinutes,
  });
  Future<void> joinChallenge({
    required String challengeId,
    required String userId,
    required String displayName,
  });
  Future<void> submitChallengeAttempt({
    required String challengeId,
    required String userId,
    required int score,
    required int durationSeconds,
    required double percentage,
  });
}

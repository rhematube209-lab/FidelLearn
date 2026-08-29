import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/challenges/data/repositories/local_challenge_repository.dart';
import 'package:fidel_learn/features/challenges/domain/models/challenge_models.dart';

void main() {
  group('ChallengeRepository & Contest Tests', () {
    late LocalChallengeRepository repository;

    setUp(() {
      repository = LocalChallengeRepository();
    });

    test('retrieves seeded active sponsored and friend challenges', () async {
      final list = await repository.getActiveChallenges(grade: 12);
      expect(list.isNotEmpty, isTrue);

      final sponsored = await repository.getActiveChallenges(
        grade: 12,
        type: ChallengeType.sponsored,
      );
      expect(sponsored.any((c) => c.id == 'chal_sponsored_1'), isTrue);
    });

    test('creates friend challenge with invite code and creator participant', () async {
      final challenge = await repository.createFriendChallenge(
        creatorUserId: 'user_abebe',
        creatorName: 'Abebe B.',
        title: 'Calculus Duel',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        grade: 12,
        totalQuestions: 10,
        timeLimitMinutes: 15,
      );

      expect(challenge.titleEn, 'Calculus Duel');
      expect(challenge.inviteCode, isNotNull);
      expect(challenge.participants.length, 1);
      expect(challenge.participants.first.userId, 'user_abebe');

      final fetched = await repository.getChallengeByInviteCode(challenge.inviteCode!);
      expect(fetched, isNotNull);
      expect(fetched!.id, challenge.id);
    });

    test('joins challenge and records submitted participant attempt', () async {
      final challenge = await repository.createFriendChallenge(
        creatorUserId: 'user_abebe',
        creatorName: 'Abebe B.',
        title: 'Sequences Race',
        subjectId: 'math_g12',
        subjectName: 'Mathematics',
        grade: 12,
        totalQuestions: 10,
        timeLimitMinutes: 10,
      );

      // Friend joins
      await repository.joinChallenge(
        challengeId: challenge.id,
        userId: 'user_chala',
        displayName: 'Chala D.',
      );

      var updated = await repository.getChallengeById(challenge.id);
      expect(updated!.participants.length, 2);

      // Friend completes test
      await repository.submitChallengeAttempt(
        challengeId: challenge.id,
        userId: 'user_chala',
        score: 9,
        durationSeconds: 240,
        percentage: 90.0,
      );

      updated = await repository.getChallengeById(challenge.id);
      final chalaRecord = updated!.participants.firstWhere((p) => p.userId == 'user_chala');
      expect(chalaRecord.hasCompleted, isTrue);
      expect(chalaRecord.score, 9);
      expect(chalaRecord.percentage, 90.0);
    });
  });
}

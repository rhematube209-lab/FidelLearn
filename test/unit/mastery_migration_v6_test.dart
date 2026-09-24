import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/progress/data/repositories/drift_mastery_repository.dart';
import 'package:fidel_learn/features/progress/domain/models/mastery_models.dart';
import 'package:fidel_learn/features/progress/domain/services/mastery_aggregation_service.dart';
import 'package:fidel_learn/features/progress/domain/services/mastery_engine_service.dart';
import 'package:fidel_learn/features/progress/domain/services/spaced_repetition_scheduler.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';

void main() {
  group('Mastery Drift Schema Migration (v4 -> v6 & v5 -> v6) Tests', () {
    test(
        'Direct upgrade from schema v4 to v6 backfills legacy mistakes with legacyMigration provenance without fabricating review events',
        () async {
      final db = AppDatabase.inMemory();

      // Drop any existing mastery tables to simulate a clean v4 environment
      await db.customStatement('DROP TABLE IF EXISTS db_review_events');
      await db
          .customStatement('DROP TABLE IF EXISTS db_learning_target_mastery');
      await db.customStatement('DROP TABLE IF EXISTS db_question_mastery');
      await db.customStatement('DROP TABLE IF EXISTS db_mistakes');

      // 1. Create v4 schema for db_mistakes
      await db.customStatement('''
        CREATE TABLE db_mistakes (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          subject_id TEXT NOT NULL,
          unit_id TEXT,
          topic_id TEXT,
          selected_choice_id TEXT NOT NULL,
          mistake_count INTEGER NOT NULL DEFAULT 1,
          miss_count INTEGER NOT NULL DEFAULT 1,
          retry_count INTEGER NOT NULL DEFAULT 0,
          correct_retry_count INTEGER NOT NULL DEFAULT 0,
          is_mastered INTEGER NOT NULL DEFAULT 0,
          mastery_status TEXT NOT NULL DEFAULT 'needsReview',
          last_failed_at INTEGER,
          first_missed_at INTEGER,
          last_missed_at INTEGER,
          last_attempt_at INTEGER,
          mastered_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');

      // 2. Insert one resolved mistake and one unresolved mistake
      final nowEpoch = DateTime.utc(2026, 9, 20, 10, 0).millisecondsSinceEpoch;
      await db.customStatement('''
        INSERT INTO db_mistakes (
          id, user_id, question_id, subject_id, unit_id, topic_id,
          selected_choice_id, mistake_count, miss_count, retry_count,
          correct_retry_count, is_mastered, mastery_status,
          last_failed_at, last_missed_at, last_attempt_at, mastered_at,
          sync_status, created_at, updated_at
        ) VALUES
        ('m_res_1', 'u_test', 'q_resolved', 'physics_g12', 'u1', 't1', 'c2', 2, 2, 2, 2, 1, 'mastered', $nowEpoch, $nowEpoch, $nowEpoch, $nowEpoch, 'synced', $nowEpoch, $nowEpoch),
        ('m_unres_2', 'u_test', 'q_unresolved', 'physics_g12', 'u1', 't1', 'c1', 1, 1, 0, 0, 0, 'needsReview', $nowEpoch, $nowEpoch, NULL, NULL, 'synced', $nowEpoch, $nowEpoch);
      ''');

      // 3. Execute migration from schema v4 to v6
      final migrator = db.createMigrator();
      await db.migration.onUpgrade(migrator, 4, 6);

      // 4. Verify backfilled records in db_question_mastery
      final repo = DriftMasteryRepository(db: db);

      final resolvedMastery =
          await repo.getQuestionMastery('u_test', 'q_resolved');
      expect(resolvedMastery, isNotNull);
      expect(resolvedMastery!.masteryState, equals(MasteryState.mastered));
      expect(resolvedMastery.evidenceSource,
          equals(EvidenceSource.legacyMigration));
      expect(resolvedMastery.stability, equals(3.0));

      final unresolvedMastery =
          await repo.getQuestionMastery('u_test', 'q_unresolved');
      expect(unresolvedMastery, isNotNull);
      expect(unresolvedMastery!.masteryState, equals(MasteryState.learning));
      expect(unresolvedMastery.evidenceSource,
          equals(EvidenceSource.legacyMigration));
      expect(unresolvedMastery.stability, equals(1.0));

      // 5. Verify NO fabricated review events exist in db_review_events
      final events = await repo.getReviewEvents('u_test');
      expect(events, isEmpty);

      // 6. Simulate real review: converts legacyMigration to native
      final engine = MasteryEngineService(
        masteryRepo: repo,
        scheduler: const SpacedRepetitionScheduler(),
        aggregationService: const MasteryAggregationService(),
      );

      const q = Question(
        id: 'q_resolved',
        grade: 12,
        stream: 'natural',
        subjectId: 'physics_g12',
        unitId: 'u1',
        topicId: 't1',
        questionTextEn: 'Verify circuit resistance',
        difficulty: 'medium',
        verificationStatus: VerificationStatus.verified,
        sourceName: 'seed',
        contentVersion: 1,
        choices: [],
        explanation: Explanation(solutionTextEn: 'Direct sum.'),
      );

      final reviewTime = DateTime.utc(2026, 9, 24, 15, 0);
      final updated = await engine.processQuestionOutcome(
        userId: 'u_test',
        question: q,
        isCorrect: true,
        attemptId: 'att_rev_1',
        eventTime: reviewTime,
      );

      expect(updated.evidenceSource, equals(EvidenceSource.native));
      final reloaded = await repo.getQuestionMastery('u_test', 'q_resolved');
      expect(reloaded!.evidenceSource, equals(EvidenceSource.native));

      // Audit log event now exists with subject and question
      final reviewEventsAfter = await repo.getReviewEvents('u_test');
      expect(reviewEventsAfter.length, equals(1));
      expect(reviewEventsAfter.first.questionId, equals('q_resolved'));
      expect(reviewEventsAfter.first.subjectId, equals('physics_g12'));

      await db.close();
    });
  });
}

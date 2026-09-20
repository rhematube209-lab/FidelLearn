import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/mistakes/domain/models/mistake_model.dart';

void main() {
  group('Mistake Notebook Schema Migration, Backfill & Offline Restart', () {
    test(
        'Migration from schema v1 to v2 backfills legacy fields preserving historic timestamps',
        () async {
      final db = AppDatabase.inMemory();

      // Simulate legacy V1 table structure and insert legacy records
      await db.customStatement('DROP TABLE IF EXISTS db_mistakes');
      await db.customStatement('''
        CREATE TABLE db_mistakes (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          subject_id TEXT NOT NULL,
          mistake_count INTEGER NOT NULL DEFAULT 1,
          is_mastered INTEGER NOT NULL DEFAULT 0,
          last_failed_at INTEGER NOT NULL,
          mastered_at INTEGER
        )
      ''');

      final historicTime = DateTime(2025, 3, 15, 10, 30);
      final historicEpoch = historicTime.millisecondsSinceEpoch ~/ 1000;
      final historicMasteredTime = DateTime(2025, 4, 1, 14, 0);
      final historicMasteredEpoch =
          historicMasteredTime.millisecondsSinceEpoch ~/ 1000;

      // Legacy unmastered record
      await db.customStatement('''
        INSERT INTO db_mistakes (id, user_id, question_id, subject_id, mistake_count, is_mastered, last_failed_at)
        VALUES ('legacy_1', 'user_abc', 'q_1', 'math_g12', 4, 0, $historicEpoch)
      ''');

      // Legacy mastered record
      await db.customStatement('''
        INSERT INTO db_mistakes (id, user_id, question_id, subject_id, mistake_count, is_mastered, last_failed_at, mastered_at)
        VALUES ('legacy_2', 'user_abc', 'q_2', 'bio_g12', 2, 1, $historicEpoch, $historicMasteredEpoch)
      ''');

      // Run migration to v2
      final migrator = db.createMigrator();
      await db.migration.onUpgrade(migrator, 1, 2);

      final repo = DriftMistakeRepository(db: db);
      final mistakes = await repo.getMistakes('user_abc');

      expect(mistakes.length, equals(2));

      // Verify unmastered record backfill
      final unmastered = mistakes.firstWhere((m) => m.questionId == 'q_1');
      expect(unmastered.missCount, equals(4));
      expect(unmastered.masteryStatus, equals(MasteryStatus.needsReview));
      expect(unmastered.isMastered, isFalse);
      expect(unmastered.correctRetryCount, equals(0));
      expect(unmastered.firstMissedAt.year, equals(2025));
      expect(unmastered.firstMissedAt.month, equals(3));
      expect(unmastered.firstMissedAt.day, equals(15));

      // Verify mastered record backfill
      final mastered = mistakes.firstWhere((m) => m.questionId == 'q_2');
      expect(mastered.missCount, equals(2));
      expect(mastered.masteryStatus, equals(MasteryStatus.mastered));
      expect(mastered.isMastered, isTrue);
      expect(mastered.correctRetryCount, equals(2));
      expect(mastered.firstMissedAt.year, equals(2025));

      await db.close();
    });

    test('State survives database reload / app restart without loss', () async {
      // In-memory test using repository methods
      final db = AppDatabase.inMemory();
      final repo = DriftMistakeRepository(db: db);

      await repo.recordMistake(
        userId: 'student_offline',
        questionId: 'q_chem_1',
        subjectId: 'chem_g12',
        attemptId: 'att_init',
      );
      await repo.recordRetryResult(
        userId: 'student_offline',
        questionId: 'q_chem_1',
        isCorrect: true,
        attemptId: 'att_retry_1',
      );

      final beforeReload = await repo.getMistakeById(
        userId: 'student_offline',
        questionId: 'q_chem_1',
      );
      expect(beforeReload!.masteryStatus, equals(MasteryStatus.improving));
      expect(beforeReload.retryCount, equals(1));
      expect(beforeReload.correctRetryCount, equals(1));

      // Query again directly through new repository instance wrapping same connection
      final reloadedRepo = DriftMistakeRepository(db: db);
      final afterReload = await reloadedRepo.getMistakeById(
        userId: 'student_offline',
        questionId: 'q_chem_1',
      );

      expect(afterReload, isNotNull);
      expect(afterReload!.masteryStatus, equals(MasteryStatus.improving));
      expect(afterReload.retryCount, equals(1));
      expect(afterReload.correctRetryCount, equals(1));
      expect(afterReload.lastAttemptId, equals('att_retry_1'));

      await db.close();
    });
  });
}

import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  DbExamAttempts,
  DbActiveAttempts,
  DbBookmarks,
  DbMistakes,
  DbCoinLedger,
  DbSyncQueue,
  DbStudyPlans,
  DbStudyPlanSessions,
  DbQuestionMastery,
  DbLearningTargetMastery,
  DbReviewEvents,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.constructDb());

  factory AppDatabase.inMemory() {
    return AppDatabase(impl.constructInMemoryDb());
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          Future<bool> columnExists(String tableName, String columnName) async {
            try {
              final result =
                  await customSelect('PRAGMA table_info("$tableName")').get();
              return result.any((row) =>
                  row.read<String>('name').toLowerCase() ==
                  columnName.toLowerCase());
            } catch (_) {
              return false;
            }
          }

          Future<void> safeAddColumn(
              TableInfo<Table, Object?> table, GeneratedColumn column) async {
            try {
              final exists =
                  await columnExists(table.actualTableName, column.$name);
              if (exists) return;
            } catch (_) {}

            try {
              await m.addColumn(table, column);
            } catch (e) {
              final errStr = e.toString().toLowerCase();
              if (!errStr.contains('duplicate column') &&
                  !errStr.contains('already exists')) {
                rethrow;
              }
            }
          }

          Future<void> safeCreateTable(TableInfo<Table, Object?> table) async {
            try {
              await m.createTable(table);
            } catch (e) {
              final errStr = e.toString().toLowerCase();
              if (!errStr.contains('already exists')) {
                rethrow;
              }
            }
          }

          if (from < 2 && to >= 2) {
            await safeAddColumn(dbMistakes, dbMistakes.unitId);
            await safeAddColumn(dbMistakes, dbMistakes.topicId);
            await safeAddColumn(dbMistakes, dbMistakes.lastAttemptId);
            await safeAddColumn(dbMistakes, dbMistakes.lastSelectedChoiceId);
            await safeAddColumn(dbMistakes, dbMistakes.firstMissedAt);
            await safeAddColumn(dbMistakes, dbMistakes.lastMissedAt);
            await safeAddColumn(dbMistakes, dbMistakes.lastAttemptAt);
            await safeAddColumn(dbMistakes, dbMistakes.missCount);
            await safeAddColumn(dbMistakes, dbMistakes.retryCount);
            await safeAddColumn(dbMistakes, dbMistakes.correctRetryCount);
            await safeAddColumn(dbMistakes, dbMistakes.masteryStatus);
            await safeAddColumn(dbMistakes, dbMistakes.createdAt);
            await safeAddColumn(dbMistakes, dbMistakes.updatedAt);
            await safeAddColumn(dbMistakes, dbMistakes.syncStatus);

            // Backfill existing records preserving historic timestamps
            await customStatement('''
              UPDATE db_mistakes SET
                miss_count = mistake_count,
                mastery_status = CASE WHEN is_mastered = 1 THEN 'mastered' ELSE 'needsReview' END,
                first_missed_at = last_failed_at,
                last_missed_at = last_failed_at,
                created_at = last_failed_at,
                updated_at = COALESCE(mastered_at, last_failed_at),
                correct_retry_count = CASE WHEN is_mastered = 1 THEN 2 ELSE 0 END,
                retry_count = CASE WHEN is_mastered = 1 THEN 2 ELSE 0 END,
                sync_status = 'synced'
              WHERE last_failed_at IS NOT NULL
            ''');

            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_db_mistakes_user_question ON db_mistakes(user_id, question_id)',
            );
          }

          if (from < 3 && to >= 3) {
            await safeCreateTable(dbStudyPlans);
            await safeCreateTable(dbStudyPlanSessions);
          }

          if (from < 4 && to >= 4) {
            if (from >= 3) {
              await safeAddColumn(
                  dbStudyPlanSessions, dbStudyPlanSessions.examVariant);
              await safeAddColumn(
                  dbStudyPlanSessions, dbStudyPlanSessions.assessmentStructure);
              await safeAddColumn(
                  dbStudyPlanSessions, dbStudyPlanSessions.contentDomain);
              await safeAddColumn(
                  dbStudyPlanSessions, dbStudyPlanSessions.skill);
            }

            // Safe legacy migration from v3 -> v4:
            // For unambiguous subjects, backfill assessment structure and variant.
            // Ambiguous Mathematics sessions are safely left NULL for safe handling.
            await customStatement('''
              UPDATE db_study_plan_sessions SET
                assessment_structure = CASE
                  WHEN subject_id LIKE '%apt%' THEN 'skillBased'
                  WHEN subject_id LIKE '%eng%' THEN 'mixed'
                  ELSE 'curriculum'
                END,
                exam_variant = CASE
                  WHEN subject_id LIKE '%eng%' OR subject_id LIKE '%apt%' THEN 'shared'
                  WHEN subject_id LIKE '%bio%' OR subject_id LIKE '%phys%' OR subject_id LIKE '%chem%' THEN 'naturalScience'
                  WHEN subject_id LIKE '%hist%' OR subject_id LIKE '%geo%' OR subject_id LIKE '%econ%' THEN 'socialScience'
                  ELSE NULL
                END
              WHERE assessment_structure IS NULL
            ''');
          }

          if (from < 5 && to >= 5) {
            await safeCreateTable(dbQuestionMastery);
            await safeCreateTable(dbLearningTargetMastery);
            await safeCreateTable(dbReviewEvents);

            // Performance and review queue indexes
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_question_mastery_user_subject ON db_question_mastery(user_id, subject_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_question_mastery_next_review ON db_question_mastery(user_id, next_review_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_target_mastery_user_subject ON db_learning_target_mastery(user_id, subject_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_target_mastery_next_review ON db_learning_target_mastery(user_id, next_review_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_review_events_user ON db_review_events(user_id, reviewed_at)',
            );

            // Non-destructive initial backfill:
            // Seed question mastery from existing mistake records so student history is preserved.
            await customStatement('''
              INSERT OR IGNORE INTO db_question_mastery (
                id, user_id, question_id, subject_id, unit_id, topic_id,
                mastery_state, attempt_count, correct_count, incorrect_count,
                consecutive_correct, stability, difficulty, review_count, lapse_count,
                last_seen_at, last_correct_at, last_incorrect_at, next_review_at,
                algorithm_version, evidence_source, updated_at
              )
              SELECT
                user_id || '_' || question_id,
                user_id,
                question_id,
                subject_id,
                unit_id,
                topic_id,
                CASE WHEN mastery_status = 'mastered' THEN 'mastered' ELSE 'learning' END,
                (miss_count + retry_count),
                correct_retry_count,
                miss_count,
                correct_retry_count,
                CASE WHEN mastery_status = 'mastered' THEN 3.0 ELSE 1.0 END,
                2.0,
                CASE WHEN mastery_status = 'mastered' THEN 2 ELSE 0 END,
                0,
                COALESCE(last_attempt_at, last_missed_at),
                CASE WHEN correct_retry_count > 0 THEN COALESCE(last_attempt_at, updated_at) ELSE NULL END,
                last_missed_at,
                -- Spaced review date backfill: 3 days for mastered, 1 day for learning
                datetime(COALESCE(updated_at, last_missed_at, 'now'), CASE WHEN mastery_status = 'mastered' THEN '+3 days' ELSE '+1 day' END),
                'mastery_engine_v1.0',
                'legacy_migration',
                COALESCE(updated_at, last_missed_at, 'now')
              FROM db_mistakes
              WHERE user_id IS NOT NULL AND question_id IS NOT NULL;
            ''');
          }

          if (from < 6 && to >= 6) {
            if (from >= 5) {
              await safeAddColumn(
                  dbQuestionMastery, dbQuestionMastery.evidenceSource);
              await safeAddColumn(dbLearningTargetMastery,
                  dbLearningTargetMastery.evidenceSource);
              await safeAddColumn(dbReviewEvents, dbReviewEvents.subjectId);
              await safeAddColumn(dbReviewEvents, dbReviewEvents.examVariant);
            }

            // Ensure any legacy migrated mastery rows carry the legacy_migration provenance
            await customStatement('''
              UPDATE db_question_mastery SET evidence_source = 'legacy_migration'
              WHERE id IN (
                SELECT user_id || '_' || question_id FROM db_mistakes
              );
            ''');
          }
        },
      );
}

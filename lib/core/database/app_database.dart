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
          if (from < 2 && to >= 2) {
            await m.addColumn(dbMistakes, dbMistakes.unitId);
            await m.addColumn(dbMistakes, dbMistakes.topicId);
            await m.addColumn(dbMistakes, dbMistakes.lastAttemptId);
            await m.addColumn(dbMistakes, dbMistakes.lastSelectedChoiceId);
            await m.addColumn(dbMistakes, dbMistakes.firstMissedAt);
            await m.addColumn(dbMistakes, dbMistakes.lastMissedAt);
            await m.addColumn(dbMistakes, dbMistakes.lastAttemptAt);
            await m.addColumn(dbMistakes, dbMistakes.missCount);
            await m.addColumn(dbMistakes, dbMistakes.retryCount);
            await m.addColumn(dbMistakes, dbMistakes.correctRetryCount);
            await m.addColumn(dbMistakes, dbMistakes.masteryStatus);
            await m.addColumn(dbMistakes, dbMistakes.createdAt);
            await m.addColumn(dbMistakes, dbMistakes.updatedAt);
            await m.addColumn(dbMistakes, dbMistakes.syncStatus);

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
            await m.createTable(dbStudyPlans);
            await m.createTable(dbStudyPlanSessions);
          }

          if (from < 4 && to >= 4) {
            await m.addColumn(
                dbStudyPlanSessions, dbStudyPlanSessions.examVariant);
            await m.addColumn(
                dbStudyPlanSessions, dbStudyPlanSessions.assessmentStructure);
            await m.addColumn(
                dbStudyPlanSessions, dbStudyPlanSessions.contentDomain);
            await m.addColumn(dbStudyPlanSessions, dbStudyPlanSessions.skill);

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
            await m.createTable(dbQuestionMastery);
            await m.createTable(dbLearningTargetMastery);
            await m.createTable(dbReviewEvents);

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
              await m.addColumn(
                  dbQuestionMastery, dbQuestionMastery.evidenceSource);
              await m.addColumn(dbLearningTargetMastery,
                  dbLearningTargetMastery.evidenceSource);
              await m.addColumn(dbReviewEvents, dbReviewEvents.subjectId);
              await m.addColumn(dbReviewEvents, dbReviewEvents.examVariant);
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

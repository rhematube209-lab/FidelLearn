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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.constructDb());

  factory AppDatabase.inMemory() {
    return AppDatabase(impl.constructInMemoryDb());
  }

  @override
  int get schemaVersion => 4;

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
        },
      );
}

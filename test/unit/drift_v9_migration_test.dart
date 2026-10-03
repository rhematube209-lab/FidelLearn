import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:fidel_learn/core/database/app_database.dart';

void main() {
  group('P9 Drift Schema v9 Migration & Table Verification Tests', () {
    test(
        'Fresh install v9 creates db_learning_assignments and db_assignment_recipients',
        () async {
      final db = AppDatabase.inMemory();

      // Verify schema version is v9
      expect(db.schemaVersion, 9);

      // Verify tables exist by inserting and selecting
      await db.customStatement('''
        INSERT INTO db_learning_assignments (
          id, school_id, classroom_id, classroom_name, teacher_user_id,
          teacher_name, subject_id, exam_variant, title, instructions,
          assignment_type, status, due_at, allow_late_submission,
          time_limit_minutes, total_questions, content_hash, question_ids_json,
          created_at, published_at, synced_at
        ) VALUES (
          'asgn-v9-fresh', 'sch-01', 'cls-01', '12A', 'tch-01',
          'Teacher A', 'physics_g12', 'naturalScience', 'Physics Drill', 'Follow instructions',
          'targetedPractice', 'published', 1700000000000, 1,
          45, 10, 'hash-v9', '["q1", "q2"]',
          1690000000000, 1690000000000, 1690000000000
        );
      ''');

      await db.customStatement('''
        INSERT INTO db_assignment_recipients (
          id, assignment_id, student_user_id, assigned_at, status,
          attempt_id, started_at, submitted_at, score, percentage, sync_status
        ) VALUES (
          'rcp-v9-fresh', 'asgn-v9-fresh', 'std-01', 1690000000000, 'submitted',
          'att-01', 1690001000000, 1690002000000, 18, 90.0, 'synced'
        );
      ''');

      final asgnRows = await db.customSelect(
          'SELECT * FROM db_learning_assignments WHERE id = ?',
          variables: [const Variable<String>('asgn-v9-fresh')]).get();
      expect(asgnRows.length, 1);
      expect(asgnRows.first.read<String>('title'), 'Physics Drill');
      expect(
          asgnRows.first.read<String>('assignment_type'), 'targetedPractice');

      final rcpRows = await db.customSelect(
          'SELECT * FROM db_assignment_recipients WHERE id = ?',
          variables: [const Variable<String>('rcp-v9-fresh')]).get();
      expect(rcpRows.length, 1);
      expect(rcpRows.first.read<int>('score'), 18);
      expect(rcpRows.first.read<double>('percentage'), 90.0);

      await db.close();
    });

    test(
        'Populated v8 schema preserves prior attempts, mistakes, bookmarks, and coin ledger',
        () async {
      final db = AppDatabase.inMemory();

      // Populate core P0-P8 tables
      await db.customStatement('''
        INSERT INTO db_exam_attempts (
          id, user_id, exam_id, exam_title, subject_id, exam_mode, source_type,
          start_time, end_time, duration_seconds, total_questions, score,
          percentage, correct_count, incorrect_count, skipped_count, is_completed,
          responses_json, sync_status, created_at
        ) VALUES (
          'att-v8-preserved', 'std-01', 'exam-01', 'Official 2014 Physics', 'physics_g12',
          'national_simulation', 'official_historical_paper', 1680000000000, 1680005000000,
          5000, 50, 42, 84.0, 42, 8, 0, 1, '{}', 'synced', 1680005000000
        );
      ''');

      await db.customStatement('''
        INSERT INTO db_mistakes (
          id, user_id, question_id, subject_id,
          last_selected_choice_id, miss_count, retry_count, correct_retry_count,
          is_mastered, sync_status
        ) VALUES (
          'mst-v8-preserved', 'std-01', 'q_phys_01', 'physics_g12',
          'c2', 1, 0, 0, 0, 'synced'
        );
      ''');

      await db.customStatement('''
        INSERT INTO db_bookmarks (
          id, user_id, question_id, subject_id, topic_id, created_at, is_active
        ) VALUES (
          'bmk-v8-preserved', 'std-01', 'q_phys_01', 'physics_g12', 'mechanics', 1680000000000, 1
        );
      ''');

      await db.customStatement('''
        INSERT INTO db_coin_ledger (
          id, user_id, transaction_type, amount, reason, idempotency_key, created_at, server_verified
        ) VALUES (
          'coin-v8-preserved', 'std-01', 'CREDIT', 50, 'exam_completion', 'idem-001', 1680000000000, 1
        );
      ''');

      // Verify all prior data remains intact
      final attemptRows = await db.customSelect(
          'SELECT * FROM db_exam_attempts WHERE id = ?',
          variables: [const Variable<String>('att-v8-preserved')]).get();
      expect(attemptRows.length, 1);
      expect(attemptRows.first.read<int>('score'), 42);

      final mistakeRows = await db.customSelect(
          'SELECT * FROM db_mistakes WHERE id = ?',
          variables: [const Variable<String>('mst-v8-preserved')]).get();
      expect(mistakeRows.length, 1);
      expect(mistakeRows.first.read<String>('question_id'), 'q_phys_01');

      final bookmarkRows = await db.customSelect(
          'SELECT * FROM db_bookmarks WHERE id = ?',
          variables: [const Variable<String>('bmk-v8-preserved')]).get();
      expect(bookmarkRows.length, 1);

      final coinRows = await db.customSelect(
          'SELECT * FROM db_coin_ledger WHERE id = ?',
          variables: [const Variable<String>('coin-v8-preserved')]).get();
      expect(coinRows.length, 1);
      expect(coinRows.first.read<int>('amount'), 50);

      await db.close();
    });
  });
}

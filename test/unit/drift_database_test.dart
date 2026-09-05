import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/core/database/app_database.dart';
import 'package:fidel_learn/core/errors/failures.dart';
import 'package:fidel_learn/core/sync/repositories/drift_sync_queue_repository.dart';
import 'package:fidel_learn/features/bookmarks/data/repositories/drift_bookmark_repository.dart';
import 'package:fidel_learn/features/exams/data/repositories/drift_exam_repository.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/drift_mistake_repository.dart';
import 'package:fidel_learn/features/rewards/data/repositories/drift_coin_ledger_repository.dart';
import 'package:fidel_learn/features/rewards/domain/models/coin_ledger_entry.dart';

void main() {
  group('Drift SQLite Database & Repositories Tests', () {
    late AppDatabase db;
    late DriftSyncQueueRepository queueRepo;
    late DriftExamRepository examRepo;
    late DriftBookmarkRepository bookmarkRepo;
    late DriftMistakeRepository mistakeRepo;
    late DriftCoinLedgerRepository coinRepo;

    setUp(() {
      db = AppDatabase.inMemory();
      queueRepo = DriftSyncQueueRepository(db);
      examRepo = DriftExamRepository(db: db, syncQueue: queueRepo);
      bookmarkRepo = DriftBookmarkRepository(db: db, syncQueue: queueRepo);
      mistakeRepo = DriftMistakeRepository(db: db, syncQueue: queueRepo);
      coinRepo = DriftCoinLedgerRepository(db: db, syncQueue: queueRepo);
    });

    tearDown(() async {
      await db.close();
    });

    group('DriftExamRepository', () {
      test('auto-saves active attempt and restores it', () async {
        final attempt = ExamAttempt(
          id: 'attempt_active_1',
          examId: 'exam_bio_2013',
          examTitle: 'Biology 2013 National Exam',
          subjectId: 'biology',
          userId: 'student_123',
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          durationSeconds: 1500,
          totalQuestions: 10,
          score: 0,
          percentage: 0.0,
          correctCount: 0,
          incorrectCount: 0,
          skippedCount: 10,
          isCompleted: false,
          responses: const {
            'q1': UserResponse(
                questionId: 'q1', selectedChoiceId: 'c1', isCorrect: true),
          },
        );

        await examRepo.saveActiveAttempt(attempt);

        final restored = await examRepo.getActiveAttempt('student_123');
        expect(restored, isNotNull);
        expect(restored!.id, 'attempt_active_1');
        expect(restored.examTitle, 'Biology 2013 National Exam');
        expect(restored.responses.containsKey('q1'), isTrue);
        expect(restored.durationSeconds, 1500);

        await examRepo.clearActiveAttempt('student_123');
        final deleted = await examRepo.getActiveAttempt('student_123');
        expect(deleted, isNull);
      });

      test('saves completed attempt and queries history', () async {
        final finished = ExamAttempt(
          id: 'attempt_comp_1',
          examId: 'exam_bio_2013',
          examTitle: 'Biology 2013 National Exam',
          subjectId: 'biology',
          userId: 'student_123',
          startTime: DateTime.now().subtract(const Duration(minutes: 60)),
          endTime: DateTime.now(),
          durationSeconds: 3600,
          totalQuestions: 100,
          score: 85,
          percentage: 85.0,
          correctCount: 85,
          incorrectCount: 15,
          skippedCount: 0,
          isCompleted: true,
          responses: const {},
        );

        await examRepo.saveCompletedAttempt(finished);

        final history = await examRepo.getAttemptHistory('student_123');
        expect(history.length, 1);
        expect(history.first.score, 85);
        expect(history.first.isCompleted, true);

        final single = await examRepo.getAttemptById('attempt_comp_1');
        expect(single, isNotNull);
        expect(single!.score, 85);

        // Also verify sync queue has an enqueued submitAttempt operation
        final pending = await queueRepo.getPendingOperations();
        expect(
            pending.any((op) => op.idempotencyKey == 'attempt_attempt_comp_1'),
            isTrue);
      });
    });

    group('DriftBookmarkRepository', () {
      test('toggles bookmark on and off with persistence', () async {
        expect(
          await bookmarkRepo.isBookmarked(
              userId: 'student_123', questionId: 'q_101'),
          isFalse,
        );

        await bookmarkRepo.toggleBookmark(
          userId: 'student_123',
          questionId: 'q_101',
          subjectId: 'biology',
          topicId: 'genetics',
        );

        expect(
          await bookmarkRepo.isBookmarked(
              userId: 'student_123', questionId: 'q_101'),
          isTrue,
        );
        final list1 = await bookmarkRepo.getBookmarks('student_123');
        expect(list1.length, 1);
        expect(list1.first.questionId, 'q_101');
        expect(list1.first.isActive, isTrue);

        // Toggle off
        await bookmarkRepo.toggleBookmark(
          userId: 'student_123',
          questionId: 'q_101',
          subjectId: 'biology',
          topicId: 'genetics',
        );

        expect(
          await bookmarkRepo.isBookmarked(
              userId: 'student_123', questionId: 'q_101'),
          isFalse,
        );
        final list2 = await bookmarkRepo.getBookmarks('student_123');
        expect(list2, isEmpty);
      });
    });

    group('DriftMistakeRepository', () {
      test('records mistake, increments count, and marks mastered', () async {
        await mistakeRepo.recordMistake(
          userId: 'student_123',
          questionId: 'q_chem_5',
          subjectId: 'chemistry',
        );

        var mistakes =
            await mistakeRepo.getMistakes('student_123', onlyUnmastered: false);
        expect(mistakes.length, 1);
        expect(mistakes.first.mistakeCount, 1);
        expect(mistakes.first.isMastered, isFalse);

        // Record again -> count increments to 2
        await mistakeRepo.recordMistake(
          userId: 'student_123',
          questionId: 'q_chem_5',
          subjectId: 'chemistry',
        );

        mistakes =
            await mistakeRepo.getMistakes('student_123', onlyUnmastered: false);
        expect(mistakes.first.mistakeCount, 2);

        // Mark mastered
        await mistakeRepo.markMastered(
          userId: 'student_123',
          questionId: 'q_chem_5',
        );

        // Unmastered query should now be empty
        final unmastered =
            await mistakeRepo.getMistakes('student_123', onlyUnmastered: true);
        expect(unmastered, isEmpty);

        // All mistakes query shows mastered
        final all =
            await mistakeRepo.getMistakes('student_123', onlyUnmastered: false);
        expect(all.first.isMastered, isTrue);
      });
    });

    group('DriftCoinLedgerRepository', () {
      test('enforces append-only ledger and computes balance', () async {
        final credit = CoinLedgerEntry(
          id: 'tx_1',
          userId: 'student_123',
          transactionType: CoinTransactionType.credit,
          amount: 100,
          reason: 'Signup Bonus',
          idempotencyKey: 'bonus_student_123',
          createdAt: DateTime.now(),
        );

        await coinRepo.appendEntry(credit);

        final balance1 = await coinRepo.getBalance('student_123');
        expect(balance1, 100);

        final debit = CoinLedgerEntry(
          id: 'tx_2',
          userId: 'student_123',
          transactionType: CoinTransactionType.debit,
          amount: 40,
          reason: 'Airtime Redemption',
          idempotencyKey: 'airtime_student_123',
          createdAt: DateTime.now(),
        );

        await coinRepo.appendEntry(debit);

        final balance2 = await coinRepo.getBalance('student_123');
        expect(balance2, 60);
      });

      test('throws InsufficientCoinsFailure when debit exceeds balance',
          () async {
        final debit = CoinLedgerEntry(
          id: 'tx_overshoot',
          userId: 'student_123',
          transactionType: CoinTransactionType.debit,
          amount: 50,
          reason: 'Excessive debit',
          idempotencyKey: 'overshoot_key',
          createdAt: DateTime.now(),
        );

        expect(
          () => coinRepo.appendEntry(debit),
          throwsA(isA<InsufficientCoinsFailure>()),
        );
      });

      test('throws DuplicateRewardClaimFailure when idempotency key repeats',
          () async {
        final entry1 = CoinLedgerEntry(
          id: 'tx_dup_1',
          userId: 'student_123',
          transactionType: CoinTransactionType.credit,
          amount: 25,
          reason: 'Daily streak',
          idempotencyKey: 'streak_20260905',
          createdAt: DateTime.now(),
        );

        final entry2 = CoinLedgerEntry(
          id: 'tx_dup_2',
          userId: 'student_123',
          transactionType: CoinTransactionType.credit,
          amount: 25,
          reason: 'Daily streak repeated',
          idempotencyKey: 'streak_20260905',
          createdAt: DateTime.now(),
        );

        await coinRepo.appendEntry(entry1);

        expect(
          () => coinRepo.appendEntry(entry2),
          throwsA(isA<DuplicateRewardClaimFailure>()),
        );
      });
    });
  });
}

import 'package:drift/drift.dart';

/// SQLite table for storing completed and scored exam attempts
@DataClassName('DbExamAttempt')
class DbExamAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get examId => text()();
  TextColumn get examTitle => text()();
  TextColumn get subjectId => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  IntColumn get score => integer().withDefault(const Constant(0))();
  RealColumn get percentage => real().withDefault(const Constant(0.0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get skippedCount => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(
      const Constant('synced'))(); // 'synced' | 'pending' | 'failed'
  TextColumn get responsesJson =>
      text()(); // Serialized Map<String, UserResponse>
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for in-progress active attempts (auto-save / crash recovery)
@DataClassName('DbActiveAttempt')
class DbActiveAttempts extends Table {
  TextColumn get userId => text()();
  TextColumn get attemptJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

/// SQLite table for offline bookmarked questions
@DataClassName('DbBookmark')
class DbBookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get questionId => text()();
  TextColumn get subjectId => text()();
  TextColumn get topicId => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for mistake notebook and mastery tracker
@DataClassName('DbMistake')
class DbMistakes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get questionId => text()();
  TextColumn get subjectId => text()();
  IntColumn get mistakeCount => integer().withDefault(const Constant(1))();
  BoolColumn get isMastered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastFailedAt => dateTime()();
  DateTimeColumn get masteredAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite append-only ledger for Study Coins
@DataClassName('DbCoinLedgerEntry')
class DbCoinLedger extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get transactionType => text()(); // 'CREDIT' | 'DEBIT'
  IntColumn get amount => integer()(); // Strictly positive
  TextColumn get reason => text()();
  TextColumn get relatedEntityId => text().nullable()();
  TextColumn get idempotencyKey => text().customConstraint('UNIQUE NOT NULL')();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get serverVerified =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for pending offline sync queue operations
@DataClassName('DbSyncQueueItem')
class DbSyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text().customConstraint('UNIQUE NOT NULL')();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

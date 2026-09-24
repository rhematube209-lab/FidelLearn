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
  TextColumn get unitId => text().nullable()();
  TextColumn get topicId => text().nullable()();

  TextColumn get lastAttemptId => text().nullable()();
  TextColumn get lastSelectedChoiceId => text().nullable()();

  DateTimeColumn get firstMissedAt => dateTime().nullable()();
  DateTimeColumn get lastMissedAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  IntColumn get missCount => integer().withDefault(const Constant(1))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get correctRetryCount => integer().withDefault(const Constant(0))();

  TextColumn get masteryStatus => text().withDefault(const Constant(
      'needsReview'))(); // 'needsReview' | 'improving' | 'mastered'

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(
      const Constant('synced'))(); // 'synced' | 'pending' | 'failed'

  // Legacy columns kept for database backward compatibility
  IntColumn get mistakeCount => integer().withDefault(const Constant(1))();
  BoolColumn get isMastered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastFailedAt => dateTime().nullable()();
  DateTimeColumn get masteredAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, questionId},
      ];
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

/// SQLite table for daily personalized study plans
@DataClassName('DbStudyPlan')
class DbStudyPlans extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get planDate => dateTime()();
  IntColumn get targetMinutes => integer().withDefault(const Constant(45))();
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(45))();
  TextColumn get status => text().withDefault(const Constant(
      'not_started'))(); // 'not_started' | 'in_progress' | 'completed' | 'skipped'
  TextColumn get algorithmVersion =>
      text().withDefault(const Constant('adaptive_planner_v1'))();
  DateTimeColumn get generatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for sessions within a daily study plan
@DataClassName('DbStudyPlanSession')
class DbStudyPlanSessions extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get subjectId => text()();
  TextColumn get unitId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get sessionType => text()();
  TextColumn get titleEn => text()();
  TextColumn get titleAm => text()();
  IntColumn get questionTarget => integer().withDefault(const Constant(10))();
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(15))();
  RealColumn get priorityScore => real().withDefault(const Constant(0.0))();
  TextColumn get reasonCode => text()();
  TextColumn get reasonDetailEn => text()();
  TextColumn get reasonDetailAm => text()();
  TextColumn get status => text().withDefault(const Constant('not_started'))();
  TextColumn get questionIdsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get timeSpentSeconds => integer().withDefault(const Constant(0))();
  RealColumn get scorePercentage => real().nullable()();
  TextColumn get examVariant => text().nullable()();
  TextColumn get assessmentStructure => text().nullable()();
  TextColumn get contentDomain => text().nullable()();
  TextColumn get skill => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for question-level mastery states and spaced review dates
@DataClassName('DbQuestionMasteryRow')
class DbQuestionMastery extends Table {
  TextColumn get id => text()(); // userId_questionId
  TextColumn get userId => text()();
  TextColumn get questionId => text()();
  TextColumn get subjectId => text()();
  TextColumn get examVariant => text().nullable()();
  TextColumn get assessmentStructure => text().nullable()();
  TextColumn get unitId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get contentDomain => text().nullable()();
  TextColumn get skill => text().nullable()();

  TextColumn get masteryState => text().withDefault(const Constant(
      'new'))(); // 'new' | 'learning' | 'improving' | 'mastered' | 'at_risk' | 'relearning'
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();

  RealColumn get stability => real().withDefault(const Constant(1.0))();
  RealColumn get difficulty => real().withDefault(const Constant(2.0))();

  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  IntColumn get lapseCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get lastCorrectAt => dateTime().nullable()();
  DateTimeColumn get lastIncorrectAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

  TextColumn get algorithmVersion =>
      text().withDefault(const Constant('mastery_engine_v1.0'))();
  TextColumn get evidenceSource => text()
      .withDefault(const Constant('native'))(); // 'native' | 'legacy_migration'
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, questionId},
      ];
}

/// SQLite table for learning-target level mastery aggregation (Topic / Skill / Domain)
@DataClassName('DbLearningTargetMasteryRow')
class DbLearningTargetMastery extends Table {
  TextColumn get id =>
      text()(); // userId_targetKey (where targetKey is canonical & variant-qualified)
  TextColumn get userId => text()();
  TextColumn get targetKey => text()();
  TextColumn get subjectId => text()();
  TextColumn get examVariant => text().nullable()();
  TextColumn get assessmentStructure => text().nullable()();
  TextColumn get unitId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get contentDomain => text().nullable()();
  TextColumn get skill => text().nullable()();

  TextColumn get titleEn => text()();
  TextColumn get titleAm => text()();

  TextColumn get masteryState => text().withDefault(const Constant('new'))();
  TextColumn get evidenceSource => text()
      .withDefault(const Constant('native'))(); // 'native' | 'legacy_migration'
  RealColumn get accuracyPercentage =>
      real().withDefault(const Constant(0.0))();
  IntColumn get totalAttempts => integer().withDefault(const Constant(0))();
  IntColumn get masteredQuestionCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get coveredQuestionCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalAvailableQuestions =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get lastPracticedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, targetKey},
      ];
}

/// SQLite table for immutable review event history and audit logs
@DataClassName('DbReviewEventRow')
class DbReviewEvents extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get questionId => text()();
  TextColumn get targetKey => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get examVariant => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime()();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get isCorrect => boolean()();
  IntColumn get timeSpentSeconds => integer().withDefault(const Constant(0))();
  TextColumn get previousState => text()();
  TextColumn get newState => text()();
  IntColumn get previousIntervalDays =>
      integer().withDefault(const Constant(0))();
  IntColumn get newIntervalDays => integer().withDefault(const Constant(0))();
  TextColumn get algorithmVersion =>
      text().withDefault(const Constant('mastery_engine_v1.0'))();

  @override
  Set<Column> get primaryKey => {id};
}

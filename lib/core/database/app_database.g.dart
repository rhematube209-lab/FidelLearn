// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DbExamAttemptsTable extends DbExamAttempts
    with TableInfo<$DbExamAttemptsTable, DbExamAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbExamAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
      'exam_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _examTitleMeta =
      const VerificationMeta('examTitle');
  @override
  late final GeneratedColumn<String> examTitle = GeneratedColumn<String>(
      'exam_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalQuestionsMeta =
      const VerificationMeta('totalQuestions');
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
      'total_questions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _percentageMeta =
      const VerificationMeta('percentage');
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
      'percentage', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _incorrectCountMeta =
      const VerificationMeta('incorrectCount');
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
      'incorrect_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _skippedCountMeta =
      const VerificationMeta('skippedCount');
  @override
  late final GeneratedColumn<int> skippedCount = GeneratedColumn<int>(
      'skipped_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _responsesJsonMeta =
      const VerificationMeta('responsesJson');
  @override
  late final GeneratedColumn<String> responsesJson = GeneratedColumn<String>(
      'responses_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        examId,
        examTitle,
        subjectId,
        startTime,
        endTime,
        durationSeconds,
        totalQuestions,
        score,
        percentage,
        correctCount,
        incorrectCount,
        skippedCount,
        isCompleted,
        syncStatus,
        responsesJson,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_exam_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<DbExamAttempt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(_examIdMeta,
          examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta));
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('exam_title')) {
      context.handle(_examTitleMeta,
          examTitle.isAcceptableOrUnknown(data['exam_title']!, _examTitleMeta));
    } else if (isInserting) {
      context.missing(_examTitleMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('total_questions')) {
      context.handle(
          _totalQuestionsMeta,
          totalQuestions.isAcceptableOrUnknown(
              data['total_questions']!, _totalQuestionsMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('percentage')) {
      context.handle(
          _percentageMeta,
          percentage.isAcceptableOrUnknown(
              data['percentage']!, _percentageMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
          _incorrectCountMeta,
          incorrectCount.isAcceptableOrUnknown(
              data['incorrect_count']!, _incorrectCountMeta));
    }
    if (data.containsKey('skipped_count')) {
      context.handle(
          _skippedCountMeta,
          skippedCount.isAcceptableOrUnknown(
              data['skipped_count']!, _skippedCountMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('responses_json')) {
      context.handle(
          _responsesJsonMeta,
          responsesJson.isAcceptableOrUnknown(
              data['responses_json']!, _responsesJsonMeta));
    } else if (isInserting) {
      context.missing(_responsesJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbExamAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbExamAttempt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      examId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_id'])!,
      examTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_title'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      totalQuestions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_questions'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      percentage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}percentage'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      incorrectCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}incorrect_count'])!,
      skippedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}skipped_count'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      responsesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}responses_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DbExamAttemptsTable createAlias(String alias) {
    return $DbExamAttemptsTable(attachedDatabase, alias);
  }
}

class DbExamAttempt extends DataClass implements Insertable<DbExamAttempt> {
  final String id;
  final String userId;
  final String examId;
  final String examTitle;
  final String subjectId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int totalQuestions;
  final int score;
  final double percentage;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final bool isCompleted;
  final String syncStatus;
  final String responsesJson;
  final DateTime createdAt;
  const DbExamAttempt(
      {required this.id,
      required this.userId,
      required this.examId,
      required this.examTitle,
      required this.subjectId,
      required this.startTime,
      this.endTime,
      required this.durationSeconds,
      required this.totalQuestions,
      required this.score,
      required this.percentage,
      required this.correctCount,
      required this.incorrectCount,
      required this.skippedCount,
      required this.isCompleted,
      required this.syncStatus,
      required this.responsesJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['exam_id'] = Variable<String>(examId);
    map['exam_title'] = Variable<String>(examTitle);
    map['subject_id'] = Variable<String>(subjectId);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['total_questions'] = Variable<int>(totalQuestions);
    map['score'] = Variable<int>(score);
    map['percentage'] = Variable<double>(percentage);
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['skipped_count'] = Variable<int>(skippedCount);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['sync_status'] = Variable<String>(syncStatus);
    map['responses_json'] = Variable<String>(responsesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbExamAttemptsCompanion toCompanion(bool nullToAbsent) {
    return DbExamAttemptsCompanion(
      id: Value(id),
      userId: Value(userId),
      examId: Value(examId),
      examTitle: Value(examTitle),
      subjectId: Value(subjectId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationSeconds: Value(durationSeconds),
      totalQuestions: Value(totalQuestions),
      score: Value(score),
      percentage: Value(percentage),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      skippedCount: Value(skippedCount),
      isCompleted: Value(isCompleted),
      syncStatus: Value(syncStatus),
      responsesJson: Value(responsesJson),
      createdAt: Value(createdAt),
    );
  }

  factory DbExamAttempt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbExamAttempt(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      examId: serializer.fromJson<String>(json['examId']),
      examTitle: serializer.fromJson<String>(json['examTitle']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      score: serializer.fromJson<int>(json['score']),
      percentage: serializer.fromJson<double>(json['percentage']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      skippedCount: serializer.fromJson<int>(json['skippedCount']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      responsesJson: serializer.fromJson<String>(json['responsesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'examId': serializer.toJson<String>(examId),
      'examTitle': serializer.toJson<String>(examTitle),
      'subjectId': serializer.toJson<String>(subjectId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'score': serializer.toJson<int>(score),
      'percentage': serializer.toJson<double>(percentage),
      'correctCount': serializer.toJson<int>(correctCount),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'skippedCount': serializer.toJson<int>(skippedCount),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'responsesJson': serializer.toJson<String>(responsesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbExamAttempt copyWith(
          {String? id,
          String? userId,
          String? examId,
          String? examTitle,
          String? subjectId,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          int? durationSeconds,
          int? totalQuestions,
          int? score,
          double? percentage,
          int? correctCount,
          int? incorrectCount,
          int? skippedCount,
          bool? isCompleted,
          String? syncStatus,
          String? responsesJson,
          DateTime? createdAt}) =>
      DbExamAttempt(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        examId: examId ?? this.examId,
        examTitle: examTitle ?? this.examTitle,
        subjectId: subjectId ?? this.subjectId,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        score: score ?? this.score,
        percentage: percentage ?? this.percentage,
        correctCount: correctCount ?? this.correctCount,
        incorrectCount: incorrectCount ?? this.incorrectCount,
        skippedCount: skippedCount ?? this.skippedCount,
        isCompleted: isCompleted ?? this.isCompleted,
        syncStatus: syncStatus ?? this.syncStatus,
        responsesJson: responsesJson ?? this.responsesJson,
        createdAt: createdAt ?? this.createdAt,
      );
  DbExamAttempt copyWithCompanion(DbExamAttemptsCompanion data) {
    return DbExamAttempt(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      examId: data.examId.present ? data.examId.value : this.examId,
      examTitle: data.examTitle.present ? data.examTitle.value : this.examTitle,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      score: data.score.present ? data.score.value : this.score,
      percentage:
          data.percentage.present ? data.percentage.value : this.percentage,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      skippedCount: data.skippedCount.present
          ? data.skippedCount.value
          : this.skippedCount,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      responsesJson: data.responsesJson.present
          ? data.responsesJson.value
          : this.responsesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbExamAttempt(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('examId: $examId, ')
          ..write('examTitle: $examTitle, ')
          ..write('subjectId: $subjectId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('score: $score, ')
          ..write('percentage: $percentage, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('skippedCount: $skippedCount, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('responsesJson: $responsesJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      examId,
      examTitle,
      subjectId,
      startTime,
      endTime,
      durationSeconds,
      totalQuestions,
      score,
      percentage,
      correctCount,
      incorrectCount,
      skippedCount,
      isCompleted,
      syncStatus,
      responsesJson,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbExamAttempt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.examId == this.examId &&
          other.examTitle == this.examTitle &&
          other.subjectId == this.subjectId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.totalQuestions == this.totalQuestions &&
          other.score == this.score &&
          other.percentage == this.percentage &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.skippedCount == this.skippedCount &&
          other.isCompleted == this.isCompleted &&
          other.syncStatus == this.syncStatus &&
          other.responsesJson == this.responsesJson &&
          other.createdAt == this.createdAt);
}

class DbExamAttemptsCompanion extends UpdateCompanion<DbExamAttempt> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> examId;
  final Value<String> examTitle;
  final Value<String> subjectId;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> durationSeconds;
  final Value<int> totalQuestions;
  final Value<int> score;
  final Value<double> percentage;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> skippedCount;
  final Value<bool> isCompleted;
  final Value<String> syncStatus;
  final Value<String> responsesJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DbExamAttemptsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.examId = const Value.absent(),
    this.examTitle = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.score = const Value.absent(),
    this.percentage = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.skippedCount = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.responsesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbExamAttemptsCompanion.insert({
    required String id,
    required String userId,
    required String examId,
    required String examTitle,
    required String subjectId,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.score = const Value.absent(),
    this.percentage = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.skippedCount = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String responsesJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        examId = Value(examId),
        examTitle = Value(examTitle),
        subjectId = Value(subjectId),
        startTime = Value(startTime),
        responsesJson = Value(responsesJson),
        createdAt = Value(createdAt);
  static Insertable<DbExamAttempt> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? examId,
    Expression<String>? examTitle,
    Expression<String>? subjectId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationSeconds,
    Expression<int>? totalQuestions,
    Expression<int>? score,
    Expression<double>? percentage,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? skippedCount,
    Expression<bool>? isCompleted,
    Expression<String>? syncStatus,
    Expression<String>? responsesJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (examId != null) 'exam_id': examId,
      if (examTitle != null) 'exam_title': examTitle,
      if (subjectId != null) 'subject_id': subjectId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (score != null) 'score': score,
      if (percentage != null) 'percentage': percentage,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (skippedCount != null) 'skipped_count': skippedCount,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (responsesJson != null) 'responses_json': responsesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbExamAttemptsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? examId,
      Value<String>? examTitle,
      Value<String>? subjectId,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int>? durationSeconds,
      Value<int>? totalQuestions,
      Value<int>? score,
      Value<double>? percentage,
      Value<int>? correctCount,
      Value<int>? incorrectCount,
      Value<int>? skippedCount,
      Value<bool>? isCompleted,
      Value<String>? syncStatus,
      Value<String>? responsesJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DbExamAttemptsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      examTitle: examTitle ?? this.examTitle,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      skippedCount: skippedCount ?? this.skippedCount,
      isCompleted: isCompleted ?? this.isCompleted,
      syncStatus: syncStatus ?? this.syncStatus,
      responsesJson: responsesJson ?? this.responsesJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (examTitle.present) {
      map['exam_title'] = Variable<String>(examTitle.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (skippedCount.present) {
      map['skipped_count'] = Variable<int>(skippedCount.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (responsesJson.present) {
      map['responses_json'] = Variable<String>(responsesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbExamAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('examId: $examId, ')
          ..write('examTitle: $examTitle, ')
          ..write('subjectId: $subjectId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('score: $score, ')
          ..write('percentage: $percentage, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('skippedCount: $skippedCount, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('responsesJson: $responsesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbActiveAttemptsTable extends DbActiveAttempts
    with TableInfo<$DbActiveAttemptsTable, DbActiveAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbActiveAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptJsonMeta =
      const VerificationMeta('attemptJson');
  @override
  late final GeneratedColumn<String> attemptJson = GeneratedColumn<String>(
      'attempt_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [userId, attemptJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_active_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<DbActiveAttempt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('attempt_json')) {
      context.handle(
          _attemptJsonMeta,
          attemptJson.isAcceptableOrUnknown(
              data['attempt_json']!, _attemptJsonMeta));
    } else if (isInserting) {
      context.missing(_attemptJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  DbActiveAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbActiveAttempt(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      attemptJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attempt_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DbActiveAttemptsTable createAlias(String alias) {
    return $DbActiveAttemptsTable(attachedDatabase, alias);
  }
}

class DbActiveAttempt extends DataClass implements Insertable<DbActiveAttempt> {
  final String userId;
  final String attemptJson;
  final DateTime updatedAt;
  const DbActiveAttempt(
      {required this.userId,
      required this.attemptJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['attempt_json'] = Variable<String>(attemptJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DbActiveAttemptsCompanion toCompanion(bool nullToAbsent) {
    return DbActiveAttemptsCompanion(
      userId: Value(userId),
      attemptJson: Value(attemptJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbActiveAttempt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbActiveAttempt(
      userId: serializer.fromJson<String>(json['userId']),
      attemptJson: serializer.fromJson<String>(json['attemptJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'attemptJson': serializer.toJson<String>(attemptJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbActiveAttempt copyWith(
          {String? userId, String? attemptJson, DateTime? updatedAt}) =>
      DbActiveAttempt(
        userId: userId ?? this.userId,
        attemptJson: attemptJson ?? this.attemptJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DbActiveAttempt copyWithCompanion(DbActiveAttemptsCompanion data) {
    return DbActiveAttempt(
      userId: data.userId.present ? data.userId.value : this.userId,
      attemptJson:
          data.attemptJson.present ? data.attemptJson.value : this.attemptJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbActiveAttempt(')
          ..write('userId: $userId, ')
          ..write('attemptJson: $attemptJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, attemptJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbActiveAttempt &&
          other.userId == this.userId &&
          other.attemptJson == this.attemptJson &&
          other.updatedAt == this.updatedAt);
}

class DbActiveAttemptsCompanion extends UpdateCompanion<DbActiveAttempt> {
  final Value<String> userId;
  final Value<String> attemptJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DbActiveAttemptsCompanion({
    this.userId = const Value.absent(),
    this.attemptJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbActiveAttemptsCompanion.insert({
    required String userId,
    required String attemptJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        attemptJson = Value(attemptJson),
        updatedAt = Value(updatedAt);
  static Insertable<DbActiveAttempt> custom({
    Expression<String>? userId,
    Expression<String>? attemptJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (attemptJson != null) 'attempt_json': attemptJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbActiveAttemptsCompanion copyWith(
      {Value<String>? userId,
      Value<String>? attemptJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DbActiveAttemptsCompanion(
      userId: userId ?? this.userId,
      attemptJson: attemptJson ?? this.attemptJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (attemptJson.present) {
      map['attempt_json'] = Variable<String>(attemptJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbActiveAttemptsCompanion(')
          ..write('userId: $userId, ')
          ..write('attemptJson: $attemptJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbBookmarksTable extends DbBookmarks
    with TableInfo<$DbBookmarksTable, DbBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
      'topic_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, questionId, subjectId, topicId, createdAt, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<DbBookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbBookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
    );
  }

  @override
  $DbBookmarksTable createAlias(String alias) {
    return $DbBookmarksTable(attachedDatabase, alias);
  }
}

class DbBookmark extends DataClass implements Insertable<DbBookmark> {
  final String id;
  final String userId;
  final String questionId;
  final String subjectId;
  final String topicId;
  final DateTime createdAt;
  final bool isActive;
  const DbBookmark(
      {required this.id,
      required this.userId,
      required this.questionId,
      required this.subjectId,
      required this.topicId,
      required this.createdAt,
      required this.isActive});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['question_id'] = Variable<String>(questionId);
    map['subject_id'] = Variable<String>(subjectId);
    map['topic_id'] = Variable<String>(topicId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  DbBookmarksCompanion toCompanion(bool nullToAbsent) {
    return DbBookmarksCompanion(
      id: Value(id),
      userId: Value(userId),
      questionId: Value(questionId),
      subjectId: Value(subjectId),
      topicId: Value(topicId),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory DbBookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbBookmark(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      topicId: serializer.fromJson<String>(json['topicId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'questionId': serializer.toJson<String>(questionId),
      'subjectId': serializer.toJson<String>(subjectId),
      'topicId': serializer.toJson<String>(topicId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  DbBookmark copyWith(
          {String? id,
          String? userId,
          String? questionId,
          String? subjectId,
          String? topicId,
          DateTime? createdAt,
          bool? isActive}) =>
      DbBookmark(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        questionId: questionId ?? this.questionId,
        subjectId: subjectId ?? this.subjectId,
        topicId: topicId ?? this.topicId,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );
  DbBookmark copyWithCompanion(DbBookmarksCompanion data) {
    return DbBookmark(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbBookmark(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('subjectId: $subjectId, ')
          ..write('topicId: $topicId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, questionId, subjectId, topicId, createdAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbBookmark &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.questionId == this.questionId &&
          other.subjectId == this.subjectId &&
          other.topicId == this.topicId &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class DbBookmarksCompanion extends UpdateCompanion<DbBookmark> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> questionId;
  final Value<String> subjectId;
  final Value<String> topicId;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const DbBookmarksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbBookmarksCompanion.insert({
    required String id,
    required String userId,
    required String questionId,
    required String subjectId,
    required String topicId,
    required DateTime createdAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        questionId = Value(questionId),
        subjectId = Value(subjectId),
        topicId = Value(topicId),
        createdAt = Value(createdAt);
  static Insertable<DbBookmark> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? questionId,
    Expression<String>? subjectId,
    Expression<String>? topicId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      if (subjectId != null) 'subject_id': subjectId,
      if (topicId != null) 'topic_id': topicId,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbBookmarksCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? questionId,
      Value<String>? subjectId,
      Value<String>? topicId,
      Value<DateTime>? createdAt,
      Value<bool>? isActive,
      Value<int>? rowid}) {
    return DbBookmarksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('subjectId: $subjectId, ')
          ..write('topicId: $topicId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbMistakesTable extends DbMistakes
    with TableInfo<$DbMistakesTable, DbMistake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbMistakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
      'topic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptIdMeta =
      const VerificationMeta('lastAttemptId');
  @override
  late final GeneratedColumn<String> lastAttemptId = GeneratedColumn<String>(
      'last_attempt_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSelectedChoiceIdMeta =
      const VerificationMeta('lastSelectedChoiceId');
  @override
  late final GeneratedColumn<String> lastSelectedChoiceId =
      GeneratedColumn<String>('last_selected_choice_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _firstMissedAtMeta =
      const VerificationMeta('firstMissedAt');
  @override
  late final GeneratedColumn<DateTime> firstMissedAt =
      GeneratedColumn<DateTime>('first_missed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastMissedAtMeta =
      const VerificationMeta('lastMissedAt');
  @override
  late final GeneratedColumn<DateTime> lastMissedAt = GeneratedColumn<DateTime>(
      'last_missed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _missCountMeta =
      const VerificationMeta('missCount');
  @override
  late final GeneratedColumn<int> missCount = GeneratedColumn<int>(
      'miss_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _correctRetryCountMeta =
      const VerificationMeta('correctRetryCount');
  @override
  late final GeneratedColumn<int> correctRetryCount = GeneratedColumn<int>(
      'correct_retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _masteryStatusMeta =
      const VerificationMeta('masteryStatus');
  @override
  late final GeneratedColumn<String> masteryStatus = GeneratedColumn<String>(
      'mastery_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('needsReview'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  static const VerificationMeta _mistakeCountMeta =
      const VerificationMeta('mistakeCount');
  @override
  late final GeneratedColumn<int> mistakeCount = GeneratedColumn<int>(
      'mistake_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isMasteredMeta =
      const VerificationMeta('isMastered');
  @override
  late final GeneratedColumn<bool> isMastered = GeneratedColumn<bool>(
      'is_mastered', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_mastered" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastFailedAtMeta =
      const VerificationMeta('lastFailedAt');
  @override
  late final GeneratedColumn<DateTime> lastFailedAt = GeneratedColumn<DateTime>(
      'last_failed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _masteredAtMeta =
      const VerificationMeta('masteredAt');
  @override
  late final GeneratedColumn<DateTime> masteredAt = GeneratedColumn<DateTime>(
      'mastered_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        questionId,
        subjectId,
        unitId,
        topicId,
        lastAttemptId,
        lastSelectedChoiceId,
        firstMissedAt,
        lastMissedAt,
        lastAttemptAt,
        missCount,
        retryCount,
        correctRetryCount,
        masteryStatus,
        createdAt,
        updatedAt,
        syncStatus,
        mistakeCount,
        isMastered,
        lastFailedAt,
        masteredAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_mistakes';
  @override
  VerificationContext validateIntegrity(Insertable<DbMistake> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    }
    if (data.containsKey('last_attempt_id')) {
      context.handle(
          _lastAttemptIdMeta,
          lastAttemptId.isAcceptableOrUnknown(
              data['last_attempt_id']!, _lastAttemptIdMeta));
    }
    if (data.containsKey('last_selected_choice_id')) {
      context.handle(
          _lastSelectedChoiceIdMeta,
          lastSelectedChoiceId.isAcceptableOrUnknown(
              data['last_selected_choice_id']!, _lastSelectedChoiceIdMeta));
    }
    if (data.containsKey('first_missed_at')) {
      context.handle(
          _firstMissedAtMeta,
          firstMissedAt.isAcceptableOrUnknown(
              data['first_missed_at']!, _firstMissedAtMeta));
    }
    if (data.containsKey('last_missed_at')) {
      context.handle(
          _lastMissedAtMeta,
          lastMissedAt.isAcceptableOrUnknown(
              data['last_missed_at']!, _lastMissedAtMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('miss_count')) {
      context.handle(_missCountMeta,
          missCount.isAcceptableOrUnknown(data['miss_count']!, _missCountMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('correct_retry_count')) {
      context.handle(
          _correctRetryCountMeta,
          correctRetryCount.isAcceptableOrUnknown(
              data['correct_retry_count']!, _correctRetryCountMeta));
    }
    if (data.containsKey('mastery_status')) {
      context.handle(
          _masteryStatusMeta,
          masteryStatus.isAcceptableOrUnknown(
              data['mastery_status']!, _masteryStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('mistake_count')) {
      context.handle(
          _mistakeCountMeta,
          mistakeCount.isAcceptableOrUnknown(
              data['mistake_count']!, _mistakeCountMeta));
    }
    if (data.containsKey('is_mastered')) {
      context.handle(
          _isMasteredMeta,
          isMastered.isAcceptableOrUnknown(
              data['is_mastered']!, _isMasteredMeta));
    }
    if (data.containsKey('last_failed_at')) {
      context.handle(
          _lastFailedAtMeta,
          lastFailedAt.isAcceptableOrUnknown(
              data['last_failed_at']!, _lastFailedAtMeta));
    }
    if (data.containsKey('mastered_at')) {
      context.handle(
          _masteredAtMeta,
          masteredAt.isAcceptableOrUnknown(
              data['mastered_at']!, _masteredAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, questionId},
      ];
  @override
  DbMistake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbMistake(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id']),
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic_id']),
      lastAttemptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_attempt_id']),
      lastSelectedChoiceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_selected_choice_id']),
      firstMissedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}first_missed_at']),
      lastMissedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_missed_at']),
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
      missCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}miss_count'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      correctRetryCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}correct_retry_count'])!,
      masteryStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mastery_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      mistakeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mistake_count'])!,
      isMastered: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mastered'])!,
      lastFailedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_failed_at']),
      masteredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}mastered_at']),
    );
  }

  @override
  $DbMistakesTable createAlias(String alias) {
    return $DbMistakesTable(attachedDatabase, alias);
  }
}

class DbMistake extends DataClass implements Insertable<DbMistake> {
  final String id;
  final String userId;
  final String questionId;
  final String subjectId;
  final String? unitId;
  final String? topicId;
  final String? lastAttemptId;
  final String? lastSelectedChoiceId;
  final DateTime? firstMissedAt;
  final DateTime? lastMissedAt;
  final DateTime? lastAttemptAt;
  final int missCount;
  final int retryCount;
  final int correctRetryCount;
  final String masteryStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String syncStatus;
  final int mistakeCount;
  final bool isMastered;
  final DateTime? lastFailedAt;
  final DateTime? masteredAt;
  const DbMistake(
      {required this.id,
      required this.userId,
      required this.questionId,
      required this.subjectId,
      this.unitId,
      this.topicId,
      this.lastAttemptId,
      this.lastSelectedChoiceId,
      this.firstMissedAt,
      this.lastMissedAt,
      this.lastAttemptAt,
      required this.missCount,
      required this.retryCount,
      required this.correctRetryCount,
      required this.masteryStatus,
      this.createdAt,
      this.updatedAt,
      required this.syncStatus,
      required this.mistakeCount,
      required this.isMastered,
      this.lastFailedAt,
      this.masteredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['question_id'] = Variable<String>(questionId);
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    if (!nullToAbsent || lastAttemptId != null) {
      map['last_attempt_id'] = Variable<String>(lastAttemptId);
    }
    if (!nullToAbsent || lastSelectedChoiceId != null) {
      map['last_selected_choice_id'] = Variable<String>(lastSelectedChoiceId);
    }
    if (!nullToAbsent || firstMissedAt != null) {
      map['first_missed_at'] = Variable<DateTime>(firstMissedAt);
    }
    if (!nullToAbsent || lastMissedAt != null) {
      map['last_missed_at'] = Variable<DateTime>(lastMissedAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['miss_count'] = Variable<int>(missCount);
    map['retry_count'] = Variable<int>(retryCount);
    map['correct_retry_count'] = Variable<int>(correctRetryCount);
    map['mastery_status'] = Variable<String>(masteryStatus);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['mistake_count'] = Variable<int>(mistakeCount);
    map['is_mastered'] = Variable<bool>(isMastered);
    if (!nullToAbsent || lastFailedAt != null) {
      map['last_failed_at'] = Variable<DateTime>(lastFailedAt);
    }
    if (!nullToAbsent || masteredAt != null) {
      map['mastered_at'] = Variable<DateTime>(masteredAt);
    }
    return map;
  }

  DbMistakesCompanion toCompanion(bool nullToAbsent) {
    return DbMistakesCompanion(
      id: Value(id),
      userId: Value(userId),
      questionId: Value(questionId),
      subjectId: Value(subjectId),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      lastAttemptId: lastAttemptId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptId),
      lastSelectedChoiceId: lastSelectedChoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSelectedChoiceId),
      firstMissedAt: firstMissedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstMissedAt),
      lastMissedAt: lastMissedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMissedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      missCount: Value(missCount),
      retryCount: Value(retryCount),
      correctRetryCount: Value(correctRetryCount),
      masteryStatus: Value(masteryStatus),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncStatus: Value(syncStatus),
      mistakeCount: Value(mistakeCount),
      isMastered: Value(isMastered),
      lastFailedAt: lastFailedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailedAt),
      masteredAt: masteredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(masteredAt),
    );
  }

  factory DbMistake.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbMistake(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      lastAttemptId: serializer.fromJson<String?>(json['lastAttemptId']),
      lastSelectedChoiceId:
          serializer.fromJson<String?>(json['lastSelectedChoiceId']),
      firstMissedAt: serializer.fromJson<DateTime?>(json['firstMissedAt']),
      lastMissedAt: serializer.fromJson<DateTime?>(json['lastMissedAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      missCount: serializer.fromJson<int>(json['missCount']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      correctRetryCount: serializer.fromJson<int>(json['correctRetryCount']),
      masteryStatus: serializer.fromJson<String>(json['masteryStatus']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      mistakeCount: serializer.fromJson<int>(json['mistakeCount']),
      isMastered: serializer.fromJson<bool>(json['isMastered']),
      lastFailedAt: serializer.fromJson<DateTime?>(json['lastFailedAt']),
      masteredAt: serializer.fromJson<DateTime?>(json['masteredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'questionId': serializer.toJson<String>(questionId),
      'subjectId': serializer.toJson<String>(subjectId),
      'unitId': serializer.toJson<String?>(unitId),
      'topicId': serializer.toJson<String?>(topicId),
      'lastAttemptId': serializer.toJson<String?>(lastAttemptId),
      'lastSelectedChoiceId': serializer.toJson<String?>(lastSelectedChoiceId),
      'firstMissedAt': serializer.toJson<DateTime?>(firstMissedAt),
      'lastMissedAt': serializer.toJson<DateTime?>(lastMissedAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'missCount': serializer.toJson<int>(missCount),
      'retryCount': serializer.toJson<int>(retryCount),
      'correctRetryCount': serializer.toJson<int>(correctRetryCount),
      'masteryStatus': serializer.toJson<String>(masteryStatus),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'mistakeCount': serializer.toJson<int>(mistakeCount),
      'isMastered': serializer.toJson<bool>(isMastered),
      'lastFailedAt': serializer.toJson<DateTime?>(lastFailedAt),
      'masteredAt': serializer.toJson<DateTime?>(masteredAt),
    };
  }

  DbMistake copyWith(
          {String? id,
          String? userId,
          String? questionId,
          String? subjectId,
          Value<String?> unitId = const Value.absent(),
          Value<String?> topicId = const Value.absent(),
          Value<String?> lastAttemptId = const Value.absent(),
          Value<String?> lastSelectedChoiceId = const Value.absent(),
          Value<DateTime?> firstMissedAt = const Value.absent(),
          Value<DateTime?> lastMissedAt = const Value.absent(),
          Value<DateTime?> lastAttemptAt = const Value.absent(),
          int? missCount,
          int? retryCount,
          int? correctRetryCount,
          String? masteryStatus,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          String? syncStatus,
          int? mistakeCount,
          bool? isMastered,
          Value<DateTime?> lastFailedAt = const Value.absent(),
          Value<DateTime?> masteredAt = const Value.absent()}) =>
      DbMistake(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        questionId: questionId ?? this.questionId,
        subjectId: subjectId ?? this.subjectId,
        unitId: unitId.present ? unitId.value : this.unitId,
        topicId: topicId.present ? topicId.value : this.topicId,
        lastAttemptId:
            lastAttemptId.present ? lastAttemptId.value : this.lastAttemptId,
        lastSelectedChoiceId: lastSelectedChoiceId.present
            ? lastSelectedChoiceId.value
            : this.lastSelectedChoiceId,
        firstMissedAt:
            firstMissedAt.present ? firstMissedAt.value : this.firstMissedAt,
        lastMissedAt:
            lastMissedAt.present ? lastMissedAt.value : this.lastMissedAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        missCount: missCount ?? this.missCount,
        retryCount: retryCount ?? this.retryCount,
        correctRetryCount: correctRetryCount ?? this.correctRetryCount,
        masteryStatus: masteryStatus ?? this.masteryStatus,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        mistakeCount: mistakeCount ?? this.mistakeCount,
        isMastered: isMastered ?? this.isMastered,
        lastFailedAt:
            lastFailedAt.present ? lastFailedAt.value : this.lastFailedAt,
        masteredAt: masteredAt.present ? masteredAt.value : this.masteredAt,
      );
  DbMistake copyWithCompanion(DbMistakesCompanion data) {
    return DbMistake(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      lastAttemptId: data.lastAttemptId.present
          ? data.lastAttemptId.value
          : this.lastAttemptId,
      lastSelectedChoiceId: data.lastSelectedChoiceId.present
          ? data.lastSelectedChoiceId.value
          : this.lastSelectedChoiceId,
      firstMissedAt: data.firstMissedAt.present
          ? data.firstMissedAt.value
          : this.firstMissedAt,
      lastMissedAt: data.lastMissedAt.present
          ? data.lastMissedAt.value
          : this.lastMissedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      missCount: data.missCount.present ? data.missCount.value : this.missCount,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      correctRetryCount: data.correctRetryCount.present
          ? data.correctRetryCount.value
          : this.correctRetryCount,
      masteryStatus: data.masteryStatus.present
          ? data.masteryStatus.value
          : this.masteryStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      mistakeCount: data.mistakeCount.present
          ? data.mistakeCount.value
          : this.mistakeCount,
      isMastered:
          data.isMastered.present ? data.isMastered.value : this.isMastered,
      lastFailedAt: data.lastFailedAt.present
          ? data.lastFailedAt.value
          : this.lastFailedAt,
      masteredAt:
          data.masteredAt.present ? data.masteredAt.value : this.masteredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbMistake(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('subjectId: $subjectId, ')
          ..write('unitId: $unitId, ')
          ..write('topicId: $topicId, ')
          ..write('lastAttemptId: $lastAttemptId, ')
          ..write('lastSelectedChoiceId: $lastSelectedChoiceId, ')
          ..write('firstMissedAt: $firstMissedAt, ')
          ..write('lastMissedAt: $lastMissedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('missCount: $missCount, ')
          ..write('retryCount: $retryCount, ')
          ..write('correctRetryCount: $correctRetryCount, ')
          ..write('masteryStatus: $masteryStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('isMastered: $isMastered, ')
          ..write('lastFailedAt: $lastFailedAt, ')
          ..write('masteredAt: $masteredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        questionId,
        subjectId,
        unitId,
        topicId,
        lastAttemptId,
        lastSelectedChoiceId,
        firstMissedAt,
        lastMissedAt,
        lastAttemptAt,
        missCount,
        retryCount,
        correctRetryCount,
        masteryStatus,
        createdAt,
        updatedAt,
        syncStatus,
        mistakeCount,
        isMastered,
        lastFailedAt,
        masteredAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbMistake &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.questionId == this.questionId &&
          other.subjectId == this.subjectId &&
          other.unitId == this.unitId &&
          other.topicId == this.topicId &&
          other.lastAttemptId == this.lastAttemptId &&
          other.lastSelectedChoiceId == this.lastSelectedChoiceId &&
          other.firstMissedAt == this.firstMissedAt &&
          other.lastMissedAt == this.lastMissedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.missCount == this.missCount &&
          other.retryCount == this.retryCount &&
          other.correctRetryCount == this.correctRetryCount &&
          other.masteryStatus == this.masteryStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.mistakeCount == this.mistakeCount &&
          other.isMastered == this.isMastered &&
          other.lastFailedAt == this.lastFailedAt &&
          other.masteredAt == this.masteredAt);
}

class DbMistakesCompanion extends UpdateCompanion<DbMistake> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> questionId;
  final Value<String> subjectId;
  final Value<String?> unitId;
  final Value<String?> topicId;
  final Value<String?> lastAttemptId;
  final Value<String?> lastSelectedChoiceId;
  final Value<DateTime?> firstMissedAt;
  final Value<DateTime?> lastMissedAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> missCount;
  final Value<int> retryCount;
  final Value<int> correctRetryCount;
  final Value<String> masteryStatus;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<String> syncStatus;
  final Value<int> mistakeCount;
  final Value<bool> isMastered;
  final Value<DateTime?> lastFailedAt;
  final Value<DateTime?> masteredAt;
  final Value<int> rowid;
  const DbMistakesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.lastAttemptId = const Value.absent(),
    this.lastSelectedChoiceId = const Value.absent(),
    this.firstMissedAt = const Value.absent(),
    this.lastMissedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.missCount = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.correctRetryCount = const Value.absent(),
    this.masteryStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.mistakeCount = const Value.absent(),
    this.isMastered = const Value.absent(),
    this.lastFailedAt = const Value.absent(),
    this.masteredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbMistakesCompanion.insert({
    required String id,
    required String userId,
    required String questionId,
    required String subjectId,
    this.unitId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.lastAttemptId = const Value.absent(),
    this.lastSelectedChoiceId = const Value.absent(),
    this.firstMissedAt = const Value.absent(),
    this.lastMissedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.missCount = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.correctRetryCount = const Value.absent(),
    this.masteryStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.mistakeCount = const Value.absent(),
    this.isMastered = const Value.absent(),
    this.lastFailedAt = const Value.absent(),
    this.masteredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        questionId = Value(questionId),
        subjectId = Value(subjectId);
  static Insertable<DbMistake> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? questionId,
    Expression<String>? subjectId,
    Expression<String>? unitId,
    Expression<String>? topicId,
    Expression<String>? lastAttemptId,
    Expression<String>? lastSelectedChoiceId,
    Expression<DateTime>? firstMissedAt,
    Expression<DateTime>? lastMissedAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? missCount,
    Expression<int>? retryCount,
    Expression<int>? correctRetryCount,
    Expression<String>? masteryStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? mistakeCount,
    Expression<bool>? isMastered,
    Expression<DateTime>? lastFailedAt,
    Expression<DateTime>? masteredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      if (subjectId != null) 'subject_id': subjectId,
      if (unitId != null) 'unit_id': unitId,
      if (topicId != null) 'topic_id': topicId,
      if (lastAttemptId != null) 'last_attempt_id': lastAttemptId,
      if (lastSelectedChoiceId != null)
        'last_selected_choice_id': lastSelectedChoiceId,
      if (firstMissedAt != null) 'first_missed_at': firstMissedAt,
      if (lastMissedAt != null) 'last_missed_at': lastMissedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (missCount != null) 'miss_count': missCount,
      if (retryCount != null) 'retry_count': retryCount,
      if (correctRetryCount != null) 'correct_retry_count': correctRetryCount,
      if (masteryStatus != null) 'mastery_status': masteryStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (mistakeCount != null) 'mistake_count': mistakeCount,
      if (isMastered != null) 'is_mastered': isMastered,
      if (lastFailedAt != null) 'last_failed_at': lastFailedAt,
      if (masteredAt != null) 'mastered_at': masteredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbMistakesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? questionId,
      Value<String>? subjectId,
      Value<String?>? unitId,
      Value<String?>? topicId,
      Value<String?>? lastAttemptId,
      Value<String?>? lastSelectedChoiceId,
      Value<DateTime?>? firstMissedAt,
      Value<DateTime?>? lastMissedAt,
      Value<DateTime?>? lastAttemptAt,
      Value<int>? missCount,
      Value<int>? retryCount,
      Value<int>? correctRetryCount,
      Value<String>? masteryStatus,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<String>? syncStatus,
      Value<int>? mistakeCount,
      Value<bool>? isMastered,
      Value<DateTime?>? lastFailedAt,
      Value<DateTime?>? masteredAt,
      Value<int>? rowid}) {
    return DbMistakesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      subjectId: subjectId ?? this.subjectId,
      unitId: unitId ?? this.unitId,
      topicId: topicId ?? this.topicId,
      lastAttemptId: lastAttemptId ?? this.lastAttemptId,
      lastSelectedChoiceId: lastSelectedChoiceId ?? this.lastSelectedChoiceId,
      firstMissedAt: firstMissedAt ?? this.firstMissedAt,
      lastMissedAt: lastMissedAt ?? this.lastMissedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      missCount: missCount ?? this.missCount,
      retryCount: retryCount ?? this.retryCount,
      correctRetryCount: correctRetryCount ?? this.correctRetryCount,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      isMastered: isMastered ?? this.isMastered,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
      masteredAt: masteredAt ?? this.masteredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (lastAttemptId.present) {
      map['last_attempt_id'] = Variable<String>(lastAttemptId.value);
    }
    if (lastSelectedChoiceId.present) {
      map['last_selected_choice_id'] =
          Variable<String>(lastSelectedChoiceId.value);
    }
    if (firstMissedAt.present) {
      map['first_missed_at'] = Variable<DateTime>(firstMissedAt.value);
    }
    if (lastMissedAt.present) {
      map['last_missed_at'] = Variable<DateTime>(lastMissedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (missCount.present) {
      map['miss_count'] = Variable<int>(missCount.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (correctRetryCount.present) {
      map['correct_retry_count'] = Variable<int>(correctRetryCount.value);
    }
    if (masteryStatus.present) {
      map['mastery_status'] = Variable<String>(masteryStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (mistakeCount.present) {
      map['mistake_count'] = Variable<int>(mistakeCount.value);
    }
    if (isMastered.present) {
      map['is_mastered'] = Variable<bool>(isMastered.value);
    }
    if (lastFailedAt.present) {
      map['last_failed_at'] = Variable<DateTime>(lastFailedAt.value);
    }
    if (masteredAt.present) {
      map['mastered_at'] = Variable<DateTime>(masteredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbMistakesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('questionId: $questionId, ')
          ..write('subjectId: $subjectId, ')
          ..write('unitId: $unitId, ')
          ..write('topicId: $topicId, ')
          ..write('lastAttemptId: $lastAttemptId, ')
          ..write('lastSelectedChoiceId: $lastSelectedChoiceId, ')
          ..write('firstMissedAt: $firstMissedAt, ')
          ..write('lastMissedAt: $lastMissedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('missCount: $missCount, ')
          ..write('retryCount: $retryCount, ')
          ..write('correctRetryCount: $correctRetryCount, ')
          ..write('masteryStatus: $masteryStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('isMastered: $isMastered, ')
          ..write('lastFailedAt: $lastFailedAt, ')
          ..write('masteredAt: $masteredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbCoinLedgerTable extends DbCoinLedger
    with TableInfo<$DbCoinLedgerTable, DbCoinLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbCoinLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relatedEntityIdMeta =
      const VerificationMeta('relatedEntityId');
  @override
  late final GeneratedColumn<String> relatedEntityId = GeneratedColumn<String>(
      'related_entity_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'UNIQUE NOT NULL');
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _serverVerifiedMeta =
      const VerificationMeta('serverVerified');
  @override
  late final GeneratedColumn<bool> serverVerified = GeneratedColumn<bool>(
      'server_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("server_verified" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        transactionType,
        amount,
        reason,
        relatedEntityId,
        idempotencyKey,
        createdAt,
        serverVerified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_coin_ledger';
  @override
  VerificationContext validateIntegrity(Insertable<DbCoinLedgerEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('related_entity_id')) {
      context.handle(
          _relatedEntityIdMeta,
          relatedEntityId.isAcceptableOrUnknown(
              data['related_entity_id']!, _relatedEntityIdMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('server_verified')) {
      context.handle(
          _serverVerifiedMeta,
          serverVerified.isAcceptableOrUnknown(
              data['server_verified']!, _serverVerifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCoinLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCoinLedgerEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      relatedEntityId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_entity_id']),
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      serverVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}server_verified'])!,
    );
  }

  @override
  $DbCoinLedgerTable createAlias(String alias) {
    return $DbCoinLedgerTable(attachedDatabase, alias);
  }
}

class DbCoinLedgerEntry extends DataClass
    implements Insertable<DbCoinLedgerEntry> {
  final String id;
  final String userId;
  final String transactionType;
  final int amount;
  final String reason;
  final String? relatedEntityId;
  final String idempotencyKey;
  final DateTime createdAt;
  final bool serverVerified;
  const DbCoinLedgerEntry(
      {required this.id,
      required this.userId,
      required this.transactionType,
      required this.amount,
      required this.reason,
      this.relatedEntityId,
      required this.idempotencyKey,
      required this.createdAt,
      required this.serverVerified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['transaction_type'] = Variable<String>(transactionType);
    map['amount'] = Variable<int>(amount);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || relatedEntityId != null) {
      map['related_entity_id'] = Variable<String>(relatedEntityId);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['server_verified'] = Variable<bool>(serverVerified);
    return map;
  }

  DbCoinLedgerCompanion toCompanion(bool nullToAbsent) {
    return DbCoinLedgerCompanion(
      id: Value(id),
      userId: Value(userId),
      transactionType: Value(transactionType),
      amount: Value(amount),
      reason: Value(reason),
      relatedEntityId: relatedEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedEntityId),
      idempotencyKey: Value(idempotencyKey),
      createdAt: Value(createdAt),
      serverVerified: Value(serverVerified),
    );
  }

  factory DbCoinLedgerEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCoinLedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      relatedEntityId: serializer.fromJson<String?>(json['relatedEntityId']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      serverVerified: serializer.fromJson<bool>(json['serverVerified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'transactionType': serializer.toJson<String>(transactionType),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<String>(reason),
      'relatedEntityId': serializer.toJson<String?>(relatedEntityId),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'serverVerified': serializer.toJson<bool>(serverVerified),
    };
  }

  DbCoinLedgerEntry copyWith(
          {String? id,
          String? userId,
          String? transactionType,
          int? amount,
          String? reason,
          Value<String?> relatedEntityId = const Value.absent(),
          String? idempotencyKey,
          DateTime? createdAt,
          bool? serverVerified}) =>
      DbCoinLedgerEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        transactionType: transactionType ?? this.transactionType,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
        relatedEntityId: relatedEntityId.present
            ? relatedEntityId.value
            : this.relatedEntityId,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        createdAt: createdAt ?? this.createdAt,
        serverVerified: serverVerified ?? this.serverVerified,
      );
  DbCoinLedgerEntry copyWithCompanion(DbCoinLedgerCompanion data) {
    return DbCoinLedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      relatedEntityId: data.relatedEntityId.present
          ? data.relatedEntityId.value
          : this.relatedEntityId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverVerified: data.serverVerified.present
          ? data.serverVerified.value
          : this.serverVerified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCoinLedgerEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('transactionType: $transactionType, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('relatedEntityId: $relatedEntityId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverVerified: $serverVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, transactionType, amount, reason,
      relatedEntityId, idempotencyKey, createdAt, serverVerified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCoinLedgerEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.transactionType == this.transactionType &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.relatedEntityId == this.relatedEntityId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.createdAt == this.createdAt &&
          other.serverVerified == this.serverVerified);
}

class DbCoinLedgerCompanion extends UpdateCompanion<DbCoinLedgerEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> transactionType;
  final Value<int> amount;
  final Value<String> reason;
  final Value<String?> relatedEntityId;
  final Value<String> idempotencyKey;
  final Value<DateTime> createdAt;
  final Value<bool> serverVerified;
  final Value<int> rowid;
  const DbCoinLedgerCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.relatedEntityId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbCoinLedgerCompanion.insert({
    required String id,
    required String userId,
    required String transactionType,
    required int amount,
    required String reason,
    this.relatedEntityId = const Value.absent(),
    required String idempotencyKey,
    required DateTime createdAt,
    this.serverVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        transactionType = Value(transactionType),
        amount = Value(amount),
        reason = Value(reason),
        idempotencyKey = Value(idempotencyKey),
        createdAt = Value(createdAt);
  static Insertable<DbCoinLedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? transactionType,
    Expression<int>? amount,
    Expression<String>? reason,
    Expression<String>? relatedEntityId,
    Expression<String>? idempotencyKey,
    Expression<DateTime>? createdAt,
    Expression<bool>? serverVerified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (relatedEntityId != null) 'related_entity_id': relatedEntityId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (createdAt != null) 'created_at': createdAt,
      if (serverVerified != null) 'server_verified': serverVerified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbCoinLedgerCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? transactionType,
      Value<int>? amount,
      Value<String>? reason,
      Value<String?>? relatedEntityId,
      Value<String>? idempotencyKey,
      Value<DateTime>? createdAt,
      Value<bool>? serverVerified,
      Value<int>? rowid}) {
    return DbCoinLedgerCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      serverVerified: serverVerified ?? this.serverVerified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (relatedEntityId.present) {
      map['related_entity_id'] = Variable<String>(relatedEntityId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverVerified.present) {
      map['server_verified'] = Variable<bool>(serverVerified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbCoinLedgerCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('transactionType: $transactionType, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('relatedEntityId: $relatedEntityId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverVerified: $serverVerified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbSyncQueueTable extends DbSyncQueue
    with TableInfo<$DbSyncQueueTable, DbSyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationTypeMeta =
      const VerificationMeta('operationType');
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
      'operation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'UNIQUE NOT NULL');
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operationType,
        payloadJson,
        idempotencyKey,
        retryCount,
        nextRetryAt,
        lastError,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<DbSyncQueueItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
          _operationTypeMeta,
          operationType.isAcceptableOrUnknown(
              data['operation_type']!, _operationTypeMeta));
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    } else if (isInserting) {
      context.missing(_nextRetryAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbSyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbSyncQueueItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      operationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      nextRetryAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DbSyncQueueTable createAlias(String alias) {
    return $DbSyncQueueTable(attachedDatabase, alias);
  }
}

class DbSyncQueueItem extends DataClass implements Insertable<DbSyncQueueItem> {
  final String id;
  final String operationType;
  final String payloadJson;
  final String idempotencyKey;
  final int retryCount;
  final DateTime nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
  const DbSyncQueueItem(
      {required this.id,
      required this.operationType,
      required this.payloadJson,
      required this.idempotencyKey,
      required this.retryCount,
      required this.nextRetryAt,
      this.lastError,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['retry_count'] = Variable<int>(retryCount);
    map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DbSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return DbSyncQueueCompanion(
      id: Value(id),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      idempotencyKey: Value(idempotencyKey),
      retryCount: Value(retryCount),
      nextRetryAt: Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory DbSyncQueueItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbSyncQueueItem(
      id: serializer.fromJson<String>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DbSyncQueueItem copyWith(
          {String? id,
          String? operationType,
          String? payloadJson,
          String? idempotencyKey,
          int? retryCount,
          DateTime? nextRetryAt,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt}) =>
      DbSyncQueueItem(
        id: id ?? this.id,
        operationType: operationType ?? this.operationType,
        payloadJson: payloadJson ?? this.payloadJson,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        retryCount: retryCount ?? this.retryCount,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
      );
  DbSyncQueueItem copyWithCompanion(DbSyncQueueCompanion data) {
    return DbSyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbSyncQueueItem(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operationType, payloadJson,
      idempotencyKey, retryCount, nextRetryAt, lastError, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbSyncQueueItem &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class DbSyncQueueCompanion extends UpdateCompanion<DbSyncQueueItem> {
  final Value<String> id;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> idempotencyKey;
  final Value<int> retryCount;
  final Value<DateTime> nextRetryAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DbSyncQueueCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbSyncQueueCompanion.insert({
    required String id,
    required String operationType,
    required String payloadJson,
    required String idempotencyKey,
    this.retryCount = const Value.absent(),
    required DateTime nextRetryAt,
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        operationType = Value(operationType),
        payloadJson = Value(payloadJson),
        idempotencyKey = Value(idempotencyKey),
        nextRetryAt = Value(nextRetryAt),
        createdAt = Value(createdAt);
  static Insertable<DbSyncQueueItem> custom({
    Expression<String>? id,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? idempotencyKey,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbSyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? operationType,
      Value<String>? payloadJson,
      Value<String>? idempotencyKey,
      Value<int>? retryCount,
      Value<DateTime>? nextRetryAt,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DbSyncQueueCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbStudyPlansTable extends DbStudyPlans
    with TableInfo<$DbStudyPlansTable, DbStudyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbStudyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDateMeta =
      const VerificationMeta('planDate');
  @override
  late final GeneratedColumn<DateTime> planDate = GeneratedColumn<DateTime>(
      'plan_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _targetMinutesMeta =
      const VerificationMeta('targetMinutes');
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
      'target_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(45));
  static const VerificationMeta _estimatedMinutesMeta =
      const VerificationMeta('estimatedMinutes');
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
      'estimated_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(45));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('not_started'));
  static const VerificationMeta _algorithmVersionMeta =
      const VerificationMeta('algorithmVersion');
  @override
  late final GeneratedColumn<String> algorithmVersion = GeneratedColumn<String>(
      'algorithm_version', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('adaptive_planner_v1'));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        planDate,
        targetMinutes,
        estimatedMinutes,
        status,
        algorithmVersion,
        generatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_study_plans';
  @override
  VerificationContext validateIntegrity(Insertable<DbStudyPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('plan_date')) {
      context.handle(_planDateMeta,
          planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta));
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
          _targetMinutesMeta,
          targetMinutes.isAcceptableOrUnknown(
              data['target_minutes']!, _targetMinutesMeta));
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
          _estimatedMinutesMeta,
          estimatedMinutes.isAcceptableOrUnknown(
              data['estimated_minutes']!, _estimatedMinutesMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('algorithm_version')) {
      context.handle(
          _algorithmVersionMeta,
          algorithmVersion.isAcceptableOrUnknown(
              data['algorithm_version']!, _algorithmVersionMeta));
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbStudyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbStudyPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      planDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}plan_date'])!,
      targetMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_minutes'])!,
      estimatedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}estimated_minutes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      algorithmVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}algorithm_version'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
    );
  }

  @override
  $DbStudyPlansTable createAlias(String alias) {
    return $DbStudyPlansTable(attachedDatabase, alias);
  }
}

class DbStudyPlan extends DataClass implements Insertable<DbStudyPlan> {
  final String id;
  final String userId;
  final DateTime planDate;
  final int targetMinutes;
  final int estimatedMinutes;
  final String status;
  final String algorithmVersion;
  final DateTime generatedAt;
  const DbStudyPlan(
      {required this.id,
      required this.userId,
      required this.planDate,
      required this.targetMinutes,
      required this.estimatedMinutes,
      required this.status,
      required this.algorithmVersion,
      required this.generatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['plan_date'] = Variable<DateTime>(planDate);
    map['target_minutes'] = Variable<int>(targetMinutes);
    map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    map['status'] = Variable<String>(status);
    map['algorithm_version'] = Variable<String>(algorithmVersion);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  DbStudyPlansCompanion toCompanion(bool nullToAbsent) {
    return DbStudyPlansCompanion(
      id: Value(id),
      userId: Value(userId),
      planDate: Value(planDate),
      targetMinutes: Value(targetMinutes),
      estimatedMinutes: Value(estimatedMinutes),
      status: Value(status),
      algorithmVersion: Value(algorithmVersion),
      generatedAt: Value(generatedAt),
    );
  }

  factory DbStudyPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbStudyPlan(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      planDate: serializer.fromJson<DateTime>(json['planDate']),
      targetMinutes: serializer.fromJson<int>(json['targetMinutes']),
      estimatedMinutes: serializer.fromJson<int>(json['estimatedMinutes']),
      status: serializer.fromJson<String>(json['status']),
      algorithmVersion: serializer.fromJson<String>(json['algorithmVersion']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'planDate': serializer.toJson<DateTime>(planDate),
      'targetMinutes': serializer.toJson<int>(targetMinutes),
      'estimatedMinutes': serializer.toJson<int>(estimatedMinutes),
      'status': serializer.toJson<String>(status),
      'algorithmVersion': serializer.toJson<String>(algorithmVersion),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  DbStudyPlan copyWith(
          {String? id,
          String? userId,
          DateTime? planDate,
          int? targetMinutes,
          int? estimatedMinutes,
          String? status,
          String? algorithmVersion,
          DateTime? generatedAt}) =>
      DbStudyPlan(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        planDate: planDate ?? this.planDate,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        status: status ?? this.status,
        algorithmVersion: algorithmVersion ?? this.algorithmVersion,
        generatedAt: generatedAt ?? this.generatedAt,
      );
  DbStudyPlan copyWithCompanion(DbStudyPlansCompanion data) {
    return DbStudyPlan(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      status: data.status.present ? data.status.value : this.status,
      algorithmVersion: data.algorithmVersion.present
          ? data.algorithmVersion.value
          : this.algorithmVersion,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbStudyPlan(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('planDate: $planDate, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('status: $status, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, planDate, targetMinutes,
      estimatedMinutes, status, algorithmVersion, generatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbStudyPlan &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.planDate == this.planDate &&
          other.targetMinutes == this.targetMinutes &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.status == this.status &&
          other.algorithmVersion == this.algorithmVersion &&
          other.generatedAt == this.generatedAt);
}

class DbStudyPlansCompanion extends UpdateCompanion<DbStudyPlan> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> planDate;
  final Value<int> targetMinutes;
  final Value<int> estimatedMinutes;
  final Value<String> status;
  final Value<String> algorithmVersion;
  final Value<DateTime> generatedAt;
  final Value<int> rowid;
  const DbStudyPlansCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.planDate = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbStudyPlansCompanion.insert({
    required String id,
    required String userId,
    required DateTime planDate,
    this.targetMinutes = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    required DateTime generatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        planDate = Value(planDate),
        generatedAt = Value(generatedAt);
  static Insertable<DbStudyPlan> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? planDate,
    Expression<int>? targetMinutes,
    Expression<int>? estimatedMinutes,
    Expression<String>? status,
    Expression<String>? algorithmVersion,
    Expression<DateTime>? generatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (planDate != null) 'plan_date': planDate,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (status != null) 'status': status,
      if (algorithmVersion != null) 'algorithm_version': algorithmVersion,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbStudyPlansCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? planDate,
      Value<int>? targetMinutes,
      Value<int>? estimatedMinutes,
      Value<String>? status,
      Value<String>? algorithmVersion,
      Value<DateTime>? generatedAt,
      Value<int>? rowid}) {
    return DbStudyPlansCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planDate: planDate ?? this.planDate,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (planDate.present) {
      map['plan_date'] = Variable<DateTime>(planDate.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (algorithmVersion.present) {
      map['algorithm_version'] = Variable<String>(algorithmVersion.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbStudyPlansCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('planDate: $planDate, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('status: $status, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbStudyPlanSessionsTable extends DbStudyPlanSessions
    with TableInfo<$DbStudyPlanSessionsTable, DbStudyPlanSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbStudyPlanSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _topicIdMeta =
      const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
      'topic_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sessionTypeMeta =
      const VerificationMeta('sessionType');
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
      'session_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleEnMeta =
      const VerificationMeta('titleEn');
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
      'title_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleAmMeta =
      const VerificationMeta('titleAm');
  @override
  late final GeneratedColumn<String> titleAm = GeneratedColumn<String>(
      'title_am', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionTargetMeta =
      const VerificationMeta('questionTarget');
  @override
  late final GeneratedColumn<int> questionTarget = GeneratedColumn<int>(
      'question_target', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _estimatedMinutesMeta =
      const VerificationMeta('estimatedMinutes');
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
      'estimated_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _priorityScoreMeta =
      const VerificationMeta('priorityScore');
  @override
  late final GeneratedColumn<double> priorityScore = GeneratedColumn<double>(
      'priority_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _reasonCodeMeta =
      const VerificationMeta('reasonCode');
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
      'reason_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonDetailEnMeta =
      const VerificationMeta('reasonDetailEn');
  @override
  late final GeneratedColumn<String> reasonDetailEn = GeneratedColumn<String>(
      'reason_detail_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonDetailAmMeta =
      const VerificationMeta('reasonDetailAm');
  @override
  late final GeneratedColumn<String> reasonDetailAm = GeneratedColumn<String>(
      'reason_detail_am', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('not_started'));
  static const VerificationMeta _questionIdsJsonMeta =
      const VerificationMeta('questionIdsJson');
  @override
  late final GeneratedColumn<String> questionIdsJson = GeneratedColumn<String>(
      'question_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _timeSpentSecondsMeta =
      const VerificationMeta('timeSpentSeconds');
  @override
  late final GeneratedColumn<int> timeSpentSeconds = GeneratedColumn<int>(
      'time_spent_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _scorePercentageMeta =
      const VerificationMeta('scorePercentage');
  @override
  late final GeneratedColumn<double> scorePercentage = GeneratedColumn<double>(
      'score_percentage', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _examVariantMeta =
      const VerificationMeta('examVariant');
  @override
  late final GeneratedColumn<String> examVariant = GeneratedColumn<String>(
      'exam_variant', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _assessmentStructureMeta =
      const VerificationMeta('assessmentStructure');
  @override
  late final GeneratedColumn<String> assessmentStructure =
      GeneratedColumn<String>('assessment_structure', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentDomainMeta =
      const VerificationMeta('contentDomain');
  @override
  late final GeneratedColumn<String> contentDomain = GeneratedColumn<String>(
      'content_domain', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _skillMeta = const VerificationMeta('skill');
  @override
  late final GeneratedColumn<String> skill = GeneratedColumn<String>(
      'skill', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planId,
        subjectId,
        unitId,
        topicId,
        sessionType,
        titleEn,
        titleAm,
        questionTarget,
        estimatedMinutes,
        priorityScore,
        reasonCode,
        reasonDetailEn,
        reasonDetailAm,
        status,
        questionIdsJson,
        completedAt,
        timeSpentSeconds,
        scorePercentage,
        examVariant,
        assessmentStructure,
        contentDomain,
        skill
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_study_plan_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<DbStudyPlanSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta,
          topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    }
    if (data.containsKey('session_type')) {
      context.handle(
          _sessionTypeMeta,
          sessionType.isAcceptableOrUnknown(
              data['session_type']!, _sessionTypeMeta));
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('title_en')) {
      context.handle(_titleEnMeta,
          titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta));
    } else if (isInserting) {
      context.missing(_titleEnMeta);
    }
    if (data.containsKey('title_am')) {
      context.handle(_titleAmMeta,
          titleAm.isAcceptableOrUnknown(data['title_am']!, _titleAmMeta));
    } else if (isInserting) {
      context.missing(_titleAmMeta);
    }
    if (data.containsKey('question_target')) {
      context.handle(
          _questionTargetMeta,
          questionTarget.isAcceptableOrUnknown(
              data['question_target']!, _questionTargetMeta));
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
          _estimatedMinutesMeta,
          estimatedMinutes.isAcceptableOrUnknown(
              data['estimated_minutes']!, _estimatedMinutesMeta));
    }
    if (data.containsKey('priority_score')) {
      context.handle(
          _priorityScoreMeta,
          priorityScore.isAcceptableOrUnknown(
              data['priority_score']!, _priorityScoreMeta));
    }
    if (data.containsKey('reason_code')) {
      context.handle(
          _reasonCodeMeta,
          reasonCode.isAcceptableOrUnknown(
              data['reason_code']!, _reasonCodeMeta));
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('reason_detail_en')) {
      context.handle(
          _reasonDetailEnMeta,
          reasonDetailEn.isAcceptableOrUnknown(
              data['reason_detail_en']!, _reasonDetailEnMeta));
    } else if (isInserting) {
      context.missing(_reasonDetailEnMeta);
    }
    if (data.containsKey('reason_detail_am')) {
      context.handle(
          _reasonDetailAmMeta,
          reasonDetailAm.isAcceptableOrUnknown(
              data['reason_detail_am']!, _reasonDetailAmMeta));
    } else if (isInserting) {
      context.missing(_reasonDetailAmMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('question_ids_json')) {
      context.handle(
          _questionIdsJsonMeta,
          questionIdsJson.isAcceptableOrUnknown(
              data['question_ids_json']!, _questionIdsJsonMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('time_spent_seconds')) {
      context.handle(
          _timeSpentSecondsMeta,
          timeSpentSeconds.isAcceptableOrUnknown(
              data['time_spent_seconds']!, _timeSpentSecondsMeta));
    }
    if (data.containsKey('score_percentage')) {
      context.handle(
          _scorePercentageMeta,
          scorePercentage.isAcceptableOrUnknown(
              data['score_percentage']!, _scorePercentageMeta));
    }
    if (data.containsKey('exam_variant')) {
      context.handle(
          _examVariantMeta,
          examVariant.isAcceptableOrUnknown(
              data['exam_variant']!, _examVariantMeta));
    }
    if (data.containsKey('assessment_structure')) {
      context.handle(
          _assessmentStructureMeta,
          assessmentStructure.isAcceptableOrUnknown(
              data['assessment_structure']!, _assessmentStructureMeta));
    }
    if (data.containsKey('content_domain')) {
      context.handle(
          _contentDomainMeta,
          contentDomain.isAcceptableOrUnknown(
              data['content_domain']!, _contentDomainMeta));
    }
    if (data.containsKey('skill')) {
      context.handle(
          _skillMeta, skill.isAcceptableOrUnknown(data['skill']!, _skillMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbStudyPlanSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbStudyPlanSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id']),
      topicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topic_id']),
      sessionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_type'])!,
      titleEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_en'])!,
      titleAm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_am'])!,
      questionTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}question_target'])!,
      estimatedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}estimated_minutes'])!,
      priorityScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}priority_score'])!,
      reasonCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason_code'])!,
      reasonDetailEn: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reason_detail_en'])!,
      reasonDetailAm: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reason_detail_am'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      questionIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}question_ids_json'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      timeSpentSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}time_spent_seconds'])!,
      scorePercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}score_percentage']),
      examVariant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exam_variant']),
      assessmentStructure: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}assessment_structure']),
      contentDomain: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_domain']),
      skill: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}skill']),
    );
  }

  @override
  $DbStudyPlanSessionsTable createAlias(String alias) {
    return $DbStudyPlanSessionsTable(attachedDatabase, alias);
  }
}

class DbStudyPlanSession extends DataClass
    implements Insertable<DbStudyPlanSession> {
  final String id;
  final String planId;
  final String subjectId;
  final String? unitId;
  final String? topicId;
  final String sessionType;
  final String titleEn;
  final String titleAm;
  final int questionTarget;
  final int estimatedMinutes;
  final double priorityScore;
  final String reasonCode;
  final String reasonDetailEn;
  final String reasonDetailAm;
  final String status;
  final String questionIdsJson;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final double? scorePercentage;
  final String? examVariant;
  final String? assessmentStructure;
  final String? contentDomain;
  final String? skill;
  const DbStudyPlanSession(
      {required this.id,
      required this.planId,
      required this.subjectId,
      this.unitId,
      this.topicId,
      required this.sessionType,
      required this.titleEn,
      required this.titleAm,
      required this.questionTarget,
      required this.estimatedMinutes,
      required this.priorityScore,
      required this.reasonCode,
      required this.reasonDetailEn,
      required this.reasonDetailAm,
      required this.status,
      required this.questionIdsJson,
      this.completedAt,
      required this.timeSpentSeconds,
      this.scorePercentage,
      this.examVariant,
      this.assessmentStructure,
      this.contentDomain,
      this.skill});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['subject_id'] = Variable<String>(subjectId);
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    map['session_type'] = Variable<String>(sessionType);
    map['title_en'] = Variable<String>(titleEn);
    map['title_am'] = Variable<String>(titleAm);
    map['question_target'] = Variable<int>(questionTarget);
    map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    map['priority_score'] = Variable<double>(priorityScore);
    map['reason_code'] = Variable<String>(reasonCode);
    map['reason_detail_en'] = Variable<String>(reasonDetailEn);
    map['reason_detail_am'] = Variable<String>(reasonDetailAm);
    map['status'] = Variable<String>(status);
    map['question_ids_json'] = Variable<String>(questionIdsJson);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['time_spent_seconds'] = Variable<int>(timeSpentSeconds);
    if (!nullToAbsent || scorePercentage != null) {
      map['score_percentage'] = Variable<double>(scorePercentage);
    }
    if (!nullToAbsent || examVariant != null) {
      map['exam_variant'] = Variable<String>(examVariant);
    }
    if (!nullToAbsent || assessmentStructure != null) {
      map['assessment_structure'] = Variable<String>(assessmentStructure);
    }
    if (!nullToAbsent || contentDomain != null) {
      map['content_domain'] = Variable<String>(contentDomain);
    }
    if (!nullToAbsent || skill != null) {
      map['skill'] = Variable<String>(skill);
    }
    return map;
  }

  DbStudyPlanSessionsCompanion toCompanion(bool nullToAbsent) {
    return DbStudyPlanSessionsCompanion(
      id: Value(id),
      planId: Value(planId),
      subjectId: Value(subjectId),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      sessionType: Value(sessionType),
      titleEn: Value(titleEn),
      titleAm: Value(titleAm),
      questionTarget: Value(questionTarget),
      estimatedMinutes: Value(estimatedMinutes),
      priorityScore: Value(priorityScore),
      reasonCode: Value(reasonCode),
      reasonDetailEn: Value(reasonDetailEn),
      reasonDetailAm: Value(reasonDetailAm),
      status: Value(status),
      questionIdsJson: Value(questionIdsJson),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      timeSpentSeconds: Value(timeSpentSeconds),
      scorePercentage: scorePercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(scorePercentage),
      examVariant: examVariant == null && nullToAbsent
          ? const Value.absent()
          : Value(examVariant),
      assessmentStructure: assessmentStructure == null && nullToAbsent
          ? const Value.absent()
          : Value(assessmentStructure),
      contentDomain: contentDomain == null && nullToAbsent
          ? const Value.absent()
          : Value(contentDomain),
      skill:
          skill == null && nullToAbsent ? const Value.absent() : Value(skill),
    );
  }

  factory DbStudyPlanSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbStudyPlanSession(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      titleEn: serializer.fromJson<String>(json['titleEn']),
      titleAm: serializer.fromJson<String>(json['titleAm']),
      questionTarget: serializer.fromJson<int>(json['questionTarget']),
      estimatedMinutes: serializer.fromJson<int>(json['estimatedMinutes']),
      priorityScore: serializer.fromJson<double>(json['priorityScore']),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      reasonDetailEn: serializer.fromJson<String>(json['reasonDetailEn']),
      reasonDetailAm: serializer.fromJson<String>(json['reasonDetailAm']),
      status: serializer.fromJson<String>(json['status']),
      questionIdsJson: serializer.fromJson<String>(json['questionIdsJson']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      timeSpentSeconds: serializer.fromJson<int>(json['timeSpentSeconds']),
      scorePercentage: serializer.fromJson<double?>(json['scorePercentage']),
      examVariant: serializer.fromJson<String?>(json['examVariant']),
      assessmentStructure:
          serializer.fromJson<String?>(json['assessmentStructure']),
      contentDomain: serializer.fromJson<String?>(json['contentDomain']),
      skill: serializer.fromJson<String?>(json['skill']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'subjectId': serializer.toJson<String>(subjectId),
      'unitId': serializer.toJson<String?>(unitId),
      'topicId': serializer.toJson<String?>(topicId),
      'sessionType': serializer.toJson<String>(sessionType),
      'titleEn': serializer.toJson<String>(titleEn),
      'titleAm': serializer.toJson<String>(titleAm),
      'questionTarget': serializer.toJson<int>(questionTarget),
      'estimatedMinutes': serializer.toJson<int>(estimatedMinutes),
      'priorityScore': serializer.toJson<double>(priorityScore),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'reasonDetailEn': serializer.toJson<String>(reasonDetailEn),
      'reasonDetailAm': serializer.toJson<String>(reasonDetailAm),
      'status': serializer.toJson<String>(status),
      'questionIdsJson': serializer.toJson<String>(questionIdsJson),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'timeSpentSeconds': serializer.toJson<int>(timeSpentSeconds),
      'scorePercentage': serializer.toJson<double?>(scorePercentage),
      'examVariant': serializer.toJson<String?>(examVariant),
      'assessmentStructure': serializer.toJson<String?>(assessmentStructure),
      'contentDomain': serializer.toJson<String?>(contentDomain),
      'skill': serializer.toJson<String?>(skill),
    };
  }

  DbStudyPlanSession copyWith(
          {String? id,
          String? planId,
          String? subjectId,
          Value<String?> unitId = const Value.absent(),
          Value<String?> topicId = const Value.absent(),
          String? sessionType,
          String? titleEn,
          String? titleAm,
          int? questionTarget,
          int? estimatedMinutes,
          double? priorityScore,
          String? reasonCode,
          String? reasonDetailEn,
          String? reasonDetailAm,
          String? status,
          String? questionIdsJson,
          Value<DateTime?> completedAt = const Value.absent(),
          int? timeSpentSeconds,
          Value<double?> scorePercentage = const Value.absent(),
          Value<String?> examVariant = const Value.absent(),
          Value<String?> assessmentStructure = const Value.absent(),
          Value<String?> contentDomain = const Value.absent(),
          Value<String?> skill = const Value.absent()}) =>
      DbStudyPlanSession(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        subjectId: subjectId ?? this.subjectId,
        unitId: unitId.present ? unitId.value : this.unitId,
        topicId: topicId.present ? topicId.value : this.topicId,
        sessionType: sessionType ?? this.sessionType,
        titleEn: titleEn ?? this.titleEn,
        titleAm: titleAm ?? this.titleAm,
        questionTarget: questionTarget ?? this.questionTarget,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        priorityScore: priorityScore ?? this.priorityScore,
        reasonCode: reasonCode ?? this.reasonCode,
        reasonDetailEn: reasonDetailEn ?? this.reasonDetailEn,
        reasonDetailAm: reasonDetailAm ?? this.reasonDetailAm,
        status: status ?? this.status,
        questionIdsJson: questionIdsJson ?? this.questionIdsJson,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
        scorePercentage: scorePercentage.present
            ? scorePercentage.value
            : this.scorePercentage,
        examVariant: examVariant.present ? examVariant.value : this.examVariant,
        assessmentStructure: assessmentStructure.present
            ? assessmentStructure.value
            : this.assessmentStructure,
        contentDomain:
            contentDomain.present ? contentDomain.value : this.contentDomain,
        skill: skill.present ? skill.value : this.skill,
      );
  DbStudyPlanSession copyWithCompanion(DbStudyPlanSessionsCompanion data) {
    return DbStudyPlanSession(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      sessionType:
          data.sessionType.present ? data.sessionType.value : this.sessionType,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      titleAm: data.titleAm.present ? data.titleAm.value : this.titleAm,
      questionTarget: data.questionTarget.present
          ? data.questionTarget.value
          : this.questionTarget,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      priorityScore: data.priorityScore.present
          ? data.priorityScore.value
          : this.priorityScore,
      reasonCode:
          data.reasonCode.present ? data.reasonCode.value : this.reasonCode,
      reasonDetailEn: data.reasonDetailEn.present
          ? data.reasonDetailEn.value
          : this.reasonDetailEn,
      reasonDetailAm: data.reasonDetailAm.present
          ? data.reasonDetailAm.value
          : this.reasonDetailAm,
      status: data.status.present ? data.status.value : this.status,
      questionIdsJson: data.questionIdsJson.present
          ? data.questionIdsJson.value
          : this.questionIdsJson,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      timeSpentSeconds: data.timeSpentSeconds.present
          ? data.timeSpentSeconds.value
          : this.timeSpentSeconds,
      scorePercentage: data.scorePercentage.present
          ? data.scorePercentage.value
          : this.scorePercentage,
      examVariant:
          data.examVariant.present ? data.examVariant.value : this.examVariant,
      assessmentStructure: data.assessmentStructure.present
          ? data.assessmentStructure.value
          : this.assessmentStructure,
      contentDomain: data.contentDomain.present
          ? data.contentDomain.value
          : this.contentDomain,
      skill: data.skill.present ? data.skill.value : this.skill,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbStudyPlanSession(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('subjectId: $subjectId, ')
          ..write('unitId: $unitId, ')
          ..write('topicId: $topicId, ')
          ..write('sessionType: $sessionType, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleAm: $titleAm, ')
          ..write('questionTarget: $questionTarget, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('priorityScore: $priorityScore, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonDetailEn: $reasonDetailEn, ')
          ..write('reasonDetailAm: $reasonDetailAm, ')
          ..write('status: $status, ')
          ..write('questionIdsJson: $questionIdsJson, ')
          ..write('completedAt: $completedAt, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('scorePercentage: $scorePercentage, ')
          ..write('examVariant: $examVariant, ')
          ..write('assessmentStructure: $assessmentStructure, ')
          ..write('contentDomain: $contentDomain, ')
          ..write('skill: $skill')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        planId,
        subjectId,
        unitId,
        topicId,
        sessionType,
        titleEn,
        titleAm,
        questionTarget,
        estimatedMinutes,
        priorityScore,
        reasonCode,
        reasonDetailEn,
        reasonDetailAm,
        status,
        questionIdsJson,
        completedAt,
        timeSpentSeconds,
        scorePercentage,
        examVariant,
        assessmentStructure,
        contentDomain,
        skill
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbStudyPlanSession &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.subjectId == this.subjectId &&
          other.unitId == this.unitId &&
          other.topicId == this.topicId &&
          other.sessionType == this.sessionType &&
          other.titleEn == this.titleEn &&
          other.titleAm == this.titleAm &&
          other.questionTarget == this.questionTarget &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.priorityScore == this.priorityScore &&
          other.reasonCode == this.reasonCode &&
          other.reasonDetailEn == this.reasonDetailEn &&
          other.reasonDetailAm == this.reasonDetailAm &&
          other.status == this.status &&
          other.questionIdsJson == this.questionIdsJson &&
          other.completedAt == this.completedAt &&
          other.timeSpentSeconds == this.timeSpentSeconds &&
          other.scorePercentage == this.scorePercentage &&
          other.examVariant == this.examVariant &&
          other.assessmentStructure == this.assessmentStructure &&
          other.contentDomain == this.contentDomain &&
          other.skill == this.skill);
}

class DbStudyPlanSessionsCompanion extends UpdateCompanion<DbStudyPlanSession> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> subjectId;
  final Value<String?> unitId;
  final Value<String?> topicId;
  final Value<String> sessionType;
  final Value<String> titleEn;
  final Value<String> titleAm;
  final Value<int> questionTarget;
  final Value<int> estimatedMinutes;
  final Value<double> priorityScore;
  final Value<String> reasonCode;
  final Value<String> reasonDetailEn;
  final Value<String> reasonDetailAm;
  final Value<String> status;
  final Value<String> questionIdsJson;
  final Value<DateTime?> completedAt;
  final Value<int> timeSpentSeconds;
  final Value<double?> scorePercentage;
  final Value<String?> examVariant;
  final Value<String?> assessmentStructure;
  final Value<String?> contentDomain;
  final Value<String?> skill;
  final Value<int> rowid;
  const DbStudyPlanSessionsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.titleAm = const Value.absent(),
    this.questionTarget = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.priorityScore = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.reasonDetailEn = const Value.absent(),
    this.reasonDetailAm = const Value.absent(),
    this.status = const Value.absent(),
    this.questionIdsJson = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.scorePercentage = const Value.absent(),
    this.examVariant = const Value.absent(),
    this.assessmentStructure = const Value.absent(),
    this.contentDomain = const Value.absent(),
    this.skill = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbStudyPlanSessionsCompanion.insert({
    required String id,
    required String planId,
    required String subjectId,
    this.unitId = const Value.absent(),
    this.topicId = const Value.absent(),
    required String sessionType,
    required String titleEn,
    required String titleAm,
    this.questionTarget = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.priorityScore = const Value.absent(),
    required String reasonCode,
    required String reasonDetailEn,
    required String reasonDetailAm,
    this.status = const Value.absent(),
    this.questionIdsJson = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.scorePercentage = const Value.absent(),
    this.examVariant = const Value.absent(),
    this.assessmentStructure = const Value.absent(),
    this.contentDomain = const Value.absent(),
    this.skill = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        planId = Value(planId),
        subjectId = Value(subjectId),
        sessionType = Value(sessionType),
        titleEn = Value(titleEn),
        titleAm = Value(titleAm),
        reasonCode = Value(reasonCode),
        reasonDetailEn = Value(reasonDetailEn),
        reasonDetailAm = Value(reasonDetailAm);
  static Insertable<DbStudyPlanSession> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? subjectId,
    Expression<String>? unitId,
    Expression<String>? topicId,
    Expression<String>? sessionType,
    Expression<String>? titleEn,
    Expression<String>? titleAm,
    Expression<int>? questionTarget,
    Expression<int>? estimatedMinutes,
    Expression<double>? priorityScore,
    Expression<String>? reasonCode,
    Expression<String>? reasonDetailEn,
    Expression<String>? reasonDetailAm,
    Expression<String>? status,
    Expression<String>? questionIdsJson,
    Expression<DateTime>? completedAt,
    Expression<int>? timeSpentSeconds,
    Expression<double>? scorePercentage,
    Expression<String>? examVariant,
    Expression<String>? assessmentStructure,
    Expression<String>? contentDomain,
    Expression<String>? skill,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (subjectId != null) 'subject_id': subjectId,
      if (unitId != null) 'unit_id': unitId,
      if (topicId != null) 'topic_id': topicId,
      if (sessionType != null) 'session_type': sessionType,
      if (titleEn != null) 'title_en': titleEn,
      if (titleAm != null) 'title_am': titleAm,
      if (questionTarget != null) 'question_target': questionTarget,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (priorityScore != null) 'priority_score': priorityScore,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonDetailEn != null) 'reason_detail_en': reasonDetailEn,
      if (reasonDetailAm != null) 'reason_detail_am': reasonDetailAm,
      if (status != null) 'status': status,
      if (questionIdsJson != null) 'question_ids_json': questionIdsJson,
      if (completedAt != null) 'completed_at': completedAt,
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (scorePercentage != null) 'score_percentage': scorePercentage,
      if (examVariant != null) 'exam_variant': examVariant,
      if (assessmentStructure != null)
        'assessment_structure': assessmentStructure,
      if (contentDomain != null) 'content_domain': contentDomain,
      if (skill != null) 'skill': skill,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbStudyPlanSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? planId,
      Value<String>? subjectId,
      Value<String?>? unitId,
      Value<String?>? topicId,
      Value<String>? sessionType,
      Value<String>? titleEn,
      Value<String>? titleAm,
      Value<int>? questionTarget,
      Value<int>? estimatedMinutes,
      Value<double>? priorityScore,
      Value<String>? reasonCode,
      Value<String>? reasonDetailEn,
      Value<String>? reasonDetailAm,
      Value<String>? status,
      Value<String>? questionIdsJson,
      Value<DateTime?>? completedAt,
      Value<int>? timeSpentSeconds,
      Value<double?>? scorePercentage,
      Value<String?>? examVariant,
      Value<String?>? assessmentStructure,
      Value<String?>? contentDomain,
      Value<String?>? skill,
      Value<int>? rowid}) {
    return DbStudyPlanSessionsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      subjectId: subjectId ?? this.subjectId,
      unitId: unitId ?? this.unitId,
      topicId: topicId ?? this.topicId,
      sessionType: sessionType ?? this.sessionType,
      titleEn: titleEn ?? this.titleEn,
      titleAm: titleAm ?? this.titleAm,
      questionTarget: questionTarget ?? this.questionTarget,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      priorityScore: priorityScore ?? this.priorityScore,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonDetailEn: reasonDetailEn ?? this.reasonDetailEn,
      reasonDetailAm: reasonDetailAm ?? this.reasonDetailAm,
      status: status ?? this.status,
      questionIdsJson: questionIdsJson ?? this.questionIdsJson,
      completedAt: completedAt ?? this.completedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      examVariant: examVariant ?? this.examVariant,
      assessmentStructure: assessmentStructure ?? this.assessmentStructure,
      contentDomain: contentDomain ?? this.contentDomain,
      skill: skill ?? this.skill,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (titleAm.present) {
      map['title_am'] = Variable<String>(titleAm.value);
    }
    if (questionTarget.present) {
      map['question_target'] = Variable<int>(questionTarget.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (priorityScore.present) {
      map['priority_score'] = Variable<double>(priorityScore.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (reasonDetailEn.present) {
      map['reason_detail_en'] = Variable<String>(reasonDetailEn.value);
    }
    if (reasonDetailAm.present) {
      map['reason_detail_am'] = Variable<String>(reasonDetailAm.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (questionIdsJson.present) {
      map['question_ids_json'] = Variable<String>(questionIdsJson.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (timeSpentSeconds.present) {
      map['time_spent_seconds'] = Variable<int>(timeSpentSeconds.value);
    }
    if (scorePercentage.present) {
      map['score_percentage'] = Variable<double>(scorePercentage.value);
    }
    if (examVariant.present) {
      map['exam_variant'] = Variable<String>(examVariant.value);
    }
    if (assessmentStructure.present) {
      map['assessment_structure'] = Variable<String>(assessmentStructure.value);
    }
    if (contentDomain.present) {
      map['content_domain'] = Variable<String>(contentDomain.value);
    }
    if (skill.present) {
      map['skill'] = Variable<String>(skill.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbStudyPlanSessionsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('subjectId: $subjectId, ')
          ..write('unitId: $unitId, ')
          ..write('topicId: $topicId, ')
          ..write('sessionType: $sessionType, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleAm: $titleAm, ')
          ..write('questionTarget: $questionTarget, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('priorityScore: $priorityScore, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonDetailEn: $reasonDetailEn, ')
          ..write('reasonDetailAm: $reasonDetailAm, ')
          ..write('status: $status, ')
          ..write('questionIdsJson: $questionIdsJson, ')
          ..write('completedAt: $completedAt, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('scorePercentage: $scorePercentage, ')
          ..write('examVariant: $examVariant, ')
          ..write('assessmentStructure: $assessmentStructure, ')
          ..write('contentDomain: $contentDomain, ')
          ..write('skill: $skill, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DbExamAttemptsTable dbExamAttempts = $DbExamAttemptsTable(this);
  late final $DbActiveAttemptsTable dbActiveAttempts =
      $DbActiveAttemptsTable(this);
  late final $DbBookmarksTable dbBookmarks = $DbBookmarksTable(this);
  late final $DbMistakesTable dbMistakes = $DbMistakesTable(this);
  late final $DbCoinLedgerTable dbCoinLedger = $DbCoinLedgerTable(this);
  late final $DbSyncQueueTable dbSyncQueue = $DbSyncQueueTable(this);
  late final $DbStudyPlansTable dbStudyPlans = $DbStudyPlansTable(this);
  late final $DbStudyPlanSessionsTable dbStudyPlanSessions =
      $DbStudyPlanSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        dbExamAttempts,
        dbActiveAttempts,
        dbBookmarks,
        dbMistakes,
        dbCoinLedger,
        dbSyncQueue,
        dbStudyPlans,
        dbStudyPlanSessions
      ];
}

typedef $$DbExamAttemptsTableCreateCompanionBuilder = DbExamAttemptsCompanion
    Function({
  required String id,
  required String userId,
  required String examId,
  required String examTitle,
  required String subjectId,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<int> totalQuestions,
  Value<int> score,
  Value<double> percentage,
  Value<int> correctCount,
  Value<int> incorrectCount,
  Value<int> skippedCount,
  Value<bool> isCompleted,
  Value<String> syncStatus,
  required String responsesJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DbExamAttemptsTableUpdateCompanionBuilder = DbExamAttemptsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> examId,
  Value<String> examTitle,
  Value<String> subjectId,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<int> totalQuestions,
  Value<int> score,
  Value<double> percentage,
  Value<int> correctCount,
  Value<int> incorrectCount,
  Value<int> skippedCount,
  Value<bool> isCompleted,
  Value<String> syncStatus,
  Value<String> responsesJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DbExamAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $DbExamAttemptsTable> {
  $$DbExamAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examTitle => $composableBuilder(
      column: $table.examTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get skippedCount => $composableBuilder(
      column: $table.skippedCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responsesJson => $composableBuilder(
      column: $table.responsesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DbExamAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbExamAttemptsTable> {
  $$DbExamAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examId => $composableBuilder(
      column: $table.examId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examTitle => $composableBuilder(
      column: $table.examTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get skippedCount => $composableBuilder(
      column: $table.skippedCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responsesJson => $composableBuilder(
      column: $table.responsesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DbExamAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbExamAttemptsTable> {
  $$DbExamAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get examTitle =>
      $composableBuilder(column: $table.examTitle, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
      column: $table.percentage, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount, builder: (column) => column);

  GeneratedColumn<int> get skippedCount => $composableBuilder(
      column: $table.skippedCount, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get responsesJson => $composableBuilder(
      column: $table.responsesJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbExamAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbExamAttemptsTable,
    DbExamAttempt,
    $$DbExamAttemptsTableFilterComposer,
    $$DbExamAttemptsTableOrderingComposer,
    $$DbExamAttemptsTableAnnotationComposer,
    $$DbExamAttemptsTableCreateCompanionBuilder,
    $$DbExamAttemptsTableUpdateCompanionBuilder,
    (
      DbExamAttempt,
      BaseReferences<_$AppDatabase, $DbExamAttemptsTable, DbExamAttempt>
    ),
    DbExamAttempt,
    PrefetchHooks Function()> {
  $$DbExamAttemptsTableTableManager(
      _$AppDatabase db, $DbExamAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbExamAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbExamAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbExamAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> examId = const Value.absent(),
            Value<String> examTitle = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> totalQuestions = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<double> percentage = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> incorrectCount = const Value.absent(),
            Value<int> skippedCount = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> responsesJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbExamAttemptsCompanion(
            id: id,
            userId: userId,
            examId: examId,
            examTitle: examTitle,
            subjectId: subjectId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            totalQuestions: totalQuestions,
            score: score,
            percentage: percentage,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            skippedCount: skippedCount,
            isCompleted: isCompleted,
            syncStatus: syncStatus,
            responsesJson: responsesJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String examId,
            required String examTitle,
            required String subjectId,
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> totalQuestions = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<double> percentage = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> incorrectCount = const Value.absent(),
            Value<int> skippedCount = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            required String responsesJson,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbExamAttemptsCompanion.insert(
            id: id,
            userId: userId,
            examId: examId,
            examTitle: examTitle,
            subjectId: subjectId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            totalQuestions: totalQuestions,
            score: score,
            percentage: percentage,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            skippedCount: skippedCount,
            isCompleted: isCompleted,
            syncStatus: syncStatus,
            responsesJson: responsesJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbExamAttemptsTable, DbExamAttempt>(table),
                    BaseReferences<_$AppDatabase, $DbExamAttemptsTable,
                        DbExamAttempt>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbExamAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbExamAttemptsTable,
    DbExamAttempt,
    $$DbExamAttemptsTableFilterComposer,
    $$DbExamAttemptsTableOrderingComposer,
    $$DbExamAttemptsTableAnnotationComposer,
    $$DbExamAttemptsTableCreateCompanionBuilder,
    $$DbExamAttemptsTableUpdateCompanionBuilder,
    (
      DbExamAttempt,
      BaseReferences<_$AppDatabase, $DbExamAttemptsTable, DbExamAttempt>
    ),
    DbExamAttempt,
    PrefetchHooks Function()>;
typedef $$DbActiveAttemptsTableCreateCompanionBuilder
    = DbActiveAttemptsCompanion Function({
  required String userId,
  required String attemptJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DbActiveAttemptsTableUpdateCompanionBuilder
    = DbActiveAttemptsCompanion Function({
  Value<String> userId,
  Value<String> attemptJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DbActiveAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $DbActiveAttemptsTable> {
  $$DbActiveAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attemptJson => $composableBuilder(
      column: $table.attemptJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DbActiveAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbActiveAttemptsTable> {
  $$DbActiveAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attemptJson => $composableBuilder(
      column: $table.attemptJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DbActiveAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbActiveAttemptsTable> {
  $$DbActiveAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get attemptJson => $composableBuilder(
      column: $table.attemptJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DbActiveAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbActiveAttemptsTable,
    DbActiveAttempt,
    $$DbActiveAttemptsTableFilterComposer,
    $$DbActiveAttemptsTableOrderingComposer,
    $$DbActiveAttemptsTableAnnotationComposer,
    $$DbActiveAttemptsTableCreateCompanionBuilder,
    $$DbActiveAttemptsTableUpdateCompanionBuilder,
    (
      DbActiveAttempt,
      BaseReferences<_$AppDatabase, $DbActiveAttemptsTable, DbActiveAttempt>
    ),
    DbActiveAttempt,
    PrefetchHooks Function()> {
  $$DbActiveAttemptsTableTableManager(
      _$AppDatabase db, $DbActiveAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbActiveAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbActiveAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbActiveAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> attemptJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbActiveAttemptsCompanion(
            userId: userId,
            attemptJson: attemptJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String attemptJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbActiveAttemptsCompanion.insert(
            userId: userId,
            attemptJson: attemptJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbActiveAttemptsTable, DbActiveAttempt>(table),
                    BaseReferences<_$AppDatabase, $DbActiveAttemptsTable,
                        DbActiveAttempt>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbActiveAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbActiveAttemptsTable,
    DbActiveAttempt,
    $$DbActiveAttemptsTableFilterComposer,
    $$DbActiveAttemptsTableOrderingComposer,
    $$DbActiveAttemptsTableAnnotationComposer,
    $$DbActiveAttemptsTableCreateCompanionBuilder,
    $$DbActiveAttemptsTableUpdateCompanionBuilder,
    (
      DbActiveAttempt,
      BaseReferences<_$AppDatabase, $DbActiveAttemptsTable, DbActiveAttempt>
    ),
    DbActiveAttempt,
    PrefetchHooks Function()>;
typedef $$DbBookmarksTableCreateCompanionBuilder = DbBookmarksCompanion
    Function({
  required String id,
  required String userId,
  required String questionId,
  required String subjectId,
  required String topicId,
  required DateTime createdAt,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$DbBookmarksTableUpdateCompanionBuilder = DbBookmarksCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> questionId,
  Value<String> subjectId,
  Value<String> topicId,
  Value<DateTime> createdAt,
  Value<bool> isActive,
  Value<int> rowid,
});

class $$DbBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $DbBookmarksTable> {
  $$DbBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));
}

class $$DbBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $DbBookmarksTable> {
  $$DbBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));
}

class $$DbBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbBookmarksTable> {
  $$DbBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$DbBookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbBookmarksTable,
    DbBookmark,
    $$DbBookmarksTableFilterComposer,
    $$DbBookmarksTableOrderingComposer,
    $$DbBookmarksTableAnnotationComposer,
    $$DbBookmarksTableCreateCompanionBuilder,
    $$DbBookmarksTableUpdateCompanionBuilder,
    (DbBookmark, BaseReferences<_$AppDatabase, $DbBookmarksTable, DbBookmark>),
    DbBookmark,
    PrefetchHooks Function()> {
  $$DbBookmarksTableTableManager(_$AppDatabase db, $DbBookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String> topicId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbBookmarksCompanion(
            id: id,
            userId: userId,
            questionId: questionId,
            subjectId: subjectId,
            topicId: topicId,
            createdAt: createdAt,
            isActive: isActive,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String questionId,
            required String subjectId,
            required String topicId,
            required DateTime createdAt,
            Value<bool> isActive = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbBookmarksCompanion.insert(
            id: id,
            userId: userId,
            questionId: questionId,
            subjectId: subjectId,
            topicId: topicId,
            createdAt: createdAt,
            isActive: isActive,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbBookmarksTable, DbBookmark>(table),
                    BaseReferences<_$AppDatabase, $DbBookmarksTable,
                        DbBookmark>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbBookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbBookmarksTable,
    DbBookmark,
    $$DbBookmarksTableFilterComposer,
    $$DbBookmarksTableOrderingComposer,
    $$DbBookmarksTableAnnotationComposer,
    $$DbBookmarksTableCreateCompanionBuilder,
    $$DbBookmarksTableUpdateCompanionBuilder,
    (DbBookmark, BaseReferences<_$AppDatabase, $DbBookmarksTable, DbBookmark>),
    DbBookmark,
    PrefetchHooks Function()>;
typedef $$DbMistakesTableCreateCompanionBuilder = DbMistakesCompanion Function({
  required String id,
  required String userId,
  required String questionId,
  required String subjectId,
  Value<String?> unitId,
  Value<String?> topicId,
  Value<String?> lastAttemptId,
  Value<String?> lastSelectedChoiceId,
  Value<DateTime?> firstMissedAt,
  Value<DateTime?> lastMissedAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> missCount,
  Value<int> retryCount,
  Value<int> correctRetryCount,
  Value<String> masteryStatus,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<String> syncStatus,
  Value<int> mistakeCount,
  Value<bool> isMastered,
  Value<DateTime?> lastFailedAt,
  Value<DateTime?> masteredAt,
  Value<int> rowid,
});
typedef $$DbMistakesTableUpdateCompanionBuilder = DbMistakesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> questionId,
  Value<String> subjectId,
  Value<String?> unitId,
  Value<String?> topicId,
  Value<String?> lastAttemptId,
  Value<String?> lastSelectedChoiceId,
  Value<DateTime?> firstMissedAt,
  Value<DateTime?> lastMissedAt,
  Value<DateTime?> lastAttemptAt,
  Value<int> missCount,
  Value<int> retryCount,
  Value<int> correctRetryCount,
  Value<String> masteryStatus,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<String> syncStatus,
  Value<int> mistakeCount,
  Value<bool> isMastered,
  Value<DateTime?> lastFailedAt,
  Value<DateTime?> masteredAt,
  Value<int> rowid,
});

class $$DbMistakesTableFilterComposer
    extends Composer<_$AppDatabase, $DbMistakesTable> {
  $$DbMistakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastAttemptId => $composableBuilder(
      column: $table.lastAttemptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSelectedChoiceId => $composableBuilder(
      column: $table.lastSelectedChoiceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstMissedAt => $composableBuilder(
      column: $table.firstMissedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMissedAt => $composableBuilder(
      column: $table.lastMissedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get missCount => $composableBuilder(
      column: $table.missCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctRetryCount => $composableBuilder(
      column: $table.correctRetryCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get masteryStatus => $composableBuilder(
      column: $table.masteryStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mistakeCount => $composableBuilder(
      column: $table.mistakeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMastered => $composableBuilder(
      column: $table.isMastered, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFailedAt => $composableBuilder(
      column: $table.lastFailedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get masteredAt => $composableBuilder(
      column: $table.masteredAt, builder: (column) => ColumnFilters(column));
}

class $$DbMistakesTableOrderingComposer
    extends Composer<_$AppDatabase, $DbMistakesTable> {
  $$DbMistakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastAttemptId => $composableBuilder(
      column: $table.lastAttemptId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSelectedChoiceId => $composableBuilder(
      column: $table.lastSelectedChoiceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstMissedAt => $composableBuilder(
      column: $table.firstMissedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMissedAt => $composableBuilder(
      column: $table.lastMissedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get missCount => $composableBuilder(
      column: $table.missCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctRetryCount => $composableBuilder(
      column: $table.correctRetryCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get masteryStatus => $composableBuilder(
      column: $table.masteryStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mistakeCount => $composableBuilder(
      column: $table.mistakeCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMastered => $composableBuilder(
      column: $table.isMastered, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFailedAt => $composableBuilder(
      column: $table.lastFailedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get masteredAt => $composableBuilder(
      column: $table.masteredAt, builder: (column) => ColumnOrderings(column));
}

class $$DbMistakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbMistakesTable> {
  $$DbMistakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
      column: $table.questionId, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get lastAttemptId => $composableBuilder(
      column: $table.lastAttemptId, builder: (column) => column);

  GeneratedColumn<String> get lastSelectedChoiceId => $composableBuilder(
      column: $table.lastSelectedChoiceId, builder: (column) => column);

  GeneratedColumn<DateTime> get firstMissedAt => $composableBuilder(
      column: $table.firstMissedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMissedAt => $composableBuilder(
      column: $table.lastMissedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumn<int> get missCount =>
      $composableBuilder(column: $table.missCount, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get correctRetryCount => $composableBuilder(
      column: $table.correctRetryCount, builder: (column) => column);

  GeneratedColumn<String> get masteryStatus => $composableBuilder(
      column: $table.masteryStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<int> get mistakeCount => $composableBuilder(
      column: $table.mistakeCount, builder: (column) => column);

  GeneratedColumn<bool> get isMastered => $composableBuilder(
      column: $table.isMastered, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFailedAt => $composableBuilder(
      column: $table.lastFailedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get masteredAt => $composableBuilder(
      column: $table.masteredAt, builder: (column) => column);
}

class $$DbMistakesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbMistakesTable,
    DbMistake,
    $$DbMistakesTableFilterComposer,
    $$DbMistakesTableOrderingComposer,
    $$DbMistakesTableAnnotationComposer,
    $$DbMistakesTableCreateCompanionBuilder,
    $$DbMistakesTableUpdateCompanionBuilder,
    (DbMistake, BaseReferences<_$AppDatabase, $DbMistakesTable, DbMistake>),
    DbMistake,
    PrefetchHooks Function()> {
  $$DbMistakesTableTableManager(_$AppDatabase db, $DbMistakesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbMistakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbMistakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbMistakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<String?> topicId = const Value.absent(),
            Value<String?> lastAttemptId = const Value.absent(),
            Value<String?> lastSelectedChoiceId = const Value.absent(),
            Value<DateTime?> firstMissedAt = const Value.absent(),
            Value<DateTime?> lastMissedAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> missCount = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> correctRetryCount = const Value.absent(),
            Value<String> masteryStatus = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> mistakeCount = const Value.absent(),
            Value<bool> isMastered = const Value.absent(),
            Value<DateTime?> lastFailedAt = const Value.absent(),
            Value<DateTime?> masteredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbMistakesCompanion(
            id: id,
            userId: userId,
            questionId: questionId,
            subjectId: subjectId,
            unitId: unitId,
            topicId: topicId,
            lastAttemptId: lastAttemptId,
            lastSelectedChoiceId: lastSelectedChoiceId,
            firstMissedAt: firstMissedAt,
            lastMissedAt: lastMissedAt,
            lastAttemptAt: lastAttemptAt,
            missCount: missCount,
            retryCount: retryCount,
            correctRetryCount: correctRetryCount,
            masteryStatus: masteryStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            mistakeCount: mistakeCount,
            isMastered: isMastered,
            lastFailedAt: lastFailedAt,
            masteredAt: masteredAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String questionId,
            required String subjectId,
            Value<String?> unitId = const Value.absent(),
            Value<String?> topicId = const Value.absent(),
            Value<String?> lastAttemptId = const Value.absent(),
            Value<String?> lastSelectedChoiceId = const Value.absent(),
            Value<DateTime?> firstMissedAt = const Value.absent(),
            Value<DateTime?> lastMissedAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> missCount = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> correctRetryCount = const Value.absent(),
            Value<String> masteryStatus = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> mistakeCount = const Value.absent(),
            Value<bool> isMastered = const Value.absent(),
            Value<DateTime?> lastFailedAt = const Value.absent(),
            Value<DateTime?> masteredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbMistakesCompanion.insert(
            id: id,
            userId: userId,
            questionId: questionId,
            subjectId: subjectId,
            unitId: unitId,
            topicId: topicId,
            lastAttemptId: lastAttemptId,
            lastSelectedChoiceId: lastSelectedChoiceId,
            firstMissedAt: firstMissedAt,
            lastMissedAt: lastMissedAt,
            lastAttemptAt: lastAttemptAt,
            missCount: missCount,
            retryCount: retryCount,
            correctRetryCount: correctRetryCount,
            masteryStatus: masteryStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus,
            mistakeCount: mistakeCount,
            isMastered: isMastered,
            lastFailedAt: lastFailedAt,
            masteredAt: masteredAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbMistakesTable, DbMistake>(table),
                    BaseReferences<_$AppDatabase, $DbMistakesTable, DbMistake>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbMistakesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbMistakesTable,
    DbMistake,
    $$DbMistakesTableFilterComposer,
    $$DbMistakesTableOrderingComposer,
    $$DbMistakesTableAnnotationComposer,
    $$DbMistakesTableCreateCompanionBuilder,
    $$DbMistakesTableUpdateCompanionBuilder,
    (DbMistake, BaseReferences<_$AppDatabase, $DbMistakesTable, DbMistake>),
    DbMistake,
    PrefetchHooks Function()>;
typedef $$DbCoinLedgerTableCreateCompanionBuilder = DbCoinLedgerCompanion
    Function({
  required String id,
  required String userId,
  required String transactionType,
  required int amount,
  required String reason,
  Value<String?> relatedEntityId,
  required String idempotencyKey,
  required DateTime createdAt,
  Value<bool> serverVerified,
  Value<int> rowid,
});
typedef $$DbCoinLedgerTableUpdateCompanionBuilder = DbCoinLedgerCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> transactionType,
  Value<int> amount,
  Value<String> reason,
  Value<String?> relatedEntityId,
  Value<String> idempotencyKey,
  Value<DateTime> createdAt,
  Value<bool> serverVerified,
  Value<int> rowid,
});

class $$DbCoinLedgerTableFilterComposer
    extends Composer<_$AppDatabase, $DbCoinLedgerTable> {
  $$DbCoinLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedEntityId => $composableBuilder(
      column: $table.relatedEntityId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get serverVerified => $composableBuilder(
      column: $table.serverVerified,
      builder: (column) => ColumnFilters(column));
}

class $$DbCoinLedgerTableOrderingComposer
    extends Composer<_$AppDatabase, $DbCoinLedgerTable> {
  $$DbCoinLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedEntityId => $composableBuilder(
      column: $table.relatedEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get serverVerified => $composableBuilder(
      column: $table.serverVerified,
      builder: (column) => ColumnOrderings(column));
}

class $$DbCoinLedgerTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbCoinLedgerTable> {
  $$DbCoinLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get relatedEntityId => $composableBuilder(
      column: $table.relatedEntityId, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get serverVerified => $composableBuilder(
      column: $table.serverVerified, builder: (column) => column);
}

class $$DbCoinLedgerTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbCoinLedgerTable,
    DbCoinLedgerEntry,
    $$DbCoinLedgerTableFilterComposer,
    $$DbCoinLedgerTableOrderingComposer,
    $$DbCoinLedgerTableAnnotationComposer,
    $$DbCoinLedgerTableCreateCompanionBuilder,
    $$DbCoinLedgerTableUpdateCompanionBuilder,
    (
      DbCoinLedgerEntry,
      BaseReferences<_$AppDatabase, $DbCoinLedgerTable, DbCoinLedgerEntry>
    ),
    DbCoinLedgerEntry,
    PrefetchHooks Function()> {
  $$DbCoinLedgerTableTableManager(_$AppDatabase db, $DbCoinLedgerTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbCoinLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbCoinLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbCoinLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> transactionType = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> relatedEntityId = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> serverVerified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbCoinLedgerCompanion(
            id: id,
            userId: userId,
            transactionType: transactionType,
            amount: amount,
            reason: reason,
            relatedEntityId: relatedEntityId,
            idempotencyKey: idempotencyKey,
            createdAt: createdAt,
            serverVerified: serverVerified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String transactionType,
            required int amount,
            required String reason,
            Value<String?> relatedEntityId = const Value.absent(),
            required String idempotencyKey,
            required DateTime createdAt,
            Value<bool> serverVerified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbCoinLedgerCompanion.insert(
            id: id,
            userId: userId,
            transactionType: transactionType,
            amount: amount,
            reason: reason,
            relatedEntityId: relatedEntityId,
            idempotencyKey: idempotencyKey,
            createdAt: createdAt,
            serverVerified: serverVerified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbCoinLedgerTable, DbCoinLedgerEntry>(table),
                    BaseReferences<_$AppDatabase, $DbCoinLedgerTable,
                        DbCoinLedgerEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbCoinLedgerTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbCoinLedgerTable,
    DbCoinLedgerEntry,
    $$DbCoinLedgerTableFilterComposer,
    $$DbCoinLedgerTableOrderingComposer,
    $$DbCoinLedgerTableAnnotationComposer,
    $$DbCoinLedgerTableCreateCompanionBuilder,
    $$DbCoinLedgerTableUpdateCompanionBuilder,
    (
      DbCoinLedgerEntry,
      BaseReferences<_$AppDatabase, $DbCoinLedgerTable, DbCoinLedgerEntry>
    ),
    DbCoinLedgerEntry,
    PrefetchHooks Function()>;
typedef $$DbSyncQueueTableCreateCompanionBuilder = DbSyncQueueCompanion
    Function({
  required String id,
  required String operationType,
  required String payloadJson,
  required String idempotencyKey,
  Value<int> retryCount,
  required DateTime nextRetryAt,
  Value<String?> lastError,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DbSyncQueueTableUpdateCompanionBuilder = DbSyncQueueCompanion
    Function({
  Value<String> id,
  Value<String> operationType,
  Value<String> payloadJson,
  Value<String> idempotencyKey,
  Value<int> retryCount,
  Value<DateTime> nextRetryAt,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DbSyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $DbSyncQueueTable> {
  $$DbSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DbSyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $DbSyncQueueTable> {
  $$DbSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operationType => $composableBuilder(
      column: $table.operationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DbSyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbSyncQueueTable> {
  $$DbSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DbSyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbSyncQueueTable,
    DbSyncQueueItem,
    $$DbSyncQueueTableFilterComposer,
    $$DbSyncQueueTableOrderingComposer,
    $$DbSyncQueueTableAnnotationComposer,
    $$DbSyncQueueTableCreateCompanionBuilder,
    $$DbSyncQueueTableUpdateCompanionBuilder,
    (
      DbSyncQueueItem,
      BaseReferences<_$AppDatabase, $DbSyncQueueTable, DbSyncQueueItem>
    ),
    DbSyncQueueItem,
    PrefetchHooks Function()> {
  $$DbSyncQueueTableTableManager(_$AppDatabase db, $DbSyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> operationType = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> nextRetryAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbSyncQueueCompanion(
            id: id,
            operationType: operationType,
            payloadJson: payloadJson,
            idempotencyKey: idempotencyKey,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String operationType,
            required String payloadJson,
            required String idempotencyKey,
            Value<int> retryCount = const Value.absent(),
            required DateTime nextRetryAt,
            Value<String?> lastError = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbSyncQueueCompanion.insert(
            id: id,
            operationType: operationType,
            payloadJson: payloadJson,
            idempotencyKey: idempotencyKey,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbSyncQueueTable, DbSyncQueueItem>(table),
                    BaseReferences<_$AppDatabase, $DbSyncQueueTable,
                        DbSyncQueueItem>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbSyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbSyncQueueTable,
    DbSyncQueueItem,
    $$DbSyncQueueTableFilterComposer,
    $$DbSyncQueueTableOrderingComposer,
    $$DbSyncQueueTableAnnotationComposer,
    $$DbSyncQueueTableCreateCompanionBuilder,
    $$DbSyncQueueTableUpdateCompanionBuilder,
    (
      DbSyncQueueItem,
      BaseReferences<_$AppDatabase, $DbSyncQueueTable, DbSyncQueueItem>
    ),
    DbSyncQueueItem,
    PrefetchHooks Function()>;
typedef $$DbStudyPlansTableCreateCompanionBuilder = DbStudyPlansCompanion
    Function({
  required String id,
  required String userId,
  required DateTime planDate,
  Value<int> targetMinutes,
  Value<int> estimatedMinutes,
  Value<String> status,
  Value<String> algorithmVersion,
  required DateTime generatedAt,
  Value<int> rowid,
});
typedef $$DbStudyPlansTableUpdateCompanionBuilder = DbStudyPlansCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> planDate,
  Value<int> targetMinutes,
  Value<int> estimatedMinutes,
  Value<String> status,
  Value<String> algorithmVersion,
  Value<DateTime> generatedAt,
  Value<int> rowid,
});

class $$DbStudyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DbStudyPlansTable> {
  $$DbStudyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get algorithmVersion => $composableBuilder(
      column: $table.algorithmVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));
}

class $$DbStudyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DbStudyPlansTable> {
  $$DbStudyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get algorithmVersion => $composableBuilder(
      column: $table.algorithmVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DbStudyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbStudyPlansTable> {
  $$DbStudyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
      column: $table.targetMinutes, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get algorithmVersion => $composableBuilder(
      column: $table.algorithmVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);
}

class $$DbStudyPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbStudyPlansTable,
    DbStudyPlan,
    $$DbStudyPlansTableFilterComposer,
    $$DbStudyPlansTableOrderingComposer,
    $$DbStudyPlansTableAnnotationComposer,
    $$DbStudyPlansTableCreateCompanionBuilder,
    $$DbStudyPlansTableUpdateCompanionBuilder,
    (
      DbStudyPlan,
      BaseReferences<_$AppDatabase, $DbStudyPlansTable, DbStudyPlan>
    ),
    DbStudyPlan,
    PrefetchHooks Function()> {
  $$DbStudyPlansTableTableManager(_$AppDatabase db, $DbStudyPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbStudyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbStudyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbStudyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> planDate = const Value.absent(),
            Value<int> targetMinutes = const Value.absent(),
            Value<int> estimatedMinutes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> algorithmVersion = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbStudyPlansCompanion(
            id: id,
            userId: userId,
            planDate: planDate,
            targetMinutes: targetMinutes,
            estimatedMinutes: estimatedMinutes,
            status: status,
            algorithmVersion: algorithmVersion,
            generatedAt: generatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime planDate,
            Value<int> targetMinutes = const Value.absent(),
            Value<int> estimatedMinutes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> algorithmVersion = const Value.absent(),
            required DateTime generatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DbStudyPlansCompanion.insert(
            id: id,
            userId: userId,
            planDate: planDate,
            targetMinutes: targetMinutes,
            estimatedMinutes: estimatedMinutes,
            status: status,
            algorithmVersion: algorithmVersion,
            generatedAt: generatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbStudyPlansTable, DbStudyPlan>(table),
                    BaseReferences<_$AppDatabase, $DbStudyPlansTable,
                        DbStudyPlan>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbStudyPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbStudyPlansTable,
    DbStudyPlan,
    $$DbStudyPlansTableFilterComposer,
    $$DbStudyPlansTableOrderingComposer,
    $$DbStudyPlansTableAnnotationComposer,
    $$DbStudyPlansTableCreateCompanionBuilder,
    $$DbStudyPlansTableUpdateCompanionBuilder,
    (
      DbStudyPlan,
      BaseReferences<_$AppDatabase, $DbStudyPlansTable, DbStudyPlan>
    ),
    DbStudyPlan,
    PrefetchHooks Function()>;
typedef $$DbStudyPlanSessionsTableCreateCompanionBuilder
    = DbStudyPlanSessionsCompanion Function({
  required String id,
  required String planId,
  required String subjectId,
  Value<String?> unitId,
  Value<String?> topicId,
  required String sessionType,
  required String titleEn,
  required String titleAm,
  Value<int> questionTarget,
  Value<int> estimatedMinutes,
  Value<double> priorityScore,
  required String reasonCode,
  required String reasonDetailEn,
  required String reasonDetailAm,
  Value<String> status,
  Value<String> questionIdsJson,
  Value<DateTime?> completedAt,
  Value<int> timeSpentSeconds,
  Value<double?> scorePercentage,
  Value<String?> examVariant,
  Value<String?> assessmentStructure,
  Value<String?> contentDomain,
  Value<String?> skill,
  Value<int> rowid,
});
typedef $$DbStudyPlanSessionsTableUpdateCompanionBuilder
    = DbStudyPlanSessionsCompanion Function({
  Value<String> id,
  Value<String> planId,
  Value<String> subjectId,
  Value<String?> unitId,
  Value<String?> topicId,
  Value<String> sessionType,
  Value<String> titleEn,
  Value<String> titleAm,
  Value<int> questionTarget,
  Value<int> estimatedMinutes,
  Value<double> priorityScore,
  Value<String> reasonCode,
  Value<String> reasonDetailEn,
  Value<String> reasonDetailAm,
  Value<String> status,
  Value<String> questionIdsJson,
  Value<DateTime?> completedAt,
  Value<int> timeSpentSeconds,
  Value<double?> scorePercentage,
  Value<String?> examVariant,
  Value<String?> assessmentStructure,
  Value<String?> contentDomain,
  Value<String?> skill,
  Value<int> rowid,
});

class $$DbStudyPlanSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $DbStudyPlanSessionsTable> {
  $$DbStudyPlanSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleEn => $composableBuilder(
      column: $table.titleEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleAm => $composableBuilder(
      column: $table.titleAm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get questionTarget => $composableBuilder(
      column: $table.questionTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priorityScore => $composableBuilder(
      column: $table.priorityScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonDetailEn => $composableBuilder(
      column: $table.reasonDetailEn,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasonDetailAm => $composableBuilder(
      column: $table.reasonDetailAm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get scorePercentage => $composableBuilder(
      column: $table.scorePercentage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examVariant => $composableBuilder(
      column: $table.examVariant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assessmentStructure => $composableBuilder(
      column: $table.assessmentStructure,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentDomain => $composableBuilder(
      column: $table.contentDomain, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get skill => $composableBuilder(
      column: $table.skill, builder: (column) => ColumnFilters(column));
}

class $$DbStudyPlanSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DbStudyPlanSessionsTable> {
  $$DbStudyPlanSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subjectId => $composableBuilder(
      column: $table.subjectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topicId => $composableBuilder(
      column: $table.topicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleEn => $composableBuilder(
      column: $table.titleEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleAm => $composableBuilder(
      column: $table.titleAm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get questionTarget => $composableBuilder(
      column: $table.questionTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priorityScore => $composableBuilder(
      column: $table.priorityScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonDetailEn => $composableBuilder(
      column: $table.reasonDetailEn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasonDetailAm => $composableBuilder(
      column: $table.reasonDetailAm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get scorePercentage => $composableBuilder(
      column: $table.scorePercentage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examVariant => $composableBuilder(
      column: $table.examVariant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assessmentStructure => $composableBuilder(
      column: $table.assessmentStructure,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentDomain => $composableBuilder(
      column: $table.contentDomain,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get skill => $composableBuilder(
      column: $table.skill, builder: (column) => ColumnOrderings(column));
}

class $$DbStudyPlanSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DbStudyPlanSessionsTable> {
  $$DbStudyPlanSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
      column: $table.sessionType, builder: (column) => column);

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get titleAm =>
      $composableBuilder(column: $table.titleAm, builder: (column) => column);

  GeneratedColumn<int> get questionTarget => $composableBuilder(
      column: $table.questionTarget, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes, builder: (column) => column);

  GeneratedColumn<double> get priorityScore => $composableBuilder(
      column: $table.priorityScore, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
      column: $table.reasonCode, builder: (column) => column);

  GeneratedColumn<String> get reasonDetailEn => $composableBuilder(
      column: $table.reasonDetailEn, builder: (column) => column);

  GeneratedColumn<String> get reasonDetailAm => $composableBuilder(
      column: $table.reasonDetailAm, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get questionIdsJson => $composableBuilder(
      column: $table.questionIdsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds, builder: (column) => column);

  GeneratedColumn<double> get scorePercentage => $composableBuilder(
      column: $table.scorePercentage, builder: (column) => column);

  GeneratedColumn<String> get examVariant => $composableBuilder(
      column: $table.examVariant, builder: (column) => column);

  GeneratedColumn<String> get assessmentStructure => $composableBuilder(
      column: $table.assessmentStructure, builder: (column) => column);

  GeneratedColumn<String> get contentDomain => $composableBuilder(
      column: $table.contentDomain, builder: (column) => column);

  GeneratedColumn<String> get skill =>
      $composableBuilder(column: $table.skill, builder: (column) => column);
}

class $$DbStudyPlanSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DbStudyPlanSessionsTable,
    DbStudyPlanSession,
    $$DbStudyPlanSessionsTableFilterComposer,
    $$DbStudyPlanSessionsTableOrderingComposer,
    $$DbStudyPlanSessionsTableAnnotationComposer,
    $$DbStudyPlanSessionsTableCreateCompanionBuilder,
    $$DbStudyPlanSessionsTableUpdateCompanionBuilder,
    (
      DbStudyPlanSession,
      BaseReferences<_$AppDatabase, $DbStudyPlanSessionsTable,
          DbStudyPlanSession>
    ),
    DbStudyPlanSession,
    PrefetchHooks Function()> {
  $$DbStudyPlanSessionsTableTableManager(
      _$AppDatabase db, $DbStudyPlanSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbStudyPlanSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbStudyPlanSessionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbStudyPlanSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> planId = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<String?> unitId = const Value.absent(),
            Value<String?> topicId = const Value.absent(),
            Value<String> sessionType = const Value.absent(),
            Value<String> titleEn = const Value.absent(),
            Value<String> titleAm = const Value.absent(),
            Value<int> questionTarget = const Value.absent(),
            Value<int> estimatedMinutes = const Value.absent(),
            Value<double> priorityScore = const Value.absent(),
            Value<String> reasonCode = const Value.absent(),
            Value<String> reasonDetailEn = const Value.absent(),
            Value<String> reasonDetailAm = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> questionIdsJson = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> timeSpentSeconds = const Value.absent(),
            Value<double?> scorePercentage = const Value.absent(),
            Value<String?> examVariant = const Value.absent(),
            Value<String?> assessmentStructure = const Value.absent(),
            Value<String?> contentDomain = const Value.absent(),
            Value<String?> skill = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbStudyPlanSessionsCompanion(
            id: id,
            planId: planId,
            subjectId: subjectId,
            unitId: unitId,
            topicId: topicId,
            sessionType: sessionType,
            titleEn: titleEn,
            titleAm: titleAm,
            questionTarget: questionTarget,
            estimatedMinutes: estimatedMinutes,
            priorityScore: priorityScore,
            reasonCode: reasonCode,
            reasonDetailEn: reasonDetailEn,
            reasonDetailAm: reasonDetailAm,
            status: status,
            questionIdsJson: questionIdsJson,
            completedAt: completedAt,
            timeSpentSeconds: timeSpentSeconds,
            scorePercentage: scorePercentage,
            examVariant: examVariant,
            assessmentStructure: assessmentStructure,
            contentDomain: contentDomain,
            skill: skill,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String planId,
            required String subjectId,
            Value<String?> unitId = const Value.absent(),
            Value<String?> topicId = const Value.absent(),
            required String sessionType,
            required String titleEn,
            required String titleAm,
            Value<int> questionTarget = const Value.absent(),
            Value<int> estimatedMinutes = const Value.absent(),
            Value<double> priorityScore = const Value.absent(),
            required String reasonCode,
            required String reasonDetailEn,
            required String reasonDetailAm,
            Value<String> status = const Value.absent(),
            Value<String> questionIdsJson = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> timeSpentSeconds = const Value.absent(),
            Value<double?> scorePercentage = const Value.absent(),
            Value<String?> examVariant = const Value.absent(),
            Value<String?> assessmentStructure = const Value.absent(),
            Value<String?> contentDomain = const Value.absent(),
            Value<String?> skill = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DbStudyPlanSessionsCompanion.insert(
            id: id,
            planId: planId,
            subjectId: subjectId,
            unitId: unitId,
            topicId: topicId,
            sessionType: sessionType,
            titleEn: titleEn,
            titleAm: titleAm,
            questionTarget: questionTarget,
            estimatedMinutes: estimatedMinutes,
            priorityScore: priorityScore,
            reasonCode: reasonCode,
            reasonDetailEn: reasonDetailEn,
            reasonDetailAm: reasonDetailAm,
            status: status,
            questionIdsJson: questionIdsJson,
            completedAt: completedAt,
            timeSpentSeconds: timeSpentSeconds,
            scorePercentage: scorePercentage,
            examVariant: examVariant,
            assessmentStructure: assessmentStructure,
            contentDomain: contentDomain,
            skill: skill,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DbStudyPlanSessionsTable, DbStudyPlanSession>(
                        table),
                    BaseReferences<_$AppDatabase, $DbStudyPlanSessionsTable,
                        DbStudyPlanSession>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DbStudyPlanSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DbStudyPlanSessionsTable,
    DbStudyPlanSession,
    $$DbStudyPlanSessionsTableFilterComposer,
    $$DbStudyPlanSessionsTableOrderingComposer,
    $$DbStudyPlanSessionsTableAnnotationComposer,
    $$DbStudyPlanSessionsTableCreateCompanionBuilder,
    $$DbStudyPlanSessionsTableUpdateCompanionBuilder,
    (
      DbStudyPlanSession,
      BaseReferences<_$AppDatabase, $DbStudyPlanSessionsTable,
          DbStudyPlanSession>
    ),
    DbStudyPlanSession,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DbExamAttemptsTableTableManager get dbExamAttempts =>
      $$DbExamAttemptsTableTableManager(_db, _db.dbExamAttempts);
  $$DbActiveAttemptsTableTableManager get dbActiveAttempts =>
      $$DbActiveAttemptsTableTableManager(_db, _db.dbActiveAttempts);
  $$DbBookmarksTableTableManager get dbBookmarks =>
      $$DbBookmarksTableTableManager(_db, _db.dbBookmarks);
  $$DbMistakesTableTableManager get dbMistakes =>
      $$DbMistakesTableTableManager(_db, _db.dbMistakes);
  $$DbCoinLedgerTableTableManager get dbCoinLedger =>
      $$DbCoinLedgerTableTableManager(_db, _db.dbCoinLedger);
  $$DbSyncQueueTableTableManager get dbSyncQueue =>
      $$DbSyncQueueTableTableManager(_db, _db.dbSyncQueue);
  $$DbStudyPlansTableTableManager get dbStudyPlans =>
      $$DbStudyPlansTableTableManager(_db, _db.dbStudyPlans);
  $$DbStudyPlanSessionsTableTableManager get dbStudyPlanSessions =>
      $$DbStudyPlanSessionsTableTableManager(_db, _db.dbStudyPlanSessions);
}

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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.constructDb());

  factory AppDatabase.inMemory() {
    return AppDatabase(impl.constructInMemoryDb());
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Schema upgrades will be specified here
        },
      );
}

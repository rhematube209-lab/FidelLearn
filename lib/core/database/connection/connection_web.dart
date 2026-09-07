import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection({bool logStatements = false}) {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'fidel_learn',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

QueryExecutor inMemoryConnection({bool logStatements = false}) {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'fidel_learn_inmemory',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

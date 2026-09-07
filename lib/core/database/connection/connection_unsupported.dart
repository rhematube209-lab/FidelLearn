import 'package:drift/drift.dart';

QueryExecutor openConnection({bool logStatements = false}) {
  throw UnsupportedError(
      'No suitable database implementation found for this platform.');
}

QueryExecutor inMemoryConnection({bool logStatements = false}) {
  throw UnsupportedError(
      'No suitable in-memory database implementation found for this platform.');
}

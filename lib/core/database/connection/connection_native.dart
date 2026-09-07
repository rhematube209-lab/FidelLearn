import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection({bool logStatements = false}) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fidel_learn.sqlite'));
    return NativeDatabase.createInBackground(file, logStatements: logStatements);
  });
}

QueryExecutor inMemoryConnection({bool logStatements = false}) {
  return NativeDatabase.memory(logStatements: logStatements);
}

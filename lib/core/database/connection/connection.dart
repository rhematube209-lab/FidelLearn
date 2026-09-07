import 'package:drift/drift.dart';

import 'connection_unsupported.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    if (dart.library.io) 'connection_native.dart';

QueryExecutor constructDb({bool logStatements = false}) =>
    openConnection(logStatements: logStatements);

QueryExecutor constructInMemoryDb({bool logStatements = false}) =>
    inMemoryConnection(logStatements: logStatements);

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import '../../lib/services/export_import_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('export and import round trip', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)');
    });

    await db.insert('test', {'name': 'foo'});

    final service = ExportImportService(databaseProvider: () async => db);
    final json = await service.exportToJson();

    await db.delete('test');
    expect(await db.query('test'), isEmpty);

    await service.importFromJson(json);
    final rows = await db.query('test');
    expect(rows.length, 1);
    expect(rows.first['name'], 'foo');

    await db.close();
  });

  test('rejects unknown table names', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY)');
    });

    final service = ExportImportService(databaseProvider: () async => db);
    final badJson = jsonEncode({'unknown_table': []});

    expect(() => service.importFromJson(badJson), throwsFormatException);

    await db.close();
  });
}

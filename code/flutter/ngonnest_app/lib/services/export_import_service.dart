import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ExportImportService {
  final Future<Database> Function() _dbProvider;

  ExportImportService({Future<Database> Function()? databaseProvider})
      : _dbProvider = databaseProvider ?? (() => DatabaseService().database);

  Future<String> exportToJson() async {
    final db = await _dbProvider();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );

    final Map<String, List<Map<String, dynamic>>> data = {};
    for (final table in tables) {
      final tableName = table['name'] as String;
      final rows = await db.query(tableName);
      data[tableName] = rows;
    }

    return jsonEncode(data);
  }

  Future<void> importFromJson(String jsonString) async {
    final db = await _dbProvider();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await db.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF');
      for (final table in data.keys) {
        await txn.delete(table);
      }
      for (final entry in data.entries) {
        final table = entry.key;
        final rows = List<Map<String, dynamic>>.from(entry.value as List);
        for (final row in rows) {
          await txn.insert(table, row);
        }
      }
      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }
}

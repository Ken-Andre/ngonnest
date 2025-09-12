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
    late final Map<String, dynamic> data;
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON format: expected object');
      }
      data = parsed;
    } catch (e) {
      throw FormatException('Failed to parse JSON: $e');
    }

    final db = await _dbProvider();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    final existingTables = tables.map((t) => t['name'] as String).toSet();


    final unknownTables =
        data.keys.where((t) => !existingTables.contains(t)).toList();
    if (unknownTables.isNotEmpty) {
      throw FormatException('Unknown tables: ${unknownTables.join(', ')}');
    }

    final fkStatus = await db.rawQuery('PRAGMA foreign_keys');

    final wasFkOn = fkStatus.first.values.first == 1;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        for (final table in data.keys) {
          if (existingTables.contains(table)) {
            await txn.delete(table);
          }
        }
        for (final entry in data.entries) {
          final table = entry.key;
          if (!existingTables.contains(table)) continue;

          final rows = List<Map<String, dynamic>>.from(entry.value as List);
          for (final row in rows) {
            await txn.insert(table, row);
          for (final row in rows) {
            await txn.insert(table, row);
          }
    
          try {
            final hasSeqTable = await txn.rawQuery(
              // Ensure sqlite_sequence exists before querying
              final seqTableExists = await txn.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='sqlite_sequence'",
              );
              if (seqTableExists.isNotEmpty) {
                final seqRows = await txn.rawQuery(
                  'SELECT seq FROM sqlite_sequence WHERE name = ?',
                  [table],
                );
                if (seqRows.isNotEmpty) {
                  final safeTable = table.replaceAll('"', '""');
                  final maxIdResult =
                      await txn.rawQuery('SELECT MAX(rowid) AS max_id FROM "$safeTable"');
                  final maxId = maxIdResult.first['max_id'] as int?;
                  await txn.rawUpdate(
                    'UPDATE sqlite_sequence SET seq = ? WHERE name = ?',
                    [maxId ?? 0, table],
                  );
                    'UPDATE sqlite_sequence SET seq = ? WHERE name = ?',
                    [maxId, table],
                  );
                } else {
                  await txn.rawInsert(
                    'INSERT INTO sqlite_sequence(name, seq) VALUES(?, ?)',
                    [table, maxId],
                  );
                }
              }
            }
          } catch (_) {
            // Ignore if sqlite_sequence is unavailable on this schema/engine.
          }
            }
          }
        }
      });
    } finally {
      await db.execute("PRAGMA foreign_keys = ${wasFkOn ? 'ON' : 'OFF'}");
//           await txn.delete(table);
//         }
//         for (final entry in data.entries) {
//           final table = entry.key;
//           final rows =
//               List<Map<String, dynamic>>.from(entry.value as List);
//           for (final row in rows) {
//             await txn.insert(table, row);
//           }
//         }
//       });
//     } finally {
//       if (wasFkOn) {
//         await db.execute('PRAGMA foreign_keys = ON');
//       }
    }
  }
}

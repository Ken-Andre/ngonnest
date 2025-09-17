import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

/// Enhanced export/import service with security, performance, and integrity checks
class ExportImportService {
  final Future<Database> Function() _dbProvider;

  ExportImportService({Future<Database> Function()? databaseProvider})
      : _dbProvider = databaseProvider ?? (() => DatabaseService().database);

  /// Tables that should NOT be exported (contain sensitive data)
  static const List<String> _sensitiveTables = [
    'user_sessions',
    'auth_tokens',
    'sensitive_settings',
  ];

  /// Tables that are safe to export (user data)
  static const List<String> _safeTables = [
    'foyer',
    'objets',
    'budget_categories',
    'inventory_transactions',
    'shopping_lists',
    'product_templates',
  ];

  Future<String> exportToJson() async {
    final db = await _dbProvider();

    // Get all tables but filter for safe ones only
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );

    final Map<String, List<Map<String, dynamic>>> data = {};

    for (final table in tables) {
      final tableName = table['name'] as String;

      // Only export safe tables, skip sensitive ones
      if (_safeTables.contains(tableName) && !_sensitiveTables.contains(tableName)) {
        final rows = await db.query(tableName);
        data[tableName] = rows;
      }
    }

    // Add export metadata
    final metadata = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // TODO-S2: ExportImportService - App Version Retrieval (MEDIUM PRIORITY)
      // Description: Implement actual app version retrieval
      // Details: Replace placeholder with package_info_plus package integration
      // Required: Add package_info_plus dependency to pubspec.yaml
      // Implementation: Use PackageInfo.fromPlatform().then((info) => info.version)
      // Impact: Export metadata lacks proper version information
      'exported_tables': data.keys.toList(),
      'security_note': 'This export contains user data. Keep secure.',
    };

    final exportData = {
      '_metadata': metadata,
      ...data,
    };

    return jsonEncode(exportData);
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

    // Extract metadata if present
    final metadata = data['_metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      print('Importing data from ${metadata['export_timestamp']}');
    }

    // Remove metadata from data to import
    data.remove('_metadata');

    final db = await _dbProvider();

    // Get existing tables
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    final existingTables = tables.map((t) => t['name'] as String).toSet();

    // Validate tables exist
    final unknownTables = data.keys.where((t) => !existingTables.contains(t)).toList();
    if (unknownTables.isNotEmpty) {
      throw FormatException('Unknown tables: ${unknownTables.join(', ')}');
    }

    // Validate only safe tables are being imported
    final unsafeTables = data.keys.where((t) => _sensitiveTables.contains(t)).toList();
    if (unsafeTables.isNotEmpty) {
      throw FormatException('Cannot import sensitive tables: ${unsafeTables.join(', ')}');
    }

    // Handle foreign keys properly
    final fkStatus = await db.rawQuery('PRAGMA foreign_keys');
    final wasFkOn = (fkStatus.isNotEmpty && fkStatus.first['foreign_keys'] == 1);

    await db.transaction((txn) async {
      // Disable FK checks during import
      await txn.execute('PRAGMA foreign_keys = OFF');

      try {
        // Clear existing data in tables being imported
        for (final table in data.keys) {
          if (existingTables.contains(table)) {
            await txn.delete(table);
          }
        }

        // Import data using batch operations for performance
        for (final entry in data.entries) {
          final table = entry.key;
          if (!existingTables.contains(table)) continue;

          final rows = List<Map<String, dynamic>>.from(entry.value as List);

          // Use batch insert for better performance
          final batch = txn.batch();

          for (final row in rows) {
            batch.insert(table, row);
          }

          await batch.commit(noResult: true);
        }

        // Check foreign key integrity after import
        final violations = await txn.rawQuery('PRAGMA foreign_key_check');
        if (violations.isNotEmpty) {
          throw Exception('Import failed: ${violations.length} foreign key violations found');
        }

      } catch (e) {
        // Transaction will be rolled back automatically on exception
        throw Exception('Import failed: $e');
      } finally {
        // Restore original FK setting
        await txn.execute('PRAGMA foreign_keys = ${wasFkOn ? 'ON' : 'OFF'}');
      }
    });
  }

  /// Get list of tables that will be exported
  Future<List<String>> getExportableTables() async {
    final db = await _dbProvider();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );

    return tables
        .map((t) => t['name'] as String)
        .where((table) => _safeTables.contains(table) && !_sensitiveTables.contains(table))
        .toList();
  }

  /// Validate if an export file is safe to import
  Future<bool> validateImportFile(String jsonString) async {
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed is! Map<String, dynamic>) {
        return false;
      }

      // Check for sensitive tables
      final sensitiveTables = parsed.keys.where((t) => _sensitiveTables.contains(t));
      return sensitiveTables.isEmpty;
    } catch (e) {
      return false;
    }
  }
}

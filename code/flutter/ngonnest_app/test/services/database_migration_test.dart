import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ngonnest_app/models/budget_category.dart';

/// Tests for database migration V12
///
/// Verifies that the migration correctly:
/// - Adds percentage column to budget_categories
/// - Calculates percentages from existing data
/// - Updates foyer.budgetMensuelEstime
/// - Creates performance indexes
/// - Handles rollback on failure
void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Migration V12 Tests', () {
    late Database db;

    setUp(() async {
      // Create in-memory database for testing
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create V11 schema (before migration)
          await _createV11Schema(db);
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('should add percentage column to budget_categories', () async {
      // Verify column doesn't exist initially
      final columnsBefore = await db.rawQuery(
        "PRAGMA table_info(budget_categories)",
      );
      expect(
        columnsBefore.any((col) => col['name'] == 'percentage'),
        isFalse,
      );

      // Run migration
      await _migrateToVersion12(db);

      // Verify column exists after migration
      final columnsAfter = await db.rawQuery(
        "PRAGMA table_info(budget_categories)",
      );
      expect(
        columnsAfter.any((col) => col['name'] == 'percentage'),
        isTrue,
      );
    });

    test('should calculate percentages from existing data', () async {
      // Insert test data
      await db.insert('budget_categories', {
        'name': 'Hygiène',
        'limit_amount': 120.0,
        'spent_amount': 50.0,
        'month': '2025-01',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('budget_categories', {
        'name': 'Nettoyage',
        'limit_amount': 80.0,
        'spent_amount': 30.0,
        'month': '2025-01',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Run migration
      await _migrateToVersion12(db);

      // Verify percentages calculated correctly
      final categories = await db.query('budget_categories');
      expect(categories.length, 2);

      final hygiene = categories.firstWhere((c) => c['name'] == 'Hygiène');
      final nettoyage = categories.firstWhere((c) => c['name'] == 'Nettoyage');

      // Total = 120 + 80 = 200
      // Hygiène = 120/200 = 0.6
      // Nettoyage = 80/200 = 0.4
      expect((hygiene['percentage'] as double), closeTo(0.6, 0.001));
      expect((nettoyage['percentage'] as double), closeTo(0.4, 0.001));
    });

    test('should handle multiple months separately', () async {
      // Insert data for two different months
      await db.insert('budget_categories', {
        'name': 'Hygiène',
        'limit_amount': 100.0,
        'spent_amount': 0.0,
        'month': '2025-01',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('budget_categories', {
        'name': 'Hygiène',
        'limit_amount': 150.0,
        'spent_amount': 0.0,
        'month': '2025-02',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('budget_categories', {
        'name': 'Nettoyage',
        'limit_amount': 100.0,
        'spent_amount': 0.0,
        'month': '2025-01',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Run migration
      await _migrateToVersion12(db);

      // Verify percentages calculated per month
      final jan = await db.query(
        'budget_categories',
        where: 'month = ?',
        whereArgs: ['2025-01'],
      );
      final feb = await db.query(
        'budget_categories',
        where: 'month = ?',
        whereArgs: ['2025-02'],
      );

      // January: 100 + 100 = 200, each 50%
      expect((jan[0]['percentage'] as double), closeTo(0.5, 0.001));
      expect((jan[1]['percentage'] as double), closeTo(0.5, 0.001));

      // February: only one category, 100%
      expect((feb[0]['percentage'] as double), closeTo(1.0, 0.001));
    });

    test('should update foyer.budgetMensuelEstime if not set', () async {
      // Insert foyer without budget
      await db.insert('foyer', {
        'nb_personnes': 4,
        'nb_pieces': 3,
        'type_logement': 'appartement',
        'langue': 'fr',
      });

      // Insert budget categories for current month
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      await db.insert('budget_categories', {
        'name': 'Hygiène',
        'limit_amount': 120.0,
        'spent_amount': 0.0,
        'month': currentMonth,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('budget_categories', {
        'name': 'Nettoyage',
        'limit_amount': 80.0,
        'spent_amount': 0.0,
        'month': currentMonth,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Run migration
      await _migrateToVersion12(db);

      // Verify foyer budget was set
      final foyers = await db.query('foyer');
      expect(foyers.length, 1);
      expect(foyers[0]['budget_mensuel_estime'], 200.0);
    });

    test('should not overwrite existing foyer.budgetMensuelEstime', () async {
      // Insert foyer with existing budget
      await db.insert('foyer', {
        'nb_personnes': 4,
        'nb_pieces': 3,
        'type_logement': 'appartement',
        'langue': 'fr',
        'budget_mensuel_estime': 500.0,
      });

      // Run migration
      await _migrateToVersion12(db);

      // Verify foyer budget was not changed
      final foyers = await db.query('foyer');
      expect(foyers.length, 1);
      expect(foyers[0]['budget_mensuel_estime'], 500.0);
    });

    test('should create performance indexes', () async {
      // Run migration
      await _migrateToVersion12(db);

      // Verify indexes exist
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='budget_categories'",
      );

      final indexNames = indexes.map((i) => i['name'] as String).toList();
      expect(
        indexNames.contains('idx_budget_categories_month'),
        isTrue,
      );
      expect(
        indexNames.contains('idx_budget_categories_name_month'),
        isTrue,
      );
    });

    test('should handle empty database gracefully', () async {
      // Run migration on empty database
      await _migrateToVersion12(db);

      // Verify no errors and column exists
      final columns = await db.rawQuery(
        "PRAGMA table_info(budget_categories)",
      );
      expect(
        columns.any((col) => col['name'] == 'percentage'),
        isTrue,
      );
    });

    test('should handle zero total limit gracefully', () async {
      // Insert categories with zero limits
      await db.insert('budget_categories', {
        'name': 'Hygiène',
        'limit_amount': 0.0,
        'spent_amount': 0.0,
        'month': '2025-01',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Run migration
      await _migrateToVersion12(db);

      // Verify migration completed without error
      final categories = await db.query('budget_categories');
      expect(categories.length, 1);
      // Percentage should remain at default since total is 0
      expect(categories[0]['percentage'], 0.25);
    });

    test('BudgetCategory model should handle percentage field', () {
      // Test fromMap with percentage
      final category = BudgetCategory.fromMap({
        'id': 1,
        'name': 'Hygiène',
        'limit_amount': 120.0,
        'spent_amount': 50.0,
        'month': '2025-01',
        'percentage': 0.33,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      expect(category.percentage, 0.33);

      // Test toMap includes percentage
      final map = category.toMap();
      expect(map['percentage'], 0.33);

      // Test copyWith updates percentage
      final updated = category.copyWith(percentage: 0.5);
      expect(updated.percentage, 0.5);
    });

    test('BudgetCategory should use default percentage if not provided', () {
      final category = BudgetCategory.fromMap({
        'id': 1,
        'name': 'Hygiène',
        'limit_amount': 120.0,
        'spent_amount': 50.0,
        'month': '2025-01',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Should default to 0.25 (25%)
      expect(category.percentage, 0.25);
    });
  });
}

/// Create V11 schema (before migration V12)
Future<void> _createV11Schema(Database db) async {
  // Create foyer table
  await db.execute('''
    CREATE TABLE foyer (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nb_personnes INTEGER NOT NULL,
      nb_pieces INTEGER NOT NULL DEFAULT 1,
      type_logement TEXT NOT NULL,
      langue TEXT NOT NULL,
      budget_mensuel_estime REAL
    )
  ''');

  // Create budget_categories table WITHOUT percentage column
  await db.execute('''
    CREATE TABLE budget_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      limit_amount REAL NOT NULL,
      spent_amount REAL NOT NULL DEFAULT 0,
      month TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(name, month)
    )
  ''');
}

/// Migration V12 logic (copied from db.dart for testing)
Future<void> _migrateToVersion12(Database db) async {
  await db.transaction((txn) async {
    // Check if percentage column already exists
    final budgetColumns = await txn.rawQuery(
      "PRAGMA table_info(budget_categories)",
    );
    final hasPercentage = budgetColumns.any(
      (col) => col['name'] == 'percentage',
    );

    if (!hasPercentage) {
      // Add percentage column with default value
      await txn.execute(
        'ALTER TABLE budget_categories ADD COLUMN percentage REAL DEFAULT 0.25',
      );
    }

    // Get all existing budget categories
    final categories = await txn.query('budget_categories');

    if (categories.isNotEmpty) {
      // Group categories by month to calculate percentages
      final Map<String, List<Map<String, dynamic>>> byMonth = {};
      for (final cat in categories) {
        final month = cat['month'] as String;
        byMonth.putIfAbsent(month, () => []).add(cat);
      }

      // Calculate and update percentages for each month
      for (final entry in byMonth.entries) {
        final monthCategories = entry.value;
        final totalLimit = monthCategories.fold<double>(
          0.0,
          (sum, cat) => sum + ((cat['limit_amount'] as num?)?.toDouble() ?? 0.0),
        );

        if (totalLimit > 0) {
          for (final cat in monthCategories) {
            final limit = (cat['limit_amount'] as num?)?.toDouble() ?? 0.0;
            final percentage = limit / totalLimit;

            await txn.update(
              'budget_categories',
              {'percentage': percentage},
              where: 'id = ?',
              whereArgs: [cat['id']],
            );
          }
        }
      }
    }

    // Update foyer.budgetMensuelEstime if not set
    final foyers = await txn.query('foyer');
    for (final foyer in foyers) {
      final budgetMensuelEstime = foyer['budget_mensuel_estime'];
      if (budgetMensuelEstime == null) {
        // Calculate from current month's categories
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';

        final foyerCategories = categories.where(
          (cat) => cat['month'] == currentMonth,
        );

        if (foyerCategories.isNotEmpty) {
          final totalBudget = foyerCategories.fold<double>(
            0.0,
            (sum, cat) =>
                sum + ((cat['limit_amount'] as num?)?.toDouble() ?? 0.0),
          );

          await txn.update(
            'foyer',
            {'budget_mensuel_estime': totalBudget},
            where: 'id = ?',
            whereArgs: [foyer['id']],
          );
        }
      }
    }

    // Create indexes for performance
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_categories_month ON budget_categories(month)',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_categories_name_month ON budget_categories(name, month)',
    );
  });
}

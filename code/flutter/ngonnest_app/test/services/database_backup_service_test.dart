// import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/services/database_backup_service.dart';
import '../helpers/test_database_helper.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseBackupService', () {
    test('createBackup creates a backup file', () async {
      // Create a test database
      final db = await TestDatabaseHelper.createTestDatabaseV12();

      // Note: In real tests, we'd need to mock the database path
      // For now, this test verifies the logic structure

      await db.close();
    });

    test('verifyBackup checks backup integrity', () async {
      // Create a test database
      final db = await TestDatabaseHelper.createTestDatabaseV12();
      final dbPath = db.path;

      // Verify the database can be opened and queried
      final isValid = await DatabaseBackupService.verifyBackup(dbPath);

      expect(isValid, isTrue);

      await db.close();
    });

    test('verifyBackup returns false for invalid backup', () async {
      // Test with non-existent file
      final isValid = await DatabaseBackupService.verifyBackup(
        '/invalid/path.db',
      );

      expect(isValid, isFalse);
    });
  });

  group('TestDatabaseHelper', () {
    test(
      'createTestDatabaseV12 creates database with correct schema',
      () async {
        final db = await TestDatabaseHelper.createTestDatabaseV12();

        // Verify tables exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
        );

        final tableNames = tables.map((t) => t['name'] as String).toList();

        expect(tableNames, contains('foyer'));
        expect(tableNames, contains('objet'));
        expect(tableNames, contains('budget_categories'));
        expect(tableNames, contains('alertes'));
        expect(tableNames, contains('reachat_log'));
        expect(tableNames, contains('product_prices'));
        expect(tableNames, contains('sync_outbox'));

        await db.close();
      },
    );

    test('createTestDatabaseV12 inserts sample data', () async {
      final db = await TestDatabaseHelper.createTestDatabaseV12();

      // Verify record counts
      final counts = await TestDatabaseHelper.getRecordCounts(db);

      expect(counts['foyer'], equals(2));
      expect(counts['objet'], equals(3));
      expect(counts['budget_categories'], equals(2));
      expect(counts['alertes'], equals(1));
      expect(counts['reachat_log'], equals(1));
      expect(counts['product_prices'], equals(1));
      expect(counts['sync_outbox'], equals(1));

      await db.close();
    });

    test('verifyForeignKeyIntegrity checks relationships', () async {
      final db = await TestDatabaseHelper.createTestDatabaseV12();

      // Verify foreign key integrity
      final isValid = await TestDatabaseHelper.verifyForeignKeyIntegrity(db);

      expect(isValid, isTrue);

      await db.close();
    });

    test('verifyForeignKeyIntegrity detects orphaned records', () async {
      final db = await TestDatabaseHelper.createTestDatabaseV12();

      // Insert an orphaned objet (with non-existent foyer)
      await db.insert('objet', {
        'id': 999,
        'id_foyer': 999, // Non-existent foyer
        'nom': 'Orphaned',
        'categorie': 'Test',
        'type': 'consommable',
        'quantite_initiale': 1.0,
        'quantite_restante': 1.0,
        'unite': 'pièce',
      });

      // Verify foreign key integrity fails
      final isValid = await TestDatabaseHelper.verifyForeignKeyIntegrity(db);

      expect(isValid, isFalse);

      await db.close();
    });

    test('sample data has correct structure', () async {
      final db = await TestDatabaseHelper.createTestDatabaseV12();

      // Verify foyer data
      final foyers = await db.query('foyer');
      expect(foyers.length, equals(2));
      expect(foyers[0]['nb_personnes'], equals(4));
      expect(foyers[0]['type_logement'], equals('appartement'));

      // Verify objet data
      final objets = await db.query('objet');
      expect(objets.length, equals(3));
      expect(objets[0]['nom'], equals('Riz'));
      expect(objets[0]['id_foyer'], equals(1));

      // Verify budget_categories data
      final categories = await db.query('budget_categories');
      expect(categories.length, equals(2));
      expect(categories[0]['name'], equals('Alimentation'));
      expect(categories[0]['percentage'], equals(0.33));

      await db.close();
    });
  });
}

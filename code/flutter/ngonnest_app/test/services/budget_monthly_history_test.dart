import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/services/budget_service.dart';
import '../../lib/services/database_service.dart';

/// Test for Task 11.1: Verify getMonthlyExpenseHistory() implementation
///
/// Requirements being tested:
/// - 9.2: Returns last 12 months of data
/// - 9.3: Month names are in French
/// - Spending amounts are correct
void main() {
  late DatabaseService databaseService;
  late BudgetService budgetService;
  late String testFoyerId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory test database
    databaseService = DatabaseService();
    await databaseService.database; // Initialize database
    
    budgetService = BudgetService();

    // Create test foyer
    final db = await databaseService.database;
    final foyerId = await db.insert('foyer', {
      'nb_personnes': 4,
      'nb_pieces': 3,
      'type_logement': 'appartement',
      'langue': 'fr',
      'budget_mensuel_estime': 500.0,
    });
    testFoyerId = foyerId.toString();
  });

  tearDown(() async {
    final db = await databaseService.database;
    await db.close();
  });

  group('Task 11.1: getMonthlyExpenseHistory() verification', () {
    test('Requirement 9.2: Returns last 12 months of data', () async {
      // Arrange: Create purchases across multiple months
      final db = await databaseService.database;
      final now = DateTime.now();

      // Create purchases for the last 6 months
      for (int i = 0; i < 6; i++) {
        final purchaseDate = DateTime(now.year, now.month - i, 15);
        await db.insert('objet', {
          'id': 'obj-month-$i',
          'id_foyer': testFoyerId,
          'nom': 'Test Product $i',
          'categorie': 'Hygiène',
          'quantite': 1,
          'prix_unitaire': 50.0 + (i * 10.0), // Different amounts per month
          'date_achat': purchaseDate.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Act: Get monthly expense history
      final history = await budgetService.getMonthlyExpenseHistory(
        testFoyerId,
        'Hygiène',
        monthsBack: 12,
      );

      // Assert: Should return 12 months of data
      expect(history.length, equals(12));

      // Verify data structure
      for (final monthData in history) {
        expect(monthData, contains('month'));
        expect(monthData, contains('year'));
        expect(monthData, contains('monthNum'));
        expect(monthData, contains('spending'));
        expect(monthData, contains('monthName'));
      }

      // Verify chronological order (oldest to newest)
      for (int i = 0; i < history.length - 1; i++) {
        final current = history[i];
        final next = history[i + 1];
        
        final currentDate = DateTime(
          current['year'] as int,
          current['monthNum'] as int,
        );
        final nextDate = DateTime(
          next['year'] as int,
          next['monthNum'] as int,
        );
        
        expect(
          currentDate.isBefore(nextDate) || currentDate.isAtSameMomentAs(nextDate),
          isTrue,
          reason: 'History should be in chronological order',
        );
      }
    });

    test('Requirement 9.3: Month names are in French', () async {
      // Arrange: Create a purchase in current month
      final db = await databaseService.database;
      final now = DateTime.now();
      
      await db.insert('objet', {
        'id': 'obj-french-test',
        'id_foyer': testFoyerId,
        'nom': 'Test Product',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 100.0,
        'date_achat': now.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Act: Get monthly expense history
      final history = await budgetService.getMonthlyExpenseHistory(
        testFoyerId,
        'Hygiène',
        monthsBack: 12,
      );

      // Assert: All month names should be in French
      final frenchMonths = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];

      for (final monthData in history) {
        final monthName = monthData['monthName'] as String;
        expect(
          frenchMonths.contains(monthName),
          isTrue,
          reason: 'Month name "$monthName" should be in French',
        );
      }

      // Verify specific months
      final currentMonthData = history.last; // Most recent month
      final expectedMonthName = frenchMonths[now.month - 1];
      expect(currentMonthData['monthName'], equals(expectedMonthName));
    });

    test('Spending amounts are correct', () async {
      // Arrange: Create purchases with known amounts
      final db = await databaseService.database;
      final now = DateTime.now();
      
      // Month 1: 3 purchases totaling 150.0
      final month1 = DateTime(now.year, now.month, 5);
      await db.insert('objet', {
        'id': 'obj-1-1',
        'id_foyer': testFoyerId,
        'nom': 'Product 1',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 50.0,
        'date_achat': month1.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('objet', {
        'id': 'obj-1-2',
        'id_foyer': testFoyerId,
        'nom': 'Product 2',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 60.0,
        'date_achat': month1.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('objet', {
        'id': 'obj-1-3',
        'id_foyer': testFoyerId,
        'nom': 'Product 3',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 40.0,
        'date_achat': month1.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Month 2: 2 purchases totaling 200.0
      final month2 = DateTime(now.year, now.month - 1, 10);
      await db.insert('objet', {
        'id': 'obj-2-1',
        'id_foyer': testFoyerId,
        'nom': 'Product 4',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 100.0,
        'date_achat': month2.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('objet', {
        'id': 'obj-2-2',
        'id_foyer': testFoyerId,
        'nom': 'Product 5',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 100.0,
        'date_achat': month2.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Act: Get monthly expense history
      final history = await budgetService.getMonthlyExpenseHistory(
        testFoyerId,
        'Hygiène',
        monthsBack: 12,
      );

      // Assert: Verify spending amounts
      final currentMonthData = history.firstWhere(
        (m) => m['year'] == now.year && m['monthNum'] == now.month,
      );
      expect(currentMonthData['spending'], equals(150.0));

      final previousMonthData = history.firstWhere(
        (m) => m['year'] == month2.year && m['monthNum'] == month2.month,
      );
      expect(previousMonthData['spending'], equals(200.0));

      // Verify months with no purchases have 0.0 spending
      final emptyMonths = history.where((m) {
        final isCurrentMonth = m['year'] == now.year && m['monthNum'] == now.month;
        final isPreviousMonth = m['year'] == month2.year && m['monthNum'] == month2.month;
        return !isCurrentMonth && !isPreviousMonth;
      });

      for (final emptyMonth in emptyMonths) {
        expect(
          emptyMonth['spending'],
          equals(0.0),
          reason: 'Months without purchases should have 0.0 spending',
        );
      }
    });

    test('Handles different categories correctly', () async {
      // Arrange: Create purchases in different categories
      final db = await databaseService.database;
      final now = DateTime.now();
      
      await db.insert('objet', {
        'id': 'obj-hygiene',
        'id_foyer': testFoyerId,
        'nom': 'Hygiene Product',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 50.0,
        'date_achat': now.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('objet', {
        'id': 'obj-nettoyage',
        'id_foyer': testFoyerId,
        'nom': 'Cleaning Product',
        'categorie': 'Nettoyage',
        'quantite': 1,
        'prix_unitaire': 75.0,
        'date_achat': now.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Act: Get history for each category
      final hygieneHistory = await budgetService.getMonthlyExpenseHistory(
        testFoyerId,
        'Hygiène',
      );
      
      final nettoyageHistory = await budgetService.getMonthlyExpenseHistory(
        testFoyerId,
        'Nettoyage',
      );

      // Assert: Each category should have its own spending
      final currentHygieneMonth = hygieneHistory.firstWhere(
        (m) => m['year'] == now.year && m['monthNum'] == now.month,
      );
      expect(currentHygieneMonth['spending'], equals(50.0));

      final currentNettoyageMonth = nettoyageHistory.firstWhere(
        (m) => m['year'] == now.year && m['monthNum'] == now.month,
      );
      expect(currentNettoyageMonth['spending'], equals(75.0));
    });

    test('Returns empty list on error', () async {
      // Arrange: Use invalid foyer ID
      const invalidFoyerId = 'non-existent-foyer';

      // Act: Get monthly expense history
      final history = await budgetService.getMonthlyExpenseHistory(
        invalidFoyerId,
        'Hygiène',
      );

      // Assert: Should return empty list, not throw error
      expect(history, isEmpty);
    });

    test('Handles null prices correctly', () async {
      // Arrange: Create purchases with null prices
      final db = await databaseService.database;
      final now = DateTime.now();
      
      await db.insert('objet', {
        'id': 'obj-with-price',
        'id_foyer': testFoyerId,
        'nom': 'Product with price',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': 100.0,
        'date_achat': now.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('objet', {
        'id': 'obj-without-price',
        'id_foyer': testFoyerId,
        'nom': 'Product without price',
        'categorie': 'Hygiène',
        'quantite': 1,
        'prix_unitaire': null, // No price
        'date_achat': now.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Act: Get monthly expense history
      final history = await budgetService.getMonthlyExpenseHistory(
        testFoyerId,
        'Hygiène',
      );

      // Assert: Should only count items with prices
      final currentMonthData = history.firstWhere(
        (m) => m['year'] == now.year && m['monthNum'] == now.month,
      );
      expect(
        currentMonthData['spending'],
        equals(100.0),
        reason: 'Should only count items with non-null prices',
      );
    });
  });
}

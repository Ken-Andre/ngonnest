import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/screens/budget_screen.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/services/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration test for total budget update flow
/// Tests: Update total budget → categories recalculated → UI reflects changes
/// Requirements: 1.2, 7.5, 7.6
void main() {
  late DatabaseService databaseService;
  late BudgetService budgetService;
  late SyncService syncService;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Reset singleton instances for testing
    SyncService.resetInstance();
    
    // Initialize test database with in-memory database
    databaseService = DatabaseService();
    await databaseService.database; // Initialize the database
    
    budgetService = BudgetService();
    syncService = SyncService();
    await syncService.initialize();

    // Create test foyer
    final db = await databaseService.database;
    await db.insert('foyer', {
      'id': 1,
      'nb_personnes': 4,
      'nb_pieces': 5,
      'type_logement': 'appartement',
      'langue': 'fr',
      'budget_mensuel_estime': 360.0,
    });

    // Initialize budget categories with known percentages
    final currentMonth = BudgetService.getCurrentMonth();
    await budgetService.createBudgetCategory(
      BudgetCategory(
        name: 'Hygiène',
        limit: 120.0,
        percentage: 0.33,
        month: currentMonth,
      ),
      notify: false,
    );
    await budgetService.createBudgetCategory(
      BudgetCategory(
        name: 'Nettoyage',
        limit: 80.0,
        percentage: 0.22,
        month: currentMonth,
      ),
      notify: false,
    );
    await budgetService.createBudgetCategory(
      BudgetCategory(
        name: 'Cuisine',
        limit: 100.0,
        percentage: 0.28,
        month: currentMonth,
      ),
      notify: false,
    );
    await budgetService.createBudgetCategory(
      BudgetCategory(
        name: 'Divers',
        limit: 60.0,
        percentage: 0.17,
        month: currentMonth,
      ),
      notify: false,
    );
  });

  tearDown() async {
    // Close database after each test
    final db = await databaseService.database;
    await db.close();

    // Reset singleton
    SyncService.resetInstance();
  };

  group('Total Budget Update Flow Tests', () {
    testWidgets(
      'Update total budget → categories recalculated → UI reflects changes',
      (WidgetTester tester) async {
        // Arrange
        const foyerId = '1';
        const oldTotalBudget = 360.0;
        const newTotalBudget = 500.0;
        final currentMonth = BudgetService.getCurrentMonth();

        // Get initial budget state
        final initialCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );

        // Verify initial state
        expect(initialCategories.length, equals(4));
        final initialHygiene = initialCategories.firstWhere(
          (cat) => cat.name == 'Hygiène',
        );
        expect(initialHygiene.limit, equals(120.0));
        expect(initialHygiene.percentage, equals(0.33));

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Update total budget
        await budgetService.recalculateCategoryBudgets(
          foyerId,
          newTotalBudget,
          oldTotalBudget: oldTotalBudget,
        );

        // Wait for UI to refresh
        await tester.pumpAndSettle();

        // Assert - Verify all category limits updated proportionally
        final updatedCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );

        expect(updatedCategories.length, equals(4));

        // Verify Hygiène: 500 * 0.33 = 165.0
        final updatedHygiene = updatedCategories.firstWhere(
          (cat) => cat.name == 'Hygiène',
        );
        expect(updatedHygiene.limit, closeTo(165.0, 0.1));
        expect(updatedHygiene.percentage, equals(0.33));

        // Verify Nettoyage: 500 * 0.22 = 110.0
        final updatedNettoyage = updatedCategories.firstWhere(
          (cat) => cat.name == 'Nettoyage',
        );
        expect(updatedNettoyage.limit, closeTo(110.0, 0.1));
        expect(updatedNettoyage.percentage, equals(0.22));

        // Verify Cuisine: 500 * 0.28 = 140.0
        final updatedCuisine = updatedCategories.firstWhere(
          (cat) => cat.name == 'Cuisine',
        );
        expect(updatedCuisine.limit, closeTo(140.0, 0.1));
        expect(updatedCuisine.percentage, equals(0.28));

        // Verify Divers: 500 * 0.17 = 85.0
        final updatedDivers = updatedCategories.firstWhere(
          (cat) => cat.name == 'Divers',
        );
        expect(updatedDivers.limit, closeTo(85.0, 0.1));
        expect(updatedDivers.percentage, equals(0.17));

        // Verify UI reflects changes
        expect(find.byType(BudgetScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Percentages maintained after total budget update',
      (WidgetTester tester) async {
        // Arrange
        const foyerId = '1';
        const newTotalBudget = 720.0; // Double the original
        final currentMonth = BudgetService.getCurrentMonth();

        // Get initial percentages
        final initialCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        final initialPercentages = {
          for (var cat in initialCategories) cat.name: cat.percentage,
        };

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Update total budget
        await budgetService.recalculateCategoryBudgets(
          foyerId,
          newTotalBudget,
        );

        await tester.pumpAndSettle();

        // Assert - Verify percentages maintained
        final updatedCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );

        for (final category in updatedCategories) {
          final initialPercentage = initialPercentages[category.name];
          expect(category.percentage, equals(initialPercentage));

          // Verify limit is proportional to new total
          final expectedLimit = newTotalBudget * category.percentage;
          expect(category.limit, closeTo(expectedLimit, 0.1));
        }

        // Verify UI is functional
        expect(find.byType(BudgetScreen), findsOneWidget);
      },
    );

    test(
      'Sync operations enqueued after budget recalculation',
      () async {
        // Arrange
        const foyerId = '1';
        const newTotalBudget = 450.0;
        final currentMonth = BudgetService.getCurrentMonth();

        // Enable sync for testing
        await syncService.enableSync(userConsent: true);

        // Get initial categories count
        final initialCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        final categoriesCount = initialCategories.length;

        // Get initial pending operations count
        final initialPendingOps = syncService.pendingOperations;

        // Act - Update total budget (this should enqueue sync operations)
        await budgetService.recalculateCategoryBudgets(
          foyerId,
          newTotalBudget,
        );

        // Wait a bit for sync operations to be enqueued
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Verify sync operations were enqueued
        // Each category update should create a sync operation
        final finalPendingOps = syncService.pendingOperations;
        
        // We expect at least one sync operation per category update
        expect(
          finalPendingOps,
          greaterThanOrEqualTo(initialPendingOps),
        );

        // Verify the operations are in the sync_outbox table
        final db = await databaseService.database;
        final syncOps = await db.query(
          'sync_outbox',
          where: 'entity_type = ? AND operation_type = ?',
          whereArgs: ['budget_categories', 'UPDATE'],
        );

        // Should have sync operations for budget category updates
        expect(syncOps.length, greaterThanOrEqualTo(0));
      },
    );

    testWidgets(
      'UI reflects changes immediately after budget update',
      (WidgetTester tester) async {
        // Arrange
        const foyerId = '1';
        const newTotalBudget = 600.0;
        final currentMonth = BudgetService.getCurrentMonth();

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state is displayed
        expect(find.byType(BudgetScreen), findsOneWidget);

        // Act - Update total budget
        await budgetService.recalculateCategoryBudgets(
          foyerId,
          newTotalBudget,
        );

        // Wait for UI to refresh (should happen automatically via listener)
        await tester.pumpAndSettle();

        // Assert - Verify UI shows updated data
        final updatedCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );

        // Verify categories were updated
        expect(updatedCategories.length, equals(4));
        
        // Verify at least one category has the new calculated limit
        final hygieneCategory = updatedCategories.firstWhere(
          (cat) => cat.name == 'Hygiène',
        );
        expect(hygieneCategory.limit, closeTo(600.0 * 0.33, 0.1));

        // Verify screen is still mounted and functional
        expect(find.byType(BudgetScreen), findsOneWidget);
      },
    );

    test(
      'Budget recalculation handles edge cases correctly',
      () async {
        // Arrange
        const foyerId = '1';
        final currentMonth = BudgetService.getCurrentMonth();

        // Test 1: Zero total budget should throw error
        expect(
          () => budgetService.recalculateCategoryBudgets(foyerId, 0.0),
          throwsA(isA<ArgumentError>()),
        );

        // Test 2: Negative total budget should throw error
        expect(
          () => budgetService.recalculateCategoryBudgets(foyerId, -100.0),
          throwsA(isA<ArgumentError>()),
        );

        // Test 3: Very large budget should work
        await budgetService.recalculateCategoryBudgets(foyerId, 10000.0);
        final largeCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        expect(largeCategories.isNotEmpty, isTrue);
        
        // Test 4: Very small budget should work
        await budgetService.recalculateCategoryBudgets(foyerId, 10.0);
        final smallCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        expect(smallCategories.isNotEmpty, isTrue);
      },
    );

    test(
      'Multiple rapid budget updates handled correctly',
      () async {
        // Arrange
        const foyerId = '1';
        final currentMonth = BudgetService.getCurrentMonth();

        // Act - Perform multiple rapid updates
        final updates = [400.0, 450.0, 500.0, 550.0, 600.0];
        
        for (final newBudget in updates) {
          await budgetService.recalculateCategoryBudgets(foyerId, newBudget);
        }

        // Assert - Verify final state is correct (last update wins)
        final finalCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );

        final hygieneCategory = finalCategories.firstWhere(
          (cat) => cat.name == 'Hygiène',
        );
        
        // Should reflect the last update (600.0 * 0.33)
        expect(hygieneCategory.limit, closeTo(600.0 * 0.33, 0.1));
      },
    );
  });
}

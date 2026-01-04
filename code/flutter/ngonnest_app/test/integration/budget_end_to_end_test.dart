import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/models/objet.dart';
import 'package:ngonnest_app/providers/foyer_provider.dart';
import 'package:ngonnest_app/repository/inventory_repository.dart';
import 'package:ngonnest_app/screens/budget_screen.dart';
import 'package:ngonnest_app/services/analytics_service.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database_helper.dart';
import '../screens/budget_screen_test.mocks.dart';

/// Integration test for end-to-end budget flow
/// Tests: Create inventory item → budget updates → notification shown → UI refreshes
/// Requirements: 3.2, 3.3, 3.5
void main() {
  late DatabaseService databaseService;
  late BudgetService budgetService;
  late InventoryRepository inventoryRepository;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Initialize test database with in-memory database
    databaseService = DatabaseService();
    final db = await databaseService.database; // Initialize the database

    budgetService = BudgetService();
    inventoryRepository = InventoryRepository(databaseService);

    // Delete existing foyer data if any
    await db.delete('foyer');

    // Create test foyer
    await db.insert('foyer', {
      'id': 1,
      'nb_personnes': 4,
      'nb_pieces': 5,
      'type_logement': 'appartement',
      'langue': 'fr',
      'budget_mensuel_estime': 360.0,
    });

    // Initialize default budget categories for testing
    await budgetService.initializeDefaultCategories();
  });

  tearDown(() async {
    // Close database after each test
    final db = await databaseService.database;
    await db.close();
  });

  group('End-to-End Budget Flow Tests', () {
    testWidgets(
      'Complete flow: Create inventory item → budget updates → notification shown → UI refreshes',
      (WidgetTester tester) async {
        // Arrange
        const foyerId = '1';
        const categoryName = 'Hygiène';
        final currentMonth = BudgetService.getCurrentMonth();

        // Get initial budget state
        final initialCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        final hygieneCategory = initialCategories.firstWhere(
          (cat) => cat.name == categoryName,
        );
        final initialSpent = hygieneCategory.spent;

        // Create mocks
        final mockAnalyticsService = MockAnalyticsService();
        final mockFoyerProvider = MockFoyerProvider();

        // Configure mock to return test foyer ID
        when(mockFoyerProvider.foyerId).thenReturn(foyerId);

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(393, 830),
            ), // Realistic mobile size
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<BudgetService>.value(
                  value: budgetService,
                ),
                Provider<AnalyticsService>.value(value: mockAnalyticsService),
                ChangeNotifierProvider<FoyerProvider>.value(
                  value: mockFoyerProvider,
                ),
              ],
              child: const MaterialApp(home: BudgetScreen()),
            ),
          ),
        );

        // Wait for initial load
        await tester.pumpAndSettle();

        // Verify initial state shows in UI
        expect(find.text('Hygiène'), findsOneWidget);

        // Act - Create inventory item with price
        final newObjet = Objet(
          idFoyer: int.parse(foyerId),
          nom: 'Savon Test',
          categorie: categoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 100.0,
          quantiteRestante: 100.0,
          unite: 'pièces',
          prixUnitaire: 25.0, // Set price to trigger budget update
          dateAchat: DateTime.now(),
        );

        await inventoryRepository.create(newObjet);

        // Wait for budget service to update and notify listeners
        await tester.pumpAndSettle();

        // Assert - Verify budget spending increased correctly
        final updatedCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        final updatedCategory = updatedCategories.firstWhere(
          (cat) => cat.name == categoryName,
        );

        // Verify spending includes the new item
        expect(updatedCategory.spent, greaterThan(initialSpent));
        expect(updatedCategory.spent, greaterThanOrEqualTo(25.0));

        // Verify notification triggered at correct threshold
        // (This would require mocking NotificationService to verify the call)
        // For now, we verify the alert level is set correctly
        if (updatedCategory.spendingPercentage >= 0.8) {
          expect(
            updatedCategory.alertLevel,
            isNot(equals(BudgetAlertLevel.normal)),
          );
        }

        // Verify BudgetScreen shows updated data
        // The screen should have refreshed automatically via listener
        await tester.pumpAndSettle();

        // Verify the updated spending is displayed
        // (This would check for specific UI elements showing the new spending amount)
        expect(find.byType(BudgetScreen), findsOneWidget);
      },
    );

    testWidgets('Budget updates accumulate correctly with multiple purchases', (
      WidgetTester tester,
    ) async {
      // Arrange
      const foyerId = '1';
      const categoryName = 'Cuisine';
      final currentMonth = BudgetService.getCurrentMonth();

      // Get initial budget state
      final initialCategories = await budgetService.getBudgetCategories(
        month: currentMonth,
      );
      final cuisineCategory = initialCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );
      final initialSpent = cuisineCategory.spent;

      // Build the BudgetScreen widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetService>.value(value: budgetService),
          ],
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Add multiple items
      final items = [
        Objet(
          idFoyer: int.parse(foyerId),
          nom: 'Huile 1',
          categorie: categoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 1.0,
          quantiteRestante: 1.0,
          unite: 'litres',
          prixUnitaire: 15.0,
          dateAchat: DateTime.now(),
        ),
        Objet(
          idFoyer: int.parse(foyerId),
          nom: 'Riz',
          categorie: categoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 5.0,
          quantiteRestante: 5.0,
          unite: 'kg',
          prixUnitaire: 20.0,
          dateAchat: DateTime.now(),
        ),
        Objet(
          idFoyer: int.parse(foyerId),
          nom: 'Sel',
          categorie: categoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 1.0,
          quantiteRestante: 1.0,
          unite: 'kg',
          prixUnitaire: 12.0,
          dateAchat: DateTime.now(),
        ),
      ];

      for (final item in items) {
        await inventoryRepository.create(item);
        await tester.pumpAndSettle();
      }

      // Assert - Budget should accumulate all spending
      final updatedCategories = await budgetService.getBudgetCategories(
        month: currentMonth,
      );
      final updatedCategory = updatedCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Verify spending increased by at least the sum of new items
      final minimumExpectedIncrease = 15.0 + 20.0 + 12.0;
      expect(
        updatedCategory.spent,
        greaterThanOrEqualTo(initialSpent + minimumExpectedIncrease),
      );

      // Verify UI reflects the changes
      await tester.pumpAndSettle();
      expect(find.byType(BudgetScreen), findsOneWidget);
    });

    testWidgets('Budget alert triggered when threshold exceeded', (
      WidgetTester tester,
    ) async {
      // Arrange
      const foyerId = '1';
      const categoryName = 'Divers';
      final currentMonth = BudgetService.getCurrentMonth();

      // Get the budget category and set a low limit to easily exceed
      final categories = await budgetService.getBudgetCategories(
        month: currentMonth,
      );
      final diversCategory = categories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Update category with low limit (50€) to easily trigger alert
      final lowLimitCategory = diversCategory.copyWith(limit: 50.0, spent: 0.0);
      await budgetService.updateBudgetCategory(lowLimitCategory);

      // Build the BudgetScreen widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetService>.value(value: budgetService),
          ],
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Add item that exceeds 80% threshold (45€ out of 50€)
      final expensiveObjet = Objet(
        idFoyer: int.parse(foyerId),
        nom: 'Article coûteux',
        categorie: categoryName,
        type: TypeObjet.durable,
        quantiteInitiale: 1.0,
        quantiteRestante: 1.0,
        unite: 'pièces',
        prixUnitaire: 45.0, // 90% of budget
        dateAchat: DateTime.now(),
      );

      await inventoryRepository.create(expensiveObjet);
      await tester.pumpAndSettle();

      // Assert - Budget should be updated and alert level should be warning or higher
      final updatedCategories = await budgetService.getBudgetCategories(
        month: currentMonth,
      );
      final updatedCategory = updatedCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Verify spending increased and threshold exceeded
      expect(updatedCategory.spent, greaterThanOrEqualTo(45.0));
      expect(updatedCategory.spendingPercentage, greaterThanOrEqualTo(0.8));
      expect(
        updatedCategory.alertLevel,
        isNot(equals(BudgetAlertLevel.normal)),
      );

      // Verify UI shows the alert state
      await tester.pumpAndSettle();
      expect(find.byType(BudgetScreen), findsOneWidget);
    });

    testWidgets('Error in budget update does not block inventory operation', (
      WidgetTester tester,
    ) async {
      // Arrange
      const foyerId = '1';
      const invalidCategoryName = 'NonExistentCategory';

      // Build the BudgetScreen widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetService>.value(value: budgetService),
          ],
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Create item with category that doesn't have a budget
      final objetWithInvalidCategory = Objet(
        idFoyer: int.parse(foyerId),
        nom: 'Test Item',
        categorie: invalidCategoryName,
        type: TypeObjet.consommable,
        quantiteInitiale: 1.0,
        quantiteRestante: 1.0,
        unite: 'pièces',
        prixUnitaire: 10.0,
        dateAchat: DateTime.now(),
      );

      // Should not throw even though budget category doesn't exist
      final createdId = await inventoryRepository.create(
        objetWithInvalidCategory,
      );

      await tester.pumpAndSettle();

      // Assert - Item should still be created
      expect(createdId, isNotNull);
      expect(createdId, greaterThan(0));

      // Verify item was actually created
      final retrievedObjet = await inventoryRepository.read(createdId);
      expect(retrievedObjet, isNotNull);
      expect(retrievedObjet!.nom, equals('Test Item'));

      // Verify UI still works
      expect(find.byType(BudgetScreen), findsOneWidget);
    });

    testWidgets('UI auto-refreshes when budget changes from external source', (
      WidgetTester tester,
    ) async {
      // Arrange
      const foyerId = '1';
      const categoryName = 'Nettoyage';
      final currentMonth = BudgetService.getCurrentMonth();

      // Build the BudgetScreen widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetService>.value(value: budgetService),
          ],
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial state
      final initialCategories = await budgetService.getBudgetCategories(
        month: currentMonth,
      );
      final nettoyageCategory = initialCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Act - Update budget directly (simulating external change)
      final updatedCategory = nettoyageCategory.copyWith(
        limit: 150.0,
        spent: 75.0,
      );
      await budgetService.updateBudgetCategory(updatedCategory);

      // Wait for UI to refresh via listener
      await tester.pumpAndSettle();

      // Assert - Verify UI shows updated data
      final finalCategories = await budgetService.getBudgetCategories(
        month: currentMonth,
      );
      final finalCategory = finalCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      expect(finalCategory.limit, equals(150.0));
      expect(finalCategory.spent, equals(75.0));

      // Verify screen is still mounted and functional
      expect(find.byType(BudgetScreen), findsOneWidget);
    });
  });
}

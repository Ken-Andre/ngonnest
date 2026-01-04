import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/models/objet.dart';
import 'package:ngonnest_app/repository/inventory_repository.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration tests for inventory-budget flow
/// Tests the integration between InventoryRepository and BudgetService
/// to ensure budget updates and alerts work correctly when inventory changes
///
/// Requirements: 3.2, 3.3, 3.5
void main() {
  late DatabaseService databaseService;
  late InventoryRepository inventoryRepository;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Initialize test database with in-memory database
    databaseService = DatabaseService();
    await databaseService.database; // Initialize the database
    inventoryRepository = InventoryRepository(databaseService);

    // Initialize default budget categories for testing
    await BudgetService().initializeDefaultCategories();
  });

  tearDown(() async {
    // Close database after each test
    final db = await databaseService.database;
    await db.close();
  });

  group('Inventory-Budget Integration Tests', () {
    test('Test adding inventory item triggers budget update', () async {
      // Arrange
      const foyerId = 1;
      const categoryName = 'Hygiène';
      final currentMonth = BudgetService.getCurrentMonth();

      // Create inventory item with price
      final newObjet = Objet(
        idFoyer: foyerId,
        nom: 'Savon Test',
        categorie: categoryName,
        type: TypeObjet.consommable,
        quantiteInitiale: 100.0,
        quantiteRestante: 100.0,
        unite: 'pièces',
        prixUnitaire: 25.0, // Set price to trigger budget update
        dateAchat: DateTime.now(),
      );

      // Act
      await inventoryRepository.create(newObjet);

      // Assert - Budget should be updated with the item's price
      final updatedCategories = await BudgetService().getBudgetCategories(
        month: currentMonth,
      );
      final updatedCategory = updatedCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Verify spending includes the new item (at least 25.0)
      expect(updatedCategory.spent, greaterThanOrEqualTo(25.0));
    });

    test(
      'Test adding inventory item without price does not trigger budget update',
      () async {
        // Arrange
        const foyerId = 1;
        const categoryName = 'Nettoyage';
        final currentMonth = BudgetService.getCurrentMonth();

        // Get initial budget state
        final initialCategories = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final nettoyageCategory = initialCategories.firstWhere(
          (cat) => cat.name == categoryName,
        );
        final initialSpent = nettoyageCategory.spent;

        // Create inventory item WITHOUT price
        final newObjet = Objet(
          idFoyer: foyerId,
          nom: 'Éponge',
          categorie: categoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 10.0,
          quantiteRestante: 10.0,
          unite: 'pièces',
          // prixUnitaire not set
          dateAchat: DateTime.now(),
        );

        // Act
        await inventoryRepository.create(newObjet);

        // Assert - Budget should NOT be updated
        final updatedCategories = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final updatedCategory = updatedCategories.firstWhere(
          (cat) => cat.name == categoryName,
        );

        expect(updatedCategory.spent, equals(initialSpent));
      },
    );

    test('Test updating item price triggers budget update', () async {
      // Arrange
      const foyerId = 1;
      const categoryName = 'Cuisine';
      final currentMonth = BudgetService.getCurrentMonth();

      // Create initial item with price
      final initialObjet = Objet(
        idFoyer: foyerId,
        nom: 'Huile',
        categorie: categoryName,
        type: TypeObjet.consommable,
        quantiteInitiale: 1.0,
        quantiteRestante: 1.0,
        unite: 'litres',
        prixUnitaire: 30.0,
        dateAchat: DateTime.now(),
      );

      final objetId = await inventoryRepository.create(initialObjet);

        // Get budget state after creation
        final categoriesAfterCreate = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
      final categoryAfterCreate = categoriesAfterCreate.firstWhere(
        (cat) => cat.name == categoryName,
      );
      final spentAfterCreate = categoryAfterCreate.spent;

      // Act - Update price
      await inventoryRepository.update(objetId, {
        'prixUnitaire': 45.0, // Increase price
      });

        // Assert - Budget should reflect price change (spending increased)
        final updatedCategories = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
      final updatedCategory = updatedCategories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Verify spending increased after price update
      expect(updatedCategory.spent, greaterThan(spentAfterCreate));
    });

    test('Test budget notification shown when threshold exceeded', () async {
      // Arrange
      const foyerId = 1;
      const categoryName = 'Divers';
      final currentMonth = BudgetService.getCurrentMonth();

      // Get the budget category and set a low limit to easily exceed
      final categories = await BudgetService().getBudgetCategories(
        month: currentMonth,
      );
      final diversCategory = categories.firstWhere(
        (cat) => cat.name == categoryName,
      );

      // Update category with low limit (50€) to easily trigger alert
      final lowLimitCategory = diversCategory.copyWith(limit: 50.0, spent: 0.0);
      await BudgetService().updateBudgetCategory(lowLimitCategory);

      // Act - Add item that exceeds 80% threshold (40€ out of 50€)
      final expensiveObjet = Objet(
        idFoyer: foyerId,
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

      // Assert - Budget should be updated and alert level should be warning or higher
      final updatedCategories = await BudgetService().getBudgetCategories(
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
    });

    test(
      'Test error in budget update does not block inventory operation',
      () async {
        // Arrange
        const foyerId = 1;
        const invalidCategoryName = 'NonExistentCategory';

        // Create item with category that doesn't have a budget
        final objetWithInvalidCategory = Objet(
          idFoyer: foyerId,
          nom: 'Test Item',
          categorie: invalidCategoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 1.0,
          quantiteRestante: 1.0,
          unite: 'pièces',
          prixUnitaire: 10.0,
          dateAchat: DateTime.now(),
        );

        // Act - Should not throw even though budget category doesn't exist
        final createdId = await inventoryRepository.create(
          objetWithInvalidCategory,
        );

        // Assert - Item should still be created
        expect(createdId, isNotNull);
        expect(createdId, greaterThan(0));

        // Verify item was actually created
        final retrievedObjet = await inventoryRepository.read(createdId);
        expect(retrievedObjet, isNotNull);
        expect(retrievedObjet!.nom, equals('Test Item'));
      },
    );

    test(
      'Test multiple inventory additions accumulate budget spending',
      () async {
        // Arrange
        const foyerId = 1;
        const categoryName = 'Hygiène';
        final currentMonth = BudgetService.getCurrentMonth();

        // Get initial budget state
        final initialCategories = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final hygieneCategory = initialCategories.firstWhere(
          (cat) => cat.name == categoryName,
        );
        final initialSpent = hygieneCategory.spent;

        // Act - Add multiple items
        final items = [
          Objet(
            idFoyer: foyerId,
            nom: 'Savon 1',
            categorie: categoryName,
            type: TypeObjet.consommable,
            quantiteInitiale: 1.0,
            quantiteRestante: 1.0,
            unite: 'pièces',
            prixUnitaire: 15.0,
            dateAchat: DateTime.now(),
          ),
          Objet(
            idFoyer: foyerId,
            nom: 'Shampoing',
            categorie: categoryName,
            type: TypeObjet.consommable,
            quantiteInitiale: 1.0,
            quantiteRestante: 1.0,
            unite: 'pièces',
            prixUnitaire: 20.0,
            dateAchat: DateTime.now(),
          ),
          Objet(
            idFoyer: foyerId,
            nom: 'Dentifrice',
            categorie: categoryName,
            type: TypeObjet.consommable,
            quantiteInitiale: 1.0,
            quantiteRestante: 1.0,
            unite: 'pièces',
            prixUnitaire: 12.0,
            dateAchat: DateTime.now(),
          ),
        ];

        for (final item in items) {
          await inventoryRepository.create(item);
        }

        // Assert - Budget should accumulate all spending
        final updatedCategories = await BudgetService().getBudgetCategories(
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
      },
    );

    test(
      'Test updating item to zero price does not trigger budget alert',
      () async {
        // Arrange
        const foyerId = 1;
        const categoryName = 'Nettoyage';
        final currentMonth = BudgetService.getCurrentMonth();

        // Create item with price
        final initialObjet = Objet(
          idFoyer: foyerId,
          nom: 'Détergent',
          categorie: categoryName,
          type: TypeObjet.consommable,
          quantiteInitiale: 1.0,
          quantiteRestante: 1.0,
          unite: 'litres',
          prixUnitaire: 25.0,
          dateAchat: DateTime.now(),
        );

        final objetId = await inventoryRepository.create(initialObjet);

        // Get budget state after creation
        final categoriesAfterCreate = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final categoryAfterCreate = categoriesAfterCreate.firstWhere(
          (cat) => cat.name == categoryName,
        );
        final spentAfterCreate = categoryAfterCreate.spent;

        // Act - Update price to 0
        await inventoryRepository.update(objetId, {'prixUnitaire': 0.0});

        // Assert - Budget should not change (0 price items don't trigger alerts)
        final updatedCategories = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final updatedCategory = updatedCategories.firstWhere(
          (cat) => cat.name == categoryName,
        );

        // Spent should remain the same as after create (25.0)
        // because the update with 0 price doesn't trigger budget recalculation
        expect(updatedCategory.spent, equals(spentAfterCreate));
      },
    );

    test(
      'Test changing item category triggers budget update in new category',
      () async {
        // Arrange
        const foyerId = 1;
        const initialCategory = 'Hygiène';
        const newCategory = 'Nettoyage';
        final currentMonth = BudgetService.getCurrentMonth();

        // Create item in Hygiène category
        final initialObjet = Objet(
          idFoyer: foyerId,
          nom: 'Produit polyvalent',
          categorie: initialCategory,
          type: TypeObjet.consommable,
          quantiteInitiale: 1.0,
          quantiteRestante: 1.0,
          unite: 'pièces',
          prixUnitaire: 30.0,
          dateAchat: DateTime.now(),
        );

        final objetId = await inventoryRepository.create(initialObjet);

        // Get initial budget states
        final categoriesAfterCreate = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final nettoyageAfterCreate = categoriesAfterCreate.firstWhere(
          (cat) => cat.name == newCategory,
        );
        final nettoyageSpentBefore = nettoyageAfterCreate.spent;

        // Act - Change category
        await inventoryRepository.update(objetId, {'categorie': newCategory});

        // Assert - New category should be updated with recalculated spending
        final updatedCategories = await BudgetService().getBudgetCategories(
          month: currentMonth,
        );
        final updatedNettoyage = updatedCategories.firstWhere(
          (cat) => cat.name == newCategory,
        );

        // Nettoyage spending should have increased (item moved to this category)
        expect(updatedNettoyage.spent, greaterThan(nettoyageSpentBefore));
      },
    );
  });
}

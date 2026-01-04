import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/services/budget_allocation_rules.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/services/price_service.dart';

import '../helpers/test_helper.dart';

/// Integration tests for onboarding budget initialization
/// Tests the complete flow of budget creation during onboarding
///
/// Requirements: 1.1, 1.3, 9.7
void main() {
  // Initialize test environment once
  setUpAll(() async {
    await TestHelper.initializeTestEnvironment();
  });

  late DatabaseService databaseService;
  late BudgetService budgetService;
  late PriceService priceService;

  setUp(() async {
    // Reset database before each test
    await TestHelper.resetDatabase();
    
    databaseService = DatabaseService();
    budgetService = BudgetService();
    priceService = PriceService();

    // Initialize price data for tests
    await priceService.initializeProductPrices();
  });

  tearDown(() async {
    await TestHelper.cleanupAfterTest();
  });

  group('Onboarding Budget Initialization Integration Tests', () {
    test('Test budgets created during onboarding', () async {
      // Create a test foyer
      final foyer = Foyer(
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      final db = await databaseService.database;
      final foyerId = await db.insert('foyer', foyer.toMap());

      // Initialize recommended budgets
      await budgetService.initializeRecommendedBudgets(foyerId.toString());

      // Verify budgets were created
      final categories = await budgetService.getBudgetCategories();

      expect(categories.length, equals(4),
          reason: 'Should create 4 budget categories');

      // Verify all expected categories exist
      final categoryNames = categories.map((c) => c.name).toSet();
      expect(categoryNames, contains('Hygiène'));
      expect(categoryNames, contains('Nettoyage'));
      expect(categoryNames, contains('Cuisine'));
      expect(categoryNames, contains('Divers'));

      // Verify each category has a percentage
      for (final category in categories) {
        expect(category.percentage, greaterThan(0.0),
            reason: 'Category ${category.name} should have a percentage > 0');
        expect(category.percentage, lessThanOrEqualTo(1.0),
            reason: 'Category ${category.name} percentage should be <= 1.0');
        expect(category.limit, greaterThan(0.0),
            reason: 'Category ${category.name} should have a limit > 0');
      }
    });

    test('Test percentages sum to 1.0 (100%)', () async {
      // Create a test foyer
      final foyer = Foyer(
        nbPersonnes: 2,
        nbPieces: 2,
        typeLogement: 'maison',
        langue: 'fr',
        budgetMensuelEstime: 300.0,
      );

      final db = await databaseService.database;
      final foyerId = await db.insert('foyer', foyer.toMap());

      // Initialize recommended budgets
      await budgetService.initializeRecommendedBudgets(foyerId.toString());

      // Get all categories
      final categories = await budgetService.getBudgetCategories();

      // Calculate sum of percentages
      final totalPercentage = categories.fold<double>(
        0.0,
        (sum, category) => sum + category.percentage,
      );

      // Verify percentages sum to 1.0 (allowing small floating point error)
      expect(totalPercentage, closeTo(1.0, 0.01),
          reason: 'Total percentages should sum to 100%');
    });

    test('Test amounts are reasonable for household profile', () async {
      // Test with a large household
      final largeFoyer = Foyer(
        nbPersonnes: 6,
        nbPieces: 4,
        typeLogement: 'maison',
        langue: 'fr',
        budgetMensuelEstime: 500.0,
      );

      final db = await databaseService.database;
      final largeFoyerId = await db.insert('foyer', largeFoyer.toMap());

      // Initialize budgets
      await budgetService.initializeRecommendedBudgets(
          largeFoyerId.toString());

      final largeCategories = await budgetService.getBudgetCategories();

      // Verify amounts are within reasonable ranges
      for (final category in largeCategories) {
        switch (category.name) {
          case 'Hygiène':
            expect(category.limit, greaterThanOrEqualTo(80.0));
            expect(category.limit, lessThanOrEqualTo(300.0));
            break;
          case 'Nettoyage':
            expect(category.limit, greaterThanOrEqualTo(60.0));
            expect(category.limit, lessThanOrEqualTo(200.0));
            break;
          case 'Cuisine':
            expect(category.limit, greaterThanOrEqualTo(70.0));
            expect(category.limit, lessThanOrEqualTo(250.0));
            break;
          case 'Divers':
            expect(category.limit, greaterThanOrEqualTo(40.0));
            expect(category.limit, lessThanOrEqualTo(150.0));
            break;
        }
      }

      // Test with a small household
      final smallFoyer = Foyer(
        nbPersonnes: 1,
        nbPieces: 1,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 200.0,
      );

      final smallFoyerId = await db.insert('foyer', smallFoyer.toMap());

      // Clear previous categories
      await db.delete('budget_categories');

      // Initialize budgets
      await budgetService.initializeRecommendedBudgets(
          smallFoyerId.toString());

      final smallCategories = await budgetService.getBudgetCategories();

      // Verify small household has lower amounts than large household
      final smallTotal = smallCategories.fold<double>(
        0.0,
        (sum, cat) => sum + cat.limit,
      );
      final largeTotal = largeCategories.fold<double>(
        0.0,
        (sum, cat) => sum + cat.limit,
      );

      expect(smallTotal, lessThan(largeTotal),
          reason:
              'Small household should have lower total budget than large household');
    });

    test('Test fallback to defaults if PriceService unavailable', () async {
      // Create a test foyer
      final foyer = Foyer(
        nbPersonnes: 3,
        nbPieces: 2,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 300.0,
      );

      final db = await databaseService.database;
      final foyerId = await db.insert('foyer', foyer.toMap());

      // Clear price data to simulate PriceService failure
      await db.delete('product_prices');

      // Initialize budgets (should use fallback values)
      await budgetService.initializeRecommendedBudgets(foyerId.toString());

      // Verify budgets were still created
      final categories = await budgetService.getBudgetCategories();

      expect(categories.length, equals(4),
          reason: 'Should create 4 categories even with PriceService failure');

      // Verify all categories have valid data
      for (final category in categories) {
        expect(category.limit, greaterThan(0.0),
            reason:
                'Category ${category.name} should have a valid limit even with fallback');
        expect(category.percentage, greaterThan(0.0),
            reason:
                'Category ${category.name} should have a valid percentage even with fallback');
      }

      // Verify percentages still sum to 1.0
      final totalPercentage = categories.fold<double>(
        0.0,
        (sum, category) => sum + category.percentage,
      );
      expect(totalPercentage, closeTo(1.0, 0.01));
    });

    test('Test analytics event logged', () async {
      // Note: This test verifies the budget initialization completes successfully
      // The actual analytics event logging is tested in the analytics service tests
      // Here we just verify the flow completes without errors

      final foyer = Foyer(
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      );

      final db = await databaseService.database;
      final foyerId = await db.insert('foyer', foyer.toMap());

      // This should complete without throwing
      await budgetService.initializeRecommendedBudgets(foyerId.toString());

      // Verify budgets were created (indicates successful flow)
      final categories = await budgetService.getBudgetCategories();
      expect(categories.length, equals(4));

      // In a real scenario, the analytics event 'onboarding_completed_with_budgets'
      // would be logged in the onboarding screen after this method completes
    });

    test('Test budget initialization with household multipliers', () async {
      // Test that household characteristics affect budget amounts

      // Create two foyers with different profiles
      final foyer1 = Foyer(
        nbPersonnes: 2,
        nbPieces: 2,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 300.0,
      );

      final foyer2 = Foyer(
        nbPersonnes: 5,
        nbPieces: 4,
        typeLogement: 'maison',
        langue: 'fr',
        budgetMensuelEstime: 300.0,
      );

      final db = await databaseService.database;
      final foyerId1 = await db.insert('foyer', foyer1.toMap());
      final foyerId2 = await db.insert('foyer', foyer2.toMap());

      // Initialize budgets for first foyer
      await budgetService.initializeRecommendedBudgets(foyerId1.toString());
      final categories1 = await budgetService.getBudgetCategories();

      // Clear and initialize for second foyer
      await db.delete('budget_categories');
      await budgetService.initializeRecommendedBudgets(foyerId2.toString());
      final categories2 = await budgetService.getBudgetCategories();

      // Compare Hygiène budgets (should be higher for more people)
      final hygiene1 =
          categories1.firstWhere((c) => c.name == 'Hygiène').limit;
      final hygiene2 =
          categories2.firstWhere((c) => c.name == 'Hygiène').limit;
      expect(hygiene2, greaterThan(hygiene1),
          reason:
              'Larger household should have higher Hygiène budget');

      // Compare Nettoyage budgets (should be higher or equal for more rooms and house)
      // Note: Both may hit the minimum clamp of 60.0, so we use greaterThanOrEqualTo
      final nettoyage1 =
          categories1.firstWhere((c) => c.name == 'Nettoyage').limit;
      final nettoyage2 =
          categories2.firstWhere((c) => c.name == 'Nettoyage').limit;
      expect(nettoyage2, greaterThanOrEqualTo(nettoyage1),
          reason:
              'House with more rooms should have higher or equal Nettoyage budget');
      
      // Verify that at least one budget is different to show multipliers work
      final total1 = categories1.fold<double>(0.0, (sum, c) => sum + c.limit);
      final total2 = categories2.fold<double>(0.0, (sum, c) => sum + c.limit);
      expect(total2, greaterThan(total1),
          reason: 'Larger household should have higher total budget');
    });

    test('Test budget initialization does not duplicate categories', () async {
      // Create a test foyer
      final foyer = Foyer(
        nbPersonnes: 3,
        nbPieces: 2,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 300.0,
      );

      final db = await databaseService.database;
      final foyerId = await db.insert('foyer', foyer.toMap());

      // Initialize budgets twice
      await budgetService.initializeRecommendedBudgets(foyerId.toString());
      await budgetService.initializeRecommendedBudgets(foyerId.toString());

      // Verify only 4 categories exist (no duplicates)
      final categories = await budgetService.getBudgetCategories();
      expect(categories.length, equals(4),
          reason: 'Should not create duplicate categories');
    });

    test('Test BudgetAllocationRules default percentages', () {
      // Verify the default percentages are correct
      final percentages = BudgetAllocationRules.defaultPercentages;

      expect(percentages['Hygiène'], equals(0.33));
      expect(percentages['Nettoyage'], equals(0.22));
      expect(percentages['Cuisine'], equals(0.28));
      expect(percentages['Divers'], equals(0.17));

      // Verify they sum to 1.0
      final total = percentages.values.fold<double>(0.0, (sum, p) => sum + p);
      expect(total, closeTo(1.0, 0.01));
    });

    test('Test calculateFromTotal distributes budget correctly', () {
      final totalBudget = 360.0;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      expect(budgets['Hygiène'], closeTo(118.8, 0.1)); // 33% of 360
      expect(budgets['Nettoyage'], closeTo(79.2, 0.1)); // 22% of 360
      expect(budgets['Cuisine'], closeTo(100.8, 0.1)); // 28% of 360
      expect(budgets['Divers'], closeTo(61.2, 0.1)); // 17% of 360

      // Verify total
      final total = budgets.values.fold<double>(0.0, (sum, b) => sum + b);
      expect(total, closeTo(totalBudget, 0.1));
    });
  });
}

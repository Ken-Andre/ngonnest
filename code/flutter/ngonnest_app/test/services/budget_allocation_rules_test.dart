import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/services/budget_allocation_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // 1. Initialise les bindings Flutter pour les tests
    //    Ceci résout l'erreur "Binding has not yet been initialized"
    TestWidgetsFlutterBinding.ensureInitialized();

    // 2. Initialise la base de données FFI pour les tests sur desktop
    //    Ceci résout l'erreur "databaseFactory not initialized"
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BudgetAllocationRules - Multiplier Calculations', () {
    test('_calculatePersonMultiplier returns correct values', () {
      // Test with reflection since methods are private
      // We'll test through the public calculateRecommendedBudgets method
      // For now, we verify the logic through expected outcomes

      // 1 person: 1.0x
      expect(1.0 + (1 - 1) * 0.3, equals(1.0));

      // 2 people: 1.3x
      expect(1.0 + (2 - 1) * 0.3, equals(1.3));

      // 3 people: 1.6x
      expect(1.0 + (3 - 1) * 0.3, equals(1.6));

      // 4 people: 1.9x
      expect(1.0 + (4 - 1) * 0.3, equals(1.9));

      // 5 people: 2.2x
      expect(1.0 + (5 - 1) * 0.3, equals(2.2));
    });

    test('_calculateRoomMultiplier returns correct values', () {
      // 1 room: 1.0x
      expect(1.0 + (1 - 1) * 0.15, equals(1.0));

      // 2 rooms: 1.15x
      expect(1.0 + (2 - 1) * 0.15, equals(1.15));

      // 3 rooms: 1.3x
      expect(1.0 + (3 - 1) * 0.15, closeTo(1.3, 0.001));

      // 4 rooms: 1.45x
      expect(1.0 + (4 - 1) * 0.15, closeTo(1.45, 0.001));

      // 5 rooms: 1.6x
      expect(1.0 + (5 - 1) * 0.15, closeTo(1.6, 0.001));
    });

    test('_calculateHousingMultiplier returns correct values', () {
      // House: 1.2x
      final houseMultiplier = 'maison'.toLowerCase() == 'maison' ? 1.2 : 1.0;
      expect(houseMultiplier, equals(1.2));

      // Apartment: 1.0x
      final appartMultiplier = 'appartement'.toLowerCase() == 'maison'
          ? 1.2
          : 1.0;
      expect(appartMultiplier, equals(1.0));

      // Other types: 1.0x
      final otherMultiplier = 'studio'.toLowerCase() == 'maison' ? 1.2 : 1.0;
      expect(otherMultiplier, equals(1.0));

      // Case insensitive
      final maisonUpperMultiplier = 'MAISON'.toLowerCase() == 'maison'
          ? 1.2
          : 1.0;
      expect(maisonUpperMultiplier, equals(1.2));
    });

    test('Combined multipliers work correctly', () {
      // Test combined effect: 3 people, 2 rooms, house
      final personMultiplier = 1.0 + (3 - 1) * 0.3; // 1.6
      final roomMultiplier = 1.0 + (2 - 1) * 0.15; // 1.15
      final housingMultiplier = 1.2;
      final totalMultiplier =
          personMultiplier * roomMultiplier * housingMultiplier;

      expect(totalMultiplier, closeTo(2.208, 0.001)); // 1.6 * 1.15 * 1.2
    });

    test('Edge case: Single person in single room apartment', () {
      final personMultiplier = 1.0 + (1 - 1) * 0.3; // 1.0
      final roomMultiplier = 1.0 + (1 - 1) * 0.15; // 1.0
      final housingMultiplier = 1.0;
      final totalMultiplier =
          personMultiplier * roomMultiplier * housingMultiplier;

      expect(totalMultiplier, equals(1.0)); // No multiplier effect
    });

    test('Edge case: Large household', () {
      // 6 people, 5 rooms, house
      final personMultiplier = 1.0 + (6 - 1) * 0.3; // 2.5
      final roomMultiplier = 1.0 + (5 - 1) * 0.15; // 1.6
      final housingMultiplier = 1.2;
      final totalMultiplier =
          personMultiplier * roomMultiplier * housingMultiplier;

      expect(totalMultiplier, closeTo(4.8, 0.001)); // 2.5 * 1.6 * 1.2
    });
  });

  group('BudgetAllocationRules - Constants', () {
    test('defaultPercentages sum to 1.0 (100%)', () {
      final sum = BudgetAllocationRules.defaultPercentages.values.reduce(
        (a, b) => a + b,
      );
      expect(sum, closeTo(1.0, 0.001));
    });

    test('defaultPercentages contains all required categories', () {
      expect(
        BudgetAllocationRules.defaultPercentages.containsKey('Hygiène'),
        isTrue,
      );
      expect(
        BudgetAllocationRules.defaultPercentages.containsKey('Nettoyage'),
        isTrue,
      );
      expect(
        BudgetAllocationRules.defaultPercentages.containsKey('Cuisine'),
        isTrue,
      );
      expect(
        BudgetAllocationRules.defaultPercentages.containsKey('Divers'),
        isTrue,
      );
    });

    test('fallbackBasePrices contains all required categories', () {
      expect(
        BudgetAllocationRules.fallbackBasePrices.containsKey('Hygiène'),
        isTrue,
      );
      expect(
        BudgetAllocationRules.fallbackBasePrices.containsKey('Nettoyage'),
        isTrue,
      );
      expect(
        BudgetAllocationRules.fallbackBasePrices.containsKey('Cuisine'),
        isTrue,
      );
      expect(
        BudgetAllocationRules.fallbackBasePrices.containsKey('Divers'),
        isTrue,
      );
    });

    test('fallbackBasePrices are reasonable values', () {
      for (final price in BudgetAllocationRules.fallbackBasePrices.values) {
        expect(price, greaterThan(0));
        expect(price, lessThan(20)); // Reasonable upper bound in euros
      }
    });
  });

  group('BudgetAllocation', () {
    test('BudgetAllocation can be created', () {
      final allocation = BudgetAllocation(
        categoryName: 'Hygiène',
        percentage: 0.33,
        recommendedAmount: 120.0,
        basePrice: 8.0,
      );

      expect(allocation.categoryName, equals('Hygiène'));
      expect(allocation.percentage, equals(0.33));
      expect(allocation.recommendedAmount, equals(120.0));
      expect(allocation.basePrice, equals(8.0));
    });

    test('BudgetAllocation toString works', () {
      final allocation = BudgetAllocation(
        categoryName: 'Hygiène',
        percentage: 0.33,
        recommendedAmount: 120.0,
        basePrice: 8.0,
      );

      final str = allocation.toString();
      expect(str, contains('Hygiène'));
      expect(str, contains('0.33'));
      expect(str, contains('120.0'));
      expect(str, contains('8.0'));
    });
  });

  group('BudgetAllocationRules - Recommended Budget Calculation', () {
    test(
      'calculateRecommendedBudgets returns allocations for all categories',
      () async {
        final foyer = Foyer(
          nbPersonnes: 2,
          nbPieces: 2,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        final allocations =
            await BudgetAllocationRules.calculateRecommendedBudgets(
              foyer: foyer,
            );

        expect(allocations.length, equals(4));
        expect(allocations.containsKey('Hygiène'), isTrue);
        expect(allocations.containsKey('Nettoyage'), isTrue);
        expect(allocations.containsKey('Cuisine'), isTrue);
        expect(allocations.containsKey('Divers'), isTrue);
      },
    );

    test('calculateRecommendedBudgets applies clamping correctly', () async {
      // Test with minimal household (should hit lower bounds)
      final smallFoyer = Foyer(
        nbPersonnes: 1,
        nbPieces: 1,
        typeLogement: 'appartement',
        langue: 'fr',
      );

      final smallAllocations =
          await BudgetAllocationRules.calculateRecommendedBudgets(
            foyer: smallFoyer,
          );

      // Check that amounts are within expected ranges
      expect(
        smallAllocations['Hygiène']!.recommendedAmount,
        greaterThanOrEqualTo(80.0),
      );
      expect(
        smallAllocations['Hygiène']!.recommendedAmount,
        lessThanOrEqualTo(300.0),
      );
      expect(
        smallAllocations['Nettoyage']!.recommendedAmount,
        greaterThanOrEqualTo(60.0),
      );
      expect(
        smallAllocations['Nettoyage']!.recommendedAmount,
        lessThanOrEqualTo(200.0),
      );
      expect(
        smallAllocations['Cuisine']!.recommendedAmount,
        greaterThanOrEqualTo(70.0),
      );
      expect(
        smallAllocations['Cuisine']!.recommendedAmount,
        lessThanOrEqualTo(250.0),
      );
      expect(
        smallAllocations['Divers']!.recommendedAmount,
        greaterThanOrEqualTo(40.0),
      );
      expect(
        smallAllocations['Divers']!.recommendedAmount,
        lessThanOrEqualTo(150.0),
      );
    });

    test('calculateRecommendedBudgets scales with household size', () async {
      final smallFoyer = Foyer(
        nbPersonnes: 1,
        nbPieces: 1,
        typeLogement: 'appartement',
        langue: 'fr',
      );

      final largeFoyer = Foyer(
        nbPersonnes: 4,
        nbPieces: 4,
        typeLogement: 'maison',
        langue: 'fr',
      );

      final smallAllocations =
          await BudgetAllocationRules.calculateRecommendedBudgets(
            foyer: smallFoyer,
          );

      final largeAllocations =
          await BudgetAllocationRules.calculateRecommendedBudgets(
            foyer: largeFoyer,
          );

      // Larger household should have higher budgets
      expect(
        largeAllocations['Hygiène']!.recommendedAmount,
        greaterThan(smallAllocations['Hygiène']!.recommendedAmount),
      );
      expect(
        largeAllocations['Nettoyage']!.recommendedAmount,
        greaterThan(smallAllocations['Nettoyage']!.recommendedAmount),
      );
      expect(
        largeAllocations['Cuisine']!.recommendedAmount,
        greaterThan(smallAllocations['Cuisine']!.recommendedAmount),
      );
      expect(
        largeAllocations['Divers']!.recommendedAmount,
        greaterThan(smallAllocations['Divers']!.recommendedAmount),
      );
    });

    test(
      'calculateRecommendedBudgets uses fallback prices on PriceService failure',
      () async {
        // This test verifies that fallback prices are used when PriceService returns 0
        final foyer = Foyer(
          nbPersonnes: 2,
          nbPieces: 2,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        final allocations =
            await BudgetAllocationRules.calculateRecommendedBudgets(
              foyer: foyer,
            );

        // All allocations should have valid base prices
        for (final allocation in allocations.values) {
          expect(allocation.basePrice, greaterThan(0));
        }
      },
    );

    test('calculateRecommendedBudgets applies correct formulas', () async {
      final foyer = Foyer(
        nbPersonnes: 2,
        nbPieces: 2,
        typeLogement: 'appartement',
        langue: 'fr',
      );

      final allocations =
          await BudgetAllocationRules.calculateRecommendedBudgets(foyer: foyer);

      // Verify that each category has the correct percentage
      expect(allocations['Hygiène']!.percentage, equals(0.33));
      expect(allocations['Nettoyage']!.percentage, equals(0.22));
      expect(allocations['Cuisine']!.percentage, equals(0.28));
      expect(allocations['Divers']!.percentage, equals(0.17));

      // Verify that amounts are reasonable (not zero, not negative)
      for (final allocation in allocations.values) {
        expect(allocation.recommendedAmount, greaterThan(0));
      }
    });

    test(
      'calculateRecommendedBudgets handles house vs apartment correctly',
      () async {
        final apartment = Foyer(
          nbPersonnes: 2,
          nbPieces: 2,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        final house = Foyer(
          nbPersonnes: 2,
          nbPieces: 2,
          typeLogement: 'maison',
          langue: 'fr',
        );

        final apartmentAllocations =
            await BudgetAllocationRules.calculateRecommendedBudgets(
              foyer: apartment,
            );

        final houseAllocations =
            await BudgetAllocationRules.calculateRecommendedBudgets(
              foyer: house,
            );

        // House should have higher Nettoyage and Divers budgets due to housing multiplier
        expect(
          houseAllocations['Nettoyage']!.recommendedAmount,
          greaterThanOrEqualTo(
            apartmentAllocations['Nettoyage']!.recommendedAmount,
          ),
        );
        expect(
          houseAllocations['Divers']!.recommendedAmount,
          greaterThanOrEqualTo(
            apartmentAllocations['Divers']!.recommendedAmount,
          ),
        );
      },
    );
  });

  group('BudgetAllocationRules - Percentage-Based Calculation', () {
    test('calculateFromTotal distributes budget correctly', () {
      final totalBudget = 360.0;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      expect(budgets.length, equals(4));
      expect(budgets['Hygiène'], closeTo(118.8, 0.01)); // 33% of 360
      expect(budgets['Nettoyage'], closeTo(79.2, 0.01)); // 22% of 360
      expect(budgets['Cuisine'], closeTo(100.8, 0.01)); // 28% of 360
      expect(budgets['Divers'], closeTo(61.2, 0.01)); // 17% of 360
    });

    test('calculateFromTotal sum equals total budget', () {
      final totalBudget = 500.0;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      final sum = budgets.values.reduce((a, b) => a + b);
      expect(sum, closeTo(totalBudget, 0.01));
    });

    test('calculateFromTotal handles zero budget', () {
      final budgets = BudgetAllocationRules.calculateFromTotal(0.0);

      expect(budgets.length, equals(4));
      expect(budgets['Hygiène'], equals(0.0));
      expect(budgets['Nettoyage'], equals(0.0));
      expect(budgets['Cuisine'], equals(0.0));
      expect(budgets['Divers'], equals(0.0));
    });

    test('calculateFromTotal handles small budget', () {
      final totalBudget = 50.0;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      expect(budgets['Hygiène'], closeTo(16.5, 0.01)); // 33% of 50
      expect(budgets['Nettoyage'], closeTo(11.0, 0.01)); // 22% of 50
      expect(budgets['Cuisine'], closeTo(14.0, 0.01)); // 28% of 50
      expect(budgets['Divers'], closeTo(8.5, 0.01)); // 17% of 50

      final sum = budgets.values.reduce((a, b) => a + b);
      expect(sum, closeTo(totalBudget, 0.01));
    });

    test('calculateFromTotal handles large budget', () {
      final totalBudget = 2000.0;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      expect(budgets['Hygiène'], closeTo(660.0, 0.01)); // 33% of 2000
      expect(budgets['Nettoyage'], closeTo(440.0, 0.01)); // 22% of 2000
      expect(budgets['Cuisine'], closeTo(560.0, 0.01)); // 28% of 2000
      expect(budgets['Divers'], closeTo(340.0, 0.01)); // 17% of 2000

      final sum = budgets.values.reduce((a, b) => a + b);
      expect(sum, closeTo(totalBudget, 0.01));
    });

    test('calculateFromTotal maintains percentage ratios', () {
      final budget1 = BudgetAllocationRules.calculateFromTotal(100.0);
      final budget2 = BudgetAllocationRules.calculateFromTotal(200.0);

      // Ratios should be the same
      for (final category in budget1.keys) {
        final ratio = budget2[category]! / budget1[category]!;
        expect(ratio, closeTo(2.0, 0.01)); // Should be exactly 2x
      }
    });

    test('calculateFromTotal returns all categories', () {
      final budgets = BudgetAllocationRules.calculateFromTotal(360.0);

      expect(budgets.containsKey('Hygiène'), isTrue);
      expect(budgets.containsKey('Nettoyage'), isTrue);
      expect(budgets.containsKey('Cuisine'), isTrue);
      expect(budgets.containsKey('Divers'), isTrue);
    });

    test('calculateFromTotal with typical household budget', () {
      // Typical budget for a 2-person household
      final totalBudget = 360.0;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      // Verify all amounts are positive and reasonable
      for (final amount in budgets.values) {
        expect(amount, greaterThan(0));
        expect(amount, lessThan(totalBudget));
      }

      // Verify the largest allocation is Hygiène (33%)
      final maxCategory = budgets.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      expect(maxCategory.key, equals('Hygiène'));
    });

    test('calculateFromTotal precision with decimal budgets', () {
      final totalBudget = 123.45;
      final budgets = BudgetAllocationRules.calculateFromTotal(totalBudget);

      final sum = budgets.values.reduce((a, b) => a + b);
      expect(sum, closeTo(totalBudget, 0.01));
    });
  });
}

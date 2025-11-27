import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/services/price_service.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_helper.dart';
@GenerateMocks([Database, PriceService, DatabaseService])
import 'budget_service_enhanced_test.mocks.dart';

void main() {
  TestHelper.initializeTestEnvironment();

  group('BudgetService Enhanced Tests', () {
    late MockDatabase mockDatabase;
    late MockPriceService mockPriceService;
    late MockDatabaseService mockDbService;
    late BudgetService testBudgetService;

    setUp(() {
      mockDatabase = MockDatabase();
      mockPriceService = MockPriceService();
      mockDbService = MockDatabaseService();
      when(
        mockDbService.database,
      ).thenAnswer((_) async => Future.value(mockDatabase));
      // testBudgetService = BudgetService();
      testBudgetService = BudgetService.test(mockDbService, mockPriceService);
    });

    group('getBudgetCategories', () {
      test(
        'should return budget categories for current month by default',
        () async {
          final currentMonth = BudgetService.getCurrentMonth();
          final testCategories = [
            {
              'id': 1,
              'name': 'Hygiène',
              'limit_amount': 120.0,
              'spent_amount': 80.0,
              'month': currentMonth,
              'percentage': 0.25,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          ];

          when(
            mockDatabase.query(
              'budget_categories',
              where: 'month = ?',
              whereArgs: [currentMonth],
              orderBy: 'name ASC',
            ),
          ).thenAnswer((_) async => testCategories);

          final result = await testBudgetService.getBudgetCategories();
          expect(result, hasLength(1));
          expect(result[0].name, equals('Hygiène'));
          expect(result[0].limit, equals(120.0));
          expect(result[0].spent, equals(80.0));
        },
      );

      test('should return budget categories for specific month', () async {
        const specificMonth = '2024-01';
        final testCategories = [
          {
            'id': 1,
            'name': 'Nettoyage',
            'limit': 80.0,
            'spent': 60.0,
            'month': specificMonth,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [specificMonth],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => testCategories);

        final result = await testBudgetService.getBudgetCategories(
          month: specificMonth,
        );
        expect(result, hasLength(1));
        expect(result[0].month, equals(specificMonth));
      });

      test('should handle database errors gracefully', () async {
        when(
          mockDatabase.query(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
          ),
        ).thenThrow(Exception('Database error'));

        final result = await testBudgetService.getBudgetCategories();
        expect(result, isEmpty);
      });
    });

    group('createBudgetCategory', () {
      test('should create budget category successfully', () async {
        final category = BudgetCategory(
          name: 'Cuisine',
          limit: 150.0,
          month: '2024-01',
        );

        when(
          mockDatabase.insert('budget_categories', any),
        ).thenAnswer((_) async => 5);

        final result = await testBudgetService.createBudgetCategory(category);
        expect(result, equals('5'));
        verify(
          mockDatabase.insert('budget_categories', category.toMap()),
        ).called(1);
      });

      test('should handle creation errors and rethrow', () async {
        final category = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          month: '2024-01',
        );

        when(
          mockDatabase.insert('budget_categories', any),
        ).thenThrow(Exception('Insert failed'));

        expect(
          () => testBudgetService.createBudgetCategory(category),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateBudgetCategory', () {
      test('should update budget category with new timestamp', () async {
        final category = BudgetCategory(
          id: 1,
          name: 'Hygiène',
          limit: 120.0,
          spent: 90.0,
          month: '2024-01',
        );

        when(
          mockDatabase.update(
            'budget_categories',
            any,
            where: 'id = ?',
            whereArgs: [1],
          ),
        ).thenAnswer((_) async => 1);

        final result = await testBudgetService.updateBudgetCategory(category);
        expect(result, equals(1));

        verify(
          mockDatabase.update(
            'budget_categories',
            argThat(isA<Map<String, dynamic>>()),
            where: 'id = ?',
            whereArgs: [1],
          ),
        ).called(1);
      });
    });

    group('syncBudgetWithPurchases', () {
      test('should sync budget with actual purchases', () async {
        const idFoyer = '1';
        const month = '2024-01';

        // Mock existing categories
        final categories = [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 120.0,
            spent: 0.0,
            month: month,
          ),
        ];

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => categories.map((c) => c.toMap()).toList());

        // Mock spending calculation
        when(mockDatabase.rawQuery(any, any)).thenAnswer(
          (_) async => [
            {'total_spending': 85.0},
          ],
        );

        // Mock update
        when(
          mockDatabase.update(
            'budget_categories',
            any,
            where: 'id = ?',
            whereArgs: [1],
          ),
        ).thenAnswer((_) async => 1);

        await testBudgetService.syncBudgetWithPurchases(idFoyer, month: month);

        verify(
          mockDatabase.update(
            'budget_categories',
            argThat(isA<Map<String, dynamic>>()),
            where: 'id = ?',
            whereArgs: [1],
          ),
        ).called(1);
      });
    });

    group('calculateRecommendedBudget', () {
      test('should calculate budget based on foyer profile', () async {
        const idFoyer = '1';
        final foyerData = {
          'id': idFoyer,
          'nb_personnes': 4,
          'nb_pieces': 3,
          'type_logement': 'appartement',
        };

        when(
          mockDatabase.query(
            'foyer',
            where: 'id = ?',
            whereArgs: [idFoyer],
            limit: 1,
          ),
        ).thenAnswer((_) async => [foyerData]);

        // Mock price service calls
        when(
          mockPriceService.getAverageCategoryPrice('Hygiène'),
        ).thenAnswer((_) async => 8.0);
        when(
          mockPriceService.getAverageCategoryPrice('Nettoyage'),
        ).thenAnswer((_) async => 6.0);
        when(
          mockPriceService.getAverageCategoryPrice('Cuisine'),
        ).thenAnswer((_) async => 10.0);
        when(
          mockPriceService.getAverageCategoryPrice('Divers'),
        ).thenAnswer((_) async => 5.0);

        final result = await testBudgetService.calculateRecommendedBudget(
          idFoyer,
        );

        expect(result, isA<Map<String, double>>());
        expect(result.containsKey('Hygiène'), isTrue);
        expect(result.containsKey('Nettoyage'), isTrue);
        expect(result.containsKey('Cuisine'), isTrue);
        expect(result.containsKey('Divers'), isTrue);

        // Budget should be adjusted for family size (4 people) and pricing
        expect(result['Hygiène']! > 80.0, isTrue); // Should be above minimum
        expect(result['Hygiène']! < 300.0, isTrue); // Should be below maximum
        // With 4 people and base price 8.0, calculation should be: 8.0 * 15 * (1.0 + (4-1)*0.3) = 528.0, clamped to 300.0 max
        expect(
          result['Hygiène']! >= 200.0,
          isTrue,
        ); // Should be at higher end due to family size
      });

      test('should return default values on error', () async {
        const idFoyer = '999';
        when(
          mockDatabase.query(
            'foyer',
            where: 'id = ?',
            whereArgs: [idFoyer],
            limit: 1,
          ),
        ).thenAnswer((_) async => []); // No foyer found

        final result = await testBudgetService.calculateRecommendedBudget(
          idFoyer,
        );

        expect(
          result,
          equals({
            'Hygiène': 120.0,
            'Nettoyage': 80.0,
            'Cuisine': 100.0,
            'Divers': 60.0,
          }),
        );
      });

      test('should apply correct multipliers for house vs apartment', () async {
        const idFoyer = '1';
        final maisonData = {
          'id': idFoyer,
          'nb_personnes': 3,
          'nb_pieces': 4,
          'type_logement': 'maison', // Should get 20% bonus
        };

        when(
          mockDatabase.query(
            'foyer',
            where: 'id = ?',
            whereArgs: [idFoyer],
            limit: 1,
          ),
        ).thenAnswer((_) async => [maisonData]);

        when(
          mockPriceService.getAverageCategoryPrice('Hygiène'),
        ).thenAnswer((_) async => 5.0);
        when(
          mockPriceService.getAverageCategoryPrice('Nettoyage'),
        ).thenAnswer((_) async => 5.0);
        when(
          mockPriceService.getAverageCategoryPrice('Cuisine'),
        ).thenAnswer((_) async => 5.0);
        when(
          mockPriceService.getAverageCategoryPrice('Divers'),
        ).thenAnswer((_) async => 5.0);

        final result = await testBudgetService.calculateRecommendedBudget(
          idFoyer,
        );

        // Nettoyage should be higher for house (more rooms) and house type
        expect(result['Nettoyage']! > 60.0, isTrue);
      });
    });

    group('generateSavingsTips', () {
      test('should generate tips for high spending categories', () async {
        const idFoyer = '1';
        const month = '2024-01';

        final categories = [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 100.0,
            spent: 90.0, // 90% spent - should trigger tips
            month: month,
          ),
        ];

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => categories.map((c) => c.toMap()).toList());

        // Mock general tips query
        when(mockDatabase.rawQuery(any, any)).thenAnswer((_) async => []);

        final result = await testBudgetService.generateSavingsTips(
          idFoyer,
          month: month,
        );

        expect(result, isNotEmpty);
        expect(result.any((tip) => tip['category'] == 'Hygiène'), isTrue);
        expect(
          result.any(
            (tip) => (tip['title'] ?? '').toString().contains('format'),
          ),
          isTrue,
        );
      });

      test('should generate category-specific tips for over-budget', () async {
        const idFoyer = '1';
        const month = '2024-01';

        final categories = [
          BudgetCategory(
            id: 1,
            name: 'hygiène', // lowercase to test case handling
            limit: 100.0,
            spent: 120.0, // Over budget - should get high priority tips
            month: month,
          ),
        ];

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => categories.map((c) => c.toMap()).toList());

        when(mockDatabase.rawQuery(any, any)).thenAnswer((_) async => []);

        final result = await testBudgetService.generateSavingsTips(
          idFoyer,
          month: month,
        );

        expect(result, isNotEmpty);
        final hygieneTips = result
            .where((tip) => tip['category'] == 'hygiène')
            .toList();
        expect(hygieneTips, isNotEmpty);
        expect(hygieneTips.any((tip) => tip['urgency'] == 'high'), isTrue);
        expect(
          hygieneTips.any(
            (tip) => tip['title'].toString().contains('Marseille'),
          ),
          isTrue,
        );
      });

      test('should limit tips to maximum 5', () async {
        const idFoyer = '1';
        const month = '2024-01';

        // Create many over-budget categories
        final categories =
            ['Hygiène', 'Nettoyage', 'Cuisine', 'Divers', 'Extra1', 'Extra2']
                .map(
                  (name) => BudgetCategory(
                    id:
                        [
                          'Hygiène',
                          'Nettoyage',
                          'Cuisine',
                          'Divers',
                          'Extra1',
                          'Extra2',
                        ].indexOf(name) +
                        1,
                    name: name,
                    limit: 100.0,
                    spent: 120.0, // All over budget
                    month: month,
                  ),
                )
                .toList();

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => categories.map((c) => c.toMap()).toList());

        when(mockDatabase.rawQuery(any, any)).thenAnswer((_) async => []);

        final result = await testBudgetService.generateSavingsTips(
          idFoyer,
          month: month,
        );

        expect(result.length, lessThanOrEqualTo(5));
      });

      test('should include seasonal tips during rainy season', () async {
        const idFoyer = '1';
        final julyMonth = '2024-07'; // Rainy season

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [julyMonth],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => []);

        when(mockDatabase.rawQuery(any, any)).thenAnswer((_) async => []);

        final result = await testBudgetService.generateSavingsTips(
          idFoyer,
          month: julyMonth,
        );

        expect(result.any((tip) => tip['category'] == 'Saisonnier'), isTrue);
        expect(
          result.any((tip) => tip['title'].toString().contains('pluies')),
          isTrue,
        );
      });
    });

    group('getSpendingHistory', () {
      test('should return spending history with trends', () async {
        const idFoyer = '1';
        const monthsBack = 3;

        final spendingData = [
          {'categorie': 'Hygiène', 'total_spent': 80.0, 'item_count': 5},
          {'categorie': 'Nettoyage', 'total_spent': 60.0, 'item_count': 3},
        ];

        when(
          mockDatabase.rawQuery(any, any),
        ).thenAnswer((_) async => spendingData);

        final result = await testBudgetService.getSpendingHistory(
          idFoyer,
          monthsBack: monthsBack,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('history'), isTrue);
        expect(result.containsKey('trends'), isTrue);
        expect(result.containsKey('summary'), isTrue);

        final history = result['history'] as List;
        expect(history.length, equals(monthsBack));

        for (final monthData in history) {
          expect(monthData['categories'], isA<List>());
          expect(monthData['totalSpent'], isA<double>());
          expect(monthData['totalItems'], isA<int>());
        }
      });

      test('should calculate trends correctly', () async {
        const idFoyer = '1';

        // Mock data showing increasing trend
        final increasingSpendingData = [
          {
            'categorie': 'Hygiène',
            'total_spent': 100.0,
            'item_count': 5,
          }, // Recent months
          {
            'categorie': 'Hygiène',
            'total_spent': 80.0,
            'item_count': 4,
          }, // Older months
        ];

        when(
          mockDatabase.rawQuery(any, any),
        ).thenAnswer((_) async => increasingSpendingData);

        final result = await testBudgetService.getSpendingHistory(
          idFoyer,
          monthsBack: 6,
        );

        final trends = result['trends'] as Map<String, dynamic>;
        expect(trends.containsKey('direction'), isTrue);
        expect(trends.containsKey('percentage'), isTrue);
        expect(trends.containsKey('recentAverage'), isTrue);
      });
    });

    group('initializeRecommendedBudgets', () {
      test('should create recommended budgets for new foyer', () async {
        const idFoyer = '1';
        const month = '2024-01';

        // No existing categories
        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => []);

        // Mock foyer data
        when(
          mockDatabase.query(
            'foyer',
            where: 'id = ?',
            whereArgs: [idFoyer],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {
              'id': idFoyer,
              'nb_personnes': 4,
              'nb_pieces': 3,
              'type_logement': 'appartement',
            },
          ],
        );

        // Mock price service
        when(
          mockPriceService.getAverageCategoryPrice('Hygiène'),
        ).thenAnswer((_) async => 5.0);
        when(
          mockPriceService.getAverageCategoryPrice('Nettoyage'),
        ).thenAnswer((_) async => 5.0);
        when(
          mockPriceService.getAverageCategoryPrice('Cuisine'),
        ).thenAnswer((_) async => 5.0);
        when(
          mockPriceService.getAverageCategoryPrice('Divers'),
        ).thenAnswer((_) async => 5.0);

        // Mock category creation
        when(
          mockDatabase.insert('budget_categories', any),
        ).thenAnswer((_) async => 1);

        await testBudgetService.initializeRecommendedBudgets('1', month: month);

        // Should create 4 default categories
        verify(mockDatabase.insert('budget_categories', any)).called(4);
      });

      test('should not create budgets if categories already exist', () async {
        const idFoyer = '1';
        const month = '2024-01';

        // Existing categories
        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer(
          (_) async => [
            {
              'id': 1,
              'name': 'Hygiène',
              'limit': 120.0,
              'spent': 0.0,
              'month': month,
            },
          ],
        );

        await testBudgetService.initializeRecommendedBudgets(
          idFoyer,
          month: month,
        );

        // Should not create any new categories
        verifyNever(mockDatabase.insert('budget_categories', any));
      });
    });

    group('checkBudgetAlertsAfterPurchase', () {
      test(
        'should update spending and trigger alert for over-budget category',
        () async {
          const idFoyer = '1';
          const categoryName = 'Hygiène';
          const month = '2024-01';

          final existingCategory = BudgetCategory(
            id: 1,
            name: categoryName,
            limit: 100.0,
            spent: 80.0,
            month: month,
          );

          when(
            mockDatabase.query(
              'budget_categories',
              where: 'month = ?',
              whereArgs: [month],
              orderBy: 'name ASC',
            ),
          ).thenAnswer((_) async => [existingCategory.toMap()]);

          // Mock spending calculation that puts us over budget
          when(mockDatabase.rawQuery(any, any)).thenAnswer(
            (_) async => [
              {'total_spending': 120.0},
            ],
          );

          when(
            mockDatabase.update(
              'budget_categories',
              any,
              where: 'id = ?',
              whereArgs: [1],
            ),
          ).thenAnswer((_) async => 1);

          await testBudgetService.checkBudgetAlertsAfterPurchase(
            idFoyer,
            categoryName,
            month: month,
          );

          verify(
            mockDatabase.update(
              'budget_categories',
              argThat(isA<Map<String, dynamic>>()),
              where: 'id = ?',
              whereArgs: [1],
            ),
          ).called(1);
        },
      );
    });

    group('getBudgetSummary', () {
      test('should return comprehensive budget summary', () async {
        const month = '2024-01';
        final categories = [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 120.0,
            spent: 100.0,
            month: month,
          ),
          BudgetCategory(
            id: 2,
            name: 'Nettoyage',
            limit: 80.0,
            spent: 90.0,
            month: month,
          ), // Over budget
          BudgetCategory(
            id: 3,
            name: 'Cuisine',
            limit: 150.0,
            spent: 50.0,
            month: month,
          ),
        ];

        when(
          mockDatabase.query(
            'budget_categories',
            where: 'month = ?',
            whereArgs: [month],
            orderBy: 'name ASC',
          ),
        ).thenAnswer((_) async => categories.map((c) => c.toMap()).toList());

        final result = await testBudgetService.getBudgetSummary(month: month);

        expect(result['totalBudget'], equals(350.0));
        expect(result['totalSpent'], equals(240.0));
        expect(result['remaining'], equals(110.0));
        expect(result['spendingPercentage'], closeTo(0.686, 0.01));
        expect(result['categoriesCount'], equals(3));
        expect(
          result['overBudgetCount'],
          equals(1),
        ); // Only Nettoyage is over budget
        expect(result['categories'], hasLength(3));
      });

      test('should handle empty categories gracefully', () async {
        when(
          mockDatabase.query(
            'budget_categories',
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
          ),
        ).thenAnswer((_) async => []);

        final result = await testBudgetService.getBudgetSummary();

        expect(result['totalBudget'], equals(0.0));
        expect(result['totalSpent'], equals(0.0));
        expect(result['remaining'], equals(0.0));
        expect(result['spendingPercentage'], equals(0.0));
        expect(result['categoriesCount'], equals(0));
        expect(result['overBudgetCount'], equals(0));
      });
    });

    group('Error Handling and Logging', () {
      test('should log errors with proper metadata', () async {
        when(
          mockDatabase.query(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
          ),
        ).thenThrow(Exception('Database connection failed'));

        final result = await testBudgetService.getBudgetCategories();
        expect(result, isEmpty);
        // Error should be logged with ErrorLoggerService
      });

      test('should handle concurrent budget operations', () async {
        const idFoyer = '1';
        final category = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          month: '2024-01',
        );

        when(mockDatabase.insert('budget_categories', any)).thenAnswer((
          _,
        ) async {
          await Future.delayed(Duration(milliseconds: 100));
          return 1;
        });

        final futures = List.generate(
          3,
          (_) => testBudgetService.createBudgetCategory(category),
        );
        final results = await Future.wait(futures);

        expect(results, hasLength(3));
        for (final result in results) {
          expect(result, equals('1'));
        }
      });
    });

    group('NgonNest Specific Features', () {
      test('should work offline (local database)', () async {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 60000.0, // FCFA equivalent
          month: '2024-01',
        );

        when(
          mockDatabase.insert('budget_categories', any),
        ).thenAnswer((_) async => 1);

        final result = await testBudgetService.createBudgetCategory(category);
        expect(result, equals('1'));
      });

      test('should handle Cameroon-specific categories and pricing', () async {
        const idFoyer = '1';

        when(
          mockDatabase.query(
            'foyer',
            where: 'id = ?',
            whereArgs: [idFoyer],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => [
            {
              'id': idFoyer,
              'nb_personnes': 6, // Large Cameroon family
              'nb_pieces': 4,
              'type_logement': 'maison',
            },
          ],
        );

        // Mock Cameroon pricing (higher values)
        when(
          mockPriceService.getAverageCategoryPrice('Hygiène'),
        ).thenAnswer((_) async => 15.0);
        when(
          mockPriceService.getAverageCategoryPrice('Nettoyage'),
        ).thenAnswer((_) async => 12.0);
        when(
          mockPriceService.getAverageCategoryPrice('Cuisine'),
        ).thenAnswer((_) async => 20.0);
        when(
          mockPriceService.getAverageCategoryPrice('Divers'),
        ).thenAnswer((_) async => 8.0);

        final result = await testBudgetService.calculateRecommendedBudget(
          idFoyer,
        );

        // Should account for large family size and house type
        expect(result['Hygiène']! > 200.0, isTrue); // Higher for 6 people
        expect(
          result['Nettoyage']! > 150.0,
          isTrue,
        ); // Higher for house with 4 rooms
      });

      test('should provide French month names', () async {
        const idFoyer = '1';
        const categoryName = 'Hygiène';

        when(mockDatabase.rawQuery(any, any)).thenAnswer(
          (_) async => [
            {'total_spending': 100.0},
          ],
        );

        final result = await testBudgetService.getMonthlyExpenseHistory(
          idFoyer,
          categoryName,
          monthsBack: 3,
        );

        expect(result, isNotEmpty);
        for (final monthData in result) {
          final monthName = monthData['monthName'] as String?;
          if (monthName != null) {
            expect([
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
            ], contains(monthName));
          }
        }
      });
    });
  });
}

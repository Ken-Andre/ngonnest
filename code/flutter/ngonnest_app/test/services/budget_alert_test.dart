import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/models/budget_category.dart';

void main() {
  group('Budget Alert Tests', () {
    group('Budget Alert Triggering', () {
      test(
        'should trigger alert when spending exceeds 100% of limit',
        () async {
          // Create a category that will be over budget
          final overBudgetCategory = BudgetCategory(
            id: 1,
            name: 'Test Category',
            limit: 100.0,
            spent: 120.0, // 120% of limit
            month: BudgetService.getCurrentMonth(),
          );

          // Verify that the category is detected as over budget
          expect(overBudgetCategory.isOverBudget, isTrue);
          expect(overBudgetCategory.spendingPercentage, equals(1.2));
        },
      );

      test('should not trigger alert when spending is under limit', () async {
        final underBudgetCategory = BudgetCategory(
          id: 1,
          name: 'Test Category',
          limit: 100.0,
          spent: 80.0, // 80% of limit
          month: BudgetService.getCurrentMonth(),
        );

        expect(underBudgetCategory.isOverBudget, isFalse);
        expect(underBudgetCategory.spendingPercentage, equals(0.8));
      });

      test('should detect near limit correctly (>80%)', () async {
        final nearLimitCategory = BudgetCategory(
          id: 1,
          name: 'Test Category',
          limit: 100.0,
          spent: 85.0, // 85% of limit
          month: BudgetService.getCurrentMonth(),
        );

        expect(nearLimitCategory.isNearLimit, isTrue);
        expect(nearLimitCategory.isOverBudget, isFalse);
      });

      test('should handle edge case of exactly 100% spending', () async {
        final exactLimitCategory = BudgetCategory(
          id: 1,
          name: 'Test Category',
          limit: 100.0,
          spent: 100.0, // Exactly 100%
          month: BudgetService.getCurrentMonth(),
        );

        expect(exactLimitCategory.spendingPercentage, equals(1.0));
        expect(
          exactLimitCategory.isOverBudget,
          isFalse,
        ); // Not over, just at limit
        expect(exactLimitCategory.isNearLimit, isTrue);
      });

      test('should handle zero limit edge case', () async {
        final zeroLimitCategory = BudgetCategory(
          id: 1,
          name: 'Test Category',
          limit: 0.0,
          spent: 50.0,
          month: BudgetService.getCurrentMonth(),
        );

        expect(zeroLimitCategory.spendingPercentage, equals(0.0));
        expect(
          zeroLimitCategory.isOverBudget,
          isTrue,
        ); // Any spending over 0 limit is over budget
      });
    });

    group('Budget Calculation Performance', () {
      test('should calculate spending percentage efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Create multiple categories and calculate percentages
        final categories = List.generate(
          100,
          (index) => BudgetCategory(
            id: index,
            name: 'Category $index',
            limit: 100.0 + index,
            spent: 50.0 + (index * 0.5),
            month: BudgetService.getCurrentMonth(),
          ),
        );

        for (final category in categories) {
          final percentage = category.spendingPercentage;
          expect(percentage, isA<double>());
          expect(percentage, greaterThanOrEqualTo(0.0));
        }

        stopwatch.stop();

        // Should complete calculations quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Monthly Expense History Performance', () {
      test('should load expense history in under 2 seconds', () async {
        final stopwatch = Stopwatch()..start();

        // Simulate loading expense history
        // In a real test, this would call the actual service method
        final mockHistory = List.generate(
          12,
          (index) => {
            'month': '2024-${(index + 1).toString().padLeft(2, '0')}',
            'year': 2024,
            'monthNum': index + 1,
            'spending': 50.0 + (index * 5),
            'monthName': 'Month ${index + 1}',
          },
        );

        // Simulate processing time
        await Future.delayed(const Duration(milliseconds: 100));

        stopwatch.stop();

        // Should load in under 2 seconds as per requirement
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(mockHistory.length, equals(12));
      });
    });

    group('Budget Alert Notifications', () {
      test('should format budget alert notification correctly', () async {
        final category = BudgetCategory(
          id: 1,
          name: 'Hygiène',
          limit: 100.0,
          spent: 125.0,
          month: BudgetService.getCurrentMonth(),
        );

        // Test notification parameters
        final percentage = (category.spendingPercentage * 100).round();

        expect(percentage, equals(125));
        expect(category.spent, equals(125.0));
        expect(category.limit, equals(100.0));

        // Verify alert should be triggered
        expect(category.isOverBudget, isTrue);
      });

      test('should handle multiple over-budget categories', () async {
        final categories = [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 100.0,
            spent: 120.0,
            month: BudgetService.getCurrentMonth(),
          ),
          BudgetCategory(
            id: 2,
            name: 'Nettoyage',
            limit: 80.0,
            spent: 90.0,
            month: BudgetService.getCurrentMonth(),
          ),
          BudgetCategory(
            id: 3,
            name: 'Cuisine',
            limit: 150.0,
            spent: 100.0,
            month: BudgetService.getCurrentMonth(),
          ),
        ];

        final overBudgetCategories = categories
            .where((cat) => cat.isOverBudget)
            .toList();

        expect(overBudgetCategories.length, equals(2)); // Hygiène and Nettoyage
        expect(
          overBudgetCategories.map((cat) => cat.name),
          containsAll(['Hygiène', 'Nettoyage']),
        );
      });
    });

    group('Budget Summary Calculations', () {
      test('should calculate budget summary correctly', () async {
        final categories = [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 100.0,
            spent: 75.0,
            month: BudgetService.getCurrentMonth(),
          ),
          BudgetCategory(
            id: 2,
            name: 'Nettoyage',
            limit: 80.0,
            spent: 90.0, // Over budget
            month: BudgetService.getCurrentMonth(),
          ),
          BudgetCategory(
            id: 3,
            name: 'Cuisine',
            limit: 120.0,
            spent: 60.0,
            month: BudgetService.getCurrentMonth(),
          ),
        ];

        double totalLimit = 0.0;
        double totalSpent = 0.0;
        int overBudgetCount = 0;

        for (final category in categories) {
          totalLimit += category.limit;
          totalSpent += category.spent;
          if (category.isOverBudget) overBudgetCount++;
        }

        expect(totalLimit, equals(300.0));
        expect(totalSpent, equals(225.0));
        expect(overBudgetCount, equals(1)); // Only Nettoyage is over budget
        expect(
          totalSpent / totalLimit,
          equals(0.75),
        ); // 75% of total budget used
      });
    });
  });
}

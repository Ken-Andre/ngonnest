import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/budget_category.dart';

void main() {
  group('BudgetCategory Model', () {
    group('Alert Level Logic', () {
      test('should return normal alert level when spending is below 80%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 50.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.normal);
      });

      test('should return normal alert level when spending is exactly 79%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 79.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.normal);
      });

      test('should return warning alert level when spending is exactly 80%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 80.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.warning);
      });

      test('should return warning alert level when spending is between 80% and 100%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 90.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.warning);
      });

      test('should return warning alert level when spending is exactly 99%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 99.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.warning);
      });

      test('should return alert level when spending is exactly 100%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 100.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.alert);
      });

      test('should return alert level when spending is between 100% and 120%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 110.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.alert);
      });

      test('should return alert level when spending is exactly 119%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 119.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.alert);
      });

      test('should return critical alert level when spending is exactly 120%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 120.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.critical);
      });

      test('should return critical alert level when spending is above 120%', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: 150.0,
          month: '2025-01',
        );

        expect(category.alertLevel, BudgetAlertLevel.critical);
      });

      // Edge cases
      test('should return normal alert level when limit is zero', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 0.0,
          spent: 50.0,
          month: '2025-01',
        );

        // When limit is 0, spendingPercentage returns 0.0
        expect(category.spendingPercentage, 0.0);
        expect(category.alertLevel, BudgetAlertLevel.normal);
      });

      test('should return normal alert level when both limit and spent are zero', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 0.0,
          spent: 0.0,
          month: '2025-01',
        );

        expect(category.spendingPercentage, 0.0);
        expect(category.alertLevel, BudgetAlertLevel.normal);
      });

      test('should handle negative spent values gracefully', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          spent: -10.0,
          month: '2025-01',
        );

        // Negative spending results in negative percentage
        expect(category.spendingPercentage, -0.1);
        expect(category.alertLevel, BudgetAlertLevel.normal);
      });

      test('should handle very small limit values', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 0.01,
          spent: 0.012,
          month: '2025-01',
        );

        // 0.012 / 0.01 = 1.2 = 120%
        expect(category.spendingPercentage, 1.2);
        expect(category.alertLevel, BudgetAlertLevel.critical);
      });

      test('should handle very large values', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 1000000.0,
          spent: 1200000.0,
          month: '2025-01',
        );

        expect(category.spendingPercentage, 1.2);
        expect(category.alertLevel, BudgetAlertLevel.critical);
      });
    });

    group('Percentage Field', () {
      test('should have default percentage of 0.25', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          month: '2025-01',
        );

        expect(category.percentage, 0.25);
      });

      test('should accept custom percentage value', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          month: '2025-01',
          percentage: 0.33,
        );

        expect(category.percentage, 0.33);
      });

      test('should include percentage in toMap()', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          month: '2025-01',
          percentage: 0.33,
        );

        final map = category.toMap();
        expect(map['percentage'], 0.33);
      });

      test('should parse percentage from fromMap()', () {
        final map = {
          'id': 1,
          'name': 'Hygiène',
          'limit_amount': 100.0,
          'spent_amount': 50.0,
          'month': '2025-01',
          'percentage': 0.33,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final category = BudgetCategory.fromMap(map);
        expect(category.percentage, 0.33);
      });

      test('should use default percentage when not in map', () {
        final map = {
          'id': 1,
          'name': 'Hygiène',
          'limit_amount': 100.0,
          'spent_amount': 50.0,
          'month': '2025-01',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final category = BudgetCategory.fromMap(map);
        expect(category.percentage, 0.25);
      });

      test('should update percentage in copyWith()', () {
        final category = BudgetCategory(
          name: 'Hygiène',
          limit: 100.0,
          month: '2025-01',
          percentage: 0.25,
        );

        final updated = category.copyWith(percentage: 0.40);
        expect(updated.percentage, 0.40);
        expect(category.percentage, 0.25); // Original unchanged
      });
    });
  });
}

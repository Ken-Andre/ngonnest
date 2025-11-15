import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

// Generate mocks
@GenerateMocks([Database, DatabaseService])
import 'budget_service_test.mocks.dart';

void main() {
  group('BudgetService', () {
    late MockDatabase mockDatabase;
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      mockDatabase = MockDatabase();
      mockDatabaseService = MockDatabaseService();
    });

    group('getCurrentMonth', () {
      test('should return current month in YYYY-MM format', () {
        final currentMonth = BudgetService.getCurrentMonth();
        final now = DateTime.now();
        final expectedMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';

        expect(currentMonth, equals(expectedMonth));
      });
    });

    group('BudgetCategory model', () {
      test('should calculate spending percentage correctly', () {
        final category = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: 80.5,
          month: '2024-01',
        );

        expect(category.spendingPercentage, closeTo(0.805, 0.001));
      });

      test('should detect over budget correctly', () {
        final overBudgetCategory = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: 120.0,
          month: '2024-01',
        );

        final underBudgetCategory = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: 80.0,
          month: '2024-01',
        );

        expect(overBudgetCategory.isOverBudget, isTrue);
        expect(underBudgetCategory.isOverBudget, isFalse);
      });

      test('should detect near limit correctly', () {
        final nearLimitCategory = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: 85.0,
          month: '2024-01',
        );

        final farFromLimitCategory = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: 50.0,
          month: '2024-01',
        );

        expect(nearLimitCategory.isNearLimit, isTrue);
        expect(farFromLimitCategory.isNearLimit, isFalse);
      });

      test('should calculate remaining budget correctly', () {
        final category = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: 33.5,
          month: '2024-01',
        );

        expect(category.remainingBudget, equals(66.5));
      });

      test('should convert to and from map correctly', () {
        final originalCategory = BudgetCategory(
          id: 1,
          name: 'Test Category',
          limit: 150.0,
          spent: 75.0,
          month: '2024-01',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        final map = originalCategory.toMap();
        final reconstructedCategory = BudgetCategory.fromMap(map);

        expect(reconstructedCategory.id, equals(originalCategory.id));
        expect(reconstructedCategory.name, equals(originalCategory.name));
        expect(reconstructedCategory.limit, equals(originalCategory.limit));
        expect(reconstructedCategory.spent, equals(originalCategory.spent));
        expect(reconstructedCategory.month, equals(originalCategory.month));
      });

      test('should create copy with updated values', () {
        final originalCategory = BudgetCategory(
          id: 1,
          name: 'Original',
          limit: 100.0,
          spent: 50.0,
          month: '2024-01',
        );

        final updatedCategory = originalCategory.copyWith(
          name: 'Updated',
          spent: 75.0,
        );

        expect(updatedCategory.id, equals(originalCategory.id));
        expect(updatedCategory.name, equals('Updated'));
        expect(updatedCategory.limit, equals(originalCategory.limit));
        expect(updatedCategory.spent, equals(75.0));
        expect(updatedCategory.month, equals(originalCategory.month));
      });
    });

    group('Budget calculations', () {
      test('should handle zero limit correctly', () {
        final category = BudgetCategory(
          name: 'Test',
          limit: 0.0,
          spent: 50.0,
          month: '2024-01',
        );

        expect(category.spendingPercentage, equals(0.0));
        expect(category.isOverBudget, isTrue);
        expect(category.remainingBudget, equals(-50.0));
      });

      test('should handle negative spending correctly', () {
        final category = BudgetCategory(
          name: 'Test',
          limit: 100.0,
          spent: -10.0,
          month: '2024-01',
        );

        expect(category.spendingPercentage, equals(-0.1));
        expect(category.isOverBudget, isFalse);
        expect(category.remainingBudget, equals(110.0));
      });
    });

    group('Equality and hashCode', () {
      test('should be equal when all properties match', () {
        final category1 = BudgetCategory(
          id: 1,
          name: 'Test',
          limit: 100.0,
          spent: 50.0,
          month: '2024-01',
        );

        final category2 = BudgetCategory(
          id: 1,
          name: 'Test',
          limit: 100.0,
          spent: 50.0,
          month: '2024-01',
        );

        expect(category1, equals(category2));
        expect(category1.hashCode, equals(category2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final category1 = BudgetCategory(
          id: 1,
          name: 'Test',
          limit: 100.0,
          spent: 50.0,
          month: '2024-01',
        );

        final category2 = BudgetCategory(
          id: 1,
          name: 'Test',
          limit: 100.0,
          spent: 75.0, // Different spent amount
          month: '2024-01',
        );

        expect(category1, isNot(equals(category2)));
      });
    });
  });
}

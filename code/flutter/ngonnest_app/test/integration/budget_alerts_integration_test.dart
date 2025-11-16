import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/main.dart' as app;

import '../helpers/test_helper.dart';

void main() {
  // Initialize test environment once
  setUpAll(() async {
    await TestHelper.initializeTestEnvironment();
  });

  // Clean up after each test
  tearDown(() async {
    await TestHelper.cleanupAfterTest();
  });

  group('Budget Alerts Integration Tests', () {
    test('should create budget category and detect over budget', () async {
      // Create test category
      final testCategory = BudgetCategory(
        name: 'Test Category',
        limit: 50.0,
        spent: 60.0, // Over budget
        month: BudgetService.getCurrentMonth(),
      );

      // Verify over budget detection
      expect(testCategory.isOverBudget, isTrue);
      expect(testCategory.spendingPercentage, equals(1.2));
    });

    test('should calculate budget summary correctly', () async {
      // Create test categories
      final testCategory = BudgetCategory(
        name: 'Integration Test',
        limit: 100.0,
        spent: 75.0,
        month: BudgetService.getCurrentMonth(),
      );

      // Verify calculations
      expect(testCategory.spendingPercentage, equals(0.75));
      expect(testCategory.remainingBudget, equals(25.0));
      expect(testCategory.isOverBudget, isFalse);
      expect(testCategory.isNearLimit, isFalse);
    });

    test('should handle over budget scenario', () async {
      // Create over budget category
      final overBudgetCategory = BudgetCategory(
        name: 'Over Budget Test',
        limit: 50.0,
        spent: 75.0,
        month: BudgetService.getCurrentMonth(),
      );

      // Verify over budget detection
      expect(overBudgetCategory.isOverBudget, isTrue);
      expect(overBudgetCategory.spendingPercentage, equals(1.5));
      expect(overBudgetCategory.remainingBudget, equals(-25.0));
    });

    test('should allow editing budget categories', () async {
      // Create test category
      final editTestCategory = BudgetCategory(
        name: 'Edit Test',
        limit: 80.0,
        spent: 30.0,
        month: BudgetService.getCurrentMonth(),
      );

      // Test copyWith functionality
      final updatedCategory = editTestCategory.copyWith(limit: 120.0);

      expect(updatedCategory.name, equals('Edit Test'));
      expect(updatedCategory.limit, equals(120.0));
      expect(updatedCategory.spent, equals(30.0));
      expect(updatedCategory.spendingPercentage, equals(0.25)); // 30/120
    });

    testWidgets('should show expense history when category is tapped', (
      WidgetTester tester,
    ) async {
      // Initialize app for testing
      await tester.initializeApp();

      // Create test category
      final testCategory = BudgetCategory(
        name: 'History Test',
        limit: 100.0,
        spent: 60.0,
        month: BudgetService.getCurrentMonth(),
      );

      // Create budget category using the service
      await BudgetService().createBudgetCategory(testCategory);
      await tester.pumpAndSettle();

      // Navigate to budget screen
      final budgetTab = find.byIcon(Icons.account_balance_wallet);
      if (budgetTab.evaluate().isNotEmpty) {
        await tester.tap(budgetTab);
        await tester.pumpAndSettle();

        // Find and tap the category card
        final categoryCard = find.text('History Test');
        if (categoryCard.evaluate().isNotEmpty) {
          await tester.tap(categoryCard);
          await tester.pumpAndSettle();

          // Verify expense history screen opened
          expect(find.text('Historique - History Test'), findsOneWidget);
        } else {
          // It's good practice to fail the test if the widget isn't found
          // instead of silently skipping assertions.
          fail('Category card "History Test" not found on budget screen.');
        }
      } else {
        fail('Budget tab (Icons.account_balance_wallet) not found.');
      }
    });

    testWidgets('should calculate spending percentage correctly', (
      WidgetTester tester,
    ) async {
      // Initialize app for testing
      await tester.initializeApp();

      // Test various spending scenarios
      final testCases = [
        {
          'name': 'Half Spent',
          'limit': 100.0,
          'spent': 50.0,
          'expectedPercentage': '50%', // Assuming the UI shows this format
        },
        {
          'name': 'Quarter Spent',
          'limit': 200.0,
          'spent': 50.0,
          'expectedPercentage': '25%',
        },
        {
          'name': 'Over Budget',
          'limit': 50.0,
          'spent': 75.0,
          'expectedPercentage': '150%',
        },
      ];

      for (final testCase in testCases) {
        final category = BudgetCategory(
          name: testCase['name'] as String,
          limit: testCase['limit'] as double,
          spent: testCase['spent'] as double,
          month: BudgetService.getCurrentMonth(),
        );
        await BudgetService().createBudgetCategory(category);
      }
      await tester.pumpAndSettle(); // Pump after all categories are created.

      // Navigate to budget screen
      final budgetTab = find.byIcon(Icons.account_balance_wallet);
      if (budgetTab.evaluate().isNotEmpty) {
        await tester.tap(budgetTab);
        await tester.pumpAndSettle();

        // Verify all test cases
        for (final testCase in testCases) {
          expect(
            find.text(testCase['name'] as String),
            findsOneWidget,
            reason: "Category name '${testCase['name']}' not found.",
          );
          // This assertion for percentage might be tricky if the text is part of a larger string
          // or formatted differently. Consider using find.byWidgetPredicate for more robust matching.
          expect(
            find.textContaining(
              testCase['expectedPercentage'] as String,
              findRichText: true,
            ), // findRichText can help if it's part of styled text
            findsOneWidget,
            reason:
                "Expected percentage '${testCase['expectedPercentage']}' for category '${testCase['name']}' not found.",
          );
        }
      } else {
        fail('Budget tab (Icons.account_balance_wallet) not found.');
      }
    });
  });
}

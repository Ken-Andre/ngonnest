import 'dart:io'; // Added for Platform
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/main.dart' as app;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Added for FFI

void main() {
  // Initialize FFI for sqflite on desktop platforms for testing
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
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
      // Create test category
      final testCategory = BudgetCategory(
        name: 'History Test',
        limit: 100.0,
        spent: 60.0,
        month: BudgetService.getCurrentMonth(),
      );

      // This test requires BudgetService to interact with the database.
      // Ensure BudgetService itself is properly initialized if it relies on a global DatabaseService instance
      // or ensure it's provided with a testable DatabaseService.
      // For integration tests that run app.main(), the DatabaseService provided in main.dart should be used.
      // However, direct calls to static BudgetService methods might bypass app-level DI if not careful.
      // For this test, we assume BudgetService.createBudgetCategory can work with the initialized DB.

      // If BudgetService.createBudgetCategory is static and creates its own DB instance,
      // it won't benefit from the setUpAll FFI init unless it also checks for FFI.
      // However, if it uses a DatabaseService that is globally available or passed, it should work.

      // For a true integration test running the app, app.main() should set up services.
      app.main(); // This will re-run main() from main.dart, which includes FFI init.
      await tester.pumpAndSettle(); // Allow app to initialize

      // It's possible BudgetService.createBudgetCategory needs to be called *after* app.main()
      // if it relies on services initialized by app.main()
      // Or, it needs to be made testable with a mock/stub DatabaseService for pure unit/widget tests.
      // For an integration test, we'll assume it will use the database initialized via app.main -> DatabaseService provider.

      // Let's assume BudgetService.createBudgetCategory is a static method that would use the
      // globally configured databaseFactory.
      // If it's not static and part of an instance, that instance needs to be obtained after app init.

      // Given the structure, let's ensure the category is created within the app's context
      // or that BudgetService is robust enough to handle this.
      // A cleaner way for integration tests is often to interact via the UI to trigger data creation,
      // or to have test-specific setup routines that use the app's DI.

      // Re-evaluating: app.main() is called, which sets up the DatabaseService.
      // If BudgetService.createBudgetCategory internally gets an instance of DatabaseService
      // (e.g., via a singleton or a service locator that's also FFI-aware), it should work.

      await BudgetService.createBudgetCategory(
        testCategory,
      ); // This line might be problematic if BudgetService uses its own DB instance not aware of FFI from main.
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
      // Similar to the above, ensure services are ready.
      app.main();
      await tester.pumpAndSettle();

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
        await BudgetService.createBudgetCategory(category);
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

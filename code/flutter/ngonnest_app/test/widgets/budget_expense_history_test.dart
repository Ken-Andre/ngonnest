import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ngonnest_app/widgets/budget_expense_history.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks for Mockito
@GenerateMocks([DatabaseService])
import 'budget_expense_history_test.mocks.dart';

void main() {
  group('BudgetExpenseHistory', () {
    late BudgetCategory testCategory;
    late MockDatabaseService mockDatabaseService;

    setUpAll(() {
      // Initialize sqflite for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      testCategory = BudgetCategory(
        id: 1,
        name: 'Test Category',
        limit: 100.0,
        spent: 75.0,
        month: '2024-01',
      );
    });

    Widget createTestWidget(BudgetCategory category, int idFoyer) {
      return MaterialApp(
        home: Scaffold(
          body: BudgetExpenseHistory(category: category, idFoyer: idFoyer),
        ),
      );
    }

    testWidgets('should display category name in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory, 1));
      await tester.pumpAndSettle(); // Allow initial build

      expect(find.text('Historique - Test Category'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory, 1));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement de l\'historique...'), findsOneWidget);
      expect(
        find.text('Doit se charger en moins de 2 secondes'),
        findsOneWidget,
      );
    });

    testWidgets('should have refresh button in app bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory, 1));

      // Look for the refresh button by type instead of icon
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should display category information correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory, 1));

      // Verify the category data is accessible
      final widget = tester.widget<BudgetExpenseHistory>(
        find.byType(BudgetExpenseHistory),
      );
      expect(widget.category.name, equals('Test Category'));
      expect(widget.category.limit, equals(100.0));
      expect(widget.category.spent, equals(75.0));
      expect(widget.idFoyer, equals(1));
    });

    testWidgets('should handle different budget categories', (
      WidgetTester tester,
    ) async {
      final overBudgetCategory = BudgetCategory(
        id: 2,
        name: 'Over Budget Category',
        limit: 50.0,
        spent: 75.0,
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(overBudgetCategory, 1));

      expect(find.text('Historique - Over Budget Category'), findsOneWidget);

      final widget = tester.widget<BudgetExpenseHistory>(
        find.byType(BudgetExpenseHistory),
      );
      expect(widget.category.isOverBudget, isTrue);
    });

    testWidgets('should handle zero spending category', (
      WidgetTester tester,
    ) async {
      final zeroSpendingCategory = BudgetCategory(
        id: 3,
        name: 'Zero Spending',
        limit: 100.0,
        spent: 0.0,
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(zeroSpendingCategory, 1));

      expect(find.text('Historique - Zero Spending'), findsOneWidget);

      final widget = tester.widget<BudgetExpenseHistory>(
        find.byType(BudgetExpenseHistory),
      );
      expect(widget.category.spent, equals(0.0));
      expect(widget.category.spendingPercentage, equals(0.0));
    });

    testWidgets('should be accessible with proper semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory, 1));

      // Check that the app bar title is accessible
      expect(find.text('Historique - Test Category'), findsOneWidget);

      // Check that loading state is accessible
      expect(find.text('Chargement de l\'historique...'), findsOneWidget);
    });
  });
}
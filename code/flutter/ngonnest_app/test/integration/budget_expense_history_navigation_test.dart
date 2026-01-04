import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/widgets/budget_category_card.dart';
import 'package:ngonnest_app/widgets/budget_expense_history.dart';
import 'package:provider/provider.dart';

import 'budget_expense_history_navigation_test.mocks.dart';

@GenerateMocks([BudgetService])
void main() {
  // Disable Provider debug check for tests
  Provider.debugCheckInvalidValueType = null;
  
  group('Budget Expense History Navigation', () {
    late MockBudgetService mockBudgetService;

    setUp(() {
      mockBudgetService = MockBudgetService();
    });

    testWidgets('should navigate to expense history when category card is tapped',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 1,
        name: 'Hygiène',
        limit: 100.0,
        spent: 50.0,
        month: '2025-01',
      );

      when(mockBudgetService.getMonthlyExpenseHistory(
        any,
        any,
        monthsBack: anyNamed('monthsBack'),
      )).thenAnswer((_) async => [
            {
              'month': '2025-01',
              'year': 2025,
              'monthNum': 1,
              'spending': 50.0,
              'monthName': 'Janvier',
            },
          ]);

      // Build widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BudgetService>.value(
            value: mockBudgetService,
            child: Scaffold(
              body: BudgetCategoryCard(
                category: category,
                idFoyer: 1,
              ),
            ),
          ),
        ),
      );

      // Act - Tap on the category card
      await tester.tap(find.byType(BudgetCategoryCard));
      await tester.pumpAndSettle();

      // Assert - Verify navigation to expense history screen
      expect(find.byType(BudgetExpenseHistory), findsOneWidget);
      expect(find.text('Historique - Hygiène'), findsOneWidget);
    });

    testWidgets('expense history screen displays month, spending, and percentage',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 1,
        name: 'Nettoyage',
        limit: 80.0,
        spent: 60.0,
        month: '2025-01',
      );

      when(mockBudgetService.getMonthlyExpenseHistory(
        any,
        any,
        monthsBack: anyNamed('monthsBack'),
      )).thenAnswer((_) async => [
            {
              'month': '2025-01',
              'year': 2025,
              'monthNum': 1,
              'spending': 60.0,
              'monthName': 'Janvier',
            },
            {
              'month': '2024-12',
              'year': 2024,
              'monthNum': 12,
              'spending': 45.0,
              'monthName': 'Décembre',
            },
          ]);

      // Build widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BudgetService>.value(
            value: mockBudgetService,
            child: BudgetExpenseHistory(
              category: category,
              idFoyer: 1,
            ),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Verify expense history data is displayed
      expect(find.text('Janvier 2025'), findsOneWidget);
      expect(find.text('Décembre 2024'), findsOneWidget);
      
      // Verify spending amounts are shown
      expect(find.textContaining('60.00 €'), findsAtLeastNWidgets(1));
      expect(find.textContaining('45.00 €'), findsAtLeastNWidgets(1));
      
      // Verify percentages are calculated and displayed
      expect(find.text('75%'), findsOneWidget); // 60/80 = 75%
      expect(find.text('56%'), findsOneWidget); // 45/80 = 56%
    });

    testWidgets('expense history screen shows empty state when no data',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 1,
        name: 'Cuisine',
        limit: 100.0,
        spent: 0.0,
        month: '2025-01',
      );

      when(mockBudgetService.getMonthlyExpenseHistory(
        any,
        any,
        monthsBack: anyNamed('monthsBack'),
      )).thenAnswer((_) async => []);

      // Build widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BudgetService>.value(
            value: mockBudgetService,
            child: BudgetExpenseHistory(
              category: category,
              idFoyer: 1,
            ),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Verify empty state is displayed
      expect(find.text('Aucun historique disponible'), findsOneWidget);
      expect(
        find.text(
          'Les dépenses apparaîtront ici une fois que vous aurez ajouté des produits.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('expense history screen can be refreshed',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 1,
        name: 'Divers',
        limit: 60.0,
        spent: 30.0,
        month: '2025-01',
      );

      when(mockBudgetService.getMonthlyExpenseHistory(
        any,
        any,
        monthsBack: anyNamed('monthsBack'),
      )).thenAnswer((_) async => [
            {
              'month': '2025-01',
              'year': 2025,
              'monthNum': 1,
              'spending': 30.0,
              'monthName': 'Janvier',
            },
          ]);

      // Build widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BudgetService>.value(
            value: mockBudgetService,
            child: BudgetExpenseHistory(
              category: category,
              idFoyer: 1,
            ),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Act - Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert - Verify service was called twice (initial + refresh)
      verify(mockBudgetService.getMonthlyExpenseHistory(
        any,
        any,
        monthsBack: anyNamed('monthsBack'),
      )).called(2);
    });
  });
}

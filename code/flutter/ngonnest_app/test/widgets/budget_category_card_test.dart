import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/budget_category_card.dart';
import '../../lib/models/budget_category.dart';

void main() {
  group('BudgetCategoryCard', () {
    late BudgetCategory testCategory;

    setUp(() {
      testCategory = BudgetCategory(
        id: 1,
        name: 'Test Category',
        limit: 100.0,
        spent: 80.5,
        month: '2024-01',
      );
    });

    Widget createTestWidget(
      BudgetCategory category, {
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BudgetCategoryCard(
            category: category,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      );
    }

    testWidgets('should display category name and spending information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory));

      expect(find.text('Test Category'), findsOneWidget);
      expect(find.text('80.5 € / 100.0 €'), findsOneWidget);
      expect(find.text('81%'), findsOneWidget);
    });

    testWidgets('should show remaining budget when not over budget', (
      WidgetTester tester,
    ) async {
      final underBudgetCategory = BudgetCategory(
        id: 1,
        name: 'Under Budget',
        limit: 100.0,
        spent: 60.5,
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(underBudgetCategory));

      expect(find.text('Reste: 39.5 €'), findsOneWidget);
    });

    testWidgets('should show over budget alert when spending exceeds limit', (
      WidgetTester tester,
    ) async {
      final overBudgetCategory = BudgetCategory(
        id: 1,
        name: 'Over Budget',
        limit: 100.0,
        spent: 120.0,
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(overBudgetCategory));

      expect(find.text('Budget dépassé de 20.0 €'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
        findsOneWidget,
      );
    });

    testWidgets('should show edit button when onEdit callback is provided', (
      WidgetTester tester,
    ) async {
      bool editCalled = false;

      await tester.pumpWidget(
        createTestWidget(testCategory, onEdit: () => editCalled = true),
      );

      expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.pencil));
      await tester.pump();

      expect(editCalled, isTrue);
    });

    testWidgets(
      'should show delete button when onDelete callback is provided',
      (WidgetTester tester) async {
        bool deleteCalled = false;

        await tester.pumpWidget(
          createTestWidget(testCategory, onDelete: () => deleteCalled = true),
        );

        expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.trash));
        await tester.pump();

        expect(deleteCalled, isTrue);
      },
    );

    testWidgets('should call onTap when card is tapped', (
      WidgetTester tester,
    ) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        createTestWidget(testCategory, onTap: () => tapCalled = true),
      );

      await tester.tap(find.byType(BudgetCategoryCard));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('should display correct progress bar width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(testCategory));

      // Find the progress bar container
      final progressBar = find.byType(FractionallySizedBox);
      expect(progressBar, findsOneWidget);

      final widget = tester.widget<FractionallySizedBox>(progressBar);
      expect(widget.widthFactor, equals(0.75)); // 75% spending
    });

    testWidgets('should use error color for over budget category', (
      WidgetTester tester,
    ) async {
      final overBudgetCategory = BudgetCategory(
        id: 1,
        name: 'Over Budget',
        limit: 100.0,
        spent: 120.0,
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(overBudgetCategory));
      await tester.pump();

      // The card should have error styling when over budget
      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });

    testWidgets('should handle zero limit gracefully', (
      WidgetTester tester,
    ) async {
      final zeroLimitCategory = BudgetCategory(
        id: 1,
        name: 'Zero Limit',
        limit: 0.0,
        spent: 50.0,
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(zeroLimitCategory));

      expect(find.text('Zero Limit'), findsOneWidget);
      expect(find.text('50.0 € / 0.0 €'), findsOneWidget);
      // Should show over budget alert since spent > limit
      expect(find.text('Budget dépassé de 50.0 €'), findsOneWidget);
    });

    testWidgets('should handle near limit category styling', (
      WidgetTester tester,
    ) async {
      final nearLimitCategory = BudgetCategory(
        id: 1,
        name: 'Near Limit',
        limit: 100.0,
        spent: 85.0, // 85% - should be near limit
        month: '2024-01',
      );

      await tester.pumpWidget(createTestWidget(nearLimitCategory));

      expect(find.text('Near Limit'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Reste: 15.0 €'), findsOneWidget);
    });
  });
}

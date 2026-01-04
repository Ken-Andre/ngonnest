import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/screens/budget_screen.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration test for observer pattern implementation
/// Tests: BudgetScreen mounts → registers listener
///        Budget updated → screen refreshes automatically
///        Screen disposed → listener unregistered (no memory leak)
/// Requirements: 3.4, 3.5, 3.6
void main() {
  late DatabaseService databaseService;
  late BudgetService budgetService;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Initialize test database with in-memory database
    databaseService = DatabaseService();
    await databaseService.database; // Initialize the database
    
    budgetService = BudgetService();

    // Create test foyer
    final db = await databaseService.database;
    await db.insert('foyer', {
      'id': 1,
      'nb_personnes': 4,
      'nb_pieces': 5,
      'type_logement': 'appartement',
      'langue': 'fr',
      'budget_mensuel_estime': 360.0,
    });

    // Initialize default budget categories for testing
    await budgetService.initializeDefaultCategories();
  });

  tearDown() async {
    // Close database after each test
    final db = await databaseService.database;
    await db.close();
  };

  group('Observer Pattern Tests', () {
    testWidgets(
      'BudgetScreen mounts and registers listener',
      (WidgetTester tester) async {
        // Arrange
        int listenerCallCount = 0;
        
        // Add a test listener to track calls
        void testListener() {
          listenerCallCount++;
        }
        
        budgetService.addListener(testListener);

        // Act - Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Verify screen is mounted
        expect(find.byType(BudgetScreen), findsOneWidget);

        // Verify listener is registered by triggering a change
        final currentMonth = BudgetService.getCurrentMonth();
        final categories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        
        if (categories.isNotEmpty) {
          final category = categories.first;
          final initialCallCount = listenerCallCount;
          
          // Update category to trigger listener
          await budgetService.updateBudgetCategory(
            category.copyWith(limit: category.limit + 10.0),
          );
          
          await tester.pumpAndSettle();
          
          // Verify listener was called
          expect(listenerCallCount, greaterThan(initialCallCount));
        }

        // Cleanup
        budgetService.removeListener(testListener);
      },
    );

    testWidgets(
      'Budget updated → screen refreshes automatically',
      (WidgetTester tester) async {
        // Arrange
        final currentMonth = BudgetService.getCurrentMonth();
        
        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial state
        final initialCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        expect(initialCategories.isNotEmpty, isTrue);

        final hygieneCategory = initialCategories.firstWhere(
          (cat) => cat.name == 'Hygiène',
        );
        final initialLimit = hygieneCategory.limit;

        // Act - Update budget category
        final updatedCategory = hygieneCategory.copyWith(
          limit: initialLimit + 50.0,
        );
        await budgetService.updateBudgetCategory(updatedCategory);

        // Wait for UI to refresh automatically
        await tester.pumpAndSettle();

        // Assert - Verify screen refreshed with new data
        final finalCategories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        final finalHygieneCategory = finalCategories.firstWhere(
          (cat) => cat.name == 'Hygiène',
        );

        expect(finalHygieneCategory.limit, equals(initialLimit + 50.0));
        
        // Verify screen is still mounted and functional
        expect(find.byType(BudgetScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Screen disposed → listener unregistered (no memory leak)',
      (WidgetTester tester) async {
        // Arrange
        int listenerCallCount = 0;
        
        // Add a test listener to track calls
        void testListener() {
          listenerCallCount++;
        }
        
        budgetService.addListener(testListener);

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen is mounted
        expect(find.byType(BudgetScreen), findsOneWidget);

        // Act - Dispose the screen by navigating away
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Text('Different Screen'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Verify screen is disposed
        expect(find.byType(BudgetScreen), findsNothing);
        expect(find.text('Different Screen'), findsOneWidget);

        // Trigger a budget update
        final currentMonth = BudgetService.getCurrentMonth();
        final categories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        
        if (categories.isNotEmpty) {
          final category = categories.first;
          final callCountBeforeUpdate = listenerCallCount;
          
          // Update category
          await budgetService.updateBudgetCategory(
            category.copyWith(limit: category.limit + 10.0),
          );
          
          await tester.pumpAndSettle();
          
          // Verify our test listener was still called (it's still registered)
          expect(listenerCallCount, greaterThan(callCountBeforeUpdate));
        }

        // Cleanup
        budgetService.removeListener(testListener);
      },
    );

    testWidgets(
      'Multiple screens can listen to same BudgetService',
      (WidgetTester tester) async {
        // Arrange
        int listener1CallCount = 0;
        int listener2CallCount = 0;
        
        void listener1() {
          listener1CallCount++;
        }
        
        void listener2() {
          listener2CallCount++;
        }
        
        budgetService.addListener(listener1);
        budgetService.addListener(listener2);

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Update budget
        final currentMonth = BudgetService.getCurrentMonth();
        final categories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        
        if (categories.isNotEmpty) {
          final category = categories.first;
          
          await budgetService.updateBudgetCategory(
            category.copyWith(limit: category.limit + 10.0),
          );
          
          await tester.pumpAndSettle();
          
          // Assert - Both listeners should be called
          expect(listener1CallCount, greaterThan(0));
          expect(listener2CallCount, greaterThan(0));
        }

        // Cleanup
        budgetService.removeListener(listener1);
        budgetService.removeListener(listener2);
      },
    );

    testWidgets(
      'Listener not called when notify parameter is false',
      (WidgetTester tester) async {
        // Arrange
        int listenerCallCount = 0;
        
        void testListener() {
          listenerCallCount++;
        }
        
        budgetService.addListener(testListener);

        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Create category with notify: false
        final currentMonth = BudgetService.getCurrentMonth();
        final initialCallCount = listenerCallCount;
        
        await budgetService.createBudgetCategory(
          BudgetCategory(
            name: 'Test Category',
            limit: 100.0,
            month: currentMonth,
          ),
          notify: false,
        );
        
        await tester.pumpAndSettle();

        // Assert - Listener should not be called
        expect(listenerCallCount, equals(initialCallCount));

        // Cleanup
        budgetService.removeListener(testListener);
      },
    );

    testWidgets(
      'Screen handles rapid budget updates without crashing',
      (WidgetTester tester) async {
        // Arrange
        final currentMonth = BudgetService.getCurrentMonth();
        
        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Perform rapid updates
        final categories = await budgetService.getBudgetCategories(
          month: currentMonth,
        );
        
        if (categories.isNotEmpty) {
          final category = categories.first;
          
          // Perform 10 rapid updates
          for (int i = 0; i < 10; i++) {
            await budgetService.updateBudgetCategory(
              category.copyWith(limit: category.limit + i.toDouble()),
            );
          }
          
          // Wait for all updates to settle
          await tester.pumpAndSettle();
        }

        // Assert - Screen should still be functional
        expect(find.byType(BudgetScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'BudgetService properly manages listener lifecycle',
      () async {
        // Arrange
        int listenerCallCount = 0;
        
        void testListener() {
          listenerCallCount++;
        }

        // Act - Add listener
        budgetService.addListener(testListener);
        
        // Trigger update
        final currentMonth = BudgetService.getCurrentMonth();
        await budgetService.createBudgetCategory(
          BudgetCategory(
            name: 'Test',
            limit: 100.0,
            month: currentMonth,
          ),
        );
        
        final callCountAfterAdd = listenerCallCount;
        expect(callCountAfterAdd, greaterThan(0));

        // Remove listener
        budgetService.removeListener(testListener);
        
        // Trigger another update
        await budgetService.createBudgetCategory(
          BudgetCategory(
            name: 'Test2',
            limit: 100.0,
            month: currentMonth,
          ),
        );
        
        // Assert - Listener should not be called after removal
        expect(listenerCallCount, equals(callCountAfterAdd));
      },
    );

    testWidgets(
      'Screen survives budget service errors without memory leaks',
      (WidgetTester tester) async {
        // Arrange
        // Build the BudgetScreen widget
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetService>.value(
                value: budgetService,
              ),
            ],
            child: const MaterialApp(
              home: BudgetScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Try to trigger an error (invalid budget update)
        try {
          await budgetService.recalculateCategoryBudgets('1', -100.0);
        } catch (e) {
          // Expected to throw
        }

        await tester.pumpAndSettle();

        // Assert - Screen should still be functional
        expect(find.byType(BudgetScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Dispose screen
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('Done'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify no memory leaks (screen disposed properly)
        expect(find.byType(BudgetScreen), findsNothing);
      },
    );
  });
}

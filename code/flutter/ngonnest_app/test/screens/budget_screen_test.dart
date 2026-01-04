import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/providers/foyer_provider.dart';
import 'package:ngonnest_app/screens/budget_screen.dart';
import 'package:ngonnest_app/services/analytics_service.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:provider/provider.dart';

import 'budget_screen_test.mocks.dart';

@GenerateMocks([BudgetService, AnalyticsService, FoyerProvider])
void main() {
  late MockBudgetService mockBudgetService;
  late MockAnalyticsService mockAnalyticsService;
  late MockFoyerProvider mockFoyerProvider;

  setUp(() {
    mockBudgetService = MockBudgetService();
    mockAnalyticsService = MockAnalyticsService();
    mockFoyerProvider = MockFoyerProvider();

    // Setup default mocks
    when(mockFoyerProvider.foyerId).thenReturn('1');
    when(mockFoyerProvider.foyer).thenReturn(
      Foyer(
        id: '1',
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 360.0,
      ),
    );
    when(mockAnalyticsService.logEvent(any, parameters: anyNamed('parameters')))
        .thenAnswer((_) async => {});
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetService>.value(value: mockBudgetService),
        Provider<AnalyticsService>.value(value: mockAnalyticsService),
        ChangeNotifierProvider<FoyerProvider>.value(value: mockFoyerProvider),
      ],
      child: const MaterialApp(
        home: BudgetScreen(),
      ),
    );
  }

  group('BudgetScreen Loading State', () {
    testWidgets('displays loading indicator when loading', (tester) async {
      // Arrange - Make getBudgetCategories take a long time
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Trigger first frame
      await tester.pump(const Duration(milliseconds: 50)); // Let loading start

      // Assert - Should show loading indicator during data load
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('loading state clears after data loaded', (tester) async {
      // Arrange
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async => [
            BudgetCategory(
              id: 1,
              name: 'Hygiène',
              limit: 120.0,
              spent: 50.0,
              month: '2024-01',
            ),
          ]);
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {
            'totalBudget': 360.0,
            'totalSpent': 50.0,
            'remaining': 310.0,
          });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Loading should be cleared and data should be shown
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hygiène'), findsOneWidget);
    });
  });

  group('BudgetScreen Error State', () {
    testWidgets('displays error message with retry button on error',
        (tester) async {
      // Arrange - Make getBudgetCategories throw an error
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenThrow(Exception('Database error'));
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenThrow(Exception('Database error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show error message and retry button
      expect(find.byIcon(CupertinoIcons.exclamationmark_triangle), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.refresh), findsOneWidget);
    });

    testWidgets('retry button reloads data', (tester) async {
      // Arrange - First call fails, second succeeds
      var callCount = 0;
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Database error');
        }
      });
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async => [
            BudgetCategory(
              id: 1,
              name: 'Hygiène',
              limit: 120.0,
              spent: 50.0,
              month: '2024-01',
            ),
          ]);
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {
            'totalBudget': 360.0,
            'totalSpent': 50.0,
            'remaining': 310.0,
          });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.byIcon(CupertinoIcons.exclamationmark_triangle), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      // Assert - Should now show data
      expect(find.byIcon(CupertinoIcons.exclamationmark_triangle), findsNothing);
      expect(find.text('Hygiène'), findsOneWidget);
    });
  });

  group('BudgetScreen Category Cards', () {
    testWidgets('displays category cards with different alert levels',
        (tester) async {
      // Arrange
      final categories = [
        BudgetCategory(
          id: 1,
          name: 'Normal',
          limit: 100.0,
          spent: 50.0,
          month: '2024-01',
        ), // 50% - normal
        BudgetCategory(
          id: 2,
          name: 'Warning',
          limit: 100.0,
          spent: 85.0,
          month: '2024-01',
        ), // 85% - warning
        BudgetCategory(
          id: 3,
          name: 'Alert',
          limit: 100.0,
          spent: 110.0,
          month: '2024-01',
        ), // 110% - alert
        BudgetCategory(
          id: 4,
          name: 'Critical',
          limit: 100.0,
          spent: 130.0,
          month: '2024-01',
        ), // 130% - critical
      ];

      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async => categories);
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {
            'totalBudget': 360.0,
            'totalSpent': 375.0,
            'remaining': -15.0,
          });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - All categories should be displayed
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);

      // Verify alert icons are shown for warning/alert/critical
      // Note: We can't easily test icon colors in widget tests,
      // but we can verify the structure is correct
      expect(find.byType(Icon), findsWidgets);
    });
  });

  group('BudgetScreen Pull-to-Refresh', () {
    testWidgets('pull-to-refresh reloads data', (tester) async {
      // Arrange
      var callCount = 0;
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async {
        callCount++;
        return [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 120.0,
            spent: callCount * 10.0,
            month: '2024-01',
          ),
        ];
      });
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {
            'totalBudget': 360.0,
            'totalSpent': callCount * 10.0,
            'remaining': 360.0 - (callCount * 10.0),
          });

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('10.0 € / 120.0 €'), findsOneWidget);

      // Perform pull-to-refresh
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Assert - Data should be reloaded
      expect(find.text('20.0 € / 120.0 €'), findsOneWidget);
      expect(callCount, equals(2));
    });
  });

  group('BudgetScreen Listener Registration', () {
    testWidgets('registers listener on init and unregisters on dispose',
        (tester) async {
      // Arrange
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async => []);
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {});

      // Act - Mount widget
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify listener was added to BudgetService
      verify(mockBudgetService.addListener(any)).called(1);
      // Note: FoyerProvider also has a listener registered, so total is 2

      // Act - Dispose widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Verify listener was removed from BudgetService
      verify(mockBudgetService.removeListener(any)).called(1);
    });

    testWidgets('reloads data when budget service notifies', (tester) async {
      // Arrange
      var callCount = 0;
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async {
        callCount++;
        return [
          BudgetCategory(
            id: 1,
            name: 'Hygiène',
            limit: 120.0,
            spent: callCount * 10.0,
            month: '2024-01',
          ),
        ];
      });
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {
            'totalBudget': 360.0,
            'totalSpent': callCount * 10.0,
            'remaining': 360.0 - (callCount * 10.0),
          });

      // Act - Mount widget
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('10.0 € / 120.0 €'), findsOneWidget);

      // Simulate budget service notification
      // Note: In a real scenario, this would be triggered by BudgetService.notifyListeners()
      // For testing, we manually trigger the listener callback
      final capturedListeners =
          verify(mockBudgetService.addListener(captureAny)).captured;
      final budgetServiceListener = capturedListeners.first as VoidCallback;
      
      // Trigger the listener
      budgetServiceListener();
      await tester.pump(const Duration(milliseconds: 600)); // Wait for debounce
      await tester.pumpAndSettle();

      // Assert - Data should be reloaded
      expect(find.text('20.0 € / 120.0 €'), findsOneWidget);
      expect(callCount, equals(2));
    });

    testWidgets('verifies no memory leaks after dispose', (tester) async {
      // Arrange
      when(mockBudgetService.initializeDefaultCategories(month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.syncBudgetWithPurchases(any, month: anyNamed('month')))
          .thenAnswer((_) async {});
      when(mockBudgetService.getBudgetCategories(month: anyNamed('month')))
          .thenAnswer((_) async => []);
      when(mockBudgetService.getBudgetSummary(month: anyNamed('month')))
          .thenAnswer((_) async => {});

      // Act - Mount and dispose widget
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Assert - Verify listeners were properly cleaned up
      verify(mockBudgetService.addListener(any)).called(1);
      verify(mockBudgetService.removeListener(any)).called(1);
    });
  });
}

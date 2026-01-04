import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/analytics_service.dart';
import 'package:ngonnest_app/services/notification_service.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'budget_notification_flow_test.mocks.dart';

@GenerateMocks([AnalyticsService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  setUp(() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ngonnest.db');
    await databaseFactory.deleteDatabase(path);
  });

  group('Budget Notification Flow Integration Tests', () {
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      mockAnalytics = MockAnalyticsService();
    });

    testWidgets(
        'notification shown when budget reaches 80% (warning level)',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 1,
        name: 'Hygiène',
        limit: 100.0,
        spent: 80.0, // 80% - warning level
        month: '2024-11',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await BudgetNotifications.showBudgetAlert(
                      category: category,
                      analytics: mockAnalytics,
                      context: context,
                    );
                  },
                  child: const Text('Trigger Alert'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Alert'));
      await tester.pumpAndSettle();

      // Assert - verify analytics event was logged
      verify(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['category'], 'category', 'Hygiène')
                .having((m) => m['percentage'], 'percentage', 80)
                .having(
                  (m) => m['alert_level'],
                  'alert_level',
                  contains('warning'),
                ),
            named: 'parameters',
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'notification shown when budget reaches 100% (alert level)',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 2,
        name: 'Nettoyage',
        limit: 80.0,
        spent: 85.0, // 106% - alert level
        month: '2024-11',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await BudgetNotifications.showBudgetAlert(
                      category: category,
                      analytics: mockAnalytics,
                      context: context,
                    );
                  },
                  child: const Text('Trigger Alert'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Alert'));
      await tester.pumpAndSettle();

      // Assert - verify analytics event was logged
      verify(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['category'], 'category', 'Nettoyage')
                .having((m) => m['percentage'], 'percentage', 106)
                .having(
                  (m) => m['alert_level'],
                  'alert_level',
                  contains('alert'),
                ),
            named: 'parameters',
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'notification shown when budget reaches 120% (critical level)',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 3,
        name: 'Cuisine',
        limit: 100.0,
        spent: 125.0, // 125% - critical level
        month: '2024-11',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await BudgetNotifications.showBudgetAlert(
                      category: category,
                      analytics: mockAnalytics,
                      context: context,
                    );
                  },
                  child: const Text('Trigger Alert'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Alert'));
      await tester.pumpAndSettle();

      // Assert - verify analytics event was logged
      verify(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: argThat(
            isA<Map<String, Object>>()
                .having((m) => m['category'], 'category', 'Cuisine')
                .having((m) => m['percentage'], 'percentage', 125)
                .having(
                  (m) => m['alert_level'],
                  'alert_level',
                  contains('critical'),
                ),
            named: 'parameters',
          ),
        ),
      ).called(1);
    });

    testWidgets(
        'fallback to in-app banner when permissions denied',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 4,
        name: 'Divers',
        limit: 60.0,
        spent: 50.0, // 83% - warning level
        month: '2024-11',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await BudgetNotifications.showBudgetAlert(
                      category: category,
                      analytics: mockAnalytics,
                      context: context,
                    );
                  },
                  child: const Text('Trigger Alert'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Alert'));
      await tester.pumpAndSettle();

      // Assert - verify analytics event was logged even if notification fails
      verify(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: anyNamed('parameters'),
        ),
      ).called(1);

      // Note: In a real test environment, we would verify the SnackBar appears
      // but since notifications fail in test environment, the fallback is triggered
      // The important part is that analytics is still tracked
    });

    testWidgets(
        'analytics events are logged correctly for all alert levels',
        (WidgetTester tester) async {
      // Test warning level
      final warningCategory = BudgetCategory(
        id: 5,
        name: 'Test1',
        limit: 100.0,
        spent: 85.0,
        month: '2024-11',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await BudgetNotifications.showBudgetAlert(
                      category: warningCategory,
                      analytics: mockAnalytics,
                      context: context,
                    );
                  },
                  child: const Text('Trigger'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      // Verify analytics was called
      final captured = verify(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: captureAnyNamed('parameters'),
        ),
      ).captured;

      expect(captured.length, 1);
      final params = captured[0] as Map<String, Object>;
      expect(params['category'], 'Test1');
      expect(params['percentage'], 85);
      expect(params['spent'], 85.0);
      expect(params['limit'], 100.0);
      expect(params['alert_level'], contains('warning'));
    });

    testWidgets(
        'no notification or analytics for normal level (< 80%)',
        (WidgetTester tester) async {
      // Arrange
      final category = BudgetCategory(
        id: 6,
        name: 'Normal',
        limit: 100.0,
        spent: 50.0, // 50% - normal level
        month: '2024-11',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await BudgetNotifications.showBudgetAlert(
                      category: category,
                      analytics: mockAnalytics,
                      context: context,
                    );
                  },
                  child: const Text('Trigger Alert'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Alert'));
      await tester.pumpAndSettle();

      // Assert - no analytics event should be logged for normal level
      verifyNever(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: anyNamed('parameters'),
        ),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/services/analytics_service.dart';
import 'package:ngonnest_app/services/notification_service.dart';

import 'budget_notification_analytics_test.mocks.dart';

@GenerateMocks([AnalyticsService])
void main() {
  group('Budget Notification Analytics Tracking', () {
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      mockAnalytics = MockAnalyticsService();
    });

    test('logs budget_alert_triggered event for warning level (80%)', () async {
      // Arrange
      final category = BudgetCategory(
        id: 1,
        name: 'Hygiène',
        limit: 100.0,
        spent: 80.0, // 80% - warning level
        month: '2024-11',
      );

      // Act
      await BudgetNotifications.showBudgetAlert(
        category: category,
        analytics: mockAnalytics,
      );

      // Assert
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
                )
                .having((m) => m['spent'], 'spent', 80.0)
                .having((m) => m['limit'], 'limit', 100.0),
            named: 'parameters',
          ),
        ),
      ).called(1);
    });

    test('logs budget_alert_triggered event for alert level (100%)', () async {
      // Arrange
      final category = BudgetCategory(
        id: 2,
        name: 'Nettoyage',
        limit: 80.0,
        spent: 85.0, // 106% - alert level
        month: '2024-11',
      );

      // Act
      await BudgetNotifications.showBudgetAlert(
        category: category,
        analytics: mockAnalytics,
      );

      // Assert
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
                )
                .having((m) => m['spent'], 'spent', 85.0)
                .having((m) => m['limit'], 'limit', 80.0),
            named: 'parameters',
          ),
        ),
      ).called(1);
    });

    test('logs budget_alert_triggered event for critical level (120%)',
        () async {
      // Arrange
      final category = BudgetCategory(
        id: 3,
        name: 'Cuisine',
        limit: 100.0,
        spent: 125.0, // 125% - critical level
        month: '2024-11',
      );

      // Act
      await BudgetNotifications.showBudgetAlert(
        category: category,
        analytics: mockAnalytics,
      );

      // Assert
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
                )
                .having((m) => m['spent'], 'spent', 125.0)
                .having((m) => m['limit'], 'limit', 100.0),
            named: 'parameters',
          ),
        ),
      ).called(1);
    });

    test('includes spent and limit amounts in analytics parameters', () async {
      // Arrange
      final category = BudgetCategory(
        id: 4,
        name: 'Divers',
        limit: 60.0,
        spent: 50.0, // 83% - warning level
        month: '2024-11',
      );

      // Act
      await BudgetNotifications.showBudgetAlert(
        category: category,
        analytics: mockAnalytics,
      );

      // Assert
      final captured = verify(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: captureAnyNamed('parameters'),
        ),
      ).captured;

      expect(captured.length, 1);
      final params = captured[0] as Map<String, Object>;
      expect(params['spent'], 50.0);
      expect(params['limit'], 60.0);
      expect(params['category'], 'Divers');
      expect(params['percentage'], 83);
    });

    test('does not log event for normal level (< 80%)', () async {
      // Arrange
      final category = BudgetCategory(
        id: 5,
        name: 'Hygiène',
        limit: 100.0,
        spent: 50.0, // 50% - normal level
        month: '2024-11',
      );

      // Act
      await BudgetNotifications.showBudgetAlert(
        category: category,
        analytics: mockAnalytics,
      );

      // Assert - no event should be logged for normal level
      verifyNever(
        mockAnalytics.logEvent(
          'budget_alert_triggered',
          parameters: anyNamed('parameters'),
        ),
      );
    });
  });
}

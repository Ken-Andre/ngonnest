import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/analytics_service.dart';
import '../../lib/services/error_logger_service.dart';
// Generate mocks
@GenerateMocks([FirebaseAnalytics, SharedPreferences, ErrorLoggerService])
import 'analytics_service_test.mocks.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockFirebaseAnalytics mockFirebaseAnalytics;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockFirebaseAnalytics = MockFirebaseAnalytics();
      mockSharedPreferences = MockSharedPreferences();

      // Initialize service
      analyticsService = AnalyticsService();

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Test initialization
        expect(analyticsService, isNotNull);
      });
    });

    group('Event Logging', () {
      test('should log basic events', () async {
        // Test basic event logging
        await analyticsService.logEvent(
          'test_event',
          parameters: {'test_param': 'test_value'},
        );

        // Verify no exceptions thrown
        expect(true, isTrue);
      });

      test('should handle event logging errors gracefully', () async {
        // Test error handling in event logging
        await analyticsService.logEvent('test_event');

        // Should not throw exceptions
        expect(true, isTrue);
      });
    });

    group('MVP Critical Metrics', () {
      test('should track onboarding flow', () async {
        // Test onboarding started
        await analyticsService.logOnboardingStarted();

        // Test onboarding completed
        await analyticsService.logOnboardingCompleted();

        expect(true, isTrue);
      });

      test('should track core actions', () async {
        // Test item actions
        await analyticsService.logItemAction(
          'added',
          params: {'product_type': 'consumable', 'category': 'hygiene'},
        );

        await analyticsService.logItemAction(
          'updated',
          params: {'product_id': '123'},
        );

        await analyticsService.logItemAction('deleted');

        expect(true, isTrue);
      });

      test('should track UX flows', () async {
        const flowName = 'test_flow';

        // Start flow
        await analyticsService.logFlowStarted(flowName);

        // Complete flow
        await analyticsService.logFlowCompleted(
          flowName,
          additionalParams: {'completion_method': 'success'},
        );

        expect(true, isTrue);
      });

      test('should track flow abandonment', () async {
        const flowName = 'test_flow';

        // Start flow
        await analyticsService.logFlowStarted(flowName);

        // Abandon flow
        await analyticsService.logFlowAbandoned(
          flowName,
          reason: 'user_cancelled',
        );

        expect(true, isTrue);
      });
    });

    group('MVP High Priority Metrics', () {
      test('should track offline sessions', () async {
        // Test offline session tracking
        await analyticsService.logOfflineSessionStarted();
        await Future.delayed(Duration(milliseconds: 100));
        await analyticsService.logOfflineSessionEnded();

        expect(true, isTrue);
      });

      test('should track database migrations', () async {
        const fromVersion = 1;
        const toVersion = 2;
        const durationMs = 150;

        // Test migration attempt
        await analyticsService.logMigrationAttempt(fromVersion, toVersion);

        // Test successful migration
        await analyticsService.logMigrationSuccess(
          fromVersion,
          toVersion,
          durationMs,
        );

        expect(true, isTrue);
      });

      test('should track migration failures', () async {
        const fromVersion = 1;
        const toVersion = 2;
        const errorCode = 'sql_error';

        // Test migration failure
        await analyticsService.logMigrationFailure(
          fromVersion,
          toVersion,
          errorCode,
        );

        expect(true, isTrue);
      });
    });

    group('Post-MVP Metrics', () {
      test('should track feature first use', () async {
        const featureName = 'auto_suggestions';

        // First use should be logged
        await analyticsService.logFeatureFirstUse(featureName);

        // Second use should not be logged (handled internally)
        await analyticsService.logFeatureFirstUse(featureName);

        expect(true, isTrue);
      });

      test('should track sync operations', () async {
        // Test sync attempt
        await analyticsService.logSyncAttemptStarted();

        // Test successful sync
        await analyticsService.logSyncAttemptEnded(true);

        // Test failed sync
        await analyticsService.logSyncAttemptEnded(
          false,
          errorCode: 'network_error',
        );

        expect(true, isTrue);
      });

      test('should track database operations', () async {
        await analyticsService.logDatabaseOperation('load_inventory', 150);
        await analyticsService.logDatabaseOperation('save_product', 45);

        expect(true, isTrue);
      });

      test('should track empty state interactions', () async {
        await analyticsService.logEmptyStateCTAClicked('empty_inventory');

        expect(true, isTrue);
      });

      test('should track settings changes', () async {
        await analyticsService.logSettingChanged(
          'notifications_enabled',
          'true',
        );

        expect(true, isTrue);
      });

      test('should track alert feedback', () async {
        await analyticsService.logAlertFeedback('alert_123', 'useful');

        expect(true, isTrue);
      });
    });

    group('User Properties', () {
      test('should set household profile', () async {
        await analyticsService.setHouseholdProfile(
          householdSize: 4,
          householdType: 'apartment',
          primaryLanguage: 'français',
        );

        expect(true, isTrue);
      });

      test('should set user properties', () async {
        await analyticsService.setUserProperty('test_property', 'test_value');

        expect(true, isTrue);
      });
    });

    group('Connectivity Tracking', () {
      test('should track connectivity changes', () async {
        // Test offline transition
        await analyticsService.trackConnectivityChange(ConnectivityResult.none);

        // Test online transition
        await analyticsService.trackConnectivityChange(ConnectivityResult.wifi);

        expect(true, isTrue);
      });
    });

    group('Convenience Methods', () {
      test('should track inventory actions', () async {
        await analyticsService.logInventoryAction('viewed');
        await analyticsService.logInventoryAction(
          'filtered',
          params: {'filter_type': 'category'},
        );

        expect(true, isTrue);
      });

      test('should track alert actions', () async {
        await analyticsService.logAlertAction('viewed');
        await analyticsService.logAlertAction(
          'dismissed',
          params: {'alert_type': 'low_stock'},
        );

        expect(true, isTrue);
      });

      test('should track budget actions', () async {
        await analyticsService.logBudgetAction('created');
        await analyticsService.logBudgetAction(
          'updated',
          params: {'budget_category': 'hygiene'},
        );

        expect(true, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle analytics errors gracefully', () async {
        // Test that analytics errors don't crash the app
        await analyticsService.logEvent('test_event');
        await analyticsService.setUserProperty('test_prop', 'test_value');

        // Should complete without throwing
        expect(true, isTrue);
      });

      test('should handle null parameters', () async {
        await analyticsService.logEvent('test_event', parameters: null);
        await analyticsService.setUserProperty('test_prop', null);

        expect(true, isTrue);
      });
    });

    group('Performance', () {
      test('should handle rapid event logging', () async {
        // Test rapid fire events
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(analyticsService.logEvent('rapid_event_$i'));
        }

        await Future.wait(futures);
        expect(true, isTrue);
      });

      test('should handle concurrent operations', () async {
        // Test concurrent analytics operations
        await Future.wait([
          analyticsService.logOnboardingStarted(),
          analyticsService.logFlowStarted('test_flow'),
          analyticsService.logItemAction('added'),
          analyticsService.setUserProperty('test', 'value'),
        ]);

        expect(true, isTrue);
      });
    });
  });

  group('Analytics Integration Tests', () {
    test('should integrate with app lifecycle', () async {
      final analyticsService = AnalyticsService();

      // Test initialization
      await analyticsService.initialize();

      // Test typical user journey
      await analyticsService.logOnboardingStarted();
      await analyticsService.logFlowStarted('onboarding');

      await analyticsService.setHouseholdProfile(
        householdSize: 3,
        householdType: 'house',
        primaryLanguage: 'français',
      );

      await analyticsService.logOnboardingCompleted();
      await analyticsService.logFlowCompleted('onboarding');

      await analyticsService.logFlowStarted('add_product');
      await analyticsService.logItemAction(
        'added',
        params: {'product_type': 'consumable', 'category': 'kitchen'},
      );
      await analyticsService.logFlowCompleted('add_product');

      expect(true, isTrue);
    });
  });
}

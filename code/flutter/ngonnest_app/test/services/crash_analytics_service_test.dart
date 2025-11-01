import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/services/crash_analytics_service.dart';
import 'package:ngonnest_app/services/error_logger_service.dart';

// Generate mocks with: dart run build_runner build
@GenerateMocks([])
class MockCrashAnalyticsService extends Mock implements CrashAnalyticsService {}

void main() {
  group('CrashAnalyticsService', () {
    late CrashAnalyticsService service;

    setUp(() {
      service = CrashAnalyticsService();
    });

    test('should be a singleton', () {
      final instance1 = CrashAnalyticsService();
      final instance2 = CrashAnalyticsService();
      expect(instance1, equals(instance2));
    });

    test('should not be initialized before initialize() is called', () {
      expect(service.isInitialized, isFalse);
    });

    test('setUserId should not throw when not initialized', () async {
      expect(() async => await service.setUserId('test_user'), returnsNormally);
    });

    test('setSessionId should not throw when not initialized', () async {
      expect(() async => await service.setSessionId('test_session'), returnsNormally);
    });

    test('logNonFatalError should not throw when not initialized', () async {
      expect(
        () async => await service.logNonFatalError(
          component: 'TestComponent',
          operation: 'testOperation',
          error: Exception('Test error'),
          severity: ErrorSeverity.medium,
        ),
        returnsNormally,
      );
    });

    test('logFatalCrash should not throw when not initialized', () async {
      expect(
        () async => await service.logFatalCrash(
          error: Exception('Fatal error'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('setCustomKey should not throw when not initialized', () async {
      expect(
        () async => await service.setCustomKey('test_key', 'test_value'),
        returnsNormally,
      );
    });

    test('log should not throw when not initialized', () async {
      expect(() async => await service.log('Test message'), returnsNormally);
    });

    test('sendUnsentReports should not throw when not initialized', () async {
      expect(() async => await service.sendUnsentReports(), returnsNormally);
    });

    test('checkForUnsentReports should return false when not initialized', () async {
      final result = await service.checkForUnsentReports();
      expect(result, isFalse);
    });

    test('setCrashlyticsCollectionEnabled should not throw when not initialized', () async {
      expect(
        () async => await service.setCrashlyticsCollectionEnabled(true),
        returnsNormally,
      );
    });
  });
}

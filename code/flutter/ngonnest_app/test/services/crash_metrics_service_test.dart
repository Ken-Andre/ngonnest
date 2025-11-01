import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/crash_metrics_service.dart';
import 'package:ngonnest_app/services/error_logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashMetricsService', () {
    late CrashMetricsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = CrashMetricsService();
    });

    test('should be a singleton', () {
      final instance1 = CrashMetricsService();
      final instance2 = CrashMetricsService();
      expect(instance1, equals(instance2));
    });

    test('startSession should generate a session ID', () async {
      await service.startSession();
      expect(service.currentSessionId, isNotNull);
    });

    test('startSession should increment session count', () async {
      await service.startSession();
      await service.startSession();
      
      final prefs = await SharedPreferences.getInstance();
      final totalSessions = prefs.getInt('crash_metrics_total_sessions') ?? 0;
      expect(totalSessions, equals(2));
    });

    test('recordCrash should increment total crashes', () async {
      await service.startSession();
      
      await service.recordCrash(
        component: 'TestComponent',
        operation: 'testOperation',
        severity: ErrorSeverity.medium,
        isFatal: false,
      );

      final prefs = await SharedPreferences.getInstance();
      final totalCrashes = prefs.getInt('crash_metrics_total') ?? 0;
      expect(totalCrashes, equals(1));
    });

    test('recordCrash should track fatal vs non-fatal', () async {
      await service.startSession();
      
      // Non-fatal
      await service.recordCrash(
        component: 'TestComponent',
        operation: 'testOp1',
        severity: ErrorSeverity.medium,
        isFatal: false,
      );

      // Fatal
      await service.recordCrash(
        component: 'TestComponent',
        operation: 'testOp2',
        severity: ErrorSeverity.critical,
        isFatal: true,
      );

      final prefs = await SharedPreferences.getInstance();
      final fatalCrashes = prefs.getInt('crash_metrics_fatal') ?? 0;
      final nonFatalCrashes = prefs.getInt('crash_metrics_non_fatal') ?? 0;
      
      expect(fatalCrashes, equals(1));
      expect(nonFatalCrashes, equals(1));
    });

    test('recordCrash should track crashes by component', () async {
      await service.startSession();
      
      await service.recordCrash(
        component: 'ComponentA',
        operation: 'op1',
        severity: ErrorSeverity.medium,
      );

      await service.recordCrash(
        component: 'ComponentA',
        operation: 'op2',
        severity: ErrorSeverity.medium,
      );

      await service.recordCrash(
        component: 'ComponentB',
        operation: 'op1',
        severity: ErrorSeverity.medium,
      );

      final metrics = await service.getCurrentMetrics();
      expect(metrics?.crashesByComponent['ComponentA'], equals(2));
      expect(metrics?.crashesByComponent['ComponentB'], equals(1));
    });

    test('recordCrash should track crashes by operation', () async {
      await service.startSession();
      
      await service.recordCrash(
        component: 'Component',
        operation: 'operation1',
        severity: ErrorSeverity.medium,
      );

      await service.recordCrash(
        component: 'Component',
        operation: 'operation1',
        severity: ErrorSeverity.medium,
      );

      final metrics = await service.getCurrentMetrics();
      expect(metrics?.crashesByOperation['Component.operation1'], equals(2));
    });

    test('recordCrash should track crashes by severity', () async {
      await service.startSession();
      
      await service.recordCrash(
        component: 'Component',
        operation: 'op1',
        severity: ErrorSeverity.low,
      );

      await service.recordCrash(
        component: 'Component',
        operation: 'op2',
        severity: ErrorSeverity.high,
      );

      await service.recordCrash(
        component: 'Component',
        operation: 'op3',
        severity: ErrorSeverity.high,
      );

      final metrics = await service.getCurrentMetrics();
      expect(metrics?.crashesBySeverity[ErrorSeverity.low], equals(1));
      expect(metrics?.crashesBySeverity[ErrorSeverity.high], equals(2));
    });

    test('getCrashRate should calculate correctly', () async {
      await service.startSession();
      await service.startSession();
      await service.startSession();
      await service.startSession();
      await service.startSession(); // 5 sessions

      await service.recordCrash(
        component: 'Component',
        operation: 'op1',
        severity: ErrorSeverity.medium,
      ); // 1 crash

      final crashRate = await service.getCrashRate();
      expect(crashRate, equals(20.0)); // 1/5 * 100 = 20%
    });

    test('getCurrentMetrics should return null when no crashes', () async {
      final metrics = await service.getCurrentMetrics();
      expect(metrics, isNull);
    });

    test('getCurrentMetrics should return valid metrics after crashes', () async {
      await service.startSession();
      
      await service.recordCrash(
        component: 'TestComponent',
        operation: 'testOp',
        severity: ErrorSeverity.high,
        isFatal: false,
      );

      final metrics = await service.getCurrentMetrics();
      expect(metrics, isNotNull);
      expect(metrics!.totalCrashes, equals(1));
      expect(metrics.fatalCrashes, equals(0));
      expect(metrics.nonFatalCrashes, equals(1));
    });

    test('CrashMetrics.getCrashRate should calculate correctly', () async {
      await service.startSession();
      await service.startSession();
      await service.startSession();
      await service.startSession(); // 4 sessions

      await service.recordCrash(
        component: 'Component',
        operation: 'op1',
        severity: ErrorSeverity.medium,
      );

      final metrics = await service.getCurrentMetrics();
      final crashRate = metrics!.getCrashRate(4);
      expect(crashRate, equals(25.0)); // 1/4 * 100 = 25%
    });

    test('CrashMetrics.getFatalCrashRate should calculate correctly', () async {
      await service.startSession();

      // 2 non-fatal
      await service.recordCrash(
        component: 'Component',
        operation: 'op1',
        severity: ErrorSeverity.medium,
        isFatal: false,
      );
      await service.recordCrash(
        component: 'Component',
        operation: 'op2',
        severity: ErrorSeverity.medium,
        isFatal: false,
      );

      // 1 fatal
      await service.recordCrash(
        component: 'Component',
        operation: 'op3',
        severity: ErrorSeverity.critical,
        isFatal: true,
      );

      final metrics = await service.getCurrentMetrics();
      final fatalRate = metrics!.getFatalCrashRate();
      expect(fatalRate, closeTo(33.33, 0.01)); // 1/3 * 100 ≈ 33.33%
    });

    test('resetMetrics should clear all data', () async {
      await service.startSession();
      
      await service.recordCrash(
        component: 'Component',
        operation: 'op1',
        severity: ErrorSeverity.medium,
      );

      await service.resetMetrics();

      final metrics = await service.getCurrentMetrics();
      expect(metrics, isNull);

      final crashRate = await service.getCrashRate();
      expect(crashRate, equals(0.0));
    });
  });
}

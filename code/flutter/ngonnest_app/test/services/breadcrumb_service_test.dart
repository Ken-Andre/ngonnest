import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/breadcrumb_service.dart';

void main() {
  group('BreadcrumbService', () {
    late BreadcrumbService service;

    setUp(() {
      service = BreadcrumbService();
      service.clear(); // Start with clean state
    });

    test('should be a singleton', () {
      final instance1 = BreadcrumbService();
      final instance2 = BreadcrumbService();
      expect(instance1, equals(instance2));
    });

    test('should start empty', () {
      service.clear();
      expect(service.isEmpty, isTrue);
      expect(service.count, equals(0));
    });

    test('addNavigation should add a breadcrumb', () {
      service.addNavigation('HomeScreen');
      expect(service.count, equals(1));
      expect(service.isEmpty, isFalse);
    });

    test('addUserAction should add a breadcrumb', () {
      service.addUserAction('Tapped button');
      expect(service.count, equals(1));
    });

    test('addStateChange should add a breadcrumb', () {
      service.addStateChange('App resumed');
      expect(service.count, equals(1));
    });

    test('addNetworkRequest should add a breadcrumb', () {
      service.addNetworkRequest(
        method: 'GET',
        url: '/api/products',
        statusCode: 200,
      );
      expect(service.count, equals(1));
    });

    test('addDatabaseOperation should add a breadcrumb', () {
      service.addDatabaseOperation('Insert product');
      expect(service.count, equals(1));
    });

    test('addError should add a breadcrumb', () {
      service.addError('Something went wrong');
      expect(service.count, equals(1));
    });

    test('addLifecycle should add a breadcrumb', () {
      service.addLifecycle('App started');
      expect(service.count, equals(1));
    });

    test('addSystem should add a breadcrumb', () {
      service.addSystem('Low memory warning');
      expect(service.count, equals(1));
    });

    test('should limit breadcrumbs to max size', () {
      // Add more than max (100)
      for (int i = 0; i < 150; i++) {
        service.addUserAction('Action $i');
      }
      expect(service.count, equals(100));
      expect(service.isFull, isTrue);
    });

    test('getAllBreadcrumbs should return all breadcrumbs', () {
      service.addNavigation('Screen1');
      service.addNavigation('Screen2');
      service.addUserAction('Action1');

      final breadcrumbs = service.getAllBreadcrumbs();
      expect(breadcrumbs.length, equals(3));
    });

    test('getRecentBreadcrumbs should return limited breadcrumbs', () async {
      service.addNavigation('Screen1');
      service.addNavigation('Screen2');
      service.addNavigation('Screen3');
      service.addNavigation('Screen4');
      service.addNavigation('Screen5');

      final recent = await service.getRecentBreadcrumbs(limit: 3);
      expect(recent.length, equals(3));
    });

    test('getBreadcrumbsByType should filter by type', () {
      service.addNavigation('Screen1');
      service.addNavigation('Screen2');
      service.addUserAction('Action1');
      service.addError('Error1');

      final navBreadcrumbs = service.getBreadcrumbsByType(BreadcrumbType.navigation);
      expect(navBreadcrumbs.length, equals(2));

      final errorBreadcrumbs = service.getBreadcrumbsByType(BreadcrumbType.error);
      expect(errorBreadcrumbs.length, equals(1));
    });

    test('getBreadcrumbsByLevel should filter by level', () {
      service.addNavigation('Screen1'); // info
      service.addUserAction('Action1'); // info
      service.addError('Error1'); // error

      final infoBreadcrumbs = service.getBreadcrumbsByLevel(BreadcrumbLevel.info);
      expect(infoBreadcrumbs.length, equals(2));

      final errorBreadcrumbs = service.getBreadcrumbsByLevel(BreadcrumbLevel.error);
      expect(errorBreadcrumbs.length, equals(1));
    });

    test('getBreadcrumbsInTimeRange should filter by time', () async {
      final start = DateTime.now();
      
      service.addNavigation('Screen1');
      await Future.delayed(const Duration(milliseconds: 100));
      service.addNavigation('Screen2');
      await Future.delayed(const Duration(milliseconds: 100));
      service.addNavigation('Screen3');
      
      final end = DateTime.now();

      final breadcrumbs = service.getBreadcrumbsInTimeRange(
        start: start,
        end: end,
      );
      expect(breadcrumbs.length, equals(3));
    });

    test('clear should remove all breadcrumbs', () {
      service.addNavigation('Screen1');
      service.addNavigation('Screen2');
      service.addUserAction('Action1');

      expect(service.count, equals(3));

      service.clear();

      expect(service.count, equals(0));
      expect(service.isEmpty, isTrue);
    });

    test('exportToJson should return valid JSON', () {
      service.addNavigation('Screen1');
      service.addUserAction('Action1', data: {'key': 'value'});

      final json = service.exportToJson();
      expect(json, isA<List<Map<String, dynamic>>>());
      expect(json.length, equals(2));
      expect(json[0]['type'], equals('navigation'));
      expect(json[1]['data'], equals({'key': 'value'}));
    });

    test('breadcrumb toString should format correctly', () {
      service.addNavigation('TestScreen');
      final breadcrumbs = service.getAllBreadcrumbs();
      final breadcrumbStr = breadcrumbs.first.toString();

      expect(breadcrumbStr, contains('info'));
      expect(breadcrumbStr, contains('navigation'));
      expect(breadcrumbStr, contains('TestScreen'));
    });

    test('addCustom should add breadcrumb with custom properties', () {
      service.addCustom(
        type: BreadcrumbType.userAction,
        level: BreadcrumbLevel.warning,
        message: 'Custom action',
        data: {'custom': 'data'},
      );

      final breadcrumbs = service.getAllBreadcrumbs();
      expect(breadcrumbs.length, equals(1));
      expect(breadcrumbs.first.type, equals(BreadcrumbType.userAction));
      expect(breadcrumbs.first.level, equals(BreadcrumbLevel.warning));
      expect(breadcrumbs.first.message, equals('Custom action'));
      expect(breadcrumbs.first.data, equals({'custom': 'data'}));
    });
  });
}

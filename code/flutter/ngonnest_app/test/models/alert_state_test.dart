import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/alert_state.dart';

void main() {
  group('AlertState', () {
    late AlertState alertState;

    setUp(() {
      alertState = AlertState(
        alertId: 1,
        isRead: false,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4),
      );
    });

    test('can be instantiated', () {
      expect(alertState, isNotNull);
      expect(alertState.alertId, equals(1));
      expect(alertState.isRead, isFalse);
      expect(alertState.isResolved, isFalse);
      expect(alertState.updatedAt, equals(DateTime(2025, 12, 4)));
    });

    test('copyWith creates a new instance with updated values', () {
      final updatedAlertState = alertState.copyWith(
        isRead: true,
        isResolved: true,
      );

      expect(updatedAlertState.alertId, equals(alertState.alertId));
      expect(updatedAlertState.isRead, isTrue);
      expect(updatedAlertState.isResolved, isTrue);
      expect(updatedAlertState.updatedAt, equals(alertState.updatedAt));
    });

    test('toMap converts AlertState to Map correctly', () {
      final map = alertState.toMap();

      expect(map['alert_id'], equals(1));
      expect(map['is_read'], equals(0)); // false = 0
      expect(map['is_resolved'], equals(0)); // false = 0
      expect(map['last_updated'], equals('2025-12-04T00:00:00.000'));
    });

    test('fromMap creates AlertState from Map correctly', () {
      final map = {
        'alert_id': 2,
        'is_read': 1,
        'is_resolved': 1,
        'last_updated': '2025-12-04T10:30:00.000',
      };

      final fromMapAlertState = AlertState.fromMap(map);

      expect(fromMapAlertState.alertId, equals(2));
      expect(fromMapAlertState.isRead, isTrue);
      expect(fromMapAlertState.isResolved, isTrue);
      expect(
        fromMapAlertState.updatedAt,
        equals(DateTime(2025, 12, 4, 10, 30, 0, 0, 0)),
      );
    });

    test('equality operator works correctly', () {
      final alertState1 = AlertState(
        alertId: 1,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4),
      );

      final alertState2 = AlertState(
        alertId: 1,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4),
      );

      final alertState3 = AlertState(
        alertId: 2,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4),
      );

      expect(alertState1, equals(alertState2));
      expect(alertState1, isNot(equals(alertState3)));
    });

    test('hashCode is consistent', () {
      final alertState1 = AlertState(
        alertId: 1,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4),
      );

      final alertState2 = AlertState(
        alertId: 1,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4),
      );

      expect(alertState1.hashCode, equals(alertState2.hashCode));
    });

    test('toString returns correct string representation', () {
      final expectedString =
          'AlertState(alertId: 1, isRead: false, isResolved: false, updatedAt: 2025-12-04 00:00:00.000)';
      expect(alertState.toString(), equals(expectedString));
    });
  });
}
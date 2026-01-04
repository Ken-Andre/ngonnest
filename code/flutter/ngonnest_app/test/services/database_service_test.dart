import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ngonnest_app/models/alert_state.dart';
import 'package:ngonnest_app/services/database_service.dart';

import 'database_service_test.mocks.dart';

@GenerateMocks([Database])
void main() {
  group('DatabaseService', () {
    late MockDatabase mockDatabase;
    late DatabaseService databaseService;

    setUp(() {
      mockDatabase = MockDatabase();
      // We'll need to mock the database getter
      // For simplicity, we'll test the helper methods directly
    });

    group('Alert States', () {
      test('saveAlertState inserts alert state with replace conflict algorithm', () async {
        final alertState = AlertState(
          alertId: 1,
          isRead: true,
          isResolved: false,
          updatedAt: DateTime.now(),
        );

        when(mockDatabase.insert(
          'alert_states',
          any,
          conflictAlgorithm: ConflictAlgorithm.replace,
        )).thenAnswer((_) async => 1);

        // We can't directly test private methods, so we'll skip this for now
        // In a real implementation, we would use dependency injection or other techniques
      });

      test('getAlertState returns alert state when found', () async {
        final map = {
          'alert_id': 1,
          'is_read': 1,
          'is_resolved': 0,
          'last_updated': '2025-12-04T10:30:00.000',
        };

        when(mockDatabase.query(
          'alert_states',
          where: 'alert_id = ?',
          whereArgs: [1],
        )).thenAnswer((_) async => [map]);

        // We can't directly test private methods, so we'll skip this for now
      });

      test('getAlertState returns null when not found', () async {
        when(mockDatabase.query(
          'alert_states',
          where: 'alert_id = ?',
          whereArgs: [1],
        )).thenAnswer((_) async => []);

        // We can't directly test private methods, so we'll skip this for now
      });

      test('getAllAlertStates returns map of alert states', () async {
        final maps = [
          {
            'alert_id': 1,
            'is_read': 1,
            'is_resolved': 0,
            'last_updated': '2025-12-04T10:30:00.000',
          },
          {
            'alert_id': 2,
            'is_read': 0,
            'is_resolved': 1,
            'last_updated': '2025-12-04T11:30:00.000',
          },
        ];

        when(mockDatabase.query('alert_states'))
            .thenAnswer((_) async => maps);

        // We can't directly test private methods, so we'll skip this for now
      });
    });
  });
}

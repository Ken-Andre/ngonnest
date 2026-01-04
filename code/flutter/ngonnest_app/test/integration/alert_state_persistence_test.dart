import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/models/alert_state.dart';
import 'package:ngonnest_app/repository/alert_state_repository.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Alert State Persistence Integration', () {
    late DatabaseService databaseService;
    late AlertStateRepository alertStateRepository;

    setUp(() async {
      // Initialize FFI database for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // Create a test database service
      databaseService = DatabaseService();
      
      // Initialize the repository
      alertStateRepository = AlertStateRepository(databaseService);
    });

    tearDown(() async {
      // Clean up test database
      final db = await databaseService.database;
      await db.close();
    });

    test('save and retrieve alert state', () async {
      final alertState = AlertState(
        alertId: 100,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4, 10, 30),
      );

      // Save the alert state
      await alertStateRepository.saveAlertState(alertState);

      // Retrieve the alert state
      final retrievedState = await alertStateRepository.getAlertState(100);

      // Verify the retrieved state matches what we saved
      expect(retrievedState, isNotNull);
      expect(retrievedState!.alertId, equals(100));
      expect(retrievedState.isRead, isTrue);
      expect(retrievedState.isResolved, isFalse);
      expect(retrievedState.updatedAt, equals(DateTime(2025, 12, 4, 10, 30)));
    });

    test('update existing alert state', () async {
      final initialState = AlertState(
        alertId: 200,
        isRead: false,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4, 10, 0),
      );

      final updatedState = AlertState(
        alertId: 200,
        isRead: true,
        isResolved: true,
        updatedAt: DateTime(2025, 12, 4, 11, 0),
      );

      // Save initial state
      await alertStateRepository.saveAlertState(initialState);

      // Update state
      await alertStateRepository.saveAlertState(updatedState);

      // Retrieve the updated state
      final retrievedState = await alertStateRepository.getAlertState(200);

      // Verify the retrieved state matches the updated state
      expect(retrievedState, isNotNull);
      expect(retrievedState!.alertId, equals(200));
      expect(retrievedState.isRead, isTrue);
      expect(retrievedState.isResolved, isTrue);
      expect(retrievedState.updatedAt, equals(DateTime(2025, 12, 4, 11, 0)));
    });

    test('get all alert states returns empty map when no states exist', () async {
      final allStates = await alertStateRepository.getAllAlertStates();

      expect(allStates, isEmpty);
    });

    test('get all alert states returns all saved states', () async {
      final state1 = AlertState(
        alertId: 300,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4, 10, 0),
      );

      final state2 = AlertState(
        alertId: 301,
        isRead: false,
        isResolved: true,
        updatedAt: DateTime(2025, 12, 4, 11, 0),
      );

      // Save both states
      await alertStateRepository.saveAlertState(state1);
      await alertStateRepository.saveAlertState(state2);

      // Retrieve all states
      final allStates = await alertStateRepository.getAllAlertStates();

      // Verify both states are returned
      expect(allStates.length, equals(2));
      expect(allStates.containsKey(300), isTrue);
      expect(allStates.containsKey(301), isTrue);
      expect(allStates[300]!.isRead, isTrue);
      expect(allStates[301]!.isResolved, isTrue);
    });

    test('mark alert as read updates only read status', () async {
      final initialState = AlertState(
        alertId: 400,
        isRead: false,
        isResolved: true,
        updatedAt: DateTime(2025, 12, 4, 10, 0),
      );

      // Save initial state
      await alertStateRepository.saveAlertState(initialState);

      // Mark as read
      await alertStateRepository.markAlertAsRead(400);

      // Retrieve the updated state
      final retrievedState = await alertStateRepository.getAlertState(400);

      // Verify only read status changed
      expect(retrievedState, isNotNull);
      expect(retrievedState!.alertId, equals(400));
      expect(retrievedState.isRead, isTrue);
      expect(retrievedState.isResolved, isTrue); // Should remain true
    });

    test('mark alert as resolved updates only resolved status', () async {
      final initialState = AlertState(
        alertId: 500,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime(2025, 12, 4, 10, 0),
      );

      // Save initial state
      await alertStateRepository.saveAlertState(initialState);

      // Mark as resolved
      await alertStateRepository.markAlertAsResolved(500);

      // Retrieve the updated state
      final retrievedState = await alertStateRepository.getAlertState(500);

      // Verify only resolved status changed
      expect(retrievedState, isNotNull);
      expect(retrievedState!.alertId, equals(500));
      expect(retrievedState.isRead, isTrue); // Should remain true
      expect(retrievedState.isResolved, isTrue);
    });
  });
}
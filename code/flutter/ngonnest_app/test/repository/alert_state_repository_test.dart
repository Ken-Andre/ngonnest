import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngonnest_app/models/alert_state.dart';
import 'package:ngonnest_app/repository/alert_state_repository.dart';
import 'package:ngonnest_app/services/database_service.dart';

import 'alert_state_repository_test.mocks.dart';

@GenerateMocks([DatabaseService])
void main() {
  group('AlertStateRepository', () {
    late MockDatabaseService mockDatabaseService;
    late AlertStateRepository alertStateRepository;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      alertStateRepository = AlertStateRepository(mockDatabaseService);
    });

    test('saveAlertState calls database service', () async {
      final alertState = AlertState(
        alertId: 1,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime.now(),
      );

      when(mockDatabaseService.saveAlertState(alertState))
          .thenAnswer((_) async {});

      await alertStateRepository.saveAlertState(alertState);

      verify(mockDatabaseService.saveAlertState(alertState)).called(1);
    });

    test('getAlertState returns alert state from database service', () async {
      final alertState = AlertState(
        alertId: 1,
        isRead: true,
        isResolved: false,
        updatedAt: DateTime.now(),
      );

      when(mockDatabaseService.getAlertState(1))
          .thenAnswer((_) async => alertState);

      final result = await alertStateRepository.getAlertState(1);

      expect(result, equals(alertState));
      verify(mockDatabaseService.getAlertState(1)).called(1);
    });

    test('getAlertState returns null when database service returns null', () async {
      when(mockDatabaseService.getAlertState(1))
          .thenAnswer((_) async => null);

      final result = await alertStateRepository.getAlertState(1);

      expect(result, isNull);
      verify(mockDatabaseService.getAlertState(1)).called(1);
    });

    test('getAllAlertStates returns map from database service', () async {
      final alertStates = <int, AlertState>{
        1: AlertState(
          alertId: 1,
          isRead: true,
          isResolved: false,
          updatedAt: DateTime.now(),
        ),
        2: AlertState(
          alertId: 2,
          isRead: false,
          isResolved: true,
          updatedAt: DateTime.now(),
        ),
      };

      when(mockDatabaseService.getAllAlertStates())
          .thenAnswer((_) async => alertStates);

      final result = await alertStateRepository.getAllAlertStates();

      expect(result, equals(alertStates));
      verify(mockDatabaseService.getAllAlertStates()).called(1);
    });

    test('getAllAlertStates returns empty map when database service throws', () async {
      when(mockDatabaseService.getAllAlertStates())
          .thenThrow(Exception('Database error'));

      final result = await alertStateRepository.getAllAlertStates();

      expect(result, isEmpty);
    });

    test('markAlertAsRead saves updated alert state', () async {
      final existingState = AlertState(
        alertId: 1,
        isRead: false,
        isResolved: false,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      when(mockDatabaseService.getAlertState(1))
          .thenAnswer((_) async => existingState);
      when(mockDatabaseService.saveAlertState(any))
          .thenAnswer((_) async {});

      await alertStateRepository.markAlertAsRead(1);

      verify(mockDatabaseService.getAlertState(1)).called(1);
      verify(mockDatabaseService.saveAlertState(argThat(
        predicate<AlertState>((state) =>
            state.alertId == 1 &&
            state.isRead == true &&
            state.isResolved == false),
      ))).called(1);
    });

    test('markAlertAsResolved saves updated alert state', () async {
      final existingState = AlertState(
        alertId: 1,
        isRead: false,
        isResolved: false,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      when(mockDatabaseService.getAlertState(1))
          .thenAnswer((_) async => existingState);
      when(mockDatabaseService.saveAlertState(any))
          .thenAnswer((_) async {});

      await alertStateRepository.markAlertAsResolved(1);

      verify(mockDatabaseService.getAlertState(1)).called(1);
      verify(mockDatabaseService.saveAlertState(argThat(
        predicate<AlertState>((state) =>
            state.alertId == 1 &&
            state.isRead == false &&
            state.isResolved == true),
      ))).called(1);
    });
  });
}
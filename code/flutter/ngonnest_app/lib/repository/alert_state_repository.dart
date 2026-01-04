import 'package:flutter/foundation.dart';

import '../models/alert_state.dart';
import '../services/database_service.dart';
import '../services/error_logger_service.dart';

/// Repository for managing alert states (read/resolved status)
///
/// Handles persistence of alert states in the local database
class AlertStateRepository {
  final DatabaseService _databaseService;

  AlertStateRepository(this._databaseService);

  /// Save an alert state to the database
  Future<void> saveAlertState(AlertState state) async {
    try {
      await _databaseService.saveAlertState(state);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertStateRepository',
        operation: 'saveAlertState',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': state.alertId},
      );
      rethrow;
    }
  }

  /// Get an alert state by alert ID
  Future<AlertState?> getAlertState(int alertId) async {
    try {
      return await _databaseService.getAlertState(alertId);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertStateRepository',
        operation: 'getAlertState',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': alertId},
      );
      return null;
    }
  }

  /// Get all alert states as a map for efficient lookup
  Future<Map<int, AlertState>> getAllAlertStates() async {
    try {
      return await _databaseService.getAllAlertStates();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertStateRepository',
        operation: 'getAllAlertStates',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      return {};
    }
  }

  /// Mark an alert as read
  Future<void> markAlertAsRead(int alertId) async {
    try {
      final currentState = await getAlertState(alertId);
      final newState = AlertState(
        alertId: alertId,
        isRead: true,
        isResolved: currentState?.isResolved ?? false,
        updatedAt: DateTime.now(),
      );
      await saveAlertState(newState);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertStateRepository',
        operation: 'markAlertAsRead',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': alertId},
      );
      rethrow;
    }
  }

  /// Mark an alert as resolved
  Future<void> markAlertAsResolved(int alertId) async {
    try {
      final currentState = await getAlertState(alertId);
      final newState = AlertState(
        alertId: alertId,
        isRead: currentState?.isRead ?? true,
        isResolved: true,
        updatedAt: DateTime.now(),
      );
      await saveAlertState(newState);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertStateRepository',
        operation: 'markAlertAsResolved',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': alertId},
      );
      rethrow;
    }
  }
}
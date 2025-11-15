import '../models/foyer.dart';
import '../services/database_service.dart';
import '../services/error_logger_service.dart';

/// Repository for Foyer data operations
/// Implements the Repository pattern as a wrapper around DatabaseService
/// to ensure data persistence and comply with US-3.1 requirements
class FoyerRepository {
  final DatabaseService _databaseService;

  FoyerRepository(this._databaseService);

  /// Get the foyer data with error recovery
  Future<Foyer?> get() async {
    try {
      return await _databaseService.getFoyer();
    } catch (e, stackTrace) {
      print('[FoyerRepository] Error getting foyer: $e');
      print('StackTrace: $stackTrace');

      // Log the error for debugging
      await ErrorLoggerService.logError(
        component: 'FoyerRepository',
        operation: 'get',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      // Attempt recovery by checking connection
      try {
        final isValid = await _databaseService.isConnectionValid();
        if (!isValid) {
          print('[FoyerRepository] Connection invalid, attempting recovery...');
          // The next call will automatically trigger recovery
          return await _databaseService.getFoyer();
        }
      } catch (recoveryError, recoveryStackTrace) {
        await ErrorLoggerService.logError(
          component: 'FoyerRepository',
          operation: 'get_recovery',
          error: recoveryError,
          stackTrace: recoveryStackTrace,
          severity: ErrorSeverity.high,
        );
      }

      rethrow;
    }
  }

  /// Save foyer data (create or update) with error recovery
  /// Returns the inserted/updated ID
  Future<int> save(Foyer foyer) async {
    try {
      // Check if foyer already exists
      final existing = await _databaseService.getFoyer();

      if (existing != null) {
        // Update existing foyer
        await _databaseService.updateFoyer(foyer);
        return int.tryParse(existing.id!) ?? 0;
      } else {
        // Create new foyer
        final result = await _databaseService.insertFoyer(foyer);
        return int.tryParse(result.toString()) ?? 0;
      }
    } catch (e, stackTrace) {
      print('[FoyerRepository] Error saving foyer: $e');
      print('StackTrace: $stackTrace');

      await ErrorLoggerService.logError(
        component: 'FoyerRepository',
        operation: 'save',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'foyer_id': foyer.id},
      );

      rethrow;
    }
  }

  /// Update foyer data with error recovery
  Future<int> update(Foyer foyer) async {
    if (foyer.id == null) {
      throw ArgumentError('Cannot update foyer: id is null');
    }

    try {
      return await _databaseService.updateFoyer(foyer);
    } catch (e, stackTrace) {
      print('[FoyerRepository] Error updating foyer: $e');
      print('StackTrace: $stackTrace');

      await ErrorLoggerService.logError(
        component: 'FoyerRepository',
        operation: 'update',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'foyer_id': foyer.id},
      );

      rethrow;
    }
  }

  /// Delete foyer data with error recovery
  Future<int> delete(int id) async {
    try {
      return await _databaseService.deleteFoyer(id);
    } catch (e, stackTrace) {
      print('[FoyerRepository] Error deleting foyer: $e');
      print('StackTrace: $stackTrace');

      await ErrorLoggerService.logError(
        component: 'FoyerRepository',
        operation: 'delete',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'foyer_id': id},
      );

      rethrow;
    }
  }

  /// Check if foyer data exists with error recovery
  Future<bool> exists() async {
    try {
      final foyer = await _databaseService.getFoyer();
      return foyer != null;
    } catch (e, stackTrace) {
      print('[FoyerRepository] Error checking foyer existence: $e');
      print('StackTrace: $stackTrace');

      await ErrorLoggerService.logError(
        component: 'FoyerRepository',
        operation: 'exists',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );

      return false; // Default to false on error
    }
  }
}

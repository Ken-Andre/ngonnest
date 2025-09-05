import '../models/foyer.dart';
import '../services/database_service.dart';

/// Repository for Foyer data operations
/// Implements the Repository pattern as a wrapper around DatabaseService
/// to ensure data persistence and comply with US-3.1 requirements
class FoyerRepository {
  final DatabaseService _databaseService;

  FoyerRepository(this._databaseService);

  /// Get the foyer data
  Future<Foyer?> get() async {
    return await _databaseService.getFoyer();
  }

  /// Save foyer data (create or update)
  /// Returns the inserted/updated ID
  Future<int> save(Foyer foyer) async {
    // Check if foyer already exists
    final existing = await _databaseService.getFoyer();

    if (existing != null) {
      // Update existing foyer
      await _databaseService.updateFoyer(foyer);
      return existing.id!;
    } else {
      // Create new foyer
      return await _databaseService.insertFoyer(foyer);
    }
  }

  /// Update foyer data
  Future<int> update(Foyer foyer) async {
    if (foyer.id == null) {
      throw ArgumentError('Cannot update foyer: id is null');
    }
    return await _databaseService.updateFoyer(foyer);
  }

  /// Delete foyer data
  Future<int> delete(int id) async {
    return await _databaseService.deleteFoyer(id);
  }

  /// Check if foyer data exists
  Future<bool> exists() async {
    final foyer = await _databaseService.getFoyer();
    return foyer != null;
  }
}

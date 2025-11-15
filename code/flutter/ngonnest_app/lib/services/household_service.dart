import 'dart:math';

import '../models/foyer.dart';
import '../repository/foyer_repository.dart';
import '../services/console_logger.dart';
import '../services/database_service.dart';
import '../services/error_logger_service.dart';

class HouseholdService {
  static FoyerRepository? _foyerRepository;
  static DatabaseService? _databaseService;
  static Foyer? _cachedFoyer;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // UUID generation removed after migration completion

  static Future<FoyerRepository> get foyerRepository async {
    if (_foyerRepository != null) return _foyerRepository!;

    _databaseService ??= DatabaseService();
    _foyerRepository = FoyerRepository(_databaseService!);
    return _foyerRepository!;
  }

  // Create or update household profile
  static Future<int> saveFoyer(Foyer foyer) async {
    try {
      ConsoleLogger.info("Saving foyer with ${foyer.nbPersonnes} personnes");

      final repo = await foyerRepository;
      final result = await repo.save(foyer);

      // Clear cache after save
      clearCache();

      ConsoleLogger.success("Foyer saved successfully with ID: $result");

      // Log succès détaillé
      await ErrorLoggerService.logError(
        component: 'HouseholdService',
        operation: 'saveFoyer',
        error: 'SUCCESS: Foyer saved successfully',
        stackTrace: StackTrace.current,
        severity: ErrorSeverity.low,
        metadata: {
          'foyerId': result,
          'nbPersonnes': foyer.nbPersonnes,
          'typeLogement': foyer.typeLogement,
        },
      );

      return result;
    } catch (e, stackTrace) {
      // Log simple dans la console - comme en Python/Java
      ConsoleLogger.error(
        'HouseholdService',
        'saveFoyer',
        e,
        stackTrace: stackTrace,
      );

      // Log détaillé pour le système de debugging existant
      await ErrorLoggerService.logError(
        component: 'HouseholdService',
        operation: 'saveFoyer',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'nbPersonnes': foyer.nbPersonnes,
          'typeLogement': foyer.typeLogement,
        },
      );
      rethrow;
    }
  }

  // Create and save foyer from raw data
  static Future<String> createAndSaveFoyer(
    int nbPersonnes,
    String typeLogement,
    String langue, {
    int? nbPieces,
    double? budgetMensuelEstime,
    String? id,
  }) async {
    final foyer = Foyer(
      id: id, // Use provided ID or let database auto-generate
      nbPersonnes: nbPersonnes,
      nbPieces:
          nbPieces ??
          (nbPersonnes <= 2
              ? 2
              : nbPersonnes <= 4
              ? 3
              : 4),
      typeLogement: typeLogement,
      langue: langue,
      budgetMensuelEstime: budgetMensuelEstime,
    );
    final savedId = await saveFoyer(foyer);
    return savedId.toString();
  }

  // Get foyer data with caching
  static Future<Foyer?> getFoyer() async {
    // Check if we have a valid cached version
    if (_cachedFoyer != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedFoyer;
    }

    try {
      final repo = await foyerRepository;
      final foyer = await repo.get();

      // Update cache
      _cachedFoyer = foyer;
      _lastFetchTime = DateTime.now();

      return foyer;
    } catch (e) {
      // If we have a cached version, return it even if it's stale
      if (_cachedFoyer != null) {
        ConsoleLogger.warning("Returning cached foyer due to error: $e");
        return _cachedFoyer;
      }
      rethrow;
    }
  }

  // Clear foyer cache
  static void clearCache() {
    _cachedFoyer = null;
    _lastFetchTime = null;
  }

  // Check if foyer data exists
  static Future<bool> hasFoyer() async {
    final repo = await foyerRepository;
    return await repo.exists();
  }

  // Update foyer data
  static Future<int> updateFoyer(Foyer foyer) async {
    final repo = await foyerRepository;
    return await repo.update(foyer);
  }

  // Delete foyer data
  static Future<int> deleteFoyer(int id) async {
    final repo = await foyerRepository;
    return await repo.delete(id);
  }

  // Legacy methods for compatibility (deprecated - use foyer methods instead)
  @deprecated
  static Future<String> saveHouseholdProfile(dynamic profile) async {
    final result = await saveFoyer(profile);
    return result.toString(); // Convert int to string for legacy compatibility
  }

  @deprecated
  static Future<dynamic> getHouseholdProfile() async {
    return await getFoyer();
  }

  @deprecated
  static Future<bool> hasHouseholdProfile() async {
    return await hasFoyer();
  }
}

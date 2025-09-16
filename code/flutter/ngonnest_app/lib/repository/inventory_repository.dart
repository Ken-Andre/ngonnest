import '../models/objet.dart';
import '../services/database_service.dart';
import '../services/prediction_service.dart';
import '../services/error_logger_service.dart';

/// Repository for Inventory (Objet) data operations
/// Implements the Repository pattern as a wrapper around DatabaseService
/// to comply with US-3.2 requirements for functional CRUD inventory
/// 
/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: INVENTORY_CRUD_VALIDATION - CRUD operations may not work properly
///       - Database connection recovery logic not tested
///       - Update operations may fail with complex data
///       - Delete operations may not cascade properly
/// TODO: INVENTORY_PREDICTION_INTEGRATION - PredictionService integration incomplete
///       - Rupture date calculations may be inaccurate
///       - Automatic updates may not trigger properly
///       - Prediction logic not validated with real data
/// TODO: INVENTORY_ERROR_RECOVERY - Error recovery mechanisms incomplete
///       - Database connection errors may not recover gracefully
///       - Transaction rollback not implemented
///       - Data consistency not guaranteed during failures
/// TODO: INVENTORY_PERFORMANCE - Performance issues with large inventories
///       - Queries may be slow with many items
///       - Filtering operations not optimized
///       - Memory usage may be excessive
class InventoryRepository {
  final DatabaseService _databaseService;

  InventoryRepository(this._databaseService);

  /// Create a new inventory item with automatic recovery
  /// Automatically calculates rupture date for consumables using PredictionService
  /// Returns the ID of the newly created item
  Future<int> create(Objet objet) async {
    try {
      // Calculate rupture date for consumables
      final objetWithRuptureDate = PredictionService.updateRuptureDate(objet);
      return await _databaseService.insertObjet(objetWithRuptureDate);
    } catch (e, stackTrace) {
      print('Database error in InventoryRepository.create: $e');
      print('StackTrace: $stackTrace');

      // Attempt automatic recovery on database errors
      if (_isDatabaseConnectionError(e)) {
        print('[InventoryRepository] Database connection error detected, attempting recovery...');
        try {
          final isValid = await _databaseService.isConnectionValid();
          if (!isValid) {
            // Try again after potential recovery
            await Future.delayed(const Duration(milliseconds: 200));
            final objetWithRuptureDate = PredictionService.updateRuptureDate(objet);
            return await _databaseService.insertObjet(objetWithRuptureDate);
          }
        } catch (recoveryError, recoveryStackTrace) {
          await ErrorLoggerService.logError(
            component: 'InventoryRepository',
            operation: 'create_recovery_attempt',
            error: recoveryError,
            stackTrace: recoveryStackTrace,
            severity: ErrorSeverity.high,
            metadata: {'original_error': e.toString()},
          );
        }
      }

      await ErrorLoggerService.logError(
        component: 'InventoryRepository',
        operation: 'create',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {
          'productName': objet.nom,
          'productCategory': objet.categorie,
        },
      );
      rethrow;
    }
  }

  /// Read (get) an inventory item by ID
  Future<Objet?> read(int id) async {
    try {
      return await _databaseService.getObjet(id);
    } catch (e, stackTrace) {
      print('Database error in InventoryRepository.read: $e');
      print('StackTrace: $stackTrace');
      await ErrorLoggerService.logError(
        component: 'InventoryRepository',
        operation: 'read',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'objectId': id},
      );
      rethrow;
    }
  }

  /// Update an existing inventory item
  /// Returns the number of affected rows
  Future<int> update(int id, Map<String, dynamic> updates) async {
    try {
      // First get the existing objet
      final existingObjet = await _databaseService.getObjet(id);
      if (existingObjet == null) {
        throw ArgumentError('Objet with id $id not found');
      }

      // Create updated objet with the provided updates
      final updatedObjet = Objet(
        id: existingObjet.id,
        idFoyer: existingObjet.idFoyer,
        nom: updates['nom'] ?? existingObjet.nom,
        categorie: updates['categorie'] ?? existingObjet.categorie,
        type: updates['type'] ?? existingObjet.type,
        dateAchat: updates['dateAchat'] ?? existingObjet.dateAchat,
        dureeViePrevJours: updates['dureeViePrevJours'] ?? existingObjet.dureeViePrevJours,
        dateRupturePrev: updates['dateRupturePrev'] ?? existingObjet.dateRupturePrev,
        quantiteInitiale: updates['quantiteInitiale'] ?? existingObjet.quantiteInitiale,
        quantiteRestante: updates['quantiteRestante'] ?? existingObjet.quantiteRestante,
        unite: updates['unite'] ?? existingObjet.unite,
        tailleConditionnement: updates['tailleConditionnement'] ?? existingObjet.tailleConditionnement,
        prixUnitaire: updates['prixUnitaire'] ?? existingObjet.prixUnitaire,
        methodePrevision: updates['methodePrevision'] ?? existingObjet.methodePrevision,
        frequenceAchatJours: updates['frequenceAchatJours'] ?? existingObjet.frequenceAchatJours,
        consommationJour: updates['consommationJour'] ?? existingObjet.consommationJour,
        seuilAlerteJours: updates['seuilAlerteJours'] ?? existingObjet.seuilAlerteJours,
        seuilAlerteQuantite: updates['seuilAlerteQuantite'] ?? existingObjet.seuilAlerteQuantite,
      );

      // Recalculate rupture date for consumables when updating
      final objetWithUpdatedRuptureDate = PredictionService.updateRuptureDate(updatedObjet);
      return await _databaseService.updateObjet(objetWithUpdatedRuptureDate);
    } catch (e, stackTrace) {
      print('Database error in InventoryRepository.update: $e');
      print('StackTrace: $stackTrace');
      await ErrorLoggerService.logError(
        component: 'InventoryRepository',
        operation: 'update',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'objectId': id},
      );
      rethrow;
    }
  }

  /// Direct update with Objet object (convenience method)
  /// Automatically recalculates rupture date for consumables
  Future<int> updateObjet(Objet objet) async {
    // Recalculate rupture date for consumables when updating
    final objetWithUpdatedRuptureDate = PredictionService.updateRuptureDate(objet);
    return await _databaseService.updateObjet(objetWithUpdatedRuptureDate);
  }

  /// Delete an inventory item
  /// Returns the number of affected rows
  Future<int> delete(int id) async {
    return await _databaseService.deleteObjet(id);
  }

  /// Get all inventory items for a foyer
  Future<List<Objet>> getAll(int idFoyer, {String? category}) async {
    if (category != null) {
      final type = category == 'consommable' ? TypeObjet.consommable : TypeObjet.durable;
      return await _databaseService.getObjets(idFoyer: idFoyer, type: type);
    }
    return await _databaseService.getObjets(idFoyer: idFoyer);
  }

  /// Get consumable inventory items for a foyer
  Future<List<Objet>> getConsommables(int idFoyer) async {
    return await _databaseService.getObjets(idFoyer: idFoyer, type: TypeObjet.consommable);
  }

  /// Get durable inventory items for a foyer
  Future<List<Objet>> getDurables(int idFoyer) async {
    return await _databaseService.getObjets(idFoyer: idFoyer, type: TypeObjet.durable);
  }

  /// Get items with low stock for alerts
  Future<List<Objet>> getLowStockItems(int idFoyer) async {
    final allItems = await _databaseService.getObjets(idFoyer: idFoyer);
    return allItems.where((objet) =>
        objet.quantiteRestante <= objet.seuilAlerteQuantite).toList();
  }

  /// Get items expiring soon
  Future<List<Objet>> getExpiringSoonItems(int idFoyer, {Duration warningPeriod = const Duration(days: 3)}) async {
    final allItems = await _databaseService.getObjets(idFoyer: idFoyer);
    final now = DateTime.now();
    final warningDate = now.add(warningPeriod);

    return allItems.where((objet) =>
        objet.dateRupturePrev != null &&
        objet.dateRupturePrev!.isBefore(warningDate)).toList();
  }

  /// Get total count of inventory items
  Future<int> getTotalCount(int idFoyer) async {
    return await _databaseService.getTotalObjetCount(idFoyer);
  }

  /// Get count of items expiring soon
  Future<int> getExpiringSoonCount(int idFoyer) async {
    return await _databaseService.getExpiringSoonObjetCount(idFoyer);
  }

  /// Helper method to detect database connection errors
  /// Used to determine if automatic recovery should be attempted
  static bool _isDatabaseConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('database is closed') ||
           errorString.contains('database_closed') ||
           errorString.contains('no such table') ||
           errorString.contains('sqlite_exception') ||
           errorString.contains('connection') && errorString.contains('lost');
  }
}

import '../models/objet.dart';
import '../services/database_service.dart';
import '../services/prediction_service.dart';
import '../services/error_logger_service.dart';
import '../services/budget_service.dart';

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
  final BudgetService _budgetService = BudgetService();

  InventoryRepository(this._databaseService);

  /// Create a new inventory item with automatic recovery
  /// Automatically calculates rupture date for consumables using PredictionService
  /// Returns the ID of the newly created item
  /// 
  /// Validates:
  /// - nom must not be empty
  /// - quantiteInitiale must be > 0
  /// - quantiteRestante must be >= 0
  Future<int> create(Objet objet) async {
    // Validation: nom must not be empty
    if (objet.nom.trim().isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    
    // Validation: quantiteInitiale must be > 0
    if (objet.quantiteInitiale <= 0) {
      throw ArgumentError('Initial quantity must be greater than 0');
    }
    
    // Validation: quantiteRestante must be >= 0
    if (objet.quantiteRestante < 0) {
      throw ArgumentError('Remaining quantity cannot be negative');
    }
    
    try {
      final objetWithRuptureDate = PredictionService.updateRuptureDate(objet);
      final id = await _databaseService.insertObjet(objetWithRuptureDate);
      
      // Only trigger budget alerts if prixUnitaire is set and > 0
      if (objetWithRuptureDate.prixUnitaire != null && 
          objetWithRuptureDate.prixUnitaire! > 0) {
        try {
          await _budgetService.checkBudgetAlertsAfterPurchase(
            objetWithRuptureDate.idFoyer.toString(),
            objetWithRuptureDate.categorie,
          );
        } catch (e, stackTrace) {
          await ErrorLoggerService.logError(
            component: 'InventoryRepository',
            operation: 'create.checkBudgetAlertsAfterPurchase',
            error: e,
            stackTrace: stackTrace,
            severity: ErrorSeverity.low,
          );
        }
      }
      return id;
    } catch (e, stackTrace) {
      print('Database error in InventoryRepository.create: $e');
      print('StackTrace: $stackTrace');

      if (_isDatabaseConnectionError(e)) {
        print('[InventoryRepository] Database connection error detected, attempting recovery...');
        try {
          final isValid = await _databaseService.isConnectionValid();
          if (!isValid) {
            await Future.delayed(const Duration(milliseconds: 200));
            final objetWithRuptureDate = PredictionService.updateRuptureDate(objet);
            final id = await _databaseService.insertObjet(objetWithRuptureDate);
            
            // Only trigger budget alerts if prixUnitaire is set and > 0
            if (objetWithRuptureDate.prixUnitaire != null && 
                objetWithRuptureDate.prixUnitaire! > 0) {
              try {
                await _budgetService.checkBudgetAlertsAfterPurchase(
                  objetWithRuptureDate.idFoyer.toString(),
                  objetWithRuptureDate.categorie,
                );
              } catch (e, stackTrace) {
                await ErrorLoggerService.logError(
                  component: 'InventoryRepository',
                  operation: 'create_recovery.checkBudgetAlertsAfterPurchase',
                  error: e,
                  stackTrace: stackTrace,
                  severity: ErrorSeverity.low,
                );
              }
            }
            return id;
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
      final existingObjet = await _databaseService.getObjet(id);
      if (existingObjet == null) {
        throw ArgumentError('Objet with id $id not found');
      }

      final updatedObjet = Objet(
        id: existingObjet.id,
        idFoyer: existingObjet.idFoyer,
        nom: updates['nom'] ?? existingObjet.nom,
        categorie: updates['categorie'] ?? existingObjet.categorie,
        type: updates['type'] ?? existingObjet.type,
        dateAchat: updates['dateAchat'] ?? existingObjet.dateAchat,
        dureeViePrevJours:
            updates['dureeViePrevJours'] ?? existingObjet.dureeViePrevJours,
        dateRupturePrev:
            updates['dateRupturePrev'] ?? existingObjet.dateRupturePrev,
        quantiteInitiale:
            updates['quantiteInitiale'] ?? existingObjet.quantiteInitiale,
        quantiteRestante:
            updates['quantiteRestante'] ?? existingObjet.quantiteRestante,
        unite: updates['unite'] ?? existingObjet.unite,
        tailleConditionnement:
            updates['tailleConditionnement'] ?? existingObjet.tailleConditionnement,
        prixUnitaire: updates['prixUnitaire'] ?? existingObjet.prixUnitaire,
        methodePrevision:
            updates['methodePrevision'] ?? existingObjet.methodePrevision,
        frequenceAchatJours:
            updates['frequenceAchatJours'] ?? existingObjet.frequenceAchatJours,
        consommationJour:
            updates['consommationJour'] ?? existingObjet.consommationJour,
      );

      final objetWithUpdatedRuptureDate =
          PredictionService.updateRuptureDate(updatedObjet);
      final result = await _databaseService.updateObjet(
        objetWithUpdatedRuptureDate,
      );

      // Check if prix_unitaire changed in updates
      final priceChanged = updates.containsKey('prixUnitaire') &&
          updates['prixUnitaire'] != existingObjet.prixUnitaire;
      
      final spendingChanged =
          (updates.containsKey('categorie') &&
              updates['categorie'] != existingObjet.categorie) ||
          priceChanged ||
          (updates.containsKey('quantiteInitiale') &&
              updates['quantiteInitiale'] != existingObjet.quantiteInitiale) ||
          (updates.containsKey('dateAchat') &&
              updates['dateAchat'] != existingObjet.dateAchat);

      // Only trigger if new price is set and > 0
      if (spendingChanged && 
          objetWithUpdatedRuptureDate.prixUnitaire != null &&
          objetWithUpdatedRuptureDate.prixUnitaire! > 0) {
        try {
          await _budgetService.checkBudgetAlertsAfterPurchase(
            objetWithUpdatedRuptureDate.idFoyer.toString(),
            objetWithUpdatedRuptureDate.categorie,
          );
        } catch (e, stackTrace) {
          await ErrorLoggerService.logError(
            component: 'InventoryRepository',
            operation: 'update.checkBudgetAlertsAfterPurchase',
            error: e,
            stackTrace: stackTrace,
            severity: ErrorSeverity.low,
          );
        }
      }

      return result;
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
    final objetWithUpdatedRuptureDate = PredictionService.updateRuptureDate(
      objet,
    );
    final result = await _databaseService.updateObjet(
      objetWithUpdatedRuptureDate,
    );
    
    // Only trigger if new price is set and > 0
    if (objetWithUpdatedRuptureDate.prixUnitaire != null &&
        objetWithUpdatedRuptureDate.prixUnitaire! > 0) {
      try {
        await _budgetService.checkBudgetAlertsAfterPurchase(
          objetWithUpdatedRuptureDate.idFoyer.toString(),
          objetWithUpdatedRuptureDate.categorie,
        );
      } catch (e, stackTrace) {
        await ErrorLoggerService.logError(
          component: 'InventoryRepository',
          operation: 'updateObjet.checkBudgetAlertsAfterPurchase',
          error: e,
          stackTrace: stackTrace,
          severity: ErrorSeverity.low,
        );
      }
    }
    return result;
  }

  /// Delete an inventory item
  /// Uses hard delete strategy: permanently removes the item from database
  /// Alertes linked to this item are automatically deleted via CASCADE (see db.dart schema)
  /// Returns the number of affected rows (0 if item not found, 1 if deleted)
  /// 
  /// Note: This is a hard delete. If soft delete is needed in the future,
  /// add an 'is_deleted' column and filter in all queries.
  Future<int> delete(int id) async {
    try {
      // Verify item exists before deletion
      final existingObjet = await _databaseService.getObjet(id);
      if (existingObjet == null) {
        // Item doesn't exist, return 0 (no rows affected)
        return 0;
      }
      
      // Perform hard delete
      // Note: Alertes are automatically deleted via ON DELETE CASCADE in schema
      // Budget calculations will exclude deleted items automatically (they won't be in queries)
      final deletedRows = await _databaseService.deleteObjet(id);
      
      return deletedRows;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'InventoryRepository',
        operation: 'delete',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'objectId': id},
      );
      rethrow;
    }
  }
  
  /// Alias for create() to match Task 1.4 naming convention
  /// Adds a new product to the inventory
  /// Returns the ID of the newly created product
  Future<int> addProduct(Objet product) async {
    return create(product);
  }
  
  /// Updates an existing product
  /// Returns true if update succeeded (at least 1 row affected), false otherwise
  /// 
  /// Validates:
  /// - Product ID must exist
  /// - nom must not be empty if provided
  /// - quantiteInitiale must be > 0 if provided
  /// - quantiteRestante must be >= 0 if provided
  Future<bool> updateProduct(Objet product) async {
    try {
      // Validation: ID must be provided
      if (product.id == null) {
        throw ArgumentError('Product ID is required for update');
      }
      
      // Validation: nom must not be empty
      if (product.nom.trim().isEmpty) {
        throw ArgumentError('Product name cannot be empty');
      }
      
      // Validation: quantiteInitiale must be > 0
      if (product.quantiteInitiale <= 0) {
        throw ArgumentError('Initial quantity must be greater than 0');
      }
      
      // Validation: quantiteRestante must be >= 0
      if (product.quantiteRestante < 0) {
        throw ArgumentError('Remaining quantity cannot be negative');
      }
      
      // Verify product exists before update
      final existingObjet = await _databaseService.getObjet(product.id!);
      if (existingObjet == null) {
        // Product doesn't exist, return false
        return false;
      }
      
      // Update with recalculated rupture date
      final objetWithUpdatedRuptureDate =
          PredictionService.updateRuptureDate(product);
      final rowsAffected = await _databaseService.updateObjet(
        objetWithUpdatedRuptureDate,
      );
      
      // Check if prix_unitaire changed
      final priceChanged = product.prixUnitaire != existingObjet.prixUnitaire;
      final spendingChanged = priceChanged ||
          product.categorie != existingObjet.categorie ||
          product.quantiteInitiale != existingObjet.quantiteInitiale ||
          product.dateAchat != existingObjet.dateAchat;
      
      // Trigger budget alerts if spending changed and price is set
      if (spendingChanged &&
          objetWithUpdatedRuptureDate.prixUnitaire != null &&
          objetWithUpdatedRuptureDate.prixUnitaire! > 0) {
        try {
          await _budgetService.checkBudgetAlertsAfterPurchase(
            objetWithUpdatedRuptureDate.idFoyer.toString(),
            objetWithUpdatedRuptureDate.categorie,
          );
        } catch (e, stackTrace) {
          await ErrorLoggerService.logError(
            component: 'InventoryRepository',
            operation: 'updateProduct.checkBudgetAlertsAfterPurchase',
            error: e,
            stackTrace: stackTrace,
            severity: ErrorSeverity.low,
          );
        }
      }
      
      // Return true if at least 1 row was affected, false otherwise
      return rowsAffected > 0;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'InventoryRepository',
        operation: 'updateProduct',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'productId': product.id},
      );
      rethrow;
    }
  }
  
  /// Alias for delete() to match Task 1.4 naming convention
  /// Deletes a product from the inventory
  /// Returns the number of affected rows (0 if not found, 1 if deleted)
  Future<int> deleteProduct(int id) async {
    return delete(id);
  }

  /// Get all inventory items for a foyer
  Future<List<Objet>> getAll(int idFoyer, {String? category}) async {
    if (category != null) {
      final type = category == 'consommable'
          ? TypeObjet.consommable
          : TypeObjet.durable;
      return await _databaseService.getObjets(idFoyer: idFoyer, type: type);
    }
    return await _databaseService.getObjets(idFoyer: idFoyer);
  }

  /// Get consumable inventory items for a foyer
  Future<List<Objet>> getConsommables(int idFoyer) async {
    return await _databaseService.getObjets(
      idFoyer: idFoyer,
      type: TypeObjet.consommable,
    );
  }

  /// Get durable inventory items for a foyer
  Future<List<Objet>> getDurables(int idFoyer) async {
    return await _databaseService.getObjets(
      idFoyer: idFoyer,
      type: TypeObjet.durable,
    );
  }

  /// Get items with low stock for alerts
  Future<List<Objet>> getLowStockItems(int idFoyer) async {
    final allItems = await _databaseService.getObjets(idFoyer: idFoyer);
    return allItems
        .where((objet) => objet.quantiteRestante <= objet.seuilAlerteQuantite)
        .toList();
  }

  /// Get items expiring soon
  Future<List<Objet>> getExpiringSoonItems(
    int idFoyer, {
    Duration warningPeriod = const Duration(days: 3),
  }) async {
    final allItems = await _databaseService.getObjets(idFoyer: idFoyer);
    final now = DateTime.now();
    final warningDate = now.add(warningPeriod);

    return allItems
        .where(
          (objet) =>
              objet.dateRupturePrev != null &&
              objet.dateRupturePrev!.isBefore(warningDate),
        )
        .toList();
  }

  /// Get total count of inventory items
  Future<String> getTotalCount(int idFoyer) async {
    final count = await _databaseService.getTotalObjetCount(idFoyer);
    return count.toString();
  }

  /// Get count of items expiring soon
  Future<String> getExpiringSoonCount(int idFoyer) async {
    final count = await _databaseService.getExpiringSoonObjetCount(idFoyer);
    return count.toString();
  }

  /// Search products using SQLite LIKE queries
  /// Searches in: nom, categorie, and room fields
  /// Returns up to 100 results (performance limit)
  /// 
  /// This method uses SQLite directly for optimal performance with large inventories.
  /// For better performance, ensure indexes exist on nom, categorie, and room columns.
  Future<List<Objet>> searchProducts(String query, {int? idFoyer}) async {
    if (query.trim().isEmpty) {
      // Empty query returns empty list
      return [];
    }
    
    try {
      return await _databaseService.searchObjets(
        query: query,
        idFoyer: idFoyer,
        limit: 100,
      );
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'InventoryRepository',
        operation: 'searchProducts',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'query': query,
          'idFoyer': idFoyer,
        },
      );
      rethrow;
    }
  }

  /// Helper method to detect database connection errors
  /// Used to determine if automatic recovery should be attempted
  static bool _isDatabaseConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('database is closed') ||
        errorString.contains('database_closed') ||
        errorString.contains('no such table') ||
        errorString.contains('sqlite_exception') ||
        (errorString.contains('connection') && errorString.contains('lost'));
  }
}

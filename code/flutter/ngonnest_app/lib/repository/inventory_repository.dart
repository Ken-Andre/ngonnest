import '../models/objet.dart';
import '../services/database_service.dart';
import '../services/prediction_service.dart';

/// Repository for Inventory (Objet) data operations
/// Implements the Repository pattern as a wrapper around DatabaseService
/// to comply with US-3.2 requirements for functional CRUD inventory
class InventoryRepository {
  final DatabaseService _databaseService;

  InventoryRepository(this._databaseService);

  /// Create a new inventory item
  /// Automatically calculates rupture date for consumables using PredictionService
  /// Returns the ID of the newly created item
  Future<int> create(Objet objet) async {
    // Calculate rupture date for consumables
    final objetWithRuptureDate = PredictionService.updateRuptureDate(objet);
    return await _databaseService.insertObjet(objetWithRuptureDate);
  }

  /// Read (get) an inventory item by ID
  Future<Objet?> read(int id) async {
    return await _databaseService.getObjet(id);
  }

  /// Update an existing inventory item
  /// Returns the number of affected rows
  Future<int> update(int id, Map<String, dynamic> updates) async {
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
}

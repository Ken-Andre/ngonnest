import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/objet.dart';
import 'auth_service.dart';
import 'console_logger.dart';
import 'database_service.dart';
import 'error_logger_service.dart';
import 'supabase_api_service.dart';

/// Service de synchronisation bidirectionnelle pour NgoNest
/// Gère les conflits et fusionne intelligemment les données locales/cloud
///
/// Stratégie de conflits:
/// - Local wins pour modifications utilisateur directes
/// - Cloud wins pour sync externes (partage familiaux)
/// - Merge intelligent basé sur timestamps et sources
class BidirectionalSyncService extends ChangeNotifier {
  static BidirectionalSyncService? _instance;
  late SupabaseClient _supabase;

  // États de sync bidirectionnelle
  bool _isBidirectionalSyncEnabled = false;
  DateTime? _lastBidirectionalSync;
  int _resolvedConflicts = 0;
  int _localWonConflicts = 0;
  int _cloudWonConflicts = 0;

  static BidirectionalSyncService get instance {
    _instance ??= BidirectionalSyncService._internal();
    return _instance!;
  }

  BidirectionalSyncService._internal() {
    _initializeSupabase();
    _setupRealtimeListener();
  }

  void _initializeSupabase() {
    _supabase = Supabase.instance.client;
  }

  void _setupRealtimeListener() {
    if (!_isBidirectionalSyncEnabled) return;

    // Écouter les changements en temps réel sur toutes les tables
    final tables = [
      SupabaseConfig.productsTable,
      SupabaseConfig.householdsTable,
      SupabaseConfig.purchasesTable,
      SupabaseConfig.budgetCategoriesTable,
    ];

    for (final table in tables) {
      _supabase.channel('$table-changes').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          _handleRealtimeUpdate(payload, ref: null);
        },
      ).subscribe();
    }

    ConsoleLogger.info('[BidirectionalSyncService] Real-time listeners initialized');
  }

  // Getters
  bool get isBidirectionalSyncEnabled => _isBidirectionalSyncEnabled;
  DateTime? get lastBidirectionalSync => _lastBidirectionalSync;
  int get resolvedConflicts => _resolvedConflicts;
  int get localWonConflicts => _localWonConflicts;
  int get cloudWonConflicts => _cloudWonConflicts;

  /// Activer la sync bidirectionnelle (nécessite authentification)
  Future<void> enableBidirectionalSync() async {
    if (!AuthService.instance.isAuthenticated) {
      throw Exception('Authentification requise pour la sync bidirectionnelle');
    }

    _isBidirectionalSyncEnabled = true;
    _setupRealtimeListener();
    await _performBidirectionalSync();

    ConsoleLogger.info('[BidirectionalSyncService] Bidirectional sync enabled');
    notifyListeners();
  }

  /// Désactiver la sync bidirectionnelle
  Future<void> disableBidirectionalSync() async {
    _isBidirectionalSyncEnabled = false;

    // Couper tous les listeners real-time
    final tables = [
      SupabaseConfig.productsTable,
      SupabaseConfig.householdsTable,
      SupabaseConfig.purchasesTable,
      SupabaseConfig.budgetCategoriesTable,
    ];

    for (final table in tables) {
      await _supabase.channel('$table-changes').unsubscribe();
    }

    ConsoleLogger.info('[BidirectionalSyncService] Bidirectional sync disabled');
    notifyListeners();
  }

  /// Synchronisation bidirectionnelle complète
  Future<bool> _performBidirectionalSync() async {
    if (!AuthService.instance.isAuthenticated || !_isBidirectionalSyncEnabled) {
      return false;
    }

    try {
      ConsoleLogger.info('[BidirectionalSyncService] Starting bidirectional sync');

      // 1. Récupérer les changements distants depuis dernière sync
      await _syncFromCloud();

      // 2. Envoyer les changements locaux vers le cloud
      await _syncChangesToCloud();

      // 3. Résoudre les conflits détectés
      await _resolveConflicts();

      _lastBidirectionalSync = DateTime.now();

      ConsoleLogger.success('[BidirectionalSyncService] Bidirectional sync completed');
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      ConsoleLogger.error('BidirectionalSyncService', '_performBidirectionalSync', e, stackTrace: stackTrace);

      await ErrorLoggerService.logError(
        component: 'BidirectionalSyncService',
        operation: '_performBidirectionalSync',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );

      return false;
    }
  }

  /// Sync depuis le cloud vers local (pull)
  Future<void> _syncFromCloud() async {
    if (!AuthService.instance.isAuthenticated) return;

    final userId = AuthService.instance.currentUser!.id;

    try {
      // Récupérer les changements depuis dernière sync pour cet utilisateur
      final since = _lastBidirectionalSync ?? DateTime.now().subtract(const Duration(days: 30));

      // Sync produits
      await _syncProductsFromCloud(userId, since);

      // Sync foyers
      await _syncHouseholdsFromCloud(userId, since);

      // Sync achats
      await _syncPurchasesFromCloud(userId, since);

      // Sync catégories budgétaire
      await _syncBudgetCategoriesFromCloud(userId, since);

      ConsoleLogger.info('[BidirectionalSyncService] Pull from cloud completed');
    } catch (e, stackTrace) {
      ConsoleLogger.error('BidirectionalSyncService', '_syncFromCloud', e, stackTrace: stackTrace);
      await ErrorLoggerService.logError(
        component: 'BidirectionalSyncService',
        operation: '_syncFromCloud',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'user_id': userId},
      );
    }
  }

  /// Sync des produits depuis le cloud
  Future<void> _syncProductsFromCloud(String userId, DateTime since) async {
    final cloudProducts = await SupabaseApiService.instance.getLatestChanges(
      entityType: 'objet',
      since: since,
    );

    final db = DatabaseService();

    for (final cloudProduct in cloudProducts) {
      try {
        final localProduct = await _getLocalProduct(cloudProduct['local_id']);

        if (localProduct == null) {
          // Nouveau produit du cloud
          await _insertCloudProductLocally(cloudProduct);
        } else {
          // Produit existant - résoudre conflit
          await _resolveProductConflict(localProduct, cloudProduct);
        }
      } catch (e, stackTrace) {
        ConsoleLogger.warning('[BidirectionalSyncService] Error syncing product ${cloudProduct['id']}: $e');
        await ErrorLoggerService.logError(
          component: 'BidirectionalSyncService',
          operation: '_syncProductsFromCloud',
          error: e,
          stackTrace: stackTrace,
          severity: ErrorSeverity.low,
          metadata: {'product_id': cloudProduct['id'], 'local_id': cloudProduct['local_id']},
        );
      }
    }
  }

  /// Sync des foyers depuis le cloud
  Future<void> _syncHouseholdsFromCloud(String userId, DateTime since) async {
    final cloudHouseholds = await SupabaseApiService.instance.getLatestChanges(
      entityType: 'foyer',
      since: since,
    );

    final db = DatabaseService();

    for (final cloudHousehold in cloudHouseholds) {
      try {
        final localHousehold = await _getLocalHousehold(cloudHousehold['local_id']);

        if (localHousehold == null) {
          await _insertCloudHouseholdLocally(cloudHousehold);
        } else {
          await _resolveHouseholdConflict(localHousehold, cloudHousehold);
        }
      } catch (e, stackTrace) {
        ConsoleLogger.warning('[BidirectionalSyncService] Error syncing household ${cloudHousehold['id']}: $e');
      }
    }
  }

  /// Sync des achats depuis le cloud
  Future<void> _syncPurchasesFromCloud(String userId, DateTime since) async {
    final cloudPurchases = await SupabaseApiService.instance.getLatestChanges(
      entityType: 'reachat_log',
      since: since,
    );

    final db = DatabaseService();

    for (final cloudPurchase in cloudPurchases) {
      try {
        final localPurchase = await _getLocalPurchase(cloudPurchase['local_id']);

        if (localPurchase == null) {
          await _insertCloudPurchaseLocally(cloudPurchase);
        } else {
          await _resolvePurchaseConflict(localPurchase, cloudPurchase);
        }
      } catch (e, stackTrace) {
        ConsoleLogger.warning('[BidirectionalSyncService] Error syncing purchase ${cloudPurchase['id']}: $e');
      }
    }
  }

  /// Sync des catégories budgétaire depuis le cloud
  Future<void> _syncBudgetCategoriesFromCloud(String userId, DateTime since) async {
    final cloudCategories = await SupabaseApiService.instance.getLatestChanges(
      entityType: 'budget_categories',
      since: since,
    );

    final db = DatabaseService();

    for (final cloudCategory in cloudCategories) {
      try {
        final localCategory = await _getLocalBudgetCategory(cloudCategory['local_id']);

        if (localCategory == null) {
          await _insertCloudBudgetCategoryLocally(cloudCategory);
        } else {
          await _resolveBudgetCategoryConflict(localCategory, cloudCategory);
        }
      } catch (e, stackTrace) {
        ConsoleLogger.warning('[BidirectionalSyncService] Error syncing budget category ${cloudCategory['id']}: $e');
      }
    }
  }

  /// Envoyer les changements locaux vers le cloud (push)
  Future<void> _syncChangesToCloud() async {
    // Cette partie est déjà gérée par le SyncService existant
    // Nous pourrions ajouter ici une vérification d'état au besoin
    ConsoleLogger.info('[BidirectionalSyncService] Push to cloud handled by standard sync');
  }

  /// Résoudre les conflits entre local et cloud
  Future<void> _resolveConflicts() async {
    // Les conflits sont résolus durant la sync from cloud
    // Cette méthode peut servir pour des rapports ou nettoyage
    ConsoleLogger.info(
      '[BidirectionalSyncService] Conflicts resolved: $_resolvedConflicts '
      '(Local: $_localWonConflicts, Cloud: $_cloudWonConflicts)'
    );
  }

  /// Configuration de priorité pour résolution de conflits
  ConflictResolution _getConflictResolutionStrategy(String entityType, String source) {
    // Produits modifiés directement par l'utilisateur: local wins
    if (entityType == 'objet' && source == 'direct_user_input') {
      return ConflictResolution.localWins;
    }

    // Données partagées familial: cloud wins pour cohérence
    if (entityType == 'foyer' || entityType == 'budget_categories') {
      return ConflictResolution.cloudWins;
    }

    // Par défaut: last modified wins
    return ConflictResolution.lastModifiedWins;
  }

  /// Gestionnaire pour les updates real-time
  void _handleRealtimeUpdate(dynamic payload, {required String? ref}) {
    if (!_isBidirectionalSyncEnabled) return;

    try {
      final eventType = payload['eventType'] as String;
      final table = payload['table'] as String;
      final newRecord = payload['new'] as Map<String, dynamic>?;
      final oldRecord = payload['old'] as Map<String, dynamic>?;

      ConsoleLogger.info(
        '[BidirectionalSyncService] Real-time $eventType on $table: ${newRecord?['id']}'
      );

      // Traiter selon le type d'événement et table
      switch (table) {
        case SupabaseConfig.productsTable:
          _handleProductRealtimeUpdate(eventType, newRecord, oldRecord);
          break;
        case SupabaseConfig.householdsTable:
          _handleHouseholdRealtimeUpdate(eventType, newRecord, oldRecord);
          break;
        case SupabaseConfig.purchasesTable:
          _handlePurchaseRealtimeUpdate(eventType, newRecord, oldRecord);
          break;
        case SupabaseConfig.budgetCategoriesTable:
          _handleBudgetCategoryRealtimeUpdate(eventType, newRecord, oldRecord);
          break;
      }
    } catch (e, stackTrace) {
      ConsoleLogger.error('BidirectionalSyncService', '_handleRealtimeUpdate', e, stackTrace: stackTrace);
    }
  }

  void _handleProductRealtimeUpdate(String eventType, Map<String, dynamic>? newRecord, Map<String, dynamic>? oldRecord) {
    // Implémenter les updates real-time pour les produits
    // Par exemple: notifier l'UI de changements, ou trigger sync sélective
  }

  void _handleHouseholdRealtimeUpdate(String eventType, Map<String, dynamic>? newRecord, Map<String, dynamic>? oldRecord) {
    // Implémenter pour les foyers
  }

  void _handlePurchaseRealtimeUpdate(String eventType, Map<String, dynamic>? newRecord, Map<String, dynamic>? oldRecord) {
    // Implémenter pour les achats
  }

  void _handleBudgetCategoryRealtimeUpdate(String eventType, Map<String, dynamic>? newRecord, Map<String, dynamic>? oldRecord) {
    // Implémenter pour les catégories budgétaires
  }

  // Méthodes helper pour récupérer les données locales
  Future<Map<String, dynamic>?> _getLocalProduct(int localId) async {
    final response = await _supabase.from('objet').select().eq('id', localId);
    return response.isNotEmpty ? response.first : null;
  }

  Future<Map<String, dynamic>?> _getLocalHousehold(int localId) async {
    final response = await _supabase.from('foyer').select().eq('id', localId);
    return response.isNotEmpty ? response.first : null;
  }

  Future<Map<String, dynamic>?> _getLocalPurchase(int localId) async {
    final response =
        await _supabase.from('reachat_log').select().eq('id', localId);
    return response.isNotEmpty ? response.first : null;
  }

  Future<Map<String, dynamic>?> _getLocalBudgetCategory(int localId) async {
    final response =
        await _supabase.from('budget_categories').select().eq('id', localId);
    return response.isNotEmpty ? response.first : null;
  }

  // Méthodes helper pour insérer depuis le cloud
  Future<void> _insertCloudProductLocally(Map<String, dynamic> cloudProduct) async {
    // Adapter le format cloud vers local
    final localData = _convertCloudProductToLocal(cloudProduct);
    await _supabase.from('objet').insert(localData);
  }

  Future<void> _insertCloudHouseholdLocally(Map<String, dynamic> cloudHousehold) async {
    final localData = _convertCloudHouseholdToLocal(cloudHousehold);
    await _supabase.from('foyer').insert(localData);
  }

  Future<void> _insertCloudPurchaseLocally(Map<String, dynamic> cloudPurchase) async {
    final localData = _convertCloudPurchaseToLocal(cloudPurchase);
    await _supabase.from('reachat_log').insert(localData);
  }

  Future<void> _insertCloudBudgetCategoryLocally(Map<String, dynamic> cloudCategory) async {
    final localData = _convertCloudBudgetCategoryToLocal(cloudCategory);
    await _supabase.from('budget_categories').insert(localData);
  }

  // Méthodes de résolution de conflits
  Future<void> _resolveProductConflict(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
    final conflictResolution = _getConflictResolutionStrategy('objet', local['source'] ?? 'unknown');

    switch (conflictResolution) {
      case ConflictResolution.localWins:
        // Ne rien faire, local reste prioritaire
        _localWonConflicts++;
        break;
      case ConflictResolution.cloudWins:
        // Mettre à jour local avec les données cloud
        final localData = _convertCloudProductToLocal(cloud);
        await _supabase.from('objet').update(localData).eq('id', local['id']);
        _cloudWonConflicts++;
        break;
      case ConflictResolution.lastModifiedWins:
        // Comparer les dates de modification
        final localModified = local['date_modification'] != null
            ? DateTime.parse(local['date_modification'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        final cloudModified = cloud['synced_at'] != null
            ? DateTime.parse(cloud['synced_at'])
            : DateTime.fromMillisecondsSinceEpoch(0);

        if (cloudModified.isAfter(localModified)) {
          final localData = _convertCloudProductToLocal(cloud);
          await _supabase.from('objet').update(localData).eq('id', local['id']);
          _cloudWonConflicts++;
        } else {
          _localWonConflicts++;
        }
        break;
    }

    _resolvedConflicts++;
  }

  Future<void> _resolveHouseholdConflict(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
    final conflictResolution = _getConflictResolutionStrategy('foyer', 'shared');

    // Même logique que pour les produits
    switch (conflictResolution) {
      case ConflictResolution.localWins:
        _localWonConflicts++;
        break;
      case ConflictResolution.cloudWins:
        final localData = _convertCloudHouseholdToLocal(cloud);
        await _supabase.from('foyer').update(localData).eq('id', local['id']);
        _cloudWonConflicts++;
        break;
      case ConflictResolution.lastModifiedWins:
        final cloudDate = DateTime.parse(cloud['synced_at'] ?? cloud['updated_at']);
        final localDate = DateTime.parse(local['updated_at'] ?? '2023-01-01T00:00:00Z');

        if (cloudDate.isAfter(localDate)) {
          final localData = _convertCloudHouseholdToLocal(cloud);
          await _supabase.from('foyer').update(localData).eq('id', local['id']);
          _cloudWonConflicts++;
        } else {
          _localWonConflicts++;
        }
        break;
    }

    _resolvedConflicts++;
  }

  Future<void> _resolvePurchaseConflict(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
    // Pour les achats, ajouter simplement si pas existant (pas vraiment de conflit)
    _localWonConflicts++;
    _resolvedConflicts++;
  }

  Future<void> _resolveBudgetCategoryConflict(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
    final conflictResolution = _getConflictResolutionStrategy('budget_categories', 'shared');

    switch (conflictResolution) {
      case ConflictResolution.localWins:
        _localWonConflicts++;
        break;
      case ConflictResolution.cloudWins:
        final localData = _convertCloudBudgetCategoryToLocal(cloud);
        await _supabase
            .from('budget_categories')
            .update(localData)
            .eq('id', local['id']);
        _cloudWonConflicts++;
        break;
      case ConflictResolution.lastModifiedWins:
        final cloudDate = DateTime.parse(cloud['updated_at'] ?? cloud['synced_at']);
        final localDate = DateTime.parse(local['updated_at'] ?? '2023-01-01T00:00:00Z');

        if (cloudDate.isAfter(localDate)) {
          final localData = _convertCloudBudgetCategoryToLocal(cloud);
          await _supabase
              .from('budget_categories')
              .update(localData)
              .eq('id', local['id']);
          _cloudWonConflicts++;
        } else {
          _localWonConflicts++;
        }
        break;
    }

    _resolvedConflicts++;
  }

  // Méthodes de conversion cloud -> local
  Map<String, dynamic> _convertCloudProductToLocal(Map<String, dynamic> cloud) {
    return {
      'id': cloud['local_id'],
      'id_foyer': cloud['household_id'],
      'nom': cloud['name'],
      'categorie': cloud['category'],
      'type': cloud['type'],
      'date_achat': cloud['purchase_date'],
      'duree_vie_prev_jours': cloud['predicted_lifespan_days'],
      'date_rupture_prev': cloud['predicted_depletion_date'],
      'quantite_initiale': cloud['initial_quantity'],
      'quantite_restante': cloud['remaining_quantity'],
      'unite': cloud['unit'],
      'taille_conditionnement': cloud['package_size'],
      'prix_unitaire': cloud['unit_price'],
      'methode_prevision': cloud['prediction_method'],
      'frequence_achat_jours': cloud['purchase_frequency_days'],
      'consommation_jour': cloud['daily_consumption'],
      'seuil_alerte_jours': cloud['alert_threshold_days'] ?? 3,
      'seuil_alerte_quantite': cloud['alert_threshold_quantity'] ?? 1.0,
      'commentaires': cloud['comments'],
      'room': cloud['room'],
      'date_modification': cloud['synced_at'],
    };
  }

  Map<String, dynamic> _convertCloudHouseholdToLocal(Map<String, dynamic> cloud) {
    return {
      'id': cloud['local_id'],
      'nb_personnes': cloud['person_count'],
      'nb_pieces': cloud['room_count'],
      'type_logement': cloud['housing_type'],
      'langue': cloud['language'],
      'budget_mensuel_estime': cloud['estimated_budget'],
    };
  }

  Map<String, dynamic> _convertCloudPurchaseToLocal(Map<String, dynamic> cloud) {
    return {
      'id': cloud['local_id'],
      'id_objet': cloud['product_local_id'],
      'date': cloud['date'],
      'quantite': cloud['quantity'],
      'prix_total': cloud['total_price'],
    };
  }

  Map<String, dynamic> _convertCloudBudgetCategoryToLocal(Map<String, dynamic> cloud) {
    return {
      'id': cloud['local_id'],
      'name': cloud['name'],
      'limit_amount': cloud['limit_amount'],
      'spent_amount': cloud['spent_amount'],
      'month': cloud['month'],
      'created_at': cloud['created_at'],
      'updated_at': cloud['updated_at'],
    };
  }

  /// Statistiques de sync bidirectionnelle
  Map<String, dynamic> getStats() {
    return {
      'is_enabled': _isBidirectionalSyncEnabled,
      'last_sync': _lastBidirectionalSync?.toIso8601String(),
      'resolved_conflicts': _resolvedConflicts,
      'local_won': _localWonConflicts,
      'cloud_won': _cloudWonConflicts,
      'success_rate': _resolvedConflicts > 0
          ? (_localWonConflicts + _cloudWonConflicts) / _resolvedConflicts
          : 1.0,
    };
  }

  /// Réinitialiser les statistiques
  void resetStats() {
    _resolvedConflicts = 0;
    _localWonConflicts = 0;
    _cloudWonConflicts = 0;
    notifyListeners();
  }
}

/// Stratégies de résolution de conflits
enum ConflictResolution {
  localWins,     // Changements locaux prioritaires
  cloudWins,     // Changements cloud prioritaires
  lastModifiedWins,  // Dernière modification gagne
}

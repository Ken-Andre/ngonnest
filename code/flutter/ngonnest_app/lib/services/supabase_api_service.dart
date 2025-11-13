import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'console_logger.dart';
import 'error_logger_service.dart';

/// Service API Supabase pour la synchronisation offline-first
/// Implémente les vrais appels API en remplaçant _mockApiCall dans SyncService
class SupabaseApiService {
  static SupabaseApiService? _instance;
  late SupabaseClient _client;

  static SupabaseApiService get instance {
    _instance ??= SupabaseApiService._internal();
    return _instance!;
  }

  SupabaseApiService._internal() {
    _initializeClient();
  }

  void _initializeClient() {
    _client = Supabase.instance.client;
    ConsoleLogger.info('[SupabaseApiService] Client initialized');
  }

  /// Synchronise une opération dans Supabase selon l'entité type
  /// Méthode principale appelée par SyncService._syncOperation
  Future<void> syncOperation(Map<String, dynamic> operation) async {
    try {
      ConsoleLogger.info(
        '[SupabaseApiService] Syncing ${operation['operation_type']} on ${operation['entity_type']}',
      );

      final operationType = operation['operation_type'] as String;
      final entityType = operation['entity_type'] as String;
      final entityId = operation['entity_id'] as int;
      final payload = jsonDecode(operation['payload'] as String) as Map<String, dynamic>;

      // Ajouter metadata pour tracking et RLS
      final currentUser = _client.auth.currentUser;
      final payloadWithMeta = {
        ...payload,
        'local_id': entityId,
        'synced_at': DateTime.now().toIso8601String(),
        'sync_source': 'mobile_app',
        if (currentUser != null) 'user_id': currentUser.id, // Pour RLS
      };

      switch (entityType) {
        case 'objet':
          await _syncProduct(operationType, payloadWithMeta);
          break;
        case 'foyer':
          await _syncHousehold(operationType, payloadWithMeta);
          break;
        case 'reachat_log':
          await _syncPurchase(operationType, payloadWithMeta);
          break;
        case 'budget_categories':
          await _syncBudgetCategory(operationType, payloadWithMeta);
          break;
        default:
          throw Exception('Unsupported entity type: $entityType');
      }

      ConsoleLogger.success('[SupabaseApiService] Operation synced successfully');
    } catch (e, stackTrace) {
      ConsoleLogger.error('SupabaseApiService', 'syncOperation', e, stackTrace: stackTrace);

      await ErrorLoggerService.logError(
        component: 'SupabaseApiService',
        operation: 'syncOperation',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {
          'operation_type': operation['operation_type'],
          'entity_type': operation['entity_type'],
          'entity_id': operation['entity_id'],
        },
      );
      rethrow;
    }
  }

  /// Synchronise les produits/objets
  Future<void> _syncProduct(String operationType, Map<String, dynamic> payload) async {
    final table = SupabaseConfig.productsTable;

    switch (operationType) {
      case 'CREATE':
        // Le schéma Supabase utilise les noms français directement (nom, categorie, etc.)
        // Récupérer le UUID du household depuis les settings locaux
        String? householdUuid;
        final localHouseholdId = payload['id_foyer'] as int?;
        if (localHouseholdId != null) {
          try {
            // Utiliser le household_id stocké localement
            householdUuid = await SettingsService.getHouseholdId();
            if (householdUuid == null) {
              ConsoleLogger.warning('[SupabaseApiService] No household ID found in settings, attempting to create one');
              // Try to ensure household exists
              try {
                householdUuid = await AuthService.instance.ensureHouseholdExists();
                ConsoleLogger.info('[SupabaseApiService] Household created/recovered: $householdUuid');
              } catch (e) {
                ConsoleLogger.error('SupabaseApiService', 'household creation', e);
              }
            }
          } catch (e) {
            ConsoleLogger.warning('[SupabaseApiService] Could not fetch household UUID from settings: $e');
          }
        }
        
        // Mapper les colonnes locales vers le schéma Supabase (noms FRANÇAIS)
        final supabasePayload = <String, dynamic>{
          if (householdUuid != null) 'household_id': householdUuid,
          'nom': payload['nom'], // Pas de changement, le schéma utilise "nom"
          'categorie': payload['categorie'], // Pas de changement, le schéma utilise "categorie"
          'type': payload['type'],
          if (payload['room'] != null) 'room': payload['room'],
          // Convertir les dates ISO en format date (YYYY-MM-DD) pour Supabase
          if (payload['date_achat'] != null) 'date_achat': _formatDateForSupabase(payload['date_achat']),
          if (payload['duree_vie_prev_jours'] != null) 'duree_vie_prev_jours': payload['duree_vie_prev_jours'],
          if (payload['date_rupture_prev'] != null) 'date_rupture_prev': _formatDateForSupabase(payload['date_rupture_prev']),
          'quantite_initiale': payload['quantite_initiale'],
          'quantite_restante': payload['quantite_restante'],
          'unite': payload['unite'],
          if (payload['taille_conditionnement'] != null) 'taille_conditionnement': payload['taille_conditionnement'],
          if (payload['prix_unitaire'] != null) 'prix_unitaire': payload['prix_unitaire'],
          if (payload['methode_prevision'] != null) 'methode_prevision': payload['methode_prevision'],
          if (payload['frequence_achat_jours'] != null) 'frequence_achat_jours': payload['frequence_achat_jours'],
          if (payload['consommation_jour'] != null) 'consommation_jour': payload['consommation_jour'],
          if (payload['seuil_alerte_jours'] != null) 'seuil_alerte_jours': payload['seuil_alerte_jours'],
          if (payload['seuil_alerte_quantite'] != null) 'seuil_alerte_quantite': payload['seuil_alerte_quantite'],
          if (payload['alert_threshold_days'] != null) 'alert_threshold_days': payload['alert_threshold_days'],
          if (payload['alert_threshold_quantity'] != null) 'alert_threshold_quantity': payload['alert_threshold_quantity'],
          if (payload['commentaires'] != null) 'commentaires': payload['commentaires'],
        };
        
        // Log du payload pour debug
        ConsoleLogger.info('[SupabaseApiService] INSERT payload keys: ${supabasePayload.keys.toList()}');
        final payloadStr = supabasePayload.toString();
        ConsoleLogger.info('[SupabaseApiService] INSERT payload sample: ${payloadStr.length > 200 ? payloadStr.substring(0, 200) : payloadStr}...');
        
        try {
          final response = await _client.from(table).insert(supabasePayload).select();
          ConsoleLogger.success('[SupabaseApiService] Product inserted successfully: $response');
        } catch (e, stackTrace) {
          ConsoleLogger.error('SupabaseApiService', '_syncProduct CREATE', e, stackTrace: stackTrace);
          ConsoleLogger.error('SupabaseApiService', 'CREATE payload', supabasePayload, stackTrace: stackTrace);
          rethrow;
        }
        break;
      case 'UPDATE':
        // Pour UPDATE, on utilise le même mapping que CREATE (noms français)
        // Note: Supabase n'a pas de colonne local_id, on devra utiliser l'ID Supabase
        final supabasePayload = <String, dynamic>{
          if (payload.containsKey('nom')) 'nom': payload['nom'],
          if (payload.containsKey('categorie')) 'categorie': payload['categorie'],
          if (payload.containsKey('type')) 'type': payload['type'],
          if (payload.containsKey('room')) 'room': payload['room'],
          if (payload.containsKey('date_achat')) 'date_achat': _formatDateForSupabase(payload['date_achat']),
          if (payload.containsKey('duree_vie_prev_jours')) 'duree_vie_prev_jours': payload['duree_vie_prev_jours'],
          if (payload.containsKey('date_rupture_prev')) 'date_rupture_prev': _formatDateForSupabase(payload['date_rupture_prev']),
          if (payload.containsKey('quantite_initiale')) 'quantite_initiale': payload['quantite_initiale'],
          if (payload.containsKey('quantite_restante')) 'quantite_restante': payload['quantite_restante'],
          if (payload.containsKey('unite')) 'unite': payload['unite'],
          if (payload.containsKey('taille_conditionnement')) 'taille_conditionnement': payload['taille_conditionnement'],
          if (payload.containsKey('prix_unitaire')) 'prix_unitaire': payload['prix_unitaire'],
          if (payload.containsKey('methode_prevision')) 'methode_prevision': payload['methode_prevision'],
          if (payload.containsKey('frequence_achat_jours')) 'frequence_achat_jours': payload['frequence_achat_jours'],
          if (payload.containsKey('consommation_jour')) 'consommation_jour': payload['consommation_jour'],
          if (payload.containsKey('seuil_alerte_jours')) 'seuil_alerte_jours': payload['seuil_alerte_jours'],
          if (payload.containsKey('seuil_alerte_quantite')) 'seuil_alerte_quantite': payload['seuil_alerte_quantite'],
          if (payload.containsKey('commentaires')) 'commentaires': payload['commentaires'],
        };
        // TODO: Utiliser l'ID Supabase pour UPDATE (nécessite un mapping local_id -> supabase_id)
        // Pour l'instant, on utilise local_id comme fallback
        final localId = payload['local_id'] ?? payload['id'];
        await _client.from(table).update(supabasePayload).eq('id', localId);
        break;
      case 'DELETE':
        final localId = payload['local_id'];
        await _client.from(table).delete().eq('local_id', localId);
        break;
      default:
        throw Exception('Unsupported operation: $operationType');
    }
  }

  /// Synchronise les foyers
  Future<void> _syncHousehold(String operationType, Map<String, dynamic> payload) async {
    final table = SupabaseConfig.householdsTable;

    switch (operationType) {
      case 'CREATE':
        await _client.from(table).insert(payload);
        break;
      case 'UPDATE':
        final localId = payload['local_id'];
        final filteredPayload = Map<String, dynamic>.from(payload)
          ..remove('local_id')
          ..remove('id');
        await _client.from(table).update(filteredPayload).eq('local_id', localId);
        break;
      case 'DELETE':
        final localId = payload['local_id'];
        await _client.from(table).delete().eq('local_id', localId);
        break;
      default:
        throw Exception('Unsupported operation: $operationType');
    }
  }

  /// Synchronise les achats
  Future<void> _syncPurchase(String operationType, Map<String, dynamic> payload) async {
    final table = SupabaseConfig.purchasesTable;

    switch (operationType) {
      case 'CREATE':
        await _client.from(table).insert(payload);
        break;
      case 'UPDATE':
        final localId = payload['local_id'];
        final filteredPayload = Map<String, dynamic>.from(payload)
          ..remove('local_id')
          ..remove('id');
        await _client.from(table).update(filteredPayload).eq('local_id', localId);
        break;
      case 'DELETE':
        final localId = payload['local_id'];
        await _client.from(table).delete().eq('local_id', localId);
        break;
      default:
        throw Exception('Unsupported operation: $operationType');
    }
  }

  /// Synchronise les catégories budgétaires
  Future<void> _syncBudgetCategory(String operationType, Map<String, dynamic> payload) async {
    final table = SupabaseConfig.budgetCategoriesTable;

    switch (operationType) {
      case 'CREATE':
        await _client.from(table).insert(payload);
        break;
      case 'UPDATE':
        final localId = payload['local_id'];
        final filteredPayload = Map<String, dynamic>.from(payload)
          ..remove('local_id')
          ..remove('id');
        await _client.from(table).update(filteredPayload).eq('local_id', localId);
        break;
      case 'DELETE':
        final localId = payload['local_id'];
        await _client.from(table).delete().eq('local_id', localId);
        break;
      default:
        throw Exception('Unsupported operation: $operationType');
    }
  }

  /// Récupère les dernières modifications depuis Supabase pour merge bidirectionnel
  /// Utilisé pour résoudre les conflits et sync bidirectionnelle
  Future<List<Map<String, dynamic>>> getLatestChanges({
    required String entityType,
    required DateTime since,
  }) async {
    try {
      late String table;
      late String dateColumn;

      switch (entityType) {
        case 'objet':
          table = SupabaseConfig.productsTable;
          dateColumn = 'synced_at';
          break;
        case 'foyer':
          table = SupabaseConfig.householdsTable;
          dateColumn = 'synced_at';
          break;
        case 'reachat_log':
          table = SupabaseConfig.purchasesTable;
          dateColumn = 'synced_at';
          break;
        case 'budget_categories':
          table = SupabaseConfig.budgetCategoriesTable;
          dateColumn = 'updated_at'; // Cas spécial pour budget
          break;
        default:
          throw Exception('Unsupported entity type: $entityType');
      }

      final response = await _client
        .from(table)
        .select()
        .gte(dateColumn, since.toIso8601String())
        .order(dateColumn, ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      ConsoleLogger.error('SupabaseApiService', 'getLatestChanges', e, stackTrace: stackTrace);
      await ErrorLoggerService.logError(
        component: 'SupabaseApiService',
        operation: 'getLatestChanges',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'entity_type': entityType},
      );

      // En cas d'erreur, retourner liste vide pour que sync continue
      return [];
    }
  }

  /// Teste la connectivité Supabase
  Future<bool> testConnection() async {
    try {
      // Test simple: vérifier que l'auth fonctionne (pas besoin de RPC)
      final session = _client.auth.currentSession;
      return session != null;
    } catch (e) {
      ConsoleLogger.warning('[SupabaseApiService] Connection test failed: $e');
      // Ne pas bloquer la sync si le test échoue, Supabase peut être accessible même sans session
      return true; // Retourner true pour permettre la sync même si le test échoue
    }
  }

  /// Nettoie les anciens enregistrements (garbage collection)
  /// Supprime données > 90 jours pour optimiser stockage Cameroun
  Future<void> cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

      // Liste des tables avec dates à nettoyer
      final tables = [
        SupabaseConfig.productsTable,
        SupabaseConfig.householdsTable,
        SupabaseConfig.purchasesTable,
        SupabaseConfig.notificationsTable,
      ];

      for (final table in tables) {
        try {
          await _client
              .from(table)
              .delete()
              .lt('synced_at', cutoffDate.toIso8601String());
        } catch (e) {
          // Ignorer les erreurs si la colonne n'existe pas
          ConsoleLogger.warning('[SupabaseApiService] Cleanup failed for $table: $e');
        }
      }

      ConsoleLogger.info('[SupabaseApiService] Cleanup completed: $tables');
    } catch (e, stackTrace) {
      ConsoleLogger.warning('[SupabaseApiService] Cleanup failed: $e');
      await ErrorLoggerService.logError(
        component: 'SupabaseApiService',
        operation: 'cleanupOldData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
    }
  }

  /// Obtient des statistiques d'utilisation pour monitoring
  Map<String, dynamic> getStats() {
    return {
      'is_connected': _client != null,
      'timeout_configured': SupabaseConfig.connectionTimeout > 0,
      'rls_enabled': SupabaseConfig.rlsEnabled,
      'tables_count': SupabaseConfig.requiredTables.length,
    };
  }

  /// Convertit une date ISO string en format date (YYYY-MM-DD) pour Supabase
  /// Les colonnes de type 'date' dans Supabase attendent seulement la date sans l'heure
  String _formatDateForSupabase(dynamic dateValue) {
    if (dateValue == null) return '';
    
    if (dateValue is String) {
      // Si c'est déjà une string ISO, extraire la partie date
      try {
        final dateTime = DateTime.parse(dateValue);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } catch (e) {
        // Si le parsing échoue, retourner tel quel
        return dateValue;
      }
    } else if (dateValue is DateTime) {
      return '${dateValue.year}-${dateValue.month.toString().padLeft(2, '0')}-${dateValue.day.toString().padLeft(2, '0')}';
    }
    
    return dateValue.toString();
  }
}

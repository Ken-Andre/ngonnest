import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
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

      // Ajouter metadata pour tracking
      final payloadWithMeta = {
        ...payload,
        'local_id': entityId,
        'synced_at': DateTime.now().toIso8601String(),
        'sync_source': 'mobile_app',
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
        await _client.from(table).insert(payload);
        break;
      case 'UPDATE':
        final localId = payload['local_id'];
        final filteredPayload = Map<String, dynamic>.from(payload)
          ..remove('local_id')
          ..remove('id'); // Éviter de modifier le local_id en remote_id
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
      final response = await _client.rpc('SELECT 1');
      return response != null;
    } catch (e) {
      ConsoleLogger.warning('[SupabaseApiService] Connection test failed: $e');
      return false;
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
        await _client
          .from(table)
          .delete()
          .lt('synced_at', cutoffDate.toIso8601String());
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
}

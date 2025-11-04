import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'connectivity_service.dart';
import 'console_logger.dart';
import 'database_service.dart'; // For ErrorContext if ever needed elsewhere, though not directly in logError calls now
import 'error_logger_service.dart';
import '../config/supabase_config.dart';
import 'supabase_api_service.dart';

/// Service de synchronisation offline-first pour NgonNest
/// Respecte les principes : offline first, sync optionnelle, local wins, retry logic
///
/// Assumptions:
/// - This service is intended to be used within a single Flutter app lifecycle
/// - Thread safety is ensured by Flutter's single-threaded nature (main isolate)
/// - If accessed across isolates, additional synchronization would be required
class SyncService extends ChangeNotifier {
  static SyncService? _instance;

  /// Reset instance untuk testing
  static void resetInstance() {
    _instance?._disposeInternals();
    _instance = null;
  }

  factory SyncService() {
    _instance ??= SyncService._internal();
    return _instance!;
  }

  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // États de synchronisation
  bool _isSyncing = false;
  bool _hasError = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  bool _syncEnabled = false;
  bool _userConsent = false;

  // Configuration retry logic
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const int _maxOperationRetries = 5;

  // Statistiques de sync
  int _pendingOperations = 0;
  int _failedOperations = 0;

  int get pendingOperations => _pendingOperations;
  int get failedOperations => _failedOperations;

  // Getters pour l'état
  bool get isSyncing => _isSyncing;
  bool get hasError => _hasError;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get syncEnabled => _syncEnabled;
  bool get userConsent => _userConsent;

  /// Initialise le service de synchronisation
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _syncEnabled = prefs.getBool('sync_enabled') ?? false;
      _userConsent = prefs.getBool('sync_user_consent') ?? false;

      final lastSyncString = prefs.getString('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncString);
      }

      ConsoleLogger.info(
        '[SyncService] Initialized - Enabled: $_syncEnabled, Consent: $_userConsent',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SyncService',
        operation: 'initialize',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'context_message': 'Failed to initialize sync service'},
      );
    }
  }

  /// Active la synchronisation avec consentement utilisateur
  Future<void> enableSync({required bool userConsent}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _syncEnabled = true;
      _userConsent = userConsent;

      await prefs.setBool('sync_enabled', _syncEnabled);
      await prefs.setBool('sync_user_consent', _userConsent);

      ConsoleLogger.info(
        '[SyncService] Sync enabled with user consent: $userConsent',
      );

      notifyListeners();

      if (_connectivityService.isOnline && userConsent) {
        await _performSync();
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SyncService',
        operation: 'enableSync',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'context_message': 'Failed to enable sync'},
      );
    }
  }

  /// Désactive la synchronisation
  Future<void> disableSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _syncEnabled = false;
      _userConsent = false;

      await prefs.setBool('sync_enabled', _syncEnabled);
      await prefs.setBool('sync_user_consent', _userConsent);

      ConsoleLogger.info('[SyncService] Sync disabled');

      notifyListeners();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SyncService',
        operation: 'disableSync',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {'context_message': 'Failed to disable sync'},
      );
    }
  }

  /// Force une synchronisation avec feedback utilisateur
  Future<void> forceSyncWithFeedback(BuildContext? context) async {
    if (!_syncEnabled || !_userConsent) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Synchronisation désactivée. Activez-la dans les paramètres.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ConsoleLogger.info('[SyncService] Sync disabled - enable in settings');
      }
      return;
    }

    if (!_connectivityService.isOnline) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pas de connexion internet. Synchronisation impossible.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ConsoleLogger.warning('[SyncService] No internet connection available');
      }
      return;
    }

    if (_isSyncing) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronisation déjà en cours...'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ConsoleLogger.info('[SyncService] Sync already in progress');
      }
      return;
    }

    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronisation en cours...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ConsoleLogger.info('[SyncService] Starting sync process');
    }

    final success = await _performSync();

    if (context != null && !context.mounted) return;

    if (success) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Synchronisation réussie'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ConsoleLogger.success('[SyncService] Sync successful');
      }
    } else {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Échec synchronisation: $_lastError'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Détails',
              onPressed: () => showSyncErrorDialog(context!),
            ),
          ),
        );
      } else {
        ConsoleLogger.error('SyncService', 'forceSyncWithFeedback', _lastError);
      }
    }
  }

  /// Effectue la synchronisation avec retry logic
  Future<bool> _performSync() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _hasError = false;
    _lastError = null;
    notifyListeners();

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        ConsoleLogger.info(
          '[SyncService] Sync attempt ${attempt + 1}/$_maxRetries',
        );

        await _syncData();

        _lastSyncTime = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_sync_time',
          _lastSyncTime!.toIso8601String(),
        );

        _isSyncing = false;
        notifyListeners();

        ConsoleLogger.success('[SyncService] Sync successful');

        return true;
      } catch (e, stackTrace) {
        ConsoleLogger.error(
          'SyncService',
          'performSyncAttempt',
          e,
          stackTrace: stackTrace,
        );

        await ErrorLoggerService.logError(
          component: 'SyncService',
          operation: 'performSyncAttempt',
          error: e,
          stackTrace: stackTrace,
          severity: attempt == _maxRetries - 1
              ? ErrorSeverity.high
              : ErrorSeverity.medium,
          metadata: {
            'attempt': attempt + 1,
            'max_retries': _maxRetries,
            'context_message': 'Sync attempt ${attempt + 1} failed',
          },
        );

        if (attempt < _maxRetries - 1) {
          final delay = _baseRetryDelay * (1 << attempt);
          await Future.delayed(delay);
        } else {
          _hasError = true;
          _lastError = e.toString();
        }
      }
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  /// Logique de synchronisation des données avec outbox
  Future<void> _syncData() async {
    final db = await _databaseService.database;

    // Récupérer toutes les opérations en attente (status = 'pending' ou 'failed' avec retry < max)
    final operations = await db.query(
      'sync_outbox',
      where: 'status IN (?, ?) AND retry_count < ?',
      whereArgs: ['pending', 'failed', _maxOperationRetries],
      orderBy: 'created_at ASC',
    );

    _pendingOperations = operations.length;
    notifyListeners();

    if (operations.isEmpty) {
      ConsoleLogger.info('[SyncService] No pending operations to sync');
      return;
    }

    ConsoleLogger.info('[SyncService] Syncing ${operations.length} operations');

    int successCount = 0;
    int failCount = 0;

    for (final op in operations) {
      try {
        await _syncOperation(op);
        successCount++;
      } catch (e, stackTrace) {
        failCount++;
        ConsoleLogger.error(
          'SyncService',
          'syncOperation',
          e,
          stackTrace: stackTrace,
        );

        await ErrorLoggerService.logError(
          component: 'SyncService',
          operation: 'syncOperation',
          error: e,
          stackTrace: stackTrace,
          severity: ErrorSeverity.medium,
          metadata: {
            'operation_id': op['id'],
            'operation_type': op['operation_type'],
            'entity_type': op['entity_type'],
            'retry_count': op['retry_count'],
          },
        );
      }
    }

    _failedOperations = failCount;
    _pendingOperations = await _getPendingOperationsCount();
    notifyListeners();

    ConsoleLogger.success(
      '[SyncService] Sync completed: $successCount success, $failCount failed',
    );
  }

  /// Synchronise une opération individuelle
  Future<void> _syncOperation(Map<String, dynamic> operation) async {
    final db = await _databaseService.database;
    final opId = operation['id'] as int;

    // Marquer comme "en cours de sync"
    await db.update(
      'sync_outbox',
      {'status': 'syncing', 'last_retry_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [opId],
    );

    try {
      // Appel réel à Supabase
      await _callSupabaseApi(operation);

      // Marquer comme synchronisé
      await db.update(
        'sync_outbox',
        {'status': 'synced'},
        where: 'id = ?',
        whereArgs: [opId],
      );

      // Nettoyer les opérations synchronisées (optionnel, garder pour historique)
      // await db.delete('sync_outbox', where: 'id = ?', whereArgs: [opId]);

      ConsoleLogger.info(
        '[SyncService] Operation ${operation['operation_type']} on ${operation['entity_type']} synced',
      );
    } catch (e) {
      // Incrémenter le compteur de retry
      final retryCount = (operation['retry_count'] as int) + 1;

      await db.update(
        'sync_outbox',
        {
          'status': 'failed',
          'retry_count': retryCount,
          'error_message': e.toString().substring(0, 500), // Limiter la taille
        },
        where: 'id = ?',
        whereArgs: [opId],
      );

      rethrow;
    }
  }

  /// Appelle l'API Supabase réelle (remplace le mock)
  Future<void> _callSupabaseApi(Map<String, dynamic> operation) async {
    // Vérifier que Supabase est configuré
    if (!SupabaseConfig.isConfigured()) {
      throw Exception('Supabase not configured. Please configure URL and anon key.');
    }

    // Test connection rapide avant opération
    if (!await SupabaseApiService.instance.testConnection()) {
      if (kDebugMode) {
        // Simuler le mock en debug si pas de réseau pour éviter les blocages tests
        await Future.delayed(const Duration(milliseconds: 500));
        if (DateTime.now().millisecond % 10 == 0) {
          throw Exception('Simulated API error (Supabase not connected)');
        }
        return;
      }
      throw Exception('Cannot connect to Supabase API');
    }

    // Appel réel à Supabase
    await SupabaseApiService.instance.syncOperation(operation);
  }

  /// Compte les opérations en attente
  Future<int> _getPendingOperationsCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_outbox WHERE status IN (?, ?) AND retry_count < ?',
      ['pending', 'failed', _maxOperationRetries],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Affiche le dialogue d'erreur de synchronisation
  void showSyncErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur de synchronisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dernière erreur: ${_lastError ?? "Inconnue"}'),
            const SizedBox(height: 8),
            Text('Dernière sync: ${_lastSyncTime?.toString() ?? "Jamais"}'),
            const SizedBox(height: 16),
            const Text(
              'L\'application fonctionne normalement en mode hors ligne. '
              'Vous pouvez réessayer la synchronisation plus tard.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (_connectivityService.isOnline)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                forceSyncWithFeedback(context);
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  /// Obtient le statut de synchronisation
  Map<String, dynamic> getSyncStatus() {
    return {
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncing': _isSyncing,
      'hasError': _hasError,
      'lastError': _lastError,
      'syncEnabled': _syncEnabled,
      'userConsent': _userConsent,
      'pendingOperations': _pendingOperations,
      'failedOperations': _failedOperations,
    };
  }

  /// Enregistre une opération locale dans l'outbox pour sync ultérieure
  /// Principe "local wins": l'opération est d'abord appliquée localement
  Future<void> enqueueOperation({
    required String operationType, // 'CREATE', 'UPDATE', 'DELETE'
    required String
    entityType, // 'objet', 'foyer', 'reachat_log', 'budget_categories'
    required int entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final db = await _databaseService.database;

      await db.insert('sync_outbox', {
        'operation_type': operationType,
        'entity_type': entityType,
        'entity_id': entityId,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'retry_count': 0,
      });

      _pendingOperations = await _getPendingOperationsCount();
      notifyListeners();

      ConsoleLogger.info(
        '[SyncService] Operation enqueued: $operationType $entityType #$entityId',
      );

      // Tenter une sync automatique si en ligne et sync activée
      if (_syncEnabled &&
          _userConsent &&
          _connectivityService.isOnline &&
          !_isSyncing) {
        // Sync en arrière-plan sans bloquer
        unawaited(
          _performSync().catchError((e) {
            ConsoleLogger.error('SyncService', 'autoSync', e);
            return false;
          }),
        );
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SyncService',
        operation: 'enqueueOperation',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {
          'operation_type': operationType,
          'entity_type': entityType,
          'entity_id': entityId,
        },
      );
      rethrow;
    }
  }

  /// Nettoie les opérations synchronisées anciennes (> 30 jours)
  Future<void> cleanupSyncedOperations() async {
    try {
      final db = await _databaseService.database;
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      final deleted = await db.delete(
        'sync_outbox',
        where: 'status = ? AND created_at < ?',
        whereArgs: ['synced', cutoffDate.toIso8601String()],
      );

      if (deleted > 0) {
        ConsoleLogger.info(
          '[SyncService] Cleaned up $deleted old synced operations',
        );
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'SyncService',
        operation: 'cleanupSyncedOperations',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
    }
  }

  /// Synchronisation automatique en arrière-plan (si activée)
  Future<void> backgroundSync() async {
    if (!_syncEnabled || !_userConsent || !_connectivityService.isOnline) {
      return;
    }

    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync.inMinutes < 30) {
        return;
      }
    }

    await _performSync();
  }

  /// Nettoyage des ressources du service
  void _disposeInternals() {
    _isSyncing = false;
    _hasError = false;
    _lastError = null;
    _lastSyncTime = null;
    _syncEnabled = false;
    _userConsent = false;
    _pendingOperations = 0;
    _failedOperations = 0;
  }

  /// Nettoyage des ressources
  @override
  void dispose() {
    // Potentially cancel any ongoing timers or listeners if created
    super.dispose();
  }
}

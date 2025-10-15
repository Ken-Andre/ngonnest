import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart'; // For ErrorContext if ever needed elsewhere, though not directly in logError calls now
import 'connectivity_service.dart';
import 'error_logger_service.dart';
import 'console_logger.dart';

/// Service de synchronisation offline-first pour NgonNest
/// Respecte les principes : offline first, sync optionnelle, local wins, retry logic
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
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

      ConsoleLogger.info('[SyncService] Sync enabled with user consent: $userConsent');

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
  Future<void> forceSyncWithFeedback(BuildContext context) async {
    if (!_syncEnabled || !_userConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Synchronisation désactivée. Activez-la dans les paramètres.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_connectivityService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pas de connexion internet. Synchronisation impossible.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSyncing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronisation déjà en cours...'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Synchronisation en cours...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    final success = await _performSync();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Synchronisation réussie'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Échec synchronisation: $_lastError'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Détails',
            onPressed: () => showSyncErrorDialog(context),
          ),
        ),
      );
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
        ConsoleLogger.info('[SyncService] Sync attempt ${attempt + 1}/$_maxRetries');

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
        ConsoleLogger.error('SyncService', 'performSyncAttempt', e, stackTrace: stackTrace);

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

  /// Logique de synchronisation des données (placeholder)
  Future<void> _syncData() async {
    await Future.delayed(const Duration(seconds: 2));

    // Optionally simulate errors in debug using a feature flag in the future

    ConsoleLogger.info('[SyncService] Data sync completed (simulated)');
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
    };
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

  /// Nettoyage des ressources
  @override
  void dispose() {
    // Potentially cancel any ongoing timers or listeners if created
    super.dispose();
  }
}

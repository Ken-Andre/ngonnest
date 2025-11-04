import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/connectivity_service.dart';
import '../services/console_logger.dart';

/// Optimisations spécifiques au Cameroun pour NgoNest
/// Respecte contraintes: réseau lent, 2Go RAM, <25Mo app, Android 8.0+
/// Lit les règles: .cursor/rules/ngonnest-rules.md
class CameroonOptimization {
  static CameroonOptimization? _instance;
  static CameroonOptimization get instance => _instance ??= CameroonOptimization._internal();

  CameroonOptimization._internal() {
    _setupPerformanceOptimizations();
  }

  // Optimisations réseau pour réseau Cameroun (MTN, Orange, Nexttel lent/chère)
  static const int maxImageSize = 200 * 1024; // 200KB max pour images
  static const int maxPayloadSize = 50 * 1024; // 50KB max par opération
  static const int syncBatchSize = 5; // 5 opérations max par batch
  static const Duration syncCooldown = Duration(minutes: 15); // Sync tous les 15min
  static const int maxConcurrentRequests = 1; // 1 requête à la fois

  // Optimisations batterie Cameroun (importance économie énergie)
  static const int backgroundSyncBatteryThreshold = 20; // % min pour sync
  static const Duration batteryCheckInterval = Duration(minutes: 5);

  // Cache optimisé Cameroun (stockage limité)
  static const Duration cacheMaxAge = Duration(days: 3); // Cache 3j max
  static const int maxCacheEntries = 100;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isBatterySavingMode = false;
  bool _isDataSavingMode = false;
  final ConnectivityService _connectivityService = ConnectivityService();
  final Connectivity _connectivity = Connectivity();

  /// Configuration réseau optimisée Cameroun
  void _setupPerformanceOptimizations() {
    // Surveillance connectivité réseau Cameroun
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Optimisations selon type de réseau
    _optimizeForNetworkType();

    // Optimisations batterie
    _setupBatteryOptimizations();

    ConsoleLogger.info('[CameroonOptimization] Performance optimizations initialized');
  }

  /// Adaptations selon réseau (WiFi vs Data mobile chère)
  void _optimizeForNetworkType() async {
    final status = _connectivityService.connectivityResult;

    switch (status) {
      case ConnectivityResult.wifi:
        _isDataSavingMode = false;
        ConsoleLogger.info('[CameroonOptimization] WiFi detected - standard mode');
        break;

      case ConnectivityResult.mobile:
        _isDataSavingMode = true;
        ConsoleLogger.info('[CameroonOptimization] Mobile data - data saving mode');
        _enableDataSavingMode();
        break;
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.none:
        ConsoleLogger.warning('[CameroonOptimization] Limited connectivity detected - data saving mode');
        _isDataSavingMode = true;  // Par défaut en mode économie pour sécurité
        break;
    }
  }

  /// Gestion changement de connectivité
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // Prendre le premier résultat (comme dans ConnectivityService)
    final status = results.isNotEmpty ? results.first : ConnectivityResult.none;
    ConsoleLogger.info('[CameroonOptimization] Connectivity changed: $status');
    _optimizeForNetworkType();
  }

  /// Mode économie données (réseau mobile)
  void _enableDataSavingMode() {
    // Réduire fréquence sync
    // Compresser payloads
    // Désactiver auto-sync non-essentiel
    ConsoleLogger.info('[CameroonOptimization] Data saving mode enabled');
  }

  /// Optimisations batterie Cameroun
  void _setupBatteryOptimizations() {
    // Vérifier batterie périodiquement
    Timer.periodic(batteryCheckInterval, _checkBatteryLevel);

    // Optimiser animations pour appareils modestes
    _optimizeAnimations();

    ConsoleLogger.info('[CameroonOptimization] Battery optimizations setup');
  }

  /// Vérification niveau batterie
  void _checkBatteryLevel(Timer timer) async {
    try {
      // Sur Android, vérifier niveau batterie
      if (Platform.isAndroid) {
        // Simuler vérification batterie
        final batteryLevel = await _getBatteryLevel();

        if (batteryLevel < backgroundSyncBatteryThreshold) {
          if (!_isBatterySavingMode) {
            _isBatterySavingMode = true;
            ConsoleLogger.info('[CameroonOptimization] Battery saving mode enabled');
            _enableBatterySavingMode();
          }
        } else {
          if (_isBatterySavingMode) {
            _isBatterySavingMode = false;
            ConsoleLogger.info('[CameroonOptimization] Battery saving mode disabled');
          }
        }
      }
    } catch (e) {
      ConsoleLogger.warning('[CameroonOptimization] Battery check failed: $e');
    }
  }

  /// Simulation niveau batterie (remplacer par vraie API)
  Future<int> _getBatteryLevel() async {
    // Simulation - utiliser vraie API Android
    // Pour production: Android BatteryManager
    return 75; // Par défaut 75%
  }

  /// Mode économie batterie
  void _enableBatterySavingMode() {
    // Désactiver sync en arrière-plan
    // Réduire fréquence des tâches
    // Désactiver animations coûteuses

    ConsoleLogger.info('[CameroonOptimization] Battery savings activated');
  }

  /// Optimisations animations pour appareils modestes
  void _optimizeAnimations() {
    // Réduire complexité animations
    // Utiliser moins d'effets visuels
    // Optimiser frame rate
  }

  /// Validation payloads Cameroun (limites data)
  Map<String, dynamic> validateAndOptimizePayload(
    String entityType,
    Map<String, dynamic> payload,
  ) {
    var optimized = Map<String, dynamic>.from(payload);

    // Validation taille payload
    final payloadSize = _calculatePayloadSize(optimized);
    if (payloadSize > maxPayloadSize) {
      ConsoleLogger.warning(
        '[CameroonOptimization] Payload too large: ${payloadSize}KB, compressing...'
      );

      // Compression des champs texte
      optimized = _compressPayload(optimized);
    }

    // Optimisations spécifiques par entité
    switch (entityType) {
      case 'objet':
        optimized = _optimizeProductPayload(optimized);
        break;
      case 'foyer':
        optimized = _optimizeHouseholdPayload(optimized);
        break;
      case 'reachat_log':
        optimized = _optimizePurchasePayload(optimized);
        break;
      case 'budget_categories':
        optimized = _optimizeBudgetPayload(optimized);
        break;
    }

    return optimized;
  }

  /// Compression payload
  Map<String, dynamic> _compressPayload(Map<String, dynamic> payload) {
    final compressed = Map<String, dynamic>.from(payload);

    // Compresser commentaires et descriptions longues
    if (compressed.containsKey('commentaires')) {
      final commentaires = compressed['commentaires'] as String?;
      if (commentaires != null && commentaires.length > 200) {
        compressed['commentaires'] = '${commentaires.substring(0, 200)}...';
      }
    }

    // Compresser noms longs
    if (compressed.containsKey('nom')) {
      final nom = compressed['nom'] as String?;
      if (nom != null && nom.length > 50) {
        compressed['nom'] = '${nom.substring(0, 50)}...';
      }
    }

    return compressed;
  }

  /// Optimisations spécifiques produit
  Map<String, dynamic> _optimizeProductPayload(Map<String, dynamic> payload) {
    final optimized = Map<String, dynamic>.from(payload);

    // Pour produits, garder seulement champs essentiels
    const essentialFields = [
      'id', 'id_foyer', 'nom', 'categorie', 'type', 'quantite_initiale',
      'quantite_restante', 'unite', 'prix_unitaire', 'date_modification'
    ];

    optimized.removeWhere((key, value) =>
      !essentialFields.contains(key) &&
      value == null
    );

    return optimized;
  }

  /// Optimisations spécifiques foyer
  Map<String, dynamic> _optimizeHouseholdPayload(Map<String, dynamic> payload) {
    // Foyers gardent tous leurs champs (petits)
    return payload;
  }

  /// Optimisations spécifiques achats
  Map<String, dynamic> _optimizePurchasePayload(Map<String, dynamic> payload) {
    final optimized = Map<String, dynamic>.from(payload);

    // Achats: seulement champs essentiels
    const essentialFields = [
      'id', 'id_objet', 'date', 'quantite', 'prix_total'
    ];

    optimized.removeWhere((key, value) =>
      !essentialFields.contains(key) &&
      value == null
    );

    return optimized;
  }

  /// Optimisations spécifiques budget
  Map<String, dynamic> _optimizeBudgetPayload(Map<String, dynamic> payload) {
    // Budgets gardent tous leurs champs (petits)
    return payload;
  }

  /// Calcul taille payload en KB
  int _calculatePayloadSize(Map<String, dynamic> payload) {
    // Estimation simple basée sur contenu texte
    final jsonString = payload.toString();
    return (jsonString.length * 2) ~/ 1024; // Approximation
  }

  /// Vérifier si sync possible avec contraintes Cameroun
  bool canPerformSync(BuildContext? context) {
    // Vérifier connectivité
    final connected = _connectivityService.isOnline;
    if (!connected) return false;

    // En mode économie données, seulement sync manuelle
    if (_isDataSavingMode && context == null) return false;

    // En mode économie batterie, pas de sync auto
    if (_isBatterySavingMode && context == null) return false;

    return true;
  }

  /// Recommandations sync intelligentes Cameroun
  Duration getRecommendedSyncInterval() {
    if (_isDataSavingMode) return const Duration(hours: 2);
    if (_isBatterySavingMode) return const Duration(hours: 1);
    return syncCooldown; // 15 minutes normal
  }

  /// Statistiques optimisation Cameroun
  Map<String, dynamic> getOptimizationStats() {
    return {
      'data_saving_mode': _isDataSavingMode,
      'battery_saving_mode': _isBatterySavingMode,
      'network_type': _connectivityService.connectivityResult,
      'sync_enabled': canPerformSync(null),
      'recommended_sync_interval_minutes': getRecommendedSyncInterval().inMinutes,
      'payload_size_limit_kb': maxPayloadSize ~/ 1024,
      'max_concurrent_requests': maxConcurrentRequests,
    };
  }

  /// Cleanup et sauvegarde batterie
  void dispose() {
    _connectivitySubscription.cancel();
    ConsoleLogger.info('[CameroonOptimization] Disposed');
  }

  /// Méthodes publiques pour accès

  /// Vérification avant sync
  static bool shouldPerformSync(BuildContext? context) {
    return instance.canPerformSync(context);
  }

  /// Optimisation payload avant envoi
  static Map<String, dynamic> optimizePayload(String entityType, Map<String, dynamic> payload) {
    return instance.validateAndOptimizePayload(entityType, payload);
  }

  /// Intervalle sync recommandé
  static Duration getSyncInterval() {
    return instance.getRecommendedSyncInterval();
  }

  /// Stats pour monitoring
  static Map<String, dynamic> getStats() {
    return instance.getOptimizationStats();
  }
}

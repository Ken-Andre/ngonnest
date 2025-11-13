import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'analytics_service.dart';

/// Service de gestion de la connectivité réseau pour NgonNest MVP
/// Fournit des notifications dynamiques comme YouTube pour l'état réseau
/// Optimisé pour les besoins Cameroun : détection hors ligne/online
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _initConnectivity();
  }

  final AnalyticsService _analytics = AnalyticsService();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _bannerTimer;
  bool _isInitialized = false;

  // États de connectivité
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _isOnline = false;
  bool _showBanner = false;
  String _bannerMessage = '';
  Color _bannerColor = Colors.blue;
  IconData _bannerIcon = Icons.wifi;

  // Getters pour l'état actuel
  ConnectivityResult get connectivityResult => _connectivityResult;
  bool get isOnline => _isOnline;
  bool get showBanner => _showBanner;
  String get bannerMessage => _bannerMessage;
  Color get bannerColor => _bannerColor;
  IconData get bannerIcon => _bannerIcon;
  
  // Expose the connectivity stream for external listeners
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  /// Initialise la surveillance de la connectivité
  Future<void> _initConnectivity() async {
    try {
      // Vérification initiale
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);

      // Écoute des changements
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          _updateConnectivityStatus(results);
          // Track connectivity changes for analytics
          _analytics.trackConnectivityChange(results.first);
        },
        onError: (error) {
          print('[ConnectivityService] Erreur surveillance réseau: $error');
          _showOfflineBanner();
        },
      );

      print('[ConnectivityService] Service connectivité initialisé');
    } catch (e) {
      print('[ConnectivityService] Erreur initialisation: $e');
      _showOfflineBanner();
    }
  }

  /// Met à jour le statut de connectivité
  void _updateConnectivityStatus(List<ConnectivityResult> results, {bool isInitialCheck = false}) {
    // Prendre le premier résultat (priorité WiFi > Mobile > Ethernet > None)
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final newStatus = result != ConnectivityResult.none;

    // Si c'est le premier lancement, juste mettre à jour l'état sans bannière
    if (!isInitialCheck && newStatus != _isOnline) {
      // Il y a eu un changement de statut réseau - afficher la bannière
      _connectivityResult = result;
      _showTemporaryBannerForStatus(newStatus);
    } else {
      // Mise à jour normale de l'état
      _connectivityResult = result;
      _isOnline = newStatus;
    }

    if (isInitialCheck) {
      _isInitialized = true;
    }

    notifyListeners();
  }

  /// Affiche une bannière temporaire lors d'un changement de statut
  void _showTemporaryBannerForStatus(bool isNowOnline) {
    _isOnline = isNowOnline;

    if (isNowOnline) {
      // Reconnexion
      _bannerMessage = 'De retour en ligne';
      _bannerColor = Colors.green;
      _bannerIcon = Icons.wifi;
    } else {
      // Déconnexion
      _bannerMessage = 'Vous êtes hors ligne';
      _bannerColor = Colors.orange;
      _bannerIcon = Icons.wifi_off;
    }

    _showBanner = true;

    // Masquer automatiquement après 4 secondes
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      _showBanner = false;
      notifyListeners();
    });
  }

  /// Affichage bannière hors ligne (méthode de compatibilité)
  void _showOfflineBanner() {
    if (!_isInitialized) return; // Ne pas afficher au démarrage

    _isOnline = false;
    _bannerMessage = 'Vous êtes hors ligne';
    _bannerColor = Colors.orange;
    _bannerIcon = Icons.wifi_off;
    _showBanner = true;

    // Masquer automatiquement après 4 secondes
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      _showBanner = false;
      notifyListeners();
    });
  }

  /// Force l'affichage de la bannière (pour debug/tests)
  void showConnectivityBanner() {
    _showBanner = true;
    notifyListeners();
  }

  /// Masque manuellement la bannière
  void hideConnectivityBanner() {
    _showBanner = false;
    notifyListeners();
  }

  /// Vérifie manuellement la connectivité
  Future<void> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
    } catch (e) {
      print('[ConnectivityService] Erreur vérification manuelle: $e');
      _showOfflineBanner();
    }
  }

  /// Vérification de pré-vol pour les opérations réseau critiques
  /// Retourne true si le réseau semble opérationnel
  Future<bool> preFlightCheck() async {
    try {
      // Vérification rapide de la connectivité
      final results = await _connectivity.checkConnectivity();
      final hasConnectivity = results.any((result) =>
          result != ConnectivityResult.none);

      if (!hasConnectivity) {
        print('[ConnectivityService] Pré-vol: Pas de connectivité détectée');
        return false;
      }

      // Test DNS rapide (ping-like) pour Supabase
      final supabaseUrl = 'https://twihbdmgqrsvfpyuhkoz.supabase.co';
      final uri = Uri.parse(supabaseUrl);

      // Timeout court pour éviter de bloquer l'UI
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      try {
        final request = await client.headUrl(uri);
        final response = await request.close();
        await response.drain();
        client.close();

        print('[ConnectivityService] Pré-vol: Supabase accessible');
        return true;
      } catch (e) {
        print('[ConnectivityService] Pré-vol: Supabase inaccessible - $e');
        client.close();
        return false;
      }
    } catch (e) {
      print('[ConnectivityService] Pré-vol: Erreur générale - $e');
      return false;
    }
  }

  /// Vérifie si une erreur est liée au réseau
  bool isNetworkError(dynamic error) {
    if (error == null) return false;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('socket') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('dns') ||
           errorString.contains('host lookup') ||
           errorString.contains('no address associated');
  }

  /// Obtient un message d'erreur réseau convivial
  String getNetworkErrorMessage(dynamic error) {
    if (!isOnline) {
      return 'Vous êtes hors ligne. Vérifiez votre connexion internet.';
    }

    if (isNetworkError(error)) {
      return 'Problème de connexion réseau. Réessayez dans quelques instants.';
    }

    return 'Erreur de connexion. Vérifiez votre réseau.';
  }

  /// Libère les ressources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }

  /// Debug: obtenir l'état complet
  Map<String, dynamic> getDebugInfo() {
    return {
      'connectivity_result': _connectivityResult.toString(),
      'is_online': _isOnline,
      'show_banner': _showBanner,
      'banner_message': _bannerMessage,
      'banner_color': _bannerColor.toString(),
      'banner_icon': _bannerIcon.toString(),
    };
  }

  /// Méthode pour les tests - permet de forcer l'état de connectivité
  void setConnectivityForTesting(bool isOnline, bool showBanner) {
    _isOnline = isOnline;
    _showBanner = showBanner;
    _isInitialized = true;
    
    if (isOnline && showBanner) {
      // État reconnecté
      _bannerMessage = 'De retour en ligne';
      _bannerColor = Colors.green;
      _bannerIcon = Icons.wifi;
    } else if (!isOnline && showBanner) {
      // État offline
      _bannerMessage = 'Vous êtes hors ligne';
      _bannerColor = Colors.orange;
      _bannerIcon = Icons.wifi_off;
    }
    
    notifyListeners();
  }
}

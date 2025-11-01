import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Type de breadcrumb pour catégorisation
enum BreadcrumbType {
  navigation, // Navigation entre écrans
  userAction, // Actions utilisateur (tap, swipe, etc.)
  stateChange, // Changements d'état app
  networkRequest, // Requêtes réseau
  databaseOperation, // Opérations DB
  error, // Erreurs non-fatales
  lifecycle, // Événements lifecycle app
  system, // Événements système (mémoire, batterie, etc.)
}

/// Niveau de sévérité du breadcrumb
enum BreadcrumbLevel {
  debug,
  info,
  warning,
  error,
}

/// Entrée de breadcrumb pour traçage des événements
class Breadcrumb {
  final DateTime timestamp;
  final BreadcrumbType type;
  final BreadcrumbLevel level;
  final String message;
  final Map<String, dynamic>? data;

  Breadcrumb({
    required this.timestamp,
    required this.type,
    required this.level,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final typeStr = type.toString().split('.').last;
    final levelStr = level.toString().split('.').last;
    return '[$timeStr] [$levelStr] [$typeStr] $message${data != null ? ' | ${data.toString()}' : ''}';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString().split('.').last,
    'level': level.toString().split('.').last,
    'message': message,
    'data': data,
  };
}

/// Service de fil d'Ariane pour tracer les événements précédant un crash
/// Conserve les N derniers événements en mémoire pour analyse post-crash
class BreadcrumbService {
  static final BreadcrumbService _instance = BreadcrumbService._internal();
  factory BreadcrumbService() => _instance;
  BreadcrumbService._internal();

  // Queue circulaire pour limiter la mémoire (important pour devices camerounais)
  static const int _maxBreadcrumbs = 100;
  final Queue<Breadcrumb> _breadcrumbs = Queue<Breadcrumb>();

  /// Ajoute un breadcrumb de navigation
  void addNavigation(String screenName, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.navigation,
      level: BreadcrumbLevel.info,
      message: 'Navigated to $screenName',
      data: data,
    );
  }

  /// Ajoute un breadcrumb d'action utilisateur
  void addUserAction(String action, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.userAction,
      level: BreadcrumbLevel.info,
      message: action,
      data: data,
    );
  }

  /// Ajoute un breadcrumb de changement d'état
  void addStateChange(String state, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.stateChange,
      level: BreadcrumbLevel.debug,
      message: state,
      data: data,
    );
  }

  /// Ajoute un breadcrumb de requête réseau
  void addNetworkRequest({
    required String method,
    required String url,
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    _addBreadcrumb(
      type: BreadcrumbType.networkRequest,
      level: statusCode != null && statusCode >= 400 
          ? BreadcrumbLevel.warning 
          : BreadcrumbLevel.info,
      message: '$method $url${statusCode != null ? ' -> $statusCode' : ''}',
      data: data,
    );
  }

  /// Ajoute un breadcrumb d'opération DB
  void addDatabaseOperation(String operation, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.databaseOperation,
      level: BreadcrumbLevel.debug,
      message: operation,
      data: data,
    );
  }

  /// Ajoute un breadcrumb d'erreur non-fatale
  void addError(String errorMessage, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.error,
      level: BreadcrumbLevel.error,
      message: errorMessage,
      data: data,
    );
  }

  /// Ajoute un breadcrumb de lifecycle
  void addLifecycle(String event, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.lifecycle,
      level: BreadcrumbLevel.info,
      message: event,
      data: data,
    );
  }

  /// Ajoute un breadcrumb système (mémoire, batterie, etc.)
  void addSystem(String event, {Map<String, dynamic>? data}) {
    _addBreadcrumb(
      type: BreadcrumbType.system,
      level: BreadcrumbLevel.warning,
      message: event,
      data: data,
    );
  }

  /// Ajoute un breadcrumb custom
  void addCustom({
    required BreadcrumbType type,
    required BreadcrumbLevel level,
    required String message,
    Map<String, dynamic>? data,
  }) {
    _addBreadcrumb(
      type: type,
      level: level,
      message: message,
      data: data,
    );
  }

  /// Méthode interne pour ajouter un breadcrumb
  void _addBreadcrumb({
    required BreadcrumbType type,
    required BreadcrumbLevel level,
    required String message,
    Map<String, dynamic>? data,
  }) {
    final breadcrumb = Breadcrumb(
      timestamp: DateTime.now(),
      type: type,
      level: level,
      message: message,
      data: data,
    );

    _breadcrumbs.add(breadcrumb);

    // Limiter la taille de la queue (rotation automatique)
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeFirst();
    }

    // Log en debug mode
    if (kDebugMode) {
      debugPrint('🍞 [Breadcrumb] $breadcrumb');
    }
  }

  /// Récupère les N derniers breadcrumbs
  Future<List<Breadcrumb>> getRecentBreadcrumbs({int limit = 50}) async {
    final count = limit > _breadcrumbs.length ? _breadcrumbs.length : limit;
    return _breadcrumbs.toList().sublist(_breadcrumbs.length - count);
  }

  /// Récupère tous les breadcrumbs
  List<Breadcrumb> getAllBreadcrumbs() {
    return _breadcrumbs.toList();
  }

  /// Récupère les breadcrumbs par type
  List<Breadcrumb> getBreadcrumbsByType(BreadcrumbType type) {
    return _breadcrumbs.where((b) => b.type == type).toList();
  }

  /// Récupère les breadcrumbs par niveau
  List<Breadcrumb> getBreadcrumbsByLevel(BreadcrumbLevel level) {
    return _breadcrumbs.where((b) => b.level == level).toList();
  }

  /// Récupère les breadcrumbs dans une plage de temps
  List<Breadcrumb> getBreadcrumbsInTimeRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _breadcrumbs
        .where((b) => b.timestamp.isAfter(start) && b.timestamp.isBefore(end))
        .toList();
  }

  /// Efface tous les breadcrumbs
  void clear() {
    _breadcrumbs.clear();
    if (kDebugMode) {
      debugPrint('🧹 [Breadcrumb] All breadcrumbs cleared');
    }
  }

  /// Récupère le nombre de breadcrumbs
  int get count => _breadcrumbs.length;

  /// Vérifie si la queue est vide
  bool get isEmpty => _breadcrumbs.isEmpty;

  /// Vérifie si la queue est pleine
  bool get isFull => _breadcrumbs.length >= _maxBreadcrumbs;

  /// Exporte les breadcrumbs en JSON pour debug
  List<Map<String, dynamic>> exportToJson() {
    return _breadcrumbs.map((b) => b.toJson()).toList();
  }

  /// Affiche un résumé des breadcrumbs (debug)
  void printSummary() {
    if (!kDebugMode) return;

    debugPrint('📊 [Breadcrumb] Summary:');
    debugPrint('   Total: ${_breadcrumbs.length}');
    
    final typeCount = <BreadcrumbType, int>{};
    final levelCount = <BreadcrumbLevel, int>{};
    
    for (final b in _breadcrumbs) {
      typeCount[b.type] = (typeCount[b.type] ?? 0) + 1;
      levelCount[b.level] = (levelCount[b.level] ?? 0) + 1;
    }

    debugPrint('   By Type:');
    typeCount.forEach((type, count) {
      debugPrint('      ${type.toString().split('.').last}: $count');
    });

    debugPrint('   By Level:');
    levelCount.forEach((level, count) {
      debugPrint('      ${level.toString().split('.').last}: $count');
    });
  }
}

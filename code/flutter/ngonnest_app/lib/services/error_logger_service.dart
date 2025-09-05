import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Sévérité des erreurs pour priorisation et reporting
enum ErrorSeverity {
  low,      // Erreurs mineures (validation UI)
  medium,   // Erreurs fonctionnelles (DB, réseau léger)
  high,     // Erreurs critiques (crash, données perdues)
  critical  // Erreurs système (app unusable)
}

/// Entrée de log structuré pour le debugging professionnel
class ErrorLogEntry {
  final DateTime timestamp;
  final String component;
  final String operation;
  final String errorCode;
  final ErrorSeverity severity;
  final String userMessage;
  final String technicalMessage;
  final String stackTrace;
  final String appVersion;
  final Map<String, String> deviceInfo;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final String? sessionId;

  ErrorLogEntry({
    required this.timestamp,
    required this.component,
    required this.operation,
    required this.errorCode,
    required this.severity,
    required this.userMessage,
    required this.technicalMessage,
    required this.stackTrace,
    required this.appVersion,
    required this.deviceInfo,
    this.metadata,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'component': component,
    'operation': operation,
    'error_code': errorCode,
    'severity': severity.toString().split('.').last,
    'user_message': userMessage,
    'technical_message': technicalMessage,
    'stack_trace': stackTrace,
    'app_version': appVersion,
    'device_info': deviceInfo,
    'metadata': metadata,
    'user_id': userId,
    'session_id': sessionId,
  };

  static ErrorLogEntry fromJson(Map<String, dynamic> json) => ErrorLogEntry(
    timestamp: DateTime.parse(json['timestamp']),
    component: json['component'],
    operation: json['operation'],
    errorCode: json['error_code'],
    severity: ErrorSeverity.values.firstWhere((e) => e.toString().split('.').last == json['severity']),
    userMessage: json['user_message'],
    technicalMessage: json['technical_message'],
    stackTrace: json['stack_trace'],
    appVersion: json['app_version'],
    deviceInfo: Map<String, String>.from(json['device_info']),
    metadata: json['metadata'],
    userId: json['user_id'],
    sessionId: json['session_id'],
  );
}

/// Service centralisé de logging d'erreurs professionel
/// Inspiré des pratiques Google, Airbnb, Sentry
class ErrorLoggerService {
  static const String _logFileName = 'ngonnest_error_logs.json';

  /// Génère un code d'erreur prédictible basé sur le type d'erreur
  static String _generateErrorCode(dynamic error, String operation) {
    // Codes prédéfinis pour les erreurs communes
    final Map<String, String> errorCodes = {
      'PlatformException': 'SYS_001',     // Erreurs système/Android
      'DatabaseException': 'DB_001',      // Erreurs base de données
      'ValidationError': 'VAL_000',       // Erreurs de validation (sera spécifié)
      'NetworkException': 'NET_001',      // Erreurs réseau
      'PermissionException': 'PERM_001',   // Erreurs permissions
    };

    final errorType = error.runtimeType.toString();

    // Si c'est une erreur connue, utiliser le code prédéfini
    if (errorCodes.containsKey(errorType)) {
      return errorCodes[errorType]!;
    }

    // Pour les erreurs non prédéfinies, utiliser un hash déterministe
    final operationHash = operation.hashCode % 1000;
    final errorTypeHash = errorType.hashCode % 900;
    return 'ERR_${operationHash}_${errorTypeHash}';
  }

  /// Génère un message utilisateur adapté selon le type d'erreur
  static String _getUserMessage(dynamic error, String operation) {
    final errorType = error.runtimeType.toString().toLowerCase();

    if (errorType.contains('sqflite')) {
      return 'Erreur de base de données. Veuillez réessayer.';
    }
    if (errorType.contains('network') || errorType.contains('socket')) {
      return 'Problème de connexion. Vérifiez votre réseau.';
    }
    if (errorType.contains('validation') || errorType.contains('argument')) {
      return 'Données invalides. Vérifiez vos informations.';
    }
    if (errorType.contains('permission')) {
      return 'Permission requise manquante.';
    }

    return 'Une erreur inattendue s\'est produite.';
  }

  /// Récupère les informations de l'appareil
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final info = <String, String>{};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'platform': 'android',
          'model': androidInfo.model ?? 'unknown',
          'android_version': androidInfo.version.release ?? 'unknown',
          'manufacturer': androidInfo.manufacturer ?? 'unknown',
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'platform': 'ios',
          'model': iosInfo.model ?? 'unknown',
          'system_version': iosInfo.systemVersion ?? 'unknown',
        });
      }
    } catch (e) {
      info.addAll({
        'platform': Platform.operatingSystem,
        'error_getting_device_info': e.toString(),
      });
    }

    return info;
  }

  /// Récupère la version de l'application
  static Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Log une erreur avec tous les détails nécessaires pour le debugging
  static Future<void> logError({
    required String component,
    required String operation,
    required dynamic error,
    required StackTrace stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) async {
    try {
      final errorCode = _generateErrorCode(error, operation);
      final userMessage = _getUserMessage(error, operation);

      // Log console toujours (indépendamment du stockage)
      if (kDebugMode) {
        debugPrint('🔴 [ERROR_LOG] $errorCode | $component.$operation | $userMessage');
        debugPrint('   Technical: ${error.toString()}');
      }

      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();

      final logEntry = ErrorLogEntry(
        timestamp: DateTime.now(),
        component: component,
        operation: operation,
        errorCode: errorCode,
        severity: severity,
        userMessage: userMessage,
        technicalMessage: error.toString(),
        stackTrace: stackTrace.toString(),
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        metadata: metadata,
        userId: userId,
        sessionId: sessionId,
      );

      // Sauvegarde en JSON avec fallback sécurisé
      try {
        await _saveLogEntry(logEntry);
      } catch (saveError) {
        // Fallback console seulement
        debugPrint('⚠️  Failed to persist log (fallback to console only)');
        if (kDebugMode) {
          debugPrint('   Log entry: ${logEntry.toJson()}');
        }
      }

    } catch (logError) {
      // Fallback ultime : seulement console (pas de crash de l'app)
      debugPrint('❌ Failed to log error: $logError');
      debugPrint('   Original error: $error');
    }
  }

  /// Sauvegarde l'entrée de log dans le stockage persistant
  static Future<void> _saveLogEntry(ErrorLogEntry entry) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');

      List<ErrorLogEntry> existingLogs = [];
      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        if (content.isNotEmpty) {
          final jsonList = jsonDecode(content) as List<dynamic>;
          existingLogs = jsonList.map((e) => ErrorLogEntry.fromJson(e)).toList();
        }
      }

      existingLogs.add(entry);

      // Garde seulement les 1000 dernières erreurs (rotation)
      if (existingLogs.length > 1000) {
        existingLogs = existingLogs.sublist(existingLogs.length - 1000);
      }

      final jsonString = jsonEncode(existingLogs.map((e) => e.toJson()).toList());
      await logFile.writeAsString(jsonString);

    } catch (e) {
      debugPrint('❌ Failed to save error log: $e');
    }
  }

  /// Récupère tous les logs pour analyse (debug uniquement)
  static Future<List<ErrorLogEntry>> getAllLogs() async {
    if (!kDebugMode) return [];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');

      if (!await logFile.exists()) return [];

      final content = await logFile.readAsString();
      if (content.isEmpty) return [];

      final jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList.map((e) => ErrorLogEntry.fromJson(e)).toList();

    } catch (e) {
      debugPrint('❌ Failed to read error logs: $e');
      return [];
    }
  }

  /// Supprime les anciens logs (garde seulement les derniers jours)
  static Future<void> cleanOldLogs({int daysToKeep = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');

      if (!await logFile.exists()) return;

      final content = await logFile.readAsString();
      if (content.isEmpty) return;

      final jsonList = jsonDecode(content) as List<dynamic>;
      final logs = jsonList.map((e) => ErrorLogEntry.fromJson(e)).toList();

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final recentLogs = logs.where((log) => log.timestamp.isAfter(cutoffDate)).toList();

      if (recentLogs.length != logs.length) {
        final jsonString = jsonEncode(recentLogs.map((e) => e.toJson()).toList());
        await logFile.writeAsString(jsonString);
        debugPrint('🧹 Cleaned ${logs.length - recentLogs.length} old error logs');
      }

    } catch (e) {
      debugPrint('❌ Failed to clean error logs: $e');
    }
  }

  /// Log une erreur de validation utilisateur
  static Future<void> logValidationError({
    required String fieldName,
    required String value,
    required String errorMessage,
    String component = 'Validation',
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      component: component,
      operation: 'validateField',
      error: 'ValidationError: $errorMessage',
      stackTrace: StackTrace.current,
      severity: ErrorSeverity.low,
      metadata: {
        'field': fieldName,
        'input_length': value.length,
        'input_preview': value.length > 50 ? '${value.substring(0, 50)}...' : value,
        ...?metadata,
      },
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'error_logger_service.dart';
import 'analytics_service.dart';

/// Métriques de crash pour monitoring proactif
class CrashMetrics {
  final String appVersion;
  final String deviceModel;
  final String osVersion;
  final int totalCrashes;
  final int fatalCrashes;
  final int nonFatalCrashes;
  final DateTime firstCrash;
  final DateTime lastCrash;
  final Map<String, int> crashesByComponent;
  final Map<String, int> crashesByOperation;
  final Map<ErrorSeverity, int> crashesBySeverity;

  CrashMetrics({
    required this.appVersion,
    required this.deviceModel,
    required this.osVersion,
    required this.totalCrashes,
    required this.fatalCrashes,
    required this.nonFatalCrashes,
    required this.firstCrash,
    required this.lastCrash,
    required this.crashesByComponent,
    required this.crashesByOperation,
    required this.crashesBySeverity,
  });

  /// Calcule le taux de crash (crashes par session)
  double getCrashRate(int totalSessions) {
    if (totalSessions == 0) return 0.0;
    return (totalCrashes / totalSessions) * 100;
  }

  /// Calcule le taux de crash fatal
  double getFatalCrashRate() {
    if (totalCrashes == 0) return 0.0;
    return (fatalCrashes / totalCrashes) * 100;
  }

  Map<String, dynamic> toJson() => {
    'app_version': appVersion,
    'device_model': deviceModel,
    'os_version': osVersion,
    'total_crashes': totalCrashes,
    'fatal_crashes': fatalCrashes,
    'non_fatal_crashes': nonFatalCrashes,
    'first_crash': firstCrash.toIso8601String(),
    'last_crash': lastCrash.toIso8601String(),
    'crashes_by_component': crashesByComponent,
    'crashes_by_operation': crashesByOperation,
    'crashes_by_severity': crashesBySeverity.map(
      (k, v) => MapEntry(k.toString().split('.').last, v),
    ),
  };
}

/// Service de métriques avancées pour monitoring proactif des crashes
/// Fournit des insights pour DevOps, Finance/Investors, Product Owner
class CrashMetricsService {
  static final CrashMetricsService _instance = CrashMetricsService._internal();
  factory CrashMetricsService() => _instance;
  CrashMetricsService._internal();

  // Clés SharedPreferences
  static const String _keyTotalCrashes = 'crash_metrics_total';
  static const String _keyFatalCrashes = 'crash_metrics_fatal';
  static const String _keyNonFatalCrashes = 'crash_metrics_non_fatal';
  static const String _keyFirstCrash = 'crash_metrics_first';
  static const String _keyLastCrash = 'crash_metrics_last';
  static const String _keyCrashesByComponent = 'crash_metrics_by_component';
  static const String _keyCrashesByOperation = 'crash_metrics_by_operation';
  static const String _keyCrashesBySeverity = 'crash_metrics_by_severity';
  static const String _keyTotalSessions = 'crash_metrics_total_sessions';
  static const String _keyCurrentSessionId = 'crash_metrics_session_id';

  // Seuils d'alerte (configurables)
  static const double _crashRateThreshold = 1.0; // 1% de taux de crash
  static const int _crashesPerDayThreshold = 10;
  static const double _fatalCrashRateThreshold = 0.1; // 0.1% de crashes fatals

  String? _currentSessionId;

  /// Initialise une nouvelle session
  Future<void> startSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Générer un ID de session unique
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await prefs.setString(_keyCurrentSessionId, _currentSessionId!);
      
      // Incrémenter le compteur de sessions
      final totalSessions = prefs.getInt(_keyTotalSessions) ?? 0;
      await prefs.setInt(_keyTotalSessions, totalSessions + 1);

      debugPrint('📊 [CrashMetrics] Session started: $_currentSessionId');
    } catch (e) {
      debugPrint('❌ [CrashMetrics] Failed to start session: $e');
    }
  }

  /// Enregistre un crash dans les métriques
  Future<void> recordCrash({
    required String component,
    required String operation,
    required ErrorSeverity severity,
    bool isFatal = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Compteurs globaux
      final totalCrashes = (prefs.getInt(_keyTotalCrashes) ?? 0) + 1;
      await prefs.setInt(_keyTotalCrashes, totalCrashes);

      if (isFatal) {
        final fatalCrashes = (prefs.getInt(_keyFatalCrashes) ?? 0) + 1;
        await prefs.setInt(_keyFatalCrashes, fatalCrashes);
      } else {
        final nonFatalCrashes = (prefs.getInt(_keyNonFatalCrashes) ?? 0) + 1;
        await prefs.setInt(_keyNonFatalCrashes, nonFatalCrashes);
      }

      // Timestamps
      if (!prefs.containsKey(_keyFirstCrash)) {
        await prefs.setString(_keyFirstCrash, now.toIso8601String());
      }
      await prefs.setString(_keyLastCrash, now.toIso8601String());

      // Crashes par component
      final crashesByComponent = _getMapFromPrefs(prefs, _keyCrashesByComponent);
      crashesByComponent[component] = (crashesByComponent[component] ?? 0) + 1;
      await _saveMapToPrefs(prefs, _keyCrashesByComponent, crashesByComponent);

      // Crashes par operation
      final crashesByOperation = _getMapFromPrefs(prefs, _keyCrashesByOperation);
      final operationKey = '$component.$operation';
      crashesByOperation[operationKey] = (crashesByOperation[operationKey] ?? 0) + 1;
      await _saveMapToPrefs(prefs, _keyCrashesByOperation, crashesByOperation);

      // Crashes par severity
      final crashesBySeverity = _getMapFromPrefs(prefs, _keyCrashesBySeverity);
      final severityKey = severity.toString().split('.').last;
      crashesBySeverity[severityKey] = (crashesBySeverity[severityKey] ?? 0) + 1;
      await _saveMapToPrefs(prefs, _keyCrashesBySeverity, crashesBySeverity);

      // Envoyer événement analytics (safe en cas d'erreur binding)
      try {
        await AnalyticsService().logEvent(
          'crash_recorded',
          parameters: {
            'component': component,
            'operation': operation,
            'severity': severityKey,
            'is_fatal': isFatal.toString(), // Convert boolean to string
            'session_id': _currentSessionId ?? 'unknown',
          },
        );
      } catch (analyticsError) {
        // Ignore analytics errors (peut échouer en test)
      }

      // Vérifier les seuils d'alerte (safe en cas d'erreur binding)
      try {
        await _checkAlertThresholds();
      } catch (alertError) {
        // Ignore alert errors (peut échouer en test)
      }

      debugPrint('📊 [CrashMetrics] Crash recorded: $component.$operation (${isFatal ? 'FATAL' : 'NON-FATAL'})');
    } catch (e) {
      debugPrint('❌ [CrashMetrics] Failed to record crash: $e');
    }
  }

  /// Récupère les métriques actuelles
  Future<CrashMetrics?> getCurrentMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get device info with proper error handling for test environments
      Map<String, String> deviceInfo = {'model': 'unknown', 'os_version': 'unknown'};
      try {
        deviceInfo = await _getDeviceInfo();
      } catch (e) {
        // Handle case where device_info is not available (e.g., in tests)
        debugPrint('⚠️  [CrashMetrics] Failed to get device info: $e');
      }
      
      // Get package info with proper error handling for test environments
      String appVersion = 'unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        // Handle case where package_info is not available (e.g., in tests)
        debugPrint('⚠️  [CrashMetrics] Failed to get package info: $e');
        appVersion = 'unknown';
      }

      final totalCrashes = prefs.getInt(_keyTotalCrashes) ?? 0;
      if (totalCrashes == 0) return null; // Pas de crashes enregistrés

      final firstCrashStr = prefs.getString(_keyFirstCrash);
      final lastCrashStr = prefs.getString(_keyLastCrash);

      if (firstCrashStr == null || lastCrashStr == null) return null;

      final crashesByComponent = _getMapFromPrefs(prefs, _keyCrashesByComponent);
      final crashesByOperation = _getMapFromPrefs(prefs, _keyCrashesByOperation);
      final crashesBySeverityStr = _getMapFromPrefs(prefs, _keyCrashesBySeverity);

      // Convertir severity strings en enum
      final crashesBySeverity = <ErrorSeverity, int>{};
      for (final entry in crashesBySeverityStr.entries) {
        final severity = ErrorSeverity.values.firstWhere(
          (s) => s.toString().split('.').last == entry.key,
          orElse: () => ErrorSeverity.medium,
        );
        crashesBySeverity[severity] = entry.value;
      }

      return CrashMetrics(
        appVersion: appVersion,
        deviceModel: deviceInfo['model'] ?? 'unknown',
        osVersion: deviceInfo['os_version'] ?? 'unknown',
        totalCrashes: totalCrashes,
        fatalCrashes: prefs.getInt(_keyFatalCrashes) ?? 0,
        nonFatalCrashes: prefs.getInt(_keyNonFatalCrashes) ?? 0,
        firstCrash: DateTime.parse(firstCrashStr),
        lastCrash: DateTime.parse(lastCrashStr),
        crashesByComponent: crashesByComponent,
        crashesByOperation: crashesByOperation,
        crashesBySeverity: crashesBySeverity,
      );
    } catch (e) {
      debugPrint('❌ [CrashMetrics] Failed to get metrics: $e');
      return null;
    }
  }

  /// Calcule le taux de crash actuel
  Future<double> getCrashRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalCrashes = prefs.getInt(_keyTotalCrashes) ?? 0;
      final totalSessions = prefs.getInt(_keyTotalSessions) ?? 0;

      // Prevent division by zero and handle edge cases
      if (totalSessions <= 0) {
        // If there are crashes but no sessions, return 100% crash rate
        // This can happen during initial testing or error conditions
        return totalCrashes > 0 ? 100.0 : 0.0;
      }
      
      return (totalCrashes / totalSessions) * 100;
    } catch (e) {
      debugPrint('❌ [CrashMetrics] Failed to calculate crash rate: $e');
      return 0.0;
    }
  }

  /// Vérifie si les seuils d'alerte sont dépassés
  Future<void> _checkAlertThresholds() async {
    try {
      final crashRate = await getCrashRate();
      
      // Alerte taux de crash global
      if (crashRate > _crashRateThreshold) {
        await _sendAlert(
          'High Crash Rate',
          'Crash rate is ${crashRate.toStringAsFixed(2)}% (threshold: $_crashRateThreshold%)',
          AlertSeverity.high,
        );
      }

      // Alerte crashes par jour
      final metrics = await getCurrentMetrics();
      if (metrics != null) {
        // Make sure we have valid dates before calculating days
        try {
          final daysSinceFirstCrash = DateTime.now().difference(metrics.firstCrash).inDays;
          if (daysSinceFirstCrash > 0) {
            final crashesPerDay = metrics.totalCrashes / daysSinceFirstCrash;
            if (crashesPerDay > _crashesPerDayThreshold) {
              await _sendAlert(
                'High Daily Crash Count',
                'Average ${crashesPerDay.toStringAsFixed(1)} crashes per day (threshold: $_crashesPerDayThreshold)',
                AlertSeverity.medium,
              );
            }
          }
        } catch (dateError) {
          // Handle potential date calculation errors
          debugPrint('⚠️  [CrashMetrics] Date calculation error: $dateError');
        }

        // Alerte taux de crash fatal
        try {
          final fatalRate = metrics.getFatalCrashRate();
          if (fatalRate > _fatalCrashRateThreshold) {
            await _sendAlert(
              'High Fatal Crash Rate',
              'Fatal crash rate is ${fatalRate.toStringAsFixed(2)}% (threshold: $_fatalCrashRateThreshold%)',
              AlertSeverity.critical,
            );
          }
        } catch (fatalRateError) {
          // Handle potential fatal rate calculation errors
          debugPrint('⚠️  [CrashMetrics] Fatal rate calculation error: $fatalRateError');
        }
      }
    } catch (e) {
      debugPrint('❌ [CrashMetrics] Failed to check alert thresholds: $e');
    }
  }

  /// Envoie une alerte (log + analytics)
  Future<void> _sendAlert(String title, String message, AlertSeverity severity) async {
    debugPrint('🚨 [CrashMetrics] ALERT [$severity] $title: $message');
    
    try {
      await AnalyticsService().logEvent(
        'crash_alert',
        parameters: {
          'title': title,
          'message': message,
          'severity': severity.toString().split('.').last,
        },
      );
    } catch (e) {
      // Ignore analytics errors (peut échouer en test)
    }
  }

  /// Réinitialise toutes les métriques (debug uniquement)
  Future<void> resetMetrics() async {
    if (!kDebugMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTotalCrashes);
      await prefs.remove(_keyFatalCrashes);
      await prefs.remove(_keyNonFatalCrashes);
      await prefs.remove(_keyFirstCrash);
      await prefs.remove(_keyLastCrash);
      await prefs.remove(_keyCrashesByComponent);
      await prefs.remove(_keyCrashesByOperation);
      await prefs.remove(_keyCrashesBySeverity);
      await prefs.remove(_keyTotalSessions);
      await prefs.remove(_keyCurrentSessionId);

      debugPrint('🧹 [CrashMetrics] All metrics reset');
    } catch (e) {
      debugPrint('❌ [CrashMetrics] Failed to reset metrics: $e');
    }
  }

  /// Affiche un rapport de stabilité (debug)
  Future<void> printStabilityReport() async {
    if (!kDebugMode) return;

    final metrics = await getCurrentMetrics();
    if (metrics == null) {
      debugPrint('📊 [CrashMetrics] No crash data available');
      return;
    }

    final crashRate = await getCrashRate();
    final prefs = await SharedPreferences.getInstance();
    final totalSessions = prefs.getInt(_keyTotalSessions) ?? 0;

    debugPrint('📊 [CrashMetrics] Stability Report:');
    debugPrint('   App Version: ${metrics.appVersion}');
    debugPrint('   Device: ${metrics.deviceModel} (${metrics.osVersion})');
    debugPrint('   Total Sessions: $totalSessions');
    debugPrint('   Total Crashes: ${metrics.totalCrashes}');
    debugPrint('   Fatal Crashes: ${metrics.fatalCrashes}');
    debugPrint('   Non-Fatal Crashes: ${metrics.nonFatalCrashes}');
    debugPrint('   Crash Rate: ${crashRate.toStringAsFixed(2)}%');
    debugPrint('   Fatal Rate: ${metrics.getFatalCrashRate().toStringAsFixed(2)}%');
    debugPrint('   First Crash: ${metrics.firstCrash}');
    debugPrint('   Last Crash: ${metrics.lastCrash}');
    debugPrint('   Top Components:');
    final sortedComponents = metrics.crashesByComponent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedComponents.take(5)) {
      debugPrint('      ${entry.key}: ${entry.value}');
    }
  }

  // Helpers

  Map<String, int> _getMapFromPrefs(SharedPreferences prefs, String key) {
    final str = prefs.getString(key);
    if (str == null || str.isEmpty) return {};
    
    try {
      final parts = str.split(',');
      final map = <String, int>{};
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          map[kv[0]] = int.tryParse(kv[1]) ?? 0;
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveMapToPrefs(SharedPreferences prefs, String key, Map<String, int> map) async {
    final str = map.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(key, str);
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'os_version': 'Android ${androidInfo.version.release}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'os_version': 'iOS ${iosInfo.systemVersion}',
        };
      }
    } catch (e) {
      // Fallback
    }
    return {'model': 'unknown', 'os_version': 'unknown'};
  }

  String? get currentSessionId => _currentSessionId;
}

/// Sévérité des alertes
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

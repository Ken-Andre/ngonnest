import 'dart:async';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'error_logger_service.dart';
import 'breadcrumb_service.dart';

/// Service de crash analytics avancé intégrant Firebase Crashlytics
/// Extension de ErrorLoggerService avec capacités de reporting en temps réel
/// Optimisé pour le marché camerounais (offline-first, faible bande passante)
class CrashAnalyticsService {
  static final CrashAnalyticsService _instance = CrashAnalyticsService._internal();
  factory CrashAnalyticsService() => _instance;
  CrashAnalyticsService._internal();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;
  String? _userId;
  String? _sessionId;

  /// Initialise Firebase Crashlytics avec configuration optimale
  Future<void> initialize({bool enableInDebug = false}) async {
    try {
      // Firebase Crashlytics uniquement sur mobile
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _crashlytics = FirebaseCrashlytics.instance;

        // Configuration: désactiver en debug par défaut (économie ressources)
        await _crashlytics!.setCrashlyticsCollectionEnabled(
          kReleaseMode || enableInDebug,
        );

        // Capturer les erreurs Flutter non gérées
        FlutterError.onError = (FlutterErrorDetails details) {
          _crashlytics!.recordFlutterFatalError(details);
          // Log local aussi pour debug offline
          ErrorLoggerService.logError(
            component: 'FlutterFramework',
            operation: 'unhandledError',
            error: details.exception,
            stackTrace: details.stack,
            severity: ErrorSeverity.critical,
          );
        };

        // Capturer les erreurs async non gérées (zone errors)
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics!.recordError(error, stack, fatal: true);
          ErrorLoggerService.logError(
            component: 'AsyncZone',
            operation: 'unhandledAsyncError',
            error: error,
            stackTrace: stack,
            severity: ErrorSeverity.critical,
          );
          return true;
        };

        // Configurer les métadonnées de l'appareil
        await _setDeviceMetadata();

        _isInitialized = true;
        debugPrint('✅ [CrashAnalytics] Firebase Crashlytics initialized');
      } else {
        debugPrint('ℹ️  [CrashAnalytics] Crashlytics not available on this platform');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CrashAnalytics] Initialization failed: $e');
      await ErrorLoggerService.logError(
        component: 'CrashAnalyticsService',
        operation: 'initialize',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Configure les métadonnées de l'appareil pour contexte crash
  Future<void> _setDeviceMetadata() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      // Version de l'app
      await _crashlytics?.setCustomKey('app_version', packageInfo.version);
      await _crashlytics?.setCustomKey('build_number', packageInfo.buildNumber);

      // Informations appareil
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        await _crashlytics?.setCustomKey('device_model', androidInfo.model);
        await _crashlytics?.setCustomKey('android_version', androidInfo.version.release);
        await _crashlytics?.setCustomKey('manufacturer', androidInfo.manufacturer);
        await _crashlytics?.setCustomKey('device_brand', androidInfo.brand);

        // Métriques importantes pour marché camerounais
        // Note: totalMemory property not available in AndroidDeviceInfo
        // Memory info would require additional system_info_plus package or native calls
        await _crashlytics?.setCustomKey('sdk_int', androidInfo.version.sdkInt.toString());
        await _crashlytics?.setCustomKey('is_physical_device', androidInfo.isPhysicalDevice.toString());
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        await _crashlytics?.setCustomKey('device_model', iosInfo.model);
        await _crashlytics?.setCustomKey('ios_version', iosInfo.systemVersion);
        await _crashlytics?.setCustomKey('device_name', iosInfo.name);
      }
    } catch (e) {
      debugPrint('⚠️  [CrashAnalytics] Failed to set device metadata: $e');
    }
  }

  /// Définit l'identifiant utilisateur pour tracking
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (_isInitialized && userId != null) {
      await _crashlytics?.setUserIdentifier(userId);
      await _crashlytics?.setCustomKey('user_id', userId);
    }
  }

  /// Définit l'identifiant de session pour tracking
  Future<void> setSessionId(String sessionId) async {
    _sessionId = sessionId;
    if (_isInitialized) {
      await _crashlytics?.setCustomKey('session_id', sessionId);
    }
  }

  /// Log une erreur non-fatale avec contexte complet
  Future<void> logNonFatalError({
    required String component,
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
  }) async {
    // Log local d'abord (offline-first)
    await ErrorLoggerService.logError(
      component: component,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      severity: severity,
      metadata: metadata,
      userId: _userId,
      sessionId: _sessionId,
    );

    // Envoyer à Firebase si initialisé et erreur suffisamment sévère
    if (_isInitialized && (severity == ErrorSeverity.high || severity == ErrorSeverity.critical)) {
      try {
        // Ajouter le contexte breadcrumb
        final breadcrumbs = await BreadcrumbService().getRecentBreadcrumbs(limit: 10);
        await _crashlytics?.setCustomKey('breadcrumbs', breadcrumbs.map((b) => b.toString()).join('\n'));

        // Ajouter métadonnées custom
        if (metadata != null) {
          for (final entry in metadata.entries) {
            await _crashlytics?.setCustomKey(entry.key, entry.value.toString());
          }
        }

        // Ajouter contexte component/operation
        await _crashlytics?.setCustomKey('component', component);
        await _crashlytics?.setCustomKey('operation', operation);
        await _crashlytics?.setCustomKey('severity', severity.toString());

        // Enregistrer l'erreur
        await _crashlytics?.recordError(
          error,
          stackTrace ?? StackTrace.current,
          reason: '$component.$operation',
          fatal: false,
        );
      } catch (e) {
        debugPrint('⚠️  [CrashAnalytics] Failed to send to Firebase: $e');
      }
    }
  }

  /// Log un crash fatal (utilisé par les error handlers)
  Future<void> logFatalCrash({
    required dynamic error,
    required StackTrace stackTrace,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    // Log local critique
    await ErrorLoggerService.logError(
      component: 'CrashHandler',
      operation: 'fatalCrash',
      error: error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.critical,
      metadata: metadata,
      userId: _userId,
      sessionId: _sessionId,
    );

    // Envoyer à Firebase
    if (_isInitialized) {
      try {
        // Ajouter breadcrumbs
        final breadcrumbs = await BreadcrumbService().getRecentBreadcrumbs(limit: 20);
        await _crashlytics?.setCustomKey('breadcrumbs', breadcrumbs.map((b) => b.toString()).join('\n'));

        if (metadata != null) {
          for (final entry in metadata.entries) {
            await _crashlytics?.setCustomKey(entry.key, entry.value.toString());
          }
        }

        await _crashlytics?.recordError(
          error,
          stackTrace,
          reason: reason ?? 'Fatal crash',
          fatal: true,
        );

        // Force l'envoi immédiat si possible
        await _crashlytics?.sendUnsentReports();
      } catch (e) {
        debugPrint('❌ [CrashAnalytics] Failed to log fatal crash: $e');
      }
    }
  }

  /// Ajoute une clé custom pour contexte additionnel
  Future<void> setCustomKey(String key, String value) async {
    if (_isInitialized) {
      await _crashlytics?.setCustomKey(key, value);
    }
  }

  /// Log un message custom dans Crashlytics
  Future<void> log(String message) async {
    if (_isInitialized) {
      await _crashlytics?.log(message);
    }
  }

  /// Teste le crash reporting (debug uniquement)
  Future<void> testCrash() async {
    if (kDebugMode && _isInitialized) {
      debugPrint('⚠️  [CrashAnalytics] Testing crash reporting...');
      _crashlytics?.crash();
    }
  }

  /// Force l'envoi des rapports non envoyés
  Future<void> sendUnsentReports() async {
    if (_isInitialized) {
      await _crashlytics?.sendUnsentReports();
    }
  }

  /// Vérifie s'il y a des rapports non envoyés
  Future<bool> checkForUnsentReports() async {
    if (_isInitialized) {
      return await _crashlytics?.checkForUnsentReports() ?? false;
    }
    return false;
  }

  /// Active/désactive la collecte Crashlytics
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    if (_isInitialized) {
      await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
    }
  }

  /// Getter pour savoir si le service est initialisé
  bool get isInitialized => _isInitialized;
}

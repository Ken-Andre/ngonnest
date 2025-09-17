import 'dart:async';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'error_logger_service.dart';

/// Service for tracking custom analytics metrics as defined in the NgonNest analytics specification
/// Implements metrics for DevOps, Finance/Investors, Product Owner, Analysts, and Marketing stakeholders
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  // ErrorLoggerService _errorLogger = ErrorLoggerService();

  // Session tracking
  DateTime? _offlineSessionStart;
  DateTime? _onboardingStartTime;
  final Map<String, DateTime> _flowStartTimes = {};

  // Preferences keys
  static const String _keyOnboardingCompleted =
      'analytics_onboarding_completed';
  static const String _keyFirstCriticalActionDone =
      'analytics_first_critical_action_done';
  static const String _keyOfflineSessionDuration =
      'analytics_offline_session_duration';

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Set up user properties
      await _setUserProperties();

      // Track app initialization
      await logEvent(
        'app_initialized',
        parameters: {
          'platform': Platform.operatingSystem,
          'app_version': await _getAppVersion(),
        },
      );
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AnalyticsService',
        operation: 'initialize',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  FirebaseAnalyticsObserver? get observer => _observer;

  // =============================================================================
  // CORE LOGGING METHODS
  // =============================================================================

  /// Log a custom event with parameters
  Future<void> logEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(name: eventName, parameters: parameters);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AnalyticsService',
        operation: 'logEvent',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set user property
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AnalyticsService',
        operation: 'setUserProperty',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // =============================================================================
  // MVP CRITICAL METRICS (Finance/Investors)
  // =============================================================================

  /// Track onboarding flow start
  Future<void> logOnboardingStarted() async {
    _onboardingStartTime = DateTime.now();
    await logEvent('onboarding_flow_started');
  }

  /// Track onboarding completion - Critical MVP metric
  Future<void> logOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);

    final duration = _onboardingStartTime != null
        ? DateTime.now().difference(_onboardingStartTime!).inSeconds
        : null;

    await logEvent(
      'onboarding_flow_completed',
      parameters: {if (duration != null) 'duration_seconds': duration},
    );
  }

  /// Track core actions - Critical MVP metric
  Future<void> logCoreAction(
    String actionType, {
    Map<String, Object>? additionalParams,
  }) async {
    final params = <String, Object>{
      'action_type': actionType,
      ...?additionalParams,
    };

    await logEvent('core_action', parameters: params);

    // Track first critical action timing
    await _trackFirstCriticalAction(actionType);
  }

  /// Track first critical action for time-to-value metric
  Future<void> _trackFirstCriticalAction(String actionType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_keyFirstCriticalActionDone}_$actionType';

    final firstActionValue = prefs.getBool(key) ?? false;
    if (!firstActionValue) {
      await prefs.setBool(key, true);

      final onboardingCompleted =
          prefs.getBool(_keyOnboardingCompleted) ?? false;
      if (onboardingCompleted) {
        await logEvent(
          'first_critical_action',
          parameters: {'action_type': actionType},
        );
      }
    }
  }

  // =============================================================================
  // MVP CRITICAL METRICS (Product Owner - UX Flow Efficiency)
  // =============================================================================

  /// Start tracking a UX flow - Critical MVP metric
  Future<void> logFlowStarted(String flowName) async {
    _flowStartTimes[flowName] = DateTime.now();
    await logEvent('flow_started', parameters: {'flow_name': flowName});
  }

  /// Complete a UX flow - Critical MVP metric
  Future<void> logFlowCompleted(
    String flowName, {
    Map<String, Object>? additionalParams,
  }) async {
    final startTime = _flowStartTimes[flowName];
    final duration = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;

    _flowStartTimes.remove(flowName);

    final params = <String, Object>{
      'flow_name': flowName,
      if (duration != null) 'duration_ms': duration,
      ...?additionalParams,
    };

    await logEvent('flow_completed', parameters: params);
  }

  /// Abandon a UX flow
  Future<void> logFlowAbandoned(String flowName, {String? reason}) async {
    final startTime = _flowStartTimes[flowName];
    final duration = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;

    _flowStartTimes.remove(flowName);

    await logEvent(
      'flow_abandoned',
      parameters: {
        'flow_name': flowName,
        if (duration != null) 'duration_ms': duration,
        if (reason != null) 'reason': reason,
      },
    );
  }

  // =============================================================================
  // MVP HIGH PRIORITY METRICS (DevOps)
  // =============================================================================

  /// Start offline session tracking - High MVP priority
  Future<void> logOfflineSessionStarted() async {
    _offlineSessionStart = DateTime.now();
    await logEvent('offline_session_started');
  }

  /// End offline session tracking - High MVP priority
  Future<void> logOfflineSessionEnded() async {
    if (_offlineSessionStart != null) {
      final duration = DateTime.now().difference(_offlineSessionStart!);
      _offlineSessionStart = null;

      // Store cumulative offline duration
      final prefs = await SharedPreferences.getInstance();
      final totalDuration = prefs.getInt(_keyOfflineSessionDuration) ?? 0;
      await prefs.setInt(
        _keyOfflineSessionDuration,
        totalDuration + duration.inSeconds,
      );

      await logEvent(
        'offline_session_ended',
        parameters: {'duration_seconds': duration.inSeconds},
      );
    }
  }

  /// Track database migration attempts - High MVP priority
  Future<void> logMigrationAttempt(int fromVersion, int toVersion) async {
    await logEvent(
      'migration_attempt',
      parameters: {'from_version': fromVersion, 'to_version': toVersion},
    );
  }

  /// Track database migration success - High MVP priority
  Future<void> logMigrationSuccess(
    int fromVersion,
    int toVersion,
    int durationMs,
  ) async {
    await logEvent(
      'migration_completed',
      parameters: {
        'from_version': fromVersion,
        'to_version': toVersion,
        'duration_ms': durationMs,
        'status': 'success',
      },
    );
  }

  /// Track database migration failure - High MVP priority
  Future<void> logMigrationFailure(
    int fromVersion,
    int toVersion,
    String errorCode,
  ) async {
    await logEvent(
      'migration_completed',
      parameters: {
        'from_version': fromVersion,
        'to_version': toVersion,
        'status': 'failure',
        'error_code': errorCode,
      },
    );
  }

  // =============================================================================
  // POST-MVP METRICS (Medium Priority)
  // =============================================================================

  /// Track sync attempts
  Future<void> logSyncAttemptStarted() async {
    await logEvent('sync_attempt_started');
  }

  /// Track sync completion
  Future<void> logSyncAttemptEnded(bool success, {String? errorCode}) async {
    await logEvent(
      'sync_attempt_ended',
      parameters: {
        'status': success ? 'success' : 'failure',
        if (!success && errorCode != null) 'error_code': errorCode,
      },
    );
  }

  /// Track database operation performance
  Future<void> logDatabaseOperation(
    String operationType,
    int durationMs,
  ) async {
    await logEvent(
      'db_operation',
      parameters: {'operation_type': operationType, 'duration_ms': durationMs},
    );
  }

  /// Track feature first use
  Future<void> logFeatureFirstUse(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'feature_first_use_$featureName';

    final featureUsed = prefs.getBool(key) ?? false;
    if (!featureUsed) {
      await prefs.setBool(key, true);
      await logEvent(
        'feature_first_use',
        parameters: {'feature_name': featureName},
      );
    }
  }

  /// Track empty state CTA interactions
  Future<void> logEmptyStateCTAClicked(String emptyStateScreen) async {
    await logEvent(
      'empty_state_cta_clicked',
      parameters: {'empty_state_screen': emptyStateScreen},
    );
  }

  /// Track settings changes
  Future<void> logSettingChanged(String settingName, String newValue) async {
    await logEvent(
      'setting_changed',
      parameters: {'setting_name': settingName, 'new_value': newValue},
    );
  }

  /// Track alert feedback (if feedback system is implemented)
  Future<void> logAlertFeedback(String alertId, String feedbackValue) async {
    await logEvent(
      'alert_feedback',
      parameters: {
        'alert_id': alertId,
        'feedback_value': feedbackValue, // 'useful' or 'not_useful'
      },
    );
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Set up user properties based on device and household info
  Future<void> _setUserProperties() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        await setUserProperty('device_model', androidInfo.model);
        await setUserProperty('android_version', androidInfo.version.release);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        await setUserProperty('device_model', iosInfo.model);
        await setUserProperty('ios_version', iosInfo.systemVersion);
      }

      // Check for low storage
      await _checkAndSetLowStorageProperty();
    } catch (e, stackTrace) {
      // Note: LogError method may not exist, using print for now
      debugPrint('AnalyticsService Error in _setUserProperties: $e');
      await ErrorLoggerService.logError(
        component: 'AnalyticsService',
        operation: '_setUserProperties',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check for low storage and set user property
  Future<void> _checkAndSetLowStorageProperty() async {
    try {
      // This is a simplified check - in production you might want more sophisticated logic
      final prefs = await SharedPreferences.getInstance();
      final hasLowStorage = prefs.getBool('has_low_storage') ?? false;

      if (hasLowStorage) {
        await setUserProperty('low_storage', 'true');
        await logEvent('low_storage_detected');
      }
    } catch (e) {
      // Ignore storage check errors
    }
  }

  /// Set household profile properties for segmentation
  Future<void> setHouseholdProfile({
    required int householdSize,
    String? householdType,
    String? primaryLanguage,
  }) async {
    await setUserProperty('household_size', householdSize.toString());
    if (householdType != null) {
      await setUserProperty('household_type', householdType);
    }
    if (primaryLanguage != null) {
      await setUserProperty('primary_language', primaryLanguage);
    }
  }

  /// Get app version for tracking
  Future<String> _getAppVersion() async {
    try {
      // This would typically use package_info_plus
      return '1.0.0'; // Placeholder
    } catch (e) {
      return 'unknown';
    }
  }

  /// Track connectivity changes for offline/online transitions
  Future<void> trackConnectivityChange(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      await logOfflineSessionStarted();
    } else {
      await logOfflineSessionEnded();
    }
  }

  // =============================================================================
  // CONVENIENCE METHODS FOR COMMON ACTIONS
  // =============================================================================

  /// Track item-related actions (core functionality)
  Future<void> logItemAction(
    String action, {
    Map<String, Object>? params,
  }) async {
    await logCoreAction('item_$action', additionalParams: params);
  }

  /// Track inventory-related actions
  Future<void> logInventoryAction(
    String action, {
    Map<String, Object>? params,
  }) async {
    await logCoreAction('inventory_$action', additionalParams: params);
  }

  /// Track alert-related actions
  Future<void> logAlertAction(
    String action, {
    Map<String, Object>? params,
  }) async {
    await logCoreAction('alert_$action', additionalParams: params);
  }

  /// Track budget-related actions
  Future<void> logBudgetAction(
    String action, {
    Map<String, Object>? params,
  }) async {
    await logCoreAction('budget_$action', additionalParams: params);
  }
}

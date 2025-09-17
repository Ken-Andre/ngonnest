import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:ngonnest_app/services/remote_config_service.dart';

class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Feature flag keys - add all your feature flags here
  static const String _premiumBannerKey = 'feature_premium_banner_enabled';
  static const String _advancedAnalyticsKey = 'feature_advanced_analytics';
  static const String _maintenanceModeKey = 'maintenance_mode';
  static const String _appUpdateRequiredKey = 'app_update_required';
  
  // Initialize the service
  Future<void> initialize() async {
    await _remoteConfig.initialize();
  }
  
  // Check if a feature is enabled
  bool isFeatureEnabled(String featureKey) {
    try {
      return _remoteConfig.getBool(featureKey);
    } catch (e) {
      log('Error checking feature flag $featureKey: $e', name: 'FeatureFlagService');
      return false;
    }
  }
  
  // Check if premium banner is enabled
  bool get isPremiumBannerEnabled => isFeatureEnabled(_premiumBannerKey);
  
  // Check if advanced analytics is enabled
  bool get isAdvancedAnalyticsEnabled => isFeatureEnabled(_advancedAnalyticsKey);
  
  // Check if app is in maintenance mode
  bool get isMaintenanceMode => isFeatureEnabled(_maintenanceModeKey);
  
  // Check if app update is required
  bool get isUpdateRequired => isFeatureEnabled(_appUpdateRequiredKey);
  
  // Get the required app version
  String get requiredAppVersion => _remoteConfig.requiredAppVersion;
  
  // Get the current A/B test variant
  String get abTestVariant => _remoteConfig.abTestVariant;
  
  // Track feature exposure for A/B testing
  Future<void> trackFeatureExposure(String featureName) async {
    if (!isAdvancedAnalyticsEnabled) return;
    
    try {
      await _analytics.logEvent(
        name: 'feature_exposure',
        parameters: {
          'feature_name': featureName,
          'variant': abTestVariant,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      log('Error tracking feature exposure: $e', name: 'FeatureFlagService');
    }
  }
  
  // Track feature usage
  Future<void> trackFeatureUsage(String featureName, {Map<String, dynamic>? parameters}) async {
    if (!isAdvancedAnalyticsEnabled) return;
    
    try {
      final eventParams = {
        'feature_name': featureName,
        'variant': abTestVariant,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (parameters != null) {
        eventParams.addAll(Map<String, String>.from(parameters));
      }
      
      await _analytics.logEvent(
        name: 'feature_usage',
        parameters: eventParams,
      );
    } catch (e) {
      log('Error tracking feature usage: $e', name: 'FeatureFlagService');
    }
  }
  
  // Force refresh feature flags from remote
  Future<void> refresh() async {
    await _remoteConfig.forceFetch();
  }
  
  // Get all feature flags as a map
  Map<String, dynamic> getAllFeatureFlags() {
    return {
      _premiumBannerKey: isPremiumBannerEnabled,
      _advancedAnalyticsKey: isAdvancedAnalyticsEnabled,
      _maintenanceModeKey: isMaintenanceMode,
      _appUpdateRequiredKey: isUpdateRequired,
      'required_app_version': requiredAppVersion,
      'ab_test_variant': abTestVariant,
    };
  }
  
  // Check if the current app version meets the required version
  bool isAppVersionCompatible(String currentVersion) {
    try {
      if (requiredAppVersion.isEmpty) return true;
      
      final currentParts = currentVersion.split('.');
      final requiredParts = requiredAppVersion.split('.');
      
      for (int i = 0; i < requiredParts.length; i++) {
        final current = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
        final required = int.tryParse(requiredParts[i]) ?? 0;
        
        if (current > required) return true;
        if (current < required) return false;
      }
      
      return true;
    } catch (e) {
      log('Error checking app version compatibility: $e', name: 'FeatureFlagService');
      return true; // Default to compatible if there's an error
    }
  }
}

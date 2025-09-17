import 'dart:developer';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:ngonnest_app/services/remote_config_service.dart';

class ABTestingService {
  static final ABTestingService _instance = ABTestingService._internal();
  factory ABTestingService() => _instance;
  ABTestingService._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Experiment keys - define all your A/B test experiments here
  static const String _homepageLayoutExperiment = 'homepage_layout_v1';
  static const String _ctaButtonColorExperiment = 'cta_button_color_v1';
  
  // Experiment variants
  static const String _variantControl = 'control';
  static const String _variantA = 'variant_a';
  static const String _variantB = 'variant_b';
  
  // Initialize the service
  Future<void> initialize() async {
    await _remoteConfig.initialize();
  }
  
  // Get the variant for an experiment
  String getExperimentVariant(String experimentKey) {
    try {
      return _remoteConfig.getString('${experimentKey}_variant') ?? _variantControl;
    } catch (e) {
      log('Error getting experiment variant for $experimentKey: $e', name: 'ABTestingService');
      return _variantControl;
    }
  }
  
  // Get the homepage layout variant
  String get homepageLayoutVariant => getExperimentVariant(_homepageLayoutExperiment);
  
  // Get the CTA button color variant
  String get ctaButtonColorVariant => getExperimentVariant(_ctaButtonColorExperiment);
  
  // Track experiment exposure
  Future<void> trackExperimentExposure(String experimentKey) async {
    try {
      final variant = getExperimentVariant(experimentKey);
      
      await _analytics.logEvent(
        name: 'experiment_exposure',
        parameters: {
          'experiment_name': experimentKey,
          'variant': variant,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      log('Error tracking experiment exposure: $e', name: 'ABTestingService');
    }
  }
  
  // Track experiment conversion
  Future<void> trackExperimentConversion(
    String experimentKey, 
    String conversionEvent, {
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final variant = getExperimentVariant(experimentKey);
      
      final params = {
        'experiment_name': experimentKey,
        'variant': variant,
        'conversion_event': conversionEvent,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (additionalParams != null) {
params.addAll(Map<String, String>.from(additionalParams));
      }
      
      await _analytics.logEvent(
        name: 'experiment_conversion',
        parameters: params,
      );
    } catch (e) {
      log('Error tracking experiment conversion: $e', name: 'ABTestingService');
    }
  }
  
  // Get all active experiments and their variants
  Map<String, String> getAllActiveExperiments() {
    return {
      _homepageLayoutExperiment: getExperimentVariant(_homepageLayoutExperiment),
      _ctaButtonColorExperiment: getExperimentVariant(_ctaButtonColorExperiment),
    };
  }
  
  // Check if a specific variant is active for an experiment
  bool isVariantActive(String experimentKey, String variant) {
    return getExperimentVariant(experimentKey) == variant;
  }
  
  // Get a feature flag with experiment override
  bool getFeatureWithExperiment(
    String featureKey, 
    String experimentKey, 
    Map<String, bool> variantOverrides,
  ) {
    try {
      final variant = getExperimentVariant(experimentKey);
      return variantOverrides[variant] ?? _remoteConfig.getBool(featureKey);
    } catch (e) {
      log('Error getting feature with experiment: $e', name: 'ABTestingService');
      return _remoteConfig.getBool(featureKey) ?? false;
    }
  }
  
  // Get a dynamic value with experiment override
  T getValueWithExperiment<T>(
    String key, 
    String experimentKey, 
    Map<String, T> variantOverrides, {
    required T defaultValue,
  }) {
    try {
      final variant = getExperimentVariant(experimentKey);
      return variantOverrides[variant] ?? _getConfigValue(key, defaultValue);
    } catch (e) {
      log('Error getting value with experiment: $e', name: 'ABTestingService');
      return _getConfigValue(key, defaultValue);
    }
  }
  
  // Helper method to get typed config value
  T _getConfigValue<T>(String key, T defaultValue) {
    if (T == bool) {
      return (_remoteConfig.getBool(key) ?? (defaultValue as bool)) as T;
    } else if (T == int) {
      return (_remoteConfig.getInt(key) ?? (defaultValue as int)) as T;
    } else if (T == double) {
      return (_remoteConfig.getDouble(key) ?? (defaultValue as double)) as T;
    } else if (T == String) {
      return (_remoteConfig.getString(key) ?? (defaultValue as String)) as T;
    }
    return defaultValue;
  }
  
  // Force refresh experiments from remote
  Future<void> refresh() async {
    await _remoteConfig.forceFetch();
  }
}

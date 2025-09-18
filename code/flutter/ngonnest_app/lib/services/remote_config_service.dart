import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  static const String _lastFetchTimeKey = 'last_fetch_time';
  static const Duration _minimumFetchInterval = Duration(hours: 1);

  // In-memory cache for config values
  final Map<String, dynamic> _configCache = {};

  // Default values for all parameters
  static const Map<String, dynamic> _defaults = const <String, dynamic>{
    // Feature Flags
    'feature_premium_banner_enabled': false,
    'feature_advanced_analytics': true,
    'maintenance_mode': false,
    'app_update_required': false,
    'emergency_rollback': false,

    // Premium Banner Content
    'premium_banner_title': 'Upgrade to Premium',
    'premium_banner_description': 'Unlock advanced features and unlimited storage',

    // Dynamic Content
    'welcome_message': 'Welcome to NgonNest',
    'ui_home_banner_content': 'default_banner',

    // A/B Testing Variants
    'homepage_layout_v1_variant': 'control',
    'cta_button_color_v1_variant': 'control',
    'a_b_test_variant': 'control',

    // App Version Control
    'app_version_required': '1.0.0',

    // Onboarding Flow
    'onboarding_steps': '{"steps": ["Welcome", "Setup Profile", "Add Items", "Done"]}',

    // Premium Features List
    'premium_features_list': '{"features": ["Unlimited Items", "Advanced Analytics", "Priority Support"]}',
  };

  Future<void> initialize() async {
    try {
      // Load cached config values
      await _loadCachedConfig();

      // Only try Firebase operations on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // In development, simulate Firebase Remote Config behavior
        if (kDebugMode) {
          await _simulateRemoteConfigFetch();
        }
      }

      debugPrint('Remote Config initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
      // Load defaults in case of error
      _configCache.addAll(_defaults);
    }
  }

  Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _configCache.clear();

      // Load defaults first
      _configCache.addAll(_defaults);

      // Load any cached values (simulating Firebase behavior)
      for (final key in _defaults.keys) {
        final cachedValue = prefs.get(key);
        if (cachedValue != null) {
          _configCache[key] = cachedValue;
        }
      }
    } catch (e) {
      debugPrint('Error loading cached config: $e');
    }
  }

  Future<void> _simulateRemoteConfigFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt(_lastFetchTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Simulate fetch delay
      if (now - lastFetchTime > _minimumFetchInterval.inMilliseconds) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

        // In development, you can modify these values to test different scenarios
        _configCache['feature_premium_banner_enabled'] = true; // Enable for testing
        _configCache['welcome_message'] = 'Welcome to NgonNest (Dev Mode)';

        await prefs.setInt(_lastFetchTimeKey, now);

        // Cache the values
        for (final entry in _configCache.entries) {
          if (entry.value is String) {
            await prefs.setString(entry.key, entry.value as String);
          } else if (entry.value is bool) {
            await prefs.setBool(entry.key, entry.value as bool);
          } else if (entry.value is int) {
            await prefs.setInt(entry.key, entry.value as int);
          } else if (entry.value is double) {
            await prefs.setDouble(entry.key, entry.value as double);
          }
        }
      }
    } catch (e) {
      debugPrint('Error simulating remote config fetch: $e');
    }
  }

  // Getters for different value types
  bool getBool(String key) => _configCache[key] as bool? ?? _defaults[key] as bool? ?? false;
  String getString(String key) => _configCache[key] as String? ?? _defaults[key] as String? ?? '';
  int getInt(String key) => _configCache[key] as int? ?? _defaults[key] as int? ?? 0;
  double getDouble(String key) => _configCache[key] as double? ?? _defaults[key] as double? ?? 0.0;

  // Helper methods for specific features
  bool get isPremiumBannerEnabled => getBool('feature_premium_banner_enabled');
  bool get isMaintenanceMode => getBool('maintenance_mode');
  bool get isUpdateRequired => getBool('app_update_required');
  String get requiredAppVersion => getString('app_version_required');
  String get abTestVariant => getString('a_b_test_variant');
  String get homepageLayoutVariant => getString('homepage_layout_v1_variant');
  String get ctaButtonColorVariant => getString('cta_button_color_v1_variant');

  // Get JSON data as Map
  Map<String, dynamic> getJson(String key) {
    try {
      final jsonString = getString(key);
      return jsonString.isNotEmpty
          ? Map<String, dynamic>.from(json.decode(jsonString))
          : {};
    } catch (e) {
      debugPrint('Error parsing JSON from Remote Config: $e');
      return {};
    }
  }

  // Force fetch the latest values (simulated in development)
  Future<void> forceFetch() async {
    if (kDebugMode) {
      await _simulateRemoteConfigFetch();
    } else {
      // In production, this would trigger actual Firebase Remote Config fetch
      debugPrint('Force fetch called (production mode - implement Firebase Remote Config)');
    }
  }

  // Get all config values for debugging
  Map<String, dynamic> getAllConfig() => Map<String, dynamic>.from(_configCache);
}

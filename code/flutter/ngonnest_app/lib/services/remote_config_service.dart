import 'dart:convert';
import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static const String _lastFetchTimeKey = 'last_fetch_time';
  static const Duration _minimumFetchInterval = Duration(hours: 1);

  // Default values for all parameters
  static const Map<String, dynamic> _defaults = const <String, dynamic>{
    'feature_premium_banner_enabled': false,
    'feature_advanced_analytics': true,
    'ui_home_banner_content': 'default_banner',
    'app_version_required': '1.0.0',
    'maintenance_mode': false,
    'app_update_required': false,
    'a_b_test_variant': 'control',
  };

  Future<void> initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults(_defaults);
      
      // Set fetch timeout and minimum fetch interval
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: _minimumFetchInterval,
        ),
      );

      // Fetch and activate config
      await _fetchAndActivate();
      
      // Listen for updates in the background
      _remoteConfig.onConfigUpdated.listen(
        (_) async => await _fetchAndActivate(),
      );
      
      // Enable debug mode in development
      if (kDebugMode) {
        await _remoteConfig.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: Duration.zero,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
      // Activate defaults in case of error
      await _remoteConfig.setDefaults(_defaults);
    }
  }

  Future<void> _fetchAndActivate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt(_lastFetchTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Only fetch if enough time has passed
      if (now - lastFetchTime > _minimumFetchInterval.inMilliseconds) {
        await _remoteConfig.fetchAndActivate();
        await prefs.setInt(_lastFetchTimeKey, now);
      }
    } catch (e) {
      debugPrint('Error fetching Remote Config: $e');
    }
  }

  // Getters for different value types
  bool getBool(String key) => _remoteConfig.getBool(key);
  String getString(String key) => _remoteConfig.getString(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);
  
  // Helper methods for specific features
  bool get isPremiumBannerEnabled => getBool('feature_premium_banner_enabled');
  bool get isMaintenanceMode => getBool('maintenance_mode');
  bool get isUpdateRequired => getBool('app_update_required');
  String get requiredAppVersion => getString('app_version_required');
  String get abTestVariant => getString('a_b_test_variant');
  
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
  
  // Force fetch the latest values from the server
  Future<void> forceFetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error forcing Remote Config fetch: $e');
    }
  }
}

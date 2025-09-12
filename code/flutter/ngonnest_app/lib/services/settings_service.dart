import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const String _languageKey = 'language';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationFrequencyKey = 'notification_frequency';
  static const String _localDataOnlyKey = 'local_data_only';
  static const String _themeModeKey = 'theme_mode';
  static const String _lastSyncKey = 'last_sync';
  static const String _localDataOnlyKey = 'local_data_only';
  static const String _cloudSyncAcceptedKey = 'cloud_sync_accepted';
  static const String _notificationFrequencyKey = 'notification_frequency';

  static SharedPreferences? _prefs;

  /// Initialize the settings service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the current language setting
  static Future<String> getLanguage() async {
    await initialize();
    return _prefs!.getString(_languageKey) ??
        'fr'; // Default to French for Cameroon market
  }

  /// Set the language setting
  static Future<bool> setLanguage(String languageCode) async {
    await initialize();
    return _prefs!.setString(_languageKey, languageCode);
  }

  /// Get notifications enabled setting
  static Future<bool> getNotificationsEnabled() async {
    await initialize();
    return _prefs!.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Set notifications enabled setting
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    await initialize();
    return _prefs!.setBool(_notificationsEnabledKey, enabled);
  }


  /// Get if user has accepted cloud synchronization
  static Future<bool> getCloudSyncAccepted() async {
    await initialize();
    return _prefs!.getBool(_cloudSyncAcceptedKey) ?? false;
  }



  /// Get notification frequency setting
  static Future<String> getNotificationFrequency() async {
    await initialize();
    return _prefs!.getString(_notificationFrequencyKey) ?? 'quotidienne';
  }

  /// Set notification frequency setting
  static Future<bool> setNotificationFrequency(String frequency) async {
    await initialize();
    return _prefs!.setString(_notificationFrequencyKey, frequency);
  }

  /// Get local data only mode setting
  static Future<bool> getLocalDataOnly() async {
    await initialize();
    return _prefs!.getBool(_localDataOnlyKey) ?? true;
  }

  /// Set local data only mode setting
  static Future<bool> setLocalDataOnly(bool value) async {
    await initialize();
    return _prefs!.setBool(_localDataOnlyKey, value);
  }

  /// Get theme mode setting
  static Future<ThemeMode> getThemeMode() async {
    await initialize();
    final themeModeString = _prefs!.getString(_themeModeKey) ?? 'system';
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode setting
  static Future<bool> setThemeMode(ThemeMode themeMode) async {
    await initialize();
    String themeModeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
        break;
    }
    return _prefs!.setString(_themeModeKey, themeModeString);
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    await initialize();
    final timestamp = _prefs!.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Set last sync time
  static Future<bool> setLastSyncTime(DateTime dateTime) async {
    await initialize();
    return _prefs!.setInt(_lastSyncKey, dateTime.millisecondsSinceEpoch);
  }

  /// Clear all settings (for testing or reset)
  static Future<bool> clearAll() async {
    await initialize();
    return _prefs!.clear();
  }

  /// Get all settings as a map (for debugging)
  static Future<Map<String, dynamic>> getAllSettings() async {
    await initialize();
    final keys = _prefs!.getKeys();
    final Map<String, dynamic> settings = {};
    for (String key in keys) {
      settings[key] = _prefs!.get(key);
    }
    return settings;
  }
}

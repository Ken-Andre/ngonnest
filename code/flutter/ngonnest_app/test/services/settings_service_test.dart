import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    setUp(() async {
      // Clear all preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return default language as French', () async {
      final language = await SettingsService.getLanguage();
      expect(language, 'fr');
    });

    test('should save and retrieve language setting', () async {
      await SettingsService.setLanguage('en');
      final language = await SettingsService.getLanguage();
      expect(language, 'en');
    });

    test('should return default notifications enabled as true', () async {
      final enabled = await SettingsService.getNotificationsEnabled();
      expect(enabled, true);
    });

    test('should save and retrieve notifications setting', () async {
      await SettingsService.setNotificationsEnabled(false);
      final enabled = await SettingsService.getNotificationsEnabled();
      expect(enabled, false);
    });

    test('should return default theme mode as system', () async {
      final themeMode = await SettingsService.getThemeMode();
      expect(themeMode, ThemeMode.system);
    });

    test('should save and retrieve theme mode setting', () async {
      await SettingsService.setThemeMode(ThemeMode.dark);
      final themeMode = await SettingsService.getThemeMode();
      expect(themeMode, ThemeMode.dark);
    });

    test('should save and retrieve last sync time', () async {
      final now = DateTime.now();
      await SettingsService.setLastSyncTime(now);
      final lastSync = await SettingsService.getLastSyncTime();

      expect(lastSync, isNotNull);
      expect(lastSync!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('should return null for last sync time when not set', () async {
      // Ensure clean state
      await SettingsService.clearAll();
      final lastSync = await SettingsService.getLastSyncTime();
      expect(lastSync, isNull);
    });

    test('should clear all settings', () async {
      // Set some values
      await SettingsService.setLanguage('en');
      await SettingsService.setNotificationsEnabled(false);
      await SettingsService.setThemeMode(ThemeMode.dark);

      // Clear all
      await SettingsService.clearAll();

      // Check defaults are restored
      expect(await SettingsService.getLanguage(), 'fr');
      expect(await SettingsService.getNotificationsEnabled(), true);
      expect(await SettingsService.getThemeMode(), ThemeMode.system);
    });

    test('should get all settings as map', () async {
      await SettingsService.setLanguage('en');
      await SettingsService.setNotificationsEnabled(false);

      final settings = await SettingsService.getAllSettings();

      expect(settings['language'], 'en');
      expect(settings['notifications_enabled'], false);
    });
  });
}

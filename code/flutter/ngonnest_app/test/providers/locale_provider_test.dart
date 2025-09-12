import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/providers/locale_provider.dart';
import 'package:ngonnest_app/services/settings_service.dart';

void main() {
  group('LocaleProvider', () {
    setUp(() async {
      // Clear all preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize with French locale by default', () async {
      final provider = LocaleProvider();
      await provider.initialize();

      expect(provider.locale.languageCode, 'fr');
    });

    test('should initialize with saved locale', () async {
      // First set the language using SettingsService
      await SettingsService.setLanguage('en');

      final provider = LocaleProvider();
      await provider.initialize();

      expect(provider.locale.languageCode, 'en');
    });

    test('should change locale and persist it', () async {
      final provider = LocaleProvider();
      await provider.initialize();

      // Change to English
      await provider.setLocale(const Locale('en'));

      expect(provider.locale.languageCode, 'en');

      // Verify it was persisted using SettingsService
      final language = await SettingsService.getLanguage();
      expect(language, 'en');
    });

    test('should not change if same locale is set', () async {
      final provider = LocaleProvider();
      await provider.initialize();

      final initialLocale = provider.locale;
      await provider.setLocale(initialLocale);

      expect(provider.locale, initialLocale);
    });

    test('should return correct supported locales', () {
      final supportedLocales = LocaleProvider.supportedLocales;

      expect(supportedLocales.length, 3);
      expect(supportedLocales.any((l) => l.languageCode == 'fr'), true);
      expect(supportedLocales.any((l) => l.languageCode == 'en'), true);
      expect(supportedLocales.any((l) => l.languageCode == 'es'), true);
    });

    test('should return correct display names', () {
      final provider = LocaleProvider();

      expect(provider.getLocaleDisplayName(const Locale('fr')), 'Français');
      expect(provider.getLocaleDisplayName(const Locale('en')), 'English');
      expect(provider.getLocaleDisplayName(const Locale('es')), 'Español');
      expect(provider.getLocaleDisplayName(const Locale('de')), 'de');
    });

    test('should check if locale is supported', () {
      final provider = LocaleProvider();

      expect(provider.isSupported(const Locale('fr')), true);
      expect(provider.isSupported(const Locale('en')), true);
      expect(provider.isSupported(const Locale('es')), true);
      expect(provider.isSupported(const Locale('de')), false);
    });
  });
}

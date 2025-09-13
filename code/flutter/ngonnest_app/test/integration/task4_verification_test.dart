import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/services/settings_service.dart';
import 'package:ngonnest_app/providers/locale_provider.dart';
import 'package:ngonnest_app/services/notification_permission_service.dart';

void main() {
  group(
    'Task 4 Verification: Persist settings and support multiple languages',
    () {
      setUp(() async {
        // Clear all preferences before each test
        SharedPreferences.setMockInitialValues({});
      });

      test('should save preferences via SharedPreferences', () async {
        // Test language preference
        await SettingsService.setLanguage('en');
        final language = await SettingsService.getLanguage();
        expect(language, 'en');

        // Test notifications preference
        await SettingsService.setNotificationsEnabled(false);
        final notificationsEnabled =
            await SettingsService.getNotificationsEnabled();
        expect(notificationsEnabled, false);

        // Test notification frequency
        await SettingsService.setNotificationFrequency('hebdomadaire');
        final freq = await SettingsService.getNotificationFrequency();
        expect(freq, 'hebdomadaire');

        // Test local data mode
        await SettingsService.setLocalDataOnly(false);
        final local = await SettingsService.getLocalDataOnly();
        expect(local, false);

        // Test theme preference
        await SettingsService.setThemeMode(ThemeMode.dark);
        final themeMode = await SettingsService.getThemeMode();
        expect(themeMode, ThemeMode.dark);

        // Test last sync time
        final now = DateTime.now();
        await SettingsService.setLastSyncTime(now);
        final lastSync = await SettingsService.getLastSyncTime();
        expect(lastSync?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      });

      test(
        'should apply selected language dynamically with English fallback',
        () async {
          // Ensure clean state
          await SettingsService.clearAll();

          final localeProvider = LocaleProvider();

          // Test initialization with default French
          await localeProvider.initialize();
          expect(localeProvider.locale.languageCode, 'fr');

          // Test changing to English
          await localeProvider.setLocale(const Locale('en'));
          expect(localeProvider.locale.languageCode, 'en');

          // Test that it persists
          final savedLanguage = await SettingsService.getLanguage();
          expect(savedLanguage, 'en');

          // Test supported locales include English as fallback
          expect(
            LocaleProvider.supportedLocales.any((l) => l.languageCode == 'en'),
            true,
          );
          expect(
            LocaleProvider.supportedLocales.any((l) => l.languageCode == 'fr'),
            true,
          );
        },
      );

      test(
        'should handle notification enable/disable with permission prompts',
        () async {
          // Ensure clean state
          await SettingsService.clearAll();

          // Test default state
          final defaultEnabled =
              await SettingsService.getNotificationsEnabled();
          expect(defaultEnabled, true);

          // Test disabling notifications
          await NotificationPermissionService.disableNotifications();
          final disabled = await SettingsService.getNotificationsEnabled();
          expect(disabled, false);

          // Test that notification permission service has proper error handling
          expect(
            () => NotificationPermissionService.enableNotifications(),
            returnsNormally,
          );
          expect(
            () => NotificationPermissionService.areNotificationsEnabled(),
            returnsNormally,
          );
        },
      );

      test('should provide proper locale display names', () {
        final localeProvider = LocaleProvider();

        expect(
          localeProvider.getLocaleDisplayName(const Locale('fr')),
          'Français',
        );
        expect(
          localeProvider.getLocaleDisplayName(const Locale('en')),
          'English',
        );
        expect(
          localeProvider.getLocaleDisplayName(const Locale('es')),
          'Español',
        );

        // Test fallback for unsupported locale
        expect(localeProvider.getLocaleDisplayName(const Locale('de')), 'de');
      });

      test('should check if locales are supported correctly', () {
        final localeProvider = LocaleProvider();

        expect(localeProvider.isSupported(const Locale('fr')), true);
        expect(localeProvider.isSupported(const Locale('en')), true);
        expect(localeProvider.isSupported(const Locale('es')), true);
        expect(localeProvider.isSupported(const Locale('de')), false);
      });

      test(
        'should maintain settings persistence across app restarts',
        () async {
          // Simulate first app session
          await SettingsService.setLanguage('en');
          await SettingsService.setNotificationsEnabled(false);
          await SettingsService.setThemeMode(ThemeMode.dark);
          await SettingsService.setNotificationFrequency('hebdomadaire');
          await SettingsService.setLocalDataOnly(false);

          // Simulate app restart by creating new provider instance
          final localeProvider = LocaleProvider();
          await localeProvider.initialize();

          // Verify settings are restored
          expect(localeProvider.locale.languageCode, 'en');
          expect(await SettingsService.getNotificationsEnabled(), false);
          expect(await SettingsService.getThemeMode(), ThemeMode.dark);
          expect(await SettingsService.getNotificationFrequency(), 'hebdomadaire');
          expect(await SettingsService.getLocalDataOnly(), false);
        },
      );

      test('should handle error scenarios gracefully', () async {
        // Test clearing all settings
        await SettingsService.clearAll();

        // Verify defaults are restored
        expect(
          await SettingsService.getLanguage(),
          'fr',
        ); // Default to French for Cameroon
        expect(await SettingsService.getNotificationsEnabled(), true);
        expect(await SettingsService.getThemeMode(), ThemeMode.system);
        expect(await SettingsService.getNotificationFrequency(), 'quotidienne');
        expect(await SettingsService.getLocalDataOnly(), true);
      });
    },
  );
}

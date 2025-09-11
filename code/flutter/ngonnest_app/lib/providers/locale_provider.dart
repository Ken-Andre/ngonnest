import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr'); // Default to French for Cameroon market

  Locale get locale => _locale;

  /// Initialize the locale from saved settings
  Future<void> initialize() async {
    final languageCode = await SettingsService.getLanguage();
    _locale = Locale(languageCode);
    notifyListeners();
  }

  /// Set the locale and persist it
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    await SettingsService.setLanguage(locale.languageCode);
    notifyListeners();
  }

  /// Get supported locales
  static List<Locale> get supportedLocales => const [
    Locale('fr'), // French - primary for Cameroon
    Locale('en'), // English - fallback
    Locale('es'), // Spanish - additional support
  ];

  /// Get locale display name
  String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return locale.languageCode;
    }
  }

  /// Check if a locale is supported
  bool isSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) => 
        supportedLocale.languageCode == locale.languageCode);
  }
}
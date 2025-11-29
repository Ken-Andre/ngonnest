import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/error_logger_service.dart';

/// Supported currencies for the application
enum Currency {
  fcfa('FCFA', 'XAF', 'Franc CFA', 'CFA'),
  usd('USD', '\$', 'US Dollar', 'USD'),
  eur('EUR', '€', 'Euro', 'EUR'),
  cad('CAD', 'C\$', 'Canadian Dollar', 'CAD');

  const Currency(this.code, this.symbol, this.name, this.isoCode);

  final String code;
  final String symbol;
  final String name;
  final String isoCode;

  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => Currency.fcfa, // Default fallback
    );
  }
}

/// Currency conversion rates and preferences management
class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const String _currencyPreferenceKey = 'preferred_currency';
  static const String _exchangeRatesKey = 'exchange_rates';

  Currency _currentCurrency = Currency.fcfa;
  Map<String, double> _exchangeRates = {};
  bool _isInitialized = false;

  /// Get current preferred currency
  Currency get currentCurrency => _currentCurrency;

  /// Get all available currencies
  List<Currency> get availableCurrencies => Currency.values;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the currency service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load preferred currency
      final currencyCode = prefs.getString(_currencyPreferenceKey);
      if (currencyCode != null) {
        _currentCurrency = Currency.fromCode(currencyCode);
      }

      // Load cached exchange rates
      final ratesJson = prefs.getString(_exchangeRatesKey);
      if (ratesJson != null) {
        final ratesMap = jsonDecode(ratesJson) as Map<String, dynamic>;
        _exchangeRates = ratesMap.map((key, value) => MapEntry(key, value as double));
      }

      // Initialize default exchange rates if none cached
      if (_exchangeRates.isEmpty) {
        await _initializeDefaultRates();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CurrencyService',
        operation: 'initialize',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      // Use defaults on error
      await _initializeDefaultRates();
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set preferred currency
  Future<void> setPreferredCurrency(Currency currency) async {
    if (_currentCurrency == currency) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyPreferenceKey, currency.code);

      _currentCurrency = currency;
      notifyListeners();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CurrencyService',
        operation: 'setPreferredCurrency',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      rethrow;
    }
  }

  /// Convert amount from FCFA to target currency
  double convertFromFcfa(double fcfaAmount, {Currency? targetCurrency}) {
    final target = targetCurrency ?? _currentCurrency;

    if (target == Currency.fcfa) return fcfaAmount;

    final rate = _exchangeRates[target.code];
    if (rate == null || rate == 0) {
      // Fallback to hardcoded rates if API rates unavailable
      return _convertWithFallbackRates(fcfaAmount, target);
    }

    return fcfaAmount * rate;
  }

  /// Convert amount to FCFA from any currency
  double convertToFcfa(double amount, Currency fromCurrency) {
    if (fromCurrency == Currency.fcfa) return amount;

    final rate = _exchangeRates[fromCurrency.code];
    if (rate == null || rate == 0) {
      // Fallback to hardcoded rates
      return _convertFromFallbackRates(amount, fromCurrency);
    }

    return amount / rate;
  }

  /// Convert amount between any two currencies
  double convert(double amount, Currency fromCurrency, Currency toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    // Convert to FCFA first, then to target currency
    final fcfaAmount = convertToFcfa(amount, fromCurrency);
    return convertFromFcfa(fcfaAmount, targetCurrency: toCurrency);
  }

  /// Format amount with currency symbol
  String formatAmount(double amount, {Currency? currency, int decimals = 1}) {
    final targetCurrency = currency ?? _currentCurrency;
    final formattedAmount = amount.toStringAsFixed(decimals);
    return '${targetCurrency.symbol}$formattedAmount';
  }

  /// Format amount with currency code (for settings/debug)
  String formatAmountWithCode(double amount, {Currency? currency, int decimals = 1}) {
    final targetCurrency = currency ?? _currentCurrency;
    final formattedAmount = amount.toStringAsFixed(decimals);
    return '$formattedAmount ${targetCurrency.code}';
  }

  /// Update exchange rates (called periodically or on demand)
  Future<void> updateExchangeRates() async {
    try {
      // In a real implementation, this would fetch from an API
      // For now, we'll use static rates that are reasonably current

      final newRates = await _fetchExchangeRates();
      _exchangeRates = newRates;

      // Cache rates
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_exchangeRatesKey, jsonEncode(_exchangeRates));

      notifyListeners();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'CurrencyService',
        operation: 'updateExchangeRates',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      // Don't rethrow - keep using cached rates
    }
  }

  /// Initialize default exchange rates
  Future<void> _initializeDefaultRates() async {
    // Default rates as of November 2024 (FCFA to target currency)
    // 1 FCFA = X target currency
    _exchangeRates = {
      'USD': 0.00152,  // 1 FCFA = 0.00152 USD
      'EUR': 0.00137,  // 1 FCFA = 0.00137 EUR
      'CAD': 0.00205,  // 1 FCFA = 0.00205 CAD
    };
  }

  /// Fetch exchange rates from API (placeholder for future implementation)
  Future<Map<String, double>> _fetchExchangeRates() async {
    // TODO: Implement real API call to currency exchange service
    // For now, return updated rates
    return {
      'USD': 0.00152,  // Updated rate
      'EUR': 0.00137,  // Updated rate
      'CAD': 0.00205,  // Updated rate
    };
  }

  /// Fallback conversion using hardcoded rates
  double _convertWithFallbackRates(double fcfaAmount, Currency target) {
    switch (target) {
      case Currency.usd:
        return fcfaAmount * 0.00152;
      case Currency.eur:
        return fcfaAmount * 0.00137;
      case Currency.cad:
        return fcfaAmount * 0.00205;
      case Currency.fcfa:
      default:
        return fcfaAmount;
    }
  }

  /// Convert from fallback rates to FCFA
  double _convertFromFallbackRates(double amount, Currency fromCurrency) {
    switch (fromCurrency) {
      case Currency.usd:
        return amount / 0.00152;
      case Currency.eur:
        return amount / 0.00137;
      case Currency.cad:
        return amount / 0.00205;
      case Currency.fcfa:
      default:
        return amount;
    }
  }

  /// Get currency display name with symbol
  String getCurrencyDisplayName(Currency currency) {
    return '${currency.name} (${currency.symbol})';
  }

  /// Check if currency is supported
  bool isCurrencySupported(Currency currency) {
    return Currency.values.contains(currency);
  }

  /// Reset to default currency (FCFA)
  Future<void> resetToDefault() async {
    await setPreferredCurrency(Currency.fcfa);
  }
}

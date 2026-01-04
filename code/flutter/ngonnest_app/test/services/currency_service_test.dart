import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngonnest_app/services/currency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrencyService', () {
    late CurrencyService currencyService;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      currencyService = CurrencyService();
      await currencyService.initialize();
    });

    test('should initialize with default currency (FCFA)', () {
      expect(currencyService.currentCurrency.code, 'FCFA');
      expect(currencyService.isInitialized, true);
    });

    test('should convert FCFA to EUR correctly', () {
      final euroAmount = currencyService.convertFromFcfa(655.957);
      expect(euroAmount, closeTo(1.0, 0.01)); // Approximately 1 EUR
    });

    test('should convert FCFA to USD correctly', () {
      final usdAmount = currencyService.convertFromFcfa(1000);
      expect(usdAmount, closeTo(1.52, 0.01)); // Approximately 1.52 USD
    });

    test('should format amount with currency symbol', () {
      final formatted = currencyService.formatAmount(100.5);
      expect(formatted, 'FCFA100.5'); // FCFA is default
    });

    test('should format amount with specific currency', () {
      final formatted = currencyService.formatAmount(100.5, currency: Currency.eur);
      expect(formatted, '€100.5');
    });

    test('should change preferred currency', () async {
      await currencyService.setPreferredCurrency(Currency.eur);
      expect(currencyService.currentCurrency.code, 'EUR');
    });

    test('should convert between any currencies', () {
      final usdToEur = currencyService.convert(100, Currency.usd, Currency.eur);
      expect(usdToEur, greaterThan(80)); // 100 USD should be more than 80 EUR
    });

    test('should return all available currencies', () {
      final currencies = currencyService.availableCurrencies;
      expect(currencies.length, 4); // FCFA, USD, EUR, CAD
      expect(currencies.map((c) => c.code), containsAll(['FCFA', 'USD', 'EUR', 'CAD']));
    });

    test('should validate currency support', () {
      expect(currencyService.isCurrencySupported(Currency.fcfa), true);
      expect(currencyService.isCurrencySupported(Currency.usd), true);
    });

    test('should provide currency display names', () {
      final displayName = currencyService.getCurrencyDisplayName(Currency.eur);
      expect(displayName, 'Euro (€)');
    });
  });
}

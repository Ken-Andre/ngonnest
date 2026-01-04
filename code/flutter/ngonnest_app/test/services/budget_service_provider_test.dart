import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/budget_service.dart';

void main() {
  group('BudgetService Provider Setup', () {
    test('BudgetService extends ChangeNotifier', () {
      final service = BudgetService();
      expect(service, isA<ChangeNotifier>());
    });

    test('BudgetService uses singleton pattern', () {
      final instance1 = BudgetService();
      final instance2 = BudgetService();

      // Both instances should be the same object
      expect(identical(instance1, instance2), isTrue);
    });

    test('BudgetService can be instantiated without errors', () {
      expect(() => BudgetService(), returnsNormally);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/product_intelligence_service.dart';
import 'package:ngonnest_app/models/product_template.dart';

void main() {
  group('ProductIntelligenceService', () {
    late ProductIntelligenceService service;

    setUp(() {
      service = ProductIntelligenceService();
    });

    test('searchProducts returns filtered results', () async {
      final results = await service.searchProducts('savon', 'hygiene');

      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(10));
      expect(results.every((product) => product.category == 'hygiene'), isTrue);

      // Vérifier que les résultats contiennent des produits liés au savon
      final productNames = results.map((p) => p.name.toLowerCase());
      expect(productNames.any((name) => name.contains('savon')), isTrue);
    });

    test('getPopularProductsByCategory returns sorted products', () async {
      final products = await service.getPopularProductsByCategory('hygiene');

      expect(products, isNotEmpty);
      expect(products.length, lessThanOrEqualTo(5));

      // Vérifier que les produits sont triés par popularité
      for (int i = 0; i < products.length - 1; i++) {
        expect(products[i].popularity >= products[i + 1].popularity, isTrue);
      }
    });

    test('calculateOptimalQuantity considers family size', () async {
      final mockProduct = ProductTemplate(
        id: 'test_savon',
        name: 'Savon Test',
        category: 'hygiene',
        unit: 'pièces',
        quantityGuidelines: {'family_4': 2.0, 'period': 30},
        icon: '🧼',
      );

      final quantityFor2 = await service.calculateOptimalQuantity(
        mockProduct,
        2,
      );
      final quantityFor6 = await service.calculateOptimalQuantity(
        mockProduct,
        6,
      );

      expect(quantityFor2, lessThan(quantityFor6));
      expect(quantityFor2, isA<double>());
    });

    test('calculateOptimalFrequency adjusts based on family size', () async {
      final mockProduct = ProductTemplate(
        id: 'test_savon',
        name: 'Savon Test',
        category: 'hygiene',
        unit: 'pièces',
        defaultFrequency: 30,
        icon: '🧼',
      );

      final freqFor2 = await service.calculateOptimalFrequency(mockProduct, 2);
      final freqFor6 = await service.calculateOptimalFrequency(mockProduct, 6);

      expect(freqFor2, lessThan(freqFor6));
    });

    test('searchProducts with empty query returns no results', () async {
      final results = await service.searchProducts('', 'hygiene');
      expect(results, isEmpty);
    });

    test('ProductTemplate calculates recommended quantity correctly', () {
      final template = ProductTemplate(
        id: 'test',
        name: 'Test Product',
        category: 'hygiene',
        unit: 'unités',
        quantityGuidelines: {'family_4': 4.0, 'period': 30},
        icon: '📦',
      );

      final quantityFor2 = template.getRecommendedQuantity(2);
      final quantityFor8 = template.getRecommendedQuantity(8);

      expect(quantityFor2, equals(2.0)); // 4 * (2/4)
      expect(quantityFor8, equals(8.0)); // 4 * (8/4)
    });

    test('ProductTemplate calculates recommended frequency correctly', () {
      final template = ProductTemplate(
        id: 'test',
        name: 'Test Product',
        category: 'hygiene',
        unit: 'unités',
        defaultFrequency: 40,
        icon: '📦',
      );

      final freqFor2 = template.getRecommendedFrequency(2);
      final freqFor6 = template.getRecommendedFrequency(6);

      expect(freqFor2, equals(32)); // 40 * 0.8
      expect(freqFor6, equals(48)); // 40 * 1.2
    });

    test('ProductPresets contains expected hierarchical data', () {
      final categories = ProductPresets.categories;
      expect(categories, isNotNull);
      expect(categories, isNotEmpty);
      expect(
        categories.length,
        equals(4),
      ); // hygiene, nettoyage, cuisine, durables

      final hygieneCategory = categories.firstWhere(
        (cat) => cat['id'] == 'hygiene',
      );

      expect(hygieneCategory, isNotNull);
      expect(hygieneCategory['subcategories'], isNotEmpty);
      expect(hygieneCategory['products'], isNotEmpty);
    });

    test('commonQuantities are used when available', () {
      final template = ProductTemplate(
        id: 'test',
        name: 'Test Product',
        category: 'hygiene',
        unit: 'unités',
        quantityGuidelines: {'family_4': 4.0, 'period': 30},
        commonQuantities: {'2_persons': 1, '4_persons': 3, '6_persons': 6},
        icon: '📦',
      );

      expect(
        template.getRecommendedQuantity(2),
        equals(1.0),
      ); // Uses common quantity
      expect(
        template.getRecommendedQuantity(4),
        equals(3.0),
      ); // Uses common quantity
      expect(
        template.getRecommendedQuantity(6),
        equals(6.0),
      ); // Uses common quantity
      expect(
        template.getRecommendedQuantity(3),
        equals(3.0),
      ); // Falls back to calculation: 4 * (3/4) = 3
    });
  });
}

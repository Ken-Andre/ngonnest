import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/services/cloud_import_service.dart';
// Generate mocks
@GenerateMocks([SupabaseClient])
import 'cloud_import_service_test.mocks.dart';

void main() {
  group('CloudImportService', () {
    late CloudImportService cloudImportService;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      cloudImportService = CloudImportService(client: mockSupabaseClient);
    });

    group('schema mapping', () {
      test(
        'mapHouseholdToLocal correctly maps cloud schema to local schema',
        () {
          // Arrange
          final cloudHousehold = {
            'id': 'household-1',
            'nb_personnes': 4,
            'nb_pieces': 3,
            'type_logement': 'appartement',
            'langue': 'fr',
            'budget_mensuel_estime': 150000.0,
          };

          // Act
          final localHousehold = cloudImportService.mapHouseholdToLocal(
            cloudHousehold,
          );

          // Assert
          expect(localHousehold['id'], equals('household-1'));
          expect(localHousehold['nb_personnes'], equals(4));
          expect(localHousehold['nb_pieces'], equals(3));
          expect(localHousehold['type_logement'], equals('appartement'));
          expect(localHousehold['langue'], equals('fr'));
          expect(localHousehold['budget_mensuel_estime'], equals(150000.0));
        },
      );

      test('mapProductToLocal correctly maps cloud schema to local schema', () {
        // Arrange
        final cloudProduct = {
          'id': 'product-1',
          'household_id': 'household-1',
          'nom': 'Riz',
          'categorie': 'Alimentaire',
          'type': 'consommable',
          'date_achat': '2024-01-01T00:00:00Z',
          'quantite_initiale': 5.0,
          'quantite_restante': 3.0,
          'unite': 'kg',
          'room': 'cuisine',
        };

        // Act
        final localProduct = cloudImportService.mapProductToLocal(cloudProduct);

        // Assert
        expect(localProduct['id'], equals('product-1'));
        expect(localProduct['id_foyer'], equals('household-1'));
        expect(localProduct['nom'], equals('Riz'));
        expect(localProduct['categorie'], equals('Alimentaire'));
        expect(localProduct['type'], equals('consommable'));
        expect(localProduct['room'], equals('cuisine'));
      });

      test(
        'mapBudgetCategoryToLocal correctly maps cloud schema to local schema',
        () {
          // Arrange
          final cloudBudget = {
            'id': 'budget-1',
            'name': 'Alimentaire',
            'limit_amount': 50000.0,
            'spent_amount': 25000.0,
            'month': '2024-01',
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-15T12:00:00Z',
          };

          // Act
          final localBudget = cloudImportService.mapBudgetCategoryToLocal(
            cloudBudget,
          );

          // Assert
          expect(localBudget['id'], equals('budget-1'));
          expect(localBudget['name'], equals('Alimentaire'));
          expect(localBudget['limit_amount'], equals(50000.0));
          expect(localBudget['spent_amount'], equals(25000.0));
          expect(localBudget['month'], equals('2024-01'));
          expect(localBudget['created_at'], equals('2024-01-01T00:00:00Z'));
          expect(localBudget['updated_at'], equals('2024-01-15T12:00:00Z'));
        },
      );

      test(
        'mapPurchaseToLocal correctly maps cloud schema to local schema',
        () {
          // Arrange
          final cloudPurchase = {
            'id': 'purchase-1',
            'product_id': 'product-1',
            'date': '2024-01-15',
            'quantite': 2.0,
            'prix_total': 5000.0,
          };

          // Act
          final localPurchase = cloudImportService.mapPurchaseToLocal(
            cloudPurchase,
          );

          // Assert
          expect(localPurchase['id'], equals('purchase-1'));
          expect(localPurchase['id_objet'], equals('product-1'));
          expect(localPurchase['date'], equals('2024-01-15'));
          expect(localPurchase['quantite'], equals(2.0));
          expect(localPurchase['prix_total'], equals(5000.0));
        },
      );
    });

    group('ImportResult', () {
      test('calculates total imported correctly', () {
        // Arrange
        final result = ImportResult()
          ..householdsImported = 2
          ..productsImported = 10
          ..budgetsImported = 5
          ..purchasesImported = 3;

        // Act & Assert
        expect(result.totalImported, equals(20));
      });

      test('identifies partial success correctly', () {
        // Arrange
        final result = ImportResult()
          ..success = true
          ..householdsImported = 2
          ..error = 'Some products failed to import';

        // Act & Assert
        expect(result.isPartialSuccess, isTrue);
      });

      test('toString returns formatted string', () {
        // Arrange
        final result = ImportResult()
          ..success = true
          ..householdsImported = 1
          ..productsImported = 5
          ..budgetsImported = 2
          ..purchasesImported = 0;

        // Act
        final resultString = result.toString();

        // Assert
        expect(resultString, contains('success: true'));
        expect(resultString, contains('households: 1'));
        expect(resultString, contains('products: 5'));
        expect(resultString, contains('budgets: 2'));
        expect(resultString, contains('purchases: 0'));
      });
    });
  });
}

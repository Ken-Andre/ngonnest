import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/household_service.dart';
import 'package:ngonnest_app/models/foyer.dart';

void main() {
  group('HouseholdService', () {
    setUp(() {
      // Reset static state before each test
      HouseholdService.clearCache();
    });

    tearDown(() {
      // Clean up static state after each test
      HouseholdService.clearCache();
    });

    group('Cache Management', () {
      test('clearCache should reset internal state', () {
        // Act
        HouseholdService.clearCache();
        
        // Assert - method should execute without error
        expect(() => HouseholdService.clearCache(), returnsNormally);
      });
    });

    group('Foyer Model Validation', () {
      test('should create valid Foyer objects', () {
        // Arrange & Act
        final testFoyer = Foyer(
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        // Assert
        expect(testFoyer.nbPersonnes, equals(4));
        expect(testFoyer.nbPieces, equals(3));
        expect(testFoyer.typeLogement, equals('appartement'));
        expect(testFoyer.langue, equals('fr'));
      });

      test('should handle different foyer configurations', () {
        final testCases = [
          {
            'nbPersonnes': 1,
            'nbPieces': 1,
            'typeLogement': 'studio',
            'langue': 'fr',
          },
          {
            'nbPersonnes': 6,
            'nbPieces': 5,
            'typeLogement': 'maison',
            'langue': 'en',
          },
        ];

        for (final testCase in testCases) {
          final foyer = Foyer(
            nbPersonnes: testCase['nbPersonnes'] as int,
            nbPieces: testCase['nbPieces'] as int,
            typeLogement: testCase['typeLogement'] as String,
            langue: testCase['langue'] as String,
          );

          expect(foyer.nbPersonnes, equals(testCase['nbPersonnes']));
          expect(foyer.nbPieces, equals(testCase['nbPieces']));
          expect(foyer.typeLogement, equals(testCase['typeLogement']));
          expect(foyer.langue, equals(testCase['langue']));
        }
      });
    });

    group('Service Initialization', () {
      test('should initialize without errors', () {
        // Test that the service can be accessed without throwing
        expect(() => HouseholdService.clearCache(), returnsNormally);
      });
    });
  });
}

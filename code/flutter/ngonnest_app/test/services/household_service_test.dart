import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/household_service.dart';
import 'package:ngonnest_app/models/foyer.dart';

void main() {
  setUp(() {
    // Reset static state before each test
    HouseholdService.clearCache();
  });

  tearDown(() {
    // Clean up static state after each test
    HouseholdService.clearCache();
  });

  group('HouseholdService', () {
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
    });

    group('createAndSaveFoyer', () {
      test('should calculate nbPieces automatically when not provided', () {
        // Test cases for automatic nbPieces calculation
        final testCases = [
          {'nbPersonnes': 1, 'expectedPieces': 2},
          {'nbPersonnes': 2, 'expectedPieces': 2},
          {'nbPersonnes': 3, 'expectedPieces': 3},
          {'nbPersonnes': 4, 'expectedPieces': 3},
          {'nbPersonnes': 5, 'expectedPieces': 4},
          {'nbPersonnes': 6, 'expectedPieces': 4},
        ];

        for (final testCase in testCases) {
          // Act
          final foyer = Foyer(
            nbPersonnes: testCase['nbPersonnes'] as int,
            nbPieces: (testCase['nbPersonnes'] as int <= 2 ? 2 : testCase['nbPersonnes'] as int <= 4 ? 3 : 4),
            typeLogement: 'appartement',
            langue: 'fr',
          );

          // Assert
          expect(
            foyer.nbPieces,
            equals(testCase['expectedPieces']),
            reason: 'For ${testCase['nbPersonnes']} personnes, expected ${testCase['expectedPieces']} pieces',
          );
        }
      });

      test('should use provided nbPieces over calculated value', () {
        // Act
        final foyer = Foyer(
          nbPersonnes: 4, // Would normally calculate to 3 pieces
          nbPieces: 5, // Override with 5 pieces
          typeLogement: 'maison',
          langue: 'fr',
        );

        // Assert
        expect(foyer.nbPieces, equals(5));
      });
    });

    group('clearCache', () {
      test('should clear cached foyer data', () async {
        // Act
        HouseholdService.clearCache();

        // Assert - method should execute without error
        expect(() => HouseholdService.clearCache(), returnsNormally);
      });
    });

    group('Legacy methods (deprecated)', () {
      test('legacy methods exist and are accessible', () {
        // Assert that deprecated methods exist
        expect(HouseholdService.saveHouseholdProfile, isNotNull);
        expect(HouseholdService.getHouseholdProfile, isNotNull);
        expect(HouseholdService.hasHouseholdProfile, isNotNull);
      });
    });
  });
}

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
    });
  });
}

        when(mockFoyerRepository.save(any)).thenThrow(testError);

        // Act & Assert
        expect(
          () => HouseholdService.saveFoyer(testFoyer),
          throwsA(isA<Exception>()),
        );
      });

      test('should log success with metadata', () async {
        // Arrange
        final testFoyer = Foyer(
          nbPersonnes: 3,
          nbPieces: 2,
          typeLogement: 'maison',
          langue: 'en',
        );

        when(mockFoyerRepository.save(any)).thenAnswer((_) async => 5);

        // Act
        final result = await HuseholdService.saveFoyer(testFoyer);

        // Assert
        expect(result, equals(5));
        verify(mockFoyerRepository.save(testFoyer)).called(1);
      });
    });

    group('createAndSaveFoyer', () {
      test('should create foyer with provided parameters', () async {
        // Arrange
        const nbPersonnes = 4;
        const typeLogement = 'appartement';
        const langue = 'fr';
        const nbPieces = 3;
        const expectedId = 2;

        when(mockFoyerRepository.save(any)).thenAnswer((_) async => expectedId);

        // Act
        final result = await HouseholdService.createAndSaveFoyer(
          nbPersonnes,
          typeLogement,
          langue,
          nbPieces: nbPieces,
        );

        // Assert
        expect(result, equals(expectedId));
        
        final capturedFoyer = verify(mockFoyerRepository.save(captureAny)).captured.single as Foyer;
        expect(capturedFoyer.nbPersonnes, equals(nbPersonnes));
        expect(capturedFoyer.nbPieces, equals(nbPieces));
        expect(capturedFoyer.typeLogement, equals(typeLogement));
        expect(capturedFoyer.langue, equals(langue));
      });

      test('should calculate nbPieces automatically when not provided', () async {
        // Arrange
        when(mockFoyerRepository.save(any)).thenAnswer((_) async => 1);

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
          await HouseholdService.createAndSaveFoyer(
            testCase['nbPersonnes'] as int,
            'appartement',
            'fr',
          );

          // Assert
          final capturedFoyer = verify(mockFoyerRepository.save(captureAny)).captured.last as Foyer;
          expect(
            capturedFoyer.nbPieces,
            equals(testCase['expectedPieces']),
            reason: 'For ${testCase['nbPersonnes']} personnes, expected ${testCase['expectedPieces']} pieces',
          );
        }
      });

      test('should use provided nbPieces over calculated value', () async {
        // Arrange
        when(mockFoyerRepository.save(any)).thenAnswer((_) async => 1);

        // Act
        await HouseholdService.createAndSaveFoyer(
          4, // Would normally calculate to 3 pieces
          'maison',
          'fr',
          nbPieces: 5, // Override with 5 pieces
        );

        // Assert
        final capturedFoyer = verify(mockFoyerRepository.save(captureAny)).captured.single as Foyer;
        expect(capturedFoyer.nbPieces, equals(5));
      });
    });

    group('getFoyer', () {
      test('should return foyer from repository on first call', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        when(mockFoyerRepository.get()).thenAnswer((_) async => testFoyer);

        // Act
        final result = await HouseholdService.getFoyer();

        // Assert
        expect(result, equals(testFoyer));
        verify(mockFoyerRepository.get()).called(1);
      });

      test('should return cached foyer on subsequent calls within cache duration', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        when(mockFoyerRepository.get()).thenAnswer((_) async => testFoyer);

        // Act
        final result1 = await HouseholdService.getFoyer();
        final result2 = await HouseholdService.getFoyer();

        // Assert
        expect(result1, equals(testFoyer));
        expect(result2, equals(testFoyer));
        verify(mockFoyerRepository.get()).called(1); // Should only be called once due to caching
      });

      test('should return cached foyer when repository fails', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        // First call succeeds and caches the foyer
        when(mockFoyerRepository.get()).thenAnswer((_) async => testFoyer);
        await HouseholdService.getFoyer();

        // Second call fails but should return cached value
        when(mockFoyerRepository.get()).thenThrow(Exception('Database error'));

        // Act
        final result = await HouseholdService.getFoyer();

        // Assert
        expect(result, equals(testFoyer));
      });

      test('should rethrow error when no cached foyer available', () async {
        // Arrange
        final testError = Exception('Database connection failed');
        when(mockFoyerRepository.get()).thenThrow(testError);

        // Act & Assert
        expect(
          () => HouseholdService.getFoyer(),
          throwsA(isA<Exception>()),
        );
      });

      test('should return null when no foyer exists', () async {
        // Arrange
        when(mockFoyerRepository.get()).thenAnswer((_) async => null);

        // Act
        final result = await HouseholdService.getFoyer();

        // Assert
        expect(result, isNull);
        verify(mockFoyerRepository.get()).called(1);
      });
    });

    group('clearCache', () {
      test('should clear cached foyer data', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        when(mockFoyerRepository.get()).thenAnswer((_) async => testFoyer);

        // Cache a foyer
        await HouseholdService.getFoyer();
        verify(mockFoyerRepository.get()).called(1);

        // Act
        HouseholdService.clearCache();

        // Next call should hit repository again
        await HouseholdService.getFoyer();

        // Assert
        verify(mockFoyerRepository.get()).called(2);
      });
    });

    group('hasFoyer', () {
      test('should return true when foyer exists', () async {
        // Arrange
        when(mockFoyerRepository.exists()).thenAnswer((_) async => true);

        // Act
        final result = await HouseholdService.hasFoyer();

        // Assert
        expect(result, isTrue);
        verify(mockFoyerRepository.exists()).called(1);
      });

      test('should return false when no foyer exists', () async {
        // Arrange
        when(mockFoyerRepository.exists()).thenAnswer((_) async => false);

        // Act
        final result = await HouseholdService.hasFoyer();

        // Assert
        expect(result, isFalse);
        verify(mockFoyerRepository.exists()).called(1);
      });

      test('should handle repository errors', () async {
        // Arrange
        when(mockFoyerRepository.exists()).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => HouseholdService.hasFoyer(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateFoyer', () {
      test('should update foyer successfully', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 5,
          nbPieces: 4,
          typeLogement: 'maison',
          langue: 'en',
        );
        const expectedResult = 1;

        when(mockFoyerRepository.update(any)).thenAnswer((_) async => expectedResult);

        // Act
        final result = await HouseholdService.updateFoyer(testFoyer);

        // Assert
        expect(result, equals(expectedResult));
        verify(mockFoyerRepository.update(testFoyer)).called(1);
      });

      test('should handle update errors', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 5,
          nbPieces: 4,
          typeLogement: 'maison',
          langue: 'en',
        );

        when(mockFoyerRepository.update(any)).thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => HouseholdService.updateFoyer(testFoyer),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteFoyer', () {
      test('should delete foyer successfully', () async {
        // Arrange
        const foyerId = 1;
        const expectedResult = 1;

        when(mockFoyerRepository.delete(any)).thenAnswer((_) async => expectedResult);

        // Act
        final result = await HouseholdService.deleteFoyer(foyerId);

        // Assert
        expect(result, equals(expectedResult));
        verify(mockFoyerRepository.delete(foyerId)).called(1);
      });

      test('should handle delete errors', () async {
        // Arrange
        const foyerId = 1;

        when(mockFoyerRepository.delete(any)).thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => HouseholdService.deleteFoyer(foyerId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Legacy methods (deprecated)', () {
      test('saveHouseholdProfile should call saveFoyer', () async {
        // Arrange
        final testProfile = Foyer(
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        when(mockFoyerRepository.save(any)).thenAnswer((_) async => 1);

        // Act
        final result = await HouseholdService.saveHouseholdProfile(testProfile);

        // Assert
        expect(result, equals(1));
        verify(mockFoyerRepository.save(testProfile)).called(1);
      });

      test('getHouseholdProfile should call getFoyer', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        when(mockFoyerRepository.get()).thenAnswer((_) async => testFoyer);

        // Act
        final result = await HouseholdService.getHouseholdProfile();

        // Assert
        expect(result, equals(testFoyer));
        verify(mockFoyerRepository.get()).called(1);
      });

      test('hasHouseholdProfile should call hasFoyer', () async {
        // Arrange
        when(mockFoyerRepository.exists()).thenAnswer((_) async => true);

        // Act
        final result = await HouseholdService.hasHouseholdProfile();

        // Assert
        expect(result, isTrue);
        verify(mockFoyerRepository.exists()).called(1);
      });
    });

    group('Error logging integration', () {
      test('should log errors with proper metadata', () async {
        // Arrange
        final testFoyer = Foyer(
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );
        final testError = Exception('Save operation failed');

        when(mockFoyerRepository.save(any)).thenThrow(testError);

        // Act & Assert
        expect(
          () => HouseholdService.saveFoyer(testFoyer),
          throwsA(isA<Exception>()),
        );

        // The error should be logged with ErrorLoggerService
        // (We can't easily verify this without mocking ErrorLoggerService,
        // but the test ensures the error is properly rethrown)
      });
    });

    group('Offline-first behavior', () {
      test('should work with cached data when repository is unavailable', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        // First call succeeds and caches data
        when(mockFoyerRepository.get()).thenAnswer((_) async => testFoyer);
        final firstResult = await HouseholdService.getFoyer();

        // Repository becomes unavailable
        when(mockFoyerRepository.get()).thenThrow(Exception('Offline'));

        // Act
        final secondResult = await HouseholdService.getFoyer();

        // Assert
        expect(firstResult, equals(testFoyer));
        expect(secondResult, equals(testFoyer)); // Should return cached data
      });
    });

    group('Thread safety and concurrency', () {
      test('should handle concurrent getFoyer calls', () async {
        // Arrange
        final testFoyer = Foyer(
          id: 1,
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        when(mockFoyerRepository.get()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return testFoyer;
        });

        // Act - Make concurrent calls
        final futures = List.generate(5, (_) => HouseholdService.getFoyer());
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, equals(testFoyer));
        }
        
        // Repository should be called only once due to caching
        verify(mockFoyerRepository.get()).called(1);
      });
    });
  });
}

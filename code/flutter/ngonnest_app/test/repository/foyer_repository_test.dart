import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/repository/foyer_repository.dart';
import 'package:ngonnest_app/services/database_service.dart';

// Generate mocks for Mockito
@GenerateMocks([DatabaseService])
import 'foyer_repository_test.mocks.dart';

void main() {
  late FoyerRepository foyerRepository;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    foyerRepository = FoyerRepository(mockDatabaseService as DatabaseService);
  });

  group('FoyerRepository Tests', () {
    const testId = 1;
    final testFoyer = Foyer(
      id: testId.toString(),
      nbPersonnes: 4,
      nbPieces: 3,
      typeLogement: 'appartement',
      langue: 'fr',
    );

    test('save() should call insertFoyer when no existing foyer', () async {
      // Arrange
      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => null);
      when(
        mockDatabaseService.insertFoyer(any),
      ).thenAnswer((_) async => testId.toString());

      // Act
      final result = await foyerRepository.save(testFoyer);

      // Assert
      expect(result, testId);
      verify(mockDatabaseService.getFoyer()).called(1);
      verify(mockDatabaseService.insertFoyer(any)).called(1);
      verifyNever(mockDatabaseService.updateFoyer(any));
    });

    test('save() should call updateFoyer when existing foyer exists', () async {
      // Arrange
      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => testFoyer);
      when(mockDatabaseService.updateFoyer(any)).thenAnswer((_) async => 1);

      // Act
      final result = await foyerRepository.save(testFoyer);

      // Assert
      expect(result, testId);
      verify(mockDatabaseService.getFoyer()).called(1);
      verify(mockDatabaseService.updateFoyer(any)).called(1);
      verifyNever(mockDatabaseService.insertFoyer(any));
    });

    test('get() should return foyer data from databaseService', () async {
      // Arrange
      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => testFoyer);

      // Act
      final result = await foyerRepository.get();

      // Assert
      expect(result, testFoyer);
      verify(mockDatabaseService.getFoyer()).called(1);
    });

    test('get() should return null when no foyer exists', () async {
      // Arrange
      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => null);

      // Act
      final result = await foyerRepository.get();

      // Assert
      expect(result, null);
      verify(mockDatabaseService.getFoyer()).called(1);
    });

    test('update() should call databaseService.updateFoyer', () async {
      // Arrange
      when(mockDatabaseService.updateFoyer(any)).thenAnswer((_) async => 1);

      // Act
      final result = await foyerRepository.update(testFoyer);

      // Assert
      expect(result, 1);
      verify(mockDatabaseService.updateFoyer(any)).called(1);
    });

    test('update() should throw error when foyer id is null', () {
      // Arrange
      final foyerWithNullId = Foyer(
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
      );

      // Act & Assert
      expect(
        () => foyerRepository.update(foyerWithNullId),
        throwsArgumentError,
      );
    });

    test('delete() should call databaseService.deleteFoyer', () async {
      // Arrange
      when(mockDatabaseService.deleteFoyer(testId)).thenAnswer((_) async => 1);

      // Act
      final result = await foyerRepository.delete(testId);

      // Assert
      expect(result, 1);
      verify(mockDatabaseService.deleteFoyer(testId)).called(1);
    });

    test('exists() should return true when foyer exists', () async {
      // Arrange
      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => testFoyer);

      // Act
      final result = await foyerRepository.exists();

      // Assert
      expect(result, true);
      verify(mockDatabaseService.getFoyer()).called(1);
    });

    test('exists() should return false when no foyer exists', () async {
      // Arrange
      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => null);

      // Act
      final result = await foyerRepository.exists();

      // Assert
      expect(result, false);
      verify(mockDatabaseService.getFoyer()).called(1);
    });
  });

  group('FoyerRepository Data Persistence Test', () {
    test('FoyerRepository saves and retrieves data correctly', () async {
      // Arrange
      final foyerToSave = Foyer(
        nbPersonnes: 4,
        nbPieces: 3,
        typeLogement: 'appartement',
        langue: 'fr',
        budgetMensuelEstime: 800.0,
      );

      when(mockDatabaseService.getFoyer()).thenAnswer((_) async => null);
      when(mockDatabaseService.insertFoyer(any)).thenAnswer((_) async => '1');
      when(
        mockDatabaseService.getFoyer(),
      ).thenAnswer((_) async => foyerToSave.copyWith(id: '1'));

      // Act
      final saveId = await foyerRepository.save(foyerToSave);
      final retrievedFoyer = await foyerRepository.get();

      // Assert
      expect(saveId, '1');
      expect(retrievedFoyer, isNotNull);
      expect(retrievedFoyer!.nbPersonnes, foyerToSave.nbPersonnes);
      expect(retrievedFoyer.typeLogement, foyerToSave.typeLogement);
      expect(retrievedFoyer.langue, foyerToSave.langue);
      expect(
        retrievedFoyer.budgetMensuelEstime,
        foyerToSave.budgetMensuelEstime,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngonnest_app/models/objet.dart';
import 'package:ngonnest_app/repository/inventory_repository.dart';
import 'package:ngonnest_app/services/database_service.dart';

// Generate mocks for Mockito
@GenerateMocks([DatabaseService])
import 'inventory_repository_test.mocks.dart';

void main() {
  late InventoryRepository inventoryRepository;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    inventoryRepository = InventoryRepository(
      mockDatabaseService as DatabaseService,
    );
  });

  group('InventoryRepository CRUD Tests', () {
    const testId = 1;
    const testIdFoyer = 1;
    final testObjet = Objet(
      id: testId,
      idFoyer: testIdFoyer,
      nom: 'Savon',
      categorie: 'hygiène',
      type: TypeObjet.consommable,
      quantiteInitiale: 100.0,
      quantiteRestante: 50.0,
      unite: 'pièces',
      seuilAlerteQuantite: 10.0,
    );

    test(
      'create() should call databaseService.insertObjet and return ID',
      () async {
        // Arrange
        when(
          mockDatabaseService.insertObjet(any),
        ).thenAnswer((_) async => testId);

        // Act
        final result = await inventoryRepository.create(testObjet);

        // Assert
        expect(result, testId);
        verify(mockDatabaseService.insertObjet(any)).called(1);
      },
    );

    test('read() should return objet when found', () async {
      // Arrange
      when(
        mockDatabaseService.getObjet(testId),
      ).thenAnswer((_) async => testObjet);

      // Act
      final result = await inventoryRepository.read(testId);

      // Assert
      expect(result, testObjet);
      verify(mockDatabaseService.getObjet(testId)).called(1);
    });

    test('read() should return null when objet not found', () async {
      // Arrange
      when(mockDatabaseService.getObjet(testId)).thenAnswer((_) async => null);

      // Act
      final result = await inventoryRepository.read(testId);

      // Assert
      expect(result, null);
      verify(mockDatabaseService.getObjet(testId)).called(1);
    });

    test('update() should update objet with provided changes', () async {
      // Arrange
      const newName = 'Savon liquide';

      when(
        mockDatabaseService.getObjet(testId),
      ).thenAnswer((_) async => testObjet);
      when(mockDatabaseService.updateObjet(any)).thenAnswer((_) async => 1);

      // Act
      final result = await inventoryRepository.update(testId, {'nom': newName});

      // Assert
      expect(result, 1);
      verify(mockDatabaseService.getObjet(testId)).called(1);
      verify(
        mockDatabaseService.updateObjet(
          argThat(isA<Objet>().having((obj) => obj.nom, 'nom', newName)),
        ),
      ).called(1);
    });

    test('update() should throw error when objet not found', () {
      // Arrange
      when(mockDatabaseService.getObjet(testId)).thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => inventoryRepository.update(testId, {'nom': 'New Name'}),
        throwsArgumentError,
      );
      verify(mockDatabaseService.getObjet(testId)).called(1);
      verifyNever(mockDatabaseService.updateObjet(any));
    });

    test(
      'updateObjet() should call databaseService.updateObjet directly',
      () async {
        // Arrange
        when(mockDatabaseService.updateObjet(any)).thenAnswer((_) async => 1);

        // Act
        final result = await inventoryRepository.updateObjet(testObjet);

        // Assert
        expect(result, 1);
        verify(mockDatabaseService.updateObjet(any)).called(1);
      },
    );

    test('delete() should call databaseService.deleteObjet', () async {
      // Arrange
      when(mockDatabaseService.deleteObjet(testId)).thenAnswer((_) async => 1);

      // Act
      final result = await inventoryRepository.delete(testId);

      // Assert
      expect(result, 1);
      verify(mockDatabaseService.deleteObjet(testId)).called(1);
    });

    test('getAll() should return list of objets for foyer', () async {
      // Arrange
      final objets = [testObjet];
      when(
        mockDatabaseService.getObjets(idFoyer: testIdFoyer),
      ).thenAnswer((_) async => objets);

      // Act
      final result = await inventoryRepository.getAll(testIdFoyer);

      // Assert
      expect(result, objets);
      verify(mockDatabaseService.getObjets(idFoyer: testIdFoyer)).called(1);
    });

    test('getAll() should filter by category when provided', () async {
      // Arrange
      when(
        mockDatabaseService.getObjets(
          idFoyer: testIdFoyer,
          type: TypeObjet.consommable,
        ),
      ).thenAnswer((_) async => [testObjet]);

      // Act
      final result = await inventoryRepository.getAll(
        testIdFoyer,
        category: 'consommable',
      );

      // Assert
      expect(result.length, 1);
      expect(result.first, testObjet);
      verify(
        mockDatabaseService.getObjets(
          idFoyer: testIdFoyer,
          type: TypeObjet.consommable,
        ),
      ).called(1);
    });
  });

  group('InventoryRepository Business Logic Tests', () {
    const testId = 1;
    const testIdFoyer = 1;

    final lowStockObjet = Objet(
      id: testId,
      idFoyer: testIdFoyer,
      nom: 'Savon presque épuisé',
      categorie: 'hygiène',
      type: TypeObjet.consommable,
      quantiteInitiale: 100.0,
      quantiteRestante: 5.0, // Below threshold
      unite: 'pièces',
      seuilAlerteQuantite: 10.0,
    );

    final expiringObjet = Objet(
      id: testId + 1,
      idFoyer: testIdFoyer,
      nom: 'Lait bientôt périmé',
      categorie: 'alimentaire',
      type: TypeObjet.consommable,
      quantiteInitiale: 1.0,
      quantiteRestante: 0.5,
      unite: 'litres',
      seuilAlerteQuantite: 0.2,
      dateRupturePrev: DateTime.now().add(
        const Duration(days: 1),
      ), // Expires soon
    );

    final safeObjet = Objet(
      id: testId + 2,
      idFoyer: testIdFoyer,
      nom: 'Pâtes en stock',
      categorie: 'alimentaire',
      type: TypeObjet.consommable,
      quantiteInitiale: 10.0,
      quantiteRestante: 8.0, // Plenty left
      unite: 'paquets',
      seuilAlerteQuantite: 2.0,
    );

    test(
      'getLowStockItems() should return only items below threshold',
      () async {
        // Arrange
        final allItems = [lowStockObjet, expiringObjet, safeObjet];
        when(
          mockDatabaseService.getObjets(idFoyer: testIdFoyer),
        ).thenAnswer((_) async => allItems);

        // Act
        final result = await inventoryRepository.getLowStockItems(testIdFoyer);

        // Assert
        expect(result.length, 1);
        expect(result.first.nom, 'Savon presque épuisé');
        expect(
          result.first.quantiteRestante <= result.first.seuilAlerteQuantite,
          true,
        );
      },
    );

    test(
      'getExpiringSoonItems() should return items expiring within warning period',
      () async {
        // Arrange
        final allItems = [lowStockObjet, expiringObjet, safeObjet];
        when(
          mockDatabaseService.getObjets(idFoyer: testIdFoyer),
        ).thenAnswer((_) async => allItems);

        // Act
        final result = await inventoryRepository.getExpiringSoonItems(
          testIdFoyer,
        );

        // Assert
        expect(result.length, 1);
        expect(result.first.nom, 'Lait bientôt périmé');
        expect(result.first.dateRupturePrev, isNotNull);
        expect(
          result.first.dateRupturePrev!.isBefore(
            DateTime.now().add(const Duration(days: 3)),
          ),
          true,
        );
      },
    );

    test('getTotalCount() should return total count of items', () async {
      // Arrange
      when(
        mockDatabaseService.getTotalObjetCount(testIdFoyer),
      ).thenAnswer((_) async => 42);

      // Act
      final result = await inventoryRepository.getTotalCount(testIdFoyer);

      // Assert
      expect(result, 42);
      verify(mockDatabaseService.getTotalObjetCount(testIdFoyer)).called(1);
    });

    test(
      'getExpiringSoonCount() should return count of expiring items',
      () async {
        // Arrange
        when(
          mockDatabaseService.getExpiringSoonObjetCount(testIdFoyer),
        ).thenAnswer((_) async => 7);

        // Act
        final result = await inventoryRepository.getExpiringSoonCount(
          testIdFoyer,
        );

        // Assert
        expect(result, 7);
        verify(
          mockDatabaseService.getExpiringSoonObjetCount(testIdFoyer),
        ).called(1);
      },
    );
  });

  group('InventoryRepository CRUD Operations Test (US-3.2)', () {
    test('InventoryRepository CRUD operations work correctly', () async {
      // Arrange
      const foyerId = 1;
      final newObjet = Objet(
        idFoyer: foyerId,
        nom: 'Savon',
        categorie: 'hygiène',
        type: TypeObjet.consommable,
        quantiteInitiale: 100.0,
        quantiteRestante: 80.0,
        unite: 'pièces',
        seuilAlerteQuantite: 10.0,
      );

      const objetId = 42;
      final foundObjet = Objet(
        id: objetId,
        idFoyer: foyerId,
        nom: 'Savon',
        categorie: 'hygiène',
        type: TypeObjet.consommable,
        quantiteInitiale: 100.0,
        quantiteRestante: 80.0,
        unite: 'pièces',
        seuilAlerteQuantite: 10.0,
      );

      // Mock create
      when(
        mockDatabaseService.insertObjet(any),
      ).thenAnswer((_) async => objetId);
      when(
        mockDatabaseService.getObjet(objetId),
      ).thenAnswer((_) async => foundObjet);
      when(mockDatabaseService.updateObjet(any)).thenAnswer((_) async => 1);
      when(mockDatabaseService.deleteObjet(objetId)).thenAnswer((_) async => 1);

      // Act & Assert

      // 1. Create
      final createdId = await inventoryRepository.create(newObjet);
      expect(createdId, objetId);

      // 2. Read
      final retrievedObjet = await inventoryRepository.read(objetId);
      expect(retrievedObjet, isNotNull);
      expect(retrievedObjet!.nom, 'Savon');
      expect(retrievedObjet.categorie, 'hygiène');

      // 3. Update
      final updateResult = await inventoryRepository.update(objetId, {
        'nom': 'Savon liquide',
      });
      expect(updateResult, 1);

      // 4. Delete
      final deleteResult = await inventoryRepository.delete(objetId);
      expect(deleteResult, 1);

      // Verify calls
      verify(mockDatabaseService.insertObjet(any)).called(1);
      verify(mockDatabaseService.getObjet(objetId)).called(1);
      verify(mockDatabaseService.updateObjet(any)).called(1);
      verify(mockDatabaseService.deleteObjet(objetId)).called(1);
    });
  });

  group('Task 1.4 - Inventory CRUD Complete Offline Tests', () {
    const testIdFoyer = 1;
    final testProduct = Objet(
      idFoyer: testIdFoyer,
      nom: 'Riz',
      categorie: 'cuisine',
      type: TypeObjet.consommable,
      quantiteInitiale: 5.0,
      quantiteRestante: 3.0,
      unite: 'kg',
      seuilAlerteQuantite: 1.0,
    );

    // Test 1.4.T1: addProduct() insère bien en DB
    test('1.4.T1: addProduct() should insert product in database', () async {
      // Arrange
      const expectedId = 42;
      when(mockDatabaseService.insertObjet(any))
          .thenAnswer((_) async => expectedId);

      // Act
      final result = await inventoryRepository.addProduct(testProduct);

      // Assert
      expect(result, expectedId);
      verify(mockDatabaseService.insertObjet(any)).called(1);
    });

    // Test 1.4.T1: Validation tests for addProduct
    test('1.4.T1: addProduct() should validate nom is not empty', () async {
      // Arrange
      final invalidProduct = Objet(
        idFoyer: testIdFoyer,
        nom: '', // Empty name
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: 3.0,
        unite: 'kg',
      );

      // Act & Assert
      expect(
        () => inventoryRepository.addProduct(invalidProduct),
        throwsArgumentError,
      );
      verifyNever(mockDatabaseService.insertObjet(any));
    });

    test('1.4.T1: addProduct() should validate quantiteInitiale > 0', () async {
      // Arrange
      final invalidProduct = Objet(
        idFoyer: testIdFoyer,
        nom: 'Riz',
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 0.0, // Invalid: must be > 0
        quantiteRestante: 0.0,
        unite: 'kg',
      );

      // Act & Assert
      expect(
        () => inventoryRepository.addProduct(invalidProduct),
        throwsArgumentError,
      );
      verifyNever(mockDatabaseService.insertObjet(any));
    });

    test('1.4.T1: addProduct() should validate quantiteRestante >= 0', () async {
      // Arrange
      final invalidProduct = Objet(
        idFoyer: testIdFoyer,
        nom: 'Riz',
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: -1.0, // Invalid: must be >= 0
        unite: 'kg',
      );

      // Act & Assert
      expect(
        () => inventoryRepository.addProduct(invalidProduct),
        throwsArgumentError,
      );
      verifyNever(mockDatabaseService.insertObjet(any));
    });

    // Test 1.4.T2: updateProduct() modifie le bon produit et renvoie booléen
    test('1.4.T2: updateProduct() should update product and return true', () async {
      // Arrange
      final existingProduct = Objet(
        id: 1,
        idFoyer: testIdFoyer,
        nom: 'Riz',
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: 3.0,
        unite: 'kg',
      );

      final updatedProduct = Objet(
        id: 1,
        idFoyer: testIdFoyer,
        nom: 'Riz Basmati',
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: 3.0,
        unite: 'kg',
      );

      when(mockDatabaseService.getObjet(1))
          .thenAnswer((_) async => existingProduct);
      when(mockDatabaseService.updateObjet(any))
          .thenAnswer((_) async => 1);

      // Act
      final result = await inventoryRepository.updateProduct(updatedProduct);

      // Assert
      expect(result, true);
      verify(mockDatabaseService.getObjet(1)).called(1);
      verify(mockDatabaseService.updateObjet(any)).called(1);
    });

    test('1.4.T2: updateProduct() should return false when product not found', () async {
      // Arrange
      final productToUpdate = Objet(
        id: 999,
        idFoyer: testIdFoyer,
        nom: 'Riz',
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: 3.0,
        unite: 'kg',
      );

      when(mockDatabaseService.getObjet(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await inventoryRepository.updateProduct(productToUpdate);

      // Assert
      expect(result, false);
      verify(mockDatabaseService.getObjet(999)).called(1);
      verifyNever(mockDatabaseService.updateObjet(any));
    });

    test('1.4.T2: updateProduct() should validate nom is not empty', () async {
      // Arrange
      final invalidProduct = Objet(
        id: 1,
        idFoyer: testIdFoyer,
        nom: '', // Empty name
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: 3.0,
        unite: 'kg',
      );

      // Act & Assert
      expect(
        () => inventoryRepository.updateProduct(invalidProduct),
        throwsArgumentError,
      );
    });

    // Test 1.4.T3: deleteProduct() supprime correctement
    test('1.4.T3: deleteProduct() should delete product and return 1', () async {
      // Arrange
      const productId = 1;
      final existingProduct = Objet(
        id: productId,
        idFoyer: testIdFoyer,
        nom: 'Riz',
        categorie: 'cuisine',
        type: TypeObjet.consommable,
        quantiteInitiale: 5.0,
        quantiteRestante: 3.0,
        unite: 'kg',
      );

      when(mockDatabaseService.getObjet(productId))
          .thenAnswer((_) async => existingProduct);
      when(mockDatabaseService.deleteObjet(productId))
          .thenAnswer((_) async => 1);

      // Act
      final result = await inventoryRepository.deleteProduct(productId);

      // Assert
      expect(result, 1);
      verify(mockDatabaseService.getObjet(productId)).called(1);
      verify(mockDatabaseService.deleteObjet(productId)).called(1);
    });

    test('1.4.T3: deleteProduct() should return 0 when product not found', () async {
      // Arrange
      const productId = 999;
      when(mockDatabaseService.getObjet(productId))
          .thenAnswer((_) async => null);

      // Act
      final result = await inventoryRepository.deleteProduct(productId);

      // Assert
      expect(result, 0);
      verify(mockDatabaseService.getObjet(productId)).called(1);
      verifyNever(mockDatabaseService.deleteObjet(any));
    });

    // Test 1.4.T4: searchProducts() retourne résultats pertinents avec limite
    test('1.4.T4: searchProducts() should return relevant results', () async {
      // Arrange
      final searchResults = [
        Objet(
          id: 1,
          idFoyer: testIdFoyer,
          nom: 'Riz Basmati',
          categorie: 'cuisine',
          type: TypeObjet.consommable,
          quantiteInitiale: 5.0,
          quantiteRestante: 3.0,
          unite: 'kg',
        ),
        Objet(
          id: 2,
          idFoyer: testIdFoyer,
          nom: 'Riz complet',
          categorie: 'cuisine',
          type: TypeObjet.consommable,
          quantiteInitiale: 3.0,
          quantiteRestante: 2.0,
          unite: 'kg',
        ),
      ];

      when(mockDatabaseService.searchObjets(
        query: 'riz',
        idFoyer: testIdFoyer,
        limit: 100,
      )).thenAnswer((_) async => searchResults);

      // Act
      final result = await inventoryRepository.searchProducts(
        'riz',
        idFoyer: testIdFoyer,
      );

      // Assert
      expect(result.length, 2);
      expect(result[0].nom, 'Riz Basmati');
      expect(result[1].nom, 'Riz complet');
      verify(mockDatabaseService.searchObjets(
        query: 'riz',
        idFoyer: testIdFoyer,
        limit: 100,
      )).called(1);
    });

    test('1.4.T4: searchProducts() should return empty list for empty query', () async {
      // Act
      final result = await inventoryRepository.searchProducts('');

      // Assert
      expect(result, isEmpty);
      // Empty query should return early without calling database
      // No verification needed as method returns early
    });

    test('1.4.T4: searchProducts() should respect limit of 100', () async {
      // Arrange
      final manyResults = List.generate(
        150,
        (i) => Objet(
          id: i,
          idFoyer: testIdFoyer,
          nom: 'Produit $i',
          categorie: 'cuisine',
          type: TypeObjet.consommable,
          quantiteInitiale: 1.0,
          quantiteRestante: 1.0,
          unite: 'unité',
        ),
      );

      when(mockDatabaseService.searchObjets(
        query: 'produit',
        idFoyer: testIdFoyer,
        limit: 100,
      )).thenAnswer((_) async => manyResults.take(100).toList());

      // Act
      final result = await inventoryRepository.searchProducts(
        'produit',
        idFoyer: testIdFoyer,
      );

      // Assert
      expect(result.length, lessThanOrEqualTo(100));
      verify(mockDatabaseService.searchObjets(
        query: 'produit',
        idFoyer: testIdFoyer,
        limit: 100,
      )).called(1);
    });
  });
}

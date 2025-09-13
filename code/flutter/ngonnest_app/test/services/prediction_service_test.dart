import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/objet.dart';
import '../../lib/models/foyer.dart';
import '../../lib/services/prediction_service.dart';

void main() {
  group('PredictionService Tests - US-4.1', () {
    late Objet frequenceConsommable;
    late Objet debitConsommable;
    late Objet durableObjet;

    setUp(() {
      final dateAchat = DateTime(2025, 1, 1); // 2025-01-01

      // Consommable with frequency method (30 days)
      frequenceConsommable = Objet(
        idFoyer: 1,
        nom: 'Savon',
        categorie: 'hygiène',
        type: TypeObjet.consommable,
        dateAchat: dateAchat,
        quantiteInitiale: 10.0,
        quantiteRestante: 10.0,
        unite: 'pièces',
        methodePrevision: MethodePrevision.frequence,
        frequenceAchatJours: 30,
        consommationJour: 1.0,
      );

      // Consommable with debit method (quantity 100, consumption 2/day)
      debitConsommable = Objet(
        idFoyer: 1,
        nom: 'Savon-débit',
        categorie: 'hygiène',
        type: TypeObjet.consommable,
        dateAchat: dateAchat,
        quantiteInitiale: 100.0,
        quantiteRestante: 100.0,
        unite: 'unités',
        methodePrevision: MethodePrevision.debit,
        frequenceAchatJours: null,
        consommationJour: 2.0,
      );

      // Durable object (no date de rupture)
      durableObjet = Objet(
        idFoyer: 1,
        nom: 'Lave-linge',
        categorie: 'électroménager',
        type: TypeObjet.durable,
        dateAchat: dateAchat,
        quantiteInitiale: 1.0,
        quantiteRestante: 1.0,
        unite: 'pièces',
        methodePrevision: null,
        frequenceAchatJours: null,
        consommationJour: null,
      );
    });

    test('calculateRuptureDate - Frequency method returns correct date', () {
      // Arrange
      final result = PredictionService.calculateRuptureDate(
        frequenceConsommable,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 1); // January
      expect(result.day, 31); // 2025-01-01 + 30 days = 2025-01-31
    });

    test('calculateRuptureDate - Debit method returns correct date', () {
      // Arrange
      final result = PredictionService.calculateRuptureDate(debitConsommable);

      // Assert
      expect(result, isNotNull);
      // 100 / 2 = 50 days -> 2025-01-01 + 50 days = 2025-02-20
      expect(result!.year, 2025);
      expect(result.month, 2); // February
      expect(result.day, 20); // 2025-02-20
    });

    test('calculateRuptureDate - Durable objects return null', () {
      // Arrange
      final result = PredictionService.calculateRuptureDate(durableObjet);

      // Assert
      expect(result, isNull);
    });

    test('calculateRuptureDate - Missing dateAchat returns null', () {
      // Arrange
      final objetWithoutDate = Objet(
        id: frequenceConsommable.id,
        idFoyer: frequenceConsommable.idFoyer,
        nom: frequenceConsommable.nom,
        categorie: frequenceConsommable.categorie,
        type: frequenceConsommable.type,
        dateAchat: null, // Explicitly set to null
        quantiteInitiale: frequenceConsommable.quantiteInitiale,
        quantiteRestante: frequenceConsommable.quantiteRestante,
        unite: frequenceConsommable.unite,
        methodePrevision: frequenceConsommable.methodePrevision,
        frequenceAchatJours: frequenceConsommable.frequenceAchatJours,
        consommationJour: frequenceConsommable.consommationJour,
      );
      final result = PredictionService.calculateRuptureDate(objetWithoutDate);

      // Assert
      expect(result, isNull);
    });

    test('calculateRuptureDate - Invalid frequency returns null', () {
      // Arrange
      final objetWithInvalidFreq = frequenceConsommable.copyWith(
        frequenceAchatJours: 0,
      );
      final result = PredictionService.calculateRuptureDate(
        objetWithInvalidFreq,
      );

      // Assert
      expect(result, isNull);
    });

    test('calculateRuptureDate - Invalid consumption returns null', () {
      // Arrange
      final objetWithInvalidCons = debitConsommable.copyWith(
        consommationJour: 0,
      );
      final result = PredictionService.calculateRuptureDate(
        objetWithInvalidCons,
      );

      // Assert
      expect(result, isNull);
    });

    test('calculateRuptureDate - Invalid quantity returns null', () {
      // Arrange
      final objetWithInvalidQty = debitConsommable.copyWith(
        quantiteInitiale: 0,
      );
      final result = PredictionService.calculateRuptureDate(
        objetWithInvalidQty,
      );

      // Assert
      expect(result, isNull);
    });

    test('calculateRuptureDate - Undefined method returns null', () {
      // Arrange
      final objetWithoutMethod = Objet(
        id: frequenceConsommable.id,
        idFoyer: frequenceConsommable.idFoyer,
        nom: frequenceConsommable.nom,
        categorie: frequenceConsommable.categorie,
        type: frequenceConsommable.type,
        dateAchat: frequenceConsommable.dateAchat,
        quantiteInitiale: frequenceConsommable.quantiteInitiale,
        quantiteRestante: frequenceConsommable.quantiteRestante,
        unite: frequenceConsommable.unite,
        methodePrevision: null, // Explicitly set to null
        frequenceAchatJours: frequenceConsommable.frequenceAchatJours,
        consommationJour: frequenceConsommable.consommationJour,
      );
      final result = PredictionService.calculateRuptureDate(objetWithoutMethod);

      // Assert
      expect(result, isNull);
    });

    test('updateRuptureDate - Frequency method updates correctly', () {
      // Arrange
      // Start date: 2025-01-01 -> Expected rupture: 2025-01-31

      // Act
      final updatedObjet = PredictionService.updateRuptureDate(
        frequenceConsommable,
      );

      // Assert
      expect(updatedObjet.dateRupturePrev, isNotNull);
      expect(updatedObjet.dateRupturePrev!.year, 2025);
      expect(updatedObjet.dateRupturePrev!.month, 1);
      expect(updatedObjet.dateRupturePrev!.day, 31);
    });

    test('updateRuptureDate - Debit method updates correctly', () {
      // Arrange
      // Start date: 2025-01-01, quantity: 100, consumption: 2/day -> Expected rupture: 2025-02-20

      // Act
      final updatedObjet = PredictionService.updateRuptureDate(
        debitConsommable,
      );

      // Assert
      expect(updatedObjet.dateRupturePrev, isNotNull);
      expect(updatedObjet.dateRupturePrev!.year, 2025);
      expect(updatedObjet.dateRupturePrev!.month, 2);
      expect(updatedObjet.dateRupturePrev!.day, 20);
    });

    test('updateRuptureDate - Durable does not update rupture date', () {
      // Act
      final updatedObjet = PredictionService.updateRuptureDate(durableObjet);

      // Assert
      expect(updatedObjet.dateRupturePrev, isNull);
    });

    test('updateRuptureDate - Preserves all other object properties', () {
      // Act
      final updatedObjet = PredictionService.updateRuptureDate(
        frequenceConsommable,
      );

      // Assert - Check that all other properties are unchanged
      expect(updatedObjet.id, frequenceConsommable.id);
      expect(updatedObjet.idFoyer, frequenceConsommable.idFoyer);
      expect(updatedObjet.nom, frequenceConsommable.nom);
      expect(updatedObjet.type, frequenceConsommable.type);
      expect(
        updatedObjet.quantiteInitiale,
        frequenceConsommable.quantiteInitiale,
      );
      expect(
        updatedObjet.frequenceAchatJours,
        frequenceConsommable.frequenceAchatJours,
      );
    });

    test('isRuptureExpired - Returns true for past dates', () {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final objetWithPastRupture = frequenceConsommable.copyWith(
        dateRupturePrev: pastDate,
      );

      // Act
      final result = PredictionService.isRuptureExpired(objetWithPastRupture);

      // Assert
      expect(result, true);
    });

    test('isRuptureExpired - Returns false for future dates', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final objetWithFutureRupture = frequenceConsommable.copyWith(
        dateRupturePrev: futureDate,
      );

      // Act
      final result = PredictionService.isRuptureExpired(objetWithFutureRupture);

      // Assert
      expect(result, false);
    });

    test('isRuptureExpired - Returns false when no rupture date', () {
      // Arrange
      final objetWithoutRuptureDate = frequenceConsommable.copyWith(
        dateRupturePrev: null,
      );

      // Act
      final result = PredictionService.isRuptureExpired(
        objetWithoutRuptureDate,
      );

      // Assert
      expect(result, false);
    });

    test('getDaysUntilRupture - Returns positive for future dates', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final objetWithFutureRupture = frequenceConsommable.copyWith(
        dateRupturePrev: futureDate,
      );

      // Act
      final result = PredictionService.getDaysUntilRupture(
        objetWithFutureRupture,
      );

      // Assert - Allow for small variations due to timing
      expect(result, inInclusiveRange(4, 5));
    });

    test('getDaysUntilRupture - Returns negative for past dates', () {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final objetWithPastRupture = frequenceConsommable.copyWith(
        dateRupturePrev: pastDate,
      );

      // Act
      final result = PredictionService.getDaysUntilRupture(
        objetWithPastRupture,
      );

      // Assert
      expect(result, -3);
    });

    test('getDaysUntilRupture - Returns null when no rupture date', () {
      // Arrange
      final objetWithoutRuptureDate = frequenceConsommable.copyWith(
        dateRupturePrev: null,
      );

      // Act
      final result = PredictionService.getDaysUntilRupture(
        objetWithoutRuptureDate,
      );

      // Assert
      expect(result, null);
    });

    test('isNearRupture - Returns true when within alert threshold', () {
      // Arrange
      final alertWithinDays = DateTime.now().add(
        const Duration(days: 2),
      ); // seuilAlerteJours = 3
      final objetNearRupture = frequenceConsommable.copyWith(
        dateRupturePrev: alertWithinDays,
      );

      // Act
      final result = PredictionService.isNearRupture(objetNearRupture);

      // Assert
      expect(result, true);
    });

    test('isNearRupture - Returns true when past rupture date', () {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final objetPastRupture = frequenceConsommable.copyWith(
        dateRupturePrev: pastDate,
      );

      // Act
      final result = PredictionService.isNearRupture(objetPastRupture);

      // Assert
      expect(result, true);
    });

    test('isNearRupture - Returns false when outside alert threshold', () {
      // Arrange
      final farFutureDate = DateTime.now().add(
        const Duration(days: 10),
      ); // seuilAlerteJours = 3
      final objetFarFromRupture = frequenceConsommable.copyWith(
        dateRupturePrev: farFutureDate,
      );

      // Act
      final result = PredictionService.isNearRupture(objetFarFromRupture);

      // Assert
      expect(result, false);
    });

    test('calculateRuptureDateForTest - Direct test method works', () {
      // Arrange
      final testDate = DateTime(2025, 1, 1);

      // Act
      final result = PredictionService.calculateRuptureDateForTest(
        dateAchat: testDate,
        methodePrevision: MethodePrevision.frequence,
        frequenceAchatJours: 30,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 1);
      expect(result.day, 31);
    });
  });
}

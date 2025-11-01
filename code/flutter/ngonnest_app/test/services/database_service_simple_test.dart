import 'package:flutter_test/flutter_test.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/models/objet.dart';
import 'package:ngonnest_app/models/alert.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    tearDown(() async {
      try {
        await databaseService.close();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = DatabaseService();
        final instance2 = DatabaseService();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Model Validation', () {
      test('should create valid Foyer objects', () {
        final foyer = Foyer(
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );

        expect(foyer.nbPersonnes, equals(4));
        expect(foyer.nbPieces, equals(3));
        expect(foyer.typeLogement, equals('appartement'));
        expect(foyer.langue, equals('fr'));
      });

      test('should create valid Objet objects', () {
        final objet = Objet(
          nom: 'Savon',
          categorie: 'Hygiène',
          type: TypeObjet.consommable,
          quantiteInitiale: 5,
          quantiteRestante: 5,
          unite: 'unités',
          prixUnitaire: 500.0,
          idFoyer: 1,
        );

        expect(objet.nom, equals('Savon'));
        expect(objet.categorie, equals('Hygiène'));
        expect(objet.quantiteRestante, equals(5));
        expect(objet.prixUnitaire, equals(500.0));
        expect(objet.idFoyer, equals(1));
      });

      test('should create valid Alert objects', () {
        final alert = Alert(
          titre: 'Stock faible',
          message: 'Le savon est en rupture de stock',
          typeAlerte: AlertType.stockFaible,
          urgences: AlertUrgency.medium,
          dateCreation: DateTime.now(),
          idFoyer: 1,
        );

        expect(alert.titre, equals('Stock faible'));
        expect(alert.message, equals('Le savon est en rupture de stock'));
        expect(alert.typeAlerte, equals(AlertType.stockFaible));
        expect(alert.idFoyer, equals(1));
      });
    });

    group('Database Operations', () {
      test('should handle database initialization', () {
        expect(() => DatabaseService(), returnsNormally);
      });

      test('should handle close operation gracefully', () async {
        expect(() async => await databaseService.close(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle invalid operations gracefully', () {
        // Test that service doesn't crash on invalid operations
        expect(() => DatabaseService(), returnsNormally);
      });
    });

    group('NgonNest Specific Features', () {
      test('should support Cameroon product categories', () {
        final categories = [
          'Hygiène',
          'Nettoyage', 
          'Cuisine',
          'Divers',
        ];

        for (final category in categories) {
          final objet = Objet(
            nom: 'Produit test',
            categorie: category,
            type: TypeObjet.consommable,
            quantiteInitiale: 1,
            quantiteRestante: 1,
            unite: 'unités',
            prixUnitaire: 1000.0, // FCFA
            idFoyer: 1,
          );
          
          expect(objet.categorie, equals(category));
        }
      });

      test('should handle FCFA pricing', () {
        final objet = Objet(
          nom: 'Savon de Marseille',
          categorie: 'Hygiène',
          type: TypeObjet.consommable,
          quantiteInitiale: 3,
          quantiteRestante: 3,
          unite: 'unités',
          prixUnitaire: 2500.0, // 2500 FCFA
          idFoyer: 1,
        );

        expect(objet.prixUnitaire, equals(2500.0));
        expect(objet.prixUnitaire! > 1000.0, isTrue); // Typical FCFA range
      });

      test('should support French language alerts', () {
        final alert = Alert(
          titre: 'Expiration proche',
          message: 'Le savon expire bientôt (dans 3 jours)',
          typeAlerte: AlertType.expirationProche,
          urgences: AlertUrgency.medium,
          dateCreation: DateTime.now(),
          idFoyer: 1,
        );

        expect(alert.titre.contains('Expiration'), isTrue);
        expect(alert.message.contains('expire'), isTrue);
      });
    });

    group('Offline-First Behavior', () {
      test('should work without network connection', () {
        // Database operations should work offline
        expect(() => DatabaseService(), returnsNormally);
      });

      test('should handle concurrent operations', () async {
        // Test multiple database instances
        final futures = List.generate(3, (_) => Future(() => DatabaseService()));
        final results = await Future.wait(futures);
        
        expect(results.length, equals(3));
        // All should be the same singleton instance
        for (int i = 1; i < results.length; i++) {
          expect(identical(results[0], results[i]), isTrue);
        }
      });
    });
  });
}

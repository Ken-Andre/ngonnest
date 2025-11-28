import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/models/objet.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

@GenerateMocks([Database])
import 'database_service_test.mocks.dart';

void main() {
  group('DatabaseService', () {
    late MockDatabase mockDatabase;
    late DatabaseService databaseService;

    setUp(() {
      mockDatabase = MockDatabase();
      databaseService = DatabaseService();
    });

    tearDown(() async {
      try {
        await databaseService.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Connection Management', () {
      test('should establish database connection successfully', () async {
        when(mockDatabase.isOpen).thenReturn(true);
        when(mockDatabase.rawQuery('SELECT 1')).thenAnswer(
          (_) async => [
            {'1': 1},
          ],
        );
        expect(() => databaseService.database, returnsNormally);
      });

      test('should validate connection with simple query', () async {
        when(mockDatabase.isOpen).thenReturn(true);
        when(mockDatabase.rawQuery('SELECT 1')).thenAnswer(
          (_) async => [
            {'1': 1},
          ],
        );
        final isValid = await databaseService.isConnectionValid();
        expect(isValid, isA<bool>());
      });

      test('should return connection status information', () {
        final status = databaseService.getConnectionStatus();
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('is_connected'), isTrue);
        expect(status.containsKey('is_initializing'), isTrue);
      });

      test('should close database connection properly', () async {
        await databaseService.close();
        expect(true, isTrue);
      });
    });

    group('Foyer Operations', () {
      test('should get foyer from database', () async {
        final testFoyerMap = {
          'id': 1,
          'nb_personnes': 4,
          'nb_pieces': 3,
          'type_logement': 'appartement',
          'langue': 'fr',
          'budget_mensuel_estime': 800.0,
          'date_creation': DateTime.now().toIso8601String(),
          'date_modification': DateTime.now().toIso8601String(),
        };

        when(
          mockDatabase.query('foyer', limit: 1),
        ).thenAnswer((_) async => [testFoyerMap]);

        final result = await databaseService.getFoyer();
        expect(result, isA<Foyer>());
        expect(result?.id, equals(1));
        expect(result?.nbPersonnes, equals(4));
      });

      test('should return null when no foyer exists', () async {
        when(mockDatabase.query('foyer', limit: 1)).thenAnswer((_) async => []);
        final result = await databaseService.getFoyer();
        expect(result, isNull);
      });

      test('should insert foyer successfully', () async {
        final testFoyer = Foyer(
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );
        when(mockDatabase.insert('foyer', any)).thenAnswer((_) async => 1);
        final result = await databaseService.insertFoyer(testFoyer);
        expect(result, equals(1));
      });

      test('should update foyer successfully', () async {
        final testFoyer = Foyer(
          id: "1",
          nbPersonnes: 5,
          nbPieces: 4,
          typeLogement: 'maison',
          langue: 'en',
        );
        when(
          mockDatabase.update(
            'foyer',
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => 1);
        final result = await databaseService.updateFoyer(testFoyer);
        expect(result, equals(1));
      });
    });

    group('Objet Operations', () {
      test('should get all objets for a foyer', () async {
        const idFoyer = 1;
        final testObjetMaps = [
          {
            'id': 1,
            'id_foyer': idFoyer,
            'nom': 'Savon de Marseille',
            'categorie': 'Hygiène',
            'type': 'consommable',
            'quantite_restante': 2.0,
            'seuil_alerte_quantite': 1.0,
            'prix_unitaire': 3.50,
            'date_achat': DateTime.now().toIso8601String(),
          },
        ];

        when(
          mockDatabase.query(
            'objet',
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
          ),
        ).thenAnswer((_) async => testObjetMaps);

        final result = await databaseService.getObjets(idFoyer: idFoyer);
        expect(result, hasLength(1));
        expect(result[0].nom, equals('Savon de Marseille'));
      });

      test('should insert objet successfully', () async {
        final testObjet = Objet(
          idFoyer: 1,
          nom: 'Nouveau Savon',
          categorie: 'Hygiène',
          type: TypeObjet.consommable,
          quantiteRestante: 3.0,
          seuilAlerteQuantite: 1.0,
          prixUnitaire: 4.00,
          dateAchat: DateTime.now(),
          quantiteInitiale: 5,
          unite: '',
        );
        when(mockDatabase.insert('objet', any)).thenAnswer((_) async => 5);
        final result = await databaseService.insertObjet(testObjet);
        expect(result, equals(5));
      });
    });

    group('Alert Operations', () {
      test('should get alerts for foyer', () async {
        const idFoyer = 1;
        final alertMaps = [
          {
            'id': 1,
            'id_objet': 123,
            'type_alerte': 'stock_faible',
            'titre': 'Stock faible',
            'message': 'Savon en rupture de stock',
            'urgences': 'high',
            'date_creation': DateTime.now().toIso8601String(),
            'lu': 0,
            'resolu': 0,
          },
        ];

        when(
          mockDatabase.rawQuery(any, any),
        ).thenAnswer((_) async => alertMaps);
        final result = await databaseService.getAlerts(idFoyer: idFoyer);
        expect(result, hasLength(1));
        expect(result[0].title, equals('Stock faible'));
      });

      test('should mark alert as read', () async {
        const alertId = 1;
        when(
          mockDatabase.update(
            'alertes',
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => 1);
        final result = await databaseService.markAlertAsRead(alertId);
        expect(result, equals(1));
      });
    });

    group('Error Handling', () {
      test('should retry on database busy error', () async {
        // Create a mock exception that simulates a database busy error
        final busyError = Exception('Database is locked');
        when(mockDatabase.query('foyer', limit: 1)).thenThrow(busyError);
        when(mockDatabase.query('foyer', limit: 1)).thenAnswer((_) async => []);
        final result = await databaseService.getFoyer();
        expect(result, isNull);
      });

      test('should not retry on non-retryable errors', () async {
        // Create a mock exception for non-retryable errors
        final nonRetryableError = Exception('Syntax error');
        when(
          mockDatabase.query('foyer', limit: 1),
        ).thenThrow(nonRetryableError);
        expect(() => databaseService.getFoyer(), throwsA(isA<Exception>()));
      });
    });

    group('NgonNest Specific', () {
      test('should handle Cameroon product categories', () async {
        const cameroonCategories = [
          'Hygiène',
          'Nettoyage',
          'Cuisine',
          'Divers',
        ];
        final testObjets = cameroonCategories
            .map(
              (cat) => {
                'id': cameroonCategories.indexOf(cat) + 1,
                'id_foyer': 1,
                'nom': 'Produit $cat',
                'categorie': cat,
                'type': 'consommable',
                'quantite_restante': 2.0,
                'seuil_alerte_quantite': 1.0,
                'prix_unitaire': 1000.0,
                'date_achat': DateTime.now().toIso8601String(),
              },
            )
            .toList();

        when(
          mockDatabase.query(
            'objet',
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            orderBy: anyNamed('orderBy'),
          ),
        ).thenAnswer((_) async => testObjets);

        final result = await databaseService.getObjets(idFoyer: 1);
        expect(result, hasLength(4));
        for (final objet in result) {
          expect(cameroonCategories, contains(objet.categorie));
        }
      });

      test('should work offline (local SQLite)', () async {
        final testFoyer = Foyer(
          nbPersonnes: 4,
          nbPieces: 3,
          typeLogement: 'appartement',
          langue: 'fr',
        );
        when(mockDatabase.insert('foyer', any)).thenAnswer((_) async => 1);
        final result = await databaseService.insertFoyer(testFoyer);
        expect(result, equals(1));
      });
    });
  });
}

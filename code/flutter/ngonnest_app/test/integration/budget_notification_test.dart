import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ngonnest_app/models/budget_category.dart';
import 'package:ngonnest_app/models/foyer.dart';
import 'package:ngonnest_app/models/objet.dart';
import 'package:ngonnest_app/repository/inventory_repository.dart';
import 'package:ngonnest_app/services/budget_service.dart';
import 'package:ngonnest_app/services/database_service.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  setUp(() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ngonnest.db');
    await databaseFactory.deleteDatabase(path);
  });

  test('adding item beyond budget triggers over-budget state', () async {
    final databaseService = DatabaseService();
    final inventoryRepository = InventoryRepository(databaseService);

    // Ensure the database has required columns for the test
    final db = await databaseService.database;
    final columns = await db.rawQuery('PRAGMA table_info(objet)');
    final hasRoom = columns.any((c) => c['name'] == 'room');
    if (!hasRoom) {
      await db.execute('ALTER TABLE objet ADD COLUMN room TEXT');
    }

    await databaseService.insertFoyer(
      Foyer(
        nbPersonnes: 1,
        nbPieces: 1,
        typeLogement: 'appartement',
        langue: 'fr',
      ),
    );

    await BudgetService.createBudgetCategory(
      BudgetCategory(
        name: 'Hygiène',
        limit: 10.0,
        month: BudgetService.getCurrentMonth(),
      ),
    );

    final objet = Objet(
      idFoyer: 1,
      nom: 'Savon de luxe',
      categorie: 'Hygiène',
      type: TypeObjet.consommable,
      dateAchat: DateTime.now(),
      quantiteInitiale: 1,
      quantiteRestante: 1,
      unite: 'pièce',
      prixUnitaire: 15.0,
    );

    await inventoryRepository.create(objet);

    final categories = await BudgetService.getBudgetCategories();
    final hygiene = categories.firstWhere((c) => c.name == 'Hygiène');
    expect(hygiene.isOverBudget, isTrue);
  });
}

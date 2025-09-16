import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/services/settings_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('should clear database and preferences', () async {
    final dbService = DatabaseService();
    final db = await dbService.database;

    await db.insert('foyer', {
      'nb_personnes': 1,
      'nb_pieces': 1,
      'type_logement': 'test',
      'langue': 'fr',
      'budget_mensuel_estime': 0
    });
    await SettingsService.setLanguage('en');

    await dbService.clearAllData();
    await SettingsService.clearAll();

    final rows = await db.query('foyer');
    expect(rows, isEmpty);
    expect(await SettingsService.getLanguage(), 'fr');

    await db.close();
  });
}

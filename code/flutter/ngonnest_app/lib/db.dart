import 'package:sqflite/sqflite.dart';

Future<Database> initDatabase() async {
  return openDatabase(
    'ngonnest.db',
    version: 1,
    onCreate: (db, version) {
      db.execute(
        'CREATE TABLE foyer (id INTEGER PRIMARY KEY, nb_personnes INTEGER, type_logement TEXT, langue TEXT)',
      );
    },
  );
}

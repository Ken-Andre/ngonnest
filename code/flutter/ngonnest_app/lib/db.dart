import 'package:sqflite/sqflite.dart';

Future<Database> initDatabase() async {
  return openDatabase(
    'ngonnest.db',
    version: 1,
    onCreate: (db, version) async {
      // Table foyer
      await db.execute('''
        CREATE TABLE foyer (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nb_personnes INTEGER NOT NULL,
          nb_pieces INTEGER NOT NULL DEFAULT 1,
          type_logement TEXT NOT NULL,
          langue TEXT NOT NULL,
          budget_mensuel_estime REAL
        )
      ''');

      // Table objet (pour consommables et durables)
      await db.execute('''
        CREATE TABLE objet (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_foyer INTEGER NOT NULL,
          nom TEXT NOT NULL,
          categorie TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('consommable', 'durable')),
          date_achat TEXT,
          duree_vie_prev_jours INTEGER,
          date_rupture_prev TEXT,
          quantite_initiale REAL NOT NULL,
          quantite_restante REAL NOT NULL CHECK (quantite_restante >= 0),
          unite TEXT NOT NULL,
          taille_conditionnement REAL,
          prix_unitaire REAL,
          methode_prevision TEXT CHECK (methode_prevision IN ('frequence', 'debit')),
          frequence_achat_jours INTEGER,
          consommation_jour REAL,
          seuil_alerte_jours INTEGER DEFAULT 3,
          seuil_alerte_quantite REAL DEFAULT 1,
          FOREIGN KEY (id_foyer) REFERENCES foyer (id)
        )
      ''');

      // Table reachat_log (optionnel dans le MVP)
      await db.execute('''
        CREATE TABLE reachat_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_objet INTEGER NOT NULL,
          date TEXT NOT NULL,
          quantite REAL NOT NULL,
          prix_total REAL,
          FOREIGN KEY (id_objet) REFERENCES objet (id)
        )
      ''');
    },
  );
}

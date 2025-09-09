import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<Database> initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'ngonnest.db');

  final database = await openDatabase(
    path,
    version: 5, // Migration v5: forcer ajout colonne commentaires durables
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

      // Table objet (pour consommables et durables) - version avec commentaires
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
          commentaires TEXT,
          FOREIGN KEY (id_foyer) REFERENCES foyer (id)
        )
      ''');

      // Table alertes (pour les notifications - US-2.1)
      await db.execute('''
        CREATE TABLE alertes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_objet INTEGER,
          type_alerte TEXT NOT NULL CHECK (type_alerte IN ('stock_faible', 'expiration_proche', 'reminder', 'system')),
          titre TEXT NOT NULL,
          message TEXT NOT NULL,
          urgences TEXT NOT NULL CHECK (urgences IN ('low', 'medium', 'high')) DEFAULT 'medium',
          date_creation TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          date_lecture TEXT,
          lu INTEGER NOT NULL DEFAULT 0,
          resolu INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (id_objet) REFERENCES objet (id) ON DELETE CASCADE
        )
      ''');

      // Table budget (pour gérer le budget des catégories)
      await db.execute('''
        CREATE TABLE budget (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_foyer INTEGER NOT NULL,
          categorie TEXT NOT NULL,
          montant_alloue REAL NOT NULL,
          montant_depense REAL NOT NULL DEFAULT 0,
          date_mise_a_jour TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (id_foyer) REFERENCES foyer (id) ON DELETE CASCADE,
          UNIQUE(id_foyer, categorie)
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
    onUpgrade: (db, oldVersion, newVersion) async {
      // Handle database migrations
      if (oldVersion < 2) {
        // Migration from version 1 to 2: Ensure alertes table exists
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='alertes'");
        if (tables.isEmpty) {
          await db.execute('''
            CREATE TABLE alertes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_objet INTEGER,
              type_alerte TEXT NOT NULL CHECK (type_alerte IN ('stock_faible', 'expiration_proche', 'reminder', 'system')),
              titre TEXT NOT NULL,
              message TEXT NOT NULL,
              urgences TEXT NOT NULL CHECK (urgences IN ('low', 'medium', 'high')) DEFAULT 'medium',
              date_creation TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              date_lecture TEXT,
              lu INTEGER NOT NULL DEFAULT 0,
              resolu INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (id_objet) REFERENCES objet (id) ON DELETE CASCADE
            )
          ''');
        }
      }

      // Migration to version 3: Add missing columns to objet table
      if (oldVersion < 3) {
        // Vérifier et ajouter colonne seuil_alerte_jours
        final seuilAlerteJoursColumns = await db.rawQuery("PRAGMA table_info(objet)");
        final hasSeuilAlerteJours = seuilAlerteJoursColumns.any((col) => col['name'] == 'seuil_alerte_jours');

        if (!hasSeuilAlerteJours) {
          await db.execute('ALTER TABLE objet ADD COLUMN seuil_alerte_jours INTEGER NOT NULL DEFAULT 3');
        }

        // Vérifier et ajouter colonne seuil_alerte_quantite
        final hasSeuilAlerteQuantite = seuilAlerteJoursColumns.any((col) => col['name'] == 'seuil_alerte_quantite');

        if (!hasSeuilAlerteQuantite) {
          await db.execute('ALTER TABLE objet ADD COLUMN seuil_alerte_quantite REAL NOT NULL DEFAULT 1');
        }
      }

      // Migration to version 4: Add commentaires column for durables
      if (oldVersion < 4) {
        // Vérifier et ajouter colonne commentaires
        final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
        final hasCommentaires = objetColumns.any((col) => col['name'] == 'commentaires');

        if (!hasCommentaires) {
          await db.execute('ALTER TABLE objet ADD COLUMN commentaires TEXT');
          print('✅ Migration v4: Added commentaires column to objet table');
        }
      }

      // Migration to version 4: Force add commentaires column for legacy databases
      if (oldVersion < 5) {
        // Toujours vérifier et ajouter colonne commentaires (même si déjà fait en v4)
        final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
        final hasCommentaires = objetColumns.any((col) => col['name'] == 'commentaires');

        if (!hasCommentaires) {
          await db.execute('ALTER TABLE objet ADD COLUMN commentaires TEXT');
          print('✅ Migration v5: Force added commentaires column to objet table');
        } else {
          print('✅ Migration v5: Commentaires column already exists');
        }
      }
    },
  );

  // Debug: Log database structure after initialization
  try {
    final objetColumns = await database.rawQuery("PRAGMA table_info(objet)");
    print('[INIT DEBUG] Objet table structure after migration:');
    for (final col in objetColumns) {
      print('  - ${col['name']}: ${col['type']} ${col['notnull'] == 1 ? 'NOT NULL' : 'NULL'}');
    }
  } catch (e) {
    print('[INIT DEBUG ERROR] Failed to check table structure: $e');
  }

  return database;
}

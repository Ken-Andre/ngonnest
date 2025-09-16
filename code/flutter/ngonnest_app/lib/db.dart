import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const int _databaseVersion = 7; // Incremented version

Future<Database> initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'ngonnest.db');

  return await openDatabase(
    path,
    version: _databaseVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
    onDowngrade: onDatabaseDowngradeDelete, // Prevent downgrades
  );
}

Future<void> _onCreate(Database db, int version) async {
  debugPrint(
    '[DB] Creating new database. Applying V1 schema and migrating to version: $version',
  );
  // Create tables for version 1
  await _createV1Schema(db);
  // Then, apply all subsequent migrations up to the current version
  // This ensures a new install gets all migrations.
  if (version > 1) {
    await _onUpgrade(db, 1, version);
  }
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  debugPrint('[DB] Upgrading database from version $oldVersion to $newVersion');
  for (int i = oldVersion + 1; i <= newVersion; i++) {
    debugPrint('[DB] Applying migration to version $i');
    try {
      await _migrations[i]?.call(db);
      debugPrint('[DB] Successfully applied migration to version $i');
    } catch (e) {
      debugPrint('[DB] Error applying migration to version $i: $e');
      // Consider re-throwing or specific error handling if a migration fails
      rethrow;
    }
  }
}

Future<void> _createV1Schema(Database db) async {
  debugPrint('[DB] Applying V1 schema (foyer, objet_v1, reachat_log)');
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

  // Initial 'objet' table definition (Version 1)
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
      // seuil_alerte_jours, seuil_alerte_quantite, commentaires will be added via migrations
      FOREIGN KEY (id_foyer) REFERENCES foyer (id)
    )
  ''');

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
  debugPrint('[DB] V1 schema applied.');
}

// --- Migration Functions ---

Future<void> _migrateToVersion2(Database db) async {
  debugPrint('[DB Migration V2] Creating alertes table');
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='alertes'",
  );
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
    debugPrint('[DB Migration V2] ✅ alertes table created.');
  } else {
    debugPrint('[DB Migration V2] ✅ alertes table already exists.');
  }
}

Future<void> _migrateToVersion3(Database db) async {
  debugPrint(
    '[DB Migration V3] Adding seuil_alerte_jours and seuil_alerte_quantite to objet table',
  );
  final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");

  bool hasSeuilAlerteJours = objetColumns.any(
    (col) => col['name'] == 'seuil_alerte_jours',
  );
  if (!hasSeuilAlerteJours) {
    await db.execute(
      'ALTER TABLE objet ADD COLUMN seuil_alerte_jours INTEGER DEFAULT 3',
    );
    debugPrint('[DB Migration V3] ✅ seuil_alerte_jours column added.');
  } else {
    debugPrint('[DB Migration V3] ✅ seuil_alerte_jours column already exists.');
  }

  bool hasSeuilAlerteQuantite = objetColumns.any(
    (col) => col['name'] == 'seuil_alerte_quantite',
  );
  if (!hasSeuilAlerteQuantite) {
    await db.execute(
      'ALTER TABLE objet ADD COLUMN seuil_alerte_quantite REAL DEFAULT 1',
    );
    debugPrint('[DB Migration V3] ✅ seuil_alerte_quantite column added.');
  } else {
    debugPrint(
      '[DB Migration V3] ✅ seuil_alerte_quantite column already exists.',
    );
  }
}

Future<void> _migrateToVersion4(Database db) async {
  debugPrint('[DB Migration V4] Adding commentaires column to objet table');
  final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
  bool hasCommentaires = objetColumns.any(
    (col) => col['name'] == 'commentaires',
  );

  if (!hasCommentaires) {
    await db.execute('ALTER TABLE objet ADD COLUMN commentaires TEXT');
    debugPrint('[DB Migration V4] ✅ commentaires column added to objet table.');
  } else {
    debugPrint(
      '[DB Migration V4] ✅ commentaires column already exists in objet table.',
    );
  }
}

Future<void> _migrateToVersion5(Database db) async {
  debugPrint(
    '[DB Migration V5] Ensuring commentaires column exists in objet table',
  );
  final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
  bool hasCommentaires = objetColumns.any(
    (col) => col['name'] == 'commentaires',
  );

  if (!hasCommentaires) {
    await db.execute('ALTER TABLE objet ADD COLUMN commentaires TEXT');
    debugPrint(
      '[DB Migration V5] ✅ commentaires column added (verified/force added).',
    );
  } else {
    debugPrint(
      '[DB Migration V5] ✅ commentaires column already exists (verified).',
    );
  }
}

Future<void> _migrateToVersion6(Database db) async {
  debugPrint('[DB Migration V6] Creating budget_categories table');
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='budget_categories'",
  );
  if (tables.isEmpty) {
    await db.execute('''
      CREATE TABLE budget_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        spent_amount REAL NOT NULL DEFAULT 0,
        month TEXT NOT NULL, -- Format YYYY-MM
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(name, month)
      )
    ''');
    debugPrint('[DB Migration V6] ✅ budget_categories table created.');
  } else {
    debugPrint('[DB Migration V6] ✅ budget_categories table already exists.');
  }
}

Future<void> _migrateToVersion7(Database db) async {
  debugPrint(
    '[DB Migration V7] Adding date_modification column to objet table',
  );
  final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
  bool hasDateModification = objetColumns.any(
    (col) => col['name'] == 'date_modification',
  );

  if (!hasDateModification) {
    await db.execute('ALTER TABLE objet ADD COLUMN date_modification TEXT');
    debugPrint(
      '[DB Migration V7] ✅ date_modification column added to objet table.',
    );
  } else {
    debugPrint(
      '[DB Migration V7] ✅ date_modification column already exists in objet table.',
    );
  }
}

// --- Migrations Map ---

final Map<int, Future<void> Function(Database)> _migrations = {
  2: _migrateToVersion2,
  3: _migrateToVersion3,
  4: _migrateToVersion4,
  5: _migrateToVersion5,
  6: _migrateToVersion6,
  7: _migrateToVersion7,
};

// --- Debug (Optional, can be removed or conditional) ---

Future<void> _debugLogTableStructure(Database db, String tableName) async {
  try {
    final columns = await db.rawQuery("PRAGMA table_info($tableName)");
    debugPrint('[DB DEBUG] $tableName table structure after migrations:');
    for (final col in columns) {
      final colName = col['name'];
      final colType = col['type'];
      final isNotNull = col['notnull'] == 1 ? 'NOT NULL' : 'NULL';
      final isPk = col['pk'] == 1 ? 'PRIMARY KEY' : '';
      final defaultValue = col['dflt_value'] != null
          ? 'DEFAULT ${col['dflt_value']}'
          : '';
      debugPrint(
        '  - $colName: $colType $isNotNull $isPk $defaultValue'.trim(),
      );
    }
    final currentDbVersion = await db.getVersion(); // Renamed to avoid conflict
    debugPrint('[DB DEBUG] Database version: $currentDbVersion');
  } catch (err) {
    // Renamed to avoid conflict
    debugPrint('[DB DEBUG ERROR] Failed to get $tableName structure: $err');
  }
}

Future<void> initDatabaseAndDebug() async {
  final db = await initDatabase();
  await _debugLogTableStructure(db, 'foyer');
  await _debugLogTableStructure(db, 'objet');
  await _debugLogTableStructure(db, 'alertes'); // Corrected this line
  await _debugLogTableStructure(db, 'budget_categories');
  await _debugLogTableStructure(db, 'reachat_log');
  // db.close(); // Close if only for debug
}

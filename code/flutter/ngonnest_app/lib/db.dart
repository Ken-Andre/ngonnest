import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io'; // Required for Directory

import 'services/analytics_service.dart';

const int _databaseVersion =
    11; // Added sync_outbox table for offline-first sync

Future<Database> initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'ngonnest.db');

  // Ensure the databases directory exists
  try {
    final directory = Directory(databasesPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  } catch (e) {
    // If we can't create the directory, we'll let the database handle the error
    debugPrint('Failed to create database directory: $e');
  }

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

  // Track migration attempt
  final analytics = AnalyticsService();
  await analytics.logMigrationAttempt(oldVersion, newVersion);

  final stopwatch = Stopwatch()..start();

  try {
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      debugPrint('[DB] Applying migration to version $i');
      await _migrations[i]?.call(db);
      debugPrint('[DB] Successfully applied migration to version $i');
    }

    stopwatch.stop();
    // Track successful migration
    await analytics.logMigrationSuccess(
      oldVersion,
      newVersion,
      stopwatch.elapsedMilliseconds,
    );
  } catch (e) {
    stopwatch.stop();
    debugPrint(
      '[DB] Error applying migration from $oldVersion to $newVersion: $e',
    );

    // Track failed migration
    await analytics.logMigrationFailure(
      oldVersion,
      newVersion,
      e.toString().substring(0, 50), // Truncate error for analytics
    );

    rethrow;
  }
}
// }

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
      consommation_jour REAL, -- seuil_alerte_jours, seuil_alerte_quantite, commentaires will be added via migrations
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

Future<void> _migrateToVersion8(Database db) async {
  debugPrint('[DB Migration V8] Creating product_prices table for Phase 2');
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='product_prices'",
  );
  if (tables.isEmpty) {
    await db.execute('''
      CREATE TABLE product_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price_fcfa REAL NOT NULL,
        price_euro REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'piece',
        brand TEXT,
        description TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create optimized indexes for faster searches
    await db.execute(
      'CREATE INDEX idx_product_prices_name ON product_prices(name)',
    );
    await db.execute(
      'CREATE INDEX idx_product_prices_category ON product_prices(category)',
    );
    await db.execute(
      'CREATE INDEX idx_product_prices_name_category ON product_prices(name, category)',
    );

    debugPrint('[DB Migration V8] ✅ product_prices table created.');
  } else {
    debugPrint('[DB Migration V8] ✅ product_prices table already exists.');
  }
}

Future<void> _migrateToVersion9(Database db) async {
  debugPrint(
    '[DB Migration V9] Adding performance indexes for Phase 3 optimization',
  );

  // Add missing indexes for frequently queried tables
  try {
    // Index for objet table - most frequent queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_objet_foyer ON objet(id_foyer)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_objet_categorie ON objet(categorie)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_objet_type ON objet(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_objet_date_rupture ON objet(date_rupture_prev)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_objet_quantite ON objet(quantite_restante)',
    );

    // Index for alertes table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alertes_objet ON alertes(id_objet)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alertes_type ON alertes(type_alerte)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alertes_lu ON alertes(lu)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alertes_date ON alertes(date_creation)',
    );

    // Index for budget_categories table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_month ON budget_categories(month)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_name_month ON budget_categories(name, month)',
    );

    // Index for reachat_log table
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reachat_objet ON reachat_log(id_objet)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reachat_date ON reachat_log(date)',
    );

    debugPrint('[DB Migration V9] ✅ Performance indexes created.');
  } catch (e) {
    debugPrint('[DB Migration V9] ⚠️ Some indexes may already exist: $e');
  }
}

Future<void> _migrateToVersion10(Database db) async {
  debugPrint(
    '[DB Migration V10] Adding room column to objet table for import compatibility',
  );
  final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
  bool hasRoom = objetColumns.any((col) => col['name'] == 'room');

  if (!hasRoom) {
    await db.execute('ALTER TABLE objet ADD COLUMN room TEXT');
    debugPrint('[DB Migration V10] ✅ room column added to objet table.');
  } else {
    debugPrint(
      '[DB Migration V10] ✅ room column already exists in objet table.',
    );
  }
}

Future<void> _migrateToVersion11(Database db) async {
  debugPrint(
    '[DB Migration V11] Creating sync_outbox table for offline-first sync',
  );
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_outbox'",
  );
  if (tables.isEmpty) {
    await db.execute('''
      CREATE TABLE sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL CHECK (operation_type IN ('CREATE', 'UPDATE', 'DELETE')),
        entity_type TEXT NOT NULL CHECK (entity_type IN ('objet', 'foyer', 'reachat_log', 'budget_categories')),
        entity_id INTEGER NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_retry_at TEXT,
        status TEXT NOT NULL CHECK (status IN ('pending', 'syncing', 'synced', 'failed')) DEFAULT 'pending',
        error_message TEXT
      )
    ''');

    // Index pour optimiser les requêtes de sync
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_status ON sync_outbox(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_created ON sync_outbox(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_outbox_entity ON sync_outbox(entity_type, entity_id)',
    );

    debugPrint('[DB Migration V11] ✅ sync_outbox table created.');
  } else {
    debugPrint('[DB Migration V11] ✅ sync_outbox table already exists.');
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
  8: _migrateToVersion8,
  9: _migrateToVersion9,
  10: _migrateToVersion10,
  11: _migrateToVersion11,
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
  await _debugLogTableStructure(db, 'product_prices');
  await _debugLogTableStructure(db, 'reachat_log');
  await _debugLogTableStructure(db, 'sync_outbox');
  // db.close(); // Close if only for debug
}

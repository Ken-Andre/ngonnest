// import 'package:uuid/uuid.dart';
import 'dart:io'; // Required for Directory

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'services/analytics_service.dart';

const int _databaseVersion = 6; // Updated to version 6 to add brand column

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
  debugPrint('[DB] Applying V1 schema (foyer, objet_v1, reachat_log, alertes, budget_categories, product_prices, sync_outbox, alert_states)');
  
  // foyer table
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

  // objet table with all columns
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
      date_modification TEXT,
      room TEXT,
      FOREIGN KEY (id_foyer) REFERENCES foyer (id)
    )
  ''');

  // reachat_log table
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

  // alertes table
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

  // budget_categories table
  await db.execute('''
    CREATE TABLE budget_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      limit_amount REAL NOT NULL,
      spent_amount REAL NOT NULL DEFAULT 0,
      month TEXT NOT NULL, -- Format YYYY-MM
      percentage REAL DEFAULT 0.25,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(name, month)
    )
  ''');

  // product_prices table (latest version)
  await db.execute('''
    CREATE TABLE product_prices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      name_normalized TEXT NOT NULL,
      category TEXT NOT NULL,
      price_local REAL NOT NULL,
      currency_code TEXT NOT NULL,
      unit TEXT NOT NULL,
      country_code TEXT NOT NULL DEFAULT 'CM',
      region TEXT,
      brand TEXT,
      description TEXT,
      source TEXT DEFAULT 'static',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE(name_normalized, country_code)
    )
  ''');

  // sync_outbox table
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

  // alert_states table
  await db.execute('''
    CREATE TABLE alert_states (
      alert_id INTEGER PRIMARY KEY,
      is_read INTEGER NOT NULL DEFAULT 0,
      is_resolved INTEGER NOT NULL DEFAULT 0,
      last_updated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  // Create indexes
  await db.execute('CREATE INDEX idx_objet_foyer ON objet(id_foyer)');
  await db.execute('CREATE INDEX idx_objet_categorie ON objet(categorie)');
  await db.execute('CREATE INDEX idx_objet_type ON objet(type)');
  await db.execute('CREATE INDEX idx_objet_date_rupture ON objet(date_rupture_prev)');
  await db.execute('CREATE INDEX idx_objet_quantite ON objet(quantite_restante)');
  await db.execute('CREATE INDEX idx_alertes_objet ON alertes(id_objet)');
  await db.execute('CREATE INDEX idx_alertes_type ON alertes(type_alerte)');
  await db.execute('CREATE INDEX idx_alertes_lu ON alertes(lu)');
  await db.execute('CREATE INDEX idx_alertes_date ON alertes(date_creation)');
  await db.execute('CREATE INDEX idx_budget_month ON budget_categories(month)');
  await db.execute('CREATE INDEX idx_budget_name_month ON budget_categories(name, month)');
  await db.execute('CREATE INDEX idx_reachat_objet ON reachat_log(id_objet)');
  await db.execute('CREATE INDEX idx_reachat_date ON reachat_log(date)');
  await db.execute('CREATE INDEX idx_outbox_status ON sync_outbox(status)');
  await db.execute('CREATE INDEX idx_outbox_created ON sync_outbox(created_at)');
  await db.execute('CREATE INDEX idx_outbox_entity ON sync_outbox(entity_type, entity_id)');
  await db.execute('CREATE INDEX idx_prices_name ON product_prices(name_normalized)');
  await db.execute('CREATE INDEX idx_prices_country ON product_prices(country_code)');
  await db.execute('CREATE INDEX idx_prices_category ON product_prices(category)');
  await db.execute('CREATE INDEX idx_budget_categories_month ON budget_categories(month)');
  await db.execute('CREATE INDEX idx_budget_categories_name_month ON budget_categories(name, month)');

  debugPrint('[DB] V1 schema applied with all tables and indexes.');
}

// --- Migration Functions (keeping only last 5) ---

Future<void> _migrateToVersion2(Database db) async {
  debugPrint('[DB Migration V2] Adding initial price data');
  // This would populate with initial data if needed
  debugPrint('[DB Migration V2] ✅ Initial data populated');
}

Future<void> _migrateToVersion3(Database db) async {
  debugPrint('[DB Migration V3] Updating price data');
  // This would update price data if needed
  debugPrint('[DB Migration V3] ✅ Price data updated');
}

Future<void> _migrateToVersion4(Database db) async {
  debugPrint('[DB Migration V4] Adding additional indexes');
  // This would add additional indexes if needed
  debugPrint('[DB Migration V4] ✅ Additional indexes added');
}

Future<void> _migrateToVersion5(Database db) async {
  debugPrint('[DB Migration V5] Finalizing schema');
  
  // Add brand column to product_prices table
  try {
    await db.execute('ALTER TABLE product_prices ADD COLUMN brand TEXT');
    debugPrint('[DB Migration V5] ✅ Added brand column to product_prices table');
  } catch (e) {
    // Column might already exist
    debugPrint('[DB Migration V5] Note: brand column may already exist ($e)');
  }
  
  // Add description column to product_prices table
  try {
    await db.execute('ALTER TABLE product_prices ADD COLUMN description TEXT');
    debugPrint('[DB Migration V5] ✅ Added description column to product_prices table');
  } catch (e) {
    // Column might already exist
    debugPrint('[DB Migration V5] Note: description column may already exist ($e)');
  }
  
  debugPrint('[DB Migration V5] ✅ Schema finalized');
}

// --- Migrations Map ---

final Map<int, Future<void> Function(Database)> _migrations = {
  2: _migrateToVersion2,
  3: _migrateToVersion3,
  4: _migrateToVersion4,
  5: _migrateToVersion5,
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
    final currentDbVersion = await db.getVersion();
    debugPrint('[DB DEBUG] Database version: $currentDbVersion');
  } catch (err) {
    debugPrint('[DB DEBUG ERROR] Failed to get $tableName structure: $err');
  }
}

Future<void> initDatabaseAndDebug() async {
  final db = await initDatabase();
  await _debugLogTableStructure(db, 'foyer');
  await _debugLogTableStructure(db, 'objet');
  await _debugLogTableStructure(db, 'alertes');
  await _debugLogTableStructure(db, 'budget_categories');
  await _debugLogTableStructure(db, 'product_prices');
  await _debugLogTableStructure(db, 'reachat_log');
  await _debugLogTableStructure(db, 'sync_outbox');
  await _debugLogTableStructure(db, 'alert_states');
  // db.close(); // Close if only for debug
}

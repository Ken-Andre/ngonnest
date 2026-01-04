import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:path/path.dart';

/// Helper class for creating test databases with sample data
/// Used for UUID migration testing
class TestDatabaseHelper {
  /// Creates a test database with sample data at version 12 (pre-UUID)
  static Future<Database> createTestDatabaseV12() async {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Create in-memory database
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 12,
      onCreate: (db, version) async {
        await _createV12Schema(db);
        await _insertSampleData(db);
      },
    );

    return db;
  }

  /// Creates the v12 schema (INTEGER IDs)
  static Future<void> _createV12Schema(Database db) async {
    // Create foyer table
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

    // Create objet table
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

    // Create budget_categories table
    await db.execute('''
      CREATE TABLE budget_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        spent REAL NOT NULL DEFAULT 0,
        percentage REAL NOT NULL DEFAULT 0.25,
        month TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(name, month)
      )
    ''');

    // Create alertes table
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

    // Create reachat_log table
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

    // Create product_prices table
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

    // Create sync_outbox table
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

    // Create indexes
    await db.execute('CREATE INDEX idx_objet_foyer ON objet(id_foyer)');
    await db.execute('CREATE INDEX idx_alertes_objet ON alertes(id_objet)');
    await db.execute('CREATE INDEX idx_reachat_objet ON reachat_log(id_objet)');
  }

  /// Inserts sample data for testing
  static Future<void> _insertSampleData(Database db) async {
    // Insert sample foyer
    await db.insert('foyer', {
      'id': 1,
      'nb_personnes': 4,
      'nb_pieces': 5,
      'type_logement': 'appartement',
      'langue': 'fr',
      'budget_mensuel_estime': 150000.0,
    });

    await db.insert('foyer', {
      'id': 2,
      'nb_personnes': 2,
      'nb_pieces': 3,
      'type_logement': 'maison',
      'langue': 'fr',
      'budget_mensuel_estime': 100000.0,
    });

    // Insert sample objets
    await db.insert('objet', {
      'id': 1,
      'id_foyer': 1,
      'nom': 'Riz',
      'categorie': 'Alimentation',
      'type': 'consommable',
      'date_achat': '2024-01-01',
      'quantite_initiale': 10.0,
      'quantite_restante': 5.0,
      'unite': 'kg',
      'prix_unitaire': 1500.0,
      'room': 'Cuisine',
    });

    await db.insert('objet', {
      'id': 2,
      'id_foyer': 1,
      'nom': 'Huile',
      'categorie': 'Alimentation',
      'type': 'consommable',
      'date_achat': '2024-01-05',
      'quantite_initiale': 5.0,
      'quantite_restante': 2.0,
      'unite': 'L',
      'prix_unitaire': 2000.0,
      'room': 'Cuisine',
    });

    await db.insert('objet', {
      'id': 3,
      'id_foyer': 2,
      'nom': 'Savon',
      'categorie': 'Hygiène',
      'type': 'consommable',
      'date_achat': '2024-01-10',
      'quantite_initiale': 12.0,
      'quantite_restante': 8.0,
      'unite': 'pièce',
      'prix_unitaire': 500.0,
      'room': 'Salle de bain',
    });

    // Insert sample budget categories
    await db.insert('budget_categories', {
      'id': 1,
      'name': 'Alimentation',
      'limit_amount': 50000.0,
      'spent': 15000.0,
      'percentage': 0.33,
      'month': '2024-01',
      'created_at': '2024-01-01T00:00:00',
      'updated_at': '2024-01-01T00:00:00',
    });

    await db.insert('budget_categories', {
      'id': 2,
      'name': 'Hygiène',
      'limit_amount': 20000.0,
      'spent': 5000.0,
      'percentage': 0.13,
      'month': '2024-01',
      'created_at': '2024-01-01T00:00:00',
      'updated_at': '2024-01-01T00:00:00',
    });

    // Insert sample alertes
    await db.insert('alertes', {
      'id': 1,
      'id_objet': 1,
      'type_alerte': 'stock_faible',
      'titre': 'Stock faible',
      'message': 'Le stock de Riz est faible',
      'urgences': 'medium',
      'date_creation': '2024-01-15T10:00:00',
      'lu': 0,
      'resolu': 0,
    });

    // Insert sample reachat_log
    await db.insert('reachat_log', {
      'id': 1,
      'id_objet': 1,
      'date': '2024-01-01',
      'quantite': 10.0,
      'prix_total': 15000.0,
    });

    // Insert sample product_prices
    await db.insert('product_prices', {
      'id': 1,
      'name': 'Riz',
      'category': 'Alimentation',
      'price_fcfa': 1500.0,
      'price_euro': 2.29,
      'unit': 'kg',
      'created_at': '2024-01-01T00:00:00',
      'updated_at': '2024-01-01T00:00:00',
    });

    // Insert sample sync_outbox
    await db.insert('sync_outbox', {
      'id': 1,
      'operation_type': 'CREATE',
      'entity_type': 'objet',
      'entity_id': 1,
      'payload': '{"id":1,"nom":"Riz"}',
      'created_at': '2024-01-01T00:00:00',
      'retry_count': 0,
      'status': 'pending',
    });
  }

  /// Gets record counts for verification
  static Future<Map<String, int>> getRecordCounts(Database db) async {
    final counts = <String, int>{};

    final tables = [
      'foyer',
      'objet',
      'budget_categories',
      'alertes',
      'reachat_log',
      'product_prices',
      'sync_outbox',
    ];

    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      counts[table] = result.first['count'] as int;
    }

    return counts;
  }

  /// Verifies foreign key integrity
  static Future<bool> verifyForeignKeyIntegrity(Database db) async {
    try {
      // Check objet.id_foyer references foyer.id
      final orphanedObjets = await db.rawQuery('''
        SELECT COUNT(*) as count FROM objet 
        WHERE id_foyer NOT IN (SELECT id FROM foyer)
      ''');

      if ((orphanedObjets.first['count'] as int) > 0) {
        return false;
      }

      // Check alertes.id_objet references objet.id
      final orphanedAlertes = await db.rawQuery('''
        SELECT COUNT(*) as count FROM alertes 
        WHERE id_objet IS NOT NULL 
        AND id_objet NOT IN (SELECT id FROM objet)
      ''');

      if ((orphanedAlertes.first['count'] as int) > 0) {
        return false;
      }

      // Check reachat_log.id_objet references objet.id
      final orphanedReachat = await db.rawQuery('''
        SELECT COUNT(*) as count FROM reachat_log 
        WHERE id_objet NOT IN (SELECT id FROM objet)
      ''');

      if ((orphanedReachat.first['count'] as int) > 0) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

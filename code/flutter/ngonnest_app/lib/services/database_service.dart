import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import '../models/foyer.dart';
import '../models/objet.dart';
import '../models/alert.dart';
import '../db.dart';
import 'error_logger_service.dart';

class DatabaseService {
  static Database? _database;
  static bool _isConnected = false;
  static bool _isInitializing = false;
  static DateTime? _lastConnectionCheck;
  static int _connectionRetryCount = 0;
  static const int _maxRetryAttempts = 3;
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _connectionValidationInterval = Duration(minutes: 5);
  static final _lock = Lock(); // Thread-safe synchronization

  /// Enhanced getter with proper lifecycle management and synchronization
  Future<Database> get database async {
    // Fast path: return existing connection if available and truly open
    if (_database != null && _isConnected && _database!.isOpen) {
      return _database!;
    }

    // Use synchronization for connection management
    return await _lock.synchronized(() async {
      // Double-check after acquiring lock
      if (_database != null && _isConnected && _database!.isOpen) {
        return _database!;
      }

      // Prevent concurrent initialization
      if (_isInitializing) {
        await _waitForInitialization();
        if (_database != null && _isConnected && _database!.isOpen) {
          return _database!;
        }
      }

      return await _establishDatabaseConnection();
    });
  }

  /// Establish database connection with retry logic and timeout
  Future<Database> _establishDatabaseConnection() async {
    _isInitializing = true;

    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        print('[DatabaseService] Establishing database connection (attempt $attempt/$_maxRetryAttempts)...');

        if (_database != null && !_isConnected) {
          print('[DatabaseService] Connection lost, attempting recovery...');
          await _logDatabaseError(
            'connection_recovery_attempted',
            'Database connection was lost, attempting automatic recovery',
            severity: ErrorSeverity.medium,
            metadata: {'attempt': attempt, 'max_attempts': _maxRetryAttempts},
          );
        }

        // Use timeout for database initialization
        _database = await initDatabase().timeout(_connectionTimeout);

        // Validate connection immediately after creation
        await _validateNewConnection();

        _isConnected = true;
        _lastConnectionCheck = DateTime.now();
        _connectionRetryCount = 0;

        print('[DatabaseService] Database connection established successfully');
        return _database!;

      } catch (e, stackTrace) {
        _isConnected = false;
        _connectionRetryCount++;

        print('[DatabaseService] Connection attempt $attempt failed: $e');

        await _logDatabaseError(
          'connection_failed',
          'Failed to establish database connection',
          error: e,
          stackTrace: stackTrace,
          severity: attempt == _maxRetryAttempts ? ErrorSeverity.critical : ErrorSeverity.high,
          metadata: {
            'attempt': attempt,
            'max_attempts': _maxRetryAttempts,
            'retry_count': _connectionRetryCount,
            'timestamp': DateTime.now().toIso8601String()
          },
        );

        if (attempt == _maxRetryAttempts) {
          print('[DatabaseService] All connection attempts failed, giving up');
          rethrow;
        }

        // Wait before retrying (exponential backoff)
        final waitTime = Duration(seconds: attempt * 2);
        print('[DatabaseService] Waiting ${waitTime.inSeconds}s before retry...');
        await Future.delayed(waitTime);
      }
    }

    _isInitializing = false;
    throw Exception('Failed to establish database connection after $_maxRetryAttempts attempts');
  }

  /// Remove all user data from the database
  Future<void> clearAllData() async {
    final db = await database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    for (final table in tables) {
      final tableName = table['name'] as String;
      if (tableName != 'android_metadata') {
        await db.delete(tableName);
      }
    }
  }

  /// Validate that a newly created connection is working
  Future<void> _validateNewConnection() async {
    try {
      // Simple validation query
      await _database!.rawQuery('SELECT 1');
      print('[DatabaseService] New connection validated successfully');
    } catch (e) {
      print('[DatabaseService] New connection validation failed: $e');
      _isConnected = false;
      await _logDatabaseError(
        'connection_validation_failed',
        'Failed to validate new database connection',
        error: e,
        severity: ErrorSeverity.high,
      );
      throw e;
    }
  }

  /// Check if current connection is still valid
  Future<bool> _isConnectionStillValid() async {
    if (_database == null) return false;

    // Check if we need to validate based on time interval
    final now = DateTime.now();
    if (_lastConnectionCheck != null &&
        now.difference(_lastConnectionCheck!) < _connectionValidationInterval) {
      return true; // Skip validation if recently checked
    }

    try {
      await _database!.rawQuery('SELECT 1').timeout(const Duration(seconds: 5));
      _lastConnectionCheck = now;
      return true;
    } catch (e) {
      print('[DatabaseService] Connection validation failed: $e');
      _isConnected = false;
      await _logDatabaseError(
        'connection_validation_failed',
        'Database connection validation failed during periodic check',
        error: e,
        severity: ErrorSeverity.medium,
      );
      return false;
    }
  }

  // Foyer operations
  Future<Foyer?> getFoyer() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foyer', limit: 1);
    if (maps.isEmpty) return null;
    return Foyer.fromMap(maps.first);
  }

  Future<int> insertFoyer(Foyer foyer) async {
    final db = await database;
    return await db.insert('foyer', foyer.toMap());
  }

  Future<int> updateFoyer(Foyer foyer) async {
    final db = await database;
    return await db.update(
      'foyer',
      foyer.toMap(),
      where: 'id = ?',
      whereArgs: [foyer.id],
    );
  }

  Future<int> deleteFoyer(int id) async {
    final db = await database;
    return await db.delete(
      'foyer',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Objet operations
  Future<List<Objet>> getObjets({int? idFoyer, TypeObjet? type}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (idFoyer != null) {
      whereClause = 'id_foyer = ?';
      whereArgs.add(idFoyer);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.toString().split('.').last);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'objet',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'categorie ASC, nom ASC',
    );

    return List.generate(maps.length, (i) => Objet.fromMap(maps[i]));
  }

  Future<Objet?> getObjet(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'objet',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Objet.fromMap(maps.first);
  }

  Future<int> insertObjet(Objet objet) async {
    final db = await database;
    try {
      return await db.insert('objet', objet.toMap());
    } catch (e) {
      // Handle legacy database without commentaires column
      if (e.toString().contains('no column named commentaires')) {
        print('[DatabaseService] Legacy database detected, adding commentaires column...');
        try {
          await db.execute('ALTER TABLE objet ADD COLUMN commentaires TEXT');
          print('✅ Auto-migration: Added commentaires column successfully');
          // Retry the insert after adding the column
          return await db.insert('objet', objet.toMap());
        } catch (migrationError) {
          print('[DatabaseService] Failed to add commentaires column: $migrationError');
          await _logDatabaseError(
            'auto_migration_failed',
            'Failed to auto-add commentaires column to legacy database',
            error: migrationError,
            severity: ErrorSeverity.high,
          );
          rethrow;
        }
      }
      // Re-throw other errors
      await _logDatabaseError(
        'insert_objet_failed',
        'Failed to insert objet into database',
        error: e,
        severity: ErrorSeverity.medium,
      );
      rethrow;
    }
  }

  Future<int> updateObjet(Objet objet) async {
    final db = await database;
    return await db.update(
      'objet',
      objet.toMap(),
      where: 'id = ?',
      whereArgs: [objet.id],
    );
  }

  Future<int> deleteObjet(int id) async {
    final db = await database;
    return await db.delete(
      'objet',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total object count
  Future<int> getTotalObjetCount(int idFoyer) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM objet WHERE id_foyer = ?', [idFoyer]));
    return count ?? 0;
  }

  // Get expiring soon object count
  Future<int> getExpiringSoonObjetCount(int idFoyer) async {
    final db = await database;
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: 5));

    final count = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM objet 
      WHERE id_foyer = ? 
      AND (
        (type = 'consommable' AND quantite_restante <= seuil_alerte_quantite)
        OR (type = 'consommable' AND date_rupture_prev IS NOT NULL AND date_rupture_prev <= ?)
        OR (type = 'durable' AND date_achat IS NOT NULL AND duree_vie_prev_jours IS NOT NULL 
            AND date(?, '+' || duree_vie_prev_jours || ' days') <= ?)
      )
    ''', [
      idFoyer,
      now.add(const Duration(days: 3)).toIso8601String(),
      now.toIso8601String(),
      now.add(const Duration(days: 3)).toIso8601String(),
    ]));
    return count ?? 0;
  }

  // Get objects with alerts (for dashboard)
  Future<List<Objet>> getObjetsWithAlerts(int idFoyer) async {
    final db = await database;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM objet 
      WHERE id_foyer = ? 
      AND (
        (type = 'consommable' AND quantite_restante <= seuil_alerte_quantite)
        OR (type = 'consommable' AND date_rupture_prev IS NOT NULL AND date_rupture_prev <= ?)
        OR (type = 'durable' AND date_achat IS NOT NULL AND duree_vie_prev_jours IS NOT NULL 
            AND date(?, '+' || duree_vie_prev_jours || ' days') <= ?)
      )
      ORDER BY 
        CASE 
          WHEN type = 'consommable' AND quantite_restante <= seuil_alerte_quantite THEN 1
          WHEN type = 'consommable' AND date_rupture_prev IS NOT NULL AND date_rupture_prev <= ? THEN 2
          ELSE 3
        END,
        categorie ASC, nom ASC
    ''', [
      idFoyer,
      now.add(const Duration(days: 3)).toIso8601String(),
      now.toIso8601String(),
      now.add(const Duration(days: 3)).toIso8601String(),
      now.add(const Duration(days: 3)).toIso8601String(),
    ]);

    return List.generate(maps.length, (i) => Objet.fromMap(maps[i]));
  }

  // Get budget calculation
  Future<Map<String, double>> getBudgetMensuel(int idFoyer) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        categorie,
        SUM(
          CASE 
            WHEN methode_prevision = 'frequence' THEN (prix_unitaire * 30.0 / frequence_achat_jours)
            WHEN methode_prevision = 'debit' THEN (prix_unitaire * consommation_jour * 30.0 / taille_conditionnement)
            ELSE 0
          END
        ) as budget_categorie
      FROM objet 
      WHERE id_foyer = ? 
      AND type = 'consommable' 
      AND prix_unitaire IS NOT NULL
      AND (
        (methode_prevision = 'frequence' AND frequence_achat_jours > 0)
        OR (methode_prevision = 'debit' AND consommation_jour > 0 AND taille_conditionnement > 0)
      )
      GROUP BY categorie
    ''', [idFoyer]);

    final Map<String, double> budget = {};
    for (final map in maps) {
      budget[map['categorie']] = map['budget_categorie'];
    }
    return budget;
  }

  // Alert operations (US-2.1 & US-2.4)
  Future<List<Alert>> getAlerts({int? idFoyer, bool? unreadOnly}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (idFoyer != null) {
      // Join with objet table to filter by foyer
      final sql = '''
        SELECT a.* FROM alertes a
        INNER JOIN objet o ON a.id_objet = o.id
        WHERE o.id_foyer = ?
        ${unreadOnly == true ? 'AND a.lu = 0' : ''}
        ORDER BY a.date_creation DESC
      ''';
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [idFoyer]);
      return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
    } else {
      if (unreadOnly == true) {
        whereClause = 'lu = 0';
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'alertes',
        where: whereClause.isEmpty ? null : whereClause,
        orderBy: 'date_creation DESC',
      );
      return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
    }
  }

  Future<Alert?> getAlert(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alertes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Alert.fromMap(maps.first);
  }

  Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert('alertes', alert.toMap());
  }

  Future<int> updateAlert(Alert alert) async {
    final db = await database;
    return await db.update(
      'alertes',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return await db.delete(
      'alertes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insert objet and generate associated alerts
  Future<int> insertObjetWithAlerts(Objet objet, int idFoyer) async {
    final db = await database;
    final objetId = await db.insert('objet', objet.toMap());
    if (objetId > 0) {
      await generateAlerts(idFoyer); // Generate alerts after inserting the object
    }
    return objetId;
  }

  Future<int> markAlertAsRead(int id) async {
    final db = await database;
    return await db.update(
      'alertes',
      {
        'lu': 1,
        'date_lecture': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllReadAlerts(int idFoyer) async {
    final db = await database;
    final sql = '''
      DELETE FROM alertes
      WHERE lu = 1 AND id_objet IN (
        SELECT id FROM objet WHERE id_foyer = ?
      )
    ''';
    return await db.rawDelete(sql, [idFoyer]);
  }

  // Generate alerts for low stock and expiry (US-2.4)
  Future<void> generateAlerts(int idFoyer) async {
    final db = await database;
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: 5));

    // Generate low stock alerts
    await db.rawInsert('''
      INSERT INTO alertes (id_objet, type_alerte, titre, message, urgences, date_creation, lu, resolu)
      SELECT
        o.id,
        'stock_faible',
        'Stock faible',
        o.nom || ' est en rupture de stock (quantité restante: ' || o.quantite_restante || ')',
        CASE WHEN o.quantite_restante <= 1 THEN 'high' ELSE 'medium' END,
        ?,
        0,
        0
      FROM objet o
      LEFT JOIN alertes a ON a.id_objet = o.id AND a.type_alerte = 'stock_faible' AND a.resolu = 0
      WHERE o.id_foyer = ?
        AND o.type = 'consommable'
        AND o.quantite_restante <= o.seuil_alerte_quantite
        AND a.id IS NULL
    ''', [now.toIso8601String(), idFoyer]);

    // Generate expiry alerts
    await db.rawInsert('''
      INSERT INTO alertes (id_objet, type_alerte, titre, message, urgences, date_creation, lu, resolu)
      SELECT
        o.id,
        'expiration_proche',
        'Expiration proche',
        o.nom || ' expire bientôt (le ' || date(o.date_rupture_prev) || ')',
        CASE WHEN date(o.date_rupture_prev) <= date(?) THEN 'high' ELSE 'medium' END,
        ?,
        0,
        0
      FROM objet o
      LEFT JOIN alertes a ON a.id_objet = o.id AND a.type_alerte = 'expiration_proche' AND a.resolu = 0
      WHERE o.id_foyer = ?
        AND o.date_rupture_prev IS NOT NULL
        AND date(o.date_rupture_prev) <= date(?)
        AND a.id IS NULL
    ''', [now.add(const Duration(days: 2)).toIso8601String(), now.toIso8601String(), idFoyer, warningDate.toIso8601String()]);
  }

  /// Helper method to wait for concurrent initialization to complete
  static Future<void> _waitForInitialization() async {
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Centralized logging method for database errors with metadata
  static Future<void> _logDatabaseError(
    String operation,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      Map<String, dynamic> enhancedMetadata = {
        'is_connected': _isConnected,
        'is_initializing': _isInitializing,
        'last_connection_check': _lastConnectionCheck?.toIso8601String(),
        ...?metadata,
      };

      await ErrorLoggerService.logError(
        component: 'DatabaseService',
        operation: operation,
        error: error ?? 'Database connection lost - automatic recovery recommended',
        stackTrace: stackTrace ?? StackTrace.current,
        severity: severity,
        metadata: enhancedMetadata,
      );
    } catch (logError) {
      // Fallback console logging if ErrorLoggerService fails
      print('[DatabaseService.FALLBACK] $operation: $message');
      if (error != null) {
        print('  Original error: $error');
      }
    }
  }

  /// Check if database connection is still valid
  Future<bool> isConnectionValid() async {
    if (_database == null) return false;

    try {
      await _database!.query('foyer', limit: 1);
      _lastConnectionCheck = DateTime.now();
      return true;
    } catch (e) {
      _isConnected = false;
      print('[DatabaseService] Connection validation failed: $e');
      await _logDatabaseError(
        'connection_validation_failed',
        'Database connection validation failed',
        error: e,
        stackTrace: StackTrace.current,
        severity: ErrorSeverity.high,
      );
      return false;
    }
  }

  /// Emergency close database - ONLY CALL FROM MAIN APP SHUTDOWN
  /// This method should NEVER be called during normal app operation
  /// It will break all database operations until app restart
  Future<void> close() async {
    await _lock.synchronized(() async {
      if (_database != null) {
        final db = _database!;
        _database = null;
        _isConnected = false;
        _isInitializing = false;
        _lastConnectionCheck = null;
        _connectionRetryCount = 0;

        try {
          await db.close();
          print('[DatabaseService] ⚠️  Database EMERGENCY closed successfully');
          print('[DatabaseService] ⚠️  WARNING: All database operations will fail until app restart!');
        } catch (e) {
          print('[DatabaseService] Error during emergency close: $e');
        }
      }
    });
  }

  /// Get database connection status for debugging
  Map<String, dynamic> getConnectionStatus() {
    return {
      'is_connected': _isConnected,
      'is_initializing': _isInitializing,
      'has_database': _database != null,
      'is_open': _database?.isOpen ?? false,
      'last_check': _lastConnectionCheck?.toIso8601String(),
      'retry_count': _connectionRetryCount,
    };
  }

  /// Debug method: Check table structure
  Future<void> debugTableStructure() async {
    final db = await database;
    try {
      final objetColumns = await db.rawQuery("PRAGMA table_info(objet)");
      print('[DEBUG] Objet table structure:');
      for (final col in objetColumns) {
        print('  - ${col['name']}: ${col['type']} ${col['notnull'] == 1 ? 'NOT NULL' : 'NULL'} ${col['dflt_value'] != null ? 'DEFAULT ${col['dflt_value']}' : ''}');
      }

      final dbVersion = await db.getVersion();
      print('[DEBUG] Database version: $dbVersion');
    } catch (e) {
      print('[DEBUG ERROR] Failed to get table structure: $e');
    }
  }
}

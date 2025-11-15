import 'dart:async';

import 'package:flutter/foundation.dart'; // Required for kDebugMode
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../db.dart';
import '../models/alert.dart';
import '../models/foyer.dart';
import '../models/objet.dart';
import 'error_logger_service.dart';

/// Service centralisé pour la gestion de la base de données SQLite
///
/// Implémente le pattern Singleton avec gestion des connexions,
/// retry automatique et optimisations de performance pour NgonNest.
///
/// Fonctionnalités principales:
/// - Gestion thread-safe des connexions SQLite
/// - Retry automatique en cas d'échec
/// - Cache des connexions avec validation périodique
/// - Optimisations mémoire et performance
/// - Logging des erreurs intégré
class DatabaseService {
  static Database? _database;
  static bool _isConnected = false;
  static bool _isInitializing = false;
  static DateTime? _lastConnectionCheck;
  static int _connectionRetryCount = 0;
  static const int _maxConnectionRetryAttempts = 3;
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _connectionValidationInterval = Duration(minutes: 5);
  static final _lock = Lock(); // Thread-safe synchronization

  // For general DB operations retry
  static const int _maxDbOperationRetries = 2;
  static const Duration _dbOperationRetryDelay = Duration(milliseconds: 200);

  Future<Database> get database async {
    if (_database != null && _isConnected && _database!.isOpen) {
      if (await _isConnectionStillValid()) {
        return _database!;
      }
      if (kDebugMode) {
        print(
          '[DatabaseService] Cached connection is no longer valid. Re-establishing.',
        );
      }
    }

    return await _lock.synchronized(() async {
      if (_database != null && _isConnected && _database!.isOpen) {
        if (await _isConnectionStillValid()) {
          return _database!;
        }
      }
      if (_isInitializing) {
        await _waitForInitialization();
        if (_database != null &&
            _isConnected &&
            _database!.isOpen &&
            await _isConnectionStillValid()) {
          return _database!;
        }
      }
      return await _establishDatabaseConnection();
    });
  }

  Future<Database> _establishDatabaseConnection() async {
    _isInitializing = true;
    try {
      for (int attempt = 1; attempt <= _maxConnectionRetryAttempts; attempt++) {
        try {
          if (kDebugMode) {
            print(
              '[DatabaseService] Establishing database connection (attempt $attempt/$_maxConnectionRetryAttempts)...',
            );
          }
          if (_database != null && !_isConnected) {
            if (kDebugMode) {
              print(
                '[DatabaseService] Connection lost, attempting recovery...',
              );
            }
            await _logDatabaseError(
              ErrorContext.connectionRecovery,
              'Database connection was lost, attempting automatic recovery',
              severity: ErrorSeverity.medium,
              metadata: {
                'attempt': attempt,
                'max_attempts': _maxConnectionRetryAttempts,
              },
            );
          }

          // Close existing database connection if it exists but is closed
          if (_database != null && !_database!.isOpen) {
            try {
              await _database!.close();
            } catch (e) {
              if (kDebugMode) {
                print('[DatabaseService] Error closing existing database: $e');
              }
            }
            _database = null;
          }

          _database = await initDatabase().timeout(_connectionTimeout);
          await _validateNewConnection(_database!);

          _isConnected = true;
          _lastConnectionCheck = DateTime.now();
          _connectionRetryCount = 0;
          if (kDebugMode) {
            print(
              '[DatabaseService] Database connection established successfully',
            );
          }
          return _database!;
        } catch (e, stackTrace) {
          _isConnected = false;
          _connectionRetryCount++;
          if (kDebugMode) {
            print('[DatabaseService] Connection attempt $attempt failed: $e');
          }
          await _logDatabaseError(
            ErrorContext.connectionFailed,
            'Failed to establish database connection',
            error: e,
            stackTrace: stackTrace,
            severity: attempt == _maxConnectionRetryAttempts
                ? ErrorSeverity.critical
                : ErrorSeverity.high,
            metadata: {
              'attempt': attempt,
              'max_attempts': _maxConnectionRetryAttempts,
              'retry_count': _connectionRetryCount,
            },
          );
          if (attempt == _maxConnectionRetryAttempts) {
            if (kDebugMode) {
              print(
                '[DatabaseService] All connection attempts failed, giving up',
              );
            }
            rethrow;
          }
          final waitTime = Duration(seconds: attempt * 2);
          if (kDebugMode) {
            print(
              '[DatabaseService] Waiting ${waitTime.inSeconds}s before retry...',
            );
          }
          await Future.delayed(waitTime);
        }
      }
      throw Exception(
        'Failed to establish database connection after $_maxConnectionRetryAttempts attempts',
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _validateNewConnection(Database db) async {
    try {
      await db.rawQuery('SELECT 1').timeout(const Duration(seconds: 5));
      if (kDebugMode) {
        print('[DatabaseService] New connection validated successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DatabaseService] New connection validation failed: $e');
      }
      _isConnected = false;
      await _logDatabaseError(
        ErrorContext.connectionValidationFailed,
        'Failed to validate new database connection',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      // Try to close the database to prevent resource leaks
      try {
        await db.close();
      } catch (closeError) {
        if (kDebugMode) {
          print(
            '[DatabaseService] Error closing database after failed validation: $closeError',
          );
        }
      }
      throw Exception('New connection validation failed: $e');
    }
  }

  Future<bool> _isConnectionStillValid() async {
    if (_database == null || !_database!.isOpen) return false;

    final now = DateTime.now();
    if (_lastConnectionCheck != null &&
        now.difference(_lastConnectionCheck!) < _connectionValidationInterval) {
      return true;
    }

    try {
      await _database!.rawQuery('SELECT 1').timeout(const Duration(seconds: 5));
      _lastConnectionCheck = now;
      _isConnected = true;
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DatabaseService] Connection validation failed: $e');
      }
      _isConnected = false;
      await _logDatabaseError(
        ErrorContext.connectionValidationFailed,
        'Database connection validation failed during periodic check',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      return false;
    }
  }

  Future<T> _executeDbOperation<T>(
    Future<T> Function(Database db) operation,
    ErrorContext errorContext, {
    int retries = _maxDbOperationRetries,
    Duration delay = _dbOperationRetryDelay,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final db = await database;
        return await operation(db);
      } catch (e, stackTrace) {
        if (e is DatabaseException) {
          // Changed from SqfliteDatabaseException
          // SQLITE_BUSY (5), SQLITE_LOCKED (6)
          bool isRetryable =
              e.getResultCode() == 5 ||
              e.getResultCode() == 6; // Used getResultCode()

          if (isRetryable && attempt < retries) {
            if (kDebugMode) {
              print(
                '[DatabaseService] Retryable DB error (${e.getResultCode()}) on $errorContext (attempt ${attempt + 1}/${retries + 1}). Retrying in $delay...',
              );
            }
            await _logDatabaseError(
              errorContext,
              'Retryable DB error encountered',
              error: e,
              stackTrace: stackTrace,
              severity: ErrorSeverity.medium,
              metadata: {'attempt': attempt + 1, 'retries': retries},
            ); // Changed to medium
            await Future.delayed(delay * (attempt + 1));
            continue;
          }
        }
        if (kDebugMode) {
          print(
            '[DatabaseService] Non-retryable DB error or retries exhausted on $errorContext: $e',
          );
        }
        await _logDatabaseError(
          errorContext,
          'Failed to execute DB operation',
          error: e,
          stackTrace: stackTrace,
          severity: ErrorSeverity.high,
        );
        rethrow;
      }
    }
    throw Exception(
      'DB operation failed after $retries retries for $errorContext',
    );
  }

  Future<Foyer?> getFoyer() async {
    return _executeDbOperation((db) async {
      final List<Map<String, dynamic>> maps = await db.query('foyer', limit: 1);
      if (maps.isEmpty) return null;
      return Foyer.fromMap(maps.first);
    }, ErrorContext.getFoyer);
  }

  Future<String> insertFoyer(Foyer foyer) async {
    return _executeDbOperation((db) async {
      await db.insert('foyer', foyer.toMap());
      return foyer.id.toString();
    }, ErrorContext.insertFoyer);
  }

  Future<int> updateFoyer(Foyer foyer) async {
    return _executeDbOperation((db) {
      return db.update(
        'foyer',
        foyer.toMap(),
        where: 'id = ?',
        whereArgs: [foyer.id],
      );
    }, ErrorContext.updateFoyer);
  }

  Future<int> deleteFoyer(int id) async {
    return _executeDbOperation((db) {
      return db.delete('foyer', where: 'id = ?', whereArgs: [id]);
    }, ErrorContext.deleteFoyer);
  }

  Future<List<Objet>> getObjets({int? idFoyer, TypeObjet? type}) async {
    return _executeDbOperation((db) async {
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
    }, ErrorContext.getObjets);
  }

  Future<Objet?> getObjet(int id) async {
    return _executeDbOperation((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'objet',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return Objet.fromMap(maps.first);
    }, ErrorContext.getObjet);
  }

  Future<int> insertObjet(Objet objet) async {
    return _executeDbOperation((db) async {
      final id = await db.insert('objet', objet.toMap());
      return id;
    }, ErrorContext.insertObjet);
  }

  Future<int> updateObjet(Objet objet) async {
    return _executeDbOperation((db) {
      return db.update(
        'objet',
        objet.toMap(),
        where: 'id = ?',
        whereArgs: [objet.id],
      );
    }, ErrorContext.updateObjet);
  }

  Future<int> deleteObjet(int id) async {
    return _executeDbOperation((db) {
      return db.delete('objet', where: 'id = ?', whereArgs: [id]);
    }, ErrorContext.deleteObjet);
  }

  Future<int> getTotalObjetCount(int idFoyer) async {
    return _executeDbOperation((db) async {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM objet WHERE id_foyer = ?', [
          idFoyer,
        ]),
      );
      return count ?? 0;
    }, ErrorContext.getTotalObjetCount);
  }

  Future<int> getExpiringSoonObjetCount(int idFoyer) async {
    return _executeDbOperation((db) async {
      final now = DateTime.now();
      final alertDateThreshold = now
          .add(const Duration(days: 3))
          .toIso8601String()
          .substring(0, 10);
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          '''
        SELECT COUNT(*) FROM objet
        WHERE id_foyer = ?
        AND (
          (type = 'consommable' AND quantite_restante <= seuil_alerte_quantite)
          OR (type = 'consommable' AND date_rupture_prev IS NOT NULL AND date(date_rupture_prev) <= date(?))
          OR (type = 'durable' AND date_achat IS NOT NULL AND duree_vie_prev_jours IS NOT NULL
              AND date(date_achat, '+' || duree_vie_prev_jours || ' days') <= date(?))
        )
      ''',
          [idFoyer, alertDateThreshold, alertDateThreshold],
        ),
      );
      return count ?? 0;
    }, ErrorContext.getExpiringSoonObjetCount);
  }

  Future<List<Objet>> getObjetsWithAlerts(int idFoyer) async {
    return _executeDbOperation((db) async {
      final now = DateTime.now();
      final alertDateThreshold = now
          .add(const Duration(days: 3))
          .toIso8601String()
          .substring(0, 10);

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM objet 
        WHERE id_foyer = ? 
        AND (
          (type = 'consommable' AND quantite_restante <= seuil_alerte_quantite)
          OR (type = 'consommable' AND date_rupture_prev IS NOT NULL AND date(date_rupture_prev) <= date(?))
          OR (type = 'durable' AND date_achat IS NOT NULL AND duree_vie_prev_jours IS NOT NULL 
              AND date(date_achat, '+' || duree_vie_prev_jours || ' days') <= date(?))
        )
        ORDER BY 
          CASE 
            WHEN type = 'consommable' AND quantite_restante <= seuil_alerte_quantite THEN 1
            WHEN type = 'consommable' AND date_rupture_prev IS NOT NULL AND date(date_rupture_prev) <= date(?) THEN 2
            ELSE 3
          END,
          categorie ASC, nom ASC
      ''',
        [idFoyer, alertDateThreshold, alertDateThreshold, alertDateThreshold],
      );
      return List.generate(maps.length, (i) => Objet.fromMap(maps[i]));
    }, ErrorContext.getObjetsWithAlerts);
  }

  Future<Map<String, double>> getBudgetMensuel(int idFoyer) async {
    return _executeDbOperation((db) async {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT 
          categorie,
          SUM(
            CASE 
              WHEN methode_prevision = 'frequence' AND frequence_achat_jours IS NOT NULL AND frequence_achat_jours > 0 THEN (prix_unitaire * 30.0 / frequence_achat_jours)
              WHEN methode_prevision = 'debit' AND consommation_jour IS NOT NULL AND consommation_jour > 0 AND taille_conditionnement IS NOT NULL AND taille_conditionnement > 0 THEN (prix_unitaire * consommation_jour * 30.0 / taille_conditionnement)
              ELSE 0
            END
          ) as budget_categorie
        FROM objet 
        WHERE id_foyer = ? 
        AND type = 'consommable' 
        AND prix_unitaire IS NOT NULL
        GROUP BY categorie
      ''',
        [idFoyer],
      );
      final Map<String, double> budget = {};
      for (final map in maps) {
        budget[map['categorie'] as String] =
            (map['budget_categorie'] as num?)?.toDouble() ?? 0.0;
      }
      return budget;
    }, ErrorContext.getBudgetMensuel);
  }

  Future<List<Alert>> getAlerts({int? idFoyer, bool? unreadOnly}) async {
    return _executeDbOperation((db) async {
      if (idFoyer != null) {
        final sql =
            '''
          SELECT a.* FROM alertes a
          INNER JOIN objet o ON a.id_objet = o.id
          WHERE o.id_foyer = ?
          ${unreadOnly == true ? 'AND a.lu = 0' : ''}
          ORDER BY a.date_creation DESC
        ''';
        final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [
          idFoyer,
        ]);
        return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
      } else {
        String whereClause = unreadOnly == true ? 'lu = 0' : '';
        final List<Map<String, dynamic>> maps = await db.query(
          'alertes',
          where: whereClause.isEmpty ? null : whereClause,
          orderBy: 'date_creation DESC',
        );
        return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
      }
    }, ErrorContext.getAlerts);
  }

  Future<Alert?> getAlert(int id) async {
    return _executeDbOperation((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
        'alertes',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return Alert.fromMap(maps.first);
    }, ErrorContext.getAlert);
  }

  Future<int> insertAlert(Alert alert) async {
    return _executeDbOperation((db) async {
      final id = await db.insert('alertes', alert.toMap());
      return id;
    }, ErrorContext.insertAlert);
  }

  Future<int> updateAlert(Alert alert) async {
    return _executeDbOperation((db) {
      return db.update(
        'alertes',
        alert.toMap(),
        where: 'id = ?',
        whereArgs: [alert.id],
      );
    }, ErrorContext.updateAlert);
  }

  Future<int> deleteAlert(int id) async {
    return _executeDbOperation((db) {
      return db.delete('alertes', where: 'id = ?', whereArgs: [id]);
    }, ErrorContext.deleteAlert);
  }

  Future<int> insertObjetWithAlerts(Objet objet, int idFoyer) async {
    final objetId = await insertObjet(objet);
    if (objetId > 0) {
      await generateAlerts(idFoyer);
    }
    return objetId;
  }

  Future<int> markAlertAsRead(int id) async {
    return _executeDbOperation((db) {
      return db.update(
        'alertes',
        {'lu': 1, 'date_lecture': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }, ErrorContext.markAlertAsRead);
  }

  Future<int> deleteAllReadAlerts(int idFoyer) async {
    return _executeDbOperation((db) {
      final sql = '''
        DELETE FROM alertes
        WHERE lu = 1 AND id_objet IN (SELECT id FROM objet WHERE id_foyer = ?)
      ''';
      return db.rawDelete(sql, [idFoyer]);
    }, ErrorContext.deleteAllReadAlerts);
  }

  Future<void> generateAlerts(int idFoyer) async {
    return _executeDbOperation((db) async {
      final now = DateTime.now();
      final warningDate = now.add(const Duration(days: 5));
      final todayDateStr = now.toIso8601String();
      final warningDateStr = warningDate.toIso8601String();
      final twoDaysFromNowStr = now
          .add(const Duration(days: 2))
          .toIso8601String();

      await db.rawInsert(
        '''
        INSERT INTO alertes (id_objet, type_alerte, titre, message, urgences, date_creation, lu, resolu)
        SELECT
          o.id, 'stock_faible', 'Stock faible',
          o.nom || ' est en rupture de stock (quantité restante: ' || o.quantite_restante || ')',
          CASE WHEN o.quantite_restante <= 1 THEN 'high' ELSE 'medium' END,
          ?,
          0, 0
        FROM objet o
        LEFT JOIN alertes a ON a.id_objet = o.id AND a.type_alerte = 'stock_faible' AND a.resolu = 0
        WHERE o.id_foyer = ? AND o.type = 'consommable' AND o.quantite_restante <= o.seuil_alerte_quantite AND a.id IS NULL
      ''',
        [todayDateStr, idFoyer],
      );

      await db.rawInsert(
        '''
        INSERT INTO alertes (id_objet, type_alerte, titre, message, urgences, date_creation, lu, resolu)
        SELECT
          o.id, 'expiration_proche', 'Expiration proche',
          o.nom || ' expire bientôt (le ' || date(o.date_rupture_prev) || ')',
          CASE WHEN date(o.date_rupture_prev) <= date(?) THEN 'high' ELSE 'medium' END,
          ?,
          0, 0
        FROM objet o
        LEFT JOIN alertes a ON a.id_objet = o.id AND a.type_alerte = 'expiration_proche' AND a.resolu = 0
        WHERE o.id_foyer = ? AND o.date_rupture_prev IS NOT NULL AND date(o.date_rupture_prev) <= date(?) AND a.id IS NULL
      ''',
        [twoDaysFromNowStr, todayDateStr, idFoyer, warningDateStr],
      );
    }, ErrorContext.generateAlerts);
  }

  static Future<void> _waitForInitialization() async {
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<void> _logDatabaseError(
    ErrorContext context,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await ErrorLoggerService.logError(
        component: 'DatabaseService',
        operation: context.name,
        error: error ?? message,
        stackTrace: stackTrace ?? StackTrace.current,
        severity: severity,
        metadata: {
          'is_connected': _isConnected,
          'is_initializing': _isInitializing,
          'last_connection_check': _lastConnectionCheck?.toIso8601String(),
          ...?metadata,
        },
      );
    } catch (logError) {
      if (kDebugMode) {
        print(
          '[DatabaseService.FALLBACK_LOGGING] $context: $message. Error: $error. Stack: $stackTrace. Logging service error: $logError',
        );
      }
    }
  }

  Future<bool> isConnectionValid() async {
    return _isConnectionStillValid();
  }

  Future<void> close() async {
    await _lock.synchronized(() async {
      if (_database != null) {
        final dbToClose = _database!;
        _database = null;
        _isConnected = false;
        _isInitializing = false;
        _lastConnectionCheck = null;
        _connectionRetryCount = 0;
        try {
          await dbToClose.close();
          if (kDebugMode) {
            print(
              '[DatabaseService] ⚠️ Database closed successfully via DatabaseService.close()',
            );
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('[DatabaseService] Error during close: $e');
          }
          await _logDatabaseError(
            ErrorContext.closeConnection,
            'Error closing database',
            error: e,
            stackTrace: stackTrace,
            severity: ErrorSeverity.medium,
          ); // Changed to medium
        }
      }
    });
  }

  Map<String, dynamic> getConnectionStatus() {
    return {
      'is_connected': _isConnected,
      'is_initializing': _isInitializing,
      'has_database_instance': _database != null,
      'is_database_open': _database?.isOpen ?? false,
      'last_connection_check': _lastConnectionCheck?.toIso8601String(),
      'connection_retry_count': _connectionRetryCount,
    };
  }

  Future<void> debugTableStructure() async {
    try {
      final db = await database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
      );
      for (var table in tables) {
        final tableName = table['name'] as String;
        final columns = await db.rawQuery("PRAGMA table_info($tableName)");
        if (kDebugMode) {
          print('[DEBUG] $tableName table structure:');
        }
        for (final col in columns) {
          if (kDebugMode) {
            print(
              '  - ${col['name']}: ${col['type']} ${col['notnull'] == 1 ? 'NOT NULL' : 'NULL'} ${col['dflt_value'] != null ? 'DEFAULT ${col['dflt_value']}' : ''} ${col['pk'] == 1 ? 'PRIMARY KEY' : ''}',
            );
          }
        }
      }
      final dbVersion = await db.getVersion();
      if (kDebugMode) {
        print('[DEBUG] Database version: $dbVersion');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[DEBUG ERROR] Failed to get table structure: $e');
      }
      await _logDatabaseError(
        ErrorContext.debugOperation,
        'Failed to debug table structure',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      ); // Changed to low
    }
  }

  /// Clears all data from the database tables
  Future<void> clearAllData() async {
    return _executeDbOperation((db) async {
      // Get all table names
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
      );

      // Clear each table
      for (var table in tables) {
        final tableName = table['name'] as String;
        await db.delete(tableName);
      }
    }, ErrorContext.debugOperation);
  }
}

enum ErrorContext {
  connectionRecovery,
  connectionFailed,
  connectionValidationFailed,
  getFoyer,
  insertFoyer,
  updateFoyer,
  deleteFoyer,
  getObjets,
  getObjet,
  insertObjet,
  updateObjet,
  deleteObjet,
  getTotalObjetCount,
  getExpiringSoonObjetCount,
  getObjetsWithAlerts,
  getBudgetMensuel,
  getAlerts,
  getAlert,
  insertAlert,
  updateAlert,
  deleteAlert,
  markAlertAsRead,
  deleteAllReadAlerts,
  generateAlerts,
  closeConnection,
  debugOperation,
  inventory, // Added
  sync, // Added
  unknown,
}

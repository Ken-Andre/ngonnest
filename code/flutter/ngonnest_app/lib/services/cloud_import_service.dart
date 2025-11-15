import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_service.dart';
import 'console_logger.dart';
import 'database_service.dart';
import 'error_logger_service.dart';

/// Service for importing data from Supabase cloud to local SQLite database
/// Handles cloud data detection, import orchestration, and schema mapping
class CloudImportService {
  late final SupabaseClient _client;
  final DatabaseService _databaseService = DatabaseService();
  final AnalyticsService _analytics = AnalyticsService();

  CloudImportService({SupabaseClient? client}) {
    _client = client ?? Supabase.instance.client;
  }

  /// Check if cloud data exists for the current authenticated user
  Future<bool> checkCloudData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        ConsoleLogger.warning('[CloudImportService] No authenticated user found');
        return false;
      }

      ConsoleLogger.info('[CloudImportService] Checking cloud data for user: $userId');

      final response = await _client
          .from('households')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      final hasData = response.isNotEmpty;
      ConsoleLogger.info('[CloudImportService] Cloud data exists: $hasData');
      
      return hasData;
    } catch (e, stackTrace) {
      ConsoleLogger.error('CloudImportService', 'checkCloudData', e, stackTrace: stackTrace);
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: 'checkCloudData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'user_id': _client.auth.currentUser?.id,
        },
      );
      
      return false;
    }
  }

  /// Import all data from cloud to local database
  /// Returns ImportResult with success status and entity counts
  Future<ImportResult> importAllData() async {
    final result = ImportResult();
    
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      ConsoleLogger.info('[CloudImportService] Starting import for user: $userId');

      // 1. Import households first (required for foreign keys)
      final households = await _importHouseholds(userId);
      result.householdsImported = households.length;
      ConsoleLogger.info('[CloudImportService] Imported ${households.length} households');

      // 2. Import products for each household
      for (final household in households) {
        final products = await _importProducts(household['id']);
        result.productsImported += products.length;
      }
      ConsoleLogger.info('[CloudImportService] Imported ${result.productsImported} products');

      // 3. Import budget categories for each household
      for (final household in households) {
        final budgets = await _importBudgetCategories(household['id']);
        result.budgetsImported += budgets.length;
      }
      ConsoleLogger.info('[CloudImportService] Imported ${result.budgetsImported} budget categories');

      // 4. Import purchases
      final purchases = await _importPurchases();
      result.purchasesImported = purchases.length;
      ConsoleLogger.info('[CloudImportService] Imported ${purchases.length} purchases');

      // Update last sync time to prevent re-downloading
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_sync_time',
        DateTime.now().toIso8601String(),
      );

      // Log analytics event with entity counts
      await _analytics.logEvent('cloud_data_imported', parameters: {
        'households': result.householdsImported,
        'products': result.productsImported,
        'budgets': result.budgetsImported,
        'purchases': result.purchasesImported,
        'total_entities': result.householdsImported + 
                         result.productsImported + 
                         result.budgetsImported + 
                         result.purchasesImported,
      });

      result.success = true;
      ConsoleLogger.success('[CloudImportService] Import completed successfully');
      
    } catch (e, stackTrace) {
      result.success = false;
      result.error = e.toString();
      
      ConsoleLogger.error('CloudImportService', 'importAllData', e, stackTrace: stackTrace);
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: 'importAllData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {
          'user_id': _client.auth.currentUser?.id,
          'households_imported': result.householdsImported,
          'products_imported': result.productsImported,
          'budgets_imported': result.budgetsImported,
          'purchases_imported': result.purchasesImported,
        },
      );
    }

    return result;
  }

  /// Import households from cloud and insert into local foyer table
  /// Handles UUID strings from Supabase (v13+ schema)
  Future<List<Map<String, dynamic>>> _importHouseholds(String userId) async {
    try {
      final response = await _client
          .from('households')
          .select()
          .eq('user_id', userId);

      final db = await _databaseService.database;

      for (final household in response) {
        final localData = mapHouseholdToLocal(household);
        ConsoleLogger.info('[CloudImportService] Importing household with UUID: ${localData['id']}');
        
        await db.insert(
          'foyer',
          localData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      ConsoleLogger.error('CloudImportService', '_importHouseholds', e, stackTrace: stackTrace);
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: '_importHouseholds',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'user_id': userId},
      );
      
      rethrow;
    }
  }

  /// Import products from cloud and insert into local objet table
  /// Handles UUID strings from Supabase (v13+ schema)
  Future<List<Map<String, dynamic>>> _importProducts(String householdId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('household_id', householdId);

      final db = await _databaseService.database;

      for (final product in response) {
        final localData = mapProductToLocal(product);
        ConsoleLogger.info('[CloudImportService] Importing product with UUID: ${localData['id']}');
        
        await db.insert(
          'objet',
          localData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      ConsoleLogger.error('CloudImportService', '_importProducts', e, stackTrace: stackTrace);
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: '_importProducts',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'household_id': householdId},
      );
      
      rethrow;
    }
  }

  /// Import budget categories from cloud and insert into local budget_categories table
  /// Handles UUID strings from Supabase (v13+ schema)
  Future<List<Map<String, dynamic>>> _importBudgetCategories(String householdId) async {
    try {
      final response = await _client
          .from('budget_categories')
          .select()
          .eq('household_id', householdId);

      final db = await _databaseService.database;

      for (final budget in response) {
        final localData = mapBudgetCategoryToLocal(budget);
        ConsoleLogger.info('[CloudImportService] Importing budget category with UUID: ${localData['id']}');
        
        await db.insert(
          'budget_categories',
          localData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      ConsoleLogger.error('CloudImportService', '_importBudgetCategories', e, stackTrace: stackTrace);
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: '_importBudgetCategories',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'household_id': householdId},
      );
      
      rethrow;
    }
  }

  /// Import purchases from cloud and insert into local reachat_log table
  /// Handles UUID strings from Supabase (v13+ schema)
  Future<List<Map<String, dynamic>>> _importPurchases() async {
    try {
      final response = await _client.from('purchases').select();

      final db = await _databaseService.database;

      for (final purchase in response) {
        final localData = mapPurchaseToLocal(purchase);
        ConsoleLogger.info('[CloudImportService] Importing purchase with UUID: ${localData['id']}');
        
        await db.insert(
          'reachat_log',
          localData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      ConsoleLogger.error('CloudImportService', '_importPurchases', e, stackTrace: stackTrace);
      
      await ErrorLoggerService.logError(
        component: 'CloudImportService',
        operation: '_importPurchases',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      
      rethrow;
    }
  }

  /// Map cloud household schema to local foyer schema
  /// Cloud uses UUID strings, local now uses UUID strings (v13+)
  Map<String, dynamic> mapHouseholdToLocal(Map<String, dynamic> household) {
    return {
      'id': household['id'] as String, // UUID string from Supabase
      'nb_personnes': household['nb_personnes'] as int,
      'nb_pieces': household['nb_pieces'] as int,
      'type_logement': household['type_logement'] as String,
      'langue': household['langue'] as String,
      'budget_mensuel_estime': household['budget_mensuel_estime'] as double?,
    };
  }

  /// Map cloud product schema to local objet schema
  /// Cloud uses UUID strings, local now uses UUID strings (v13+)
  Map<String, dynamic> mapProductToLocal(Map<String, dynamic> product) {
    return {
      'id': product['id'] as String, // UUID string from Supabase
      'id_foyer': product['household_id'] as String, // UUID foreign key
      'nom': product['nom'] as String,
      'categorie': product['categorie'] as String,
      'type': product['type'] as String,
      'date_achat': product['date_achat'] as String?,
      'duree_vie_prev_jours': product['duree_vie_prev_jours'] as int?,
      'date_rupture_prev': product['date_rupture_prev'] as String?,
      'quantite_initiale': product['quantite_initiale'] as double,
      'quantite_restante': product['quantite_restante'] as double,
      'unite': product['unite'] as String,
      'taille_conditionnement': product['taille_conditionnement'] as String?,
      'prix_unitaire': product['prix_unitaire'] as double?,
      'methode_prevision': product['methode_prevision'] as String?,
      'frequence_achat_jours': product['frequence_achat_jours'] as int?,
      'consommation_jour': product['consommation_jour'] as double?,
      'seuil_alerte_jours': product['seuil_alerte_jours'] as int?,
      'seuil_alerte_quantite': product['seuil_alerte_quantite'] as double?,
      'commentaires': product['commentaires'] as String?,
      'room': product['room'] as String?,
      'date_modification': product['date_modification'] as String?,
    };
  }

  /// Map cloud budget category schema to local budget_categories schema
  /// Cloud uses UUID strings, local now uses UUID strings (v13+)
  Map<String, dynamic> mapBudgetCategoryToLocal(Map<String, dynamic> budget) {
    return {
      'id': budget['id'] as String, // UUID string from Supabase
      'name': budget['name'] as String,
      'limit_amount': budget['limit_amount'] as double,
      'spent': budget['spent_amount'] as double, // Note: local uses 'spent', cloud uses 'spent_amount'
      'percentage': budget['percentage'] as double? ?? 0.25, // Default to 25% if not present
      'month': budget['month'] as String,
      'created_at': budget['created_at'] as String,
      'updated_at': budget['updated_at'] as String,
    };
  }

  /// Map cloud purchase schema to local reachat_log schema
  /// Cloud uses UUID strings, local now uses UUID strings (v13+)
  Map<String, dynamic> mapPurchaseToLocal(Map<String, dynamic> purchase) {
    return {
      'id': purchase['id'] as String, // UUID string from Supabase
      'id_objet': purchase['product_id'] as String, // UUID foreign key
      'date': purchase['date'] as String,
      'quantite': purchase['quantite'] as double,
      'prix_total': purchase['prix_total'] as double,
    };
  }
}

/// Result of cloud import operation with success status and entity counts
class ImportResult {
  bool success = false;
  int householdsImported = 0;
  int productsImported = 0;
  int budgetsImported = 0;
  int purchasesImported = 0;
  String? error;

  /// Get total number of entities imported
  int get totalImported => 
      householdsImported + productsImported + budgetsImported + purchasesImported;

  /// Check if import was partially successful
  bool get isPartialSuccess => success && totalImported > 0 && error != null;

  @override
  String toString() {
    return 'ImportResult{success: $success, households: $householdsImported, '
           'products: $productsImported, budgets: $budgetsImported, '
           'purchases: $purchasesImported, error: $error}';
  }
}
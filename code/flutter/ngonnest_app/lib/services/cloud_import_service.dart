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
  Future<List<Map<String, dynamic>>> _importHouseholds(String userId) async {
    try {
      final response = await _client
          .from('households')
          .select()
          .eq('user_id', userId);

      final db = await _databaseService.database;

      for (final household in response) {
        await db.insert(
          'foyer',
          mapHouseholdToLocal(household),
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
  Future<List<Map<String, dynamic>>> _importProducts(String householdId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('household_id', householdId);

      final db = await _databaseService.database;

      for (final product in response) {
        await db.insert(
          'objet',
          mapProductToLocal(product),
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
  Future<List<Map<String, dynamic>>> _importBudgetCategories(String householdId) async {
    try {
      final response = await _client
          .from('budget_categories')
          .select()
          .eq('household_id', householdId);

      final db = await _databaseService.database;

      for (final budget in response) {
        await db.insert(
          'budget_categories',
          mapBudgetCategoryToLocal(budget),
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
  Future<List<Map<String, dynamic>>> _importPurchases() async {
    try {
      final response = await _client.from('purchases').select();

      final db = await _databaseService.database;

      for (final purchase in response) {
        await db.insert(
          'reachat_log',
          mapPurchaseToLocal(purchase),
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
  Map<String, dynamic> mapHouseholdToLocal(Map<String, dynamic> household) {
    return {
      'id': household['id'],
      'nb_personnes': household['nb_personnes'],
      'nb_pieces': household['nb_pieces'],
      'type_logement': household['type_logement'],
      'langue': household['langue'],
      'budget_mensuel_estime': household['budget_mensuel_estime'],
    };
  }

  /// Map cloud product schema to local objet schema
  Map<String, dynamic> mapProductToLocal(Map<String, dynamic> product) {
    return {
      'id': product['id'],
      'id_foyer': product['household_id'],
      'nom': product['nom'],
      'categorie': product['categorie'],
      'type': product['type'],
      'date_achat': product['date_achat'],
      'duree_vie_prev_jours': product['duree_vie_prev_jours'],
      'date_rupture_prev': product['date_rupture_prev'],
      'quantite_initiale': product['quantite_initiale'],
      'quantite_restante': product['quantite_restante'],
      'unite': product['unite'],
      'taille_conditionnement': product['taille_conditionnement'],
      'prix_unitaire': product['prix_unitaire'],
      'methode_prevision': product['methode_prevision'],
      'frequence_achat_jours': product['frequence_achat_jours'],
      'consommation_jour': product['consommation_jour'],
      'seuil_alerte_jours': product['seuil_alerte_jours'],
      'seuil_alerte_quantite': product['seuil_alerte_quantite'],
      'commentaires': product['commentaires'],
      'room': product['room'],
      'date_modification': product['date_modification'],
    };
  }

  /// Map cloud budget category schema to local budget_categories schema
  Map<String, dynamic> mapBudgetCategoryToLocal(Map<String, dynamic> budget) {
    return {
      'id': budget['id'],
      'name': budget['name'],
      'limit_amount': budget['limit_amount'],
      'spent_amount': budget['spent_amount'],
      'month': budget['month'],
      'created_at': budget['created_at'],
      'updated_at': budget['updated_at'],
    };
  }

  /// Map cloud purchase schema to local reachat_log schema
  Map<String, dynamic> mapPurchaseToLocal(Map<String, dynamic> purchase) {
    return {
      'id': purchase['id'],
      'id_objet': purchase['product_id'],
      'date': purchase['date'],
      'quantite': purchase['quantite'],
      'prix_total': purchase['prix_total'],
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
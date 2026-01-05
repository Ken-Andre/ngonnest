import 'package:flutter/foundation.dart';

import '../models/budget_category.dart';
import '../models/foyer.dart';
import 'analytics_service.dart';
import 'budget_allocation_rules.dart';
import 'database_service.dart';
import 'error_logger_service.dart';
import 'notification_service.dart';
import 'price_service.dart';

/// Service de gestion des budgets avec recommandations intelligentes
///
/// Gère les catégories budgétaires, le suivi des dépenses, les alertes
/// et génère des conseils d'économie personnalisés pour les foyers camerounais.
///
/// Fonctionnalités principales:
/// - Gestion des catégories budgétaires par mois
/// - Synchronisation automatique avec les achats
/// - Recommandations budgétaires basées sur le profil familial
/// - Conseils d'économie contextualisés
/// - Analyse des tendances de dépenses
/// - Alertes de dépassement budgétaire
class BudgetService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final PriceService _priceService;

  // Singleton instance
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal()
    : _databaseService = DatabaseService(),
      _priceService = PriceService();

  @visibleForTesting
  BudgetService.test(this._databaseService, this._priceService);

  /// Get current month in YYYY-MM format
  static String getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Get all budget categories for a specific month
  ///
  /// Returns empty list on error to prevent app crash (safe default)
  /// Requirements: 10.1, 10.2
  Future<List<BudgetCategory>> getBudgetCategories({String? month}) async {
    try {
      final db = await _databaseService.database;
      final targetMonth = month ?? getCurrentMonth();

      final List<Map<String, dynamic>> maps = await db.query(
        'budget_categories',
        where: 'month = ?',
        whereArgs: [targetMonth],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) => BudgetCategory.fromMap(maps[i]));
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'getBudgetCategories',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'month': month ?? getCurrentMonth(),
          'context_message':
              'Failed to retrieve budget categories from database',
        },
      );
      // Return empty list in case of error to prevent app crash
      return [];
    }
  }

  /// Create a new budget category
  Future<String> createBudgetCategory(
    BudgetCategory category, {
    bool notify = true,
  }) async {
    try {
      final db = await _databaseService.database;
      final id = await db.insert('budget_categories', category.toMap());

      // Track analytics event
      await AnalyticsService().logEvent(
        'budget_category_added',
        parameters: {'category_name': category.name},
      );

      // Notify listeners of change only if requested
      if (notify) {
        notifyListeners();
      }

      return id.toString();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'createBudgetCategory',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      rethrow;
    }
  }

  /// Update an existing budget category
  Future<int> updateBudgetCategory(
    BudgetCategory category, {
    bool notify = true,
    BudgetCategory? oldCategory,
  }) async {
    try {
      final db = await _databaseService.database;

      // Check if limit changed for analytics
      final limitChanged =
          oldCategory != null && oldCategory.limit != category.limit;

      final result = await db.update(
        'budget_categories',
        category.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      // Track analytics event
      await AnalyticsService().logEvent(
        'budget_category_edited',
        parameters: {
          'category_name': category.name,
          'limit_changed': limitChanged ? 'true' : 'false',
          'old_limit': oldCategory?.limit?.toString() ?? 'null',
          'new_limit': category.limit.toString(),
        },
      );

      // Notify listeners of change only if requested
      if (notify) {
        notifyListeners();
      }

      return result;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'updateBudgetCategory',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      rethrow;
    }
  }

  /// Delete a budget category
  Future<String> deleteBudgetCategory(String id) async {
    try {
      final db = await _databaseService.database;

      // Get category name before deletion for analytics
      final categoryResult = await db.query(
        'budget_categories',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final categoryName = categoryResult.isNotEmpty
          ? categoryResult.first['name'] as String?
          : null;

      await db.delete('budget_categories', where: 'id = ?', whereArgs: [id]);

      // Track analytics event
      if (categoryName != null) {
        await AnalyticsService().logEvent(
          'budget_category_deleted',
          parameters: {'category_name': categoryName},
        );
      }

      // Notify listeners of change
      notifyListeners();

      return id;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'deleteBudgetCategory',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      rethrow;
    }
  }

  /// Sync budget categories with actual purchases
  Future<void> syncBudgetWithPurchases(String idFoyer, {String? month}) async {
    await _updateSpendingFromPurchases(idFoyer, month: month);
  }

  /// Calculate and update spending for all categories based on actual purchases
  Future<void> _updateSpendingFromPurchases(
    String idFoyer, {
    String? month,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Get all budget categories for the month
      final categories = await getBudgetCategories(month: targetMonth);

      for (final category in categories) {
        // Calculate spending for this category based on objects purchased this month
        final spending = await _calculateCategorySpending(
          idFoyer,
          category.name,
          targetMonth,
        );

        // Update the category with new spending amount
        final updatedCategory = category.copyWith(
          spent: spending,
          updatedAt: DateTime.now(),
        );

        // Update without notifying to avoid infinite loops during sync
        await updateBudgetCategory(updatedCategory, notify: false);

        // Check if budget alert should be triggered (warning, alert, or critical)
        if (updatedCategory.alertLevel != BudgetAlertLevel.normal) {
          await _triggerBudgetAlert(updatedCategory);
        }
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'updateSpendingFromPurchases',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
    }
  }

  /// Calculate spending for a specific category in a given month
  ///
  /// Now uses reachat_log for actual repurchases AND objet for initial purchases
  /// Uses case-insensitive matching and category mapping for budget alignment
  /// Returns 0.0 on error to prevent calculation failures
  /// Requirements: 10.2, 10.3
  Future<double> _calculateCategorySpending(
    String idFoyer,
    String categoryName,
    String month,
  ) async {
    try {
      final db = await _databaseService.database;

      // Parse month to get start and end dates
      final monthParts = month.split('-');
      if (monthParts.length != 2) {
        throw FormatException('Invalid month format: $month. Expected YYYY-MM');
      }

      final year = int.tryParse(monthParts[0]);
      final monthNum = int.tryParse(monthParts[1]);

      if (year == null || monthNum == null || monthNum < 1 || monthNum > 12) {
        throw FormatException(
          'Invalid month values: year=$year, month=$monthNum',
        );
      }

      final startDate = DateTime(year, monthNum, 1);
      final endDate = DateTime(year, monthNum + 1, 0); // Last day of month
      
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      // Build category match list - include the budget category name and any mapped inventory categories
      // Maps inventory categories to budget categories (case-insensitive)
      final categoryMatches = _getInventoryCategoriesForBudget(categoryName);
      
      // DEBUG: Log all objects matching the category to diagnose date issues
      final debugResult = await db.rawQuery(
        '''
        SELECT id, nom, categorie, date_achat, prix_unitaire, quantite_initiale
        FROM objet 
        WHERE id_foyer = ? 
        AND LOWER(categorie) IN (${categoryMatches.map((_) => '?').join(', ')})
        ''',
        [idFoyer, ...categoryMatches],
      );
      debugPrint('[BudgetService] DEBUG: Found ${debugResult.length} objects for $categoryName:');
      for (final obj in debugResult) {
        debugPrint('  - ${obj['nom']}: cat=${obj['categorie']}, date=${obj['date_achat']}, prix=${obj['prix_unitaire']}, qty=${obj['quantite_initiale']}');
      }
      debugPrint('[BudgetService] DEBUG: Query date range: $startDateStr to $endDateStr');


      // Query 1: Get spending from reachat_log (repurchases)
      final repurchaseResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(r.prix_total), 0.0) as total_spending
        FROM reachat_log r
        INNER JOIN objet o ON r.id_objet = o.id
        WHERE o.id_foyer = ? 
        AND LOWER(o.categorie) IN (${categoryMatches.map((_) => '?').join(', ')})
        AND date(r.date) >= date(?)
        AND date(r.date) <= date(?)
        AND r.prix_total IS NOT NULL
        ''',
        [
          idFoyer,
          ...categoryMatches,
          startDateStr,
          endDateStr,
        ],
      );
      
      final repurchaseSpending = (repurchaseResult.first['total_spending'] as num?)?.toDouble() ?? 0.0;

      // Query 2: Get spending from initial purchases
      // Include products with NULL date_achat ONLY for current month, OR date_achat in queried month
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final isCurrentMonth = month == currentMonth;
      
      final initialPurchaseResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(prix_unitaire * quantite_initiale), 0.0) as total_spending
        FROM objet 
        WHERE id_foyer = ? 
        AND LOWER(categorie) IN (${categoryMatches.map((_) => '?').join(', ')})
        AND (
          ${isCurrentMonth ? 'date_achat IS NULL OR' : ''} 
          (date(date_achat) >= date(?) AND date(date_achat) <= date(?))
        )
        AND prix_unitaire IS NOT NULL
        ''',
        [
          idFoyer,
          ...categoryMatches,
          startDateStr,
          endDateStr,
        ],
      );
      
      final initialSpending = (initialPurchaseResult.first['total_spending'] as num?)?.toDouble() ?? 0.0;



      // Total spending = repurchases + initial purchases this month
      final totalSpending = repurchaseSpending + initialSpending;
      
      debugPrint('[BudgetService] Category $categoryName (matches: $categoryMatches) spending: repurchases=$repurchaseSpending, initial=$initialSpending, total=$totalSpending');

      return totalSpending;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: '_calculateCategorySpending',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {
          'id_foyer': idFoyer,
          'category_name': categoryName,
          'month': month,
          'context_message': 'Failed to calculate category spending',
        },
      );
      // Return 0.0 as safe default to prevent calculation failures
      return 0.0;
    }
  }
  
  /// Maps budget category name to list of inventory categories it should include
  /// Uses lowercase for case-insensitive matching
  List<String> _getInventoryCategoriesForBudget(String budgetCategoryName) {
    final lowerName = budgetCategoryName.toLowerCase();
    
    // Direct mapping for known 4-pillar categories (Vision Éducation Financière)
    switch (lowerName) {
      case 'hygiène':
      case 'hygiene':
        return ['hygiène', 'hygiene'];
      case 'nettoyage':
      case 'menage':
        return ['nettoyage', 'menage'];
      case 'cuisine':
      case 'nourriture':
        return ['cuisine', 'nourriture'];
      case 'divers':
        // "Divers" is the collector for all standard inventory categories not covered above
        return [
          'divers', 
          'autre', 
          'bureau', 
          'maintenance', 
          'sécurité', 
          'securité',
          'securite',
          'événementiel', 
          'evenementiel',
        ];
      default:
        // For custom categories, try exact match (lowercase)
        // This allows user-created budget categories to map to products with same category name
        return [lowerName];
    }
  }



  /// Trigger budget alert when spending exceeds limit
  ///
  /// Shows real system notifications using NotificationService.showBudgetAlert()
  /// instead of console logs. Falls back to in-app banner if permissions denied.
  /// Does not block budget operations on notification failure.
  ///
  /// Requirements: 2.4, 2.6, 10.6
  Future<void> _triggerBudgetAlert(BudgetCategory category) async {
    try {
      // Call NotificationService.showBudgetAlert() instead of debugPrint()
      await BudgetNotifications.showBudgetAlert(
        category: category,
        analytics: AnalyticsService(),
      );
    } catch (e, stackTrace) {
      // Log notification failures but don't block budget operations
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: '_triggerBudgetAlert',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'category_name': category.name,
          'alert_level': category.alertLevel.toString(),
          'spending_percentage': category.spendingPercentage,
          'context_message':
              'Failed to show budget notification, but budget operation continues',
        },
      );
      // Don't rethrow - notification failure should not block budget operations
    }
  }

  /// Get monthly expense history for a category
  Future<List<Map<String, dynamic>>> getMonthlyExpenseHistory(
    String idFoyer,
    String categoryName, {
    int monthsBack = 12,
  }) async {
    try {
      final now = DateTime.now();
      final history = <Map<String, dynamic>>[];

      for (int i = 0; i < monthsBack; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final month =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';

        final spending = await _calculateCategorySpending(
          idFoyer,
          categoryName,
          month,
        );

        history.add({
          'month': month,
          'year': targetDate.year,
          'monthNum': targetDate.month,
          'spending': spending,
          'monthName': _getMonthName(targetDate.month),
        });
      }

      return history.reversed.toList(); // Return chronological order
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'getMonthlyExpenseHistory',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return [];
    }
  }

  /// Get month name in French
  static String _getMonthName(int month) {
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month];
  }

  /// Initialize default budget categories for a new user
  Future<void> initializeDefaultCategories({String? month}) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Check if categories already exist for this month
      final existing = await getBudgetCategories(month: targetMonth);
      if (existing.isNotEmpty) return;

      // Create default categories based on the 4-pillar Financial Education vision
      // Percentages: Hygiène (33%), Nettoyage (22%), Cuisine (28%), Divers (17%)
      final defaultCategories = [
        BudgetCategory(name: 'Hygiène', limit: 120.0, month: targetMonth),
        BudgetCategory(name: 'Nettoyage', limit: 80.0, month: targetMonth),
        BudgetCategory(name: 'Cuisine', limit: 100.0, month: targetMonth),
        BudgetCategory(name: 'Divers', limit: 60.0, month: targetMonth),
      ];

      for (final category in defaultCategories) {
        // Create without notifying to avoid triggering listeners during initialization
        await createBudgetCategory(category, notify: false);
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'initializeDefaultCategories',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
    }
  }

  /// Trigger budget check and alerts after item purchase/update
  Future<void> checkBudgetAlertsAfterPurchase(
    String idFoyer,
    String categoryName, {
    String? month,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Get the budget category for this item's category
      final categories = await getBudgetCategories(month: targetMonth);
      final matchingCategory = categories
          .where((cat) => cat.name == categoryName)
          .firstOrNull;

      if (matchingCategory != null) {
        // Calculate current spending for this category
        final currentSpending = await _calculateCategorySpending(
          idFoyer,
          categoryName,
          targetMonth,
        );

        // Update the category with new spending
        final updatedCategory = matchingCategory.copyWith(
          spent: currentSpending,
          updatedAt: DateTime.now(),
        );

        await updateBudgetCategory(updatedCategory);

        // Check if budget alert should be triggered (warning, alert, or critical)
        if (updatedCategory.alertLevel != BudgetAlertLevel.normal) {
          await _triggerBudgetAlert(updatedCategory);
        }

        // Notify listeners after spending update
        notifyListeners();
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'checkBudgetAlertsAfterPurchase',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
    }
  }

  /// Recalculate all category budgets based on new total budget
  ///
  /// When the user updates their total monthly budget, this method
  /// recalculates all category limits while maintaining their percentages.
  /// This ensures budget allocations remain proportional to the new total.
  ///
  /// Handles division by zero and null/missing foyer data gracefully.
  /// Requirements: 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 10.3
  Future<void> recalculateCategoryBudgets(
    String idFoyer,
    double newTotalBudget, {
    String? month,
    double? oldTotalBudget,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Handle zero total budget - use default fallback amounts
      // Requirements: 7.5
      if (newTotalBudget <= 0) {
        await ErrorLoggerService.logError(
          component: 'BudgetService',
          operation: 'recalculateCategoryBudgets',
          error: 'Zero or negative total budget provided: $newTotalBudget',
          severity: ErrorSeverity.medium,
          metadata: {
            'id_foyer': idFoyer,
            'new_total_budget': newTotalBudget,
            'old_total_budget': oldTotalBudget,
            'month': targetMonth,
            'context_message':
                'Using default fallback amounts for zero budget',
          },
        );

        // Use default fallback amounts
        await _initializeDefaultBudgets(month: targetMonth);
        
        // Notify listeners even with fallback
        notifyListeners();
        return;
      }

      // Load all categories for current month
      final categories = await getBudgetCategories(month: targetMonth);

      if (categories.isEmpty) {
        debugPrint(
          '[BudgetService] No categories found for month $targetMonth',
        );
        return;
      }

      // Calculate new limits based on percentages and new total
      for (final category in categories) {
        // Handle division by zero in percentage calculations
        if (category.percentage <= 0 || category.percentage > 1) {
          debugPrint(
            '[BudgetService] Invalid percentage for ${category.name}: ${category.percentage}, skipping',
          );
          continue;
        }

        final newLimit = newTotalBudget * category.percentage;

        // Update category in database
        final updatedCategory = category.copyWith(
          limit: newLimit,
          updatedAt: DateTime.now(),
        );

        await updateBudgetCategory(updatedCategory);
      }

      // Track analytics event
      // Requirements: 7.7
      await AnalyticsService().logEvent(
        'budget_total_updated',
        parameters: {
          if (oldTotalBudget != null) 'old_amount': oldTotalBudget,
          'new_amount': newTotalBudget,
          'categories_recalculated': categories.length,
        },
      );

      // Notify listeners after recalculation
      // Requirements: 7.4
      notifyListeners();

      debugPrint(
        '[BudgetService] Recalculated ${categories.length} categories for new total: $newTotalBudget',
      );
    } catch (e, stackTrace) {
      // Requirements: 7.6
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'recalculateCategoryBudgets',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {
          'id_foyer': idFoyer,
          'new_total_budget': newTotalBudget,
          'old_total_budget': oldTotalBudget,
          'month': month ?? getCurrentMonth(),
          'context_message': 'Failed to recalculate category budgets',
        },
      );
      rethrow;
    }
  }

  /// Get budget summary for dashboard (read-only)
  Future<Map<String, dynamic>> getBudgetSummary({String? month}) async {
    try {
      final categories = await getBudgetCategories(month: month);

      double totalLimit = 0.0;
      double totalSpent = 0.0;
      int overBudgetCount = 0;

      for (final category in categories) {
        totalLimit += category.limit;
        totalSpent += category.spent;
        if (category.isOverBudget) overBudgetCount++;
      }

      return {
        'totalBudget': totalLimit,
        'totalSpent': totalSpent,
        'remaining': totalLimit - totalSpent,
        'spendingPercentage': totalLimit > 0 ? (totalSpent / totalLimit) : 0.0,
        'categoriesCount': categories.length,
        'overBudgetCount': overBudgetCount,
        'categories': categories,
      };
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'getBudgetSummary',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return {
        'totalBudget': 0.0,
        'totalSpent': 0.0,
        'remaining': 0.0,
        'spendingPercentage': 0.0,
        'categoriesCount': 0,
        'overBudgetCount': 0,
        'categories': <BudgetCategory>[],
      };
    }
  }

  // ===== PHASE 2: BUDGET INTELLIGENT & RECOMMANDATIONS =====

  /// Calculer automatiquement le budget recommandé basé sur le profil foyer
  Future<Map<String, double>> calculateRecommendedBudget(String idFoyer) async {
    try {
      final db = await _databaseService.database;

      // Récupérer les infos du foyer
      final foyerResult = await db.query(
        'foyer',
        where: 'id = ?',
        whereArgs: [idFoyer],
        limit: 1,
      );

      if (foyerResult.isEmpty) {
        throw Exception('Foyer non trouvé');
      }

      final foyer = foyerResult.first;
      final nbPersonnes = foyer['nb_personnes'] as int;
      final nbPieces = foyer['nb_pieces'] as int;
      final typeLogement = foyer['type_logement'] as String;

      // Calculs basés sur les prix moyens FCFA et profil foyer
      final baseHygiene = await PriceService().getAverageCategoryPrice(
        'Hygiène',
      );
      final baseNettoyage = await PriceService().getAverageCategoryPrice(
        'Nettoyage',
      );
      final baseCuisine = await PriceService().getAverageCategoryPrice(
        'Cuisine',
      );
      final baseDivers = await PriceService().getAverageCategoryPrice('Divers');

      // Facteurs multiplicateurs selon profil
      double facteurPersonnes =
          1.0 + (nbPersonnes - 1) * 0.3; // +30% par personne supplémentaire
      double facteurPieces =
          1.0 + (nbPieces - 1) * 0.15; // +15% par pièce supplémentaire
      double facteurLogement = typeLogement == 'maison'
          ? 1.2
          : 1.0; // +20% pour maison vs appartement

      final facteurTotal = facteurPersonnes * facteurPieces * facteurLogement;

      return {
        'Hygiène': (baseHygiene * 15 * facteurPersonnes).clamp(
          80.0,
          300.0,
        ), // ~15 produits/mois
        'Nettoyage': (baseNettoyage * 10 * facteurPieces).clamp(
          60.0,
          200.0,
        ), // ~10 produits/mois
        'Cuisine': (baseCuisine * 12 * facteurPersonnes).clamp(
          70.0,
          250.0,
        ), // ~12 produits/mois
        'Divers': (baseDivers * 8 * facteurTotal).clamp(
          40.0,
          150.0,
        ), // ~8 produits/mois
      };
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'calculateRecommendedBudget',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
      // Valeurs par défaut sécurisées
      return {
        'Hygiène': 120.0,
        'Nettoyage': 80.0,
        'Cuisine': 100.0,
        'Divers': 60.0,
      };
    }
  }

  /// Générer des conseils d'économies contextualisés
  Future<List<Map<String, dynamic>>> generateSavingsTips(
    String idFoyer, {
    String? month,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();
      final categories = await getBudgetCategories(month: targetMonth);
      final tips = <Map<String, dynamic>>[];

      for (final category in categories) {
        if (category.spendingPercentage > 0.8) {
          // Plus de 80% du budget utilisé
          tips.addAll(
            await _getCategorySpecificTips(
              category.name,
              category.spendingPercentage,
            ),
          );
        }
      }

      // Conseils généraux basés sur les habitudes
      final generalTips = await _getGeneralSavingsTips(idFoyer, targetMonth);
      tips.addAll(generalTips);

      // Limiter à 5 conseils max, triés par priorité
      tips.sort(
        (a, b) => (b['priority'] as int).compareTo(a['priority'] as int),
      );
      return tips.take(5).toList();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'generateSavingsTips',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return [];
    }
  }

  /// Conseils spécifiques par catégorie
  Future<List<Map<String, dynamic>>> _getCategorySpecificTips(
    String categoryName,
    double spendingPercentage,
  ) async {
    final tips = <Map<String, dynamic>>[];
    final urgency = spendingPercentage > 1.0 ? 'high' : 'medium';

    switch (categoryName.toLowerCase()) {
      case 'hygiène':
        tips.add({
          'title': 'Privilégiez les formats familiaux',
          'description':
              'Les grands conditionnements (shampoing 1L, savon pack) coûtent moins cher au litre.',
          'category': categoryName,
          'priority': urgency == 'high' ? 5 : 3,
          'urgency': urgency,
          'potentialSaving': '15-25%',
        });
        if (spendingPercentage > 1.0) {
          tips.add({
            'title': 'Utilisez le savon de Marseille',
            'description':
                'Remplacez gel douche et lessive par du savon de Marseille (800 FCFA vs 2200 FCFA).',
            'category': categoryName,
            'priority': 5,
            'urgency': 'high',
            'potentialSaving': '40%',
          });
        }
        break;

      case 'nettoyage':
        tips.add({
          'title': 'Fabriquez vos produits naturels',
          'description':
              'Vinaigre blanc + bicarbonate remplacent 80% des nettoyants chimiques.',
          'category': categoryName,
          'priority': urgency == 'high' ? 4 : 2,
          'urgency': urgency,
          'potentialSaving': '50-60%',
        });
        break;

      case 'cuisine':
        tips.add({
          'title': 'Achetez en gros au marché',
          'description':
              'Riz, huile, farine : 20-30% moins cher en sacs de 5kg+ au marché central.',
          'category': categoryName,
          'priority': urgency == 'high' ? 4 : 3,
          'urgency': urgency,
          'potentialSaving': '20-30%',
        });
        break;

      case 'divers':
        tips.add({
          'title': 'Planifiez vos achats',
          'description':
              'Une liste de courses évite les achats impulsifs (+25% en moyenne).',
          'category': categoryName,
          'priority': 2,
          'urgency': 'low',
          'potentialSaving': '25%',
        });
        break;
    }

    return tips;
  }

  /// Conseils généraux basés sur l'historique
  Future<List<Map<String, dynamic>>> _getGeneralSavingsTips(
    String idFoyer,
    String month,
  ) async {
    final tips = <Map<String, dynamic>>[];

    try {
      final db = await _databaseService.database;

      // Analyser les achats fréquents
      final frequentItems = await db.rawQuery(
        '''
        SELECT nom, categorie, COUNT(*) as frequency, AVG(prix_unitaire) as avg_price
        FROM objet 
        WHERE id_foyer = ? AND date_achat >= date('now', '-3 months')
        GROUP BY nom, categorie
        HAVING frequency > 2
        ORDER BY frequency DESC
        LIMIT 3
      ''',
        [idFoyer],
      );

      for (final item in frequentItems) {
        final productName = item['nom'] as String;
        final avgPrice = (item['avg_price'] as double?) ?? 0.0;
        final marketPrice = await PriceService().estimateObjectPrice(
          productName,
          item['categorie'] as String,
        );

        if (avgPrice > marketPrice * 1.2) {
          // 20% plus cher que le marché
          tips.add({
            'title': 'Optimisez vos achats de $productName',
            'description':
                'Vous payez ${avgPrice.toStringAsFixed(1)}€ vs ${marketPrice.toStringAsFixed(1)}€ en moyenne.',
            'category': 'Général',
            'priority': 3,
            'urgency': 'medium',
            'potentialSaving':
                '${((avgPrice - marketPrice) / avgPrice * 100).round()}%',
          });
        }
      }

      // Conseil saisonnier
      final now = DateTime.now();
      if (now.month >= 6 && now.month <= 8) {
        // Saison des pluies
        tips.add({
          'title': 'Saison des pluies : stockez malin',
          'description':
              'Profitez des prix bas sur riz, huile et conserves avant la hausse de fin d\'année.',
          'category': 'Saisonnier',
          'priority': 2,
          'urgency': 'low',
          'potentialSaving': '15%',
        });
      }
    } catch (e) {
      // Ignorer les erreurs pour les conseils généraux
    }

    return tips;
  }

  /// Obtenir l'historique des dépenses avec tendances
  Future<Map<String, dynamic>> getSpendingHistory(
    String idFoyer, {
    int monthsBack = 6,
  }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final history = <Map<String, dynamic>>[];

      for (int i = 0; i < monthsBack; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final month =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';

        // Dépenses par catégorie pour ce mois
        final categorySpending = await db.rawQuery(
          '''
          SELECT categorie, SUM(prix_unitaire) as total_spent, COUNT(*) as item_count
          FROM objet 
          WHERE id_foyer = ? 
          AND date_achat >= ? 
          AND date_achat < ?
          AND prix_unitaire IS NOT NULL
          GROUP BY categorie
        ''',
          [
            idFoyer,
            targetDate.toIso8601String(),
            DateTime(
              targetDate.year,
              targetDate.month + 1,
              1,
            ).toIso8601String(),
          ],
        );

        final monthData = {
          'month': month,
          'year': targetDate.year,
          'monthNum': targetDate.month,
          'monthName': _getMonthName(targetDate.month),
          'categories': categorySpending,
          'totalSpent': categorySpending.fold<double>(
            0.0,
            (sum, cat) => sum + ((cat['total_spent'] as double?) ?? 0.0),
          ),
          'totalItems': categorySpending.fold<int>(
            0,
            (sum, cat) => sum + ((cat['item_count'] as int?) ?? 0),
          ),
        };

        history.add(monthData);
      }

      // Calculer les tendances
      final trends = _calculateSpendingTrends(history);

      return {
        'history': history.reversed.toList(), // Ordre chronologique
        'trends': trends,
        'summary': _generateSpendingSummary(history),
      };
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'getSpendingHistory',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return {'history': [], 'trends': {}, 'summary': {}};
    }
  }

  /// Calculer les tendances de dépenses
  static Map<String, dynamic> _calculateSpendingTrends(
    List<Map<String, dynamic>> history,
  ) {
    if (history.length < 2) return {};

    final recent = history.take(3).toList(); // 3 derniers mois
    final older = history.skip(3).take(3).toList(); // 3 mois précédents

    final recentAvg =
        recent.fold<double>(
          0.0,
          (sum, month) => sum + (month['totalSpent'] as double),
        ) /
        recent.length;
    final olderAvg = older.isNotEmpty
        ? older.fold<double>(
                0.0,
                (sum, month) => sum + (month['totalSpent'] as double),
              ) /
              older.length
        : recentAvg;

    final trendPercentage = olderAvg > 0
        ? ((recentAvg - olderAvg) / olderAvg * 100)
        : 0.0;

    return {
      'direction': trendPercentage > 5
          ? 'increasing'
          : trendPercentage < -5
          ? 'decreasing'
          : 'stable',
      'percentage': trendPercentage.abs(),
      'recentAverage': recentAvg,
      'previousAverage': olderAvg,
    };
  }

  /// Générer un résumé des dépenses
  static Map<String, dynamic> _generateSpendingSummary(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return {};

    final totalSpent = history.fold<double>(
      0.0,
      (sum, month) => sum + (month['totalSpent'] as double),
    );
    final avgMonthly = totalSpent / history.length;

    // Trouver le mois le plus cher et le moins cher
    final sortedBySpending = List<Map<String, dynamic>>.from(history)
      ..sort(
        (a, b) =>
            (b['totalSpent'] as double).compareTo(a['totalSpent'] as double),
      );

    return {
      'totalSpent': totalSpent,
      'averageMonthly': avgMonthly,
      'highestMonth': sortedBySpending.first,
      'lowestMonth': sortedBySpending.last,
      'monthsTracked': history.length,
    };
  }

  /// Initialiser les budgets recommandés pour un nouveau foyer
  ///
  /// Uses BudgetAllocationRules to calculate intelligent budget allocations
  /// based on household profile (number of people, rooms, housing type).
  /// Creates budget categories with both amounts and percentages stored.
  ///
  /// Requirements: 1.1, 1.3, 6.4, 6.5, 6.6, 6.7
  Future<void> initializeRecommendedBudgets(
    String idFoyer, {
    String? month,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Vérifier si des catégories existent déjà
      final existing = await getBudgetCategories(month: targetMonth);
      if (existing.isNotEmpty) return;

      // Get foyer data
      final foyerDb = await _databaseService.database;
      final foyerResult = await foyerDb.query(
        'foyer',
        where: 'id = ?',
        whereArgs: [idFoyer],
        limit: 1,
      );

      if (foyerResult.isEmpty) {
        throw Exception('Foyer not found: $idFoyer');
      }

      final foyerMap = foyerResult.first;
      final foyer = Foyer.fromMap(foyerMap);

      // Call BudgetAllocationRules.calculateRecommendedBudgets()
      final allocations =
          await BudgetAllocationRules.calculateRecommendedBudgets(foyer: foyer);

      // Create categories with calculated amounts and percentages
      for (final allocation in allocations.values) {
        final category = BudgetCategory(
          name: allocation.categoryName,
          limit: allocation.recommendedAmount,
          percentage: allocation.percentage,
          month: targetMonth,
        );

        // Store percentage in database
        await createBudgetCategory(category, notify: false);
      }

      debugPrint(
        '[BudgetService] Initialized ${allocations.length} budget categories for foyer $idFoyer',
      );
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'initializeRecommendedBudgets',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      // Use defaults if calculation fails
      await _initializeDefaultBudgets(month: month);
    }
  }

  /// Fallback method to initialize default budgets if calculation fails
  Future<void> _initializeDefaultBudgets({String? month}) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Check if categories already exist
      final existing = await getBudgetCategories(month: targetMonth);
      if (existing.isNotEmpty) return;

      // Create default categories with default percentages
      final defaultCategories = [
        BudgetCategory(
          name: 'Hygiène',
          limit: 120.0,
          percentage: 0.33,
          month: targetMonth,
        ),
        BudgetCategory(
          name: 'Nettoyage',
          limit: 80.0,
          percentage: 0.22,
          month: targetMonth,
        ),
        BudgetCategory(
          name: 'Cuisine',
          limit: 100.0,
          percentage: 0.28,
          month: targetMonth,
        ),
        BudgetCategory(
          name: 'Divers',
          limit: 60.0,
          percentage: 0.17,
          month: targetMonth,
        ),
      ];

      for (final category in defaultCategories) {
        await createBudgetCategory(category, notify: false);
      }

      debugPrint(
        '[BudgetService] Initialized default budget categories as fallback',
      );
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: '_initializeDefaultBudgets',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
    }
  }
}

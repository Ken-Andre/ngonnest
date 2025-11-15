import 'package:flutter/foundation.dart';

import '../models/budget_category.dart';
import 'database_service.dart';
import 'error_logger_service.dart';
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
class BudgetService {
  /// Get current month in YYYY-MM format
  static String getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Get all budget categories for a specific month
  static Future<List<BudgetCategory>> getBudgetCategories({
    String? month,
  }) async {
    try {
      final db = await DatabaseService().database;
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
      );
      // Return empty list in case of error to prevent app crash
      return [];
    }
  }

  /// Create a new budget category
  static Future<String> createBudgetCategory(BudgetCategory category) async {
    try {
      final db = await DatabaseService().database;
      final id = await db.insert('budget_categories', category.toMap());

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
  static Future<int> updateBudgetCategory(BudgetCategory category) async {
    try {
      final db = await DatabaseService().database;
      final result = await db.update(
        'budget_categories',
        category.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

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
  static Future<String> deleteBudgetCategory(String id) async {
    try {
      final db = await DatabaseService().database;
      await db.delete('budget_categories', where: 'id = ?', whereArgs: [id]);

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
  static Future<void> syncBudgetWithPurchases(
    String idFoyer, {
    String? month,
  }) async {
    await _updateSpendingFromPurchases(idFoyer, month: month);
  }

  /// Calculate and update spending for all categories based on actual purchases
  static Future<void> _updateSpendingFromPurchases(
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

        await updateBudgetCategory(updatedCategory);

        // Check if budget is exceeded and trigger alert if needed
        if (updatedCategory.isOverBudget) {
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
  static Future<double> _calculateCategorySpending(
    String idFoyer,
    String categoryName,
    String month,
  ) async {
    try {
      final db = await DatabaseService().database;

      // Parse month to get start and end dates
      final monthParts = month.split('-');
      final year = int.parse(monthParts[0]);
      final monthNum = int.parse(monthParts[1]);
      final startDate = DateTime(year, monthNum, 1);
      final endDate = DateTime(year, monthNum + 1, 0); // Last day of month

      // Calculate spending based on objects purchased in this month
      final result = await db.rawQuery(
        '''
        SELECT SUM(prix_unitaire) as total_spending
        FROM objet 
        WHERE id_foyer = ? 
        AND categorie = ?
        AND date_achat >= ? 
        AND date_achat <= ?
        AND prix_unitaire IS NOT NULL
      ''',
        [
          idFoyer,
          categoryName,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
      );

      return (result.first['total_spending'] as double?) ?? 0.0;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: '_calculateCategorySpending',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return 0.0;
    }
  }

  /// Trigger budget alert when spending exceeds limit
  static Future<void> _triggerBudgetAlert(BudgetCategory category) async {
    try {
      final percentage = (category.spendingPercentage * 100).round();

      // TODO: Implement NotificationService.showBudgetAlert when service is available
      // For now, we'll log the alert to console
      debugPrint(
        'BUDGET ALERT: ${category.name} exceeded budget by $percentage% (Spent: ${category.spent}, Limit: ${category.limit})',
      );
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: '_triggerBudgetAlert',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
    }
  }

  /// Get monthly expense history for a category
  static Future<List<Map<String, dynamic>>> getMonthlyExpenseHistory(
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
  static Future<void> initializeDefaultCategories({String? month}) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Check if categories already exist for this month
      final existing = await getBudgetCategories(month: targetMonth);
      if (existing.isNotEmpty) return;

      // Create default categories based on common household categories
      final defaultCategories = [
        BudgetCategory(name: 'Hygiène', limit: 120.0, month: targetMonth),
        BudgetCategory(name: 'Nettoyage', limit: 80.0, month: targetMonth),
        BudgetCategory(name: 'Cuisine', limit: 100.0, month: targetMonth),
        BudgetCategory(name: 'Divers', limit: 60.0, month: targetMonth),
      ];

      for (final category in defaultCategories) {
        await createBudgetCategory(category);
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
  static Future<void> checkBudgetAlertsAfterPurchase(
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

        // Check if budget is exceeded and trigger alert
        if (updatedCategory.isOverBudget) {
          await _triggerBudgetAlert(updatedCategory);
        }
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
  static Future<void> recalculateCategoryBudgets(
    String idFoyer,
    double newTotalBudget, {
    String? month,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

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
        final newLimit = newTotalBudget * category.percentage;

        // Update category in database
        final updatedCategory = category.copyWith(
          limit: newLimit,
          updatedAt: DateTime.now(),
        );

        await updateBudgetCategory(updatedCategory);
      }

      debugPrint(
        '[BudgetService] Recalculated ${categories.length} categories for new total: $newTotalBudget',
      );
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'recalculateCategoryBudgets',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      rethrow;
    }
  }

  /// Get budget summary for dashboard (read-only)
  static Future<Map<String, dynamic>> getBudgetSummary({String? month}) async {
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
  static Future<Map<String, double>> calculateRecommendedBudget(
    String idFoyer,
  ) async {
    try {
      final db = await DatabaseService().database;

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
      final baseHygiene = await PriceService.getAverageCategoryPrice('Hygiène');
      final baseNettoyage = await PriceService.getAverageCategoryPrice(
        'Nettoyage',
      );
      final baseCuisine = await PriceService.getAverageCategoryPrice('Cuisine');
      final baseDivers = await PriceService.getAverageCategoryPrice('Divers');

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
  static Future<List<Map<String, dynamic>>> generateSavingsTips(
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
  static Future<List<Map<String, dynamic>>> _getCategorySpecificTips(
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
  static Future<List<Map<String, dynamic>>> _getGeneralSavingsTips(
    String idFoyer,
    String month,
  ) async {
    final tips = <Map<String, dynamic>>[];

    try {
      final db = await DatabaseService().database;

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
        final marketPrice = await PriceService.estimateObjectPrice(
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
  static Future<Map<String, dynamic>> getSpendingHistory(
    String idFoyer, {
    int monthsBack = 6,
  }) async {
    try {
      final db = await DatabaseService().database;
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
  static Future<void> initializeRecommendedBudgets(
    int idFoyer, {
    String? month,
  }) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Vérifier si des catégories existent déjà
      final existing = await getBudgetCategories(month: targetMonth);
      if (existing.isNotEmpty) return;

      // Calculer les budgets recommandés
      final recommendedBudgets = await calculateRecommendedBudget(idFoyer.toString());

      // Créer les catégories avec budgets intelligents
      for (final entry in recommendedBudgets.entries) {
        final category = BudgetCategory(
          name: entry.key,
          limit: entry.value,
          month: targetMonth,
        );
        await createBudgetCategory(category);
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'BudgetService',
        operation: 'initializeRecommendedBudgets',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );
    }
  }
}

import 'package:sqflite/sqflite.dart';
import '../models/budget_category.dart';
import '../models/objet.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/error_logger_service.dart';

class BudgetService {
  static final DatabaseService _databaseService = DatabaseService();

  /// Get current month in YYYY-MM format
  static String getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Get all budget categories for a specific month
  static Future<List<BudgetCategory>> getBudgetCategories(
      {String? month}) async {
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
      );
      return [];
    }
  }

  /// Create a new budget category
  static Future<int> createBudgetCategory(BudgetCategory category) async {
    try {
      final db = await _databaseService.database;
      return await db.insert('budget_categories', category.toMap());
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
      final db = await _databaseService.database;
      return await db.update(
        'budget_categories',
        category.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
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
  static Future<int> deleteBudgetCategory(int id) async {
    try {
      final db = await _databaseService.database;
      return await db.delete(
        'budget_categories',
        where: 'id = ?',
        whereArgs: [id],
      );
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
  static Future<void> syncBudgetWithPurchases(int idFoyer,
      {String? month}) async {
    await _updateSpendingFromPurchases(idFoyer, month: month);
  }

  /// Calculate and update spending for all categories based on actual purchases
  static Future<void> updateSpendingFromPurchases(int idFoyer,

      {String? month}) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Get all budget categories for the month
      final categories = await getBudgetCategories(month: targetMonth);

      for (final category in categories) {
        // Calculate spending for this category based on objects purchased this month
        final spending = await _calculateCategorySpending(
            idFoyer, category.name, targetMonth);

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
      int idFoyer, String categoryName, String month) async {
    try {
      final db = await _databaseService.database;

      // Parse month to get start and end dates
      final monthParts = month.split('-');
      final year = int.parse(monthParts[0]);
      final monthNum = int.parse(monthParts[1]);
      final startDate = DateTime(year, monthNum, 1);
      final endDate = DateTime(year, monthNum + 1, 0); // Last day of month

      // Calculate spending based on objects purchased in this month
      final result = await db.rawQuery('''
        SELECT SUM(prix_unitaire) as total_spending
        FROM objet 
        WHERE id_foyer = ? 
        AND categorie = ?
        AND date_achat >= ? 
        AND date_achat <= ?
        AND prix_unitaire IS NOT NULL
      ''', [
        idFoyer,
        categoryName,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);

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

      await NotificationService.showBudgetAlert(
        id: category.id ?? DateTime.now().millisecondsSinceEpoch,
        categoryName: category.name,
        spentAmount: category.spent,
        limitAmount: category.limit,
        percentage: percentage,
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
      int idFoyer, String categoryName,
      {int monthsBack = 12}) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final history = <Map<String, dynamic>>[];

      for (int i = 0; i < monthsBack; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final month =
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';

        final spending =
            await _calculateCategorySpending(idFoyer, categoryName, month);

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
      'Décembre'
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
      int idFoyer, String categoryName,
      {String? month}) async {
    try {
      final targetMonth = month ?? getCurrentMonth();

      // Get the budget category for this item's category
      final categories = await getBudgetCategories(month: targetMonth);
      final matchingCategory =
          categories.where((cat) => cat.name == categoryName).firstOrNull;

      if (matchingCategory != null) {
        // Calculate current spending for this category
        final currentSpending = await _calculateCategorySpending(
            idFoyer, categoryName, targetMonth);

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

  /// Get budget summary for dashboard
  static Future<Map<String, dynamic>> getBudgetSummary(int idFoyer,
      {String? month}) async {
    try {
      // Ensure spending values are up to date based on purchases
      await updateSpendingFromPurchases(idFoyer, month: month);
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
        'totalLimit': totalLimit,
        'totalSpent': totalSpent,
        'remainingBudget': totalLimit - totalSpent,
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
        'totalLimit': 0.0,
        'totalSpent': 0.0,
        'remainingBudget': 0.0,
        'spendingPercentage': 0.0,
        'categoriesCount': 0,
        'overBudgetCount': 0,
        'categories': <BudgetCategory>[],
      };
    }
  }
}

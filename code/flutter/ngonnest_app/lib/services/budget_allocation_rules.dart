import '../models/foyer.dart';
import 'price_service.dart';

/// Data class representing a budget allocation for a category
class BudgetAllocation {
  final String categoryName;
  final double percentage;
  final double recommendedAmount;
  final double basePrice;

  BudgetAllocation({
    required this.categoryName,
    required this.percentage,
    required this.recommendedAmount,
    required this.basePrice,
  });

  @override
  String toString() {
    return 'BudgetAllocation{categoryName: $categoryName, percentage: $percentage, recommendedAmount: $recommendedAmount, basePrice: $basePrice}';
  }
}

/// Engine for calculating intelligent budget allocations based on household profile
///
/// This service provides:
/// - Default percentage allocations for budget categories
/// - Household-specific multipliers (people, rooms, housing type)
/// - Recommended budget calculations using PriceService data
/// - Percentage-based budget distribution
class BudgetAllocationRules {
  /// Default percentage allocations for each category
  /// Based on typical household spending patterns for students and families
  static const Map<String, double> defaultPercentages = {
    'Hygiène': 0.33, // 33% - Personal hygiene products
    'Nettoyage': 0.22, // 22% - Cleaning products
    'Cuisine': 0.28, // 28% - Kitchen/cooking supplies
    'Divers': 0.17, // 17% - Miscellaneous items
  };

  /// Fallback base prices (in euros) when PriceService is unavailable
  /// These are average prices per product in each category
  static const Map<String, double> fallbackBasePrices = {
    'Hygiène': 8.0, // ~5250 FCFA
    'Nettoyage': 8.0, // ~5250 FCFA
    'Cuisine': 8.33, // ~5470 FCFA
    'Divers': 7.5, // ~4920 FCFA
  };

  /// Calculate multiplier based on number of people in household
  /// Formula: 1.0 + (nbPersonnes - 1) * 0.3
  /// Each additional person adds 30% to the base budget
  ///
  /// Examples:
  /// - 1 person: 1.0x
  /// - 2 people: 1.3x
  /// - 3 people: 1.6x
  /// - 4 people: 1.9x
  static double _calculatePersonMultiplier(int nbPersonnes) {
    return 1.0 + (nbPersonnes - 1) * 0.3;
  }

  /// Calculate multiplier based on number of rooms in household
  /// Formula: 1.0 + (nbPieces - 1) * 0.15
  /// Each additional room adds 15% to cleaning product needs
  ///
  /// Examples:
  /// - 1 room: 1.0x
  /// - 2 rooms: 1.15x
  /// - 3 rooms: 1.3x
  /// - 4 rooms: 1.45x
  static double _calculateRoomMultiplier(int nbPieces) {
    return 1.0 + (nbPieces - 1) * 0.15;
  }

  /// Calculate multiplier based on housing type
  /// Houses require 20% more cleaning products than apartments
  ///
  /// Returns:
  /// - 1.2 for 'maison' (house)
  /// - 1.0 for 'appartement' (apartment) or other types
  static double _calculateHousingMultiplier(String typeLogement) {
    return typeLogement.toLowerCase() == 'maison' ? 1.2 : 1.0;
  }

  /// Calculate recommended budget allocations based on household profile
  ///
  /// This method analyzes the household characteristics (number of people, rooms,
  /// housing type) and uses PriceService data to calculate intelligent budget
  /// recommendations for each category.
  ///
  /// The calculation applies category-specific formulas:
  /// - Hygiène: avgPrice * 15 * personMultiplier (clamped 80-300€)
  /// - Nettoyage: avgPrice * 10 * roomMultiplier (clamped 60-200€)
  /// - Cuisine: avgPrice * 12 * personMultiplier (clamped 70-250€)
  /// - Divers: avgPrice * 8 * totalMultiplier (clamped 40-150€)
  ///
  /// If PriceService fails, fallback base prices are used.
  ///
  /// Parameters:
  /// - [foyer]: The household profile containing nbPersonnes, nbPieces, typeLogement
  /// - [priceService]: Optional PriceService instance for testing (uses static methods by default)
  ///
  /// Returns: Map of category names to BudgetAllocation objects
  static Future<Map<String, BudgetAllocation>> calculateRecommendedBudgets({
    required Foyer foyer,
  }) async {
    final allocations = <String, BudgetAllocation>{};

    // Calculate household multipliers
    final personMultiplier = _calculatePersonMultiplier(foyer.nbPersonnes);
    final roomMultiplier = _calculateRoomMultiplier(foyer.nbPieces);
    final housingMultiplier = _calculateHousingMultiplier(foyer.typeLogement);
    final totalMultiplier =
        personMultiplier * roomMultiplier * housingMultiplier;

    // Calculate for each category
    for (final entry in defaultPercentages.entries) {
      final categoryName = entry.key;
      final percentage = entry.value;

      // Get average price from PriceService or use fallback
      double avgPrice;
      try {
        avgPrice = await PriceService().getAverageCategoryPrice(categoryName);
        // If PriceService returns 0, use fallback
        if (avgPrice == 0.0) {
          avgPrice = fallbackBasePrices[categoryName] ?? 8.0;
        }
      } catch (e) {
        // Use fallback on any error
        avgPrice = fallbackBasePrices[categoryName] ?? 8.0;
      }

      // Calculate recommended amount based on category-specific formula
      double recommendedAmount;
      switch (categoryName) {
        case 'Hygiène':
          // ~15 products per month, scaled by number of people
          recommendedAmount = (avgPrice * 15 * personMultiplier).clamp(
            80.0,
            300.0,
          );
          break;
        case 'Nettoyage':
          // ~10 products per month, scaled by number of rooms
          recommendedAmount = (avgPrice * 10 * roomMultiplier).clamp(
            60.0,
            200.0,
          );
          break;
        case 'Cuisine':
          // ~12 products per month, scaled by number of people
          recommendedAmount = (avgPrice * 12 * personMultiplier).clamp(
            70.0,
            250.0,
          );
          break;
        case 'Divers':
          // ~8 products per month, scaled by total household size
          recommendedAmount = (avgPrice * 8 * totalMultiplier).clamp(
            40.0,
            150.0,
          );
          break;
        default:
          // Default formula for unknown categories
          recommendedAmount = avgPrice * 10;
      }

      allocations[categoryName] = BudgetAllocation(
        categoryName: categoryName,
        percentage: percentage,
        recommendedAmount: recommendedAmount,
        basePrice: avgPrice,
      );
    }

    return allocations;
  }

  /// Calculate category budgets from a total budget using default percentages
  ///
  /// This method distributes a total monthly budget across categories using
  /// the default percentage allocations (Hygiène: 33%, Nettoyage: 22%,
  /// Cuisine: 28%, Divers: 17%).
  ///
  /// This is useful when:
  /// - User sets a total monthly budget in settings
  /// - Need to recalculate all category budgets proportionally
  /// - Initializing budgets without household profile data
  ///
  /// Parameters:
  /// - [totalBudget]: The total monthly budget in euros
  ///
  /// Returns: Map of category names to budget amounts
  ///
  /// Example:
  /// ```dart
  /// final budgets = BudgetAllocationRules.calculateFromTotal(360.0);
  /// // Returns: {
  /// //   'Hygiène': 118.8,    // 33% of 360
  /// //   'Nettoyage': 79.2,   // 22% of 360
  /// //   'Cuisine': 100.8,    // 28% of 360
  /// //   'Divers': 61.2,      // 17% of 360
  /// // }
  /// ```
  static Map<String, double> calculateFromTotal(double totalBudget) {
    return defaultPercentages.map(
      (category, percentage) => MapEntry(category, totalBudget * percentage),
    );
  }
}

import 'package:sqflite/sqflite.dart';
import '../models/product_price.dart';
import '../services/database_service.dart';
import '../services/error_logger_service.dart';

/// Service for managing product prices and price estimation
/// Provides price data for essential Cameroonian products and price estimation functionality
/// 
/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: PRICE_DATA_VALIDATION - Price data may be outdated or inaccurate
///       - Cameroonian prices need market validation
///       - Currency conversion rates not updated dynamically
/// TODO: PRICE_SEARCH_FUNCTIONALITY - Search may not work as expected
///       - Product name matching is basic string comparison
///       - No fuzzy search or synonym support
/// TODO: PRICE_ESTIMATION_ACCURACY - Price estimation logic needs validation
///       - Category-based estimation may be inaccurate
///       - No regional price variations considered
/// TODO: PRICE_DATABASE_INTEGRATION - Service not integrated with inventory
///       - Prices not automatically applied to products
///       - No price history tracking
class PriceService {
  static final DatabaseService _databaseService = DatabaseService();

  /// Taux de change FCFA vers Euro (approximatif, mise à jour annuelle)
  static const double _fcfaToEuroRate = 0.00152; // 1 FCFA = 0.00152 EUR

  /// Initialiser la base de prix avec les 50 produits essentiels camerounais
  static Future<void> initializeProductPrices() async {
    try {
      final db = await _databaseService.database;
      
      // Vérifier si les prix sont déjà initialisés
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM product_prices')
      ) ?? 0;
      
      if (count > 0) return; // Déjà initialisé

      final now = DateTime.now();
      final essentialProducts = [
        // Hygiène personnelle
        ProductPrice(name: 'Savon de toilette', category: 'Hygiène', priceFcfa: 500, priceEuro: 500 * _fcfaToEuroRate, unit: 'piece', description: 'Savon standard 100g', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Dentifrice', category: 'Hygiène', priceFcfa: 1200, priceEuro: 1200 * _fcfaToEuroRate, unit: 'piece', description: 'Tube 75ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Brosse à dents', category: 'Hygiène', priceFcfa: 800, priceEuro: 800 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Shampoing', category: 'Hygiène', priceFcfa: 2500, priceEuro: 2500 * _fcfaToEuroRate, unit: 'piece', description: 'Flacon 400ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Déodorant', category: 'Hygiène', priceFcfa: 1800, priceEuro: 1800 * _fcfaToEuroRate, unit: 'piece', description: 'Spray 150ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Papier toilette', category: 'Hygiène', priceFcfa: 2000, priceEuro: 2000 * _fcfaToEuroRate, unit: 'paquet', description: 'Paquet 4 rouleaux', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Serviettes hygiéniques', category: 'Hygiène', priceFcfa: 1500, priceEuro: 1500 * _fcfaToEuroRate, unit: 'paquet', description: 'Paquet 10 pièces', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Rasoir jetable', category: 'Hygiène', priceFcfa: 300, priceEuro: 300 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Crème hydratante', category: 'Hygiène', priceFcfa: 3000, priceEuro: 3000 * _fcfaToEuroRate, unit: 'piece', description: 'Tube 200ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Gel douche', category: 'Hygiène', priceFcfa: 2200, priceEuro: 2200 * _fcfaToEuroRate, unit: 'piece', description: 'Flacon 500ml', createdAt: now, updatedAt: now),

        // Nettoyage maison
        ProductPrice(name: 'Lessive en poudre', category: 'Nettoyage', priceFcfa: 3500, priceEuro: 3500 * _fcfaToEuroRate, unit: 'kg', description: 'Sac 2kg', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Savon de Marseille', category: 'Nettoyage', priceFcfa: 800, priceEuro: 800 * _fcfaToEuroRate, unit: 'piece', description: 'Pain 300g', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Eau de Javel', category: 'Nettoyage', priceFcfa: 600, priceEuro: 600 * _fcfaToEuroRate, unit: 'litre', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Détergent vaisselle', category: 'Nettoyage', priceFcfa: 1200, priceEuro: 1200 * _fcfaToEuroRate, unit: 'piece', description: 'Flacon 500ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Éponge vaisselle', category: 'Nettoyage', priceFcfa: 200, priceEuro: 200 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Balai', category: 'Nettoyage', priceFcfa: 2500, priceEuro: 2500 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Serpillière', category: 'Nettoyage', priceFcfa: 1500, priceEuro: 1500 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Désinfectant sol', category: 'Nettoyage', priceFcfa: 1800, priceEuro: 1800 * _fcfaToEuroRate, unit: 'litre', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Nettoyant vitres', category: 'Nettoyage', priceFcfa: 1400, priceEuro: 1400 * _fcfaToEuroRate, unit: 'piece', description: 'Spray 500ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Sacs poubelle', category: 'Nettoyage', priceFcfa: 1000, priceEuro: 1000 * _fcfaToEuroRate, unit: 'paquet', description: 'Rouleau 20 sacs', createdAt: now, updatedAt: now),

        // Cuisine et alimentation
        ProductPrice(name: 'Huile de palme', category: 'Cuisine', priceFcfa: 2000, priceEuro: 2000 * _fcfaToEuroRate, unit: 'litre', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Riz', category: 'Cuisine', priceFcfa: 1500, priceEuro: 1500 * _fcfaToEuroRate, unit: 'kg', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Farine de blé', category: 'Cuisine', priceFcfa: 800, priceEuro: 800 * _fcfaToEuroRate, unit: 'kg', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Sucre', category: 'Cuisine', priceFcfa: 700, priceEuro: 700 * _fcfaToEuroRate, unit: 'kg', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Sel', category: 'Cuisine', priceFcfa: 300, priceEuro: 300 * _fcfaToEuroRate, unit: 'kg', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Cube Maggi', category: 'Cuisine', priceFcfa: 25, priceEuro: 25 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Tomate concentrée', category: 'Cuisine', priceFcfa: 400, priceEuro: 400 * _fcfaToEuroRate, unit: 'piece', description: 'Boîte 70g', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Pâtes alimentaires', category: 'Cuisine', priceFcfa: 600, priceEuro: 600 * _fcfaToEuroRate, unit: 'paquet', description: '500g', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Sardines en boîte', category: 'Cuisine', priceFcfa: 800, priceEuro: 800 * _fcfaToEuroRate, unit: 'piece', description: 'Boîte 125g', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Lait en poudre', category: 'Cuisine', priceFcfa: 3500, priceEuro: 3500 * _fcfaToEuroRate, unit: 'paquet', description: 'Boîte 400g', createdAt: now, updatedAt: now),

        // Produits ménagers spécialisés
        ProductPrice(name: 'Insecticide', category: 'Divers', priceFcfa: 2500, priceEuro: 2500 * _fcfaToEuroRate, unit: 'piece', description: 'Spray 400ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Allumettes', category: 'Divers', priceFcfa: 100, priceEuro: 100 * _fcfaToEuroRate, unit: 'paquet', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Bougies', category: 'Divers', priceFcfa: 200, priceEuro: 200 * _fcfaToEuroRate, unit: 'piece', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Piles AA', category: 'Divers', priceFcfa: 500, priceEuro: 500 * _fcfaToEuroRate, unit: 'paquet', description: 'Paquet 4 piles', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Ampoule LED', category: 'Divers', priceFcfa: 1500, priceEuro: 1500 * _fcfaToEuroRate, unit: 'piece', description: '10W', createdAt: now, updatedAt: now),

        // Produits bébé/enfant
        ProductPrice(name: 'Couches bébé', category: 'Hygiène', priceFcfa: 4500, priceEuro: 4500 * _fcfaToEuroRate, unit: 'paquet', description: 'Paquet 30 pièces', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Lingettes bébé', category: 'Hygiène', priceFcfa: 1800, priceEuro: 1800 * _fcfaToEuroRate, unit: 'paquet', description: 'Paquet 80 pièces', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Lait infantile', category: 'Cuisine', priceFcfa: 8000, priceEuro: 8000 * _fcfaToEuroRate, unit: 'piece', description: 'Boîte 900g', createdAt: now, updatedAt: now),

        // Produits de première nécessité
        ProductPrice(name: 'Paracétamol', category: 'Divers', priceFcfa: 500, priceEuro: 500 * _fcfaToEuroRate, unit: 'paquet', description: 'Boîte 20 comprimés', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Alcool à 70°', category: 'Hygiène', priceFcfa: 800, priceEuro: 800 * _fcfaToEuroRate, unit: 'piece', description: 'Flacon 250ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Coton hydrophile', category: 'Hygiène', priceFcfa: 600, priceEuro: 600 * _fcfaToEuroRate, unit: 'paquet', description: '100g', createdAt: now, updatedAt: now),

        // Produits d'entretien spécialisés
        ProductPrice(name: 'Cire pour sol', category: 'Nettoyage', priceFcfa: 2200, priceEuro: 2200 * _fcfaToEuroRate, unit: 'litre', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Détartrant WC', category: 'Nettoyage', priceFcfa: 1600, priceEuro: 1600 * _fcfaToEuroRate, unit: 'piece', description: 'Flacon 750ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Nettoyant four', category: 'Nettoyage', priceFcfa: 2800, priceEuro: 2800 * _fcfaToEuroRate, unit: 'piece', description: 'Spray 500ml', createdAt: now, updatedAt: now),

        // Produits saisonniers/occasionnels
        ProductPrice(name: 'Antimoustique', category: 'Divers', priceFcfa: 1200, priceEuro: 1200 * _fcfaToEuroRate, unit: 'piece', description: 'Spray 100ml', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Crème solaire', category: 'Hygiène', priceFcfa: 4000, priceEuro: 4000 * _fcfaToEuroRate, unit: 'piece', description: 'Tube 200ml SPF30', createdAt: now, updatedAt: now),

        // Produits d'hygiène féminine
        ProductPrice(name: 'Tampons', category: 'Hygiène', priceFcfa: 2000, priceEuro: 2000 * _fcfaToEuroRate, unit: 'paquet', description: 'Boîte 16 pièces', createdAt: now, updatedAt: now),

        // Produits de base cuisine
        ProductPrice(name: 'Vinaigre blanc', category: 'Cuisine', priceFcfa: 400, priceEuro: 400 * _fcfaToEuroRate, unit: 'litre', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Bicarbonate de soude', category: 'Nettoyage', priceFcfa: 600, priceEuro: 600 * _fcfaToEuroRate, unit: 'paquet', description: '500g', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Papier aluminium', category: 'Cuisine', priceFcfa: 1500, priceEuro: 1500 * _fcfaToEuroRate, unit: 'piece', description: 'Rouleau 30m', createdAt: now, updatedAt: now),
        ProductPrice(name: 'Film plastique', category: 'Cuisine', priceFcfa: 1200, priceEuro: 1200 * _fcfaToEuroRate, unit: 'piece', description: 'Rouleau 50m', createdAt: now, updatedAt: now),
      ];

      // Insérer tous les produits
      for (final product in essentialProducts) {
        await db.insert('product_prices', product.toMap());
      }

    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'initializeProductPrices',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      rethrow;
    }
  }

  /// Obtenir le prix estimé d'un produit par nom
  static Future<ProductPrice?> getProductPrice(String productName) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'product_prices',
        where: 'LOWER(name) LIKE LOWER(?)',
        whereArgs: ['%$productName%'],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ProductPrice.fromMap(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'getProductPrice',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return null;
    }
  }

  /// Obtenir tous les prix par catégorie
  static Future<List<ProductPrice>> getPricesByCategory(String category) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'product_prices',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) => ProductPrice.fromMap(maps[i]));
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'getPricesByCategory',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return [];
    }
  }

  /// Estimer le prix d'un objet basé sur son nom et catégorie
  static Future<double> estimateObjectPrice(String objectName, String category) async {
    try {
      // Recherche exacte d'abord
      var price = await getProductPrice(objectName);
      
      if (price != null) {
        return price.priceEuro;
      }

      // Recherche par catégorie et similarité
      final categoryPrices = await getPricesByCategory(category);
      if (categoryPrices.isNotEmpty) {
        // Retourner le prix moyen de la catégorie
        final avgPrice = categoryPrices
            .map((p) => p.priceEuro)
            .reduce((a, b) => a + b) / categoryPrices.length;
        return avgPrice;
      }

      // Prix par défaut selon la catégorie
      switch (category.toLowerCase()) {
        case 'hygiène':
          return 3.0; // ~2000 FCFA
        case 'nettoyage':
          return 2.5; // ~1650 FCFA
        case 'cuisine':
          return 2.0; // ~1300 FCFA
        case 'divers':
          return 1.5; // ~1000 FCFA
        default:
          return 2.0; // Prix par défaut
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'estimateObjectPrice',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return 2.0; // Prix de fallback
    }
  }

  /// Obtenir des suggestions de prix pour l'auto-complétion
  static Future<List<ProductPrice>> searchProducts(String query) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'product_prices',
        where: 'LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
        limit: 10,
      );

      return List.generate(maps.length, (i) => ProductPrice.fromMap(maps[i]));
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'searchProducts',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return [];
    }
  }

  /// Convertir FCFA vers Euro
  static double fcfaToEuro(double fcfa) {
    return fcfa * _fcfaToEuroRate;
  }

  /// Convertir Euro vers FCFA
  static double euroToFcfa(double euro) {
    return euro / _fcfaToEuroRate;
  }

  /// Obtenir le prix moyen d'une catégorie
  static Future<double> getAverageCategoryPrice(String category) async {
    try {
      final prices = await getPricesByCategory(category);
      if (prices.isEmpty) return 0.0;
      
      final total = prices.map((p) => p.priceEuro).reduce((a, b) => a + b);
      return total / prices.length;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'getAverageCategoryPrice',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return 0.0;
    }
  }
}

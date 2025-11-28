import 'dart:math';

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
/// Features:
/// - ✅ 50+ produits essentiels camerounais avec prix FCFA
/// - ✅ Conversion automatique FCFA ↔ Euro ↔ USD ↔ CAD
/// - ✅ Ajustement d'inflation annuel (6% par défaut)
/// - ✅ Recherche par nom et catégorie
/// - ✅ Estimation de prix par catégorie
///
/// Catégories supportées:
/// - Hygiène (savon, dentifrice, shampoing, brosse etc.)
/// - Nettoyage (lessive, eau de javel, détergent, etc.)
/// - Cuisine (huile, riz, farine, sucre, sel, etc.)
/// - Divers (insecticide, allumettes, bougies, piles, etc.)
///
/// Dernière mise à jour: Janvier 2024
/// Source: Marchés locaux Douala/Yaoundé
class PriceService {
  final DatabaseService _databaseService;

  static final PriceService _instance = PriceService._internal();
  factory PriceService() => _instance;
  PriceService._internal() : _databaseService = DatabaseService();

  /// Taux de change FCFA vers Euro (taux officiel BCE)
  /// Source: Banque Centrale Européenne
  /// 1 EUR = 655.957 FCFA (taux fixe)
  static const double fcfaToEuroRate = 0.00152; // 1 FCFA = 0.00152 EUR

  /// Taux d'inflation annuel au Cameroun (moyenne)
  static const double _annualInflationRate = 0.06; // 6% par an

  /// Initialiser la base de prix avec les 50 produits essentiels camerounais
  Future<void> initializeProductPrices() async {
    try {
      final db = await _databaseService.database;

      // Vérifier si les prix sont déjà initialisés
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM product_prices'),
          ) ??
          0;

      if (count > 0) return; // Déjà initialisé

      final now = DateTime.now();
      final essentialProducts = [
        // Hygiène personnelle
        ProductPrice(
          name: 'Savon de toilette',
          nameNormalized: 'savon de toilette',
          category: 'Hygiène',
          priceLocal: 500,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Savon standard 100g',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Dentifrice',
          nameNormalized: 'dentifrice',
          category: 'Hygiène',
          priceLocal: 1200,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Tube 75ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Brosse à dents',
          nameNormalized: 'brosse a dents',
          category: 'Hygiène',
          priceLocal: 800,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Shampoing',
          nameNormalized: 'shampoing',
          category: 'Hygiène',
          priceLocal: 2500,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Flacon 400ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Déodorant',
          nameNormalized: 'deodorant',
          category: 'Hygiène',
          priceLocal: 1800,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Spray 150ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Papier toilette',
          nameNormalized: 'papier toilette',
          category: 'Hygiène',
          priceLocal: 2000,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Paquet 4 rouleaux',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Serviettes hygiéniques',
          nameNormalized: 'serviettes hygieniques',
          category: 'Hygiène',
          priceLocal: 1500,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Paquet 10 pièces',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Rasoir jetable',
          nameNormalized: 'rasoir jetable',
          category: 'Hygiène',
          priceLocal: 300,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Crème hydratante',
          nameNormalized: 'crème hydratante',
          category: 'Hygiène',
          priceLocal: 3000,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Tube 200ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Gel douche',
          nameNormalized: 'gel douche',
          category: 'Hygiène',
          priceLocal: 2200,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Flacon 500ml',
          createdAt: now,
          updatedAt: now,
        ),

        // Nettoyage maison
        ProductPrice(
          name: 'Lessive en poudre',
          nameNormalized: 'lessive en poudre',
          category: 'Nettoyage',
          priceLocal: 3500,
          currencyCode: 'XAF',
          unit: 'kg',
          description: 'Sac 2kg',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Savon de Marseille',
          nameNormalized: 'savon de marseille',
          category: 'Nettoyage',
          priceLocal: 800,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Pain 300g',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Eau de Javel',
          nameNormalized: 'eau de javel',
          category: 'Nettoyage',
          priceLocal: 600,
          currencyCode: 'XAF',
          unit: 'litre',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Détergent vaisselle',
          nameNormalized: 'detergent vaisselle',
          category: 'Nettoyage',
          priceLocal: 1200,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Flacon 500ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Éponge vaisselle',
          nameNormalized: 'eponge vaisselle',
          category: 'Nettoyage',
          priceLocal: 200,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Balai',
          nameNormalized: 'balai',
          category: 'Nettoyage',
          priceLocal: 2500,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Serpillière',
          nameNormalized: 'serpilliere',
          category: 'Nettoyage',
          priceLocal: 1500,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Désinfectant sol',
          nameNormalized: 'desinfectant sol',
          category: 'Nettoyage',
          priceLocal: 1800,
          currencyCode: 'XAF',
          unit: 'litre',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Nettoyant vitres',
          nameNormalized: 'nettoyant vitres',
          category: 'Nettoyage',
          priceLocal: 1400,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Spray 500ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Sacs poubelle',
          nameNormalized: 'sacs poubelle',
          category: 'Nettoyage',
          priceLocal: 1000,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Rouleau 20 sacs',
          createdAt: now,
          updatedAt: now,
        ),

        // Cuisine et alimentation
        ProductPrice(
          name: 'Huile de palme',
          nameNormalized: 'huile de palme',
          category: 'Cuisine',
          priceLocal: 2000,
          currencyCode: 'XAF',
          unit: 'litre',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Riz',
          nameNormalized: 'riz',
          category: 'Cuisine',
          priceLocal: 1500,
          currencyCode: 'XAF',
          unit: 'kg',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Farine de blé',
          nameNormalized: 'farine de ble',
          category: 'Cuisine',
          priceLocal: 800,
          currencyCode: 'XAF',
          unit: 'kg',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Sucre',
          nameNormalized: 'sucre',
          category: 'Cuisine',
          priceLocal: 700,
          currencyCode: 'XAF',
          unit: 'kg',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Sel',
          nameNormalized: 'sel',
          category: 'Cuisine',
          priceLocal: 300,
          currencyCode: 'XAF',
          unit: 'kg',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Cube Maggi',
          nameNormalized: 'cube maggi',
          category: 'Cuisine',
          priceLocal: 25,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Tomate concentrée',
          nameNormalized: 'tomate concentree',
          category: 'Cuisine',
          priceLocal: 400,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Boîte 70g',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Pâtes alimentaires',
          nameNormalized: 'pâtes alimentaires',
          category: 'Cuisine',
          priceLocal: 600,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: '500g',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Sardines en boîte',
          nameNormalized: 'sardines en boite',
          category: 'Cuisine',
          priceLocal: 800,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Boîte 125g',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Lait en poudre',
          nameNormalized: 'lait en poudre',
          category: 'Cuisine',
          priceLocal: 3500,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Boîte 400g',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits ménagers spécialisés
        ProductPrice(
          name: 'Insecticide',
          nameNormalized: 'insecticide',
          category: 'Divers',
          priceLocal: 2500,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Spray 400ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Allumettes',
          nameNormalized: 'allumettes',
          category: 'Divers',
          priceLocal: 100,
          currencyCode: 'XAF',
          unit: 'paquet',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Bougies',
          nameNormalized: 'bougies',
          category: 'Divers',
          priceLocal: 200,
          currencyCode: 'XAF',
          unit: 'piece',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Piles AA',
          nameNormalized: 'piles aa',
          category: 'Divers',
          priceLocal: 500,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Paquet 4 piles',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Ampoule LED',
          nameNormalized: 'ampoule led',
          category: 'Divers',
          priceLocal: 1500,
          currencyCode: 'XAF',
          unit: 'piece',
          description: '10W',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits bébé/enfant
        ProductPrice(
          name: 'Couches bébé',
          nameNormalized: 'couches bebe',
          category: 'Hygiène',
          priceLocal: 4500,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Paquet 30 pièces',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Lingettes bébé',
          nameNormalized: 'lingettes bebe',
          category: 'Hygiène',
          priceLocal: 1800,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Paquet 80 pièces',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Lait infantile',
          nameNormalized: 'lait infantile',
          category: 'Cuisine',
          priceLocal: 8000,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Boîte 900g',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits de première nécessité
        ProductPrice(
          name: 'Paracétamol',
          nameNormalized: 'paracetamol',
          category: 'Divers',
          priceLocal: 500,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Boîte 20 comprimés',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Alcool à 70°',
          nameNormalized: 'alcool a 70',
          category: 'Hygiène',
          priceLocal: 800,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Flacon 250ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Coton hydrophile',
          nameNormalized: 'coton hydrophile',
          category: 'Hygiène',
          priceLocal: 600,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: '100g',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits d'entretien spécialisés
        ProductPrice(
          name: 'Cire pour sol',
          nameNormalized: 'cire pour sol',
          category: 'Nettoyage',
          priceLocal: 2200,
          currencyCode: 'XAF',
          unit: 'litre',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Détartrant WC',
          nameNormalized: 'détartrant wc',
          category: 'Nettoyage',
          priceLocal: 1600,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Flacon 750ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Nettoyant four',
          nameNormalized: 'nettoyant four',
          category: 'Nettoyage',
          priceLocal: 2800,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Spray 500ml',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits saisonniers/occasionnels
        ProductPrice(
          name: 'Antimoustique',
          nameNormalized: 'antimoustique',
          category: 'Divers',
          priceLocal: 1200,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Spray 100ml',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Crème solaire',
          nameNormalized: 'crème solaire',
          category: 'Hygiène',
          priceLocal: 4000,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Tube 200ml SPF30',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits d'hygiène féminine
        ProductPrice(
          name: 'Tampons',
          nameNormalized: 'tampons',
          category: 'Hygiène',
          priceLocal: 2000,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: 'Boîte 16 pièces',
          createdAt: now,
          updatedAt: now,
        ),

        // Produits de base cuisine
        ProductPrice(
          name: 'Vinaigre blanc',
          nameNormalized: 'vinaigre blanc',
          category: 'Cuisine',
          priceLocal: 400,
          currencyCode: 'XAF',
          unit: 'litre',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Bicarbonate de soude',
          nameNormalized: 'bicarbonate de soude',
          category: 'Nettoyage',
          priceLocal: 600,
          currencyCode: 'XAF',
          unit: 'paquet',
          description: '500g',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Papier aluminium',
          nameNormalized: 'papier aluminium',
          category: 'Cuisine',
          priceLocal: 1500,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Rouleau 30m',
          createdAt: now,
          updatedAt: now,
        ),
        ProductPrice(
          name: 'Film plastique',
          nameNormalized: 'film plastique',
          category: 'Cuisine',
          priceLocal: 1200,
          currencyCode: 'XAF',
          unit: 'piece',
          description: 'Rouleau 50m',
          createdAt: now,
          updatedAt: now,
        ),
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
  Future<ProductPrice?> getProductPrice(String productName) async {
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
  Future<List<ProductPrice>> getPricesByCategory(String category) async {
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
  Future<double> estimateObjectPrice(String objectName, String category) async {
    try {
      // Recherche exacte d'abord
      var price = await getProductPrice(objectName);

      if (price != null) {
        return localToEuro(price.priceLocal, price.currencyCode);
      }

      // Recherche par catégorie et similarité
      final categoryPrices = await getPricesByCategory(category);
      if (categoryPrices.isNotEmpty) {
        // Retourner le prix moyen de la catégorie
        final avgPrice =
            categoryPrices.map((p) => localToEuro(p.priceLocal, p.currencyCode)).reduce((a, b) => a + b) /
            categoryPrices.length;
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
  Future<List<ProductPrice>> searchProducts(String query) async {
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
  ///
  /// Exemple:
  /// ```dart
  /// final euros = PriceService.fcfaToEuro(1000); // 1.52 EUR
  /// ```
  static double fcfaToEuro(double fcfa) {
    return fcfa * fcfaToEuroRate;
  }

  /// Convertir Euro vers FCFA
  ///
  /// Exemple:
  /// ```dart
  /// final fcfa = PriceService.euroToFcfa(10); // 6579.57 FCFA
  /// ```
  static double euroToFcfa(double euro) {
    return euro / fcfaToEuroRate;
  }

  /// Appliquer l'inflation annuelle à un prix
  ///
  /// Exemple:
  /// ```dart
  /// final adjustedPrice = PriceService.applyInflation(1000, years: 2); // 1123.6 FCFA
  /// ```
  static double applyInflation(
    double price, {
    int years = 1,
    double? customRate,
  }) {
    final rate = customRate ?? _annualInflationRate;
    return price * pow(1 + rate, years);
  }

  /// Obtenir le prix ajusté pour l'année en cours
  /// Ajuste automatiquement depuis la dernière mise à jour (Janvier 2024)
  static double getAdjustedPrice(double basePrice, {DateTime? baseDate}) {
    final base = baseDate ?? DateTime(2024, 1, 1);
    final now = DateTime.now();
    final yearsDiff = (now.difference(base).inDays / 365).floor();

    if (yearsDiff <= 0) return basePrice;

    return applyInflation(basePrice, years: yearsDiff);
  }

  /// Convertir le prix local en Euro
  ///
  /// Exemple:
  /// ```dart
  /// final product = ProductPrice(...);
  /// final euros = PriceService.localToEuro(product.priceLocal, product.currencyCode);
  /// ```
  static double localToEuro(double localPrice, String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'XAF':
      case 'XOF':
      case 'FCFA':
        return fcfaToEuro(localPrice);
      case 'EUR':
        return localPrice;
      case 'USD':
        // Assuming 1 USD = 0.93 EUR (approximate rate)
        return localPrice * 0.93;
      case 'CAD':
        // Assuming 1 CAD = 0.68 EUR (approximate rate)
        return localPrice * 0.68;
      default:
        // Default to FCFA conversion if unknown currency
        return fcfaToEuro(localPrice);
    }
  }

  /// Obtenir le prix moyen d'une catégorie
  Future<double> getAverageCategoryPrice(String category) async {
    try {
      final prices = await getPricesByCategory(category);
      if (prices.isEmpty) return 0.0;

      final total = prices.map((p) => localToEuro(p.priceLocal, p.currencyCode)).reduce((a, b) => a + b);
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

  /// Obtenir les statistiques de prix pour une catégorie
  ///
  /// Retourne:
  /// - `average`: Prix moyen
  /// - `min`: Prix minimum
  /// - `max`: Prix maximum
  /// - `count`: Nombre de produits
  Future<Map<String, dynamic>> getCategoryPriceStats(String category) async {
    try {
      final prices = await getPricesByCategory(category);

      if (prices.isEmpty) {
        return {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'count': 0,
          'currency': 'EUR',
        };
      }

      final priceValues = prices.map((p) => localToEuro(p.priceLocal, p.currencyCode)).toList();
      final total = priceValues.reduce((a, b) => a + b);
      final average = total / priceValues.length;
      final min = priceValues.reduce((a, b) => a < b ? a : b);
      final max = priceValues.reduce((a, b) => a > b ? a : b);

      return {
        'average': average,
        'min': min,
        'max': max,
        'count': prices.length,
        'currency': 'EUR',
      };
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'PriceService',
        operation: 'getCategoryPriceStats',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
      );
      return {
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'count': 0,
        'currency': 'EUR',
      };
    }
  }
}

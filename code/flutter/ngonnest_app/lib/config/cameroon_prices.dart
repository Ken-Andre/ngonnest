// TODO Implement this library.
/// Base de données des prix moyens en FCFA pour les produits essentiels camerounais
/// Utilisée pour les calculs budgétaires et recommandations économiques
class CameroonPrices {
  static const Map<String, ProductPrice> _pricesDatabase = {
    // === ALIMENTATION DE BASE ===
    'riz': ProductPrice(
      name: 'Riz',
      category: 'Alimentation',
      averagePrice: 650.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 500.0, max: 800.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Riz local, qualité standard',
    ),
    'huile_palme': ProductPrice(
      name: 'Huile de palme',
      category: 'Alimentation',
      averagePrice: 1200.0, // FCFA par litre
      unit: 'litre',
      priceRange: PriceRange(min: 1000.0, max: 1500.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Huile rouge traditionnelle',
    ),
    'plantain': ProductPrice(
      name: 'Plantain',
      category: 'Alimentation',
      averagePrice: 150.0, // FCFA par unité
      unit: 'unité',
      priceRange: PriceRange(min: 100.0, max: 200.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Plantain mûr, taille moyenne',
    ),
    'haricot': ProductPrice(
      name: 'Haricot',
      category: 'Alimentation',
      averagePrice: 800.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 600.0, max: 1000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Haricot rouge sec',
    ),
    'manioc': ProductPrice(
      name: 'Manioc',
      category: 'Alimentation',
      averagePrice: 300.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 200.0, max: 400.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Manioc frais',
    ),
    'poisson_fume': ProductPrice(
      name: 'Poisson fumé',
      category: 'Alimentation',
      averagePrice: 2500.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 2000.0, max: 3000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Poisson fumé local',
    ),
    'tomate': ProductPrice(
      name: 'Tomate',
      category: 'Alimentation',
      averagePrice: 500.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 300.0, max: 700.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Tomate fraîche, selon saison',
    ),
    'oignon': ProductPrice(
      name: 'Oignon',
      category: 'Alimentation',
      averagePrice: 600.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 400.0, max: 800.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés locaux',
      notes: 'Oignon jaune',
    ),

    // === HYGIÈNE ===
    'savon_marseille': ProductPrice(
      name: 'Savon de Marseille',
      category: 'Hygiène',
      averagePrice: 250.0, // FCFA par unité
      unit: 'unité',
      priceRange: PriceRange(min: 200.0, max: 300.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Pharmacies/Supermarchés',
      notes: 'Savon 100g standard',
    ),
    'dentifrice': ProductPrice(
      name: 'Dentifrice',
      category: 'Hygiène',
      averagePrice: 800.0, // FCFA par tube
      unit: 'tube',
      priceRange: PriceRange(min: 600.0, max: 1000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Pharmacies/Supermarchés',
      notes: 'Tube 75ml marque locale',
    ),
    'shampoing': ProductPrice(
      name: 'Shampoing',
      category: 'Hygiène',
      averagePrice: 1500.0, // FCFA par bouteille
      unit: 'bouteille',
      priceRange: PriceRange(min: 1200.0, max: 2000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Pharmacies/Supermarchés',
      notes: 'Bouteille 400ml',
    ),
    'papier_toilette': ProductPrice(
      name: 'Papier toilette',
      category: 'Hygiène',
      averagePrice: 1200.0, // FCFA par pack de 4
      unit: 'pack',
      priceRange: PriceRange(min: 1000.0, max: 1500.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Pack de 4 rouleaux',
    ),

    // === ENTRETIEN ===
    'eau_javel': ProductPrice(
      name: 'Eau de Javel',
      category: 'Entretien',
      averagePrice: 400.0, // FCFA par litre
      unit: 'litre',
      priceRange: PriceRange(min: 300.0, max: 500.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Eau de Javel concentrée',
    ),
    'liquide_vaisselle': ProductPrice(
      name: 'Liquide vaisselle',
      category: 'Entretien',
      averagePrice: 800.0, // FCFA par bouteille
      unit: 'bouteille',
      priceRange: PriceRange(min: 600.0, max: 1000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Bouteille 500ml',
    ),
    'eponge': ProductPrice(
      name: 'Éponge',
      category: 'Entretien',
      averagePrice: 150.0, // FCFA par unité
      unit: 'unité',
      priceRange: PriceRange(min: 100.0, max: 200.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Éponge grattante standard',
    ),

    // === BOISSONS ===
    'eau_minerale': ProductPrice(
      name: 'Eau minérale',
      category: 'Boissons',
      averagePrice: 300.0, // FCFA par bouteille 1.5L
      unit: 'bouteille',
      priceRange: PriceRange(min: 250.0, max: 350.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Bouteille 1.5L marque locale',
    ),
    'the': ProductPrice(
      name: 'Thé',
      category: 'Boissons',
      averagePrice: 1000.0, // FCFA par boîte
      unit: 'boîte',
      priceRange: PriceRange(min: 800.0, max: 1200.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Boîte de 25 sachets',
    ),
    'cafe': ProductPrice(
      name: 'Café',
      category: 'Boissons',
      averagePrice: 2500.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 2000.0, max: 3000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés/Supermarchés',
      notes: 'Café moulu local',
    ),

    // === CONDIMENTS & ÉPICES ===
    'sel': ProductPrice(
      name: 'Sel',
      category: 'Condiments',
      averagePrice: 200.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 150.0, max: 250.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés',
      notes: 'Sel de cuisine raffiné',
    ),
    'cube_maggi': ProductPrice(
      name: 'Cube Maggi',
      category: 'Condiments',
      averagePrice: 25.0, // FCFA par cube
      unit: 'cube',
      priceRange: PriceRange(min: 20.0, max: 30.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés/Supermarchés',
      notes: 'Cube d\'assaisonnement',
    ),
    'piment': ProductPrice(
      name: 'Piment',
      category: 'Condiments',
      averagePrice: 1000.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 800.0, max: 1200.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés',
      notes: 'Piment rouge séché',
    ),

    // === PRODUITS LAITIERS ===
    'lait_poudre': ProductPrice(
      name: 'Lait en poudre',
      category: 'Produits laitiers',
      averagePrice: 3500.0, // FCFA par boîte 400g
      unit: 'boîte',
      priceRange: PriceRange(min: 3000.0, max: 4000.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Boîte 400g marque internationale',
    ),

    // === CÉRÉALES ===
    'mais': ProductPrice(
      name: 'Maïs',
      category: 'Céréales',
      averagePrice: 400.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 300.0, max: 500.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Marchés',
      notes: 'Maïs sec en grains',
    ),
    'farine_ble': ProductPrice(
      name: 'Farine de blé',
      category: 'Céréales',
      averagePrice: 600.0, // FCFA par kg
      unit: 'kg',
      priceRange: PriceRange(min: 500.0, max: 700.0),
      region: 'Douala/Yaoundé',
      lastUpdated: '2024-01',
      source: 'Supermarchés',
      notes: 'Farine de blé standard',
    ),
  };

  /// Obtient le prix d'un produit par son nom (insensible à la casse)
  static ProductPrice? getPrice(String productName) {
    final normalizedName = _normalizeProductName(productName);
    return _pricesDatabase[normalizedName];
  }

  /// Obtient tous les produits d'une catégorie
  static List<ProductPrice> getProductsByCategory(String category) {
    return _pricesDatabase.values
        .where(
          (price) => price.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  /// Obtient tous les produits avec leurs prix
  static List<ProductPrice> getAllProducts() {
    return _pricesDatabase.values.toList();
  }

  /// Estime le prix d'un produit non trouvé dans la base
  static double? estimatePrice(String productName, String category) {
    final categoryProducts = getProductsByCategory(category);
    if (categoryProducts.isEmpty) return null;

    // Calcul de la moyenne des prix de la catégorie
    final averagePrice =
        categoryProducts.map((p) => p.averagePrice).reduce((a, b) => a + b) /
        categoryProducts.length;

    return averagePrice;
  }

  /// Recherche de produits par nom partiel
  static List<ProductPrice> searchProducts(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    return _pricesDatabase.values
        .where(
          (price) =>
              price.name.toLowerCase().contains(normalizedQuery) ||
              _normalizeProductName(price.name).contains(normalizedQuery),
        )
        .toList();
  }

  /// Obtient les catégories disponibles
  static List<String> getCategories() {
    return _pricesDatabase.values
        .map((price) => price.category)
        .toSet()
        .toList()
      ..sort();
  }

  /// Normalise le nom d'un produit pour la recherche
  static String _normalizeProductName(String name) {
    return name
        .toLowerCase()
        // Remove common prepositions and articles
        .replaceAll(RegExp(r'\b(de|du|des|la|le|les|un|une|et|à|a|au|aux|en|dans|sur|pour|par|avec|sans)\b', caseSensitive: false), '')
        // Normalize accented characters

        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('û', 'u')
        // Replace spaces with underscores
        .replaceAll(' ', '_')
        // Remove any remaining non-word characters except underscores
        .replaceAll(RegExp(r'[^\w_]'), '')
        // Remove multiple consecutive underscores
        .replaceAll(RegExp(r'_+'), '_')
        // Remove leading/trailing underscores
        .replaceAll(RegExp(r'^_|_$'), '');

  }

  /// Calcule le budget estimé pour une liste de produits
  static BudgetEstimate calculateBudget(List<BudgetItem> items) {
    double totalMin = 0.0;
    double totalMax = 0.0;
    double totalAverage = 0.0;
    int foundItems = 0;
    int missingItems = 0;

    for (final item in items) {
      final price = getPrice(item.productName);
      if (price != null) {
        foundItems++;
        final quantity = item.quantity;
        totalMin += price.priceRange.min * quantity;
        totalMax += price.priceRange.max * quantity;
        totalAverage += price.averagePrice * quantity;
      } else {
        missingItems++;
        // Estimation basée sur la catégorie
        final estimated = estimatePrice(
          item.productName,
          item.category ?? 'Autre',
        );
        if (estimated != null) {
          totalAverage += estimated * item.quantity;
          totalMin += estimated * 0.8 * item.quantity; // -20%
          totalMax += estimated * 1.2 * item.quantity; // +20%
        }
      }
    }

    return BudgetEstimate(
      totalMin: totalMin,
      totalMax: totalMax,
      totalAverage: totalAverage,
      foundItems: foundItems,
      missingItems: missingItems,
      totalItems: items.length,
      currency: 'FCFA',
    );
  }
}

/// Modèle pour un prix de produit
class ProductPrice {
  final String name;
  final String category;
  final double averagePrice;
  final String unit;
  final PriceRange priceRange;
  final String region;
  final String lastUpdated;
  final String source;
  final String notes;

  const ProductPrice({
    required this.name,
    required this.category,
    required this.averagePrice,
    required this.unit,
    required this.priceRange,
    required this.region,
    required this.lastUpdated,
    required this.source,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'averagePrice': averagePrice,
      'unit': unit,
      'priceRange': priceRange.toJson(),
      'region': region,
      'lastUpdated': lastUpdated,
      'source': source,
      'notes': notes,
    };
  }
}

/// Modèle pour une fourchette de prix
class PriceRange {
  final double min;
  final double max;

  const PriceRange({required this.min, required this.max});

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }
}

/// Modèle pour un élément de budget
class BudgetItem {
  final String productName;
  final double quantity;
  final String? category;

  const BudgetItem({
    required this.productName,
    required this.quantity,
    this.category,
  });
}

/// Modèle pour une estimation de budget
class BudgetEstimate {
  final double totalMin;
  final double totalMax;
  final double totalAverage;
  final int foundItems;
  final int missingItems;
  final int totalItems;
  final String currency;

  const BudgetEstimate({
    required this.totalMin,
    required this.totalMax,
    required this.totalAverage,
    required this.foundItems,
    required this.missingItems,
    required this.totalItems,
    required this.currency,
  });

  /// Pourcentage de produits trouvés dans la base de prix
  double get coveragePercentage {
    if (totalItems == 0) return 0.0;
    return (foundItems / totalItems) * 100;
  }

  /// Estimation de fiabilité du budget
  String get reliabilityLevel {
    final coverage = coveragePercentage;
    if (coverage >= 80) return 'Élevée';
    if (coverage >= 60) return 'Moyenne';
    if (coverage >= 40) return 'Faible';
    return 'Très faible';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMin': totalMin,
      'totalMax': totalMax,
      'totalAverage': totalAverage,
      'foundItems': foundItems,
      'missingItems': missingItems,
      'totalItems': totalItems,
      'currency': currency,
      'coveragePercentage': coveragePercentage,
      'reliabilityLevel': reliabilityLevel,
    };
  }
}

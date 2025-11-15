import '../models/product_template.dart';

/// Service centralisé pour le renseignement intelligent des produits
///
/// Gère la recherche intelligente, les suggestions automatiques et
/// l'apprentissage des préférences utilisateur pour NgonNest.
///
/// Fonctionnalités principales:
/// - Recherche de produits avec scoring de pertinence
/// - Suggestions basées sur la taille familiale
/// - Cache optimisé pour les performances
/// - Calculs de quantités et fréquences recommandées
/// - Apprentissage des préférences utilisateur
class ProductIntelligenceService {
  static final ProductIntelligenceService _instance =
      ProductIntelligenceService._internal();
  factory ProductIntelligenceService() => _instance;

  ProductIntelligenceService._internal();

  // Cache des suggestions populaires avec gestion mémoire optimisée
  final Map<String, List<ProductTemplate>> _suggestionsCache = {};
  static const int _maxCacheSize =
      50; // Limite pour éviter la surcharge mémoire

  /// Nettoie le cache si nécessaire pour optimiser la mémoire
  void _cleanCacheIfNeeded() {
    if (_suggestionsCache.length > _maxCacheSize) {
      // Garde seulement les 25 entrées les plus récentes
      final keys = _suggestionsCache.keys.toList();
      final keysToRemove = keys.take(keys.length - 25);
      for (final key in keysToRemove) {
        _suggestionsCache.remove(key);
      }
    }
  }

  /// Recherche intelligente de produits avec auto-suggestions
  ///
  /// [query] - Terme de recherche
  /// [category] - Catégorie de produits à filtrer
  /// [isConsumable] - Si true, ne retourne que des consommables ; si false, que des durables
  ///
  /// Retourne une liste de [ProductTemplate] triée par pertinence
  Future<List<ProductTemplate>> searchProducts(
    String query,
    String category, {
    bool? isConsumable,
  }) async {
    if (query.isEmpty) return [];

    try {
      final products = await getProductsByCategory(category);

      // Filtre par type (consommable/durable) si spécifié
      final filteredByType = isConsumable != null
          ? products
                .where(
                  (product) => _isProductType(product.category, isConsumable),
                )
                .toList()
          : products;

      final filtered = filteredByType
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      // Tri par popularité et pertinence
      filtered.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, query, category);
        final bScore = _calculateRelevanceScore(b, query, category);
        return bScore.compareTo(aScore);
      });

      return filtered
          .take(10)
          .toList(); // Limite à 10 résultats pour performance
    } catch (e) {
      print('Erreur lors de la recherche de produits: $e');
      return [];
    }
  }

  /// Détermine si un produit est consommable ou durable basé sur sa catégorie
  bool _isProductType(String category, bool isConsumable) {
    if (isConsumable) {
      // Catégories consommables
      return [
        'hygiene',
        'menage',
        'nourriture',
        'bureau',
        'maintenance',
        'securite',
        'evenementiel',
        'autre',
      ].contains(category);
    } else {
      // Catégorie durables
      return category == 'durables';
    }
  }

  /// Todo Calcule le score de pertinence pour le tri des suggestions
  double _calculateRelevanceScore(
    ProductTemplate product,
    String query,
    String category,
  ) {
    double score = 0.0;

    // Boost pour les correspondances exactes
    if (product.name.toLowerCase() == query.toLowerCase()) score += 50;
    if (product.category.toLowerCase() == category.toLowerCase()) score += 30;

    // Boost pour popularité
    score += product.popularity * 0.1;

    // Boost pour correspondance partielle
    if (product.name.toLowerCase().startsWith(query.toLowerCase())) score += 20;
    if (product.name.toLowerCase().contains(query.toLowerCase())) score += 10;

    return score;
  }

  /// Récupère les produits d'une catégorie (simplifié pour MVP)
  Future<List<Map<String, dynamic>>> getCategoryHierarchy(
    String categoryId,
  ) async {
    final categories = ProductPresets.categories;
    try {
      final category = categories.firstWhere(
        (cat) => cat['id'] == categoryId,
        orElse: () => {'products': []},
      );

      return List<Map<String, dynamic>>.from(category['products'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Récupère toutes les catégories disponibles
  List<Map<String, dynamic>> getAllCategories() {
    return ProductPresets.categories
        .map(
          (category) => {
            'id': category['id'],
            'name': category['name'],
            'icon': category['icon'],
            'popularity': category['popularity'] ?? 0,
          },
        )
        .toList();
  }

  /// Calcule la quantité optimale basée sur la taille familiale
  Future<double> calculateOptimalQuantity(
    ProductTemplate product,
    int familySize,
  ) async {
    final guidelines = product.quantityGuidelines;

    if (guidelines == null) return product.defaultQuantity ?? 1.0;

    // Calcul basé sur les guidelines existants
    final baseQuantity =
        guidelines['family_4'] ?? product.defaultQuantity ?? 1.0;
    final period = guidelines['period'] ?? 30;

    // Ajustement linéaire par taille familiale
    final adjustedQuantity = (familySize / 4.0) * baseQuantity;

    // Quantités communes prédéfinies
    final commonQuantities = product.commonQuantities ?? {};
    final familyKey = '${familySize}_persons';
    if (commonQuantities.containsKey(familyKey)) {
      return commonQuantities[familyKey]!.toDouble();
    }

    return adjustedQuantity.roundToDouble();
  }

  /// Fréquence d'achat recommandée
  Future<int> calculateOptimalFrequency(
    ProductTemplate product,
    int familySize,
  ) async {
    // Base sur les patterns d'usage courants
    final defaultFrequency = product.defaultFrequency ?? 30;

    // Ajustement selon taille familiale (consommation plus rapide = fréquence plus élevée)
    if (familySize <= 2) {
      return (defaultFrequency * 0.8).round(); // Moins fréquent
    }
    if (familySize >= 6) {
      return (defaultFrequency * 1.2).round(); // Plus fréquent
    }

    return defaultFrequency;
  }

  /// Apprend des préférences utilisateur
  Future<void> learnFromUserChoice(
    String productId,
    String category,
    int familySize,
  ) async {
    // TODO: Implémenter tracking des préférences utilisateur
    // Sauvegarde dans la base de données pour apprentissage futur
    print(
      'Learning from user choice: $productId in $category for family size $familySize',
    );
  }

  /// Produits populaires par catégorie avec cache optimisé
  ///
  /// [category] - Catégorie de produits à récupérer
  ///
  /// Retourne les 5 produits les plus populaires de la catégorie
  Future<List<ProductTemplate>> getPopularProductsByCategory(
    String category,
  ) async {
    // Pour les durables, utiliser toujours la catégorie 'durables' comme clé de cache
    final cacheKey =
        category == 'durables' ||
            [
              'electromenager',
              'meubles',
              'electronique',
              'jardin',
              'voiture',
              'sport',
            ].contains(category)
        ? 'durables'
        : category;

    if (_suggestionsCache.containsKey(cacheKey)) {
      return _suggestionsCache[cacheKey]!;
    }

    try {
      final products = await getProductsByCategory(category);
      final sorted = products.where((p) => p.popularity > 10).toList()
        ..sort((a, b) => b.popularity.compareTo(a.popularity));

      _suggestionsCache[cacheKey] = sorted.take(5).toList();
      _cleanCacheIfNeeded(); // Optimisation mémoire
      return _suggestionsCache[cacheKey]!;
    } catch (e) {
      print('Erreur récupération produits populaires: $e');
      return [];
    }
  }

  /// Récupère tous les produits d'une catégorie (methode publique)
  Future<List<ProductTemplate>> getProductsByCategory(String category) async {
    try {
      // Pour les durables, utiliser toujours la catégorie 'durables'
      final actualCategory =
          category == 'durables' ||
              [
                'electromenager',
                'meubles',
                'electronique',
                'jardin',
                'voiture',
                'sport',
              ].contains(category)
          ? 'durables'
          : category;

      final categoryData = ProductPresets.categories.firstWhere(
        (cat) => cat['id'] == actualCategory,
        orElse: () => {'products': []},
      );

      final products = <ProductTemplate>[];

      // Produits de la catégorie principale
      final categoryProducts = categoryData['products'] as List<dynamic>? ?? [];
      products.addAll(
        categoryProducts.map(
          (p) => ProductTemplate.fromMap({...p, 'category': category}),
        ),
      );

      return products;
    } catch (e) {
      print('Erreur récupération catégorie $category: $e');
      return [];
    }
  }

  /// Évalue si un produit correspond aux besoins familiaux
  Future<bool> isProductSuitableForFamily(
    ProductTemplate product,
    int familySize,
  ) async {
    // Logique basée sur les guidelines de quantité
    final guidelines = product.quantityGuidelines;
    if (guidelines == null) {
      return true; // Si pas de guidelines, considérer comme adapté
    }

    final recommended = await calculateOptimalQuantity(product, familySize);
    return recommended > 0; // Produit adapté si une quantité peut être calculée
  }
}

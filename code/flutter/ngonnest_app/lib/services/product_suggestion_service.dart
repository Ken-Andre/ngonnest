import '../models/foyer.dart';
import '../models/objet.dart';
import '../repository/foyer_repository.dart';
import '../repository/inventory_repository.dart';
import 'error_logger_service.dart';

/// Service intelligent de suggestions de produits basé sur le profil du foyer
/// Analyse la composition du foyer, l'historique et les habitudes pour proposer des produits pertinents
class ProductSuggestionService {
  final FoyerRepository _foyerRepository;
  final InventoryRepository _inventoryRepository;

  // Constructor for dependency injection
  ProductSuggestionService({
    required FoyerRepository foyerRepository,
    required InventoryRepository inventoryRepository,
  }) : _foyerRepository = foyerRepository,
       _inventoryRepository = inventoryRepository;

  /// Obtient des suggestions de produits intelligentes basées sur le profil du foyer
  Future<List<ProductSuggestion>> getSmartSuggestions({
    required int foyerId,
    String? category,
    String? room,
    int limit = 10,
  }) async {
    try {
      // No need for parse check since foyerId is now int
      final foyer = await _foyerRepository.get();
      if (foyer == null) {
        return [];
      }

      // Récupérer l'historique des produits du foyer
      final existingProducts = await _inventoryRepository.getAll(foyerId);

      // Générer les suggestions basées sur différents critères
      final suggestions = <ProductSuggestion>[];

      // 1. Suggestions basées sur la composition du foyer
      suggestions.addAll(await _getFamilyBasedSuggestions(foyer, category));

      // 2. Suggestions basées sur l'historique
      suggestions.addAll(
        await _getHistoryBasedSuggestions(existingProducts, category),
      );

      // 3. Suggestions basées sur la pièce
      if (room != null) {
        suggestions.addAll(await _getRoomBasedSuggestions(room, category));
      }

      // 4. Suggestions essentielles manquantes
      suggestions.addAll(
        await _getEssentialMissingSuggestions(
          foyer,
          existingProducts,
          category,
        ),
      );

      // Filtrer, déduplicater et trier par pertinence
      final uniqueSuggestions = _deduplicateAndRank(suggestions);

      return uniqueSuggestions.take(limit).toList();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'ProductSuggestionService',
        operation: 'getSmartSuggestions',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {
          'foyerId': foyerId,
          'category': category ?? 'all',
          'room': room ?? 'all',
        },
      );
      return [];
    }
  }

  /// Suggestions basées sur la composition familiale
  Future<List<ProductSuggestion>> _getFamilyBasedSuggestions(
    Foyer foyer,
    String? category,
  ) async {
    final suggestions = <ProductSuggestion>[];
    final familySize = foyer.nbPersonnes; // Corrected: Using nbPersonnes

    // Suggestions pour familles avec enfants
    if (foyer.hasChildren) {
      // Using extension method
      suggestions.addAll([
        ProductSuggestion(
          name: 'Lait en poudre',
          category: 'Alimentation',
          reason: 'Recommandé pour les familles avec enfants',
          confidence: 0.9,
          estimatedQuantity: familySize * 0.5, // Adjusted quantity logic
          unit: 'boîtes',
          priority: SuggestionPriority.high,
        ),
        ProductSuggestion(
          name: 'Céréales petit-déjeuner',
          category: 'Alimentation',
          reason: 'Populaire dans les familles avec enfants',
          confidence: 0.8,
          estimatedQuantity: familySize * 0.3, // Adjusted quantity logic
          unit: 'paquets',
          priority: SuggestionPriority.medium,
        ),
      ]);
    }

    // Suggestions pour grandes familles
    if (familySize >= 5) {
      suggestions.addAll([
        ProductSuggestion(
          name: 'Riz (sac)',
          category: 'Alimentation',
          reason: 'Économique pour grande famille',
          confidence: 0.95,
          estimatedQuantity: (familySize / 5.0)
              .ceilToDouble(), // Adjusted quantity logic
          unit: 'sacs',
          priority: SuggestionPriority.high,
        ),
        ProductSuggestion(
          name:
              'Huile végétale (bidon)', // Changed from Huile de palme for neutrality
          category: 'Alimentation',
          reason: 'Consommation élevée en grande famille',
          confidence: 0.9,
          estimatedQuantity: (familySize / 5.0)
              .ceilToDouble(), // Adjusted quantity logic
          unit: 'bidons',
          priority: SuggestionPriority.high,
        ),
      ]);
    }

    // Filtrer par catégorie si spécifiée
    if (category != null) {
      return suggestions
          .where((s) => s.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    return suggestions;
  }

  /// Suggestions basées sur l'historique des achats
  Future<List<ProductSuggestion>> _getHistoryBasedSuggestions(
    List<Objet> existingProducts,
    String? category,
  ) async {
    final suggestions = <ProductSuggestion>[];

    final categoryFrequency = <String, int>{};
    for (final product in existingProducts) {
      categoryFrequency[product.categorie] =
          (categoryFrequency[product.categorie] ?? 0) + 1;
    }

    for (final entry in categoryFrequency.entries) {
      if (entry.value >= 2) {
        suggestions.addAll(_getComplementaryProducts(entry.key, entry.value));
      }
    }

    for (final product in existingProducts) {
      if (product.type == TypeObjet.consommable &&
          product.quantiteRestante <= (product.quantiteInitiale * 0.3)) {
        suggestions.add(
          ProductSuggestion(
            name: product.nom,
            category: product.categorie,
            reason: 'Stock faible - renouvellement suggéré',
            confidence: 0.95,
            estimatedQuantity: product.quantiteInitiale,
            unit: product.unite,
            priority: SuggestionPriority.high,
          ),
        );
      }
    }

    if (category != null) {
      return suggestions
          .where((s) => s.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    return suggestions;
  }

  /// Suggestions basées sur la pièce
  Future<List<ProductSuggestion>> _getRoomBasedSuggestions(
    String room,
    String? category,
  ) async {
    final roomSuggestions = <String, List<ProductSuggestion>>{
      'Cuisine': [
        ProductSuggestion(
          name: 'Éponges de nettoyage',
          category: 'Entretien',
          reason: 'Essentiel pour la cuisine',
          confidence: 0.8,
          estimatedQuantity: 3.0,
          unit: 'unités',
          priority: SuggestionPriority.medium,
        ),
        ProductSuggestion(
          name: 'Liquide vaisselle concentré',
          category: 'Entretien',
          reason: 'Nécessaire pour la cuisine',
          confidence: 0.9,
          estimatedQuantity: 1.0,
          unit: 'bouteille',
          priority: SuggestionPriority.medium,
        ),
      ],
      'Salle de bain': [
        ProductSuggestion(
          name: 'Savon corporel',
          category: 'Hygiène',
          reason: 'Indispensable salle de bain',
          confidence: 0.95,
          estimatedQuantity: 2.0,
          unit: 'unités',
          priority: SuggestionPriority.high,
        ),
        ProductSuggestion(
          name: 'Papier hygiénique (pack)',
          category: 'Hygiène',
          reason: 'Consommable essentiel SDB',
          confidence: 0.95,
          estimatedQuantity: 1.0,
          unit: 'pack de 6',
          priority: SuggestionPriority.high,
        ),
      ],
      'Salon': [
        ProductSuggestion(
          name: 'Ampoules LED économiques',
          category: 'Éclairage',
          reason: 'Éclairage principal salon',
          confidence: 0.7,
          estimatedQuantity: 2.0,
          unit: 'unités',
          priority: SuggestionPriority.low,
        ),
      ],
    };

    final suggestions = roomSuggestions[room] ?? [];

    if (category != null) {
      return suggestions
          .where((s) => s.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    return suggestions;
  }

  /// Suggestions d'essentiels manquants
  Future<List<ProductSuggestion>> _getEssentialMissingSuggestions(
    Foyer foyer,
    List<Objet> existingProducts,
    String? category,
  ) async {
    final essentials = [
      ProductSuggestion(
        name: 'Riz Parfumé',
        category: 'Alimentation',
        reason: 'Aliment de base courant',
        confidence: 0.95,
        estimatedQuantity: 5.0,
        unit: 'kg',
        priority: SuggestionPriority.high,
      ),
      ProductSuggestion(
        name: 'Huile Végétale',
        category: 'Alimentation',
        reason: 'Huile de cuisson polyvalente',
        confidence: 0.9,
        estimatedQuantity: 1.0,
        unit: 'litre',
        priority: SuggestionPriority.high,
      ),
      ProductSuggestion(
        name: 'Plantain Mûr',
        category: 'Alimentation',
        reason: 'Accompagnement populaire',
        confidence: 0.85,
        estimatedQuantity: 5.0, // adjusted from 10
        unit: 'mains', // adjusted unit
        priority: SuggestionPriority.medium,
      ),
      ProductSuggestion(
        name: 'Sel de cuisine',
        category: 'Alimentation',
        reason: 'Essentiel pour l\'assaisonnement',
        confidence: 0.98,
        estimatedQuantity: 1.0,
        unit: 'kg',
        priority: SuggestionPriority.high,
      ),
      ProductSuggestion(
        name: 'Sucre en morceaux',
        category: 'Alimentation',
        reason: 'Pour le petit-déjeuner et boissons',
        confidence: 0.80,
        estimatedQuantity: 1.0,
        unit: 'kg',
        priority: SuggestionPriority.medium,
      ),
    ];

    final existingNames = existingProducts
        .map((p) => p.nom.toLowerCase())
        .toSet();
    final missingSuggestions = essentials
        .where((s) => !existingNames.contains(s.name.toLowerCase()))
        .toList();

    if (category != null) {
      return missingSuggestions
          .where((s) => s.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    return missingSuggestions;
  }

  List<ProductSuggestion> _getComplementaryProducts(
    String category,
    int frequency,
  ) {
    final complementary = <String, List<ProductSuggestion>>{
      'Alimentation': [
        ProductSuggestion(
          name: 'Cube de bouillon Maggi',
          category: 'Alimentation',
          reason: 'Rehausseur de goût commun',
          confidence: 0.7,
          estimatedQuantity: 1.0,
          unit: 'boîte',
          priority: SuggestionPriority.low,
        ),
      ],
      'Entretien': [
        ProductSuggestion(
          name: 'Eau de Javel La Croix',
          category: 'Entretien',
          reason: 'Désinfectant multi-usage',
          confidence: 0.6,
          estimatedQuantity: 1.0,
          unit: 'litre',
          priority: SuggestionPriority.low,
        ),
      ],
      'Hygiène': [
        ProductSuggestion(
          name: 'Dentifrice Colgate',
          category: 'Hygiène',
          reason: 'Pour une bonne hygiène buccale',
          confidence: 0.75,
          estimatedQuantity: 1.0,
          unit: 'tube',
          priority: SuggestionPriority.medium,
        ),
      ],
    };

    return complementary[category] ?? [];
  }

  List<ProductSuggestion> _deduplicateAndRank(
    List<ProductSuggestion> suggestions,
  ) {
    final uniqueMap = <String, ProductSuggestion>{};

    for (final suggestion in suggestions) {
      final key =
          '${suggestion.name.toLowerCase()}_${suggestion.category.toLowerCase()}';
      if (!uniqueMap.containsKey(key) ||
          uniqueMap[key]!.confidence < suggestion.confidence ||
          (uniqueMap[key]!.confidence == suggestion.confidence &&
              uniqueMap[key]!.priority.index >
                  suggestion
                      .priority
                      .index) // Prefer higher priority if confidence is same
          ) {
        uniqueMap[key] = suggestion;
      }
    }

    final uniqueSuggestions = uniqueMap.values.toList();

    uniqueSuggestions.sort((a, b) {
      final priorityComparison = a.priority.index.compareTo(b.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return b.confidence.compareTo(a.confidence);
    });

    return uniqueSuggestions;
  }

  Future<List<ProductSuggestion>> searchSuggestions({
    required int foyerId,
    required String query,
    String? category,
    int limit = 5,
  }) async {
    try {
      // This call now correctly uses the injected repositories implicitly
      final allSuggestions = await getSmartSuggestions(
        foyerId: foyerId,
        category: category,
        limit: 100, // Fetch more to allow for good textual search matches
      );

      final queryLower = query.toLowerCase().trim();
      if (queryLower.isEmpty) return [];

      final matchingSuggestions = allSuggestions
          .where((s) => s.name.toLowerCase().contains(queryLower))
          .toList();

      return matchingSuggestions.take(limit).toList();
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'ProductSuggestionService',
        operation: 'searchSuggestions',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {'query': query, 'foyerId': foyerId},
      );
      return [];
    }
  }
}

class ProductSuggestion {
  final String name;
  final String category;
  final String reason;
  final double confidence;
  final double estimatedQuantity;
  final String unit;
  final SuggestionPriority priority;

  const ProductSuggestion({
    required this.name,
    required this.category,
    required this.reason,
    required this.confidence,
    required this.estimatedQuantity,
    required this.unit,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'reason': reason,
      'confidence': confidence,
      'estimatedQuantity': estimatedQuantity,
      'unit': unit,
      'priority': priority.toString(),
    };
  }
}

enum SuggestionPriority { high, medium, low }

extension FoyerExtensions on Foyer {
  bool get hasChildren {
    return nbPersonnes >= 3; // Corrected: Using nbPersonnes directly
  }
}

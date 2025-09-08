/// Template de produit avec métadonnées intelligentes pour les suggestions
class ProductTemplate {
  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final String unit;
  final Map<String, dynamic>? quantityGuidelines;
  final int? defaultFrequency;
  final int popularity;
  final String icon;
  final String? region;
  final Map<String, int>? commonQuantities;
  final double? defaultQuantity;

  const ProductTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.unit,
    this.quantityGuidelines,
    this.defaultFrequency,
    this.popularity = 0,
    required this.icon,
    this.region,
    this.commonQuantities,
    this.defaultQuantity,
  });

  /// Calcule la quantité recommandée basée sur la taille familiale
  double getRecommendedQuantity(int familySize) {
    if (quantityGuidelines == null) return defaultQuantity ?? 1.0;

    // Utilise les guidelines spécifiques par taille de famille
    final familyKey = '${familySize}_persons';
    if (commonQuantities?.containsKey(familyKey) ?? false) {
      return commonQuantities![familyKey]!.toDouble();
    }

    // Calcul basé sur les guidelines existants (famille de 4 par défaut)
    final baseQuantity = quantityGuidelines!['family_4'] ?? defaultQuantity ?? 1.0;
    final adjustedQuantity = (familySize / 4.0) * baseQuantity;

    return adjustedQuantity.roundToDouble();
  }

  /// Fréquence recommandée d'achat
  int getRecommendedFrequency(int familySize) {
    if (defaultFrequency == null) return 30; // Default 30 jours

    // Ajustement selon taille familiale
    if (familySize <= 2) return (defaultFrequency! * 0.8).round(); // Moins fréquent pour petits foyers
    if (familySize >= 6) return (defaultFrequency! * 1.2).round(); // Plus fréquent pour gros foyers

    return defaultFrequency!;
  }

  /// Convertit un Map en ProductTemplate
  factory ProductTemplate.fromMap(Map<String, dynamic> map) {
    return ProductTemplate(
      id: map['id'] ?? map['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'unknown',
      name: map['name'] ?? 'Produit inconnu',
      category: map['category'] ?? 'unknown',
      subcategory: map['subcategory'],
      unit: map['unit'] ?? 'unités',
      quantityGuidelines: map['quantityGuidelines'] != null
          ? Map<String, dynamic>.from(map['quantityGuidelines'])
          : null,
      defaultFrequency: map['defaultFrequency'] ?? map['frequency'],
      popularity: (map['popularity'] as num?)?.toInt() ?? 10, // Popularité par défaut moyenne
      icon: map['icon'] ?? '📦',
      region: map['region'],
      commonQuantities: map['commonQuantities'] != null
          ? Map<String, int>.from(Map<String, dynamic>.from(map['commonQuantities']).map(
              (key, value) => MapEntry(key, (value as num).toInt())))
          : null,
      defaultQuantity: map['defaultQuantity']?.toDouble(),
    );
  }

  /// Convertit le template en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'unit': unit,
      'quantityGuidelines': quantityGuidelines,
      'defaultFrequency': defaultFrequency,
      'popularity': popularity,
      'icon': icon,
      'region': region,
      'commonQuantities': commonQuantities,
      'defaultQuantity': defaultQuantity,
    };
  }

  /// Crée une copie avec des modifications
  ProductTemplate copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    String? unit,
    Map<String, dynamic>? quantityGuidelines,
    int? defaultFrequency,
    int? popularity,
    String? icon,
    String? region,
    Map<String, int>? commonQuantities,
    double? defaultQuantity,
  }) {
    return ProductTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      unit: unit ?? this.unit,
      quantityGuidelines: quantityGuidelines ?? this.quantityGuidelines,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      popularity: popularity ?? this.popularity,
      icon: icon ?? this.icon,
      region: region ?? this.region,
      commonQuantities: commonQuantities ?? this.commonQuantities,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
    );
  }

  @override
  String toString() {
    return 'ProductTemplate(id: $id, name: $name, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductTemplate) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Données prédéfinies des produits organisées par catégorie pour gestion maison Camerounaise
class ProductPresets {
  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'hygiene',
      'name': 'Hygiène',
      'icon': '🧴',
      'popularity': 95,
      'products': [
        // Hygiène personnelle
        {
          'name': 'Savon de toilette',
          'unit': 'pièces',
          'defaultFrequency': 90,
          'popularity': 95,
          'icon': '🧼',
          'quantityGuidelines': {'family_4': 4},
        },
        {
          'name': 'Shampooing',
          'unit': 'L',
          'defaultFrequency': 90,
          'popularity': 85,
          'icon': '🧴',
          'quantityGuidelines': {'family_4': 0.75},
        },
        {
          'name': 'Gel douche',
          'unit': 'L',
          'defaultFrequency': 75,
          'popularity': 80,
          'icon': '🚿',
          'quantityGuidelines': {'family_4': 0.5},
        },
        {
          'name': 'Dentifrice adulte',
          'unit': 'pièces',
          'defaultFrequency': 90,
          'popularity': 85,
          'icon': '🦷',
          'quantityGuidelines': {'family_4': 2},
        },
        {
          'name': 'Dentifrice enfants',
          'unit': 'pièces',
          'defaultFrequency': 75,
          'popularity': 70,
          'icon': '👶',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Papier toilette',
          'unit': 'pack',
          'defaultFrequency': 14,
          'popularity': 100,
          'icon': '🧻',
          'quantityGuidelines': {'family_4': 12},
        },
        {
          'name': 'Serviettes hygiéniques',
          'unit': 'pack',
          'defaultFrequency': 30,
          'popularity': 75,
          'icon': '📱',
          'quantityGuidelines': {'family_4': 4},
        },
        {
          'name': 'Cotons/Compresses',
          'unit': 'pack',
          'defaultFrequency': 180,
          'popularity': 65,
          'icon': '👂',
          'quantityGuidelines': {'family_4': 2},
        },
      ],
    },
    {
      'id': 'menage',
      'name': 'Ménage',
      'icon': '🧹',
      'popularity': 90,
      'products': [
        // Ustensiles de cuisine et ménage
        {
          'name': 'Éponge vaisselle',
          'unit': 'pièces',
          'defaultFrequency': 30,
          'popularity': 90,
          'icon': '🧽',
          'quantityGuidelines': {'family_4': 3},
        },
        {
          'name': 'Balai souple',
          'unit': 'pièces',
          'defaultFrequency': 365,
          'popularity': 85,
          'icon': '🧹',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Pelle à poussière',
          'unit': 'pièces',
          'defaultFrequency': 365,
          'popularity': 80,
          'icon': '🧹',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Raclette',
          'unit': 'pièces',
          'defaultFrequency': 180,
          'popularity': 75,
          'icon': '🪒',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Serpillière',
          'unit': 'pièces',
          'defaultFrequency': 365,
          'popularity': 85,
          'icon': '🧺',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Torchoons cuisine',
          'unit': 'pièces',
          'defaultFrequency': 90,
          'popularity': 80,
          'icon': '🧺',
          'quantityGuidelines': {'family_4': 4},
        },
        {
          'name': 'Bouchon cuisine',
          'unit': 'pack',
          'defaultFrequency': 365,
          'popularity': 70,
          'icon': '🔌',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Alimentum/papieralum',
          'unit': 'pack',
          'defaultFrequency': 30,
          'popularity': 65,
          'icon': '🍽️',
          'quantityGuidelines': {'family_4': 2},
        },
        // Produits nettoyage
        {
          'name': 'Produit vaisselle',
          'unit': 'L',
          'defaultFrequency': 45,
          'popularity': 90,
          'icon': '🍽️',
          'quantityGuidelines': {'family_4': 0.75},
        },
        {
          'name': 'Détergent lessive',
          'unit': 'kg',
          'defaultFrequency': 60,
          'popularity': 95,
          'icon': '👕',
          'quantityGuidelines': {'family_4': 3},
        },
        {
          'name': 'Produit sol/multisurface',
          'unit': 'L',
          'defaultFrequency': 45,
          'popularity': 80,
          'icon': '🏠',
          'quantityGuidelines': {'family_4': 0.5},
        },
        {
          'name': 'Produit WC',
          'unit': 'pack',
          'defaultFrequency': 90,
          'popularity': 85,
          'icon': '🪠',
          'quantityGuidelines': {'family_4': 2},
        },
        {
          'name': 'Sacs poubelle',
          'unit': 'pack',
          'defaultFrequency': 30,
          'popularity': 85,
          'icon': '🗑️',
          'quantityGuidelines': {'family_4': 12},
        },
      ],
    },
    {
      'id': 'nourriture',
      'name': 'Nourriture',
      'icon': '🍳',
      'popularity': 88,
      'products': [
        {
          'name': 'Huile palme',
          'unit': 'L',
          'defaultFrequency': 90,
          'popularity': 85,
          'icon': '🥥',
          'quantityGuidelines': {'family_4': 1.5},
        },
        {
          'name': 'Huile arachide',
          'unit': 'L',
          'defaultFrequency': 90,
          'popularity': 80,
          'icon': '🥜',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Sucre',
          'unit': 'kg',
          'defaultFrequency': 180,
          'popularity': 90,
          'icon': '🍯',
          'quantityGuidelines': {'family_4': 2},
        },
        {
          'name': 'Sel de cuisine',
          'unit': 'kg',
          'defaultFrequency': 365,
          'popularity': 95,
          'icon': '🧂',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Lait concentré',
          'unit': 'pièces',
          'defaultFrequency': 60,
          'popularity': 75,
          'icon': '🥛',
          'quantityGuidelines': {'family_4': 6},
        },
        {
          'name': 'Thé/Café',
          'unit': 'pièces',
          'defaultFrequency': 90,
          'popularity': 80,
          'icon': '☕',
          'quantityGuidelines': {'family_4': 3},
        },
        {
          'name': 'Riz Bafia',
          'unit': 'kg',
          'defaultFrequency': 30,
          'popularity': 85,
          'icon': '🍚',
          'quantityGuidelines': {'family_4': 2},
        },
        {
          'name': 'Haricots rouges',
          'unit': 'kg',
          'defaultFrequency': 60,
          'popularity': 75,
          'icon': '🫘',
          'quantityGuidelines': {'family_4': 1.5},
        },
      ],
    },
    {
      'id': 'durables',
      'name': 'Durables',
      'icon': '🏠',
      'popularity': 85,
      'products': [
        // Électroménagers et meubles
        {
          'name': 'Téléviseur',
          'unit': 'pièces',
          'defaultFrequency': 1825, // ~5 ans
          'popularity': 95,
          'icon': '📺',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Ventilateur',
          'unit': 'pièces',
          'defaultFrequency': 1825, // ~5 ans
          'popularity': 90,
          'icon': '💨',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Climatiseur',
          'unit': 'pièces',
          'defaultFrequency': 2555, // ~7 ans
          'popularity': 80,
          'icon': '❄️',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Réfrigérateur',
          'unit': 'pièces',
          'defaultFrequency': 2555, // ~7 ans
          'popularity': 90,
          'icon': '🧊',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Plaque cuisson',
          'unit': 'pièces',
          'defaultFrequency': 1825, // ~5 ans
          'popularity': 85,
          'icon': '🔥',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Machine à laver',
          'unit': 'pièces',
          'defaultFrequency': 2555, // ~7 ans
          'popularity': 85,
          'icon': '🧺',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Chauffage électrique',
          'unit': 'pièces',
          'defaultFrequency': 1825, // ~5 ans
          'popularity': 70,
          'icon': '🔥',
          'quantityGuidelines': {'family_4': 1},
        },
        // Meubles
        {
          'name': 'Canapé salon',
          'unit': 'pièces',
          'defaultFrequency': 2555, // ~7 ans
          'popularity': 85,
          'icon': '🛋️',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Meuble TV',
          'unit': 'pièces',
          'defaultFrequency': 1825, // ~5 ans
          'popularity': 80,
          'icon': '📺',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Table salle à manger',
          'unit': 'pièces',
          'defaultFrequency': 2555, // ~7 ans
          'popularity': 80,
          'icon': '🍽️',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Chaises',
          'unit': 'pièces',
          'defaultFrequency': 1825, // ~5 ans
          'popularity': 85,
          'icon': '🪑',
          'quantityGuidelines': {'family_4': 4},
        },
        {
          'name': 'Lit complet',
          'unit': 'pièces',
          'defaultFrequency': 3650, // ~10 ans
          'popularity': 90,
          'icon': '🛏️',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Armoire',
          'unit': 'pièces',
          'defaultFrequency': 2555, // ~7 ans
          'popularity': 85,
          'icon': '🗂️',
          'quantityGuidelines': {'family_4': 1},
        },
        {
          'name': 'Cuisine complète',
          'unit': 'pièces',
          'defaultFrequency': 3650, // ~10 ans
          'popularity': 80,
          'icon': '🍳',
          'quantityGuidelines': {'family_4': 1},
        },
        // Électronique petite
        {
          'name': 'Ampoules',
          'unit': 'pack',
          'defaultFrequency': 730, // ~2 ans
          'popularity': 90,
          'icon': '💡',
          'quantityGuidelines': {'family_4': 2},
        },
        {
          'name': 'Piles/Batteries',
          'unit': 'pack',
          'defaultFrequency': 365, // ~1 an
          'popularity': 80,
          'icon': '🔋',
          'quantityGuidelines': {'family_4': 3},
        },
      ],
    },
  ];
}

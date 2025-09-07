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

/// Données prédéfinies des produits organisées par catégorie hiérarchique
class ProductPresets {
  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'hygiene',
      'name': 'Hygiène',
      'icon': '🧴',
      'subcategories': [
        {
          'id': 'savon',
          'name': 'Savon',
          'products': [
            {
              'name': 'Savon artisanal',
              'unit': 'pièces',
              'defaultFrequency': 30,
              'popularity': 85,
              'icon': '🧼',
              'quantityGuidelines': {
                'family_4': 2,
                'period': 30,
              },
              'commonQuantities': {
                '2_persons': 1,
                '4_persons': 2,
                '6_persons': 3,
              },
            },
            {
              'name': 'Savon liquide mains',
              'unit': 'L',
              'defaultFrequency': 45,
              'popularity': 90,
              'icon': '🧴',
              'quantityGuidelines': {
                'family_4': 0.5,
                'period': 45,
              },
              'commonQuantities': {
                '2_persons': 0.25,
                '4_persons': 0.5,
                '6_persons': 1.0,
              },
            },
            {
              'name': 'Gel douche',
              'unit': 'L',
              'defaultFrequency': 30,
              'popularity': 75,
              'icon': '🚿',
              'quantityGuidelines': {
                'family_4': 0.75,
                'period': 30,
              },
            },
          ],
        },
        {
          'id': 'dentifrice',
          'name': 'Dentifrice',
          'products': [
            {
              'name': 'Dentifrice adulte',
              'unit': 'pièces',
              'defaultFrequency': 90,
              'popularity': 80,
              'icon': '🦷',
              'quantityGuidelines': {
                'family_4': 2,
                'period': 90,
              },
              'commonQuantities': {
                '2_persons': 1,
                '4_persons': 2,
                '6_persons': 3,
              },
            },
            {
              'name': 'Dentifrice enfants',
              'unit': 'pièces',
              'defaultFrequency': 60,
              'popularity': 65,
              'icon': '👶',
              'quantityGuidelines': {
                'family_4': 1,
                'period': 60,
              },
            },
          ],
        },
      ],
      'products': [
        {
          'name': 'Papier toilette',
          'unit': 'rouleaux',
          'defaultFrequency': 14,
          'popularity': 95,
          'icon': '🧻',
          'quantityGuidelines': {
            'family_4': 12,
            'period': 14,
          },
          'commonQuantities': {
            '2_persons': 6,
            '4_persons': 12,
            '6_persons': 24,
          },
        },
        {
          'name': 'Shampooing',
          'unit': 'L',
          'defaultFrequency': 45,
          'popularity': 78,
          'icon': '🧴',
          'quantityGuidelines': {
            'family_4': 0.75,
            'period': 45,
          },
        },
      ],
    },
    {
      'id': 'nettoyage',
      'name': 'Nettoyage',
      'icon': '🧹',
      'products': [
        {
          'name': 'Liquide vaisselle',
          'unit': 'L',
          'defaultFrequency': 30,
          'popularity': 88,
          'icon': '🍽️',
          'quantityGuidelines': {
            'family_4': 0.75,
            'period': 30,
          },
        },
        {
          'name': 'Détergent lessive',
          'unit': 'kg',
          'defaultFrequency': 45,
          'popularity': 85,
          'icon': '👕',
          'quantityGuidelines': {
            'family_4': 3,
            'period': 45,
          },
          'commonQuantities': {
            '2_persons': 1.5,
            '4_persons': 3,
            '6_persons': 6,
          },
        },
      ],
    },
    {
      'id': 'cuisine',
      'name': 'Cuisine',
      'icon': '🍳',
      'products': [
        {
          'name': 'Huile de cuisson',
          'unit': 'L',
          'defaultFrequency': 60,
          'popularity': 82,
          'icon': '🫒',
          'quantityGuidelines': {
            'family_4': 1,
            'period': 60,
          },
        },
        {
          'name': 'Sel',
          'unit': 'kg',
          'defaultFrequency': 365,
          'popularity': 70,
          'icon': '🧂',
          'quantityGuidelines': {
            'family_4': 1,
            'period': 365,
          },
        },
      ],
    },
    {
      'id': 'durables',
      'name': 'Durables',
      'icon': '📺',
      'products': [
        {
          'name': 'Ampoules',
          'unit': 'unités',
          'defaultFrequency': 730, // 2 ans
          'popularity': 60,
          'icon': '💡',
          'quantityGuidelines': {
            'family_4': 10,
            'period': 730,
          },
        },
      ],
    },
  ];
}

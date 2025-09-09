/// Configuration des catégories durables pour NgonNest MVP
/// Définit les 4 catégories principales pour organiser les biens durables
/// Finalité MVP : "Catalogue catégories durables maisons Camerounaises pour organiser les biens durables"

/// Liste fixe des catégories durables disponibles
const List<Map<String, String>> CATEGORIES_DURABLES = [
  {
    'id': 'electromenager',
    'name': 'Électroménager',
    'description': 'Réfrigérateur, TV, ventilateur, plaque cuisson...',
    'icon': '🏠',
  },
  {
    'id': 'meubles',
    'name': 'Meubles',
    'description': 'Canapé, table, chaises, lit, armoire...',
    'icon': '🛋️',
  },
  {
    'id': 'electronique',
    'name': 'Électronique',
    'description': 'Ordinateur, radio, appareils électroniques...',
    'icon': '💻',
  },
  {
    'id': 'exterieur',
    'name': 'Extérieur / Jardin',
    'description': 'Terrasse, jardin, équipements extérieurs...',
    'icon': '🌳',
  },
];

/// Récupère une catégorie par son ID
Map<String, String>? getDurableCategoryById(String id) {
  try {
    return CATEGORIES_DURABLES.firstWhere(
      (category) => category['id'] == id,
    );
  } catch (e) {
    return null;
  }
}

/// Récupère le nom d'une catégorie par son ID
String getDurableCategoryName(String id) {
  final category = getDurableCategoryById(id);
  return category?['name'] ?? 'Autre';
}

/// Récupère l'icône d'une catégorie par son ID
String getDurableCategoryIcon(String id) {
  final category = getDurableCategoryById(id);
  return category?['icon'] ?? '📦';
}

/// Liste des IDs des catégories durables pour validation
const List<String> CATEGORIES_DURABLES_IDS = [
  'electromenager',
  'meubles',
  'electronique',
  'exterieur',
];

/// Vérifie si un ID de catégorie est valide
bool isValidDurableCategory(String categoryId) {
  return CATEGORIES_DURABLES_IDS.contains(categoryId);
}

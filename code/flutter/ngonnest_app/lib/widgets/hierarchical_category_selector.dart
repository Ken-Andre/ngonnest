import 'package:flutter/material.dart';
import '../models/product_template.dart';
import '../services/product_intelligence_service.dart';

/// Sélecteur de catégories hiérarchique avec navigation breadcrumb
/// Permet navigation intuitive dans l'arborescence des catégories
class HierarchicalCategorySelector extends StatefulWidget {
  final Function(String)? onCategorySelected;
  final Function(ProductTemplate)? onProductSelected;
  final int? familySize;
  final bool enabled;

  const HierarchicalCategorySelector({
    super.key,
    this.onCategorySelected,
    this.onProductSelected,
    this.familySize,
    this.enabled = true,
  });

  @override
  State<HierarchicalCategorySelector> createState() => _HierarchicalCategorySelectorState();
}

class _HierarchicalCategorySelectorState extends State<HierarchicalCategorySelector> {
  final ProductIntelligenceService _intelligenceService = ProductIntelligenceService();

  List<String> _breadcrumbPath = ['hygiene']; // Chemin de navigation
  List<Map<String, dynamic>> _currentSubcategories = [];
  List<ProductTemplate> _currentProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLevel();
  }

  Future<void> _loadCurrentLevel() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final currentCategory = _breadcrumbPath.last;

      // Charger les sous-catégories
      _currentSubcategories = await _intelligenceService.getCategoryHierarchy(currentCategory);

      // TODO-W2: HierarchicalCategorySelector - Complete Implementation (MEDIUM PRIORITY)
      // Description: Complete the category navigation and product selection
      // Details:
      // - Implement breadcrumb navigation with proper back navigation
      // - Complete product template integration with family size consideration
      // - Add category switching animations for better UX
      // - Add proper error handling for failed category loads
      // - Implement search within categories
      // Impact: Category selection may not be fully intuitive
      // Required features:
      //   - Breadcrumb click navigation: _navigateToBreadcrumb(index)
      //   - Smooth animations between category levels
      //   - Product template filtering by family size
      //   - Category favorites/recent selections

      // Charger les produits populaires de la catégorie actuelle
      _currentProducts = await _intelligenceService.getPopularProductsByCategory(currentCategory);

    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Init Error: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToSubcategory(String subcategoryId) {
    setState(() {
      _breadcrumbPath.add(subcategoryId);
    });
    _loadCurrentLevel();
    widget.onCategorySelected?.call(subcategoryId);
  }

  void _goToBreadcrumb(String categoryId) {
    final index = _breadcrumbPath.indexOf(categoryId);
    if (index != -1) {
      setState(() {
        _breadcrumbPath = _breadcrumbPath.sublist(0, index + 1);
      });
      _loadCurrentLevel();
      widget.onCategorySelected?.call(categoryId);
    }
  }

  String _getCategoryDisplayName(String categoryId) {
    final displayNames = {
      'hygiene': 'Hygiène',
      'nettoyage': 'Nettoyage',
      'cuisine': 'Cuisine',
      'durables': 'Durables',
      'savon': 'Savon',
      'dentifrice': 'Dentifrice',
    };
    return displayNames[categoryId] ?? categoryId;
  }

  String _getCategoryIcon(String categoryId) {
    final icons = {
      'hygiene': '🧴',
      'nettoyage': '🧹',
      'cuisine': '🍳',
      'durables': '📺',
      'savon': '🧼',
      'dentifrice': '🦷',
    };
    return icons[categoryId] ?? '📦';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        children: [
          // Breadcrumb navigation
          _buildBreadcrumb(),

          const SizedBox(height: 12),

          // Contenu principal
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Bouton d'accueil
            GestureDetector(
              onTap: () {
                setState(() => _breadcrumbPath = ['hygiene']);
                _loadCurrentLevel();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.home,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Éléments de breadcrumb
            for (int i = 0; i < _breadcrumbPath.length; i++) ...[
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              GestureDetector(
                onTap: i < _breadcrumbPath.length - 1 ? () => _goToBreadcrumb(_breadcrumbPath[i]) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == _breadcrumbPath.length - 1
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: i == _breadcrumbPath.length - 1 ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ) : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getCategoryIcon(_breadcrumbPath[i]),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryDisplayName(_breadcrumbPath[i]),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: i == _breadcrumbPath.length - 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_currentSubcategories.isEmpty && _currentProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Sous-catégories
        if (_currentSubcategories.isNotEmpty) ...[
          _buildSectionTitle('Sous-catégories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentSubcategories.map((subcategory) {
              return _buildSubcategoryCard(subcategory);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Produits populaires
        if (_currentProducts.isNotEmpty) ...[
          _buildSectionTitle('Produits populaires'),
          Column(
            children: _currentProducts.map((product) {
              return _buildProductCard(product);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory) {
    final subcategoryId = subcategory['id'] as String? ?? '';
    final subcategoryName = subcategory['name'] as String? ?? 'Catégorie';

    return GestureDetector(
      onTap: widget.enabled ? () => _navigateToSubcategory(subcategoryId) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCategoryIcon(subcategoryId),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              subcategoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductTemplate product) {
    final familySize = widget.familySize ?? 4;
    final recommendedQuantity = product.getRecommendedQuantity(familySize);

    return GestureDetector(
      onTap: widget.enabled ? () => widget.onProductSelected?.call(product) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icône du produit
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  product.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Détails du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Informations contextuelles
                  Row(
                    children: [
                      // Popularité
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product.popularity}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),

                      // Séparateur
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),

                      // Quantité recommandée
                      if (recommendedQuantity > 0)
                        Text(
                          '${recommendedQuantity.toStringAsFixed(recommendedQuantity % 1 == 0 ? 0 : 1)} ${product.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Flèche de sélection
            if (widget.onProductSelected != null)
              Icon(
                Icons.add,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune catégorie trouvée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Naviguer vers le parent
  void navigateBack() {
    if (_breadcrumbPath.length > 1) {
      setState(() {
        _breadcrumbPath.removeLast();
      });
      _loadCurrentLevel();
      widget.onCategorySelected?.call(_breadcrumbPath.last);
    }
  }

  /// Obtenir la catégorie actuelle
  String get currentCategory => _breadcrumbPath.isNotEmpty ? _breadcrumbPath.last : 'hygiene';

  /// Vérifier si on peut revenir en arrière
  bool get canGoBack => _breadcrumbPath.length > 1;
}

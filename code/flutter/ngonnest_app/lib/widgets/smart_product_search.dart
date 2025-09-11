import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/product_template.dart';
import '../services/product_intelligence_service.dart';

/// Widget de recherche intelligente avec auto-suggestions
/// Intègre ProductIntelligenceService pour recherche contextuelle
class SmartProductSearch extends StatefulWidget {
  final String category;
  final Function(ProductTemplate)? onProductSelected;
  final Function(String)? onTextChanged; // Nouveau callback pour le texte saisi
  final String? hintText;
  final int? familySize;
  final bool enabled;
  final InputDecoration? decoration;

  const SmartProductSearch({
    super.key,
    required this.category,
    this.onProductSelected,
    this.onTextChanged,
    this.hintText,
    this.familySize,
    this.enabled = true,
    this.decoration,
  });

  @override
  State<SmartProductSearch> createState() => _SmartProductSearchState();
}

class _SmartProductSearchState extends State<SmartProductSearch> {
  final TextEditingController _controller = TextEditingController();
  final ProductIntelligenceService _intelligenceService = ProductIntelligenceService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<ProductTemplate>> _getSuggestions(String query) async {
    if (query.isEmpty) {
      // Retourner les produits populaires quand pas de recherche
      try {
        final popular = await _intelligenceService.getPopularProductsByCategory(widget.category);
        print('DEBUG: Popular products for ${widget.category}: ${popular.length} items');
        return popular;
      } catch (e) {
        print('Erreur récupération populaires ${widget.category}: $e');
        return [];
      }
    }

    // Recherche dans tous les produits de la catégorie actuelle
    try {
      final products = await _intelligenceService.getProductsByCategory(widget.category);
      print('DEBUG: All products for ${widget.category}: ${products.length} items');

      final filtered = products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase())
      ).toList();

      print('DEBUG: Filtered products for query "$query": ${filtered.length} items');

      // Tri par popularité et pertinence
      filtered.sort((a, b) => b.popularity.compareTo(a.popularity));

      return filtered.take(8).toList(); // Limite à 8 résultats
    } catch (e) {
      print('Erreur recherche dans ${widget.category}: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldContent = TypeAheadField<ProductTemplate>(
      controller: _controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: !widget.enabled,
          onChanged: (text) {
            // Synchroniser le texte saisi avec le parent
            widget.onTextChanged?.call(text);
          },
          decoration: widget.decoration ??
              InputDecoration(
                hintText: widget.hintText ?? 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: widget.enabled ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
          style: TextStyle(
            color: widget.enabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 16,
          ),
        );
      },
      suggestionsCallback: _getSuggestions,
      itemBuilder: (context, product) {
        return _buildSuggestionItem(product);
      },
      onSelected: (product) {
        _controller.text = product.name;
        widget.onProductSelected?.call(product);
      },
      emptyBuilder: (context) => _buildEmptyState(),
      decorationBuilder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: child,
        );
      },
      constraints: const BoxConstraints(maxHeight: 300),
    );

    // Utiliser readOnly au lieu d'IgnorePointer pour une meilleure compatibilité
    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: fieldContent,
    );
  }

  Widget _buildSuggestionItem(ProductTemplate product) {
    final familySize = widget.familySize ?? 4;
    final recommendedQuantity = product.getRecommendedQuantity(familySize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Informations du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du produit
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Sous-catégorie et informations contextuelles
                Row(
                  children: [
                    if (product.subcategory != null) ...[
                      Text(
                        product.subcategory!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

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
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Quantité recommandée
                if (recommendedQuantity > 0)
                  Text(
                    'Recommandé: ${recommendedQuantity.toStringAsFixed(recommendedQuantity % 1 == 0 ? 0 : 1)} ${product.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Indicateur de fréquence
          if (product.defaultFrequency != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${product.defaultFrequency}j',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun produit trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Essayez une recherche différente',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Recherche en cours...',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Effacer la recherche
  void clearSearch() {
    _controller.clear();
  }

  /// Obtenir le texte de recherche actuel
  String get currentText => _controller.text;

  /// Définir le texte de recherche programmatiquement
  void setText(String text) {
    _controller.text = text;
  }
}

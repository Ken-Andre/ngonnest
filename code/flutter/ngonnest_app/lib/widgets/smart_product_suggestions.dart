import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repository/foyer_repository.dart';
import '../repository/inventory_repository.dart';
import '../services/product_suggestion_service.dart';
import '../theme/app_theme.dart'; // AppTheme is still needed for _PriorityConfig or other direct consts if any

/// Widget intelligent d'affichage des suggestions de produits
/// Intègre le ProductSuggestionService pour proposer des produits pertinents
class SmartProductSuggestions extends StatefulWidget {
  final int foyerId;
  final String? category;
  final String? room;
  final Function(ProductSuggestion) onSuggestionSelected;
  final int maxSuggestions;

  const SmartProductSuggestions({
    super.key,
    required this.foyerId,
    required this.onSuggestionSelected,
    this.category,
    this.room,
    this.maxSuggestions = 5,
  });

  @override
  State<SmartProductSuggestions> createState() =>
      _SmartProductSuggestionsState();
}

class _SmartProductSuggestionsState extends State<SmartProductSuggestions> {
  // ProductSuggestionService will be initialized in initState to handle dependencies if needed by DI later
  late ProductSuggestionService _suggestionService;
  List<ProductSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize service with repositories from context
    final foyerRepository = context.read<FoyerRepository>();
    final inventoryRepository = context.read<InventoryRepository>();
    _suggestionService = ProductSuggestionService(
      foyerRepository: foyerRepository,
      inventoryRepository: inventoryRepository,
    );
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(SmartProductSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.room != widget.room ||
        oldWidget.foyerId != widget.foyerId) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestions = await _suggestionService.getSmartSuggestions(
        foyerId: widget.foyerId,
        category: widget.category,
        room: widget.room,
        limit: widget.maxSuggestions,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des suggestions';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingWidget();
    }

    if (_error != null) {
      return _ErrorWidget(error: _error!, onRetry: _loadSuggestions);
    }

    if (_suggestions.isEmpty) {
      return const _EmptyWidget();
    }

    return _SuggestionsWidget(
      suggestions: _suggestions,
      onSuggestionSelected: widget.onSuggestionSelected,
    );
  }
}

/// Widget de chargement des suggestions
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Chargement des suggestions...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget d'erreur
class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Widget vide (aucune suggestion)
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Aucune suggestion disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget principal d'affichage des suggestions
class _SuggestionsWidget extends StatelessWidget {
  final List<ProductSuggestion> suggestions;
  final Function(ProductSuggestion) onSuggestionSelected;

  const _SuggestionsWidget({
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.primary, // Corrected
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions intelligentes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary, // Corrected
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _SuggestionCard(
                suggestion: suggestion,
                onTap: () => onSuggestionSelected(suggestion),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Carte individuelle de suggestion
class _SuggestionCard extends StatelessWidget {
  final ProductSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec priorité
                Row(
                  children: [
                    _PriorityIndicator(priority: suggestion.priority),
                    const Spacer(),
                    _ConfidenceIndicator(confidence: suggestion.confidence),
                  ],
                ),
                const SizedBox(height: 8),

                // Nom du produit
                Text(
                  suggestion.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Quantité suggérée
                Text(
                  '${suggestion.estimatedQuantity.toInt()} ${suggestion.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary, // Corrected
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // Raison
                Text(
                  suggestion.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicateur de priorité
class _PriorityIndicator extends StatelessWidget {
  final SuggestionPriority priority;

  const _PriorityIndicator({required this.priority});

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(priority, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: config.color,
        ),
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(
    SuggestionPriority priority,
    BuildContext context,
  ) {
    // Accessing theme colors for consistency, if needed, or use AppTheme static colors for fixed ones.
    // For this specific widget, the colors seem fixed based on priority, not theme mode.
    switch (priority) {
      case SuggestionPriority.high:
        return _PriorityConfig(
          'URGENT',
          AppTheme.primaryRed,
        ); // Using AppTheme static color
      case SuggestionPriority.medium:
        return _PriorityConfig(
          'UTILE',
          AppTheme.primaryOrange,
        ); // Using AppTheme static color
      case SuggestionPriority.low:
        return _PriorityConfig(
          'OPTION',
          AppTheme.primaryGreen,
        ); // Using AppTheme static color
    }
  }
}

class _PriorityConfig {
  final String label;
  final Color color;

  const _PriorityConfig(this.label, this.color);
}

/// Indicateur de confiance
class _ConfidenceIndicator extends StatelessWidget {
  final double confidence;

  const _ConfidenceIndicator({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final stars = (confidence * 3).round().clamp(1, 3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          size: 12,
          color:
              AppTheme.primaryYellow, // Using AppTheme static color for stars
        );
      }),
    );
  }
}

/// Widget de recherche de suggestions
class SmartSuggestionSearch extends StatefulWidget {
  final int foyerId;
  final String? category;
  final Function(ProductSuggestion) onSuggestionSelected;
  final String hintText;

  const SmartSuggestionSearch({
    super.key,
    required this.foyerId,
    required this.onSuggestionSelected,
    this.category,
    this.hintText = 'Rechercher un produit...',
  });

  @override
  State<SmartSuggestionSearch> createState() => _SmartSuggestionSearchState();
}

class _SmartSuggestionSearchState extends State<SmartSuggestionSearch> {
  final TextEditingController _controller = TextEditingController();
  late ProductSuggestionService _suggestionService; // To be initialized
  List<ProductSuggestion> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize service with repositories from context
    final foyerRepository = context.read<FoyerRepository>();
    final inventoryRepository = context.read<InventoryRepository>();
    _suggestionService = ProductSuggestionService(
      foyerRepository: foyerRepository,
      inventoryRepository: inventoryRepository,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      final results = await _suggestionService.searchSuggestions(
        foyerId: widget.foyerId,
        query: query,
        category: widget.category,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          // Optionally, show an error to the user or log it
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppTheme.neutralBlack, fontSize: 16),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _performSearch(''); // Clear results
                          },
                        )
                      : null),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppTheme.neutralWhite,
            labelStyle: const TextStyle(
              color: AppTheme.neutralGrey,
              fontSize: 16,
            ),
          ),
          onChanged: _performSearch,
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final suggestion = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: _PriorityIndicator(priority: suggestion.priority),
                  title: Text(suggestion.name),
                  subtitle: Text(
                    '${suggestion.estimatedQuantity.toInt()} ${suggestion.unit} - ${suggestion.reason}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _ConfidenceIndicator(
                    confidence: suggestion.confidence,
                  ),
                  onTap: () {
                    widget.onSuggestionSelected(suggestion);
                    _controller.clear();
                    if (mounted) {
                      setState(() {
                        _searchResults = [];
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

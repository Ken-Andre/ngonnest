import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/categories_durables.dart';

/// Widget Dropdown pour sélection des catégories durables NgonNest MVP
/// Affiche les 4 catégories fixes pour organiser les biens durables maisons
/// Finalité MVP : "Sélecteur catégories durables maisons Camerounaises"
class DropdownCategoriesDurables extends StatefulWidget {
  final String? selectedCategoryId;
  final Function(String)? onCategorySelected;
  final bool enabled;
  final String? hintText;

  const DropdownCategoriesDurables({
    super.key,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<DropdownCategoriesDurables> createState() =>
      _DropdownCategoriesDurablesState();
}

class _DropdownCategoriesDurablesState
    extends State<DropdownCategoriesDurables> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
  }

  @override
  void didUpdateWidget(DropdownCategoriesDurables oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      setState(() {
        _selectedCategoryId = widget.selectedCategoryId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _selectedCategoryId != null
        ? getDurableCategoryById(_selectedCategoryId!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Catégorie durable',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Dropdown button
          AbsorbPointer(
            absorbing: !widget.enabled,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: PopupMenuButton<String>(
                enabled: widget.enabled,
                onSelected: (categoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                  });
                  widget.onCategorySelected?.call(categoryId);
                },
                itemBuilder: (context) => categoriesDurables.map((category) {
                  final isSelected = category['id'] == _selectedCategoryId;
                  return PopupMenuItem<String>(
                    value: category['id'],
                    child: Row(
                      children: [
                        Text(
                          category['icon']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['name']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                category['description']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            CupertinoIcons.checkmark,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  );
                }).toList(),
                child: Row(
                  children: [
                    if (selectedCategory != null) ...[
                      Text(
                        selectedCategory['icon']!,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedCategory['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        CupertinoIcons.square_grid_2x2,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.hintText ?? 'Sélectionner une catégorie...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                    Icon(
                      CupertinoIcons.chevron_down,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Description de la catégorie sélectionnée
          if (selectedCategory != null) ...[
            const SizedBox(height: 8),
            Text(
              selectedCategory['description']!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Méthode publique pour définir la catégorie programmatiquement
  void setSelectedCategory(String categoryId) {
    if (isValidDurableCategory(categoryId)) {
      setState(() {
        _selectedCategoryId = categoryId;
      });
    }
  }

  /// Méthode publique pour obtenir la catégorie sélectionnée
  String? getSelectedCategoryId() => _selectedCategoryId;

  /// Méthode publique pour obtenir les détails de la catégorie sélectionnée
  Map<String, String>? getSelectedCategory() {
    return _selectedCategoryId != null
        ? getDurableCategoryById(_selectedCategoryId!)
        : null;
  }
}

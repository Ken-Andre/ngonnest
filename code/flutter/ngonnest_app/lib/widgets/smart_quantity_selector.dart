import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_template.dart';
import '../services/product_intelligence_service.dart';

/// Sélecteur de quantité intelligent avec recommandations familiales
/// Ajuste automatiquement les quantités selon la taille du foyer
class SmartQuantitySelector extends StatefulWidget {
  final String category;
  final ProductTemplate? selectedProduct;
  final int? familySize;
  final Function(double quantity, String unit)? onQuantityChanged;
  final double initialQuantity;
  final String initialUnit;
  final bool enabled;

  const SmartQuantitySelector({
    super.key,
    required this.category,
    this.selectedProduct,
    this.familySize = 4,
    this.onQuantityChanged,
    this.initialQuantity = 1.0,
    this.initialUnit = 'unités',
    this.enabled = true,
  });

  @override
  State<SmartQuantitySelector> createState() => _SmartQuantitySelectorState();
}

class _SmartQuantitySelectorState extends State<SmartQuantitySelector> {
  final TextEditingController _quantityController = TextEditingController();
  final ProductIntelligenceService _intelligenceService = ProductIntelligenceService();

  double _recommendedQuantity = 0;
  String _selectedUnit = 'unités';
  String? _currentCategory;
  ProductTemplate? _currentProduct;
  bool _isCalculating = false;

  final List<String> _commonUnits = [
    'pièces', 'kg', 'L', 'pack'
  ];

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    _quantityController.text = widget.initialQuantity.toString();
    _currentCategory = widget.category;
    _currentProduct = widget.selectedProduct;
    _calculateRecommendation();
  }

  @override
  void didUpdateWidget(SmartQuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.selectedProduct != widget.selectedProduct ||
        oldWidget.familySize != widget.familySize) {
      _currentCategory = widget.category;
      _currentProduct = widget.selectedProduct;
      _calculateRecommendation();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _calculateRecommendation() async {
    if (!mounted) return;

    setState(() => _isCalculating = true);

    try {
      if (_currentProduct != null) {
        // Calcul basé sur le template de produit sélectionné
        final familySize = widget.familySize ?? 4;
        _recommendedQuantity = _currentProduct!.getRecommendedQuantity(familySize);
        _selectedUnit = _currentProduct!.unit;

        // Pré-remplir avec la quantité recommandée si vide
        if (_quantityController.text.isEmpty || _quantityController.text == '0') {
          _quantityController.text = _recommendedQuantity.toString();
          widget.onQuantityChanged?.call(_recommendedQuantity, _selectedUnit);
        }
      } else {
        // Calcul générique basé sur la catégorie
        _recommendedQuantity = await _intelligenceService.calculateOptimalQuantity(
          ProductTemplate(
            id: 'generic_${widget.category}',
            name: 'Produit générique',
            category: widget.category,
            unit: _selectedUnit,
            defaultFrequency: 30,
            icon: '📦',
          ),
          widget.familySize ?? 4,
        );

        if (_quantityController.text.isEmpty || _quantityController.text == '0') {
          _quantityController.text = _recommendedQuantity.toString();
          widget.onQuantityChanged?.call(_recommendedQuantity, _selectedUnit);
        }
      }
    } catch (e) {
      print('Erreur calcul recommandation: $e');
    } finally {
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    }
  }

  void _onQuantityChanged(String value) {
    final quantity = double.tryParse(value) ?? 0.0;
    widget.onQuantityChanged?.call(quantity, _selectedUnit);
  }

  void _onUnitChanged(String unit) {
    setState(() => _selectedUnit = unit);
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    widget.onQuantityChanged?.call(quantity, unit);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text(
          'Quantité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Recommandation
        if (_recommendedQuantity > 0 && !_isCalculating)
          _buildRecommendationBanner(),

        const SizedBox(height: 12),

        // Champ de saisie et sélecteur d'unité
        Row(
          children: [
            // Champ quantité
            Expanded(
              flex: 2,
              child: _buildQuantityInput(),
            ),

            const SizedBox(width: 12),

            // Sélecteur d'unité
            Expanded(
              flex: 1,
              child: _buildUnitSelector(),
            ),
          ],
        ),

        // Indicateur famille
        if (widget.familySize != null && widget.familySize != 4)
          _buildFamilyIndicator(),
      ],
    );
  }

  Widget _buildRecommendationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recommandé pour ${widget.familySize ?? 4} personnes: ${_recommendedQuantity.toStringAsFixed(_recommendedQuantity % 1 == 0 ? 0 : 1)} $_selectedUnit',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_recommendedQuantity > 0)
            GestureDetector(
              onTap: () {
                _quantityController.text = _recommendedQuantity.toString();
                _onQuantityChanged(_recommendedQuantity.toString());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Appliquer',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityInput() {
    return TextField(
      controller: _quantityController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      enabled: widget.enabled,
      onChanged: _onQuantityChanged,
      decoration: InputDecoration(
        hintText: '0',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          items: _commonUnits.map((unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
          onChanged: widget.enabled ? (value) {
            if (value != null) _onUnitChanged(value);
          } : null,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            Icons.family_restroom,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Calculé pour ${_getFamilyDescription(widget.familySize!)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getFamilyDescription(int size) {
    if (size <= 2) return 'petit foyer';
    if (size <= 4) return 'famille moyenne';
    return 'grand foyer';
  }

  /// Obtenir la quantité actuelle
  double get currentQuantity => double.tryParse(_quantityController.text) ?? 0.0;

  /// Obtenir l'unité actuelle
  String get currentUnit => _selectedUnit;

  /// Définir la quantité programmatiquement
  void setQuantity(double quantity) {
    _quantityController.text = quantity.toString();
    _onQuantityChanged(quantity.toString());
  }

  /// Rafraîchir les calculs
  Future<void> refreshCalculations() async {
    await _calculateRecommendation();
  }
}

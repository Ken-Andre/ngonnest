import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/budget_category.dart';
import '../services/budget_service.dart';

class BudgetCategoryDialog extends StatefulWidget {
  final BudgetCategory? category; // null for create, non-null for edit
  final String? month;

  const BudgetCategoryDialog({super.key, this.category, this.month});

  @override
  State<BudgetCategoryDialog> createState() => _BudgetCategoryDialogState();
}

class _BudgetCategoryDialogState extends State<BudgetCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.category!.name;
      _limitController.text = widget.category!.limit.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final limit = double.parse(_limitController.text);
      final month = widget.month ?? BudgetService.getCurrentMonth();

      if (_isEditing) {
        // Update existing category
        final updatedCategory = widget.category!.copyWith(
          name: name,
          limit: limit,
          updatedAt: DateTime.now(),
        );
        await BudgetService.updateBudgetCategory(updatedCategory);
      } else {
        // Create new category
        final newCategory = BudgetCategory(
          name: name,
          limit: limit,
          month: month,
        );
        await BudgetService.createBudgetCategory(newCategory);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom de la catégorie',
                hintText: 'ex: Hygiène, Nettoyage...',
                prefixIcon: Icon(
                  CupertinoIcons.tag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un nom';
                }
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Budget limit field
            TextFormField(
              controller: _limitController,
              decoration: InputDecoration(
                labelText: 'Budget mensuel (€)',
                hintText: '0.00',
                prefixIcon: Icon(
                  CupertinoIcons.money_euro,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un montant';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Montant invalide';
                }
                if (amount <= 0) {
                  return 'Le montant doit être positif';
                }
                if (amount > 10000) {
                  return 'Le montant semble trop élevé';
                }
                return null;
              },
            ),

            // Info text for editing
            if (_isEditing) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les dépenses actuelles (${widget.category!.spent.toStringAsFixed(2)} €) seront conservées.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(_isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/objet.dart';
import '../repository/inventory_repository.dart';
import '../services/database_service.dart';
import '../services/smart_validator.dart';
import '../services/error_logger_service.dart';
import '../services/budget_service.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../services/navigation_service.dart';

/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: EDIT_VALIDATION - Form validation may not work properly
///       - Smart validator integration needs testing
///       - Category changes not properly validated
/// TODO: EDIT_SAVE_FUNCTIONALITY - Save operation may fail
///       - Budget alert integration after edit not tested
///       - Database update operations need validation
/// TODO: EDIT_UI_FEEDBACK - User feedback incomplete
///       - Loading states during save not properly handled
///       - Error messages may not display correctly
/// TODO: EDIT_NAVIGATION - Navigation after edit needs testing
///       - Return to inventory screen may not refresh data
///       - Edit result not properly communicated to parent
class EditProductScreen extends StatefulWidget {
  final Objet objet;

  const EditProductScreen({super.key, required this.objet});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseService _databaseService;
  late InventoryRepository _inventoryRepository;

  bool _isLoading = false;
  bool _isSaving = false;

  // Form fields
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _frequencyController;
  late TextEditingController _commentairesController;
  late String _selectedCategory;
  late String _selectedUnit;
  DateTime? _expiryDate;
  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
  }

  void _initializeControllers() {
    _productNameController = TextEditingController(text: widget.objet.nom);
    _quantityController = TextEditingController(
      text: widget.objet.quantiteRestante.toString(),
    );
    _frequencyController = TextEditingController(
      text: widget.objet.frequenceAchatJours?.toString() ?? '30',
    );
    _commentairesController = TextEditingController(
      text: widget.objet.commentaires ?? '',
    );
    _selectedCategory = widget.objet.categorie;
    _selectedUnit = widget.objet.unite;
    _expiryDate = widget.objet.dateRupturePrev;
    _purchaseDate = widget.objet.dateAchat;
  }

  void _initializeServices() {
    try {
      _databaseService = context.read<DatabaseService>();
      _inventoryRepository = InventoryRepository(_databaseService);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Init Error: $e');
      }
      ErrorLoggerService.logError(
        component: 'EditProductScreen',
        operation: 'initializeServices',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'screen': 'EditProductScreen'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _frequencyController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedObjet = widget.objet.copyWith(
        nom: _productNameController.text.trim(),
        categorie: _selectedCategory,
        quantiteRestante:
            double.tryParse(_quantityController.text) ??
            widget.objet.quantiteRestante,
        unite: _selectedUnit,
        dateRupturePrev: _expiryDate,
        dateAchat: _purchaseDate,
        frequenceAchatJours: widget.objet.type == TypeObjet.consommable
            ? int.tryParse(_frequencyController.text)
            : null,
        commentaires: widget.objet.type == TypeObjet.durable
            ? (_commentairesController.text.trim().isNotEmpty
                  ? _commentairesController.text.trim()
                  : null)
            : null,
        dateModification:
            DateTime.now(), // Ensured this is present and uncommented
      );

      await _inventoryRepository.updateObjet(
        updatedObjet,
      ); // Changed to updateObjet

      if (widget.objet.type == TypeObjet.consommable) {
        try {
          await BudgetService.checkBudgetAlertsAfterPurchase(
            widget.objet.idFoyer.toString(),
            _selectedCategory,
          );
          if (kDebugMode) {
            print('✅ BUDGET ALERTS: Checked after product update');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('⚠️ BUDGET ALERTS: Error checking alerts: $e');
          }
          ErrorLoggerService.logError(
            component: 'EditProductScreen',
            operation: 'checkBudgetAlertsAfterPurchase',
            error: e,
            stackTrace: stackTrace,
            severity: ErrorSeverity.medium,
            metadata: {
              'productId': widget.objet.id,
              'foyerId': widget.objet.idFoyer,
            },
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Produit modifié avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'EditProductScreen',
        operation: 'saveProduct', // Verified this is correct
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'objetId': widget.objet.id},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isExpiry,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiry
          ? (_expiryDate ?? DateTime.now())
          : (_purchaseDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConsumable = widget.objet.type == TypeObjet.consommable;

    return MainNavigationWrapper(
      currentIndex: 1, // Inventory index
      onTabChanged: (index) => NavigationService.navigateToTab(context, index),
      body: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: Text(
            'Modifier ${isConsumable ? "consommable" : "bien durable"}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(onPressed: _saveProduct, child: const Text('Sauver')),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('Nom du produit'),
                _buildTextField(
                  controller: _productNameController,
                  hintText: 'Nom du produit',
                  validator: (value) {
                    final result = SmartValidator.validateProductName(
                      value ?? '',
                      context: 'edit_product_screen',
                    );
                    return result.isValid ? null : result.userMessage;
                  },
                ),

                _buildSectionTitle('Catégorie'),
                _buildTextField(
                  controller: TextEditingController(text: _selectedCategory),
                  hintText: 'Catégorie',
                  readOnly: true,
                ),

                _buildSectionTitle('Quantité restante'),
                _buildTextField(
                  controller: _quantityController,
                  hintText: 'Quantité',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final result = SmartValidator.validateProductQuantity(
                      value ?? '',
                      context: isConsumable ? 'consommable' : 'durable',
                    );
                    return result.isValid ? null : result.userMessage;
                  },
                ),

                if (isConsumable) ...[
                  _buildSectionTitle('Fréquence d\'achat (jours)'),
                  _buildTextField(
                    controller: _frequencyController,
                    hintText: 'Fréquence en jours',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final result = SmartValidator.validateFrequency(
                        value ?? '',
                        context: 'consommable',
                      );
                      return result.isValid ? null : result.userMessage;
                    },
                  ),
                ],

                if (!isConsumable) ...[
                  _buildSectionTitle('Commentaires'),
                  _buildTextField(
                    controller: _commentairesController,
                    hintText: 'Commentaires ou notes',
                    maxLines: 3,
                  ),
                ],

                if (isConsumable) ...[
                  _buildSectionTitle('Date d\'expiration'),
                  _buildDateField(
                    date: _expiryDate,
                    hintText: 'Sélectionner la date d\'expiration',
                    onTap: () => _selectDate(context, isExpiry: true),
                  ),
                ] else ...[
                  _buildSectionTitle('Date d\'achat'),
                  _buildDateField(
                    date: _purchaseDate,
                    hintText: 'Sélectionner la date d\'achat',
                    onTap: () => _selectDate(context, isExpiry: false),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: readOnly
              ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
              : Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required DateTime? date,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : hintText,
                style: TextStyle(
                  color: date != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

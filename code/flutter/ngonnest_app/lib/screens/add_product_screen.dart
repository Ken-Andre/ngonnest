import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/objet.dart';
import '../repository/inventory_repository.dart';
import '../repository/foyer_repository.dart';
import '../services/database_service.dart';
import '../services/household_service.dart';
import '../services/smart_validator.dart';
import '../services/error_logger_service.dart';
import '../widgets/error_feedback_widget.dart';
import '../theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseService _databaseService;
  late InventoryRepository _inventoryRepository;
  late FoyerRepository _foyerRepository;
  
  bool _isConsumable = true;
  int? _foyerId;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form fields
  final _productNameController = TextEditingController();
  final _initialQuantityController = TextEditingController(text: '1');
  final _frequencyController = TextEditingController(text: '30');
  String _selectedCategory = 'hygiène';
  String _selectedUnit = 'pièces'; // Unité sélectionnée
  DateTime? _expiryDate;
  DateTime? _purchaseDate;

  // Validation intelligente
  ValidationResult? _productNameValidation;
  ValidationResult? _quantityValidation;
  ValidationResult? _frequencyValidation;
  bool _enableDebugMode = true; // Active les portes de debuggage en développement

  final List<Map<String, String>> _categories = [
    {'id': 'hygiène', 'name': 'Hygiène', 'icon': '🧴', 'color': '#22C55E'},
    {'id': 'nettoyage', 'name': 'Nettoyage', 'icon': '🧹', 'color': '#3B82F6'},
    {'id': 'cuisine', 'name': 'Cuisine', 'icon': '🍳', 'color': '#F59E0B'},
    {'id': 'durables', 'name': 'Durables', 'icon': '📺', 'color': '#8B5CF6'},
  ];

  @override
  void initState() {
    super.initState();
    // Éliminer la latence : Initialisation synchrone
    _initializeServices();
  }

  void _initializeServices() {
    try {
      _databaseService = context.read<DatabaseService>();
      _inventoryRepository = InventoryRepository(_databaseService);
      _foyerRepository = FoyerRepository(_databaseService);
      _loadFoyerId(); // Chargement asynchrone mais sans blocage UI
    } catch (e) {
      // Gestion d'erreur pour éviter les crashes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'initialisation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadFoyerId() async {
    setState(() => _isLoading = true);
    try {
      final foyer = await HouseholdService.getHouseholdProfile();
      if (foyer != null) {
        setState(() {
          _foyerId = foyer.id;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Aucun foyer configuré'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
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

  @override
  void dispose() {
    _productNameController.dispose();
    _initialQuantityController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  /// Validation intelligente du nom du produit avec feedback temps réel
  void _validateProductName(String value) {
    final result = SmartValidator.validateProductName(value, context: 'add_product_screen');
    setState(() {
      _productNameValidation = result;
    });
  }

  /// Validation intelligente de la quantité
  void _validateQuantity(String value) {
    final context = _isConsumable ? 'consommable' : 'durable';
    final result = SmartValidator.validateProductQuantity(value, context: context);
    setState(() {
      _quantityValidation = result;
    });
  }

  /// Validation intelligente de la fréquence
  void _validateFrequency(String value) {
    final result = SmartValidator.validateFrequency(value, context: 'consommable');
    setState(() {
      _frequencyValidation = result;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foyerId == null) return;

    setState(() => _isSaving = true);

    try {
      final objet = Objet(
        idFoyer: _foyerId!,
        nom: _productNameController.text.trim(),
        categorie: _selectedCategory,
        type: _isConsumable ? TypeObjet.consommable : TypeObjet.durable,
        dateAchat: _isConsumable ? null : _purchaseDate,
        dateRupturePrev: _isConsumable ? _expiryDate : null,
        quantiteInitiale: double.tryParse(_initialQuantityController.text) ?? 1.0,
        quantiteRestante: double.tryParse(_initialQuantityController.text) ?? 1.0,
        unite: _selectedUnit,
        tailleConditionnement: _isConsumable ? 1.0 : null,
        prixUnitaire: _isConsumable ? 5.0 : null, // Default price
        methodePrevision: _isConsumable ? MethodePrevision.frequence : null,
        frequenceAchatJours: _isConsumable ? int.tryParse(_frequencyController.text) : null,
        consommationJour: _isConsumable ? 1.0 : null,
        seuilAlerteJours: 3,
        seuilAlerteQuantite: 1.0,
      );

      // Use the repository pattern to create the product
      final productId = await _inventoryRepository.create(objet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_isConsumable ? "Consommable" : "Bien durable"} ajouté avec succès!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Use theme color
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface, // Use theme color
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            CupertinoIcons.back,
            color: Theme.of(context).colorScheme.onSurface, // Use theme color
          ),
        ),
        title: Text(
          'Ajouter un produit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface, // Use theme color
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Product type selector
              _buildSectionTitle('Type de produit'),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, // Use theme color
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)), // Use theme color
                ),
                child: Row(
                  children: [
                    _buildTypeOption(
                      title: 'Consommable',
                      subtitle: 'Savon, nourriture, etc.',
                      icon: CupertinoIcons.cube_box_fill,
                      selected: _isConsumable,
                      onTap: () => setState(() => _isConsumable = true),
                    ),
                    const SizedBox(width: 4),
                    _buildTypeOption(
                      title: 'Durable',
                      subtitle: 'Électroménager, meubles',
                      icon: CupertinoIcons.tv_fill,
                      selected: !_isConsumable,
                      onTap: () => setState(() => _isConsumable = false),
                    ),
                  ],
                ),
              ),

              // Product name with smart validation
              _buildSectionTitle('Nom du produit'),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _productNameValidation?.isValid == false
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    width: _productNameValidation?.isValid == false ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _productNameController,
                      onChanged: _validateProductName,
                      decoration: InputDecoration(
                        hintText: 'Ex: Savon artisanal, Aspirateur...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      validator: (value) {
                        final result = SmartValidator.validateProductName(value ?? '', context: 'add_product_screen');
                        return result.isValid ? null : result.userMessage;
                      },
                    ),
                    // Portes de debuggage intelligentes
                    ErrorFeedbackWidget(
                      validationResult: _productNameValidation,
                      showDebugInfo: _enableDebugMode,
                      padding: const EdgeInsets.only(top: 8),
                    ),
                  ],
                ),
              ),

              // Category selection for consumables
              if (_isConsumable) ...[
                _buildSectionTitle('Catégorie'),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['id'];
                      return _buildCategoryCard(category, isSelected);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Quantity with smart validation
              _buildSectionTitle('Quantité ${_isConsumable ? "actuelle" : "durable"}'),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _quantityValidation?.isValid == false
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    width: _quantityValidation?.isValid == false ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConsumable ? CupertinoIcons.cube_box : CupertinoIcons.tv,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _initialQuantityController,
                            keyboardType: TextInputType.number,
                            onChanged: _validateQuantity,
                            decoration: InputDecoration(
                              hintText: _isConsumable ? 'Ex: 5' : 'Ex: 1',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            ),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            validator: (value) {
                              final contextType = _isConsumable ? 'consommable' : 'durable';
                              final result = SmartValidator.validateProductQuantity(value ?? '', context: contextType);
                              return result.isValid ? null : result.userMessage;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sélecteur d'unités amélioré
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            items: _isConsumable
                                ? ['pièces', 'kg', 'L', 'mL', 'g', 'unités'].map((unit) =>
                                    DropdownMenuItem(value: unit, child: Text(unit, style: TextStyle(fontSize: 12))))
                                  .toList()
                                : ['unités'].map((unit) =>
                                    DropdownMenuItem(value: unit, child: Text(unit, style: TextStyle(fontSize: 12))))
                                  .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedUnit = value);
                              }
                            },
                            underline: const SizedBox.shrink(),
                            icon: Icon(CupertinoIcons.chevron_down, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                    // Portes de debuggage intelligentes
                    ErrorFeedbackWidget(
                      validationResult: _quantityValidation,
                      showDebugInfo: _enableDebugMode,
                      padding: const EdgeInsets.only(top: 8),
                    ),
                  ],
                ),
              ),

              // Frequency for consumables with smart validation
              if (_isConsumable) ...[
                _buildSectionTitle('Fréquence d\'achat (jours)'),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _frequencyValidation?.isValid == false
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      width: _frequencyValidation?.isValid == false ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _frequencyController,
                              keyboardType: TextInputType.number,
                              onChanged: _validateFrequency,
                              decoration: InputDecoration(
                                hintText: 'Ex: 30 jours pour du savon',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                              ),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              validator: (value) {
                                final result = SmartValidator.validateFrequency(value ?? '', context: 'consommable');
                                return result.isValid ? null : result.userMessage;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'jours',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        ],
                      ),
                      // Portes de debuggage intelligentes
                      ErrorFeedbackWidget(
                        validationResult: _frequencyValidation,
                        showDebugInfo: _enableDebugMode,
                        padding: const EdgeInsets.only(top: 8),
                      ),
                    ],
                  ),
                ),
              ],

              // Expiry date for consumables
              if (_isConsumable) ...[
                _buildSectionTitle('Date d\'expiration (optionnel)'),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, // Use theme color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)), // Use theme color
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _selectDate(context, isExpiry: true),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: _expiryDate == null ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Use theme color
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _expiryDate == null
                                ? 'Sélectionner une date'
                                : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                            style: TextStyle(
                              color: _expiryDate == null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface, // Use theme color
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_expiryDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _expiryDate = null),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: Theme.of(context).colorScheme.error, // Use theme color
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // Purchase date for durables
              if (!_isConsumable) ...[
                _buildSectionTitle('Date d\'achat (optionnel)'),
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, // Use theme color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)), // Use theme color
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _selectDate(context, isExpiry: false),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: _purchaseDate == null ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Use theme color
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _purchaseDate == null
                                ? 'Sélectionner une date'
                                : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}',
                            style: TextStyle(
                              color: _purchaseDate == null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface, // Use theme color
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (_purchaseDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _purchaseDate = null),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: Theme.of(context).colorScheme.error, // Use theme color
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Theme.of(context).colorScheme.primary, // Use theme color
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enregistrer le produit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimary, // Use theme color
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface, // Use theme color
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent, // Use theme color
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5), // Use theme color
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Use theme color
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface, // Use theme color
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.8) : Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Use theme color
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category, bool isSelected) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => setState(() => _selectedCategory = category['id']!),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface, // Use theme color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5), // Use theme color
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category['icon']!,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              category['name']!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, // Use theme color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isExpiry}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Étendu pour produits anciens
      lastDate: DateTime(2050),  // Étendu pour planifications futures
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(context).colorScheme.primary, // Use theme color
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // Use theme color
            ),
          ),
          child: child!,
        );
      },
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
}

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
import '../services/navigation_service.dart';
import '../widgets/error_feedback_widget.dart';
import '../widgets/smart_product_search.dart';
import '../widgets/hierarchical_category_selector.dart';
import '../widgets/smart_quantity_selector.dart';
import '../widgets/dropdown_categories_durables.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../services/product_intelligence_service.dart';
import '../models/product_template.dart';
import '../theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  final bool isConsumable;

  const AddProductScreen({super.key, this.isConsumable = true});

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
  final _commentairesController =
      TextEditingController(); // Commentaires pour durables
  String _selectedCategory = 'hygiene'; // Match database naming (no accents)
  String _selectedDurableCategory = ''; // Catégorie durable sélectionnée
  String _selectedUnit = 'pièces'; // Unité sélectionnée
  DateTime? _expiryDate;
  DateTime? _purchaseDate;

  // Validation intelligente
  ValidationResult? _productNameValidation;
  ValidationResult? _quantityValidation;
  ValidationResult? _frequencyValidation;
  bool _enableDebugMode =
      true; // Active les portes de debuggage en développement

  // Recherche intelligente de produits
  ProductTemplate? _selectedProductTemplate;
  late SmartProductSearch _smartSearch;

  final List<Map<String, String>> _categories = [
    {'id': 'hygiène', 'name': 'Hygiène', 'icon': '🧴', 'color': '#22C55E'},
    {'id': 'nettoyage', 'name': 'Nettoyage', 'icon': '🧹', 'color': '#3B82F6'},
    {'id': 'cuisine', 'name': 'Cuisine', 'icon': '🍳', 'color': '#F59E0B'},
    {'id': 'durables', 'name': 'Durables', 'icon': '📺', 'color': '#8B5CF6'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with the passed parameter
    _isConsumable = widget.isConsumable;
    // Éliminer la latence : Initialisation synchrone
    _initializeServices();
  }

  void _initializeServices() {
    try {
      _databaseService = context.read<DatabaseService>();
      _inventoryRepository = InventoryRepository(_databaseService);
      _foyerRepository = FoyerRepository(_databaseService);

      // Debug: Check database structure for commentaires column
      _databaseService.debugTableStructure();

      _loadFoyerId(); // Chargement asynchrone mais sans blocage UI
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Init Error: $e');
      print('StackTrace: $stackTrace');
      // Gestion d'erreur pour éviter les crashes
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

  Future<void> _loadFoyerId() async {
    setState(() => _isLoading = true);
    try {
      final foyer = await HouseholdService.getHouseholdProfile();
      if (foyer != null) {
        print('✅ FOYER FOUND: ${foyer.id} - ${foyer.nbPersonnes} personnes');
        setState(() {
          _foyerId = foyer.id;
          _isLoading = false;
        });
      } else {
        print('⚠️ NO FOYER FOUND: Creating default foyer for MVP...');
        // Créer un foyer par défaut pour le MVP
        final defaultFoyerId = await HouseholdService.createAndSaveFoyer(
          4, // nbPersonnes
          'Appartement', // typeLogement
          'fr', // langue
        );
        print('✅ DEFAULT FOYER CREATED: $defaultFoyerId');
        setState(() {
          _foyerId = defaultFoyerId;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('❌ FOYER ERROR: $e');
      print('❌ FOYER STACKTRACE: $stackTrace');
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

  /// Gestionnaire de sélection de produit depuis les suggestions
  void _onProductTemplateSelected(ProductTemplate product) {
    setState(() {
      _selectedProductTemplate = product;
      // Pré-remplir automatiquement depuis le template
      _productNameController.text = product.name;
      if (product.defaultQuantity != null) {
        _initialQuantityController.text = product.defaultQuantity.toString();
      }
      if (product.defaultFrequency != null && _isConsumable) {
        _frequencyController.text = product.defaultFrequency.toString();
      }
      // Automatiquement ajuster l'unité si spécifiée dans le template
      if (product.unit.isNotEmpty) {
        _selectedUnit = product.unit;
      }
    });

    // Validation automatique après remplissage
    _validateProductName(product.name);
    if (product.defaultQuantity != null) {
      _validateQuantity(product.defaultQuantity.toString());
    }
    if (product.defaultFrequency != null) {
      _validateFrequency(product.defaultFrequency.toString());
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _initialQuantityController.dispose();
    _frequencyController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  /// Validation intelligente du nom du produit avec feedback temps réel
  void _validateProductName(String value) {
    final result = SmartValidator.validateProductName(
      value,
      context: 'add_product_screen',
    );
    setState(() {
      _productNameValidation = result;
    });
  }

  /// Validation intelligente de la quantité
  void _validateQuantity(String value) {
    final context = _isConsumable ? 'consommable' : 'durable';
    final result = SmartValidator.validateProductQuantity(
      value,
      context: context,
    );
    setState(() {
      _quantityValidation = result;
    });
  }

  /// Validation intelligente de la fréquence
  void _validateFrequency(String value) {
    final result = SmartValidator.validateFrequency(
      value,
      context: 'consommable',
    );
    setState(() {
      _frequencyValidation = result;
    });
  }

  Future<void> _saveProduct() async {
    print('🔄 SAVE PRODUCT: Starting save process...');
    print(
      '🔄 SAVE PRODUCT: Form validation: ${_formKey.currentState?.validate()}',
    );
    print('🔄 SAVE PRODUCT: Foyer ID: $_foyerId');
    print('🔄 SAVE PRODUCT: Product name: ${_productNameController.text}');
    print('🔄 SAVE PRODUCT: Is consumable: $_isConsumable');
    print('🔄 SAVE PRODUCT: Selected category: $_selectedCategory');

    if (!_formKey.currentState!.validate()) {
      print('❌ SAVE PRODUCT: Form validation failed');
      return;
    }
    if (_foyerId == null) {
      print('❌ SAVE PRODUCT: No foyer ID available');
      return;
    }

    setState(() => _isSaving = true);
    print('🔄 SAVE PRODUCT: Set saving state to true');

    try {
      final objet = Objet(
        idFoyer: _foyerId!,
        nom: _productNameController.text.trim(),
        categorie: _isConsumable
            ? _selectedCategory
            : (_selectedDurableCategory.isNotEmpty
                  ? _selectedDurableCategory
                  : 'autre'),
        type: _isConsumable ? TypeObjet.consommable : TypeObjet.durable,
        dateAchat: _isConsumable ? null : _purchaseDate,
        dateRupturePrev: _isConsumable ? _expiryDate : null,
        quantiteInitiale:
            double.tryParse(_initialQuantityController.text) ?? 1.0,
        quantiteRestante:
            double.tryParse(_initialQuantityController.text) ?? 1.0,
        unite: _selectedUnit,
        tailleConditionnement: _isConsumable ? 1.0 : null,
        prixUnitaire: _isConsumable ? 5.0 : null, // Default price
        methodePrevision: _isConsumable ? MethodePrevision.frequence : null,
        frequenceAchatJours: _isConsumable
            ? int.tryParse(_frequencyController.text)
            : null,
        consommationJour: _isConsumable ? 1.0 : null,
        seuilAlerteJours: 3,
        seuilAlerteQuantite: 1.0,
        commentaires: _isConsumable
            ? null
            : (_commentairesController.text.trim().isNotEmpty
                  ? _commentairesController.text.trim()
                  : null),
      );

      print('🔄 SAVE PRODUCT: Created Objet: ${objet.nom} (${objet.type})');

      // Use the repository pattern to create the product
      print('🔄 SAVE PRODUCT: Calling repository.create()...');
      final productId = await _inventoryRepository.create(objet);
      print('✅ SAVE PRODUCT: Product created with ID: $productId');

      if (mounted) {
        print('🔄 SAVE PRODUCT: Showing success snackbar and popping screen');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_isConsumable ? "Consommable" : "Bien durable"} ajouté avec succès!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to the previous screen (inventory) with proper navigation handling
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          // Fallback: Navigate to inventory route if pop is not available
          Navigator.of(context, rootNavigator: true).pushReplacementNamed('/inventory');
        }
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('❌ SAVE PRODUCT: Database Error: $e');
      print('❌ SAVE PRODUCT: StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('DatabaseException')
                  ? 'Erreur base de données: ${e.toString().split(':')[1] ?? 'Database access error'}'
                  : 'Erreur lors de la sauvegarde: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        print('🔄 SAVE PRODUCT: Resetting saving state');
        setState(() => _isSaving = false);
      }
    }
  }

  // @override
  // void dispose() {
  //   _productNameController.dispose();
  //   _initialQuantityController.dispose();
  //   _frequencyController.dispose();
  //   _commentairesController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    // Handle route arguments for isConsumable parameter
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('isConsumable')) {
      _isConsumable = args['isConsumable'] as bool;
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainNavigationWrapper(
      currentIndex: 2, // Add product is index 2
      onTabChanged: (index) => NavigationService.navigateToTab(context, index),
      body: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Ajouter un produit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
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

                // Product name with smart suggestions
                _buildSectionTitle('Nom du produit'),
                SmartProductSearch(
                  category: _isConsumable ? 'hygiene' : 'durables',
                  onProductSelected: (product) {
                    setState(() {
                      _selectedCategory = product.category;
                      _productNameController.text = product.name;
                      if (product.defaultQuantity != null) {
                        _initialQuantityController.text = product
                            .defaultQuantity
                            .toString();
                      }
                    });
                  },
                  onTextChanged: (text) {
                    // Synchroniser le texte saisi manuellement avec le controller
                    _productNameController.text = text;
                  },
                  hintText: _isConsumable
                      ? 'Tapez pour voir les suggestions de consommables...'
                      : 'Tapez pour voir les suggestions de durables...',
                  enabled: !_isLoading,
                ),

                // Dropdown Categories Durables - only for durables
                if (!_isConsumable) ...[
                  DropdownCategoriesDurables(
                    selectedCategoryId: _selectedDurableCategory.isNotEmpty
                        ? _selectedDurableCategory
                        : null,
                    onCategorySelected: (categoryId) {
                      setState(() => _selectedDurableCategory = categoryId);
                    },
                    hintText: 'Choisir une catégorie pour ce bien durable',
                    enabled: !_isLoading,
                  ),
                ],

                // Commentaires field - only for durables
                if (!_isConsumable) ...[
                  _buildSectionTitle('Commentaires / Notes (optionnel)'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.text_bubble,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations complémentaires',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _commentairesController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText:
                                'Ex: Code iCloud, numéro de série, date de garantie...',
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Utile pour se souvenir des détails importants de ce bien durable',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Hierarchical Category Selector for consumables
                if (_isConsumable) ...[
                  _buildSectionTitle('Navigation par catégories'),
                  HierarchicalCategorySelector(
                    onCategorySelected: (categoryId) {
                      setState(() => _selectedCategory = categoryId);
                    },
                    onProductSelected: _onProductTemplateSelected,
                    familySize: _getHouseholdSize(),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                ],

                // Smart Quantity Selector
                if (_isConsumable) ...[
                  SmartQuantitySelector(
                    category: _selectedCategory,
                    selectedProduct: _selectedProductTemplate,
                    familySize: _getHouseholdSize(),
                    onQuantityChanged: (quantity, unit) {
                      setState(() {
                        _initialQuantityController.text = quantity.toString();
                        _selectedUnit = unit;
                      });
                    },
                    initialQuantity:
                        _selectedProductTemplate?.defaultQuantity ?? 1.0,
                    initialUnit: _selectedProductTemplate?.unit ?? 'pièces',
                    enabled: !_isLoading,
                  ),
                ] else ...[
                  // Quantity for durables (simplified)
                  _buildSectionTitle('Quantité durable'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.tv,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _initialQuantityController,
                            keyboardType: TextInputType.number,
                            onChanged: _validateQuantity,
                            decoration: InputDecoration(
                              hintText: 'Ex: 1',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              final result =
                                  SmartValidator.validateProductQuantity(
                                    value ?? '',
                                    context: 'durable',
                                  );
                              return result.isValid ? null : result.userMessage;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'unités',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.5),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
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
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                validator: (value) {
                                  final result =
                                      SmartValidator.validateFrequency(
                                        value ?? '',
                                        context: 'consommable',
                                      );
                                  return result.isValid
                                      ? null
                                      : result.userMessage;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'jours',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.surface, // Use theme color
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.5),
                      ), // Use theme color
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _selectDate(context, isExpiry: true),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            color: _expiryDate == null
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.onSurface
                                      .withOpacity(0.7), // Use theme color
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _expiryDate == null
                                  ? 'Sélectionner une date'
                                  : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                              style: TextStyle(
                                color: _expiryDate == null
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5)
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurface, // Use theme color
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_expiryDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _expiryDate = null),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: Theme.of(
                                  context,
                                ).colorScheme.error, // Use theme color
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
                      color: Theme.of(
                        context,
                      ).colorScheme.surface, // Use theme color
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.5),
                      ), // Use theme color
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _selectDate(context, isExpiry: false),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            color: _purchaseDate == null
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.onSurface
                                      .withOpacity(0.7), // Use theme color
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _purchaseDate == null
                                  ? 'Sélectionner une date'
                                  : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}',
                              style: TextStyle(
                                color: _purchaseDate == null
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5)
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurface, // Use theme color
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_purchaseDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _purchaseDate = null),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: Theme.of(
                                  context,
                                ).colorScheme.error, // Use theme color
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary, // Use theme color
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _isSaving
                        ? null
                        : () {
                            print(
                              '🔘 SAVE BUTTON: Pressed! isSaving: $_isSaving',
                            );
                            _saveProduct();
                          },
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Enregistrer le produit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary, // Use theme color
                            ),
                          ),
                  ),
                ),
              ],
            ),
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
          color: Theme.of(context).colorScheme.onSurface,
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
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent, // Use theme color
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5), // Use theme color
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(
                        0.7,
                      ), // Use theme color
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
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
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface, // Use theme color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.5), // Use theme color
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category['icon']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              category['name']!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface, // Use theme color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isExpiry,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Étendu pour produits anciens
      lastDate: DateTime(2050), // Étendu pour planifications futures
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(context).colorScheme.primary,
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
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

  /// Obtient la taille du foyer depuis le service Household
  int _getHouseholdSize() {
    // Intégration avec HouseholdService pour obtenir la taille réelle
    try {
      // Note: This needs to be awaited properly in a real implementation
      return 4; // Valeur par défaut temporaire
    } catch (e) {
      print('Erreur récupération taille foyer: $e');
      return 4; // Valeur par défaut
    }
  }
}

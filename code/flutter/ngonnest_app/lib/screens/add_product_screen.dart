import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/objet.dart';
import '../models/product_template.dart';
import '../repository/foyer_repository.dart';
import '../repository/inventory_repository.dart';
import '../services/analytics_service.dart';
import '../services/budget_service.dart';
import '../services/calendar_sync_service.dart';
// import '../theme/app_theme.dart';
// import '../config/cameroon_products.dart';
// import '../services/error_logger_service.dart';
import '../services/console_logger.dart';
import '../services/database_service.dart';
import '../services/household_service.dart';
import '../services/navigation_service.dart';
import '../services/notification_service.dart';
import '../services/price_service.dart';
import '../l10n/app_localizations.dart';
import '../services/product_suggestion_service.dart';
import '../services/settings_service.dart';
import '../services/smart_validator.dart';
import '../services/sync_service.dart';
import '../widgets/dropdown_categories_durables.dart';
import '../widgets/error_feedback_widget.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../widgets/smart_product_search.dart';
// import '../services/budget_service.dart';

import '../widgets/smart_quantity_selector.dart';

class AddProductScreen extends StatefulWidget {
  final bool isConsumable;
  final Function(bool)?
  onTypeChanged; // Callback pour notifier le changement de type

  const AddProductScreen({
    super.key,
    this.isConsumable = true,
    this.onTypeChanged,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseService _databaseService;
  late InventoryRepository _inventoryRepository;
  // ignore: unused_field
  late FoyerRepository _foyerRepository;

  bool _isConsumable = true;
  String? _foyerId;
  int _householdSize = 4; // Taille réelle du foyer
  bool _isLoading = true;
  bool _isSaving = false;

  // Form fields
  final _productNameController = TextEditingController();
  final _initialQuantityController = TextEditingController(text: '1');
  final _frequencyController = TextEditingController(text: '30');
  final _unitPriceController = TextEditingController();
  final _packagingSizeController = TextEditingController();
  final _commentairesController =
      TextEditingController(); // Commentaires pour durables

  // Reactive pricing
  final _totalPriceController = TextEditingController();
  bool _isUpdatingPrice = false;
  bool _userEditedUnitPrice = false;

  // Packaging composite
  String _packagingType = 'unit'; // default: piece/unit

  String _selectedCategory = 'hygiène'; // Première catégorie par défaut
  String _selectedDurableCategory =
      'electromenager'; // Catégorie durable sélectionnée avec valeur par défaut
  String _selectedUnit = 'pièces'; // Unité sélectionnée
  DateTime? _expiryDate;
  DateTime? _purchaseDate;

  // Manual precedence for category selection
  bool _categoryManuallySet = false;

  // Validation intelligente
  ValidationResult? _productNameValidation;
  ValidationResult? _quantityValidation;
  ValidationResult? _frequencyValidation;
  ValidationResult? _priceValidation;
  ValidationResult? _packagingValidation;
  bool _enableDebugMode =
      true; // Active les portes de debuggage en développement

  // Recherche intelligente de produits
  ProductTemplate? _selectedProductTemplate;
  late SmartProductSearch _smartSearch;

  final List<Map<String, String>> _categories = [
    {'id': 'hygiène', 'name': 'Hygiène', 'icon': '🧴', 'color': '#22C55E'},
    {'id': 'nettoyage', 'name': 'Nettoyage', 'icon': '🧹', 'color': '#3B82F6'},
    {'id': 'cuisine', 'name': 'Cuisine', 'icon': '🍳', 'color': '#F59E0B'},
    {'id': 'bureau', 'name': 'Bureau', 'icon': '📋', 'color': '#8B5CF6'},
    {
      'id': 'maintenance',
      'name': 'Maintenance',
      'icon': '🔧',
      'color': '#EF4444',
    },
    {'id': 'sécurité', 'name': 'Sécurité', 'icon': '🛡️', 'color': '#F97316'},
    {
      'id': 'événementiel',
      'name': 'Événementiel',
      'icon': '🎉',
      'color': '#EC4899',
    },
    {'id': 'autre', 'name': 'Autre', 'icon': '📦', 'color': '#6B7280'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with the passed parameter
    _isConsumable = widget.isConsumable;
    // Éliminer la latence : Initialisation synchrone
    _initializeServices();
    // Track flow started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().logFlowStarted('add_product');
    });

    // Reactive pricing listeners
    _unitPriceController.addListener(() {
      if (_isUpdatingPrice) return;
      _userEditedUnitPrice = true;
      _onUnitPriceChanged(_unitPriceController.text);
    });
    _totalPriceController.addListener(() {
      if (_isUpdatingPrice) return;
      _onTotalPriceChanged(_totalPriceController.text);
    });
    //     _getHouseholdSize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer les arguments de navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args.containsKey('isConsumable')) {
        _isConsumable = args['isConsumable'] as bool;
      }
      // Le callback onTypeChanged est déjà passé via le widget constructor
    }
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
      ConsoleLogger.error(
        'AddProductScreen',
        'initializeServices',
        e,
        stackTrace: stackTrace,
      );
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
        ConsoleLogger.success(
          'FOYER FOUND: ${foyer.id} - ${foyer.nbPersonnes} personnes',
        );
        setState(() {
          _foyerId = foyer.id;
          _householdSize = foyer.nbPersonnes; // Récupérer la vraie taille
          _isLoading = false;
        });
      } else {
        ConsoleLogger.warning(
          'NO FOYER FOUND: Creating default foyer for MVP...',
        );
        // Créer un foyer par défaut pour le MVP
        final defaultFoyerId = await HouseholdService.createAndSaveFoyer(
          4, // nbPersonnes
          'Appartement', // typeLogement
          'fr', // langue
        );
        ConsoleLogger.success('DEFAULT FOYER CREATED: $defaultFoyerId');
        setState(() {
          _foyerId = defaultFoyerId;
          _householdSize = 4; // Taille du foyer par défaut
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AddProductScreen',
        'loadFoyerId',
        e,
        stackTrace: stackTrace,
      );
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
    _unitPriceController.dispose();
    _totalPriceController.dispose();
    _packagingSizeController.dispose();
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

  //   /// Validation intelligente du prix unitaire
  void _validateUnitPrice(String value) {
    final result = SmartValidator.validateUnitPrice(value);
    setState(() {
      _priceValidation = result;
    });
  }

  //   /// Validation intelligente de la taille du conditionnement
  //   void _validatePackagingSize(String value) {
  //     final result = SmartValidator.validatePackagingSize(value);
  //     setState(() {
  //       _packagingValidation = result;
  //     });

  /// Create expiry reminders and calendar events for a product
  Future<void> _createExpiryReminders(
    Objet objet,
    String notificationId,
  ) async {
    if (objet.dateRupturePrev == null) return;

    final expiryDate = objet.dateRupturePrev!;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    ConsoleLogger.info(
      'REMINDERS: Creating reminders for ${objet.nom}, expiry: $expiryDate, daysUntilExpiry: $daysUntilExpiry',
    );

    // Create notification 1 day before expiry (or today if expiring tomorrow)
    if (daysUntilExpiry >= 0) {
      // Si expiration dans 1 jour ou moins, créer notification aujourd'hui
      // Sinon, créer notification 1 jour avant
      final reminderDate = daysUntilExpiry <= 1
          ? now.add(
              const Duration(hours: 1),
            ) // Notifier dans 1h si expire demain
          : expiryDate.subtract(const Duration(days: 1));

      if (reminderDate.isAfter(now)) {
        try {
          await NotificationService.showScheduledNotification(
            id:
                (int.tryParse(notificationId) ?? 0) +
                1000000, // Use high ID to avoid conflicts
            title: '⏰ Expiration proche',
            body: daysUntilExpiry == 0
                ? '${objet.nom} expire aujourd\'hui'
                : '${objet.nom} expire ${daysUntilExpiry == 1 ? 'demain' : 'dans $daysUntilExpiry jours'} (${DateFormat('dd/MM/yyyy').format(expiryDate)})',
            scheduledDate: reminderDate,
            addToCalendar:
                false, // Ne pas ajouter au calendrier via notification (on le fait séparément)
            context: context,
          );
          ConsoleLogger.success(
            'REMINDERS: Notification scheduled for ${objet.nom} at $reminderDate',
          );
        } catch (e, stackTrace) {
          ConsoleLogger.warning(
            'REMINDERS: Failed to schedule notification: $e',
          );
          ConsoleLogger.error(
            'REMINDERS',
            'showScheduledNotification',
            e,
            stackTrace: stackTrace,
          );
        }
      } else {
        ConsoleLogger.warning(
          'REMINDERS: Reminder date $reminderDate is in the past, skipping notification',
        );
      }
    }

    // Add calendar event as all-day event if enabled
    if (await SettingsService.getCalendarSyncEnabled()) {
      try {
        final calendarService = CalendarSyncService();
        // Créer un événement all-day en utilisant le début de la journée et la fin de la journée
        final startOfDay = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        );
        final endOfDay = startOfDay.add(
          const Duration(days: 1),
        ); // Fin de journée = début du jour suivant

        await calendarService.addEvent(
          title: 'Expiration: ${objet.nom}',
          description: 'Produit ${objet.categorie} - ${objet.nom}',
          start: startOfDay,
          end: endOfDay, // All-day event: start of day to start of next day
        );
        ConsoleLogger.success(
          'REMINDERS: Calendar event (all-day) added for ${objet.nom} on ${DateFormat('dd/MM/yyyy').format(startOfDay)}',
        );
      } catch (e, stackTrace) {
        ConsoleLogger.warning('REMINDERS: Failed to add calendar event: $e');
        ConsoleLogger.error(
          'REMINDERS',
          'addCalendarEvent',
          e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Gère la sélection d'une suggestion de produit
  void _onSuggestionSelected(ProductSuggestion suggestion) async {
    setState(() {
      _productNameController.text = suggestion.name;
      if (!_categoryManuallySet) {
        _selectedCategory = suggestion.category;
      }
      _initialQuantityController.text = suggestion.estimatedQuantity.toString();
      _selectedUnit = suggestion.unit;
      _packagingType = _inferPackagingTypeFromUnit(suggestion.unit);
    });
    await _applyEstimatedPrice(suggestion.name);
    _syncQuantityToPricing(double.tryParse(_initialQuantityController.text.replaceAll(',', '.')) ?? 0.0);
  }

  /// Gère la sélection d'un produit depuis SmartProductSearch
  void _onProductSelected(ProductTemplate product) async {
    setState(() {
      _productNameController.text = product.name;
      _selectedProductTemplate = product;
      if (product.defaultQuantity != null) {
        _initialQuantityController.text = product.defaultQuantity.toString();
      }
      // Auto-fill category only if user hasn't set manually
      if (!_categoryManuallySet && product.category != _selectedCategory) {
        _selectedCategory = product.category;
      }
      // Infer packaging type from unit
      _packagingType = _inferPackagingTypeFromUnit(product.unit);
    });

    // Apply estimated price after selection
    await _applyEstimatedPrice(product.name);

    // Update reactive pricing summary
    _syncQuantityToPricing(double.tryParse(_initialQuantityController.text.replaceAll(',', '.')) ?? 0.0);
  }

  Future<void> _saveProduct() async {
    ConsoleLogger.info('SAVE PRODUCT: Starting save process...');
    if (kDebugMode) {
      ConsoleLogger.info(
        'SAVE PRODUCT: Form validation: ${_formKey.currentState?.validate()}',
      );
    }
    ConsoleLogger.info('SAVE PRODUCT: Foyer ID: $_foyerId');
    ConsoleLogger.info(
      'SAVE PRODUCT: Product name: ${_productNameController.text}',
    );
    ConsoleLogger.info('SAVE PRODUCT: Is consumable: $_isConsumable');
    ConsoleLogger.info('SAVE PRODUCT: Selected category: $_selectedCategory');

    if (!_formKey.currentState!.validate()) {
      ConsoleLogger.warning('SAVE PRODUCT: Form validation failed');
      return;
    }
    if (_foyerId == null) {
      ConsoleLogger.warning('SAVE PRODUCT: No foyer ID available');
      return;
    }

    setState(() => _isSaving = true);
    ConsoleLogger.info('SAVE PRODUCT: Set saving state to true');

    try {
      final objet = Objet(
        idFoyer: int.tryParse(_foyerId!) ?? 0,
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
        tailleConditionnement: _isConsumable
            ? (double.tryParse(
                    _packagingSizeController.text.replaceAll(',', '.').trim(),
                  ) ??
                  1.0)
            : null,
        prixUnitaire: _isConsumable
            ? (double.tryParse(
                    _unitPriceController.text.replaceAll(',', '.').trim(),
                  ) ??
                  5.0)
            : null,
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

      ConsoleLogger.info(
        'SAVE PRODUCT: Created Objet: ${objet.nom} (${objet.type})',
      );

      // Use the repository pattern to create the product
      ConsoleLogger.info('SAVE PRODUCT: Calling repository.create()...');
      final productId = await _inventoryRepository.create(objet);
      ConsoleLogger.success(
        'SAVE PRODUCT: Product created with ID: $productId',
      );

      final productIdInt = productId;

      // Enqueue sync operation
      try {
        final syncService = Provider.of<SyncService>(context, listen: false);
        await syncService.enqueueOperation(
          operationType: 'CREATE',
          entityType: 'objet',
          entityId: productId,
          payload: objet.toMap(),
        );
        ConsoleLogger.info('SYNC: Product creation queued for sync');
      } catch (e) {
        ConsoleLogger.warning('SYNC: Failed to queue sync operation: $e');
        // Ne pas bloquer l'ajout du produit si la sync échoue
      }

      // Create expiry reminder and calendar event if product has expiry date
      if (_isConsumable && objet.dateRupturePrev != null) {
        try {
          await _createExpiryReminders(objet, productId.toString());
        } catch (e) {
          ConsoleLogger.warning(
            'REMINDERS: Failed to create expiry reminders: $e',
          );
          // Ne pas bloquer l'ajout du produit si les rappels échouent
        }
      }

      // Track core action - item added
      final analyticsService = context.read<AnalyticsService>();
      await analyticsService.logItemAction(
        'added',
        params: {
          'product_type': _isConsumable ? 'consumable' : 'durable',
          'category': _selectedCategory,
          'product_id': productId.toString(),
        },
      );
      await analyticsService.logFlowCompleted('add_product');

      // Déclencher les alertes budget après ajout d'un produit
      if (_isConsumable && _foyerId != null) {
        try {
          await BudgetService().checkBudgetAlertsAfterPurchase(
            _foyerId!.toString(),
            _selectedCategory,
          );
          ConsoleLogger.success(
            'BUDGET ALERTS: Checked after product creation',
          );
        } catch (e) {
          ConsoleLogger.warning('BUDGET ALERTS: Error checking alerts: $e');
          // Ne pas bloquer l'ajout du produit si les alertes échouent
        }
      }

      if (mounted) {
        ConsoleLogger.info(
          'SAVE PRODUCT: Showing success snackbar and popping screen',
        );
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
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushReplacementNamed('/inventory');
        }
      }
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AddProductScreen',
        'saveProduct',
        e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('DatabaseException')
                  ? 'Erreur base de données: ${e.toString().split(':')[1]
                    // ?? 'Database access error'
                    }'
                  : 'Erreur lors de la sauvegarde: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        ConsoleLogger.info('SAVE PRODUCT: Resetting saving state');
        setState(() => _isSaving = false);
      }
    }
  }

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

    // Vérifier si on peut revenir en arrière (pile de navigation)
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final l10n = AppLocalizations.of(context)!;

    return MainNavigationWrapper(
      currentIndex: 2, // Add product is index 2
      onTabChanged: (index) => NavigationService.navigateToTab(context, index),
      body: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: canPop
              ? IconButton(
                  icon: Icon(
                    CupertinoIcons.back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // Vérifier si des données ont été saisies avant de quitter
                    final hasData =
                        _productNameController.text.isNotEmpty ||
                        _initialQuantityController.text != '1' ||
                        _frequencyController.text != '30' ||
                        _unitPriceController.text.isNotEmpty ||
                        _packagingSizeController.text.isNotEmpty ||
                        _commentairesController.text.isNotEmpty ||
                        _expiryDate != null ||
                        _purchaseDate != null;

                    if (hasData && !_isSaving) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Quitter sans sauvegarder ?'),
                          content: const Text(
                            'Vous avez des données non sauvegardées. Voulez-vous vraiment quitter ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Fermer le dialog
                                Navigator.pop(
                                  context,
                                ); // Retourner à l'écran précédent
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Quitter'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                )
              : null,
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
                _buildSectionTitle(l10n.productTypeLabel),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTypeOption(
                        title: l10n.consumableLabel,
                        subtitle: 'Savon, nourriture, etc.',
                        icon: CupertinoIcons.cube_box_fill,
                        selected: _isConsumable,
                        onTap: () {
                          if (!_isConsumable) {
                            // Reset durable-specific fields when switching to consumable
                            setState(() {
                              _isConsumable = true;
                              _selectedDurableCategory = 'electromenager';
                              _commentairesController.clear();
                              _purchaseDate = null;
                            });
                            // Notifier le changement de type
                            widget.onTypeChanged?.call(true);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildTypeOption(
                        title: l10n.durableLabel,
                        subtitle: 'Électroménager, meubles',
                        icon: CupertinoIcons.tv_fill,
                        selected: !_isConsumable,
                        onTap: () {
                          if (_isConsumable) {
                            // Reset consumable-specific fields when switching to durable
                            setState(() {
                              _isConsumable = false;
                              _selectedCategory = 'hygiène';
                              _packagingSizeController.clear();
                              _unitPriceController.clear();
                              _frequencyController.text = '30';
                              _expiryDate = null;
                              _selectedUnit = 'pièces';
                            });
                            // Notifier le changement de type
                            widget.onTypeChanged?.call(false);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Product name with smart suggestions
                _buildSectionTitle(l10n.productNameLabel),
                SmartProductSearch(
                  category: _isConsumable ? _selectedCategory : '',
                  onProductSelected: _onProductSelected,
                  controller:
                      _productNameController, // Passer le controller pour synchronisation
                  onTextChanged: (text) {
                    // Le controller externe est déjà synchronisé
                    // Pas besoin de faire _productNameController.text = text;
                  },
                  hintText: _isConsumable
                      ? 'Tapez pour voir les suggestions de consommables...'
                      : 'Tapez pour voir les suggestions de durables...',
                  enabled: !_isLoading,
                  isConsumable: _isConsumable,
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
                        ).colorScheme.outline.withValues(alpha: 0.5),
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
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                                ).colorScheme.onSurface.withValues(alpha: 0.9),
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
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
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
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Simple Category Selector for consumables
                if (_isConsumable) ...[
                  _buildSectionTitle(l10n.categoryLabel),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          _categories.any(
                            (category) => category['id'] == _selectedCategory,
                          )
                          ? _selectedCategory
                          : null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id']!,
                          child: Row(
                            children: [
                              Text(
                                category['icon']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(category['name']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                  _categoryManuallySet = true; // manual prevails
                                });
                              }
                            },
                      hint: Text(l10n.chooseCategoryHint),
                    ),
                  ),
                ],

                // Smart Quantity Selector
                if (_isConsumable) ...[
                  SmartQuantitySelector(
                    category: _selectedCategory,
                    selectedProduct: _selectedProductTemplate,
                    familySize: _householdSize,
                    onQuantityChanged: (quantity, unit) {
                      setState(() {
                        _initialQuantityController.text = quantity.toString();
                        _selectedUnit = unit;
                      });
                      _syncQuantityToPricing(quantity);
                    },
                    initialQuantity:
                        _selectedProductTemplate?.defaultQuantity ?? 1.0,
                    initialUnit: _selectedProductTemplate?.unit ?? 'pièces',
                    enabled: !_isLoading,
                  ),
                ] else ...[
                  // Quantity for durables (simplified)
                  _buildSectionTitle(l10n.quantityDurableLabel),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.tv,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Packaging size and unit price for consumables
                if (_isConsumable) ...[
                  _buildSectionTitle(l10n.packagingTitle),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _packagingValidation?.isValid == false
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                        width: _packagingValidation?.isValid == false ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.cube_box,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: const Key('packagingTypeDropdown'),
                                value: _packagingType,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'unit', child: Text(l10n.packagingTypeUnit)),
                                  DropdownMenuItem(value: 'piece', child: Text(l10n.packagingTypePiece)),
                                  DropdownMenuItem(value: 'kg', child: Text(l10n.packagingTypeKg)),
                                  DropdownMenuItem(value: 'liter', child: Text(l10n.packagingTypeLiter)),
                                  DropdownMenuItem(value: 'bottle', child: Text(l10n.packagingTypeBottle)),
                                  DropdownMenuItem(value: 'bag', child: Text(l10n.packagingTypeBag)),
                                  DropdownMenuItem(value: 'box', child: Text(l10n.packagingTypeBox)),
                                  DropdownMenuItem(value: 'other', child: Text(l10n.packagingTypeOther)),
                                ],
                                onChanged: _isLoading ? null : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _packagingType = value;
                                    if (_isUnitOrPiece(value)) {
                                      _packagingSizeController.text = '1.0';
                                    } else if (_packagingSizeController.text.isEmpty) {
                                      _packagingSizeController.text = '1.0';
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (!_isUnitOrPiece(_packagingType)) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('packagingValueField'),
                            controller: _packagingSizeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: l10n.packagingValueHint,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            validator: (value) {
                              final result = SmartValidator.validatePackagingSize(value ?? '');
                              return result.isValid ? null : result.userMessage;
                            },
                          ),
                        ],
                        ErrorFeedbackWidget(
                          validationResult: _packagingValidation,
                          showDebugInfo: _enableDebugMode,
                          padding: const EdgeInsets.only(top: 8),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle(l10n.unitPriceLabel),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _priceValidation?.isValid == false
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                        width: _priceValidation?.isValid == false ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.money_euro,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const Key('unitPriceField'),
                            controller: _unitPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _validateUnitPrice,
                            decoration: const InputDecoration(
                              hintText: 'Ex: 2.99',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('€'),
                      ],
                    ),
                  ),

                  // Prix total réactif (éditable)
                  _buildSectionTitle(l10n.totalPriceLabel),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.sum,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const Key('totalPriceField'),
                            controller: _totalPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'Ex: 5.98',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('€'),
                      ],
                    ),
                  ),
                ],

                // Frequency for consumables with smart validation
                if (_isConsumable) ...[
                  _buildSectionTitle(l10n.frequencyLabel),
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
                              ).colorScheme.outline.withValues(alpha: 0.5),
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
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
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
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  _buildSectionTitle(l10n.expiryDateLabel),
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
                        ).colorScheme.outline.withValues(alpha: 0.5),
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
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ), // Use theme color
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _expiryDate == null
                                  ? l10n.selectDateHint
                                  : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                              style: TextStyle(
                                color: _expiryDate == null
                                    ? Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5)
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
                  _buildSectionTitle(l10n.purchaseDateLabel),
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
                        ).colorScheme.outline.withValues(alpha: 0.5),
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
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ), // Use theme color
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _purchaseDate == null
                                  ? l10n.selectDateHint
                                  : '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}',
                              style: TextStyle(
                                color: _purchaseDate == null
                                    ? Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5)
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

                // Mama Summary
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KeyedSubtree(key: const Key('mamaSummaryText'), child: _buildMamaSummary()),
                ),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _isSaving
                        ? null
                        : () {
                            ConsoleLogger.info('SAVE BUTTON: Pressed! isSaving: $_isSaving');
                            _saveProduct();
                          },
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
                            l10n.saveProductCta,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
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
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent, // Use theme color
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(
                      alpha: 0.5,
                    ), // Use theme color
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
                    : Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.7,
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
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
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

  // Widget _buildCategoryCard(Map<String, String> category, bool isSelected) {
  //   return CupertinoButton(
  //     padding: EdgeInsets.zero,
  //     onPressed: () => setState(() => _selectedCategory = category['id']!),
  //     child: Container(
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: isSelected
  //             ? Theme.of(context).colorScheme.primary
  //             : Theme.of(context).colorScheme.surface, // Use theme color
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(
  //           color: isSelected
  //               ? Theme.of(context).colorScheme.primary
  //               : Theme.of(
  //                   context,
  //                 ).colorScheme.outline.withValues(alpha: 0.5), // Use theme color
  //           width: isSelected ? 2 : 1,
  //         ),
  //       ),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text(category['icon']!, style: const TextStyle(fontSize: 20)),
  //           const SizedBox(height: 8),
  //           Text(
  //             category['name']!,
  //             style: TextStyle(
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //               color: isSelected
  //                   ? Theme.of(context).colorScheme.onPrimary
  //                   : Theme.of(
  //                       context,
  //                     ).colorScheme.onSurface, // Use theme color
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  bool _isUnitOrPiece(String t) => t == 'unit' || t == 'piece';

  String _inferPackagingTypeFromUnit(String unit) {
    final u = unit.toLowerCase();
    if (u.contains('kg')) return 'kg';
    if (u.contains('l')) return 'liter';
    if (u.contains('pièce') || u.contains('piece') || u.contains('unité') || u.contains('unit')) return 'unit';
    return 'unit';
  }

  Future<void> _applyEstimatedPrice(String productName) async {
    try {
      final priceService = PriceService();
      final direct = await priceService.getProductPrice(productName);
      double? estimated;
      if (direct != null) {
        estimated = PriceService.localToEuro(direct.priceLocal, direct.currencyCode);
      } else {
        estimated = await priceService.estimateObjectPrice(productName, _selectedCategory);
      }
      if (estimated != null) {
        if (_unitPriceController.text.isEmpty || !_userEditedUnitPrice) {
          _unitPriceController.text = estimated.toStringAsFixed(2);
        }
      }
    } catch (_) {}
  }

  void _onUnitPriceChanged(String v) {
    _isUpdatingPrice = true;
    final unit = double.tryParse(v.replaceAll(',', '.'));
    final qty = double.tryParse(_initialQuantityController.text.replaceAll(',', '.')) ?? 0.0;
    _totalPriceController.text = (unit != null && qty > 0) ? (unit * qty).toStringAsFixed(2) : '';
    _isUpdatingPrice = false;
  }

  void _onTotalPriceChanged(String v) {
    _isUpdatingPrice = true;
    final total = double.tryParse(v.replaceAll(',', '.'));
    final qty = double.tryParse(_initialQuantityController.text.replaceAll(',', '.')) ?? 0.0;
    final unit = (total != null && qty > 0) ? (total / qty) : null;
    _unitPriceController.text = unit?.toStringAsFixed(2) ?? '';
    _isUpdatingPrice = false;
  }

  void _syncQuantityToPricing(double quantity) {
    _isUpdatingPrice = true;
    final unit = double.tryParse(_unitPriceController.text.replaceAll(',', '.'));
    _totalPriceController.text = (unit != null && quantity > 0)
        ? (unit * quantity).toStringAsFixed(2)
        : '';
    _isUpdatingPrice = false;
  }

  Widget _buildMamaSummary() {
    final l10n = AppLocalizations.of(context)!;
    final qtyStr = _initialQuantityController.text.isEmpty ? '0' : _initialQuantityController.text;
    final unit = _selectedUnit.isEmpty ? l10n.unitGeneric : _selectedUnit;
    final name = _productNameController.text.isEmpty ? l10n.genericProduct : _productNameController.text;
    final total = double.tryParse(_totalPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final currency = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString());
    final totalStr = total > 0 ? currency.format(total) : l10n.priceUnknown;

    return Text(
      l10n.addSummaryWithPrice(qtyStr, unit, name, totalStr),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
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
    // Retourne la taille réelle du foyer chargée depuis HouseholdService
    return _householdSize;
  }
}

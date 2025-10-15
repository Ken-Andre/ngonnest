import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/objet.dart';
import '../repository/inventory_repository.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/inventory_filter_panel.dart';
import '../widgets/quick_quantity_update.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late DatabaseService _databaseService;
  late InventoryRepository _inventoryRepository;
  late TabController _tabController;
  List<Objet> _consommables = [];
  List<Objet> _durables = [];
  List<Objet> _filteredConsommables = [];
  List<Objet> _filteredDurables = [];
  bool _isLoading = true;
  String _searchQuery = '';
  InventoryFilterState _filterState = const InventoryFilterState();
  bool _isFilterExpanded = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Track tab switching
      if (_tabController.indexIsChanging) {
        final tabName = _tabController.index == 0 ? 'consommables' : 'durables';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<AnalyticsService>().logEvent(
              'inventory_tab_switched',
              parameters: {
                'tab_name': tabName,
                'from_tab': _tabController.previousIndex == 0
                    ? 'consommables'
                    : 'durables',
              },
            );
          }
        });

        // Réinitialiser les filtres quand on change d'onglet
        setState(() {
          _filterState = const InventoryFilterState();
        });
        _applySearchAndFilters();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseService = context.read<DatabaseService>();
      _inventoryRepository = InventoryRepository(_databaseService);
      _loadInventory();

      // Track screen view
      if (mounted) {
        context.read<AnalyticsService>().logEvent(
          'screen_view',
          parameters: {
            'screen_name': 'inventory',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    try {
      final foyer = await _databaseService.getFoyer();
      if (foyer != null && foyer.id != null) {
        final consommables = await _inventoryRepository.getConsommables(
          foyer.id!,
        );
        final durables = await _inventoryRepository.getDurables(foyer.id!);

        setState(() {
          _consommables = consommables;
          _durables = durables;
          _isLoading = false;
        });
        _applySearchAndFilters();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Aucun foyer configuré'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Internal Error: $e');
      print('StackTrace: $stackTrace');

      // Handle database connection errors specifically
      String errorMessage = 'Erreur lors du chargement';
      if (e.toString().contains('database_closed')) {
        errorMessage = 'Connexion perdue. Redémarrage en cours...';
        // Reset connection state to force reconnection
        await _handleDatabaseConnectionError();
        // Retry loading after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _loadInventory(); // Retry
        }
        return;
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: ${e.toString().split(':')[0]}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Handle database connection errors - DatabaseService handles reconnection automatically
  Future<void> _handleDatabaseConnectionError() async {
    print(
      '[InventoryScreen] Database connection error detected - DatabaseService will auto-recover',
    );
    print(
      '[InventoryScreen] No manual intervention needed - connection will be restored automatically',
    );
    // DatabaseService handles all reconnection logic internally
    // No need to close or reset anything manually
    // But we can force a reinitialization by closing and nullifying the database reference
    try {
      final db = await _databaseService.database;
      if (db.isOpen) {
        await db.close();
      }
    } catch (e) {
      print('[InventoryScreen] Error during database connection handling: $e');
    }
  }

  void _applySearchAndFilters() {
    // Optimize: Use where() lazily and materialize only once
    Iterable<Objet> filteredConsommables = _consommables;
    Iterable<Objet> filteredDurables = _durables;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredConsommables = filteredConsommables.where((objet) {
        return objet.nom.toLowerCase().contains(query) ||
            objet.categorie.toLowerCase().contains(query) ||
            (objet.room?.toLowerCase().contains(query) ?? false);
      });

      filteredDurables = filteredDurables.where((objet) {
        return objet.nom.toLowerCase().contains(query) ||
            objet.categorie.toLowerCase().contains(query) ||
            (objet.room?.toLowerCase().contains(query) ?? false);
      });
    }

    // Apply category filter
    if (_filterState.selectedRoom != null) {
      filteredConsommables = filteredConsommables.where((objet) {
        return objet.categorie == _filterState.selectedRoom;
      });

      filteredDurables = filteredDurables.where((objet) {
        return objet.categorie == _filterState.selectedRoom;
      });
    }

    // Apply expiry filter (only for consumables)
    if (_filterState.expiryFilter != ExpiryFilter.all) {
      final now = DateTime.now();
      filteredConsommables = filteredConsommables.where((objet) {
        if (objet.dateRupturePrev == null) return false;

        final daysUntilExpiry = objet.dateRupturePrev!.difference(now).inDays;

        switch (_filterState.expiryFilter) {
          case ExpiryFilter.expiringSoon:
            return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
          case ExpiryFilter.expired:
            return daysUntilExpiry < 0;
          case ExpiryFilter.all:
            return true;
        }
      }).toList();
    }

    // TODO-SC3: InventoryScreen - Enhanced Filtering (MEDIUM PRIORITY)
    // Description: Implement urgent items filtering mentioned in comments
    // Details:
    // - Add "Urgent" filter option to show items expiring soon or low stock
    // - Integrate with AlertGenerationService for urgent item detection
    // - Add ExpiryFilter.urgent enum value
    // - Add low stock detection based on quantite_restante vs seuil_alerte_quantite
    // - Combine expiry and stock alerts for comprehensive urgent filtering
    // Impact: Users cannot quickly filter urgent inventory items
    // Required implementation:
    //   case ExpiryFilter.urgent:
    //     return (daysUntilExpiry >= 0 && daysUntilExpiry <= 3) ||
    //            (objet.quantiteRestante <= (objet.seuilAlerteQuantite ?? 0))

    setState(() {
      _filteredConsommables = filteredConsommables.toList();
      _filteredDurables = filteredDurables.toList();
    });
  }

  void _onSearchChanged(String query) {
    // Track search analytics
    if (query.isNotEmpty && query != _searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AnalyticsService>().logEvent(
            'inventory_search',
            parameters: {
              'search_query': query,
              'current_tab': _tabController.index == 0
                  ? 'consommables'
                  : 'durables',
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
        }
      });
      // Cancel previous timer
      _debounce?.cancel();
    }

    setState(() {
      _searchQuery = query;
    });
    // Debounce search to avoid excessive filtering
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applySearchAndFilters();
    });
  }

  void _onFilterChanged(InventoryFilterState newFilterState) {
    setState(() {
      _filterState = newFilterState;
    });
    _applySearchAndFilters();
  }

  List<String> _getAvailableCategories() {
    final categories = <String>{};
    for (final objet in [..._consommables, ..._durables]) {
      if (objet.categorie.isNotEmpty) {
        categories.add(objet.categorie);
      }
    }
    return categories.toList()..sort();
  }

  Future<void> _updateQuantity(Objet objet, double newQuantity) async {
    try {
      final updatedObjet = objet.copyWith(quantiteRestante: newQuantity);
      await _inventoryRepository.updateObjet(updatedObjet);

      // Update local lists
      final index = _consommables.indexWhere((o) => o.id == objet.id);
      if (index != -1) {
        setState(() {
          _consommables[index] = updatedObjet;
        });
        _applySearchAndFilters();
      }
    } catch (e) {
      rethrow; // Let the widget handle the error display
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainNavigationWrapper(
      currentIndex: 1, // Inventory is index 1
      onTabChanged: (index) => NavigationService.navigateToTab(context, index),
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Inventaire'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading:
                false, // Remove back button since we have bottom nav
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.shopping_cart), text: 'Consommables'),
                Tab(icon: Icon(Icons.inventory), text: 'Durables'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadInventory,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Fix overflow: Rendre tout le contenu scrollable quand l'espace est insuffisant
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        InventorySearchBar(
                          onSearchChanged: _onSearchChanged,
                          hintText: 'Rechercher par nom, catégorie ou pièce...',
                          initialValue: _searchQuery,
                        ),
                        const SizedBox(height: 8),
                        InventoryFilterPanel(
                          filterState: _filterState,
                          onFilterChanged: _onFilterChanged,
                          availableRooms: _getAvailableCategories(),
                          isExpanded: _isFilterExpanded,
                          isConsumableTab:
                              _tabController.index ==
                              0, // 0 = Consommables, 1 = Durables
                          onToggleExpanded: () {
                            setState(() {
                              _isFilterExpanded = !_isFilterExpanded;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Hauteur fixe pour les tabs sur petits écrans, flexible sur grands écrans
                        SizedBox(
                          height: _isFilterExpanded
                              ? constraints.maxHeight *
                                    0.35 // Réduit quand filtres ouverts
                              : constraints.maxHeight *
                                    0.6, // Plus d'espace quand filtres fermés
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildConsommablesTab(),
                              _buildDurablesTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Track add item button click
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<AnalyticsService>().logEvent(
                    'inventory_add_button_clicked',
                    parameters: {
                      'current_tab': _tabController.index == 0
                          ? 'consommables'
                          : 'durables',
                      'timestamp': DateTime.now().millisecondsSinceEpoch
                          .toString(),
                    },
                  );
                }
              });
              _showAddItemDialog(context);
            },
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildConsommablesTab() {
    if (_consommables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun consommable ajouté',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour ajouter votre premier consommable',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_filteredConsommables.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun consommable trouvé pour "$_searchQuery"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez avec un autre terme de recherche',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredConsommables.length,
      itemBuilder: (context, index) {
        final objet = _filteredConsommables[index];
        return _buildObjetCard(objet);
      },
    );
  }

  Widget _buildDurablesTab() {
    if (_durables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun bien durable ajouté',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour ajouter votre premier bien durable',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_filteredDurables.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun bien durable trouvé pour "$_searchQuery"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez avec un autre terme de recherche',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDurables.length,
      itemBuilder: (context, index) {
        final objet = _filteredDurables[index];
        return _buildObjetCard(objet);
      },
    );
  }

  Widget _buildObjetCard(Objet objet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: objet.type == TypeObjet.consommable
              ? Colors.green.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
          child: Icon(
            objet.type == TypeObjet.consommable
                ? Icons.shopping_cart
                : Icons.inventory,
            color: objet.type == TypeObjet.consommable
                ? Colors.green
                : Colors.blue,
          ),
        ),
        title: Text(
          objet.nom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(objet.categorie),
            if (objet.room != null && objet.room!.isNotEmpty) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.room,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      objet.room!,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (objet.type == TypeObjet.consommable) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Quantité: ', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuickQuantityUpdate(
                      objet: objet,
                      onQuantityChanged: (newQuantity) =>
                          _updateQuantity(objet, newQuantity),
                    ),
                  ),
                ],
              ),
              if (objet.dateRupturePrev != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: _getExpiryColor(objet.dateRupturePrev!),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Rupture prévue: ${_formatDate(objet.dateRupturePrev)}',
                        style: TextStyle(
                          color: _getExpiryColor(objet.dateRupturePrev!),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              if (objet.dateAchat != null)
                Text('Acheté le: ${_formatDate(objet.dateAchat)}'),
              if (objet.dureeViePrevJours != null)
                Text('Durée de vie: ${objet.dureeViePrevJours} jours'),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, objet),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Track item view
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<AnalyticsService>().logEvent(
                'inventory_item_view',
                parameters: {
                  'item_name': objet.nom,
                  'item_type': objet.type == TypeObjet.consommable
                      ? 'consommable'
                      : 'durable',
                  'item_category': objet.categorie,
                  'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                },
              );
            }
          });
          _showObjetDetails(objet);
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: const Text('Consommable'),
              subtitle: const Text('Nourriture, produits d\'hygiène, etc.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/add-product',
                  arguments: const {'isConsumable': true},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: const Text('Bien durable'),
              subtitle: const Text('Électroménager, meubles, etc.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/add-product',
                  arguments: const {'isConsumable': false},
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showObjetDetails(Objet objet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              objet.type == TypeObjet.consommable
                  ? Icons.shopping_cart
                  : Icons.inventory,
              color: objet.type == TypeObjet.consommable
                  ? Colors.green
                  : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                objet.nom,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base
              _buildDetailRow('Catégorie', objet.categorie),
              _buildDetailRow(
                'Type',
                objet.type == TypeObjet.consommable ? "Consommable" : "Durable",
              ),
              if (objet.room != null && objet.room!.isNotEmpty)
                _buildDetailRow('Pièce', objet.room!),

              const Divider(height: 24),

              // Informations spécifiques selon le type
              if (objet.type == TypeObjet.consommable) ...[
                _buildDetailRow(
                  'Quantité initiale',
                  '${objet.quantiteInitiale} ${objet.unite}',
                ),
                _buildDetailRow(
                  'Quantité restante',
                  '${objet.quantiteRestante} ${objet.unite}',
                ),
                if (objet.prixUnitaire != null)
                  _buildDetailRow('Prix unitaire', '${objet.prixUnitaire} €'),
                if (objet.dateRupturePrev != null)
                  _buildDetailRow(
                    'Rupture prévue',
                    _formatDate(objet.dateRupturePrev),
                  ),
              ] else ...[
                if (objet.dateAchat != null)
                  _buildDetailRow(
                    'Date d\'achat',
                    _formatDate(objet.dateAchat),
                  ),
                if (objet.dureeViePrevJours != null)
                  _buildDetailRow(
                    'Durée de vie prévue',
                    '${objet.dureeViePrevJours} jours',
                  ),

                // Affichage des commentaires pour les durables
                if (objet.commentaires != null &&
                    objet.commentaires!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Commentaires / Notes :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      objet.commentaires!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ] else if (objet.type == TypeObjet.durable) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Aucun commentaire ajouté',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Objet objet) {
    // Track menu action
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsService>().logEvent(
          'inventory_menu_action',
          parameters: {
            'action': action,
            'item_name': objet.nom,
            'item_type': objet.type == TypeObjet.consommable
                ? 'consommable'
                : 'durable',
            'item_category': objet.categorie,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
      }
    });

    switch (action) {
      case 'edit':
        Navigator.pushNamed(context, '/edit-objet', arguments: objet);
        break;
      case 'delete':
        _showDeleteConfirmation(objet);
        break;
    }
  }

  void _showDeleteConfirmation(Objet objet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${objet.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteObjet(objet);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteObjet(Objet objet) async {
    try {
      await _inventoryRepository.delete(objet.id!);
      await _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${objet.nom} a été supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Deletion Error: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            child: Text(
              '$label :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    if (daysUntilExpiry < 0) {
      return Colors.red; // Expired
    } else if (daysUntilExpiry <= 7) {
      return Colors.orange; // Expiring soon
    } else {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.6); // Normal
    }
  }
}

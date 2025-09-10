import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/objet.dart';
import '../models/foyer.dart';
import '../repository/inventory_repository.dart';
import '../services/database_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late DatabaseService _databaseService;
  late InventoryRepository _inventoryRepository;
  List<Objet> _consommables = [];
  List<Objet> _durables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseService = context.read<DatabaseService>();
      _inventoryRepository = InventoryRepository(_databaseService);
      _loadInventory();
    });
  }

  Future<void> _loadInventory() async {
    try {
      final foyer = await _databaseService.getFoyer();
      if (foyer != null && foyer.id != null) {
        final consommables = await _inventoryRepository.getConsommables(foyer.id!);
        final durables = await _inventoryRepository.getDurables(foyer.id!);

        setState(() {
          _consommables = consommables;
          _durables = durables;
          _isLoading = false;
        });
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
    print('[InventoryScreen] Database connection error detected - DatabaseService will auto-recover');
    print('[InventoryScreen] No manual intervention needed - connection will be restored automatically');
    // DatabaseService handles all reconnection logic internally
    // No need to close or reset anything manually
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventaire'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.shopping_cart),
                text: 'Consommables',
              ),
              Tab(
                icon: Icon(Icons.inventory),
                text: 'Durables',
              ),
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
        body: TabBarView(
          children: [
            _buildConsommablesTab(),
            _buildDurablesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddItemDialog(context),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
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
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun consommable ajouté',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour ajouter votre premier consommable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consommables.length,
      itemBuilder: (context, index) {
        final objet = _consommables[index];
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
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun bien durable ajouté',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour ajouter votre premier bien durable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _durables.length,
      itemBuilder: (context, index) {
        final objet = _durables[index];
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
            color: objet.type == TypeObjet.consommable ? Colors.green : Colors.blue,
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
            if (objet.type == TypeObjet.consommable) ...[
              Text('Quantité: ${objet.quantiteRestante} ${objet.unite}'),
              if (objet.dateRupturePrev != null)
                Text('Rupture prévue: ${_formatDate(objet.dateRupturePrev)}'),
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
        onTap: () => _showObjetDetails(objet),
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
              color: objet.type == TypeObjet.consommable ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(objet.nom)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base
              _buildDetailRow('Catégorie', objet.categorie),
              _buildDetailRow('Type', objet.type == TypeObjet.consommable ? "Consommable" : "Durable"),

              const Divider(height: 24),

              // Informations spécifiques selon le type
              if (objet.type == TypeObjet.consommable) ...[
                _buildDetailRow('Quantité initiale', '${objet.quantiteInitiale} ${objet.unite}'),
                _buildDetailRow('Quantité restante', '${objet.quantiteRestante} ${objet.unite}'),
                if (objet.prixUnitaire != null)
                  _buildDetailRow('Prix unitaire', '${objet.prixUnitaire} €'),
                if (objet.dateRupturePrev != null)
                  _buildDetailRow('Rupture prévue', _formatDate(objet.dateRupturePrev)),
              ] else ...[
                if (objet.dateAchat != null)
                  _buildDetailRow('Date d\'achat', _formatDate(objet.dateAchat)),
                if (objet.dureeViePrevJours != null)
                  _buildDetailRow('Durée de vie prévue', '${objet.dureeViePrevJours} jours'),

                // Affichage des commentaires pour les durables
                if (objet.commentaires != null && objet.commentaires!.isNotEmpty) ...[
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
      _loadInventory();
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
          SizedBox(
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
            ),
          ),
        ],
      ),
    );
  }
}

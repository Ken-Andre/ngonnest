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
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                Navigator.pushNamed(context, '/add-product');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: const Text('Bien durable'),
              subtitle: const Text('Électroménager, meubles, etc.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-product');
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
        title: Text(objet.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catégorie: ${objet.categorie}'),
            Text('Type: ${objet.type == TypeObjet.consommable ? "Consommable" : "Durable"}'),
            if (objet.type == TypeObjet.consommable) ...[
              Text('Quantité initiale: ${objet.quantiteInitiale} ${objet.unite}'),
              Text('Quantité restante: ${objet.quantiteRestante} ${objet.unite}'),
              if (objet.prixUnitaire != null)
                Text('Prix unitaire: ${objet.prixUnitaire} €'),
            ] else ...[
              if (objet.dateAchat != null)
                Text('Date d\'achat: ${_formatDate(objet.dateAchat)}'),
              if (objet.dureeViePrevJours != null)
                Text('Durée de vie prévue: ${objet.dureeViePrevJours} jours'),
            ],
          ],
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
}

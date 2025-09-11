import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/main_navigation_wrapper.dart';
import '../services/navigation_service.dart';
import '../services/budget_service.dart';
import '../models/budget_category.dart';
import '../widgets/budget_category_card.dart';
import '../widgets/budget_category_dialog.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<BudgetCategory> _categories = [];
  bool _isLoading = true;
  String _currentMonth = BudgetService.getCurrentMonth();
  Map<String, dynamic> _budgetSummary = {};

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize default categories if none exist
      await BudgetService.initializeDefaultCategories(month: _currentMonth);
      
      // Load categories and summary
      final categories = await BudgetService.getBudgetCategories(month: _currentMonth);
      final summary = await BudgetService.getBudgetSummary(1, month: _currentMonth); // TODO: Get actual foyer ID
      
      setState(() {
        _categories = categories;
        _budgetSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showCategoryDialog({BudgetCategory? category}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BudgetCategoryDialog(
        category: category,
        month: _currentMonth,
      ),
    );
    
    if (result == true) {
      _loadBudgetData(); // Reload data after changes
    }
  }

  Future<void> _deleteCategory(BudgetCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && category.id != null) {
      try {
        await BudgetService.deleteBudgetCategory(category.id!);
        _loadBudgetData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catégorie supprimée')),
          );
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationWrapper(
      currentIndex: 3, // Budget is index 3
      onTabChanged: (index) => NavigationService.navigateToTab(context, index),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contrôle budgétaire',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Suivez vos achats et dépenses produits ménagers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.money_dollar,
                        size: 28,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick stats
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Ce mois',
                      value: '${(_budgetSummary['totalSpent'] ?? 0.0).toStringAsFixed(1)} €',
                      subtitle: 'Dépenses totales',
                      icon: CupertinoIcons.chart_bar,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context: context,
                      title: 'Budget',
                      value: '${(_budgetSummary['totalLimit'] ?? 0.0).toStringAsFixed(1)} €',
                      subtitle: 'Limite mensuelle',
                      icon: CupertinoIcons.money_dollar,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Categories header with add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catégories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCategoryDialog(),
                    icon: const Icon(CupertinoIcons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadBudgetData,
                            child: ListView.builder(
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return BudgetCategoryCard(
                                  category: category,
                                  onEdit: () => _showCategoryDialog(category: category),
                                  onDelete: () => _deleteCategory(category),
                                  idFoyer: 1, // TODO: Get actual foyer ID from user session
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.money_dollar_circle,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune catégorie de budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première catégorie pour commencer à suivre vos dépenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Créer une catégorie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/budget_category.dart';
import '../providers/foyer_provider.dart';
import '../services/analytics_service.dart';
import '../services/budget_service.dart';
import '../services/error_logger_service.dart';
import '../services/navigation_service.dart';
import '../widgets/budget_category_card.dart';
import '../widgets/budget_category_dialog.dart';
import '../widgets/main_navigation_wrapper.dart';
import 'savings_tips_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<BudgetCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentMonth = BudgetService.getCurrentMonth();
  Map<String, dynamic> _budgetSummary = {};
  BudgetService? _budgetService;
  FoyerProvider? _foyerProvider;
  bool _isLoadingData = false; // Flag to prevent infinite loops
  Timer? _debounceTimer; // Timer for debouncing updates

  @override
  void initState() {
    super.initState();

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsService>().logEvent(
          'screen_view',
          parameters: {
            'screen_name': 'budget',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
      }
    });

    // Register as listener to BudgetService
    _budgetService = context.read<BudgetService>();
    _budgetService?.addListener(_onBudgetChanged);

    // Register as listener to FoyerProvider to detect budget changes
    _foyerProvider = context.read<FoyerProvider>();
    _foyerProvider?.addListener(_onBudgetChanged);

    // Load data without blocking UI
    _loadBudgetData();
  }

  @override
  void dispose() {
    // Cancel debounce timer
    _debounceTimer?.cancel();

    // Unregister listeners to prevent memory leaks
    _budgetService?.removeListener(_onBudgetChanged);
    _foyerProvider?.removeListener(_onBudgetChanged);
    super.dispose();
  }

  /// Listener callback to reload data when budget changes
  /// Debounced to prevent excessive updates
  void _onBudgetChanged() {
    if (!mounted || _isLoadingData) return;

    // Cancel existing timer if any
    _debounceTimer?.cancel();

    // Set new timer with 500ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_isLoadingData) {
        _loadBudgetData();
      }
    });
  }

  Future<void> _loadBudgetData() async {
    if (!mounted || _isLoadingData) return;

    _isLoadingData = true;

    // Only show loading for refresh, not initial load
    if (_categories.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Initialize default categories if none exist (without notifying)
      await _budgetService?.initializeDefaultCategories(
        month: _currentMonth.toString(),
      );

      // Ensure spending is up-to-date with purchases for this foyer (without notifying)
      final foyerId = context.read<FoyerProvider>().foyerId;
      if (foyerId != null) {
        await _budgetService?.syncBudgetWithPurchases(
          foyerId,
          month: _currentMonth,
        );
      }

      // Load categories and summary
      final categories =
          await _budgetService?.getBudgetCategories(month: _currentMonth) ?? [];
      final summary =
          await _budgetService?.getBudgetSummary(month: _currentMonth) ?? {};

      // Load foyer total budget instead of sum of limits
      final foyerBudget =
          context.read<FoyerProvider>().foyer?.budgetMensuelEstime ?? 0.0;
      summary['totalBudget'] = foyerBudget;
      summary['remaining'] = foyerBudget - (summary['totalSpent'] ?? 0.0);

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _budgetSummary = summary;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      // Log technical error for debugging
      await ErrorLoggerService.logError(
        component: 'BudgetScreen',
        operation: '_loadBudgetData',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.budgetLoadError;
      });
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _showCategoryDialog({BudgetCategory? category}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          BudgetCategoryDialog(category: category, month: _currentMonth),
    );

    if (result == true) {
      _loadBudgetData(); // Reload data after changes
    }
  }

  Future<void> _deleteCategory(BudgetCategory category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${category.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
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
        await _budgetService?.deleteBudgetCategory(category.id!.toString());
        _loadBudgetData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Catégorie supprimée')));
        }
      } catch (e, stackTrace) {
        // Log technical error for debugging
        await ErrorLoggerService.logError(
          component: 'BudgetScreen',
          operation: '_deleteCategory',
          error: e,
          stackTrace: stackTrace,
          severity: ErrorSeverity.medium,
          metadata: {'category_name': category.name},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.budgetDeleteError),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get foyer budget - now with fallback instead of blocking
    final foyerBudget = context
        .watch<FoyerProvider>()
        .foyer
        ?.budgetMensuelEstime;
    
    // Calculate fallback budget from sum of category limits if foyer budget not set
    final effectiveBudget = (foyerBudget != null && foyerBudget > 0)
        ? foyerBudget
        : _categories.fold(0.0, (sum, cat) => sum + cat.limit);
    
    // Update summary with effective budget if we have categories but no foyer budget
    if ((foyerBudget == null || foyerBudget <= 0) && _categories.isNotEmpty) {
      _budgetSummary['totalBudget'] = effectiveBudget;
      _budgetSummary['remaining'] = effectiveBudget - (_budgetSummary['totalSpent'] ?? 0.0);
    }

    // Show error state with retry button only if there's an error and no data
    if (_errorMessage != null && _categories.isEmpty) {

      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadBudgetData,
                  icon: const Icon(CupertinoIcons.refresh),
                  label: Text(l10n.budgetRetry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
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
                          const SizedBox(height: 4),
                          Text(
                            'Suivez vos achats et dépenses produits ménagers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.9),
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
                        ).colorScheme.onPrimary.withValues(alpha: 0.2),
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
                      value:
                          '${(_budgetSummary['totalSpent'] ?? 0.0).toStringAsFixed(1)} €',
                      subtitle: 'Dépenses totales',
                      icon: CupertinoIcons.chart_bar,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context: context,
                      title: 'Budget total',
                      value:
                          '${(_budgetSummary['totalBudget'] ?? 0.0).toStringAsFixed(1)} €',

                      subtitle: 'Limite mensuelle',
                      icon: CupertinoIcons.creditcard,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      context: context,
                      title: 'Reste',
                      value:
                          '${(_budgetSummary['remaining'] ?? 0.0).toStringAsFixed(1)} €',
                      subtitle: 'Disponible',

                      icon: CupertinoIcons.money_dollar,
                      color: (_budgetSummary['remaining'] ?? 0.0) >= 0
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Categories section header with actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catégories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      // Conseils button
                      ElevatedButton.icon(
                        onPressed: () {
                          // Track savings tips button click
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              context.read<AnalyticsService>().logEvent(
                                'budget_savings_tips_clicked',
                                parameters: {
                                  'timestamp': DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                },
                              );
                            }
                          });

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavingsTipsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.lightbulb, size: 16),
                        label: const Text(
                          'Conseils',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add category button
                      ElevatedButton.icon(
                        onPressed: () {
                          // Track add category button click
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              context.read<AnalyticsService>().logEvent(
                                'budget_add_category_clicked',
                                parameters: {
                                  'timestamp': DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                },
                              );
                            }
                          });

                          _showCategoryDialog();
                        },
                        icon: const Icon(CupertinoIcons.add, size: 16),
                        label: const Text(
                          'Ajouter',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
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
                            final foyerId = context
                                .watch<FoyerProvider>()
                                .foyerId;
                            if (foyerId == null) {
                              return const SizedBox.shrink();
                            }
                            return BudgetCategoryCard(
                              category: category,
                              onEdit: () =>
                                  _showCategoryDialog(category: category),
                              onDelete: () => _deleteCategory(category),

                              idFoyer: int.tryParse(foyerId ?? '') ?? 0,
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune catégorie de budget',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première catégorie pour commencer à suivre vos dépenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

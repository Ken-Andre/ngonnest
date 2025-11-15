import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/foyer_provider.dart';
import '../services/budget_service.dart';
import '../services/navigation_service.dart';
import '../widgets/main_navigation_wrapper.dart';

/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: SAVINGS_TIPS_DATA - Savings tips generation may not work
///       - BudgetService.generateSavingsTips() may return empty or invalid data
///       - Spending history calculation needs validation
///       - Tips personalization logic not tested
/// TODO: SAVINGS_TIPS_UI - UI components may not display correctly
///       - Empty state handling incomplete
///       - Chart rendering may fail with insufficient data
///       - Tip cards may not show proper urgency indicators
/// TODO: SAVINGS_TIPS_INTEGRATION - Service integration incomplete
///       - BudgetService integration not fully tested
///       - FoyerProvider dependency may cause loading issues
///       - Data refresh functionality may not work
/// TODO: SAVINGS_TIPS_PERFORMANCE - Performance issues with data processing
///       - Monthly breakdown calculation may be slow
///       - Chart rendering may cause UI freezing
///       - Large datasets not properly handled
class SavingsTipsScreen extends StatefulWidget {
  const SavingsTipsScreen({super.key});

  @override
  State<SavingsTipsScreen> createState() => _SavingsTipsScreenState();
}

class _SavingsTipsScreenState extends State<SavingsTipsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _savingsTips = [];
  Map<String, dynamic> _spendingHistory = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final foyerId = context.read<FoyerProvider>().foyerId;
      if (foyerId != null) {
        final tips = await BudgetService.generateSavingsTips(foyerId);
        final history = await BudgetService.getSpendingHistory(foyerId);

        if (!mounted) return;
        setState(() {
          _savingsTips = tips;
          _spendingHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationWrapper(
      currentIndex: 3, // Budget tab
      onTabChanged: (index) => NavigationService.navigateToTab(context, index),
      body: Scaffold(
        appBar: AppBar(
          title: const Text('Conseils & Historique'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: const [
              Tab(icon: Icon(CupertinoIcons.lightbulb), text: 'Conseils'),
              Tab(icon: Icon(CupertinoIcons.chart_bar), text: 'Historique'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [_buildSavingsTipsTab(), _buildSpendingHistoryTab()],
              ),
      ),
    );
  }

  Widget _buildSavingsTipsTab() {
    if (_savingsTips.isEmpty) {
      return _buildEmptyTipsState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savingsTips.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildTipsHeader();
          }

          final tip = _savingsTips[index - 1];
          return _buildTipCard(tip);
        },
      ),
    );
  }

  Widget _buildTipsHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
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
              CupertinoIcons.lightbulb_fill,
              size: 28,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conseils personnalisés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Basés sur vos habitudes de consommation',
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
        ],
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    final urgency = tip['urgency'] as String;
    final priority = tip['priority'] as int;

    Color urgencyColor;
    IconData urgencyIcon;

    switch (urgency) {
      case 'high':
        urgencyColor = Theme.of(context).colorScheme.error;
        urgencyIcon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      case 'medium':
        urgencyColor = Colors.orange;
        urgencyIcon = CupertinoIcons.info_circle_fill;
        break;
      default:
        urgencyColor = Theme.of(context).colorScheme.primary;
        urgencyIcon = CupertinoIcons.lightbulb_fill;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(urgencyIcon, size: 16, color: urgencyColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tip['potentialSaving'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip['description'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tip['category'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < priority
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTipsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.lightbulb,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun conseil disponible',
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
            'Ajoutez des achats pour recevoir des conseils personnalisés',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingHistoryTab() {
    final history = _spendingHistory['history'] as List<dynamic>? ?? [];
    final trends = _spendingHistory['trends'] as Map<String, dynamic>? ?? {};
    final summary = _spendingHistory['summary'] as Map<String, dynamic>? ?? {};

    if (history.isEmpty) {
      return _buildEmptyHistoryState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistoryHeader(trends, summary),
          const SizedBox(height: 16),
          _buildHistoryChart(history),
          const SizedBox(height: 16),
          _buildMonthlyBreakdown(history),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(
    Map<String, dynamic> trends,
    Map<String, dynamic> summary,
  ) {
    final direction = trends['direction'] as String? ?? 'stable';
    final percentage = trends['percentage'] as double? ?? 0.0;
    final avgMonthly = summary['averageMonthly'] as double? ?? 0.0;

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (direction) {
      case 'increasing':
        trendIcon = CupertinoIcons.arrow_up_right;
        trendColor = Theme.of(context).colorScheme.error;
        trendText = '+${percentage.toStringAsFixed(1)}%';
        break;
      case 'decreasing':
        trendIcon = CupertinoIcons.arrow_down_right;
        trendColor = Colors.green;
        trendText = '-${percentage.toStringAsFixed(1)}%';
        break;
      default:
        trendIcon = CupertinoIcons.minus;
        trendColor = Theme.of(context).colorScheme.primary;
        trendText = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moyenne mensuelle',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${avgMonthly.toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChart(List<dynamic> history) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution des dépenses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildSimpleChart(history)),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<dynamic> history) {
    if (history.isEmpty) return const SizedBox();

    final maxSpent = history.fold<double>(0.0, (max, month) {
      final spent = (month['totalSpent'] as double?) ?? 0.0;
      return spent > max ? spent : max;
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: history.map<Widget>((month) {
        final spent = (month['totalSpent'] as double?) ?? 0.0;
        final height = maxSpent > 0 ? (spent / maxSpent * 120) : 0.0;
        final monthName = (month['monthName'] as String).substring(0, 3);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyBreakdown(List<dynamic> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail mensuel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...history
            .take(3)
            .map<Widget>((month) => _buildMonthCard(month))
            .toList(),
      ],
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> month) {
    final monthName = month['monthName'] as String;
    final totalSpent = (month['totalSpent'] as double?) ?? 0.0;
    final totalItems = (month['totalItems'] as int?) ?? 0;
    final categories = month['categories'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${totalSpent.toStringAsFixed(1)} €',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalItems achats',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: categories.map<Widget>((category) {
                final name = category['categorie'] as String;
                final spent = (category['total_spent'] as double?) ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$name: ${spent.toStringAsFixed(1)}€',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun historique disponible',
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
            'Vos dépenses apparaîtront ici après quelques achats',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

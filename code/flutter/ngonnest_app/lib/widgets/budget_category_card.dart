import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_category.dart';
import '../providers/foyer_provider.dart';
import 'budget_expense_history.dart';

class BudgetCategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int idFoyer; // Add foyer ID for expense history

  const BudgetCategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
    required this.idFoyer,
  });

  void _showExpenseHistory(BuildContext context) {
    final foyerId = idFoyer ?? int.tryParse(context.read<FoyerProvider>().foyerId ?? '');
    if (foyerId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              BudgetExpenseHistory(category: category, idFoyer: foyerId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = category.spendingPercentage;
    final isOverBudget = category.isOverBudget;
    final isNearLimit = category.isNearLimit;

    // Determine color based on spending status
    Color progressColor;
    Color borderColor;

    if (isOverBudget) {
      progressColor = Theme.of(context).colorScheme.error;
      borderColor = Theme.of(context).colorScheme.error.withOpacity(0.3);
    } else if (isNearLimit) {
      progressColor = const Color(0xFFF59E0B); // Orange
      borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
    } else {
      progressColor = const Color(0xFF22C55E); // Green
      borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _showExpenseHistory(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category name and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              CupertinoIcons.pencil,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Spending amounts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${category.spent.toStringAsFixed(1)} € / ${category.limit.toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverBudget
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOverBudget
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                // Alert banner for over budget
                if (isOverBudget) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Budget dépassé de ${(category.spent - category.limit).toStringAsFixed(1)} €',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Remaining budget info
                if (!isOverBudget && category.remainingBudget > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reste: ${category.remainingBudget.toStringAsFixed(1)} €',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

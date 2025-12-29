import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:totals/services/budget_service.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/utils/category_icons.dart';
import 'package:totals/utils/category_style.dart';
import 'package:totals/widgets/budget/budget_progress_bar.dart';

class BudgetCard extends StatelessWidget {
  final BudgetStatus status;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.status,
    this.onTap,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    return formatter.format(amount);
  }

  Color _getStatusColor() {
    if (status.isExceeded) {
      return Colors.red;
    } else if (status.isApproachingLimit) {
      return Colors.orange;
    } else if (status.percentageUsed < 70) {
      return Colors.green;
    } else {
      return Colors.yellow;
    }
  }

  String _getStatusText() {
    if (status.isExceeded) {
      return 'Exceeded';
    } else if (status.isApproachingLimit) {
      return 'Warning';
    } else {
      return 'On Track';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    final isCategoryBudget = status.budget.type == 'category' && status.budget.categoryId != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isCategoryBudget)
                          Consumer<TransactionProvider>(
                            builder: (context, transactionProvider, _) {
                              try {
                                final category = transactionProvider.categories.firstWhere(
                                  (c) => c.id == status.budget.categoryId,
                                );
                                final categoryColor = categoryTypeColor(category, context);
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    iconForCategoryKey(category.iconKey),
                                    color: categoryColor,
                                    size: 20,
                                  ),
                                );
                              } catch (e) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        Expanded(
                          child: Text(
                            status.budget.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(status.spent),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(status.budget.amount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BudgetProgressBar(status: status),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${status.percentageUsed.toStringAsFixed(1)}% used',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    status.remaining >= 0
                        ? '${_formatCurrency(status.remaining)} remaining'
                        : '${_formatCurrency(status.remaining.abs())} over',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.remaining >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

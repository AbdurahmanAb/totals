import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/providers/budget_provider.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/widgets/budget/budget_card.dart';
import 'package:totals/models/budget.dart';

class CategoryBudgetList extends StatelessWidget {
  final Function(Budget)? onBudgetTap;
  
  const CategoryBudgetList({super.key, this.onBudgetTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        if (budgetProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return FutureBuilder(
          future: budgetProvider.getCategoryBudgets(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final categoryBudgets = snapshot.data!;

            if (categoryBudgets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No category budgets yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a budget for a specific category',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryBudgets.length,
              itemBuilder: (context, index) {
                final status = categoryBudgets[index];
                return BudgetCard(
                  status: status,
                  onTap: () {
                    if (onBudgetTap != null) {
                      onBudgetTap!(status.budget);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

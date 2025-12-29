import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/providers/budget_provider.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/widgets/budget/budget_card.dart';
import 'package:totals/widgets/budget/budget_alert_banner.dart';
import 'package:totals/widgets/budget/budget_period_selector.dart';
import 'package:totals/widgets/budget/category_budget_list.dart';
import 'package:totals/widgets/budget/budget_form_sheet.dart';
import 'package:totals/services/budget_service.dart';
import 'package:totals/models/budget.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  String _selectedPeriod = 'monthly';
  String _selectedView = 'overview'; // 'overview' or 'categories'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      budgetProvider.setTransactionProvider(transactionProvider);
      budgetProvider.loadBudgets();
    });
  }

  void _showBudgetForm({String? type, int? categoryId, Budget? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetFormSheet(
        budget: budget,
        initialType: type,
        initialCategoryId: categoryId,
      ),
    ).then((_) {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      provider.loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showBudgetForm(),
                    tooltip: 'Create Budget',
                  ),
                ],
              ),
            ),
            // View Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildViewButton('overview', 'Overview'),
                  ),
                  Expanded(
                    child: _buildViewButton('categories', 'Categories'),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _selectedView == 'overview'
                  ? _buildOverviewView()
                  : _buildCategoriesView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewButton(String view, String label) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewView() {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        if (budgetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BudgetPeriodSelector(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Overall Budget Status
              FutureBuilder<List<BudgetStatus>>(
                future: budgetProvider.getBudgetsByType(_selectedPeriod),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final budgets = snapshot.data!;

                  if (budgets.isEmpty) {
                    return _buildEmptyState(
                      'No $_selectedPeriod budgets',
                      'Create a budget to track your spending',
                      () => _showBudgetForm(type: _selectedPeriod),
                    );
                  }

                  return Column(
                    children: [
                      // Alert banners
                      ...budgets
                          .where((status) =>
                              status.isExceeded || status.isApproachingLimit)
                          .map((status) => BudgetAlertBanner(status: status)),
                      // Budget cards
                      ...budgets.map((status) => BudgetCard(
                            status: status,
                            onTap: () {
                              _showBudgetForm(budget: status.budget);
                            },
                          )),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView() {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Budgets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showBudgetForm(type: 'category'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category Budget'),
                    ),
                  ],
                ),
              ),
              CategoryBudgetList(
                onBudgetTap: (budget) => _showBudgetForm(budget: budget),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, VoidCallback onAdd) {
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
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }
}

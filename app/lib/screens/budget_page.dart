import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/providers/budget_provider.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/widgets/budget/budget_card.dart';
import 'package:totals/widgets/budget/budget_alert_banner.dart';
import 'package:totals/widgets/budget/budget_period_selector.dart';
import 'package:totals/widgets/budget/category_budget_list.dart';
import 'package:totals/widgets/budget/budget_form_sheet.dart';
import 'package:totals/widgets/budget/category_budget_form_sheet.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          'Budgeting',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: null,
      ),
      body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Premium View Selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModernViewButton('overview', 'Main Budgets', Icons.donut_large_rounded),
                      ),
                      Expanded(
                        child: _buildModernViewButton('categories', 'Categories', Icons.category_rounded),
                      ),
                    ],
                  ),
                ),
                // Period Selector (only show in overview view)
                if (_selectedView == 'overview')
                  BudgetPeriodSelector(
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: (period) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                  ),
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: _selectedView == 'overview'
                        ? _buildOverviewView()
                        : _buildCategoriesView(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildModernViewButton(String view, String label, IconData icon) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewView() {
    return Consumer<BudgetProvider>(
      key: const ValueKey('overview'),
      builder: (context, budgetProvider, child) {
        if (budgetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Overall Budget Status
              FutureBuilder<List<BudgetStatus>>(
                future: budgetProvider.getBudgetsByType(_selectedPeriod),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final budgets = snapshot.data!;

                  if (budgets.isEmpty) {
                    return _buildModernEmptyState(
                      'No ${_selectedPeriod[0].toUpperCase()}${_selectedPeriod.substring(1)} Budgets',
                      'Plan your financial future by setting a budget goal.',
                      () => _showBudgetForm(type: _selectedPeriod),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 40, top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
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
      key: const ValueKey('categories'),
      builder: (context, budgetProvider, child) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Targets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Detailed spending goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.add_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => _showCategoryBudgetForm(),
                      ),
                    ),
                  ],
                ),
              ),
              CategoryBudgetList(
                onBudgetTap: (budget) => _showCategoryBudgetForm(budget: budget),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryBudgetForm({Budget? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryBudgetFormSheet(
        budget: budget,
      ),
    ).then((_) {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      provider.loadBudgets();
    });
  }

  Widget _buildModernEmptyState(String title, String subtitle, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

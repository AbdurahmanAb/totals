import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/models/budget.dart';
import 'package:totals/providers/budget_provider.dart';
import 'package:totals/providers/transaction_provider.dart';

class CategoryBudgetFormSheet extends StatefulWidget {
  final Budget? budget;

  const CategoryBudgetFormSheet({
    super.key,
    this.budget,
  });

  @override
  State<CategoryBudgetFormSheet> createState() => _CategoryBudgetFormSheetState();
}

class _CategoryBudgetFormSheetState extends State<CategoryBudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _alertThresholdController = TextEditingController();

  int? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toStringAsFixed(2);
      _alertThresholdController.text = widget.budget!.alertThreshold.toStringAsFixed(1);
      _selectedCategoryId = widget.budget!.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  DateTime _getPeriodStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final alertThreshold = double.parse(_alertThresholdController.text);

      // Get category name for budget name
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final category = transactionProvider.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => throw Exception('Category not found'),
      );

      final budget = Budget(
        id: widget.budget?.id,
        name: '${category.name} Budget', // Auto-generate name from category
        type: 'category', // Always 'category' type
        amount: amount,
        categoryId: _selectedCategoryId,
        startDate: widget.budget?.startDate ?? _getPeriodStart(),
        rollover: false, // Default to false for category budgets
        alertThreshold: alertThreshold,
        isActive: widget.budget?.isActive ?? true,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
      );

      final provider = Provider.of<BudgetProvider>(context, listen: false);
      if (widget.budget == null) {
        await provider.createBudget(budget);
      } else {
        await provider.updateBudget(budget);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving budget: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (widget.budget?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete this category budget? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      await provider.deleteBudget(widget.budget!.id!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<TransactionProvider>(context, listen: false)
        .categories
        .where((c) => c.flow == 'expense')
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.budget == null ? 'Create Category Budget' : 'Edit Category Budget',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Select a category'),
                    ),
                    ...categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: widget.budget == null
                      ? (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        }
                      : null, // Disable category selection when editing
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    hintText: '0.00',
                    prefixText: 'ETB ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _alertThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Threshold (%)',
                    hintText: '80',
                    helperText: 'Get notified when budget reaches this percentage',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an alert threshold';
                    }
                    final threshold = double.tryParse(value);
                    if (threshold == null || threshold < 0 || threshold > 100) {
                      return 'Please enter a value between 0 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (widget.budget != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteBudget,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Budget'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBudget,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.budget == null ? 'Create' : 'Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:totals/models/category.dart';
import 'package:totals/repositories/category_repository.dart';
import 'package:totals/repositories/transaction_repository.dart';
import 'package:totals/utils/text_utils.dart';

class CategoryExpense {
  final int categoryId;
  final String name;
  final double amount;
  final String colorHex;

  CategoryExpense({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'amount': amount,
        'colorHex': colorHex,
      };
}

class WidgetDataProvider {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  static const Map<String, String> _categoryColors = {
    'groceries': '#4CAF50',
    'transport': '#2196F3',
    'eating_outside': '#FF9800',
    'utilities': '#9C27B0',
    'health': '#F44336',
    'rent': '#607D8B',
    'airtime': '#00BCD4',
    'clothing': '#E91E63',
    'gifts_given': '#8BC34A',
    'beauty': '#FF5722',
    'loan': '#795548',
    'uncategorized': '#9E9E9E',
  };

  WidgetDataProvider({
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  })
      : _transactionRepository =
            transactionRepository ?? TransactionRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository();

  Future<List<CategoryExpense>> getTodayCategoryBreakdown() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final transactions = await _transactionRepository.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
      type: 'DEBIT',
    );

    final categories = await _categoryRepository.getCategories();
    final categoryMap = {for (final c in categories) c.id: c};

    final Map<int, double> categoryTotals = {};
    for (final tx in transactions) {
      final catId = tx.categoryId ?? 0;
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + tx.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(3).map((entry) {
      final category = categoryMap[entry.key];
      final builtInKey = category?.builtInKey ?? 'uncategorized';
      return CategoryExpense(
        categoryId: entry.key,
        name: category?.name ?? 'Uncategorized',
        amount: entry.value,
        colorHex: _categoryColors[builtInKey] ?? '#9E9E9E',
      );
    }).toList();
  }

  /// Get today's total spending (DEBIT transactions only)
  Future<double> getTodaySpending() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final transactions = await _transactionRepository.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
      type: 'DEBIT',
    );

    return transactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.amount,
    );
  }

  /// Format amount for widget display
  String formatAmountForWidget(double amount) {
    if (amount.abs() >= 1000) {
      final abbreviated = formatNumberAbbreviated(amount).replaceAll(' ', '');
      return '$abbreviated ETB';
    }

    final rounded = amount.roundToDouble();
    final formatted =
        formatNumberWithComma(rounded).replaceFirst(RegExp(r'\.00$'), '');
    return '$formatted ETB';
  }

  /// Get formatted timestamp
  String getLastUpdatedTimestamp() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$month/$day, $hour:$minute';
  }
}

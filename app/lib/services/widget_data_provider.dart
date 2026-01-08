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

  static const List<String> _rankColors = [
    '#5AC8FA',
    '#FFB347',
    '#FF5D73',
  ];

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

    final topEntries = sortedEntries.take(3).toList();
    return topEntries.asMap().entries.map((entry) {
      final rank = entry.key;
      final categoryEntry = entry.value;
      final category = categoryMap[categoryEntry.key];
      final colorHex = _rankColors[rank % _rankColors.length];
      return CategoryExpense(
        categoryId: categoryEntry.key,
        name: category?.name ?? 'Uncategorized',
        amount: categoryEntry.value,
        colorHex: colorHex,
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




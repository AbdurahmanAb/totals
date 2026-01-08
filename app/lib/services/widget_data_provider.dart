import 'package:totals/repositories/transaction_repository.dart';
import 'package:totals/utils/text_utils.dart';

class WidgetDataProvider {
  final TransactionRepository _transactionRepository;

  WidgetDataProvider({TransactionRepository? transactionRepository})
      : _transactionRepository =
            transactionRepository ?? TransactionRepository();

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
    return '${formatNumberWithComma(amount)} ETB';
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

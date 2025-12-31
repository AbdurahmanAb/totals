import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:totals/models/bank.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/screens/stats_recap_page.dart';
import 'package:totals/services/bank_config_service.dart';
import 'package:totals/utils/text_utils.dart';

class Wrapped2025Page extends StatefulWidget {
  const Wrapped2025Page({super.key});

  @override
  State<Wrapped2025Page> createState() => _Wrapped2025PageState();
}

class _Wrapped2025PageState extends State<Wrapped2025Page> {
  static const int _wrappedYear = 2025;

  final PageController _pageController = PageController();
  final BankConfigService _bankConfigService = BankConfigService();

  List<Bank> _banks = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await _bankConfigService.getBanks();
      if (mounted) {
        setState(() {
          _banks = banks;
        });
      }
    } catch (_) {
      // Ignore bank load errors; fallback labels will be used.
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime? _parseTransactionDate(Transaction transaction) {
    final raw = transaction.time;
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.tryParse(raw);
    }
  }

  String? _cleanCounterparty(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isIncome(Transaction transaction) {
    final type = transaction.type?.toUpperCase() ?? '';
    if (type.contains('CREDIT')) return true;
    if (type.contains('DEBIT')) return false;
    return transaction.amount >= 0;
  }

  List<Transaction> _filterTransactionsForYear(
    List<Transaction> transactions,
    int year,
  ) {
    final filtered = <Transaction>[];
    for (final transaction in transactions) {
      final date = _parseTransactionDate(transaction);
      if (date == null) continue;
      if (date.year == year) {
        filtered.add(transaction);
      }
    }
    return filtered;
  }

  _WrappedSummary _buildSummary(
    List<Transaction> transactions,
    TransactionProvider provider,
    Map<int, Bank> banksById,
  ) {
    final income = <Transaction>[];
    final expenses = <Transaction>[];
    final activeDays = <DateTime>{};
    final bankCounts = <int, int>{};
    final monthCounts = <int, int>{};
    final monthSpend = <int, double>{};
    final categorySpend = <int?, double>{};
    final sentTotals = <String, double>{};
    final receivedTotals = <String, double>{};
    double totalServiceCharge = 0.0;
    double totalVat = 0.0;
    int feeTransactionCount = 0;
    final feesByBank = <String, _FeeBreakdown>{};

    Transaction? biggest;
    double biggestAmount = 0.0;

    for (final transaction in transactions) {
      final date = _parseTransactionDate(transaction);
      if (date == null) continue;

      final isIncome = _isIncome(transaction);
      if (isIncome) {
        income.add(transaction);
      } else {
        expenses.add(transaction);
      }

      final serviceCharge = transaction.serviceCharge ?? 0.0;
      final vat = transaction.vat ?? 0.0;
      final feeTotal = serviceCharge + vat;
      if (feeTotal > 0) {
        totalServiceCharge += serviceCharge;
        totalVat += vat;
        feeTransactionCount++;
        final bankLabel = _bankLabelForTransaction(transaction, banksById);
        final current = feesByBank[bankLabel] ??
            const _FeeBreakdown(serviceCharge: 0.0, vat: 0.0);
        feesByBank[bankLabel] = _FeeBreakdown(
          serviceCharge: current.serviceCharge + serviceCharge,
          vat: current.vat + vat,
        );
      }

      activeDays.add(DateTime(date.year, date.month, date.day));

      if (transaction.bankId != null) {
        bankCounts.update(
          transaction.bankId!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final monthKey = date.year * 100 + date.month;
      monthCounts.update(
        monthKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      if (!isIncome) {
        final amount = transaction.amount.abs();
        monthSpend.update(
          monthKey,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
        categorySpend.update(
          transaction.categoryId,
          (value) => value + amount,
          ifAbsent: () => amount,
        );

        final recipient = _cleanCounterparty(transaction.receiver) ??
            _cleanCounterparty(transaction.creditor);
        if (recipient != null) {
          sentTotals.update(
            recipient,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
        }
      } else {
        final amount = transaction.amount.abs();
        final rawSender = _cleanCounterparty(transaction.creditor) ??
            _cleanCounterparty(transaction.receiver);
        if (rawSender != null) {
          if (transaction.bankId == 6 &&
              !_telebirrSenderHasPhone(rawSender)) {
            // Skip likely bank-to-telebirr transfers without sender phone info.
          } else {
            final sender = transaction.bankId == 6
                ? formatTelebirrSenderName(rawSender)
                : rawSender;
            receivedTotals.update(
              sender,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
          }
        }
      }

      final amountAbs = transaction.amount.abs();
      if (amountAbs > biggestAmount) {
        biggestAmount = amountAbs;
        biggest = transaction;
      }
    }

    final totalIncome =
        income.fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
    final totalExpense = expenses.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount.abs(),
    );
    final netFlow = totalIncome - totalExpense;

    int? topCategoryId;
    double topCategoryAmount = 0.0;
    for (final entry in categorySpend.entries) {
      if (entry.value > topCategoryAmount) {
        topCategoryAmount = entry.value;
        topCategoryId = entry.key;
      }
    }

    String topCategoryLabel;
    if (categorySpend.isEmpty) {
      topCategoryLabel = 'No expenses yet';
    } else if (topCategoryId == null) {
      topCategoryLabel = 'Uncategorized';
    } else {
      topCategoryLabel =
          provider.getCategoryById(topCategoryId)?.name ?? 'Other';
    }

    final topCategoryShare =
        totalExpense == 0 ? 0.0 : topCategoryAmount / totalExpense;

    int? topBankId;
    int topBankCount = 0;
    for (final entry in bankCounts.entries) {
      if (entry.value > topBankCount) {
        topBankCount = entry.value;
        topBankId = entry.key;
      }
    }

    String topBankLabel;
    if (topBankId == null) {
      topBankLabel = 'No bank data';
    } else {
      final bank = banksById[topBankId];
      topBankLabel = bank?.shortName ?? bank?.name ?? 'Bank $topBankId';
    }

    int? topMonthKey;
    int topMonthCount = 0;
    for (final entry in monthCounts.entries) {
      if (entry.value > topMonthCount) {
        topMonthCount = entry.value;
        topMonthKey = entry.key;
      }
    }

    DateTime? topMonthDate;
    double topMonthSpend = 0.0;
    if (topMonthKey != null) {
      final year = topMonthKey ~/ 100;
      final month = topMonthKey % 100;
      topMonthDate = DateTime(year, month);
      topMonthSpend = monthSpend[topMonthKey] ?? 0.0;
    }

    _BiggestTransaction? biggestHighlight;
    if (biggest != null) {
      final date = _parseTransactionDate(biggest);
      biggestHighlight = _BiggestTransaction(
        amount: biggest.amount.abs(),
        isIncome: _isIncome(biggest),
        date: date,
      );
    }

    final sentHighlight = _resolveTopCounterparty(sentTotals);
    final receivedHighlight = _resolveTopCounterparty(receivedTotals);

    return _WrappedSummary(
      totalTransactions: transactions.length,
      activeDays: activeDays.length,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netFlow: netFlow,
      totalServiceCharge: totalServiceCharge,
      totalVat: totalVat,
      feeTransactionCount: feeTransactionCount,
      feesByBank: feesByBank,
      topCategory: _CategoryHighlight(
        label: topCategoryLabel,
        amount: topCategoryAmount,
        share: topCategoryShare,
      ),
      topBank: _BankHighlight(
        label: topBankLabel,
        count: topBankCount,
      ),
      topMonth: _MonthHighlight(
        month: topMonthDate,
        count: topMonthCount,
        spend: topMonthSpend,
      ),
      topSentTo: sentHighlight,
      topReceivedFrom: receivedHighlight,
      biggestTransaction: biggestHighlight,
    );
  }

  _CounterpartyHighlight _resolveTopCounterparty(
    Map<String, double> totals,
  ) {
    if (totals.isEmpty) {
      return const _CounterpartyHighlight(
        label: 'No data yet',
        amount: 0.0,
      );
    }

    String topLabel = 'No data yet';
    double topAmount = 0.0;
    for (final entry in totals.entries) {
      if (entry.value > topAmount) {
        topLabel = entry.key;
        topAmount = entry.value;
      }
    }

    return _CounterpartyHighlight(
      label: topLabel,
      amount: topAmount,
    );
  }

  bool _telebirrSenderHasPhone(String sender) {
    final hasParens = sender.contains('(') && sender.contains(')');
    final hasDigits = RegExp(r'\d').hasMatch(sender);
    return hasParens && hasDigits;
  }

  String _bankLabelForTransaction(
    Transaction transaction,
    Map<int, Bank> banksById,
  ) {
    final bankId = transaction.bankId;
    if (bankId == null) return 'Unknown bank';
    final bank = banksById[bankId];
    return bank?.shortName ?? bank?.name ?? 'Bank $bankId';
  }

  String _formatCurrency(double value) {
    return 'ETB ${formatNumberWithComma(value)}';
  }

  String _formatCompactCurrency(double value) {
    return 'ETB ${formatNumberAbbreviated(value)}';
  }

  List<_WrappedSlideData> _buildSlides(
    BuildContext context,
    _WrappedSummary summary,
  ) {
    final accents = [
      const Color(0xFF2E6DF6),
      const Color(0xFF2BB673),
      const Color(0xFFE16A3D),
      const Color(0xFF10A6A6),
      const Color(0xFFF4B740),
      const Color(0xFF00B4D8),
      const Color(0xFFEF476F),
      const Color(0xFF118AB2),
      const Color(0xFF06D6A0),
      const Color(0xFFFA7921),
      const Color(0xFF4D96FF),
    ];

    final monthLabel = summary.topMonth.month == null
        ? 'No activity yet'
        : DateFormat('MMMM').format(summary.topMonth.month!);

    final monthSubtitle = summary.topMonth.month == null
        ? 'Add more 2025 transactions to unlock this highlight.'
        : '${summary.topMonth.count} transactions - ${_formatCurrency(summary.topMonth.spend)} spent';

    final biggestLabel = summary.biggestTransaction == null
        ? 'No transactions yet'
        : _formatCompactCurrency(summary.biggestTransaction!.amount);

    final biggestSubtitle = summary.biggestTransaction == null
        ? 'Once you have activity, your biggest moment appears here.'
        : '${summary.biggestTransaction!.isIncome ? 'Income' : 'Expense'} on ${_formatDate(summary.biggestTransaction!.date)}';

    final netLabel = summary.netFlow >= 0 ? 'Net saved' : 'Net outflow';
    final totalFees = summary.totalServiceCharge + summary.totalVat;
    final feeLines = summary.feesByBank.entries.toList()
      ..sort((a, b) {
        final totalA = a.value.serviceCharge + a.value.vat;
        final totalB = b.value.serviceCharge + b.value.vat;
        return totalB.compareTo(totalA);
      });
    final feeBreakdown = feeLines.isEmpty
        ? ''
        : feeLines
            .map(
              (entry) =>
                  '${entry.key}: ${_formatCurrency(entry.value.serviceCharge)} fees + ${_formatCurrency(entry.value.vat)} VAT',
            )
            .join('\n');
    final feeDetailText = feeBreakdown.isEmpty ? '' : '\n$feeBreakdown';

    return [
      _WrappedSlideData(
        kicker: 'Totals Wrapped $_wrappedYear',
        title: 'Your year in motion',
        value: '${summary.totalTransactions}',
        subtitle:
            'Transactions across ${summary.activeDays} active days in $_wrappedYear.',
        icon: Icons.auto_awesome,
        accent: accents[0],
        footnote: 'Swipe to keep going.',
      ),
      _WrappedSlideData(
        kicker: 'Income',
        title: 'Total money in',
        value: _formatCompactCurrency(summary.totalIncome),
        subtitle: _formatCurrency(summary.totalIncome),
        icon: Icons.trending_up,
        accent: accents[1],
      ),
      _WrappedSlideData(
        kicker: 'Spending',
        title: 'Total money out',
        value: _formatCompactCurrency(summary.totalExpense),
        subtitle: _formatCurrency(summary.totalExpense),
        icon: Icons.trending_down,
        accent: accents[2],
      ),
      _WrappedSlideData(
        kicker: 'Transaction fees',
        title: 'Service charge + VAT',
        value: totalFees == 0 ? 'ETB 0.00' : _formatCompactCurrency(totalFees),
        subtitle: summary.feeTransactionCount == 0
            ? 'No fees captured in $_wrappedYear.'
            : 'You spent ${_formatCurrency(totalFees)} in fees across ${summary.feeTransactionCount} transactions.$feeDetailText',
        icon: Icons.receipt_long_outlined,
        accent: accents[10],
      ),
      _WrappedSlideData(
        kicker: 'Balance',
        title: netLabel,
        value: _formatCompactCurrency(summary.netFlow.abs()),
        subtitle: summary.netFlow >= 0
            ? 'More income than spend.'
            : 'More spend than income.',
        icon: Icons.account_balance_wallet_outlined,
        accent: accents[3],
      ),
      _WrappedSlideData(
        kicker: 'Top category',
        title: 'Your biggest spending lane',
        value: summary.topCategory.label,
        subtitle: summary.topCategory.amount == 0
            ? 'No expense categories found in $_wrappedYear.'
            : '${_formatCurrency(summary.topCategory.amount)} - ${(summary.topCategory.share * 100).round()}% of spending',
        icon: Icons.local_florist_outlined,
        accent: accents[4],
      ),
      _WrappedSlideData(
        kicker: 'Top recipient',
        title: 'You sent the most to',
        value: summary.topSentTo.amount == 0
            ? 'No recipients yet'
            : summary.topSentTo.label,
        subtitle: summary.topSentTo.amount == 0
            ? 'No outgoing transfers yet.'
            : _formatCurrency(summary.topSentTo.amount),
        icon: Icons.send_outlined,
        accent: accents[5],
      ),
      _WrappedSlideData(
        kicker: 'Top sender',
        title: 'You received the most from',
        value: summary.topReceivedFrom.amount == 0
            ? 'No senders yet'
            : summary.topReceivedFrom.label,
        subtitle: summary.topReceivedFrom.amount == 0
            ? 'No incoming transfers yet.'
            : _formatCurrency(summary.topReceivedFrom.amount),
        icon: Icons.call_received_outlined,
        accent: accents[6],
      ),
      _WrappedSlideData(
        kicker: 'Peak month',
        title: 'Most active month',
        value: monthLabel,
        subtitle: monthSubtitle,
        icon: Icons.calendar_today_outlined,
        accent: accents[7],
      ),
      _WrappedSlideData(
        kicker: 'Biggest moment',
        title: 'Largest transaction',
        value: biggestLabel,
        subtitle: biggestSubtitle,
        icon: Icons.flash_on_outlined,
        accent: accents[8],
      ),
      _WrappedSlideData(
        kicker: 'Top bank',
        title: 'Most used bank',
        value: summary.topBank.label,
        subtitle: summary.topBank.count == 0
            ? 'Add more activity to unlock this highlight.'
            : '${summary.topBank.count} transactions in $_wrappedYear.',
        icon: Icons.account_balance_outlined,
        accent: accents[9],
        footnote: 'End of recap. Swipe back anytime.',
      ),
    ];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'an unknown date';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final transactions =
        _filterTransactionsForYear(provider.allTransactions, _wrappedYear);

    if (provider.isLoading && transactions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wrapped 2025'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    final banksById = {
      for (final bank in _banks) bank.id: bank,
    };

    final summary = _buildSummary(transactions, provider, banksById);
    final slides = _buildSlides(context, summary);
    final recapData = StatsRecapData.from(
      transactions: transactions,
      banks: _banks,
      year: _wrappedYear,
    );
    final totalPages = slides.length + 1;
    final indicatorAccent = _currentPage >= slides.length
        ? Theme.of(context).colorScheme.primary
        : slides[_currentPage].accent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Wrapped 2025'),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              if (index == slides.length) {
                return StatsRecapContent(data: recapData);
              }
              return _buildSlide(
                context,
                slides[index],
                isActive: index == _currentPage,
                showSwipeHint: index == 0,
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildPageIndicator(
                  context,
                  totalPages,
                  indicatorAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(
    BuildContext context,
    int total,
    Color accent,
  ) {
    final inactive =
        Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.35);
    return Row(
      children: [
        Row(
          children: List.generate(total, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 6),
              height: 8,
              width: isActive ? 22 : 8,
              decoration: BoxDecoration(
                color: isActive ? accent : inactive,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const Spacer(),
        Text(
          '${_currentPage + 1}/$total',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(
    BuildContext context,
    _WrappedSlideData slide, {
    required bool isActive,
    required bool showSwipeHint,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            slide.accent.withOpacity(isDark ? 0.25 : 0.16),
            base,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(
              color: slide.accent.withOpacity(isDark ? 0.25 : 0.18),
              size: 180,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -20,
            child: _GlowCircle(
              color: slide.accent.withOpacity(isDark ? 0.2 : 0.14),
              size: 220,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                kToolbarHeight + 28,
                20,
                72,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StaggeredReveal(
                    active: isActive,
                    delay: const Duration(milliseconds: 0),
                    child: Text(
                      slide.kicker,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredReveal(
                    active: isActive,
                    delay: const Duration(milliseconds: 90),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: isActive ? 1 : 0.94,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: slide.accent
                                  .withOpacity(isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              slide.icon,
                              color: slide.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            slide.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StaggeredReveal(
                    active: isActive,
                    delay: const Duration(milliseconds: 160),
                    offset: const Offset(0, 0.08),
                    child: AnimatedScale(
                      scale: isActive ? 1 : 0.98,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              theme.cardColor.withOpacity(isDark ? 0.9 : 0.96),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: slide.accent.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: slide.accent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (slide.footnote != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                slide.footnote!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showSwipeHint) ...[
                    const SizedBox(height: 18),
                    _StaggeredReveal(
                      active: isActive,
                      delay: const Duration(milliseconds: 320),
                      offset: const Offset(0, 0.04),
                      child: const _SwipeHint(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrapped 2025'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No 2025 transactions yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Once you have activity in 2025, your recap will appear here.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to analytics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrappedSlideData {
  final String kicker;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String? footnote;

  const _WrappedSlideData({
    required this.kicker,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.footnote,
  });
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _StaggeredReveal extends StatefulWidget {
  final bool active;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Widget child;

  const _StaggeredReveal({
    required this.active,
    required this.child,
    this.delay = const Duration(milliseconds: 120),
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.06),
  });

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _queueReveal();
    }
  }

  @override
  void didUpdateWidget(covariant _StaggeredReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;

    _timer?.cancel();
    if (widget.active) {
      setState(() {
        _visible = false;
      });
      _queueReveal();
    } else {
      setState(() {
        _visible = false;
      });
    }
  }

  void _queueReveal() {
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : widget.offset,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.15, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swipe,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Swipe for the next highlight',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrappedSummary {
  final int totalTransactions;
  final int activeDays;
  final double totalIncome;
  final double totalExpense;
  final double netFlow;
  final double totalServiceCharge;
  final double totalVat;
  final int feeTransactionCount;
  final Map<String, _FeeBreakdown> feesByBank;
  final _CategoryHighlight topCategory;
  final _BankHighlight topBank;
  final _MonthHighlight topMonth;
  final _CounterpartyHighlight topSentTo;
  final _CounterpartyHighlight topReceivedFrom;
  final _BiggestTransaction? biggestTransaction;

  const _WrappedSummary({
    required this.totalTransactions,
    required this.activeDays,
    required this.totalIncome,
    required this.totalExpense,
    required this.netFlow,
    required this.totalServiceCharge,
    required this.totalVat,
    required this.feeTransactionCount,
    required this.feesByBank,
    required this.topCategory,
    required this.topBank,
    required this.topMonth,
    required this.topSentTo,
    required this.topReceivedFrom,
    required this.biggestTransaction,
  });
}

class _FeeBreakdown {
  final double serviceCharge;
  final double vat;

  const _FeeBreakdown({
    required this.serviceCharge,
    required this.vat,
  });
}

class _CategoryHighlight {
  final String label;
  final double amount;
  final double share;

  const _CategoryHighlight({
    required this.label,
    required this.amount,
    required this.share,
  });
}

class _BankHighlight {
  final String label;
  final int count;

  const _BankHighlight({
    required this.label,
    required this.count,
  });
}

class _MonthHighlight {
  final DateTime? month;
  final int count;
  final double spend;

  const _MonthHighlight({
    required this.month,
    required this.count,
    required this.spend,
  });
}

class _CounterpartyHighlight {
  final String label;
  final double amount;

  const _CounterpartyHighlight({
    required this.label,
    required this.amount,
  });
}

class _BiggestTransaction {
  final double amount;
  final bool isIncome;
  final DateTime? date;

  const _BiggestTransaction({
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}

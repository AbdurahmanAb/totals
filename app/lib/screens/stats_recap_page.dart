import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:totals/models/bank.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/services/bank_config_service.dart';
import 'package:totals/utils/text_utils.dart';

class StatsRecapPage extends StatefulWidget {
  const StatsRecapPage({super.key});

  @override
  State<StatsRecapPage> createState() => _StatsRecapPageState();
}

class _StatsRecapPageState extends State<StatsRecapPage> {
  static const int _recapYear = 2025;
  final BankConfigService _bankConfigService = BankConfigService();
  List<Bank> _banks = [];

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await _bankConfigService.getBanks();
      if (!mounted) return;
      setState(() {
        _banks = banks;
      });
    } catch (_) {
      // Ignore bank load errors; placeholders will show.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final data = StatsRecapData.from(
          transactions: provider.allTransactions,
          banks: _banks,
          year: _recapYear,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF2B2C32),
          body: StatsRecapContent(data: data),
        );
      },
    );
  }
}

class StatsRecapContent extends StatelessWidget {
  final StatsRecapData data;

  const StatsRecapContent({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2B2C32),
            Color(0xFF1F2026),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              right: 24,
              top: 120,
              child: _DotField(),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Totals recap',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            data.monthLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${data.year}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _BankCluster(banks: data.topBanks),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 380;
                      final children = [
                        Expanded(
                          child: _CounterpartyColumn(
                            title: 'Top sent to',
                            entries: data.topSentTo,
                          ),
                        ),
                        const SizedBox(width: 16, height: 16),
                        Expanded(
                          child: _CounterpartyColumn(
                            title: 'Top received from',
                            entries: data.topReceivedFrom,
                          ),
                        ),
                      ];

                      if (isNarrow) {
                        return Column(
                          children: [
                            children[0],
                            const SizedBox(height: 20),
                            children[2],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsRecapData {
  final int year;
  final String monthLabel;
  final List<Bank> topBanks;
  final List<StatsRecapEntry> topSentTo;
  final List<StatsRecapEntry> topReceivedFrom;

  const StatsRecapData({
    required this.year,
    required this.monthLabel,
    required this.topBanks,
    required this.topSentTo,
    required this.topReceivedFrom,
  });

  factory StatsRecapData.from({
    required List<Transaction> transactions,
    required List<Bank> banks,
    required int year,
  }) {
    final filtered = _filterTransactionsForYear(transactions, year);
    final topBanks = _topBanks(filtered, banks);
    final sentTo = _topSentTo(filtered);
    final receivedFrom = _topReceivedFrom(filtered);
    final monthLabel = DateFormat('MMMM').format(
      DateTime(year, DateTime.now().month),
    );

    return StatsRecapData(
      year: year,
      monthLabel: monthLabel,
      topBanks: topBanks,
      topSentTo: sentTo,
      topReceivedFrom: receivedFrom,
    );
  }

  static DateTime? _parseTransactionDate(Transaction transaction) {
    final raw = transaction.time;
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.tryParse(raw);
    }
  }

  static bool _isIncome(Transaction transaction) {
    final type = transaction.type?.toUpperCase() ?? '';
    if (type.contains('CREDIT')) return true;
    if (type.contains('DEBIT')) return false;
    return transaction.amount >= 0;
  }

  static String? _cleanCounterparty(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static bool _telebirrSenderHasPhone(String sender) {
    final hasParens = sender.contains('(') && sender.contains(')');
    final hasDigits = RegExp(r'\d').hasMatch(sender);
    return hasParens && hasDigits;
  }

  static String _normalizeTelebirrName(Transaction transaction, String name) {
    if (transaction.bankId == 6) {
      return formatTelebirrSenderName(name);
    }
    return name;
  }

  static List<Transaction> _filterTransactionsForYear(
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

  static List<StatsRecapEntry> _topSentTo(List<Transaction> transactions) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (_isIncome(transaction)) continue;
      final raw = _cleanCounterparty(transaction.receiver) ??
          _cleanCounterparty(transaction.creditor);
      if (raw == null) continue;
      final label = _normalizeTelebirrName(transaction, raw);
      totals.update(
        label,
        (value) => value + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
    }
    return _topCounterparties(totals);
  }

  static List<StatsRecapEntry> _topReceivedFrom(
    List<Transaction> transactions,
  ) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (!_isIncome(transaction)) continue;
      final raw = _cleanCounterparty(transaction.creditor) ??
          _cleanCounterparty(transaction.receiver);
      if (raw == null) continue;
      if (transaction.bankId == 6 && !_telebirrSenderHasPhone(raw)) {
        continue;
      }
      final label = _normalizeTelebirrName(transaction, raw);
      totals.update(
        label,
        (value) => value + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
    }
    return _topCounterparties(totals);
  }

  static List<StatsRecapEntry> _topCounterparties(
    Map<String, double> totals,
  ) {
    final entries = totals.entries
        .map((entry) => StatsRecapEntry(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return entries.take(5).toList();
  }

  static List<Bank> _topBanks(
    List<Transaction> transactions,
    List<Bank> banks,
  ) {
    final counts = <int, int>{};
    for (final transaction in transactions) {
      final bankId = transaction.bankId;
      if (bankId == null) continue;
      counts.update(bankId, (value) => value + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final banksById = {
      for (final bank in banks) bank.id: bank,
    };
    final top = <Bank>[];
    for (final entry in sorted) {
      final bank = banksById[entry.key];
      if (bank != null) {
        top.add(bank);
      }
      if (top.length == 3) break;
    }
    return top;
  }
}

class _BankCluster extends StatelessWidget {
  final List<Bank> banks;

  const _BankCluster({required this.banks});

  @override
  Widget build(BuildContext context) {
    final placeholders = 3 - banks.length;
    return SizedBox(
      height: 180,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (banks.length > 1)
            Positioned(
              right: 16,
              top: 24,
              child: _BankBubble(
                bank: banks[1],
                size: 84,
              ),
            ),
          if (banks.length > 2)
            Positioned(
              left: 32,
              bottom: 10,
              child: _BankBubble(
                bank: banks[2],
                size: 70,
              ),
            ),
          if (banks.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              child: _BankBubble(
                bank: banks[0],
                size: 128,
              ),
            ),
          if (banks.isEmpty)
            _PlaceholderBubble(
              size: 128,
              label: 'Banks',
            ),
          if (placeholders > 0 && banks.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 16,
              child: _PlaceholderBubble(
                size: 68,
                label: '',
              ),
            ),
        ],
      ),
    );
  }
}

class _BankBubble extends StatelessWidget {
  final Bank bank;
  final double size;

  const _BankBubble({
    required this.bank,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          bank.image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _PlaceholderBubble extends StatelessWidget {
  final double size;
  final String label;

  const _PlaceholderBubble({
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _CounterpartyColumn extends StatelessWidget {
  final String title;
  final List<StatsRecapEntry> entries;

  const _CounterpartyColumn({
    required this.title,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Colors.white.withOpacity(0.85),
    );
    final emptyStyle = TextStyle(
      fontSize: 12,
      color: Colors.white.withOpacity(0.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Text('No data yet', style: emptyStyle)
        else
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ETB ${formatNumberWithComma(item.amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DotField extends StatelessWidget {
  const _DotField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          28,
          (index) => Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(index.isEven ? 0.12 : 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class StatsRecapEntry {
  final String label;
  final double amount;

  const StatsRecapEntry(this.label, this.amount);
}

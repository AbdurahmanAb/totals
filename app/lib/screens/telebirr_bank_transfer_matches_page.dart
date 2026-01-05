import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/services/bank_config_service.dart';
import 'package:totals/services/telebirr_bank_transfer_service.dart';
import 'package:totals/utils/text_utils.dart';

class TelebirrBankTransferMatchesPage extends StatefulWidget {
  const TelebirrBankTransferMatchesPage({super.key});

  @override
  State<TelebirrBankTransferMatchesPage> createState() =>
      _TelebirrBankTransferMatchesPageState();
}

class _TelebirrBankTransferMatchesPageState
    extends State<TelebirrBankTransferMatchesPage> {
  final BankConfigService _bankConfigService = BankConfigService();
  final TelebirrBankTransferService _matchService =
      TelebirrBankTransferService();
  bool _isLoading = true;
  List<TelebirrBankTransferMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.loadData();
      final banks = await _bankConfigService.getBanks();
      final matches = _matchService.findMatches(
        provider.allTransactions,
        banks,
      );
      if (!mounted) return;
      setState(() {
        _matches = matches;
      });
    } catch (e) {
      print("debug: Error loading telebirr matches: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatDelta(Duration delta) {
    final minutes = delta.inMinutes;
    if (minutes < 1) return 'seconds apart';
    if (minutes == 1) return '1 minute apart';
    return '$minutes minutes apart';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telebirr Bank Matches'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMatches,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _matches.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 48,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No matched transfers yet',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We will show Telebirr credits that match a bank debit by amount and time.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      final telebirrTx = match.telebirrTransaction;
                      final bankTx = match.bankTransaction;
                      final bank = match.bank;
                      final telebirrTime = _parseTime(telebirrTx.time);
                      final bankTime = _parseTime(bankTx.time);
                      final sender = telebirrTx.creditor?.trim() ?? '';
                      final formattedSender = sender.isEmpty
                          ? 'Unknown sender'
                          : formatTelebirrSenderName(sender);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${bank.shortName} → Telebirr',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _formatDelta(match.timeDelta),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sender: $formattedSender',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _MatchRow(
                              label: 'Telebirr credit',
                              amountLabel:
                                  '+ETB ${_formatAmount(telebirrTx.amount)}',
                              timeLabel: _formatDateTime(telebirrTime),
                              amountColor: Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _MatchRow(
                              label: '${bank.shortName} debit',
                              amountLabel:
                                  '-ETB ${_formatAmount(bankTx.amount)}',
                              timeLabel: _formatDateTime(bankTime),
                              amountColor: theme.colorScheme.error,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final String label;
  final String amountLabel;
  final String timeLabel;
  final Color amountColor;

  const _MatchRow({
    required this.label,
    required this.amountLabel,
    required this.timeLabel,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amountLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

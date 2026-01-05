import 'package:flutter/material.dart';
import 'package:totals/models/bank.dart';
import 'package:totals/services/bank_config_service.dart';
import 'package:totals/models/summary_models.dart';
import 'package:totals/widgets/accounts_summary.dart';
import 'package:totals/widgets/total_balance_card.dart';
import 'package:totals/constants/cash_constants.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/widgets/add_cash_transaction_sheet.dart';
import 'package:provider/provider.dart';

class BankDetail extends StatefulWidget {
  final int bankId;
  final List<AccountSummary> accountSummaries;

  const BankDetail({
    Key? key,
    required this.bankId,
    required this.accountSummaries,
  }) : super(key: key);

  @override
  State<BankDetail> createState() => _BankDetailState();
}

class _BankDetailState extends State<BankDetail> {
  // isBankDetailExpanded is no longer needed as TotalBalanceCard handles its own expansion.
  bool showTotalBalance = false;
  List<String> visibleTotalBalancesForSubCards = [];
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
      if (mounted) {
        setState(() {
          _banks = banks;
        });
      }
    } catch (e) {
      print("debug: Error loading banks: $e");
    }
  }

  Bank? _getBankInfo() {
    if (widget.bankId == CashConstants.bankId) {
      return Bank(
        id: CashConstants.bankId,
        name: CashConstants.bankName,
        shortName: CashConstants.bankShortName,
        codes: const [],
        image: CashConstants.bankImage,
        colors: CashConstants.bankColors,
      );
    }
    try {
      return _banks.firstWhere((element) => element.id == widget.bankId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Calculate totals for this bank
    double totalBalance = 0;
    double totalCredit = 0;
    double totalDebit = 0;

    for (var account in widget.accountSummaries) {
      totalBalance += account.balance;
      totalCredit += account.totalCredit;
      totalDebit += account.totalDebit;
    }

    final bankSummary = AllSummary(
      totalCredit: totalCredit,
      totalDebit: totalDebit,
      banks: 1,
      totalBalance: totalBalance,
      accounts: widget.accountSummaries.length,
    );

    final bankInfo = _getBankInfo();
    final bankName = bankInfo?.name ?? "Unknown Bank";
    final bankImage = bankInfo?.image ?? "assets/images/cbe.png";

    final isCashBank = widget.bankId == CashConstants.bankId;
    final cashAccountNumber = widget.accountSummaries.isNotEmpty
        ? widget.accountSummaries.first.accountNumber
        : CashConstants.defaultAccountNumber;

    return Column(
      children: [
        const SizedBox(height: 12),
        // Replaced custom Card with TotalBalanceCard (Blue Gradient ID 99)
        TotalBalanceCard(
          summary: bankSummary,
          showBalance: showTotalBalance,
          title: bankName.toUpperCase(),
          logoAsset: bankImage,
          gradientId: widget.bankId,
          colors: bankInfo?.colors, // Use colors from bank data if available
          subtitle: "${widget.accountSummaries.length} Accounts",
          onToggleBalance: () {
            setState(() {
              showTotalBalance = !showTotalBalance;
              // Migrate logic: toggling main balance also toggles all sub-cards
              visibleTotalBalancesForSubCards = visibleTotalBalancesForSubCards
                      .isEmpty
                  ? widget.accountSummaries.map((e) => e.accountNumber).toList()
                  : [];
            });
          },
        ),
        const SizedBox(height: 12),
        if (isCashBank) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick add',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => showAddCashTransactionSheet(
                          context: context,
                          provider: Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          ),
                          accountNumber: cashAccountNumber,
                          initialIsDebit: true,
                        ),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Expense'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => showAddCashTransactionSheet(
                          context: context,
                          provider: Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          ),
                          accountNumber: cashAccountNumber,
                          initialIsDebit: false,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Income'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: AccountsSummaryList(
              accountSummaries: widget.accountSummaries,
              visibleTotalBalancesForSubCards: visibleTotalBalancesForSubCards),
        ),
      ],
    );
  }
}

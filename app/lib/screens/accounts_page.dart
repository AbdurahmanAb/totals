import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:totals/repositories/user_account_repository.dart';
import 'package:totals/data/all_banks_from_assets.dart';
import 'package:totals/models/bank.dart';
import 'package:totals/models/user_account.dart';
import 'package:totals/widgets/add_user_account_form.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final UserAccountRepository _userAccountRepo = UserAccountRepository();
  final TextEditingController _searchController = TextEditingController();
  List<Bank> _banks = [];
  List<UserAccount> _userAccounts = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Load all banks from assets (same as form uses)
      _banks = AllBanksFromAssets.getAllBanks();

      // Load user accounts
      final accounts = await _userAccountRepo.getUserAccounts();

      if (mounted) {
        setState(() {
          _userAccounts = accounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("debug: Error loading data: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Bank? _getBankInfo(int bankId) {
    try {
      return _banks.firstWhere((element) => element.id == bankId);
    } catch (e) {
      return null;
    }
  }

  List<UserAccount> _filterAccounts(List<UserAccount> accounts) {
    if (_searchQuery.isEmpty) return accounts;
    return accounts.where((account) {
      final bank = _getBankInfo(account.bankId);
      final bankName = bank?.name.toLowerCase() ?? '';
      final bankShortName = bank?.shortName.toLowerCase() ?? '';
      final accountNumber = account.accountNumber.toLowerCase();
      final holderName = account.accountHolderName.toLowerCase();
      final query = _searchQuery;
      return accountNumber.contains(query) ||
          holderName.contains(query) ||
          bankName.contains(query) ||
          bankShortName.contains(query);
    }).toList();
  }

  Future<void> _copyAccountNumber(String accountNumber) async {
    await Clipboard.setData(ClipboardData(text: accountNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account number copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddAccountDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: AddUserAccountForm(
                onAccountAdded: () {
                  _loadData();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(UserAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: Text(
            'Are you sure you want to delete account ${account.accountNumber}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        if (account.id != null) {
          await _userAccountRepo.deleteUserAccount(account.id!);
        } else {
          await _userAccountRepo.deleteUserAccountByNumberAndBank(
            account.accountNumber,
            account.bankId,
          );
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredAccounts = _filterAccounts(_userAccounts);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Quick Access Accounts'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Accounts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAccounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.account_balance_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No accounts found'
                                  : 'No accounts yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isEmpty)
                              Text(
                                'Tap + to add your first account',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final account = filteredAccounts[index];
                            final bank = _getBankInfo(account.bankId);
                            return _AccountCard(
                              account: account,
                              bank: bank,
                              onCopy: () =>
                                  _copyAccountNumber(account.accountNumber),
                              onDelete: () => _confirmDeleteAccount(account),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final UserAccount account;
  final Bank? bank;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    this.bank,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('Copy Account Number'),
                      onTap: () {
                        Navigator.pop(context);
                        onCopy();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete,
                        color: colorScheme.error,
                      ),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Bank icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: bank != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              bank!.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.account_balance,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.account_balance,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank?.shortName ?? bank?.name ?? 'Unknown Bank',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.accountHolderName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: onCopy,
                    tooltip: 'Copy account number',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Number',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.accountNumber,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

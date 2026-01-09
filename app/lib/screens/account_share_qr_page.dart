import 'dart:io';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:totals/constants/cash_constants.dart';
import 'package:totals/data/all_banks_from_assets.dart';
import 'package:totals/models/account.dart';
import 'package:totals/models/bank.dart';
import 'package:totals/repositories/account_repository.dart';
import 'package:totals/utils/account_share_payload.dart';

class AccountShareQrPage extends StatefulWidget {
  const AccountShareQrPage({super.key});

  @override
  State<AccountShareQrPage> createState() => _AccountShareQrPageState();
}

class _AccountShareQrPageState extends State<AccountShareQrPage> {
  final AccountRepository _accountRepo = AccountRepository();
  final TextEditingController _displayNameController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  static const List<Color> _qrPalette = [
    Color(0xFF0D47A1),
    Color(0xFF1565C0),
    Color(0xFF1976D2),
    Color(0xFF1E88E5),
    Color(0xFF2196F3),
    Color(0xFF42A5F5),
    Color(0xFF64B5F6),
  ];
  late final int _qrSeed;
  late final PrettyQrShape _qrShape;

  List<Account> _accounts = [];
  List<Bank> _banks = [];
  bool _isLoading = true;
  Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    final random = Random();
    _qrSeed = random.nextInt(0x7fffffff);
    _qrShape = _buildRandomQrShape(random);
    _loadData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final allAccounts = await _accountRepo.getAccounts();
      // Filter out cash account
      final accounts = allAccounts
          .where((account) => account.bank != CashConstants.bankId)
          .toList();
      final banks = AllBanksFromAssets.getAllBanks();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _banks = banks;
        _selectedKeys = accounts.map(_accountKey).toSet();
        _isLoading = false;
      });
      // Initialize display name from first account
      _updateDisplayNameFromSelection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _accountKey(Account account) {
    return '${account.bank}:${account.accountNumber}';
  }

  Bank? _getBankInfo(int bankId) {
    try {
      return _banks.firstWhere((bank) => bank.id == bankId);
    } catch (_) {
      return null;
    }
  }

  Map<int, List<Account>> _groupAccountsByBank() {
    final grouped = <int, List<Account>>{};
    for (final account in _accounts) {
      grouped.putIfAbsent(account.bank, () => <Account>[]).add(account);
    }
    return grouped;
  }

  void _updateDisplayNameFromSelection() {
    // Only update if display name is empty
    if (_displayNameController.text.isEmpty) {
      for (final account in _accounts) {
        if (_selectedKeys.contains(_accountKey(account)) &&
            account.accountHolderName.trim().isNotEmpty) {
          _displayNameController.text = account.accountHolderName.trim();
          return;
        }
      }
    }
  }

  AccountSharePayload? _buildPayload() {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) return null;
    final entries = _accounts
        .where((account) => _selectedKeys.contains(_accountKey(account)))
        .map((account) => AccountShareEntry(
              bankId: account.bank,
              accountNumber: account.accountNumber,
            ))
        .toList();
    if (entries.isEmpty) return null;
    return AccountSharePayload(name: name, accounts: entries);
  }

  void _toggleAccount(Account account, bool? isSelected) {
    final key = _accountKey(account);
    setState(() {
      if (isSelected == true) {
        _selectedKeys.add(key);
      } else {
        _selectedKeys.remove(key);
      }
    });
    _updateDisplayNameFromSelection();
  }

  void _selectAllAccounts() {
    setState(() {
      _selectedKeys = _accounts.map(_accountKey).toSet();
    });
  }

  void _clearAllAccounts() {
    setState(() {
      _selectedKeys.clear();
    });
  }

  void _toggleBankSelection(List<Account> accounts, bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedKeys.addAll(accounts.map(_accountKey));
      } else {
        for (final account in accounts) {
          _selectedKeys.remove(_accountKey(account));
        }
      }
    });
  }

  Future<void> _shareQrCode() async {
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(buffer);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan this QR code to add my account details',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing QR code: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  PrettyQrShape _buildRandomQrShape(Random random) {
    return PrettyQrShape.custom(
      _TotalsRandomColorSymbol(
        palette: _qrPalette,
        seed: _qrSeed,
        rounding: 0.2 + random.nextDouble() * 0.6,
        density: 0.85 + random.nextDouble() * 0.15,
      ),
      finderPattern: _randomAccentShape(random),
      timingPatterns: _randomAccentShape(random),
      alignmentPatterns: _randomAccentShape(random),
    );
  }

  PrettyQrShape _randomAccentShape(Random random) {
    final pick = random.nextInt(3);
    final color = _qrPalette[random.nextInt(_qrPalette.length)];
    switch (pick) {
      case 0:
        return PrettyQrSmoothSymbol(
          color: color,
          roundFactor: 0.65 + random.nextDouble() * 0.35,
        );
      case 1:
        return PrettyQrSquaresSymbol(
          color: color,
          density: 0.85 + random.nextDouble() * 0.15,
          rounding: 0.2 + random.nextDouble() * 0.7,
          unifiedFinderPattern: false,
        );
      default:
        return PrettyQrDotsSymbol(
          color: color,
          density: 0.85 + random.nextDouble() * 0.15,
          unifiedFinderPattern: false,
          unifiedAlignmentPatterns: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final payload = _buildPayload();
    final qrData = payload == null ? null : AccountSharePayload.encode(payload);
    final groupedAccounts = _groupAccountsByBank();
    final groupedKeys = groupedAccounts.keys.toList()
      ..sort((a, b) {
        final nameA = _getBankInfo(a)?.name ?? '';
        final nameB = _getBankInfo(b)?.name ?? '';
        return nameA.compareTo(nameB);
      });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Share Accounts'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No accounts yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register accounts first, then generate a share QR.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _QrPreviewCard(
                      qrKey: _qrKey,
                      data: qrData,
                      sharedName: _displayNameController.text.trim(),
                      colorScheme: colorScheme,
                      qrShape: _qrShape,
                      onShare: _shareQrCode,
                    ),
                    const SizedBox(height: 24),
                    _buildDisplayNameField(theme, colorScheme),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          '${_selectedKeys.length} of ${_accounts.length} selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _selectAllAccounts,
                          child: const Text('Select all'),
                        ),
                        TextButton(
                          onPressed: _clearAllAccounts,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final bankId in groupedKeys) ...[
                      _BankSectionHeader(
                        bank: _getBankInfo(bankId),
                        accounts: groupedAccounts[bankId] ?? const [],
                        selectedKeys: _selectedKeys,
                        onToggle: _toggleBankSelection,
                      ),
                      const SizedBox(height: 8),
                      for (final account in groupedAccounts[bankId] ?? const [])
                        _AccountShareTile(
                          account: account,
                          bank: _getBankInfo(account.bank),
                          isSelected:
                              _selectedKeys.contains(_accountKey(account)),
                          onChanged: (value) => _toggleAccount(account, value),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
    );
  }

  Widget _buildDisplayNameField(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISPLAY NAME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              hintText: 'Name shown to recipient',
              prefixIcon: Icon(
                Icons.person_outline,
                size: 20,
                color: colorScheme.primary,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _TotalsRandomColorSymbol extends PrettyQrShape {
  final List<Color> palette;
  final int seed;
  final double rounding;
  final double density;

  const _TotalsRandomColorSymbol({
    required this.palette,
    required this.seed,
    this.rounding = 0.35,
    this.density = 1.0,
  })  : assert(palette.length > 1),
        assert(rounding >= 0.0 && rounding <= 1.0),
        assert(density >= 0.0 && density <= 1.0);

  @override
  void paint(PrettyQrPaintingContext context) {
    final matrix = context.matrix;
    final canvasBounds = context.estimatedBounds;
    final moduleDimension = canvasBounds.longestSide / matrix.version.dimension;

    final radius = moduleDimension / 2;
    final effectiveRadius =
        PrettyQrShape.clampDouble(radius * rounding, 0, radius);
    final effectiveDensity =
        radius - PrettyQrShape.clampDouble(radius * density, 1, radius);

    for (final module in matrix) {
      if (!module.isDark) continue;
      final moduleRect = module.resolveRect(context);
      final moduleRRect = RRect.fromRectAndRadius(
        moduleRect,
        Radius.circular(effectiveRadius),
      ).deflate(effectiveDensity);
      final paint = Paint()
        ..color = _colorForModule(module)
        ..isAntiAlias = true
        ..style = PaintingStyle.fill;

      context.canvas.drawRRect(moduleRRect, paint);
    }
  }

  Color _colorForModule(PrettyQrModule module) {
    final hash = module.x * 73856093 ^ module.y * 19349663 ^ seed;
    final index = (hash & 0x7fffffff) % palette.length;
    return palette[index];
  }

  @override
  _TotalsRandomColorSymbol? lerpFrom(PrettyQrShape? a, double t) {
    if (identical(a, this)) {
      return this;
    }

    if (a == null) return this;
    if (a is! _TotalsRandomColorSymbol) return null;

    if (t == 0.0) return a;
    if (t == 1.0) return this;

    return _TotalsRandomColorSymbol(
      palette: palette,
      seed: seed,
      rounding: ui.lerpDouble(a.rounding, rounding, t)!,
      density: ui.lerpDouble(a.density, density, t)!,
    );
  }

  @override
  _TotalsRandomColorSymbol? lerpTo(PrettyQrShape? b, double t) {
    if (identical(this, b)) {
      return this;
    }

    if (b == null) return this;
    if (b is! _TotalsRandomColorSymbol) return null;

    if (t == 0.0) return this;
    if (t == 1.0) return b;

    return _TotalsRandomColorSymbol(
      palette: palette,
      seed: seed,
      rounding: ui.lerpDouble(rounding, b.rounding, t)!,
      density: ui.lerpDouble(density, b.density, t)!,
    );
  }
}

class _QrPreviewCard extends StatelessWidget {
  final GlobalKey qrKey;
  final String? data;
  final String? sharedName;
  final ColorScheme colorScheme;
  final PrettyQrShape qrShape;
  final VoidCallback onShare;

  const _QrPreviewCard({
    required this.qrKey,
    required this.data,
    required this.sharedName,
    required this.colorScheme,
    required this.qrShape,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = data != null && data!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Share your accounts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (hasData) ...[
            RepaintBoundary(
              key: qrKey,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      Widget qrView;
                      try {
                        qrView = PrettyQrView.data(
                          data: data!,
                          decoration: PrettyQrDecoration(
                            background: Colors.white,
                            shape: qrShape,
                            image: const PrettyQrDecorationImage(
                              image: AssetImage('assets/icon/totals_icon.png'),
                              scale: 0.2,
                              padding: EdgeInsets.all(6),
                            ),
                          ),
                        );
                      } catch (_) {
                        qrView = Text(
                          'Too much data to render QR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      }

                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: qrView),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Share QR Code'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else
            Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select accounts and enter a name to generate your QR.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            sharedName == null || sharedName!.isEmpty
                ? 'Select accounts to share from your quick access list.'
                : 'Sharing as $sharedName. Have someone scan to add your accounts.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankSectionHeader extends StatelessWidget {
  final Bank? bank;
  final List<Account> accounts;
  final Set<String> selectedKeys;
  final void Function(List<Account> accounts, bool selectAll) onToggle;

  const _BankSectionHeader({
    required this.bank,
    required this.accounts,
    required this.selectedKeys,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bankName = bank?.shortName ?? bank?.name ?? 'Bank';
    bool isSelected(Account account) {
      return selectedKeys.contains('${account.bank}:${account.accountNumber}');
    }

    final allSelected = accounts.every(isSelected);

    return Row(
      children: [
        Text(
          bankName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => onToggle(accounts, !allSelected),
          child: Text(allSelected ? 'Clear bank' : 'Select bank'),
        ),
      ],
    );
  }
}

class _AccountShareTile extends StatelessWidget {
  final Account account;
  final Bank? bank;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _AccountShareTile({
    required this.account,
    required this.bank,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      activeColor: colorScheme.primary,
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: bank != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  bank!.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_balance,
                      color: colorScheme.onSurfaceVariant,
                    );
                  },
                ),
              )
            : Icon(
                Icons.account_balance,
                color: colorScheme.onSurfaceVariant,
              ),
      ),
      title: Text(
        bank?.shortName ?? bank?.name ?? 'Unknown Bank',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        account.accountNumber,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

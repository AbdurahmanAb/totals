import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:totals/providers/theme_provider.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/services/data_export_import_service.dart';
import 'package:totals/screens/categories_page.dart';
import 'package:totals/screens/notification_settings_page.dart';
import 'package:totals/widgets/clear_database_dialog.dart';
import 'package:totals/widgets/add_account_form.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final DataExportImportService _exportImportService =
      DataExportImportService();
  bool _isExporting = false;
  bool _isImporting = false;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _openSupportLink() async {
    final uri = Uri.parse('https://jami.bio/detached');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback to platform default
      await launchUrl(uri);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final jsonData = await _exportImportService.exportAllData();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final file = File('${tempDir.path}/totals_export_$timestamp.json');
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Totals Data Export',
        subject: 'Totals Backup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported successfully',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();

        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Import Data'),
            content: const Text(
              'This will add the imported data to your existing data. Duplicates will be skipped.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _exportImportService.importAllData(jsonData);

          // Reload data in provider
          if (mounted) {
            final provider =
                Provider.of<TransactionProvider>(context, listen: false);
            await provider.loadData();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Data imported successfully',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import failed: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  String _getAccountInitials(String accountHolderName) {
    if (accountHolderName.isEmpty) return 'U';
    final parts = accountHolderName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return accountHolderName[0].toUpperCase();
  }

  void _navigateToManageAccounts() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RegisterAccountForm(
                    onSubmit: () {
                      final provider = Provider.of<TransactionProvider>(
                          context,
                          listen: false);
                      provider.loadData();
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'T',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Totals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'A personal finance tracking app that helps you manage your bank accounts and transactions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Help & FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                context: context,
                question: 'How do I add an account?',
                answer: 'Tap on the account card at the top of settings to manage accounts.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                context: context,
                question: 'How do I export my data?',
                answer: 'Go to Settings > Export Data to save your data as a JSON file.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                context: context,
                question: 'How do I categorize transactions?',
                answer: 'Tap on any transaction and select a category from the list.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: theme.colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                // Get account name for profile card
                final accounts = provider.accountSummaries;
                final accountName = accounts.isNotEmpty
                    ? accounts.first.accountHolderName
                    : 'No Account';
                final accountInitials = accounts.isNotEmpty
                    ? _getAccountInitials(accounts.first.accountHolderName)
                    : 'U';

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Card
                    _buildProfileCard(
                      context: context,
                      accountName: accountName,
                      accountInitials: accountInitials,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Section: Settings
                    _buildSectionHeader(title: 'Preferences'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      children: [
                        _buildSettingTile(
                          icon: Icons.category_rounded,
                          title: 'Categories',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CategoriesPage(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingTile(
                          icon: Icons.notifications_rounded,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationSettingsPage(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingTile(
                          icon: Icons.upload_rounded,
                          title: 'Export Data',
                          trailing: _isExporting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                          onTap: _isExporting ? null : _exportData,
                        ),
                        _buildDivider(context),
                        _buildSettingTile(
                          icon: Icons.download_rounded,
                          title: 'Import Data',
                          trailing: _isImporting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                          onTap: _isImporting ? null : _importData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section: Support
                    _buildSectionHeader(title: 'Support'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      children: [
                        _buildSettingTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          onTap: _showAboutDialog,
                        ),
                        _buildDivider(context),
                        _buildSettingTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & FAQ',
                          onTap: _showHelpDialog,
                        ),
                        _buildDivider(context),
                        _buildSettingTile(
                          icon: Icons.delete_outline_rounded,
                          title: 'Clear Data',
                          titleColor: theme.colorScheme.error,
                          onTap: () => showClearDatabaseDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Support Developers Button
                    _buildSupportDevelopersButton(),
                    const SizedBox(height: 48),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String accountName,
    required String accountInitials,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _navigateToManageAccounts,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  accountInitials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to manage accounts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: titleColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: theme.colorScheme.outline.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSupportDevelopersButton() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.9),
            theme.colorScheme.primary.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openSupportLink,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Icon(
                      Icons.favorite_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 20 * (1 + 0.1 * _shimmerController.value),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Support the Developers',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
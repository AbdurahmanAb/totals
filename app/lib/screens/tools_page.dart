import 'package:flutter/material.dart';
import 'package:totals/screens/web_page.dart';
import 'package:totals/screens/accounts_page.dart';
import 'package:totals/screens/verify_payments_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Tools',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This page dedicated to handy tools',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _ToolCard(
                title: 'Web Dashboard',
                description: 'Access your financial dashboard via web browser',
                icon: Icons.dashboard_outlined,
                iconColor: colorScheme.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WebPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ToolCard(
                title: 'Accounts',
                description: 'View and manage your quick access accounts',
                icon: Icons.account_balance_outlined,
                iconColor: colorScheme.secondary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ToolCard(
                title: 'Verify Payments',
                description: 'Scan QR codes to verify payment information',
                icon: Icons.qr_code_scanner,
                iconColor: colorScheme.tertiary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VerifyPaymentsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

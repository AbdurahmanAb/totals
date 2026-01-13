import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDayHeader extends StatelessWidget {
  final DateTime? date;

  const TransactionDayHeader({super.key, required this.date});

  String _labelFor(DateTime? date) {
    if (date == null) return 'Unknown date';
    final now = DateTime.now();
    final format =
        date.year == now.year ? DateFormat('MMMM d') : DateFormat('MMMM d, yyyy');
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(date);
    final background =
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8);
    final border = Theme.of(context).colorScheme.outline.withOpacity(0.2);
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

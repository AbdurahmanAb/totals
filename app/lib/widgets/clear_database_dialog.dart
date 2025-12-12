import 'package:flutter/material.dart';
import 'package:totals/repositories/transaction_repository.dart';
import 'package:totals/repositories/account_repository.dart';
import 'package:totals/repositories/failed_parse_repository.dart';
import 'package:provider/provider.dart';
import 'package:totals/providers/transaction_provider.dart';

Future<void> showClearDatabaseDialog(BuildContext context) async {
  bool clearTransactions = false;
  bool clearAccounts = false;
  bool clearFailedParses = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              "Clear Database",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF444750),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select what to clear:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF444750),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text("Transactions"),
                    value: clearTransactions,
                    onChanged: (value) {
                      setState(() {
                        clearTransactions = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF294EC3),
                  ),
                  CheckboxListTile(
                    title: const Text("Accounts"),
                    value: clearAccounts,
                    onChanged: (value) {
                      setState(() {
                        clearAccounts = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF294EC3),
                  ),
                  CheckboxListTile(
                    title: const Text("Failed Parses"),
                    value: clearFailedParses,
                    onChanged: (value) {
                      setState(() {
                        clearFailedParses = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF294EC3),
                  ),
                  if (!clearTransactions &&
                      !clearAccounts &&
                      !clearFailedParses)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Please select at least one option",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Color(0xFF444750)),
                ),
              ),
              TextButton(
                onPressed: (clearTransactions ||
                        clearAccounts ||
                        clearFailedParses)
                    ? () async {
                        try {
                          if (clearTransactions) {
                            await TransactionRepository().clearAll();
                          }
                          if (clearAccounts) {
                            await AccountRepository().clearAll();
                          }
                          if (clearFailedParses) {
                            await FailedParseRepository().clear();
                          }

                          // Reload data
                          if (context.mounted) {
                            Provider.of<TransactionProvider>(context,
                                    listen: false)
                                .loadData();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Database cleared successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error clearing database: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                child: Text(
                  "Clear",
                  style: TextStyle(
                    color: (clearTransactions ||
                            clearAccounts ||
                            clearFailedParses)
                        ? Colors.red
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

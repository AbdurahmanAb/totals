import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/main.dart';

class Transaction {
  final String reference;
  final String creditor;
  final String receiver;
  final double amount;
  final DateTime time;

  Transaction(
      {required this.reference,
      required this.creditor,
      required this.amount,
      required this.time,
      required this.receiver});
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.creditor,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 13,
            )
          ],
        );
      },
    );
  }
}

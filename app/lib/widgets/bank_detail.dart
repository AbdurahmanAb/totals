import 'package:flutter/material.dart';

class BankDetail extends StatelessWidget {
  final int bankId;

  const BankDetail({Key? key, required this.bankId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with your actual data fetching logic

    return Container(child: Text(bankId.toString()));
  }
}

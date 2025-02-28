import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totals/data/consts.dart';

class Account {
  final String accountNumber;
  final String accountHolderName;
  final int bankId;
  final double totalCredit;
  final double totalDebit;

  Account({
    required this.accountNumber,
    required this.accountHolderName,
    required this.bankId,
    required this.totalCredit,
    required this.totalDebit,
  });
}

class Transaction {
  final String reference;
  final String accountNumber;
  final String? creditor;
  final String receiver;
  final double amount;
  final DateTime time;
  final String type;

  Transaction(
      {required this.reference,
      required this.accountNumber,
      this.creditor,
      required this.amount,
      required this.time,
      required this.receiver,
      required this.type});
}

class AccountDetailPage extends StatefulWidget {
  final String accountNumber;
  AccountDetailPage({required this.accountNumber});

  @override
  _AccountDetailPageState createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  List<String> tabs = ["All Transactions", "Credits", "Debits"];
  String activeTab = "All Transactions";
  List<Transaction> transactions = [];

  Account? account;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    List<String>? allAccounts = prefs.getStringList('accounts');
    Account? tempAccount;
    if (allAccounts != null) {
      for (var a in allAccounts) {
        var accountData = jsonDecode(a);
        if (accountData['accountNumber'] == widget.accountNumber) {
          tempAccount = Account(
            accountHolderName: accountData['accountHolderName'],
            accountNumber: accountData['accountNumber'],
            bankId: accountData['bank'],
            totalCredit: accountData['totalCredit'] ?? 0,
            totalDebit: accountData['totalDebit'] ?? 0,
          );
          break;
        }
      }
    }
    setState(() {
      account = tempAccount;
      transactions = [
        Transaction(
          reference: 'TXN001',
          creditor: 'John Doe',
          receiver: 'Jane Smith',
          accountNumber: '1000399285678',
          type: 'credit',
          amount: 100.0,
          time: DateTime.now().subtract(Duration(days: 1)),
        ),
        Transaction(
          reference: 'TXN002',
          creditor: 'Alice Johnson',
          accountNumber: '1000399285678',
          receiver: 'Bob Brown',
          type: 'credit',
          amount: 200.0,
          time: DateTime.now().subtract(Duration(days: 2)),
        ),
        Transaction(
          reference: 'TXN003',
          accountNumber: '1000399285678',
          type: 'debit',
          receiver: 'Diana Evans',
          amount: 150.0,
          time: DateTime.now().subtract(Duration(days: 3)),
        ),
        Transaction(
          reference: 'TXN004',
          receiver: 'Frank Green',
          accountNumber: '1000399285678',
          type: 'debit',
          amount: 250.0,
          time: DateTime.now().subtract(Duration(days: 4)),
        ),
        Transaction(
          reference: 'TXN005',
          creditor: 'George Harris',
          receiver: 'Hannah White',
          accountNumber: '1000399285678',
          type: 'credit',
          amount: 300.0,
          time: DateTime.now().subtract(Duration(days: 5)),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffF1F4FF),
        appBar: AppBar(
          backgroundColor: const Color(0xffF1F4FF),
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF294EC3),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Transaction History',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF294EC3))),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[500]!, width: .2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(tabs.length, (index) {
                    return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: activeTab == tabs[index]
                                    ? Color(0xFF294EC3)
                                    : Colors.transparent,
                                width: activeTab == tabs[index] ? 2 : 0),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              activeTab = tabs[index];
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: activeTab == tabs[index]
                                ? Color(0xFF294EC3)
                                : Color(0xFF444750),
                            textStyle: TextStyle(fontSize: 14),
                          ),
                          child: Text(tabs[index]),
                        ));
                  }),
                )),
            const SizedBox(height: 10),
            account?.accountHolderName != null &&
                    account?.accountHolderName != null &&
                    account?.bankId != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            color: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            elevation: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF172B6D), // Your first color
                                    Color(0xFF274AB9), // Your second color
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 28.0, 16.0, 28.0),
                                child: Column(
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.asset(
                                                AppConstants.banks
                                                    .firstWhere((element) =>
                                                        element.id ==
                                                        account?.bankId)
                                                    .image,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        AppConstants.banks
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .id ==
                                                                    account
                                                                        ?.bankId)
                                                            .name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                              Color(0xFFF7F8FB),
                                                          // Subtle text color
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            isExpanded =
                                                                !isExpanded;
                                                          });
                                                        },
                                                        child: Icon(
                                                          isExpanded
                                                              ? Icons
                                                                  .arrow_drop_up
                                                              : Icons
                                                                  .arrow_drop_down,
                                                          color: Colors.white,
                                                          size: 28,
                                                        ))
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ),
                                                Text(
                                                  account?.accountNumber ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF9FABD2),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ),
                                                Text(
                                                  account?.accountHolderName ??
                                                      '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF9FABD2),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      account?.totalCredit !=
                                                                  null &&
                                                              account?.totalDebit !=
                                                                  null
                                                          ? ((account!.totalCredit) -
                                                                  (account!
                                                                      .totalDebit))
                                                              .toString()
                                                          : '0 ETB',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            Color(0xFFF7F8FB),
                                                        // Subtle text color
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    GestureDetector(
                                                        onTap: () {
                                                          setState(() {});
                                                        },
                                                        child: Icon(
                                                            Icons
                                                                .remove_red_eye_outlined,
                                                            color: Colors
                                                                .grey[400],
                                                            size:
                                                                20)) // Add spacing between icon and text
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        ]),
                                    isExpanded
                                        ? Column(
                                            children: [
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceBetween, // Centers horizontally
                                                children: [
                                                  Text(
                                                    "Total Credit",
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                      account?.totalCredit
                                                              .toString() ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      )),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceBetween, // Centers horizontally
                                                children: [
                                                  Text(
                                                    "Total Debit",
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                      account?.totalDebit
                                                              .toString() ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      )),
                                                ],
                                              )
                                            ],
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                            )),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search for Transactions',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w300,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade400, width: 1),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade400, width: 1),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.blue, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: MediaQuery.of(context).size.height *
                                  0.5, // ✅ Give height

                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  Transaction transaction = transactions[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: ListTile(
                                      title: Text(transaction.reference),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Creditor: ${transaction.creditor}'),
                                          Text(
                                              'Receiver: ${transaction.receiver}'),
                                          Text(
                                              'Amount: ${transaction.amount} ETB'),
                                          Text(
                                              'Date: ${transaction.time.toLocal()}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ]),
                        ),
                      ])
                : Container(),
          ],
        )));
  }
}

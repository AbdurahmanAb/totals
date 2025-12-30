import 'dart:convert';

class Account {
  final String accountNumber;
  final int bank; // Mapped to 'bank' in JSON
  final double balance;
  final String accountHolderName;
  final double? settledBalance;
  final double? pendingCredit;
  final int? profileId;

  Account({
    required this.accountNumber,
    required this.bank,
    required this.balance,
    required this.accountHolderName,
    this.settledBalance,
    this.pendingCredit,
    this.profileId,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountNumber: json['accountNumber'],
      bank: json['bank'],
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      accountHolderName: json['accountHolderName'],
      settledBalance: json['settledBalance']?.toDouble(),
      pendingCredit: json['pendingCredit']?.toDouble(),
      profileId: json['profileId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'bank': bank,
      'balance': balance,
      'accountHolderName': accountHolderName,
      'settledBalance': settledBalance,
      'pendingCredit': pendingCredit,
      if (profileId != null) 'profileId': profileId,
    };
  }

  static String encode(List<Account> accounts) => json.encode(
        accounts.map<Map<String, dynamic>>((a) => a.toJson()).toList(),
      );

  static List<Account> decode(String accounts) =>
      (json.decode(accounts) as List<dynamic>)
          .map<Account>((item) => Account.fromJson(item))
          .toList();
}

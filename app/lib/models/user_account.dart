class UserAccount {
  final int? id;
  final String accountNumber;
  final int bankId;
  final String accountHolderName;
  final String createdAt;

  UserAccount({
    this.id,
    required this.accountNumber,
    required this.bankId,
    required this.accountHolderName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'accountNumber': accountNumber,
      'bankId': bankId,
      'accountHolderName': accountHolderName,
      'createdAt': createdAt,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as int?,
      accountNumber: json['accountNumber'] as String,
      bankId: json['bankId'] as int,
      accountHolderName: json['accountHolderName'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

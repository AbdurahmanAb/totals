import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:totals/database/database_helper.dart';
import 'package:totals/models/account.dart';

class AccountRepository {
  Future<List<Account>> getAccounts() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return maps.map((map) {
      return Account.fromJson({
        'accountNumber': map['accountNumber'],
        'bank': map['bank'],
        'balance': map['balance'],
        'accountHolderName': map['accountHolderName'],
        'settledBalance': map['settledBalance'],
        'pendingCredit': map['pendingCredit'],
      });
    }).toList();
  }

  Future<void> saveAccount(Account account) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'accounts',
      {
        'accountNumber': account.accountNumber,
        'bank': account.bank,
        'balance': account.balance,
        'accountHolderName': account.accountHolderName,
        'settledBalance': account.settledBalance,
        'pendingCredit': account.pendingCredit,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAllAccounts(List<Account> accounts) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (var account in accounts) {
      batch.insert(
        'accounts',
        {
          'accountNumber': account.accountNumber,
          'bank': account.bank,
          'balance': account.balance,
          'accountHolderName': account.accountHolderName,
          'settledBalance': account.settledBalance,
          'pendingCredit': account.pendingCredit,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<bool> accountExists(String accountNumber, int bank) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'accounts',
      where: 'accountNumber = ? AND bank = ?',
      whereArgs: [accountNumber, bank],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> clearAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('accounts');
  }
}

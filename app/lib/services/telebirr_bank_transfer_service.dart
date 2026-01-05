import 'package:totals/models/bank.dart';
import 'package:totals/models/transaction.dart';

class TelebirrBankTransferMatch {
  final Transaction telebirrTransaction;
  final Transaction bankTransaction;
  final Bank bank;
  final Duration timeDelta;

  TelebirrBankTransferMatch({
    required this.telebirrTransaction,
    required this.bankTransaction,
    required this.bank,
    required this.timeDelta,
  });
}

class TelebirrBankTransferService {
  static const int _telebirrBankId = 6;
  static const Duration matchWindow = Duration(minutes: 10);
  static const double amountTolerance = 0.01;

  List<TelebirrBankTransferMatch> findMatches(
    List<Transaction> transactions,
    List<Bank> banks,
  ) {
    final banksById = {for (final bank in banks) bank.id: bank};
    final tokensByBankId = {
      for (final bank in banks) bank.id: _tokensForBank(bank),
    };

    final bankDebitsById = <int, List<Transaction>>{};
    for (final transaction in transactions) {
      final bankId = transaction.bankId;
      if (bankId == null || bankId == _telebirrBankId) continue;
      if (transaction.type != 'DEBIT') continue;
      bankDebitsById.putIfAbsent(bankId, () => []).add(transaction);
    }

    final telebirrCredits = transactions.where((transaction) {
      return transaction.bankId == _telebirrBankId &&
          transaction.type == 'CREDIT' &&
          (transaction.creditor?.trim().isNotEmpty ?? false);
    }).toList();

    telebirrCredits.sort((a, b) {
      final timeA = _parseTime(a.time);
      final timeB = _parseTime(b.time);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });

    final usedBankReferences = <String>{};
    final matches = <TelebirrBankTransferMatch>[];

    for (final telebirrTx in telebirrCredits) {
      final sender = telebirrTx.creditor?.trim();
      if (sender == null || sender.isEmpty) continue;

      final senderBank = _bankFromSender(sender, banks, tokensByBankId);
      if (senderBank == null) continue;

      final telebirrTime = _parseTime(telebirrTx.time);
      if (telebirrTime == null) continue;

      final candidates = bankDebitsById[senderBank.id] ?? const [];
      Transaction? bestMatch;
      Duration? bestDelta;

      for (final bankTx in candidates) {
        if (usedBankReferences.contains(bankTx.reference)) continue;
        if (!_amountMatches(telebirrTx.amount, bankTx.amount)) continue;

        final bankTime = _parseTime(bankTx.time);
        if (bankTime == null) continue;

        final delta = telebirrTime.difference(bankTime).abs();
        if (delta > matchWindow) continue;

        if (bestDelta == null || delta < bestDelta) {
          bestDelta = delta;
          bestMatch = bankTx;
        }
      }

      if (bestMatch != null && bestDelta != null) {
        usedBankReferences.add(bestMatch.reference);
        matches.add(
          TelebirrBankTransferMatch(
            telebirrTransaction: telebirrTx,
            bankTransaction: bestMatch,
            bank: banksById[senderBank.id] ?? senderBank,
            timeDelta: bestDelta,
          ),
        );
      }
    }

    return matches;
  }

  static bool _amountMatches(double a, double b) {
    return (a - b).abs() <= amountTolerance;
  }

  static DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static Bank? _bankFromSender(
    String sender,
    List<Bank> banks,
    Map<int, Set<String>> tokensByBankId,
  ) {
    final normalizedSender = _normalizeToken(sender);
    for (final bank in banks) {
      if (bank.id == _telebirrBankId) continue;
      final tokens = tokensByBankId[bank.id];
      if (tokens == null || tokens.isEmpty) continue;
      for (final token in tokens) {
        if (token.isEmpty) continue;
        if (normalizedSender.contains(token)) {
          return bank;
        }
      }
    }
    return null;
  }

  static Set<String> _tokensForBank(Bank bank) {
    final tokens = <String>{};
    tokens.add(_normalizeToken(bank.name));
    tokens.add(_normalizeToken(bank.shortName));
    for (final code in bank.codes) {
      tokens.add(_normalizeToken(code));
    }
    tokens.removeWhere((token) => token.length < 2);
    return tokens;
  }

  static String _normalizeToken(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

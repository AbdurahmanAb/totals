import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/models/account.dart';
import 'package:totals/repositories/account_repository.dart';

/// Handler for account-related API endpoints
class AccountsHandler {
  final AccountRepository _accountRepo = AccountRepository();

  /// Returns a configured router with all account routes
  Router get router {
    final router = Router();

    // GET /api/accounts - List all accounts with bank info
    router.get('/', _getAccounts);

    // GET /api/accounts/<bankId>/<accountNumber> - Get single account
    router.get('/<bankId>/<accountNumber>', _getAccountByIdAndNumber);

    return router;
  }

  /// GET /api/accounts
  /// Returns all accounts enriched with bank information
  Future<Response> _getAccounts(Request request) async {
    try {
      final accounts = await _accountRepo.getAccounts();

      final enrichedAccounts = accounts.map((account) {
        return _enrichAccountWithBankInfo(account);
      }).toList();

      return Response.ok(
        jsonEncode(enrichedAccounts),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch accounts: $e', 500);
    }
  }

  /// GET /api/accounts/:bankId/:accountNumber
  /// Returns a single account by bank ID and account number
  Future<Response> _getAccountByIdAndNumber(
    Request request,
    String bankId,
    String accountNumber,
  ) async {
    try {
      final parsedBankId = int.tryParse(bankId);
      if (parsedBankId == null) {
        return _errorResponse('Invalid bank ID', 400);
      }

      final accounts = await _accountRepo.getAccounts();

      final account = accounts.cast<Account?>().firstWhere(
            (a) => a!.bank == parsedBankId && a.accountNumber == accountNumber,
            orElse: () => null,
          );

      if (account == null) {
        return _errorResponse('Account not found', 404);
      }

      final enrichedAccount = _enrichAccountWithBankInfo(account);

      return Response.ok(
        jsonEncode(enrichedAccount),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to fetch account: $e', 500);
    }
  }

  /// Enriches an Account with bank name, short name, and image
  Map<String, dynamic> _enrichAccountWithBankInfo(Account account) {
    final bank = _getBankById(account.bank);

    return {
      'accountNumber': account.accountNumber,
      'bank': account.bank,
      'bankName': bank?.name ?? 'Unknown Bank',
      'bankShortName': bank?.shortName ?? 'N/A',
      'bankImage': bank?.image ?? '',
      'balance': account.balance,
      'accountHolderName': account.accountHolderName,
      'settledBalance': account.settledBalance,
      'pendingCredit': account.pendingCredit,
    };
  }

  /// Finds a bank by ID from AppConstants
  Bank? _getBankById(int bankId) {
    try {
      return AppConstants.banks.firstWhere((b) => b.id == bankId);
    } catch (e) {
      return null;
    }
  }

  /// Helper to create standardized error responses
  Response _errorResponse(String message, int statusCode) {
    return Response(
      statusCode,
      body: jsonEncode({
        'error': true,
        'message': message,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

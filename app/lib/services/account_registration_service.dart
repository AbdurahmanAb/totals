import 'package:another_telephony/telephony.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/models/account.dart';
import 'package:totals/repositories/account_repository.dart';
import 'package:totals/services/sms_service.dart';
import 'package:totals/services/sms_config_service.dart';
import 'package:totals/utils/pattern_parser.dart';

class AccountRegistrationService {
  final AccountRepository _accountRepo = AccountRepository();

  /// Registers a new account and optionally syncs previous SMS messages
  Future<void> registerAccount({
    required String accountNumber,
    required String accountHolderName,
    required int bankId,
    bool syncPreviousSms = true,
    Function(String stage, double progress)? onProgress,
  }) async {
    // Check if account already exists
    onProgress?.call("Checking account...", 0.1);
    final exists = await _accountRepo.accountExists(accountNumber, bankId);
    if (exists) {
      print("debug: Account $accountNumber for bank $bankId already exists");
      onProgress?.call("Account already exists", 1.0);
      return;
    }

    // Create and save the account
    onProgress?.call("Registering account...", 0.2);
    final account = Account(
      accountNumber: accountNumber,
      bank: bankId,
      balance: 0.0,
      accountHolderName: accountHolderName,
    );
    await _accountRepo.saveAccount(account);
    print("debug: Account registered: $accountNumber");

    // Sync previous SMS if requested
    if (syncPreviousSms) {
      await _syncPreviousSms(bankId, onProgress);
    } else {
      onProgress?.call("Complete!", 1.0);
    }
  }

  /// Syncs and parses previous SMS messages from the bank
  Future<void> _syncPreviousSms(
    int bankId,
    Function(String stage, double progress)? onProgress,
  ) async {
    onProgress?.call("Finding bank messages...", 0.3);
    final bank = AppConstants.banks.firstWhere(
      (element) => element.id == bankId,
      orElse: () => throw Exception("Bank with id $bankId not found"),
    );

    final bankCodes = bank.codes;
    print("debug: Syncing SMS for bank ${bank.name} with codes: $bankCodes");

    onProgress?.call("Fetching SMS messages...", 0.4);

    // Get all messages from the bank
    final Telephony telephony = Telephony.instance;
    List<SmsMessage> allMessages = [];

    // Query messages for each bank code
    // Fetch all messages and filter by bank codes (since exact match may miss variations)
    try {
      print("debug: bankId: $bankId");
      final allSms = await telephony.getInboxSms(
        columns: const [
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      // Filter messages that match any bank code
      final filtered = allSms.where((message) {
        if (message.address == null) return false;
        final address = message.address!.toLowerCase();
        return bankCodes.any((code) => address.contains(code.toLowerCase()));
      }).toList();

      allMessages.addAll(filtered);
    } catch (e) {
      print("debug: Error fetching SMS: $e");
    }

    // Remove duplicates based on body and address
    final uniqueMessages = <String, SmsMessage>{};
    for (var msg in allMessages) {
      final key = '${msg.address}_${msg.body}';
      if (!uniqueMessages.containsKey(key)) {
        uniqueMessages[key] = msg;
      }
    }

    final messages = uniqueMessages.values.toList();
    print("debug: Found ${messages.length} unique messages from ${bank.name}");

    if (messages.isEmpty) {
      onProgress?.call("No messages found", 1.0);
      return;
    }

    onProgress?.call("Loading parsing patterns...", 0.5);

    // Load patterns for this bank
    final configService = SmsConfigService();
    final patterns = await configService.getPatterns();
    final relevantPatterns = patterns.where((p) => p.bankId == bankId).toList();

    if (relevantPatterns.isEmpty) {
      print("debug: No patterns found for bank $bankId, skipping parsing");
      onProgress?.call("No patterns found", 1.0);
      return;
    }

    onProgress?.call("Parsing messages...", 0.6);

    // Process each message
    int processedCount = 0;
    int skippedCount = 0;
    final totalMessages = messages.length;

    // Track the latest message with balance for account update
    Map<String, dynamic>? latestBalanceDetails;
    String? latestAccountNumber;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];

      // Update progress based on message index
      final baseProgress = 0.6;
      final messageProgress = (i + 1) / totalMessages;
      final currentProgress = baseProgress + (messageProgress * 0.35);
      onProgress?.call(
        "Processing message ${i + 1} of $totalMessages...",
        currentProgress,
      );

      if (message.body == null || message.address == null) {
        skippedCount++;
        continue;
      }

      try {
        // Check if message matches any pattern
        final cleanedBody = configService.cleanSmsText(message.body!);
        final details = PatternParser.extractTransactionDetails(
          cleanedBody,
          message.address!,
          relevantPatterns,
        );

        if (details != null) {
          // Track the latest message with balance (messages are sorted DESC, so first match is latest)
          if (details['currentBalance'] != null &&
              latestBalanceDetails == null) {
            latestBalanceDetails = details;
            latestAccountNumber = details['accountNumber'];
          }

          // Convert message date from milliseconds to DateTime
          DateTime? messageDate;
          if (message.date != null) {
            messageDate = DateTime.fromMillisecondsSinceEpoch(message.date!);
          }

          // Process the message using the existing SmsService logic with message date
          await SmsService.processMessage(
            message.body!,
            message.address!,
            messageDate: messageDate,
          );
          processedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        print("debug: Error processing message: $e");
        skippedCount++;
      }
    }

    // Update account balance from the latest message
    if (latestBalanceDetails != null) {
      onProgress?.call("Updating account balance...", 0.95);
      await _updateAccountBalanceFromLatestMessage(
        bankId,
        latestBalanceDetails,
        latestAccountNumber,
      );
    }

    onProgress?.call(
      "Complete! Processed $processedCount transactions",
      1.0,
    );

    print(
        "debug: SMS sync complete - Processed: $processedCount, Skipped: $skippedCount");
  }

  /// Updates account balance from the latest message
  Future<void> _updateAccountBalanceFromLatestMessage(
    int bankId,
    Map<String, dynamic> details,
    String? extractedAccountNumber,
  ) async {
    try {
      final accounts = await _accountRepo.getAccounts();
      int bankIdFromDetails = details['bankId'] ?? bankId;

      // Use the same logic as SmsService for matching accounts
      if (bankIdFromDetails == 6) {
        // For bank 6 (Telebirr), match by bank only
        final index = accounts.indexWhere((a) => a.bank == bankIdFromDetails);
        if (index != -1) {
          final account = accounts[index];
          final newBalance = details['currentBalance'] != null
              ? SmsService.sanitizeAmount(details['currentBalance'])
              : account.balance;

          final updated = Account(
            accountNumber: account.accountNumber,
            bank: account.bank,
            balance: newBalance,
            accountHolderName: account.accountHolderName,
            settledBalance: account.settledBalance,
            pendingCredit: account.pendingCredit,
          );
          await _accountRepo.saveAccount(updated);
          print(
              "debug: Account balance updated from latest message: $newBalance");
        }
      } else if (extractedAccountNumber != null) {
        // For other banks, match by bank and account number
        final index = accounts.indexWhere((a) {
          if (a.bank != bankIdFromDetails) return false;
          return a.accountNumber.endsWith(extractedAccountNumber);
        });

        if (index != -1) {
          final account = accounts[index];
          final newBalance = details['currentBalance'] != null
              ? SmsService.sanitizeAmount(details['currentBalance'])
              : account.balance;

          final updated = Account(
            accountNumber: account.accountNumber,
            bank: account.bank,
            balance: newBalance,
            accountHolderName: account.accountHolderName,
            settledBalance: account.settledBalance,
            pendingCredit: account.pendingCredit,
          );
          await _accountRepo.saveAccount(updated);
          print(
              "debug: Account balance updated from latest message for ${account.accountHolderName}: $newBalance");
        }
      }
    } catch (e) {
      print("debug: Error updating account balance from latest message: $e");
    }
  }
}

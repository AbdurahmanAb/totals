import 'package:totals/data/consts.dart';

class SmsUtils {
  static Map<String, dynamic> extractCBETransactionDetails(String message) {
    String type =
        message.toLowerCase().contains("credited") ? "CREDIT" : "DEBIT";
    if (type == "CREDIT") {
      double? creditedAmount;
      String startKeyword = "ETB";
      String endKeyword = "Your Current";

      int startIndex = message.indexOf(startKeyword);
      int endIndex = message.indexOf(endKeyword);

      if (startIndex != -1 && endIndex != -1) {
        startIndex += startKeyword.length; // Move index past "ETB"
        String extracted = message.substring(startIndex, endIndex).trim();
        extracted = extracted.replaceAll(",", "");
        if (extracted.endsWith(".")) {
          extracted = extracted.substring(0, extracted.length - 1);
        }

        print("Credited Amount: ETB $extracted");
        creditedAmount = double.tryParse(extracted.trim());
      }
      String? last4Digits;

      String transactionKeyword = "?id=";
      String accountKeyword = "your Account ";
      int transactionStart =
          message.indexOf(transactionKeyword) + transactionKeyword.length;
      String transactionId = message.contains("?id=")
          ? message.substring(transactionStart).split(" ")[0]
          : "";

      int accountStart = message.indexOf(accountKeyword);
      if (accountStart != -1) {
        accountStart += accountKeyword.length;
        List<String> parts = message.substring(accountStart).split(" ");
        if (parts.isNotEmpty) {
          String maskedAccount = parts[0]; // e.g., "1*****6068"
          if (maskedAccount.length >= 4) {
            last4Digits = maskedAccount.substring(maskedAccount.length - 4);
          }
        }
      }
      String? currentBalance;
      String balanceStartKeywordd = "Balance is ETB";
      String balanceEndKeyword = "Thank";

      int balanceStartIndex = message.indexOf(balanceStartKeywordd);
      int balanceEndIndex = message.indexOf(balanceEndKeyword);

      if (balanceStartIndex != -1 && balanceEndIndex != -1) {
        balanceStartIndex += balanceStartKeywordd.length;
        String extracted =
            message.substring(balanceStartIndex, balanceEndIndex);
        extracted = extracted.replaceAll(",", "");
        if (extracted.endsWith(".")) {
          extracted = extracted.substring(0, extracted.length - 1);
        }

        print("Current Balance: ETB $extracted");
        currentBalance = extracted.trim();
        if (currentBalance.endsWith(".")) {
          currentBalance =
              currentBalance.substring(0, currentBalance.length - 1);
        }
      }

      print("Credited amount: $creditedAmount");
      print("current balance : $currentBalance");
      print("Transaction ID: $transactionId");
      print("Last 4 digits: $last4Digits");

      return {
        "amount": creditedAmount,
        "reference": transactionId,
        "currentBalance": currentBalance,
        "bankId": 1,
        "type": "CREDIT",
        "transactionLink": "https://apps.cbe.come.et:100/?id=${transactionId}",
        "time": DateTime.now().toString(),
        "accountNumber": last4Digits
      };
    }

    String transactionKeyword = "?id=";
    String accountKeyword = "your Account ";

    double? totalDebited;
    String? transactionId;
    String? last4Digits;

    String startKeyword = "total of";
    String endKeyword = "Your Current";

    int startIndex = message.indexOf(startKeyword);
    int endIndex = message.indexOf(endKeyword);

    if (startIndex != -1 && endIndex != -1) {
      startIndex += startKeyword.length;
      String extracted = message.substring(startIndex, endIndex).trim();

      // Remove all non-numeric characters except for "."
      String cleaned = "";
      for (int i = 0; i < extracted.length; i++) {
        if ((extracted[i].codeUnitAt(0) >= 48 &&
                extracted[i].codeUnitAt(0) <= 57) ||
            extracted[i] == '.') {
          cleaned += extracted[i];
        }
      }
      if (cleaned.endsWith(".")) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }

      print("Extracted Amount: $cleaned");
      totalDebited = double.tryParse(cleaned.trim());
    } else {
      print("Keywords not found.");
    }
    int transactionStart = message.indexOf(transactionKeyword);
    if (transactionStart != -1) {
      transactionStart += transactionKeyword.length;
      transactionId = message.substring(transactionStart).split(" ")[0];
    }

    int accountStart = message.indexOf(accountKeyword);
    if (accountStart != -1) {
      accountStart += accountKeyword.length;
      List<String> parts = message.substring(accountStart).split(" ");
      if (parts.isNotEmpty) {
        String maskedAccount = parts[0];
        if (maskedAccount.length >= 4) {
          last4Digits = maskedAccount.substring(maskedAccount.length - 4);
        }
      }
    }
    String? currentBalance;
    String balanceStartKeywordd = "Balance is ETB";
    String balanceEndKeyword = "Thank";

    int balanceStartIndex = message.indexOf(balanceStartKeywordd);
    int balanceEndIndex = message.indexOf(balanceEndKeyword);

    if (balanceStartIndex != -1 && balanceEndIndex != -1) {
      balanceStartIndex += balanceStartKeywordd.length;
      String extracted = message.substring(balanceStartIndex, balanceEndIndex);
      extracted = extracted.replaceAll(",", "");
      if (extracted.endsWith(".")) {
        extracted = extracted.substring(0, extracted.length - 1);
      }

      print("Current Balance: ETB $extracted");
      currentBalance = extracted.trim();
      currentBalance = extracted.trim();
      if (currentBalance.endsWith(".")) {
        currentBalance = currentBalance.substring(0, currentBalance.length - 1);
      }
    }

    return {
      "amount": totalDebited,
      "reference": transactionId,
      "currentBalance": currentBalance,
      "bankId": 1,
      "type": "DEBIT",
      "transactionLink": "https://apps.cbe.come.et:100/?id=${transactionId}",
      "time": DateTime.now().toString(),
      "accountNumber": last4Digits
    };
  }
}

class CashConstants {
  static const int bankId = 100;
  static const String bankName = 'Cash';
  static const String bankShortName = 'Cash';
  static const String bankImage = 'assets/images/cash.png';
  static const List<String> bankColors = ['#0f766e', '#14b8a6'];
  static const String defaultAccountNumber = 'CASH';
  static const String defaultAccountHolderName = 'Cash Wallet';
  static const String atmReferencePrefix = 'cash_atm_';
  static const String manualReferencePrefix = 'cash_manual_';

  static String buildAtmReference(String bankReference) {
    return '$atmReferencePrefix$bankReference';
  }

  static String buildManualReference(int micros) {
    return '$manualReferencePrefix$micros';
  }
}

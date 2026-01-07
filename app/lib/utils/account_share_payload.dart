import 'dart:convert';

class AccountShareEntry {
  final int bankId;
  final String accountNumber;

  const AccountShareEntry({
    required this.bankId,
    required this.accountNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'bankId': bankId,
      'accountNumber': accountNumber,
    };
  }

  static AccountShareEntry? tryFromJson(Map<String, dynamic> json) {
    final bankId = _asInt(json['bankId']);
    final accountNumber = json['accountNumber']?.toString().trim();
    if (bankId == null || accountNumber == null || accountNumber.isEmpty) {
      return null;
    }
    return AccountShareEntry(
      bankId: bankId,
      accountNumber: accountNumber,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class AccountSharePayload {
  static const int currentVersion = 1;
  static const String prefix = 'totals:accounts:';

  final int version;
  final String name;
  final List<AccountShareEntry> accounts;

  const AccountSharePayload({
    this.version = currentVersion,
    required this.name,
    required this.accounts,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'accounts': accounts.map((entry) => entry.toJson()).toList(),
    };
  }

  static String encode(AccountSharePayload payload) {
    final jsonString = jsonEncode(payload.toJson());
    final encoded = base64UrlEncode(utf8.encode(jsonString));
    return '$prefix$encoded';
  }

  static AccountSharePayload? decode(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(prefix)) return null;
    final encoded = trimmed.substring(prefix.length);
    if (encoded.isEmpty) return null;
    try {
      final decoded = utf8.decode(base64Url.decode(encoded));
      final jsonValue = jsonDecode(decoded);
      if (jsonValue is! Map<String, dynamic>) return null;
      return tryFromJson(jsonValue);
    } catch (_) {
      return null;
    }
  }

  static AccountSharePayload? tryFromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim();
    if (name == null || name.isEmpty) return null;
    final rawAccounts = json['accounts'];
    if (rawAccounts is! List) return null;

    final entries = <AccountShareEntry>[];
    for (final entry in rawAccounts) {
      if (entry is Map<String, dynamic>) {
        final parsed = AccountShareEntry.tryFromJson(entry);
        if (parsed != null) entries.add(parsed);
      }
    }
    if (entries.isEmpty) return null;

    final version = _asInt(json['version']) ?? currentVersion;
    return AccountSharePayload(
      version: version,
      name: name,
      accounts: entries,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

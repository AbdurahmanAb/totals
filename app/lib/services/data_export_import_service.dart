import 'dart:convert';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:totals/database/database_helper.dart';
import 'package:totals/models/account.dart';
import 'package:totals/models/category.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/models/failed_parse.dart';
import 'package:totals/models/sms_pattern.dart';
import 'package:totals/repositories/account_repository.dart';
import 'package:totals/repositories/category_repository.dart';
import 'package:totals/repositories/transaction_repository.dart';
import 'package:totals/repositories/failed_parse_repository.dart';
import 'package:totals/services/sms_config_service.dart';

class DataExportImportService {
  final AccountRepository _accountRepo = AccountRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final FailedParseRepository _failedParseRepo = FailedParseRepository();
  final SmsConfigService _smsConfigService = SmsConfigService();

  /// Export all data to JSON
  Future<String> exportAllData() async {
    try {
      final accounts = await _accountRepo.getAccounts();
      final categories = await _categoryRepo.getCategories();
      final transactions = await _transactionRepo.getTransactions();
      final failedParses = await _failedParseRepo.getAll();
      final smsPatterns = await _smsConfigService.getPatterns();

      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'failedParses': failedParses.map((f) => f.toJson()).toList(),
        'smsPatterns': smsPatterns.map((p) => p.toJson()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Import all data from JSON (appends to existing data)
  Future<void> importAllData(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      final db = await DatabaseHelper.instance.database;

      // Validate version (for future compatibility)
      final version = data['version'] ?? '1.0';

      String normalizedFlow(String? flow) {
        final normalized = flow?.trim().toLowerCase();
        return normalized == 'income' ? 'income' : 'expense';
      }

      String categoryKey(String name, String flow) {
        return '${name.trim().toLowerCase()}|${normalizedFlow(flow)}';
      }

      final Map<int, int> categoryIdMap = {};

      // Import categories (append, skip duplicates)
      if (data['categories'] != null) {
        final categoriesList = (data['categories'] as List)
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();

        final existingCategories = await _categoryRepo.getCategories();
        final builtInKeyMap = <String, Category>{};
        final nameFlowMap = <String, Category>{};

        for (final category in existingCategories) {
          final builtInKey = category.builtInKey?.trim();
          if (builtInKey != null && builtInKey.isNotEmpty) {
            builtInKeyMap[builtInKey] = category;
          }
          nameFlowMap[categoryKey(category.name, category.flow)] = category;
        }

        for (final category in categoriesList) {
          final exportId = category.id;
          final name = category.name.trim();
          if (name.isEmpty) {
            continue;
          }

          final builtInKey = category.builtInKey?.trim();
          final flow = normalizedFlow(category.flow);
          final key = categoryKey(name, flow);
          final isBuiltIn =
              builtInKey != null && builtInKey.isNotEmpty ? true : category.builtIn;

          Category? existing;
          if (builtInKey != null && builtInKey.isNotEmpty) {
            existing = builtInKeyMap[builtInKey];
          }
          existing ??= nameFlowMap[key];

          if (existing != null) {
            if (exportId != null && existing.id != null) {
              categoryIdMap[exportId] = existing.id!;
            }
            continue;
          }

          final insertId = await db.insert(
            'categories',
            {
              'name': name,
              'essential': category.essential ? 1 : 0,
              'uncategorized': category.uncategorized ? 1 : 0,
              'iconKey': category.iconKey,
              'description': category.description,
              'flow': flow,
              'recurring': category.recurring ? 1 : 0,
              'builtIn': isBuiltIn ? 1 : 0,
              'builtInKey': category.builtInKey,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          int? resolvedId = insertId == 0 ? null : insertId;
          if (resolvedId == null) {
            List<Map<String, dynamic>> match = [];
            if (builtInKey != null && builtInKey.isNotEmpty) {
              match = await db.query(
                'categories',
                columns: ['id'],
                where: 'builtInKey = ?',
                whereArgs: [builtInKey],
                limit: 1,
              );
            }
            if (match.isEmpty) {
              match = await db.query(
                'categories',
                columns: ['id'],
                where: 'name = ? COLLATE NOCASE AND flow = ?',
                whereArgs: [name, flow],
                limit: 1,
              );
            }
            if (match.isNotEmpty) {
              resolvedId = match.first['id'] as int?;
            }
          }

          if (resolvedId != null) {
            if (exportId != null) {
              categoryIdMap[exportId] = resolvedId;
            }
            final insertedCategory =
                category.copyWith(id: resolvedId, flow: flow, builtIn: isBuiltIn);
            if (builtInKey != null && builtInKey.isNotEmpty) {
              builtInKeyMap[builtInKey] = insertedCategory;
            }
            nameFlowMap[key] = insertedCategory;
          }
        }
      }

      // Import accounts (append, skip duplicates)
      // Use repository to ensure they're associated with active profile
      if (data['accounts'] != null) {
        final accountsList = (data['accounts'] as List)
            .map((json) => Account.fromJson(json as Map<String, dynamic>))
            .toList();
        // Use saveAllAccounts which will auto-associate with active profile
        await _accountRepo.saveAllAccounts(accountsList);
      }

      // Import transactions (append, skip duplicates based on reference)
      // Use repository to ensure they're associated with active profile
      if (data['transactions'] != null) {
        final transactionsList = (data['transactions'] as List)
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .map((transaction) {
              final categoryId = transaction.categoryId;
              if (categoryId == null) return transaction;
              final mappedId = categoryIdMap[categoryId];
              if (mappedId == null || mappedId == categoryId) {
                return transaction;
              }
              return transaction.copyWith(categoryId: mappedId);
            })
            .toList();
        // Use saveAllTransactions which will auto-associate with active profile
        await _transactionRepo.saveAllTransactions(transactionsList);
      }

      // Import failed parses (append)
      if (data['failedParses'] != null) {
        final batch = db.batch();
        for (var json in data['failedParses'] as List) {
          final failedParse = FailedParse.fromJson(json as Map<String, dynamic>);
          batch.insert('failed_parses', {
            'address': failedParse.address,
            'body': failedParse.body,
            'reason': failedParse.reason,
            'timestamp': failedParse.timestamp,
          });
        }
        await batch.commit(noResult: true);
      }

      // Import SMS patterns (replace - these are configuration)
      if (data['smsPatterns'] != null) {
        final patternsList = (data['smsPatterns'] as List)
            .map((json) => SmsPattern.fromJson(json as Map<String, dynamic>))
            .toList();
        await _smsConfigService.savePatterns(patternsList);
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
}


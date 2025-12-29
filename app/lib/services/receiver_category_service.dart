import 'package:sqflite/sqflite.dart';
import 'package:totals/database/database_helper.dart';

class ReceiverCategoryService {
  static final ReceiverCategoryService instance = ReceiverCategoryService._();
  ReceiverCategoryService._();

  /// Save or update a mapping from account number to category
  /// accountType should be 'receiver' or 'creditor'
  Future<void> saveMapping(
    String accountNumber,
    int categoryId,
    String accountType,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'receiver_category_mappings',
      {
        'accountNumber': accountNumber,
        'categoryId': categoryId,
        'accountType': accountType,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get category ID for a given account number and type
  /// Returns null if no mapping exists
  Future<int?> getCategoryForAccount(
    String accountNumber,
    String accountType,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'receiver_category_mappings',
      columns: ['categoryId'],
      where: 'accountNumber = ? AND accountType = ?',
      whereArgs: [accountNumber, accountType],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['categoryId'] as int?;
  }

  /// Get category ID for receiver (checks receiver first, then creditor)
  /// Returns null if no mapping exists
  Future<int?> getCategoryForTransaction({
    String? receiver,
    String? creditor,
  }) async {
    // Check receiver first
    if (receiver != null && receiver.isNotEmpty) {
      final categoryId = await getCategoryForAccount(receiver, 'receiver');
      if (categoryId != null) return categoryId;
    }

    // Fallback to creditor
    if (creditor != null && creditor.isNotEmpty) {
      final categoryId = await getCategoryForAccount(creditor, 'creditor');
      if (categoryId != null) return categoryId;
    }

    return null;
  }

  /// Delete a mapping for a specific account number and type
  Future<void> deleteMapping(String accountNumber, String accountType) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'receiver_category_mappings',
      where: 'accountNumber = ? AND accountType = ?',
      whereArgs: [accountNumber, accountType],
    );
  }

  /// Get all mappings (for debugging/admin purposes)
  Future<List<Map<String, dynamic>>> getAllMappings() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('receiver_category_mappings');
  }

  /// Clear all mappings
  Future<void> clearAllMappings() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('receiver_category_mappings');
  }
}

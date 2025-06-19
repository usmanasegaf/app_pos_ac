// lib/data/datasources/local/transaction_dao.dart

import 'dart:convert'; // For json.decode and json.encode
import 'package:sqflite/sqflite.dart';
import 'package:app_pos_ac/data/datasources/local/database_helper.dart'; // Import DatabaseHelper
import 'package:app_pos_ac/data/models/transaction.dart'; // Mengimpor model TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart'; // Mengimpor model TransactionItem
import 'package:app_pos_ac/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For provider

/// Data Access Object (DAO) for TransactionAC related database operations.
class TransactionDao {
  final DatabaseHelper _databaseHelper;

  TransactionDao(this._databaseHelper);

  /// Converts a Map from the database to a [TransactionAC] object.
  /// Handles deserialization of the 'items' JSON string back to List<TransactionItem>.
  TransactionAC _fromMap(Map<String, dynamic> map) {
    // Deserialize 'items' from JSON string back to List<TransactionItem>
    final List<dynamic> itemsJson = json.decode(map['items'] as String);
    final List<TransactionItem> items = itemsJson
        .map((itemMap) => TransactionItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return TransactionAC(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      customerName: map['customerName'] as String,
      customerAddress: map['customerAddress'] as String?,
      total: map['total'] as double,
      items: items,
    );
  }

  /// Converts a [TransactionAC] object to a Map for database operations.
  /// Handles serialization of List<TransactionItem> to JSON string for 'items' column.
  Map<String, dynamic> _toMap(TransactionAC transaction) {
    // Serialize List<TransactionItem> to JSON string
    final String itemsJson = json.encode(transaction.items.map((item) => item.toMap()).toList());

    return {
      'id': transaction.id,
      'date': transaction.date.toIso8601String(),
      'customerName': transaction.customerName,
      'customerAddress': transaction.customerAddress,
      'total': transaction.total,
      'items': itemsJson,
    };
  }

  /// Inserts a new transaction into the database.
  Future<int> insertTransaction(TransactionAC transaction) async {
    final db = await _databaseHelper.database;
    final Map<String, dynamic> data = _toMap(transaction);
    final int id = await db.insert(AppConstants.transactionsTableName, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  /// Retrieves all transactions from the database, ordered by date descending.
  Future<List<TransactionAC>> getTransactions() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  /// Retrieves transactions within a specific date range.
  /// Dates should be DateTime objects.
  Future<List<TransactionAC>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => _fromMap(maps[i]));
  }

  /// Retrieves a single transaction by its ID.
  Future<TransactionAC?> getTransactionById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _fromMap(maps.first);
    }
    return null;
  }

  /// Updates an existing transaction in the database.
  Future<int> updateTransaction(TransactionAC transaction) async {
    final db = await _databaseHelper.database;
    final Map<String, dynamic> data = _toMap(transaction);
    return await db.update(
      AppConstants.transactionsTableName,
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a transaction from the database by its ID.
  Future<int> deleteTransaction(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      AppConstants.transactionsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Provider for [TransactionDao].
/// Bergantung pada [databaseHelperProvider] yang menyediakan instance DatabaseHelper.
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return TransactionDao(databaseHelper);
});

// Anda mungkin perlu memastikan databaseHelperProvider ada, contohnya:
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

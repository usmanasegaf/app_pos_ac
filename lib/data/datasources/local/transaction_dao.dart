// lib/data/datasources/local/transaction_dao.dart

import 'package:sqflite/sqflite.dart'; // No 'hide' needed anymore!
import 'package:app_pos_ac/core/constants/app_constants.dart';
import 'package:app_pos_ac/data/datasources/local/database_helper.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // Now imports TransactionAC (from this file)

/// Data Access Object (DAO) for Transaction operations.
class TransactionDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserts a new [TransactionAC] into the database.
  /// Returns the ID of the newly inserted row.
  Future<int> insertTransaction(TransactionAC transaction) async { // Changed to TransactionAC
    final db = await _databaseHelper.database;
    return await db.insert(
      AppConstants.transactionsTableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all [TransactionAC]s from the database, ordered by date descending.
  Future<List<TransactionAC>> getTransactions() async { // Changed to TransactionAC
    final db = await _databaseHelper.database;
    // Order by date descending to show most recent transactions first.
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      orderBy: 'date DESC',
    );

    // Convert List<Map<String, dynamic>> to List<TransactionAC>.
    return List.generate(maps.length, (i) {
      return TransactionAC.fromMap(maps[i]); // Changed to TransactionAC
    });
  }

  /// Retrieves a single [TransactionAC] by its ID.
  Future<TransactionAC?> getTransactionById(int id) async { // Changed to TransactionAC
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TransactionAC.fromMap(maps.first); // Changed to TransactionAC
    }
    return null;
  }

  /// Updates an existing [TransactionAC] in the database.
  /// Returns the number of rows affected.
  Future<int> updateTransaction(TransactionAC transaction) async { // Changed to TransactionAC
    final db = await _databaseHelper.database;
    return await db.update(
      AppConstants.transactionsTableName,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Deletes a [TransactionAC] from the database by its ID.
  /// Returns the number of rows affected.
  Future<int> deleteTransaction(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      AppConstants.transactionsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

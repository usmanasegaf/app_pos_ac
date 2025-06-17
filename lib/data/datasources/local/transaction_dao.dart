// lib/data/datasources/local/transaction_dao.dart

import 'package:sqflite/sqflite.dart'; // No 'hide' needed anymore!
import 'package:app_pos_ac/core/constants/app_constants.dart';
import 'package:app_pos_ac/data/datasources/local/database_helper.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // Now imports TransactionAC (from this file)
import 'dart:developer'; // Import untuk menggunakan log

/// Data Access Object (DAO) for Transaction operations.
class TransactionDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserts a new [TransactionAC] into the database.
  /// Returns the ID of the newly inserted row.
  Future<int> insertTransaction(TransactionAC transaction) async {
    final db = await _databaseHelper.database;
    // Log data sebelum disimpan
    log('TransactionDao: Inserting transaction with total: ${transaction.total} and items: ${transaction.items.length}');
    log('TransactionDao: Transaction toMap data: ${transaction.toMap()}');

    final id = await db.insert(
      AppConstants.transactionsTableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('TransactionDao: Inserted transaction with ID: $id');
    return id;
  }

  /// Retrieves all [TransactionAC]s from the database, ordered by date descending.
  Future<List<TransactionAC>> getTransactions() async {
    final db = await _databaseHelper.database;
    // Order by date descending to show most recent transactions first.
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      orderBy: 'date DESC',
    );

    log('TransactionDao: Retrieved ${maps.length} transaction maps from DB.');

    // Convert List<Map<String, dynamic>> to List<TransactionAC>.
    return List.generate(maps.length, (i) {
      final transactionMap = maps[i];
      // Log data setelah diambil dari DB, sebelum konversi
      log('TransactionDao: Raw map for transaction ${transactionMap['id']}: $transactionMap');
      final transaction = TransactionAC.fromMap(transactionMap);
      // Log total setelah dikonversi ke model TransactionAC
      log('TransactionDao: Converted transaction ${transaction.id} total: ${transaction.total}');
      return transaction;
    });
  }

  /// Retrieves a single [TransactionAC] by its ID.
  Future<TransactionAC?> getTransactionById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.transactionsTableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final transactionMap = maps.first;
      log('TransactionDao: Raw map for single transaction $id: $transactionMap');
      final transaction = TransactionAC.fromMap(transactionMap);
      log('TransactionDao: Converted single transaction $id total: ${transaction.total}');
      return transaction;
    }
    return null;
  }

  /// Updates an existing [TransactionAC] in the database.
  /// Returns the number of rows affected.
  Future<int> updateTransaction(TransactionAC transaction) async {
    final db = await _databaseHelper.database;
    log('TransactionDao: Updating transaction ${transaction.id} with total: ${transaction.total}');
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
    log('TransactionDao: Deleting transaction with ID: $id');
    return await db.delete(
      AppConstants.transactionsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// lib/data/datasources/local/expense_dao.dart

import 'package:sqflite/sqflite.dart';
import 'package:app_pos_ac/data/datasources/local/database_helper.dart'; // Import DatabaseHelper
import 'package:app_pos_ac/data/models/expense.dart'; // Import Expense model
import 'package:app_pos_ac/core/constants/app_constants.dart'; // Import AppConstants
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For provider
import 'package:app_pos_ac/presentation/providers/database_providers.dart';

/// Data Access Object (DAO) for Expense related database operations.
class ExpenseDao {
  final DatabaseHelper _databaseHelper;

  ExpenseDao(this._databaseHelper);

  /// Inserts a new expense into the database.
  Future<int> insertExpense(Expense expense) async {
    final db = await _databaseHelper.database;
    final Map<String, dynamic> data = expense.toMap();
    final int id = await db.insert(AppConstants.expensesTableName, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  /// Retrieves all expenses from the database, ordered by date descending.
  Future<List<Expense>> getExpenses() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.expensesTableName,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  /// Retrieves expenses within a specific date range.
  /// Dates should be DateTime objects.
  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.expensesTableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  /// Retrieves a single expense by its ID.
  Future<Expense?> getExpenseById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.expensesTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  /// Updates an existing expense in the database.
  Future<int> updateExpense(Expense expense) async {
    final db = await _databaseHelper.database;
    final Map<String, dynamic> data = expense.toMap();
    return await db.update(
      AppConstants.expensesTableName,
      data,
      where: 'id = ?',
      whereArgs: [expense.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes an expense from the database by its ID.
  Future<int> deleteExpense(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      AppConstants.expensesTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Provider for [ExpenseDao].
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider); // Assuming databaseHelperProvider is defined
  return ExpenseDao(databaseHelper);
});

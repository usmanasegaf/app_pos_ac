// lib/data/repositories/expense_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/datasources/local/expense_dao.dart'; // Import ExpenseDao
import 'package:app_pos_ac/data/models/expense.dart'; // Import Expense model

/// Repository for managing Expense data.
/// This layer abstracts the data source (e.g., local database) from the rest of the application.
class ExpenseRepository {
  final ExpenseDao _expenseDao;

  // Constructor that receives an ExpenseDao instance
  ExpenseRepository(this._expenseDao);

  /// Inserts a new [Expense] into the database.
  /// Returns the ID of the newly inserted row.
  Future<int> addExpense(Expense expense) {
    return _expenseDao.insertExpense(expense);
  }

  /// Retrieves all [Expense]s from the database.
  /// Returns a list of [Expense].
  Future<List<Expense>> getExpenses() {
    return _expenseDao.getExpenses();
  }

  /// Retrieves [Expense]s within a specific date range from the database.
  /// Returns a list of [Expense].
  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _expenseDao.getExpensesByDateRange(startDate, endDate);
  }

  /// Retrieves a single [Expense] by its ID.
  /// Returns [Expense] if found, null otherwise.
  Future<Expense?> getExpenseById(int id) {
    return _expenseDao.getExpenseById(id);
  }

  /// Updates an existing [Expense] in the database.
  /// Returns the number of rows affected.
  Future<int> updateExpense(Expense expense) {
    return _expenseDao.updateExpense(expense);
  }

  /// Deletes an [Expense] from the database by its ID.
  /// Returns the number of rows affected.
  Future<int> deleteExpense(int id) {
    return _expenseDao.deleteExpense(id);
  }
}

/// Provider for [ExpenseRepository].
/// Depends on [expenseDaoProvider] which provides an ExpenseDao instance.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return ExpenseRepository(expenseDao);
});

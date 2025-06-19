// lib/presentation/features/expenses/viewmodels/expense_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/expense.dart';
import 'package:app_pos_ac/data/repositories/expense_repository.dart'; // Import ExpenseRepository

/// StateNotifier for managing Expense data.
class ExpenseNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;

  ExpenseNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load expenses when the notifier is created
    _loadExpenses();
  }

  /// Loads all expenses from the repository.
  Future<void> _loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds a new expense to the database.
  Future<void> addExpense(String description, double amount, DateTime date) async {
    if (description.isEmpty) {
      throw Exception('Expense description cannot be empty.');
    }
    if (amount <= 0) { // Pengeluaran harus positif
      throw Exception('Expense amount must be greater than 0.');
    }

    try {
      state = const AsyncValue.loading();
      final newExpense = Expense(description: description, amount: amount, date: date);
      await _repository.addExpense(newExpense);
      await _loadExpenses(); // Reload to update UI
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates an existing expense in the database.
  Future<void> updateExpense(int id, String description, double amount, DateTime date) async {
    if (description.isEmpty) {
      throw Exception('Expense description cannot be empty.');
    }
    if (amount <= 0) {
      throw Exception('Expense amount must be greater than 0.');
    }
    if (id == 0) { // ID tidak boleh 0 untuk update
      throw Exception('Expense ID is required for update.');
    }

    try {
      state = const AsyncValue.loading();
      final updatedExpense = Expense(id: id, description: description, amount: amount, date: date);
      await _repository.updateExpense(updatedExpense);
      await _loadExpenses(); // Reload to update UI
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Deletes an expense by its ID.
  Future<void> deleteExpense(int id) async {
    try {
      // Optimistically update the UI
      if (state is AsyncData) {
        state = AsyncValue.data(state.value!.where((expense) => expense.id != id).toList());
      }
      await _repository.deleteExpense(id);
      await _loadExpenses(); // Reload from DB to ensure consistency
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await _loadExpenses(); // Revert to actual state if error
    }
  }
}

/// Provider for [ExpenseNotifier].
final expenseProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider); // Memanggil expenseRepositoryProvider
  return ExpenseNotifier(repository);
});

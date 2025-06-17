// lib/presentation/features/transactions/viewmodels/transaction_history_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:app_pos_ac/data/repositories/transaction_repository.dart';

/// StateNotifier for managing the list of [TransactionAC]s in the history.
class TransactionHistoryNotifier extends StateNotifier<AsyncValue<List<TransactionAC>>> {
  final TransactionRepository _repository;

  TransactionHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadTransactions(); // Load transactions when the notifier is created
  }

  /// Loads all transactions from the repository.
  Future<void> _loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final transactions = await _repository.getTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refreshes the list of transactions.
  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }

  /// Deletes a transaction by its ID.
  Future<void> deleteTransaction(int id) async {
    try {
      // Optimistically update the UI
      if (state is AsyncData) {
        state = AsyncValue.data(state.value!.where((tx) => tx.id != id).toList());
      }
      await _repository.deleteTransaction(id);
      await _loadTransactions(); // Reload from DB to ensure consistency
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await _loadTransactions(); // Revert to actual state if error
    }
  }
}

/// Provider for [TransactionHistoryNotifier].
final transactionHistoryProvider = StateNotifierProvider<TransactionHistoryNotifier, AsyncValue<List<TransactionAC>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionHistoryNotifier(repository);
});

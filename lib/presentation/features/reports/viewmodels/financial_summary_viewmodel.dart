// lib/presentation/features/reports/viewmodels/financial_summary_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/repositories/transaction_repository.dart'; // Mengimpor TransactionRepository
import 'package:app_pos_ac/data/repositories/expense_repository.dart'; // <--- Import ExpenseRepository
import 'package:app_pos_ac/data/models/transaction.dart'; // Mengimpor TransactionAC
import 'package:app_pos_ac/data/models/expense.dart'; // <--- Import Expense

// Enum untuk filter periode waktu
enum DateFilter {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
}

// Model untuk menyimpan hasil summary keuangan
class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;

  FinancialSummary({
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
  });

  // Factory constructor untuk membuat objek kosong
  factory FinancialSummary.empty() => FinancialSummary();
}

/// StateNotifier untuk mengelola summary keuangan (pemasukan & pengeluaran).
class FinancialSummaryNotifier extends StateNotifier<AsyncValue<FinancialSummary>> {
  final TransactionRepository _transactionRepository;
  final ExpenseRepository _expenseRepository; // <--- Tambahkan ExpenseRepository
  DateFilter _currentFilter = DateFilter.allTime; // Filter default

  FinancialSummaryNotifier(this._transactionRepository, this._expenseRepository) // <--- Tambahkan parameter
      : super(const AsyncValue.loading()) {
    // Muat summary awal saat notifier dibuat
    loadFinancialSummary(_currentFilter);
  }

  DateFilter get currentFilter => _currentFilter;

  /// Mengatur filter tanggal dan memuat ulang summary.
  Future<void> setFilter(DateFilter newFilter) async {
    _currentFilter = newFilter;
    await loadFinancialSummary(_currentFilter);
  }

  /// Memuat dan menghitung summary keuangan berdasarkan filter yang diberikan.
  Future<void> loadFinancialSummary(DateFilter filter) async {
    state = const AsyncValue.loading();
    try {
      List<TransactionAC> transactions;
      List<Expense> expenses; // Daftar pengeluaran
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // Akhir hari, termasuk milidetik

      switch (filter) {
        case DateFilter.today:
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0); // Awal hari ini
          transactions = await _transactionRepository.getTransactionsByDateRange(startDate, endDate);
          expenses = await _expenseRepository.getExpensesByDateRange(startDate, endDate); // Ambil pengeluaran
          break;
        case DateFilter.thisWeek:
          // Mencari awal minggu (Senin)
          // Mengatur startDate ke awal hari Senin minggu ini (pukul 00:00:00)
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0)
              .subtract(Duration(days: now.weekday - 1)); // -1 karena DateTime.weekday menganggap Senin = 1
          transactions = await _transactionRepository.getTransactionsByDateRange(startDate, endDate);
          expenses = await _expenseRepository.getExpensesByDateRange(startDate, endDate); // Ambil pengeluaran
          break;
        case DateFilter.thisMonth:
          startDate = DateTime(now.year, now.month, 1, 0, 0, 0, 0); // Awal bulan ini
          transactions = await _transactionRepository.getTransactionsByDateRange(startDate, endDate);
          expenses = await _expenseRepository.getExpensesByDateRange(startDate, endDate); // Ambil pengeluaran
          break;
        case DateFilter.thisYear:
          startDate = DateTime(now.year, 1, 1, 0, 0, 0, 0); // Awal tahun ini
          transactions = await _transactionRepository.getTransactionsByDateRange(startDate, endDate);
          expenses = await _expenseRepository.getExpensesByDateRange(startDate, endDate); // Ambil pengeluaran
          break;
        case DateFilter.allTime:
        default:
          transactions = await _transactionRepository.getTransactions(); // Ambil semua transaksi
          expenses = await _expenseRepository.getExpenses(); // Ambil semua pengeluaran
          break;
      }

      double income = 0.0;
      double totalExpensesAmount = 0.0; // Untuk pengeluaran dari tabel expenses

      // Hitung pemasukan dari transaksi penjualan (termasuk diskon yang sudah mengurangi total)
      for (var transaction in transactions) {
        income += transaction.total;
      }

      // Hitung total pengeluaran dari catatan pengeluaran
      for (var expense in expenses) {
        totalExpensesAmount += expense.amount;
      }

      state = AsyncValue.data(
        FinancialSummary(
          totalIncome: income,
          totalExpenses: totalExpensesAmount, // Hanya pengeluaran dari tabel expenses
          netProfit: income - totalExpensesAmount,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider untuk [FinancialSummaryNotifier].
final financialSummaryProvider =
    StateNotifierProvider<FinancialSummaryNotifier, AsyncValue<FinancialSummary>>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final expenseRepository = ref.watch(expenseRepositoryProvider); // <--- Watch expenseRepositoryProvider
  return FinancialSummaryNotifier(transactionRepository, expenseRepository); // <--- Teruskan keduanya
});

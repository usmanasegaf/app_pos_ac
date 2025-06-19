// lib/presentation/features/reports/views/financial_summary_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_pos_ac/presentation/features/reports/viewmodels/financial_summary_viewmodel.dart'; // Import ViewModel
import 'package:app_pos_ac/data/models/transaction.dart'; // Import TransactionAC model
import 'package:app_pos_ac/data/models/expense.dart'; // Import Expense model
import 'package:app_pos_ac/data/repositories/transaction_repository.dart'; // Import TransactionRepository
import 'package:app_pos_ac/data/repositories/expense_repository.dart'; // Import ExpenseRepository
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart'; // Untuk dialog pesan

// Untuk Excel
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

/// A view to display financial summary including income, expenses, and net profit.
class FinancialSummaryView extends ConsumerStatefulWidget {
  const FinancialSummaryView({super.key});

  @override
  ConsumerState<FinancialSummaryView> createState() => _FinancialSummaryViewState();
}

class _FinancialSummaryViewState extends ConsumerState<FinancialSummaryView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMMM HH:mm');

  // Deklarasikan variabel untuk menyimpan data mentah transaksi dan pengeluaran
  List<TransactionAC> allTransactions = [];
  List<Expense> allExpenses = [];

  @override
  void initState() {
    super.initState();
    // Memuat ulang summary untuk memastikan data awal diambil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financialSummaryProvider.notifier).loadFinancialSummary(DateFilter.allTime); // Muat semua data awal
    });
  }

  Future<void> _exportToExcel() async {
    // Meminta izin penyimpanan
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      if (mounted) {
        await showAppMessageDialog(
          context,
          title: 'Permission Denied',
          message: 'Storage permission is required to save the report.',
        );
      }
      return;
    }

    try {
      final excel = Excel.createExcel();
      
      // Get the default sheet (Sheet1)
      Sheet sheetSummary = excel['Sheet1']!;

      // Create other sheets by copying Sheet1, then clear their content
      // PENTING: excel.copy() tidak mengembalikan Sheet, jadi kita perlu mengambilnya setelah dicopy
      excel.copy('Sheet1', 'Income Details');
      Sheet sheetIncome = excel['Income Details']!;
      sheetIncome.removeColumn(0); // Remove dummy column if any
      sheetIncome.removeRow(0);   // Remove dummy row if any

      excel.copy('Sheet1', 'Expense Details');
      Sheet sheetExpense = excel['Expense Details']!;
      sheetExpense.removeColumn(0);
      sheetExpense.removeRow(0);

      // Now rename Sheet1 to Financial Summary
      excel.rename('Sheet1', 'Financial Summary');

      // Add data to Summary Sheet
      sheetSummary.appendRow(['Financial Summary Report', '']);
      sheetSummary.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('B1'));
      sheetSummary.appendRow(['Generated On', dateFormatter.format(DateTime.now())]);
      sheetSummary.appendRow(['Filter Period', ref.read(financialSummaryProvider.notifier).currentFilter.toString().split('.').last.toUpperCase()]);
      sheetSummary.appendRow([]); // Empty row for spacing

      // Dapatkan data summary terakhir dari provider
      final currentSummary = ref.read(financialSummaryProvider).value;
      if (currentSummary != null) {
        sheetSummary.appendRow(['Total Income', currencyFormatter.format(currentSummary.totalIncome)]);
        sheetSummary.appendRow(['Total Expenses', currencyFormatter.format(currentSummary.totalExpenses)]);
        sheetSummary.appendRow(['Net Profit', currencyFormatter.format(currentSummary.netProfit)]);
      }

      // Add data to Income (Transaction History) Sheet
      sheetIncome.appendRow(['Transaction ID', 'Date', 'Customer Name', 'Total Amount', 'Service Items']);

      final transactions = allTransactions; // Gunakan data transaksi yang sudah dimuat
      for (var transaction in transactions) {
        String items = transaction.items.map((item) => '${item.serviceName} (${item.quantity}x)').join(', '); // <--- item.serviceName
        sheetIncome.appendRow([
          transaction.id,
          dateFormatter.format(transaction.date),
          transaction.customerName,
          transaction.total,
          items,
        ]);
      }

      // Add data to Expense History Sheet
      sheetExpense.appendRow(['Expense ID', 'Date', 'Description', 'Amount']);

      final expenses = allExpenses; // Gunakan data pengeluaran yang sudah dimuat
      for (var expense in expenses) {
        sheetExpense.appendRow([
          expense.id,
          dateFormatter.format(expense.date),
          expense.description,
          expense.amount,
        ]);
      }
      
      // Simpan file
      final directory = await getExternalStorageDirectory(); // Menggunakan external storage untuk Android
      final String filePath = '${directory!.path}/Financial_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excelBytes);

        if (mounted) {
          await showAppMessageDialog(
            context,
            title: 'Report Generated',
            message: 'Financial report saved to $filePath',
          );
          OpenFilex.open(filePath); // Buka file setelah disimpan
        }
      } else {
        throw Exception('Failed to encode Excel file.');
      }
    } catch (e) {
      if (mounted) {
        await showAppMessageDialog(context, title: 'Error', message: 'Failed to generate report: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the summary provider
    final summaryAsyncValue = ref.watch(financialSummaryProvider);

    // Watch the repositories directly to get all data for lists, regardless of current filter
    // Note: This fetches ALL transactions/expenses every time this widget rebuilds.
    // For large datasets, consider fetching only what's needed for the displayed list
    // or passing a filtered list from the ViewModel.
    // For excel export, we need all data for the selected filter period anyway.
    final transactionsRepo = ref.watch(transactionRepositoryProvider);
    final expensesRepo = ref.watch(expenseRepositoryProvider);

    final currentFilter = ref.watch(financialSummaryProvider.notifier).currentFilter;
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (currentFilter) {
      case DateFilter.today:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        break;
      case DateFilter.thisWeek:
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0).subtract(Duration(days: now.weekday - 1));
        break;
      case DateFilter.thisMonth:
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
        break;
      case DateFilter.thisYear:
        startDate = DateTime(now.year, 1, 1, 0, 0, 0, 0);
        break;
      case DateFilter.allTime:
      default:
        // For allTime, we just use getTransactions()/getExpenses() without date range
        startDate = DateTime.fromMillisecondsSinceEpoch(0); // Very old date
        endDate = DateTime.now().add(const Duration(days: 365 * 100)); // Very far future date
        break;
    }

    final transactionsFuture = (currentFilter == DateFilter.allTime)
        ? transactionsRepo.getTransactions()
        : transactionsRepo.getTransactionsByDateRange(startDate, endDate);
    
    final expensesFuture = (currentFilter == DateFilter.allTime)
        ? expensesRepo.getExpenses()
        : expensesRepo.getExpensesByDateRange(startDate, endDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter by
            _buildFilterSection(context, ref),
            const SizedBox(height: 16.0),

            // Summary Cards (smaller height)
            summaryAsyncValue.when(
              data: (summary) {
                return Column(
                  children: [
                    _buildSummaryCard(context, 'Total Income', summary.totalIncome, Colors.green),
                    const SizedBox(height: 8.0),
                    _buildSummaryCard(context, 'Total Expenses', summary.totalExpenses, Colors.red),
                    const SizedBox(height: 8.0),
                    _buildSummaryCard(context, 'Net Profit', summary.netProfit, Colors.blue),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            const SizedBox(height: 16.0),

            // Report to Excel Button
            ElevatedButton.icon(
              onPressed: _exportToExcel,
              icon: const Icon(Icons.description),
              label: const Text('Generate Excel Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24.0), // Spasi setelah tombol

            // Combined History List
            const Text(
              'Combined History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            FutureBuilder<List<dynamic>>(
              future: Future.wait([transactionsFuture, expensesFuture]), // Gunakan Future yang difilter
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading history: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final List<TransactionAC> transactions = snapshot.data![0];
                  final List<Expense> expenses = snapshot.data![1];

                  // Simpan data mentah ini untuk digunakan oleh _exportToExcel
                  allTransactions = transactions;
                  allExpenses = expenses;

                  // Gabungkan dan urutkan berdasarkan tanggal terbaru
                  List<dynamic> combinedList = [...transactions, ...expenses];
                  combinedList.sort((a, b) {
                    DateTime dateA = (a is TransactionAC) ? a.date : (a as Expense).date;
                    DateTime dateB = (b is TransactionAC) ? b.date : (b as Expense).date;
                    return dateB.compareTo(dateA); // Urutkan dari terbaru ke terlama
                  });

                  if (combinedList.isEmpty) {
                    return const Center(child: Text('No history available for this period.'));
                  }

                  return ListView.builder(
                    shrinkWrap: true, // Penting agar ListView.builder bisa di dalam SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll ListView ini
                    itemCount: combinedList.length,
                    itemBuilder: (context, index) {
                      final item = combinedList[index];
                      if (item is TransactionAC) {
                        return _buildTransactionHistoryItem(item);
                      } else if (item is Expense) {
                        return _buildExpenseHistoryItem(item);
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method untuk bagian filter
  Widget _buildFilterSection(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(financialSummaryProvider.notifier).currentFilter;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.0,
              children: DateFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(filter.toString().split('.').last.replaceAll('this', '')),
                  selected: currentFilter == filter,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(financialSummaryProvider.notifier).setFilter(filter);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method untuk kartu summary yang lebih kecil
  Widget _buildSummaryCard(BuildContext context, String title, double amount, Color color) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Padding vertikal lebih kecil
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              currencyFormatter.format(amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.darken(0.2)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method untuk item riwayat transaksi
  Widget _buildTransactionHistoryItem(TransactionAC transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income: ${currencyFormatter.format(transaction.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${transaction.customerName}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Date: ${dateFormatter.format(transaction.date)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (transaction.items.isNotEmpty)
              Text(
                'Items: ${transaction.items.map((item) => '${item.serviceName} (${item.quantity}x)').join(', ')}', // <--- item.serviceName
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method untuk item riwayat pengeluaran
  Widget _buildExpenseHistoryItem(Expense expense) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense: ${currencyFormatter.format(expense.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 4),
            Text(
              'Description: ${expense.description}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Date: ${dateFormatter.format(expense.date)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension untuk mengubah kecerahan warna
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

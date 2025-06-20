// lib/presentation/features/reports/views/financial_summary_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_pos_ac/presentation/features/reports/viewmodels/financial_summary_viewmodel.dart';
import 'package:app_pos_ac/data/models/transaction.dart';
import 'package:app_pos_ac/data/models/expense.dart';
import 'package:app_pos_ac/data/repositories/transaction_repository.dart';
import 'package:app_pos_ac/data/repositories/expense_repository.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';

// Import untuk PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Beri alias pw
import 'package:printing/printing.dart'; // Untuk menyimpan dan membuka PDF

import 'package:path_provider/path_provider.dart';
import 'dart:io'; // Penting untuk Platform.isAndroid
import 'package:permission_handler/permission_handler.dart';
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
  final pdfDateFormatter = DateFormat('dd MMMM yyyy HH:mm'); // Format tanggal khusus untuk PDF

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financialSummaryProvider.notifier).loadFinancialSummary(DateFilter.allTime);
    });
  }

  Future<void> _exportToPdf() async {
    // Menampilkan dialog loading segera
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Generating PDF Report...'),
            ],
          ),
        ),
      );
    }

    final pdf = pw.Document(); // Inisialisasi dokumen PDF

    try {
      // *** Penanganan Izin Penyimpanan untuk Android ***
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.isGranted) {
          var status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
            if (mounted) {
              await showAppMessageDialog(
                context,
                title: 'Izin Diperlukan',
                message: 'Akses ke semua file ditolak. Harap berikan izin "Akses ke semua file" di Pengaturan Aplikasi untuk menyimpan laporan.',
              );
              await openAppSettings();
            }
            return;
          }
        }
      } else {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
          if (mounted) {
            await showAppMessageDialog(
              context,
              title: 'Izin Ditolak',
              message: 'Izin penyimpanan diperlukan untuk menyimpan laporan. Laporan tidak dapat disimpan.',
            );
          }
          return;
        }
      }

      // Dapatkan filter saat ini dan data
      final currentFilter = ref.read(financialSummaryProvider.notifier).currentFilter;
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
          startDate = DateTime.fromMillisecondsSinceEpoch(0);
          endDate = DateTime.now().add(const Duration(days: 365 * 100));
          break;
      }

      final transactionsRepo = ref.read(transactionRepositoryProvider);
      final expensesRepo = ref.read(expenseRepositoryProvider);
      
      final List<TransactionAC> transactionsToExport = (currentFilter == DateFilter.allTime)
          ? await transactionsRepo.getTransactions()
          : await transactionsRepo.getTransactionsByDateRange(startDate, endDate);
      
      final List<Expense> expensesToExport = (currentFilter == DateFilter.allTime)
          ? await expensesRepo.getExpenses()
          : await expensesRepo.getExpensesByDateRange(startDate, endDate);

      final currentSummary = ref.read(financialSummaryProvider).value;

      // --- Mulai Pembuatan Konten PDF ---

      // Fungsi pembantu untuk membuat tabel PDF
      pw.Widget _buildPdfTable(List<List<String>> tableData, List<double> widths, {String? title}) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (title != null) pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            if (title != null) pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: tableData.first,
              data: tableData.sublist(1),
              border: pw.TableBorder.all(color: PdfColors.grey),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              columnWidths: {
                for (int i = 0; i < widths.length; i++) i: pw.FlexColumnWidth(widths[i]),
              },
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),
          ],
        );
      }

      // Add pages to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            // 1. Financial Summary Section
            content.add(pw.Center(
              child: pw.Text('Laporan Keuangan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
            ));
            content.add(pw.Center(
              child: pw.Text('Periode: ${currentFilter.toString().split('.').last.toUpperCase().replaceAll('_', ' ')}', style: const pw.TextStyle(fontSize: 12)),
            ));
            content.add(pw.Center(
              child: pw.Text('Dihasilkan Pada: ${pdfDateFormatter.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
            ));
            content.add(pw.SizedBox(height: 30));

            if (currentSummary != null) {
              content.add(pw.Table.fromTextArray(
                headers: ['Deskripsi', 'Jumlah'],
                data: [
                  ['Total Pendapatan', currencyFormatter.format(currentSummary.totalIncome)],
                  ['Total Pengeluaran', currencyFormatter.format(currentSummary.totalExpenses)],
                  ['Laba Bersih', currencyFormatter.format(currentSummary.netProfit)],
                ],
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                cellPadding: const pw.EdgeInsets.all(5),
              ));
              content.add(pw.SizedBox(height: 20));
            }

            // 2. Income Details Section
            List<List<String>> incomeData = [
              ['ID Transaksi', 'Tanggal', 'Nama Pelanggan', 'Jumlah Total', 'Item Layanan']
            ];
            for (var transaction in transactionsToExport) {
              String items = transaction.items.map((item) => '${item.serviceName} (${item.quantity}x)').join(', ');
              incomeData.add([
                transaction.id.toString(),
                pdfDateFormatter.format(transaction.date),
                transaction.customerName,
                currencyFormatter.format(transaction.total),
                items,
              ]);
            }
            if (incomeData.length > 1) { // Hanya tambahkan jika ada data selain header
              content.add(_buildPdfTable(incomeData, [2, 2.5, 3, 2, 4], title: 'Detail Pendapatan'));
            }

            // 3. Expense Details Section
            List<List<String>> expenseData = [
              ['ID Pengeluaran', 'Tanggal', 'Deskripsi', 'Jumlah']
            ];
            for (var expense in expensesToExport) {
              expenseData.add([
                expense.id.toString(),
                pdfDateFormatter.format(expense.date),
                expense.description,
                currencyFormatter.format(expense.amount),
              ]);
            }
            if (expenseData.length > 1) { // Hanya tambahkan jika ada data selain header
              content.add(_buildPdfTable(expenseData, [2, 2.5, 4, 2], title: 'Detail Pengeluaran'));
            }

            // 4. Combined History Section
            List<List<String>> combinedHistoryData = [
              ['Tipe', 'ID', 'Tanggal', 'Deskripsi / Nama Pelanggan', 'Jumlah', 'Detail Layanan']
            ];
            List<dynamic> combinedList = [...transactionsToExport, ...expensesToExport];
            combinedList.sort((a, b) {
              DateTime dateA = (a is TransactionAC) ? a.date : (a as Expense).date;
              DateTime dateB = (b is TransactionAC) ? b.date : (b as Expense).date;
              return dateB.compareTo(dateA); // Urutkan dari terbaru ke terlama
            });

            for (var item in combinedList) {
              if (item is TransactionAC) {
                String items = item.items.map((e) => '${e.serviceName} (${e.quantity}x)').join(', ');
                combinedHistoryData.add([
                  'Pendapatan',
                  item.id.toString(),
                  pdfDateFormatter.format(item.date),
                  item.customerName,
                  currencyFormatter.format(item.total),
                  items,
                ]);
              } else if (item is Expense) {
                combinedHistoryData.add([
                  'Pengeluaran',
                  item.id.toString(),
                  pdfDateFormatter.format(item.date),
                  item.description,
                  currencyFormatter.format(item.amount),
                  '', // Tidak ada detail item untuk expense
                ]);
              }
            }
            if (combinedHistoryData.length > 1) { // Hanya tambahkan jika ada data selain header
              content.add(_buildPdfTable(combinedHistoryData, [1.5, 1.5, 2.5, 3, 2, 3.5], title: 'Riwayat Gabungan'));
            }
            
            return content;
          },
        ),
      );

      // Simpan file PDF
      final directory = await getExternalStorageDirectory();
      final String filePath = '${directory!.path}/Financial_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save()); // Simpan PDF ke bytes dan tulis ke file

      if (mounted) {
        // Tutup dialog loading sebelum menampilkan pesan sukses/membuka file
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
        await showAppMessageDialog(
          context,
          title: 'Laporan Dibuat',
          message: 'Laporan keuangan disimpan di $filePath',
        );
        OpenFilex.open(filePath); // Buka file PDF
      }
    } catch (e) {
      if (mounted) {
        // Pastikan dialog loading ditutup jika terjadi error
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
        await showAppMessageDialog(context, title: 'Error', message: 'Gagal membuat laporan: $e');
        debugPrint('Error generating PDF: $e'); // Untuk debugging
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsyncValue = ref.watch(financialSummaryProvider);

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
        startDate = DateTime.fromMillisecondsSinceEpoch(0); // Sangat lama
        endDate = DateTime.now().add(const Duration(days: 365 * 100)); // Sangat jauh di masa depan
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
        title: const Text('Ringkasan Keuangan',
        style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black), // Set icon color to black
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilterSection(context, ref),
            const SizedBox(height: 16.0),

            summaryAsyncValue.when(
              data: (summary) {
                return Column(
                  children: [
                    _buildSummaryCard(context, 'Total Income', summary.totalIncome, const Color.fromARGB(255, 85, 204, 49)),
                    const SizedBox(height: 8.0),
                    _buildSummaryCard(context, 'Total Expenses', summary.totalExpenses, const Color.fromARGB(255, 255, 17, 0)),
                    const SizedBox(height: 8.0),
                    _buildSummaryCard(context, 'Net Profit', summary.netProfit, const Color.fromARGB(255, 0, 140, 255)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            const SizedBox(height: 16.0),

            ElevatedButton.icon(
              onPressed: _exportToPdf, // Ganti ke _exportToPdf
              icon: const Icon(Icons.picture_as_pdf), // Ganti ikon
              label: const Text('Generate PDF Report'), // Ganti label
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24.0),

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

                  List<dynamic> combinedList = [...transactions, ...expenses];
                  combinedList.sort((a, b) {
                    DateTime dateA = (a is TransactionAC) ? a.date : (a as Expense).date;
                    DateTime dateB = (b is TransactionAC) ? b.date : (b as Expense).date;
                    return dateB.compareTo(dateA);
                  });

                  if (combinedList.isEmpty) {
                    return const Center(child: Text('No history available for this period.'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildSummaryCard(BuildContext context, String title, double amount, Color color) {
    return Card(
      elevation: 2,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              currencyFormatter.format(amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

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
                'Items: ${transaction.items.map((item) => '${item.serviceName} (${item.quantity}x)').join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

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

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

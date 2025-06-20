import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_pos_ac/presentation/features/service_items/views/service_item_list_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_history_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_input_view.dart';
import 'package:app_pos_ac/presentation/features/reports/views/financial_summary_view.dart';
import 'package:app_pos_ac/presentation/features/expenses/views/expense_input_view.dart';
import 'package:app_pos_ac/presentation/features/expenses/views/expense_history_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.build, 'Kelola Layanan', const ServiceItemListView()],
      [Icons.receipt_long, 'Transaksi Baru', const TransactionInputView()],
      [Icons.history, 'Riwayat Transaksi', const TransactionHistoryView()],
      [Icons.add_shopping_cart, 'Tambah Pengeluaran', const ExpenseInputView()],
      [Icons.account_balance_wallet, 'Riwayat Pengeluaran', const ExpenseHistoryView()],
      [Icons.analytics, 'Ringkasan Keuangan', const FinancialSummaryView()],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat Datang!',
                style: GoogleFonts.roboto(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Aplikasi POS AC Service Anda.',
                style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildFormalCard(
                    icon: item[0] as IconData,
                    title: item[1] as String,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => item[2] as Widget)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormalCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.indigo.shade700),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

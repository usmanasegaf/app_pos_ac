// lib/presentation/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_pos_ac/presentation/features/service_items/views/service_item_list_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_history_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_input_view.dart';
import 'package:app_pos_ac/presentation/features/reports/views/financial_summary_view.dart';
import 'package:app_pos_ac/presentation/features/expenses/views/expense_input_view.dart';
import 'package:app_pos_ac/presentation/features/expenses/views/expense_history_view.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // URL Google Form Absensi Anda
  final String _googleFormAbsensiUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSddx6WyUEgwQobJJ6j4k0rQTFGavUkiQRz9ACUPTYLlwXJMzQ/viewform?usp=dialog';

  // Fungsi untuk membuka URL - Sekarang menerima BuildContext
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
      );
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi item menu, termasuk yang baru untuk Absensi Online
    final items = [
      [Icons.build, 'Kelola Layanan', const ServiceItemListView()],
      [Icons.receipt_long, 'Transaksi Baru', const TransactionInputView()],
      [Icons.history, 'Riwayat Transaksi', const TransactionHistoryView()],
      [Icons.add_shopping_cart, 'Tambah Pengeluaran', const ExpenseInputView()],
      [Icons.account_balance_wallet, 'Riwayat Pengeluaran', const ExpenseHistoryView()],
      [Icons.analytics, 'Ringkasan Keuangan', const FinancialSummaryView()],
      // KARTU BARU: Absensi Online
      [Icons.access_time, 'Form Absensi', (ctx) => _launchUrl(ctx, _googleFormAbsensiUrl)],
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea( // Menggunakan SafeArea untuk menghindari overlap dengan status bar
        child: SingleChildScrollView(
          // Mengurangi padding top dan bottom sedikit untuk memberi ruang lebih
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16), // Padding top disesuaikan
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Aplikasi
              Center(
                child: Image.asset(
                  'assets/images/logo_ac_teknik.jpeg', // Pastikan path ini benar
                  height: 100, // Tinggi yang tetap untuk logo
                  fit: BoxFit.contain, // Memastikan gambar tidak terdistorsi
                ),
              ),
              const SizedBox(height: 16), // Spasi di bawah logo

              // Custom Header
              Text('Selamat Datang!',
                  style: GoogleFonts.roboto(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Aplikasi POS AC Service Anda.',
                  style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 20), // Spasi sebelum GridView
              
              // GridView untuk menu - PENTING: Hapus widget Expanded di sini
              // Menggunakan shrinkWrap: true dan NeverScrollableScrollPhysics()
              // Sudah cukup dan menghindari overflow di dalam SingleChildScrollView
              GridView.builder(
                shrinkWrap: true, // Membuat GridView hanya menggunakan ruang yang dibutuhkan
                physics: const NeverScrollableScrollPhysics(), // Menonaktifkan scroll GridView internal
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.41, // Disesuaikan untuk ukuran kartu
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  VoidCallback onTapCallback;
                  if (item[2] is Widget) {
                    onTapCallback = () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => item[2] as Widget));
                  } else if (item[2] is Function(BuildContext)) {
                    onTapCallback = () => (item[2] as Function(BuildContext))(context);
                  } else {
                    onTapCallback = () => debugPrint('Invalid onTap type for ${item[1]}');
                  }

                  return _buildFormalCard(
                    icon: item[0] as IconData,
                    title: item[1] as String,
                    onTap: onTapCallback,
                  );
                },
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.indigo.shade700),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

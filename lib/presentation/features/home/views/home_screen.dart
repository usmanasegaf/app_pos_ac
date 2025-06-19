// lib/presentation/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:app_pos_ac/presentation/features/service_items/views/service_item_list_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_history_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_input_view.dart';
import 'package:app_pos_ac/presentation/features/reports/views/financial_summary_view.dart';
import 'package:app_pos_ac/presentation/features/expenses/views/expense_input_view.dart'; // Import for Add Expense
import 'package:app_pos_ac/presentation/features/expenses/views/expense_history_view.dart'; // <--- TAMBAHKAN IMPORT INI

/// The main home screen of the application.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS AC Service App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            // Urutan yang Anda inginkan:
            // 1. Manage Services
            _buildFeatureCard(
              context,
              icon: Icons.build,
              title: 'Manage Services',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceItemListView()),
                );
              },
            ),
            // 2. New Transaction
            _buildFeatureCard(
              context,
              icon: Icons.receipt_long,
              title: 'New Transaction',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionInputView()),
                );
              },
            ),
            // 3. Transaction History
            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'Transaction History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionHistoryView()),
                );
              },
            ),
            // 4. Add Expense
            _buildFeatureCard(
              context,
              icon: Icons.add_shopping_cart,
              title: 'Add Expense',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseInputView()),
                );
              },
            ),
            // 5. Expense History <--- KARTU BARU UNTUK RIWAYAT PENGELUARAN
            _buildFeatureCard(
              context,
              icon: Icons.account_balance_wallet, // Icon untuk riwayat pengeluaran
              title: 'Expense History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpenseHistoryView()),
                );
              },
            ),
            // 6. Financial Summary (Jika ada)
            _buildFeatureCard(
              context,
              icon: Icons.analytics,
              title: 'Financial Summary',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FinancialSummaryView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method untuk membangun kartu fitur yang dapat disesuaikan.
  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/features/home/views/home_screen.dart

import 'package:flutter/material.dart'; // Import ini diperbaiki
import 'package:app_pos_ac/presentation/features/service_items/views/service_item_list_view.dart';
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_history_view.dart'; // Diaktifkan kembali
import 'package:app_pos_ac/presentation/features/transactions/views/transaction_input_view.dart'; // Diaktifkan kembali

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
            _buildFeatureCard(
              context,
              icon: Icons.receipt_long,
              title: 'New Transaction',
              onTap: () {
                // Navigate to Transaction Input View
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionInputView()),
                );
              },
            ),
            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'Transaction History',
              onTap: () {
                // Navigate to Transaction History View
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionHistoryView()),
                );
              },
            ),
            // Tambahkan lebih banyak kartu fitur sesuai kebutuhan
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

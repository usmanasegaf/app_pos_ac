// lib/presentation/features/reports/views/financial_summary_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/presentation/features/reports/viewmodels/financial_summary_viewmodel.dart';
import 'package:intl/intl.dart';

class FinancialSummaryView extends ConsumerWidget {
  const FinancialSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsyncValue = ref.watch(financialSummaryProvider);
    final summaryNotifier = ref.read(financialSummaryProvider.notifier);
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Summary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<DateFilter>(
              value: summaryNotifier.currentFilter,
              decoration: InputDecoration(
                labelText: 'Filter by',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              items: DateFilter.values.map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter.toString().split('.').last.toUpperCase().replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (DateFilter? newFilter) {
                if (newFilter != null) {
                  summaryNotifier.setFilter(newFilter);
                }
              },
            ),
          ),
          Expanded(
            child: summaryAsyncValue.when(
              data: (summary) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        title: 'Total Income',
                        value: currencyFormatter.format(summary.totalIncome),
                        color: Colors.green,
                        icon: Icons.arrow_upward,
                      ),
                      _buildSummaryCard(
                        title: 'Total Expenses',
                        value: currencyFormatter.format(summary.totalExpenses),
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                      ),
                      _buildSummaryCard(
                        title: 'Net Profit',
                        value: currencyFormatter.format(summary.netProfit),
                        color: Colors.blue,
                        icon: Icons.attach_money,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

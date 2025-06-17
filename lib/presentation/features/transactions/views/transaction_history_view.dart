// lib/presentation/features/transactions/views/transaction_history_view.dart

import 'package:app_pos_ac/presentation/features/transactions/views/transaction_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';
import 'package:app_pos_ac/presentation/features/transactions/viewmodels/transaction_history_viewmodel.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:intl/intl.dart';

/// Displays a list of all recorded transactions.
class TransactionHistoryView extends ConsumerWidget {
  const TransactionHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(transactionHistoryProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(transactionHistoryProvider.notifier).refreshTransactions();
            },
          ),
        ],
      ),
      body: transactionsAsyncValue.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No transactions recorded yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    '${transaction.customerName} - ${dateFormatter.format(transaction.date)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Total: ${currencyFormatter.format(transaction.total)}',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info, color: Colors.blue),
                        onPressed: () {
                          // Navigate to transaction detail view (create this next)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailView(transaction: transaction),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showConfirmationDialog(
                            context,
                            title: 'Delete Transaction',
                            content: 'Are you sure you want to delete this transaction record?',
                            confirmButtonColor: Colors.red,
                          );
                          if (confirm == true) {
                            ref.read(transactionHistoryProvider.notifier).deleteTransaction(transaction.id!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

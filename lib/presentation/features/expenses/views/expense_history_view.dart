// lib/presentation/features/expenses/views/expense_history_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_pos_ac/presentation/features/expenses/viewmodels/expense_viewmodel.dart'; // Import ExpenseViewModel
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart'; // Import app_dialogs for confirmation
import 'package:app_pos_ac/presentation/features/expenses/views/expense_input_view.dart'; // Import ExpenseInputView for editing

/// Displays a list of all recorded expenses.
class ExpenseHistoryView extends ConsumerWidget {
  const ExpenseHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsyncValue = ref.watch(expenseProvider);
    final expenseNotifier = ref.read(expenseProvider.notifier);
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History',
          style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black), // Set icon color to black
      ),
      body: expensesAsyncValue.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                'No expenses recorded yet.\nTap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Icon(Icons.money_off, color: Colors.red[700]),
                  ),
                  title: Text(
                    expense.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    '${dateFormatter.format(expense.date)}\nAmount: ${currencyFormatter.format(expense.amount)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExpenseInputView(expenseToEdit: expense)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showConfirmationDialog(
                            context,
                            title: 'Delete Expense',
                            content: 'Are you sure you want to delete this expense: "${expense.description}"?',
                            confirmButtonColor: Colors.red,
                          );
                          if (confirm == true && expense.id != null) {
                            expenseNotifier.deleteExpense(expense.id!);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseInputView()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

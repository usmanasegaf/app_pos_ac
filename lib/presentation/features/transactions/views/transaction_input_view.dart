// lib/presentation/features/transactions/views/transaction_input_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart'; // To get available service items
import 'package:app_pos_ac/presentation/features/transactions/viewmodels/transaction_input_viewmodel.dart';
import 'package:app_pos_ac/presentation/features/transactions/viewmodels/transaction_history_viewmodel.dart'; // To refresh history after new transaction
import 'package:intl/intl.dart';

/// View for inputting a new transaction.
class TransactionInputView extends ConsumerStatefulWidget {
  const TransactionInputView({super.key});

  @override
  ConsumerState<TransactionInputView> createState() => _TransactionInputViewState();
}

class _TransactionInputViewState extends ConsumerState<TransactionInputView> {
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Initialize customer name and address from viewmodel if they were previously set
    _customerNameController.text = ref.read(transactionInputProvider.notifier).customerName;
    _customerAddressController.text = ref.read(transactionInputProvider.notifier).customerAddress ?? '';

    // Listen to changes in controllers to update viewmodel state
    _customerNameController.addListener(() {
      ref.read(transactionInputProvider.notifier).setCustomerName(_customerNameController.text);
    });
    _customerAddressController.addListener(() {
      ref.read(transactionInputProvider.notifier).setCustomerAddress(_customerAddressController.text);
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  /// Shows a dialog to select service items.
  void _showServiceItemSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final serviceItemsAsyncValue = ref.watch(serviceItemProvider);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('Select Service Item'),
          content: serviceItemsAsyncValue.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('No service items available. Please add some first.');
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(currencyFormatter.format(item.price)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () {
                          ref.read(transactionInputProvider.notifier).addItemToCart(item);
                          Navigator.pop(dialogContext); // Close dialog after adding
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Finalizes the current transaction.
  Future<void> _finalizeTransaction() async {
    final transactionNotifier = ref.read(transactionInputProvider.notifier);
    if (transactionNotifier.customerName.isEmpty) {
      await showAppMessageDialog(
        context,
        title: 'Input Required',
        message: 'Customer Name cannot be empty.',
      );
      return;
    }
    if ((transactionNotifier.state.value ?? []).isEmpty) {
      await showAppMessageDialog(
        context,
        title: 'Empty Cart',
        message: 'Please add at least one service item to the transaction.',
      );
      return;
    }

    final confirm = await showConfirmationDialog(
      context,
      title: 'Finalize Transaction',
      content: 'Are you sure you want to finalize this transaction?',
    );

    if (confirm == true) {
      try {
        await transactionNotifier.finalizeTransaction();
        // Refresh transaction history after successful transaction
        ref.invalidate(transactionHistoryProvider); // or ref.read(transactionHistoryProvider.notifier).refreshTransactions();
        await showAppMessageDialog(
          context,
          title: 'Success',
          message: 'Transaction finalized successfully!',
        );
        // Clear input fields after successful transaction
        _customerNameController.clear();
        _customerAddressController.clear();
      } catch (e) {
        await showAppMessageDialog(
          context,
          title: 'Error',
          message: 'Failed to finalize transaction: ${e.toString()}',
        );
      }
    }
  }

  /// Shows a simple message dialog (similar to alert).
  Future<void> showAppMessageDialog(BuildContext context, {required String title, required String message}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final cartItemsAsyncValue = ref.watch(transactionInputProvider);
    final transactionNotifier = ref.read(transactionInputProvider.notifier);
    final total = transactionNotifier.calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cart',
            onPressed: () async {
              final confirm = await showConfirmationDialog(
                context,
                title: 'Clear Cart',
                content: 'Are you sure you want to clear the entire cart and customer details?',
                confirmButtonColor: Colors.red,
              );
              if (confirm == true) {
                transactionNotifier.clearTransaction();
                _customerNameController.clear();
                _customerAddressController.clear();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name (Required)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _customerAddressController,
                  decoration: InputDecoration(
                    labelText: 'Customer Address (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 24.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => _showServiceItemSelectionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cartItemsAsyncValue.when(
              data: (cartItems) {
                if (cartItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items in cart.\nAdd services to start a transaction!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.serviceItem.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${currencyFormatter.format(cartItem.serviceItem.price)} x ${cartItem.quantity}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormatter.format(cartItem.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.orange),
                              onPressed: () {
                                if (cartItem.quantity > 1) {
                                  transactionNotifier.updateItemQuantity(cartItem.serviceItem, cartItem.quantity - 1);
                                } else {
                                  transactionNotifier.removeItemFromCart(cartItem.serviceItem);
                                }
                              },
                            ),
                            Text(cartItem.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () {
                                transactionNotifier.updateItemQuantity(cartItem.serviceItem, cartItem.quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                transactionNotifier.removeItemFromCart(cartItem.serviceItem);
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Divider(height: 30, thickness: 2, color: Colors.grey[300]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currencyFormatter.format(total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _finalizeTransaction,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Finalize Transaction'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

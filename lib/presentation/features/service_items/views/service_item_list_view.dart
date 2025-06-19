// lib/presentation/features/service_items/views/service_item_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart'; // Revised package name
import 'package:app_pos_ac/presentation/features/service_items/views/service_item_form_view.dart'; // Revised package name
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart'; // Import the dialog helper (Revised package name)
import 'package:intl/intl.dart'; // For currency formatting

/// Displays a list of service items and allows adding/editing/deleting them.
class ServiceItemListView extends ConsumerWidget {
  const ServiceItemListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceItemsAsyncValue = ref.watch(serviceItemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Items'),
      ),
      body: serviceItemsAsyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No service items added yet.\nTap the + button to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    currencyFormatter.format(item.price),
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceItemFormView(serviceItem: item),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showConfirmationDialog(
                            context,
                            title: 'Delete Service Item',
                            content: 'Are you sure you want to delete "${item.name}"?',
                            confirmButtonColor: Colors.red,
                          );
                          if (confirm == true) {
                            ref.read(serviceItemProvider.notifier).deleteServiceItem(item.id!);
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
            MaterialPageRoute(
              builder: (context) => const ServiceItemFormView(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

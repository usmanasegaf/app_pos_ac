import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart';
import 'package:app_pos_ac/presentation/features/service_items/views/service_item_form_view.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';

class ServiceItemListView extends ConsumerWidget {
  const ServiceItemListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceItemsAsyncValue = ref.watch(serviceItemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Layanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: serviceItemsAsyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada layanan terdaftar.\nTekan tombol + untuk menambahkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(formatter.format(item.price),
                      style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
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
                            title: 'Hapus Layanan',
                            content: 'Yakin ingin menghapus "${item.name}"?',
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
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServiceItemFormView()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

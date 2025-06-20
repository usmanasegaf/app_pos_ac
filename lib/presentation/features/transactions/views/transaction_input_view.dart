import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart';
import 'package:app_pos_ac/presentation/features/transactions/viewmodels/transaction_input_viewmodel.dart';
import 'package:app_pos_ac/presentation/features/transactions/viewmodels/transaction_history_viewmodel.dart';
import 'package:intl/intl.dart';

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
    final notifier = ref.read(transactionInputProvider.notifier);
    _customerNameController.text = notifier.customerName;
    _customerAddressController.text = notifier.customerAddress ?? '';
    _customerNameController.addListener(() {
      notifier.setCustomerName(_customerNameController.text);
    });
    _customerAddressController.addListener(() {
      notifier.setCustomerAddress(_customerAddressController.text);
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  void _showServiceItemSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final serviceItems = ref.watch(serviceItemProvider);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Pilih Layanan'),
          content: serviceItems.when(
            data: (items) {
              if (items.isEmpty) return const Text('Tidak ada layanan tersedia.');
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(currencyFormatter.format(item.price)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () {
                          ref.read(transactionInputProvider.notifier).addItemToCart(item);
                          Navigator.pop(dialogContext);
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
          ],
        );
      },
    );
  }

  Future<void> _finalizeTransaction() async {
    final notifier = ref.read(transactionInputProvider.notifier);
    if (notifier.customerName.isEmpty) {
      await showAppMessageDialog(context, title: 'Nama Pelanggan Wajib', message: 'Harap isi nama pelanggan.');
      return;
    }
    if ((notifier.state.value ?? []).isEmpty) {
      await showAppMessageDialog(context, title: 'Keranjang Kosong', message: 'Tambahkan layanan terlebih dahulu.');
      return;
    }

    final confirm = await showConfirmationDialog(context, title: 'Konfirmasi', content: 'Simpan transaksi ini?');
    if (confirm == true) {
      try {
        await notifier.finalizeTransaction();
        ref.read(transactionHistoryProvider.notifier).refreshTransactions();
        await showAppMessageDialog(context, title: 'Berhasil', message: 'Transaksi berhasil disimpan.');
      } catch (e) {
        await showAppMessageDialog(context, title: 'Gagal', message: 'Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(transactionInputProvider);
    final notifier = ref.read(transactionInputProvider.notifier);
    final total = notifier.calculateTotal();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        title: const Text('Transaksi Baru', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Kosongkan Keranjang',
            onPressed: () async {
              final confirm = await showConfirmationDialog(
                context,
                title: 'Kosongkan Data',
                content: 'Hapus seluruh data pelanggan dan item?',
                confirmButtonColor: Colors.red,
              );
              if (confirm == true) {
                notifier.clearTransaction();
                _customerNameController.clear();
                _customerAddressController.clear();
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pelanggan',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customerAddressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat Pelanggan',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => _showServiceItemSelectionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Layanan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cartItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada item.\nTambahkan layanan untuk memulai transaksi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final cart = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cart.serviceItem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${currencyFormatter.format(cart.serviceItem.price)} x ${cart.quantity}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormatter.format(cart.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.orange),
                              onPressed: () {
                                cart.quantity > 1
                                    ? notifier.updateItemQuantity(cart.serviceItem, cart.quantity - 1)
                                    : notifier.removeItemFromCart(cart.serviceItem);
                              },
                            ),
                            Text('${cart.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () {
                                notifier.updateItemQuantity(cart.serviceItem, cart.quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => notifier.removeItemFromCart(cart.serviceItem),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Divider(thickness: 1.5, color: Colors.grey[300]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(currencyFormatter.format(total),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _finalizeTransaction,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Simpan Transaksi'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

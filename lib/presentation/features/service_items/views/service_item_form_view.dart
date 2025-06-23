// lib/presentation/features/service_items/views/service_item_form_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';
import 'package:flutter/services.dart'; // <<<--- TAMBAHKAN IMPORT INI

class ServiceItemFormView extends ConsumerStatefulWidget {
  final ServiceItem? serviceItem;

  const ServiceItemFormView({super.key, this.serviceItem});

  @override
  ConsumerState<ServiceItemFormView> createState() => _ServiceItemFormViewState();
}

class _ServiceItemFormViewState extends ConsumerState<ServiceItemFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.serviceItem?.name ?? '');
    _priceController = TextEditingController(
        // Menampilkan 0 jika null atau tidak valid, agar tidak crash
        text: widget.serviceItem?.price?.toStringAsFixed(0) ?? '0'); // Mengubah dari toStringAsFixed(0) agar konsisten
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      // Pastikan parsing double bisa menangani tanda minus
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      // Validasi tambahan: jika price negatif, pastikan itu benar-benar diskon
      // (ini mungkin akan ditangani lebih baik di viewmodel atau logika bisnis)
      if (price.isNaN) { // Untuk berjaga-jaga jika parsing gagal meskipun sudah diformat
        if (mounted) {
          await showAppMessageDialog(
            context,
            title: 'Input Tidak Valid',
            message: 'Harga yang dimasukkan tidak valid. Harap masukkan angka.',
          );
        }
        return;
      }

      final serviceItemNotifier = ref.read(serviceItemProvider.notifier);

      try {
        final newItem = ServiceItem(
          id: widget.serviceItem?.id,
          name: name,
          price: price,
        );

        if (widget.serviceItem == null) {
          await serviceItemNotifier.addServiceItem(newItem);
          if (mounted) {
            await showAppMessageDialog(
              context,
              title: 'Berhasil',
              message: 'Layanan berhasil ditambahkan.',
            );
          }
        } else {
          await serviceItemNotifier.updateServiceItem(newItem);
          if (mounted) {
            await showAppMessageDialog(
              context,
              title: 'Berhasil',
              message: 'Layanan berhasil diperbarui.',
            );
          }
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          await showAppMessageDialog(
            context,
            title: 'Error',
            message: e.toString(),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceItem == null ? 'Tambah Layanan' : 'Edit Layanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Layanan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Nama layanan wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                // Mengubah keyboardType agar mendukung tanda minus
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), // <<<--- PERUBAHAN UTAMA DI SINI
                // Tambahkan inputFormatters untuk mengizinkan digit, titik, dan minus
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')), // Mengizinkan minus di awal, digit, dan satu titik
                ], // <<<--- PERUBAHAN UTAMA DI SINI
                decoration: InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Harga wajib diisi';
                  // Izinkan parsing dengan tanda minus
                  if (double.tryParse(value) == null) return 'Format harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(widget.serviceItem == null ? Icons.add : Icons.save),
                  label: Text(widget.serviceItem == null ? 'Tambah Layanan' : 'Simpan Perubahan'),
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

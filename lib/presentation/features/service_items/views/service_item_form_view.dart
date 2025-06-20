import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';

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
        text: widget.serviceItem?.price.toStringAsFixed(0) ?? '');
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
      final price = double.tryParse(_priceController.text) ?? 0.0;
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Harga wajib diisi';
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

// lib/presentation/features/service_items/views/service_item_form_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart'; // Import for dialogs

/// A form view for adding or editing a service item.
class ServiceItemFormView extends ConsumerStatefulWidget {
  final ServiceItem? serviceItem; // Optional: for editing existing item

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
    _priceController = TextEditingController(text: widget.serviceItem?.price.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Handles the form submission (add or update).
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final String name = _nameController.text.trim();
      final double price = double.tryParse(_priceController.text) ?? 0.0;

      final serviceItemNotifier = ref.read(serviceItemProvider.notifier);

try {
  final newItem = ServiceItem(
    id: widget.serviceItem?.id, // id bisa null untuk item baru
    name: name,
    price: price,
  );

  if (widget.serviceItem == null) {
    // Add new item
    await serviceItemNotifier.addServiceItem(newItem);
    if (mounted) {
      await showAppMessageDialog(
        context,
        title: 'Success',
        message: 'Service item added successfully!',
      );
    }
  } else {
    // Update existing item
    await serviceItemNotifier.updateServiceItem(newItem);
    if (mounted) {
      await showAppMessageDialog(
        context,
        title: 'Success',
        message: 'Service item updated successfully!',
      );
    }
  }

  if (mounted) Navigator.pop(context); // Go back to list view
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
        title: Text(widget.serviceItem == null ? 'Add Service Item' : 'Edit Service Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Service name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixText: 'Rp ', // Menambahkan prefix Rupiah
                ),
                // --- PENTING: Pastikan ini benar dan tidak diubah ---
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price cannot be empty';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid price format';
                  }
                  // Tidak ada validasi `price < 0` di sini
                  return null;
                },
                // --- Akhir Perubahan ---
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(widget.serviceItem == null ? Icons.add : Icons.save),
                  label: Text(widget.serviceItem == null ? 'Add Service' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
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

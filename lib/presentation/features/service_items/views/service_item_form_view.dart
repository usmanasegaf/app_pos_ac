// lib/presentation/features/service_items/views/service_item_form_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart'; // Revised package name
import 'package:app_pos_ac/presentation/features/service_items/viewmodels/service_item_viewmodel.dart'; // Revised package name

/// A form for adding new service items or editing existing ones.
class ServiceItemFormView extends ConsumerStatefulWidget {
  final ServiceItem? serviceItem; // Optional: for editing existing items

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

  /// Handles saving a new or updating an existing service item.
  void _saveServiceItem() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      if (widget.serviceItem == null) {
        // Add new item
        final newItem = ServiceItem(name: name, price: price);
        ref.read(serviceItemProvider.notifier).addServiceItem(newItem);
      } else {
        // Update existing item
        final updatedItem = widget.serviceItem!.copyWith(name: name, price: price);
        ref.read(serviceItemProvider.notifier).updateServiceItem(updatedItem);
      }
      Navigator.pop(context); // Go back to the list view
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    return 'Please enter a service name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (Rp)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Allow numbers and up to 2 decimals
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveServiceItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  widget.serviceItem == null ? 'Add Service' : 'Update Service',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/presentation/features/service_items/viewmodels/service_item_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/data/repositories/service_item_repository.dart'; // Corrected import path

/// StateNotifier for managing ServiceItem data.
class ServiceItemNotifier extends StateNotifier<AsyncValue<List<ServiceItem>>> {
  final ServiceItemRepository _repository;

  ServiceItemNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadServiceItems(); // Load items when the notifier is created
  }

  /// Loads all service items from the repository.
  Future<void> _loadServiceItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.getServiceItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adds a new service item to the database.
  // Menerima objek ServiceItem secara langsung
  Future<void> addServiceItem(ServiceItem item) async { // <-- PERUBAHAN DI SINI
    if (item.name.isEmpty) { // Validasi nama dari objek item
      throw Exception('Service name cannot be empty.');
    }
    // Tidak ada validasi harga negatif di sini, karena sudah diizinkan.

    try {
      state = const AsyncValue.loading();
      await _repository.addServiceItem(item); // Melewatkan objek item
      await _loadServiceItems(); // Reload to update UI
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates an existing service item in the database.
  // Menerima objek ServiceItem secara langsung
  Future<void> updateServiceItem(ServiceItem item) async { // <-- PERUBAHAN DI SINI
    if (item.name.isEmpty) { // Validasi nama dari objek item
      throw Exception('Service name cannot be empty.');
    }
    if (item.id == null) { // Pastikan ada ID untuk update
      throw Exception('Service item ID is required for update.');
    }
    // Tidak ada validasi harga negatif di sini, karena sudah diizinkan.

    try {
      state = const AsyncValue.loading();
      await _repository.updateServiceItem(item); // Melewatkan objek item
      await _loadServiceItems(); // Reload to update UI
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Deletes a service item by its ID.
  Future<void> deleteServiceItem(int id) async {
    try {
      // Optimistically update the UI
      if (state is AsyncData) {
        state = AsyncValue.data(state.value!.where((item) => item.id != id).toList());
      }
      await _repository.deleteServiceItem(id);
      await _loadServiceItems(); // Reload from DB to ensure consistency
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await _loadServiceItems(); // Revert to actual state if error
    }
  }
}

/// Provider for [ServiceItemNotifier].
final serviceItemProvider = StateNotifierProvider<ServiceItemNotifier, AsyncValue<List<ServiceItem>>>((ref) {
  final repository = ref.watch(serviceItemRepositoryProvider);
  return ServiceItemNotifier(repository);
});

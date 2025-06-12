// lib/presentation/features/service_items/viewmodels/service_item_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart'; // Revised package name
import 'package:app_pos_ac/data/repositories/service_item_repository.dart'; // Revised package name

/// StateNotifier for managing the list of [ServiceItem]s.
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

  /// Adds a new service item.
  Future<void> addServiceItem(ServiceItem item) async {
    try {
      // Optimistically update the UI
      if (state is AsyncData) {
        state = AsyncValue.data([...state.value!, item]);
      }
      await _repository.addServiceItem(item);
      await _loadServiceItems(); // Reload from DB to get the actual ID
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await _loadServiceItems(); // Revert to actual state if error
    }
  }

  /// Updates an existing service item.
  Future<void> updateServiceItem(ServiceItem item) async {
    try {
      // Optimistically update the UI
      if (state is AsyncData) {
        state = AsyncValue.data([
          for (final i in state.value!)
            if (i.id == item.id) item else i,
        ]);
      }
      await _repository.updateServiceItem(item);
      await _loadServiceItems(); // Reload from DB
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await _loadServiceItems(); // Revert to actual state if error
    }
  }

  /// Deletes a service item.
  Future<void> deleteServiceItem(int id) async {
    try {
      // Optimistically update the UI
      if (state is AsyncData) {
        state = AsyncValue.data(state.value!.where((item) => item.id != id).toList());
      }
      await _repository.deleteServiceItem(id);
      await _loadServiceItems(); // Reload from DB
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

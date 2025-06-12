// lib/data/repositories/service_item_repository.dart

import 'package:app_pos_ac/data/datasources/local/service_item_dao.dart'; // Revised package name
import 'package:app_pos_ac/data/models/service_item.dart'; // Revised package name
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/presentation/providers/database_providers.dart'; // Revised package name

/// Repository for managing ServiceItem data.
/// This layer abstracts the data source (e.g., local database) from the rest of the application.
class ServiceItemRepository {
  final ServiceItemDao _serviceItemDao;

  ServiceItemRepository(this._serviceItemDao);

  /// Inserts a new [ServiceItem].
  Future<int> addServiceItem(ServiceItem item) {
    return _serviceItemDao.insertServiceItem(item);
  }

  /// Retrieves all [ServiceItem]s.
  Future<List<ServiceItem>> getServiceItems() {
    return _serviceItemDao.getServiceItems();
  }

  /// Updates an existing [ServiceItem].
  Future<int> updateServiceItem(ServiceItem item) {
    return _serviceItemDao.updateServiceItem(item);
  }

  /// Deletes a [ServiceItem] by its ID.
  Future<int> deleteServiceItem(int id) {
    return _serviceItemDao.deleteServiceItem(id);
  }

  /// Deletes all service items.
  Future<int> deleteAllServiceItems() {
    return _serviceItemDao.deleteAllServiceItems();
  }
}

/// Provider for [ServiceItemRepository].
/// It depends on [serviceItemDaoProvider].
final serviceItemRepositoryProvider = Provider<ServiceItemRepository>((ref) {
  final serviceItemDao = ref.watch(serviceItemDaoProvider);
  return ServiceItemRepository(serviceItemDao);
});

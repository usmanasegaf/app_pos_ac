// lib/data/datasources/local/service_item_dao.dart

import 'package:sqflite/sqflite.dart';
import 'package:app_pos_ac/core/constants/app_constants.dart';
import 'package:app_pos_ac/data/datasources/local/database_helper.dart';
import 'package:app_pos_ac/data/models/service_item.dart';

/// Data Access Object (DAO) for ServiceItem operations.
class ServiceItemDao {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserts a new [ServiceItem] into the database.
  /// Returns the ID of the newly inserted row.
  Future<int> insertServiceItem(ServiceItem item) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      AppConstants.serviceItemsTableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if item with same ID exists
    );
  }

  /// Retrieves all [ServiceItem]s from the database.
  Future<List<ServiceItem>> getServiceItems() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.serviceItemsTableName);

    // Convert List<Map<String, dynamic>> to List<ServiceItem>.
    return List.generate(maps.length, (i) {
      return ServiceItem.fromMap(maps[i]);
    });
  }

  /// Updates an existing [ServiceItem] in the database.
  /// Returns the number of rows affected.
  Future<int> updateServiceItem(ServiceItem item) async {
    final db = await _databaseHelper.database;
    return await db.update(
      AppConstants.serviceItemsTableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deletes a [ServiceItem] from the database by its ID.
  /// Returns the number of rows affected.
  Future<int> deleteServiceItem(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      AppConstants.serviceItemsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all service items from the database.
  Future<int> deleteAllServiceItems() async {
    final db = await _databaseHelper.database;
    return await db.delete(AppConstants.serviceItemsTableName);
  }
}

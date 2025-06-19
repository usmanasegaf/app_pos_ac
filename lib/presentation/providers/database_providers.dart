// lib/presentation/providers/database_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/datasources/local/database_helper.dart';
import 'package:app_pos_ac/data/datasources/local/service_item_dao.dart';
import 'package:app_pos_ac/data/datasources/local/transaction_dao.dart';
import 'package:app_pos_ac/data/datasources/local/expense_dao.dart'; // <--- Tambahkan import ini
import 'package:app_pos_ac/data/repositories/expense_repository.dart'; // <--- Tambahkan import ini

/// Provides a singleton instance of [DatabaseHelper].
/// This provider ensures that the database is initialized once and reused across the app.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provides an instance of [ServiceItemDao].
/// It depends on the [databaseHelperProvider] to interact with the database.
final serviceItemDaoProvider = Provider<ServiceItemDao>((ref) {
  return ServiceItemDao();
});

/// Provides an instance of [TransactionDao].
/// It depends on the [databaseHelperProvider] to interact with the database.
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return TransactionDao(dbHelper);
});

/// Provides an instance of [ExpenseDao].
final expenseDaoProvider = Provider<ExpenseDao>((ref) { // <--- Tambahkan provider ini
  final dbHelper = ref.watch(databaseHelperProvider);
  return ExpenseDao(dbHelper);
});

/// Provides an instance of [ExpenseRepository].
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) { // <--- Tambahkan provider ini
  final expenseDao = ref.watch(expenseDaoProvider);
  return ExpenseRepository(expenseDao);
});


/// A FutureProvider that initializes the database and ensures it's ready before the app starts.
/// This is useful for displaying a loading screen or splash screen until the database is ready.
final databaseInitializationProvider = FutureProvider<void>((ref) async {
  final dbHelper = ref.read(databaseHelperProvider);
  // Await the database getter to ensure the database is opened and tables are created.
  await dbHelper.database;
});

// lib/data/repositories/transaction_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/datasources/local/transaction_dao.dart'; // Pastikan jalur ini benar
import 'package:app_pos_ac/data/models/transaction.dart'; // Mengimpor model TransactionAC
import 'package:app_pos_ac/presentation/providers/database_providers.dart'; // <--- Import ini yang ditambahkan

/// Repository untuk mengelola data TransactionAC.
/// Layer ini mengabstraksi sumber data (misalnya, database lokal) dari bagian aplikasi lainnya.
class TransactionRepository {
  final TransactionDao _transactionDao;

  // Constructor yang menerima instance TransactionDao
  TransactionRepository(this._transactionDao);

  /// Menyisipkan [TransactionAC] baru ke database.
  /// Mengembalikan ID dari baris yang baru disisipkan.
  Future<int> addTransaction(TransactionAC transaction) {
    return _transactionDao.insertTransaction(transaction);
  }

  /// Mengambil semua [TransactionAC] dari database.
  /// Mengembalikan daftar [TransactionAC].
  Future<List<TransactionAC>> getTransactions() {
    return _transactionDao.getTransactions();
  }

  /// Mengambil satu [TransactionAC] berdasarkan ID-nya.
  /// Mengembalikan [TransactionAC] jika ditemukan, null jika tidak.
  Future<TransactionAC?> getTransactionById(int id) {
    return _transactionDao.getTransactionById(id);
  }

  /// Memperbarui [TransactionAC] yang sudah ada di database.
  /// Mengembalikan jumlah baris yang terpengaruh.
  Future<int> updateTransaction(TransactionAC transaction) {
    return _transactionDao.updateTransaction(transaction);
  }

  /// Menghapus [TransactionAC] dari database berdasarkan ID-nya.
  /// Mengembalikan jumlah baris yang terpengaruh.
  Future<int> deleteTransaction(int id) {
    return _transactionDao.deleteTransaction(id);
  }
}

/// Provider untuk [TransactionRepository].
/// Bergantung pada [transactionDaoProvider] yang menyediakan instance TransactionDao.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final transactionDao = ref.watch(transactionDaoProvider); // Sekarang transactionDaoProvider akan dikenali
  return TransactionRepository(transactionDao);
});

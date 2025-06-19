// lib/data/datasources/local/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_pos_ac/core/constants/app_constants.dart';

/// A helper class to manage database creation and version management.
class DatabaseHelper {
  static Database? _database; // Private static instance of the database

  /// Private constructor to prevent direct instantiation.
  DatabaseHelper._privateConstructor();

  /// Singleton instance of DatabaseHelper.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  /// Gets the database instance, initializing it if it's not already.
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the database for the first time.
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database by opening it or creating it if it doesn't exist.
  Future<Database> _initDatabase() async {
    // Get the default database location for the platform.
    String documentsDirectory = await getDatabasesPath();
    // Join the path with the database file name.
    String path = join(documentsDirectory, AppConstants.databaseName);

    // Open the database. If it doesn't exist, onCreate will be called.
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate, // Called when the database is created for the first time.
      onUpgrade: _onUpgrade, // Called when the database needs to be upgraded.
    );
  }

  /// Callback function to create tables when the database is created.
  Future<void> _onCreate(Database db, int version) async {
    // Create Service Items table
    await db.execute('''
      CREATE TABLE ${AppConstants.serviceItemsTableName}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    // Create Transactions table
    // Note: 'items' column stores a JSON string of List<TransactionItem>
    await db.execute('''
      CREATE TABLE ${AppConstants.transactionsTableName}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        customerName TEXT NOT NULL,
        customerAddress TEXT,
        total REAL NOT NULL,
        items TEXT NOT NULL
      )
    ''');

    // --- TAMBAHKAN TABEL PENGELUARAN BARU DI SINI ---
    await db.execute('''
      CREATE TABLE ${AppConstants.expensesTableName}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    // --- AKHIR TAMBAHAN ---
  }

  /// Callback function to handle database upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // PENTING: Untuk menambahkan tabel baru, Anda HARUS meningkatkan databaseVersion
    // di AppConstants dan menambahkan logika di sini untuk versi yang lebih baru.
    // Jika tidak, tabel pengeluaran tidak akan dibuat di database yang sudah ada.
    if (oldVersion < newVersion) {
      if (newVersion == 2) { // Contoh: Jika versi baru adalah 2
         await db.execute('''
           CREATE TABLE ${AppConstants.expensesTableName}(
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             description TEXT NOT NULL,
             amount REAL NOT NULL,
             date TEXT NOT NULL
           )
         ''');
      }
      // Tambahkan logika upgrade lain di sini jika ada perubahan skema di masa mendatang
    }
  }

  /// Closes the database.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null; // Clear the instance
    }
  }
}

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/app/app.dart'; // Revised package name
import 'package:app_pos_ac/presentation/providers/database_providers.dart'; // Import the database initialization provider (Revised package name)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Ensure that Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // ProviderScope is necessary for Riverpod to work.
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          // Watch the database initialization provider.
          // This will ensure the database is ready before the app UI is built.
          final databaseInit = ref.watch(databaseInitializationProvider);

          return databaseInit.when(
            data: (_) => const PosAcApp(), // Database is ready, show the app
            loading: () => const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(), // Show loading indicator
                ),
              ),
            ),
            error: (err, stack) => MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error initializing database: $err'), // Show error
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

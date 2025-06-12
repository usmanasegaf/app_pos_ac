// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/presentation/features/home/views/home_screen.dart'; // Revised package name

/// The root widget of the application.
/// It wraps the MaterialApp with a ProviderScope to enable Riverpod.
class PosAcApp extends ConsumerWidget {
  const PosAcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // You can use a FutureBuilder here to show a splash screen
    // while the database is initializing, using databaseInitializationProvider.
    return MaterialApp(
      title: 'POS AC Service',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
      home: const HomeScreen(), // Our starting screen
    );
  }
}

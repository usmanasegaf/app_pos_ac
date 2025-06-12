// lib/data/models/transaction.dart

import 'dart:convert';
import 'package:app_pos_ac/data/models/transaction_item.dart';

/// Represents a single transaction record.
class TransactionAC {
  final int? id;
  final DateTime date;
  final String customerName;
  final String? customerAddress;
  final double total;
  final List<TransactionItem> items; // Stored as JSON string in DB

  TransactionAC({
    this.id,
    required this.date,
    required this.customerName,
    this.customerAddress,
    required this.total,
    required this.items,
  });

  /// Converts a [TransactionAC] object into a [Map] for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(), // Store DateTime as ISO 8601 string
      'customerName': customerName,
      'customerAddress': customerAddress,
      'total': total,
      // Encode List<TransactionItem> to JSON string
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
    };
  }

  /// Creates a [TransactionAC] object from a [Map] retrieved from the database.
  factory TransactionAC.fromMap(Map<String, dynamic> map) {
    return TransactionAC(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String), // Parse ISO 8601 string back to DateTime
      customerName: map['customerName'] as String,
      customerAddress: map['customerAddress'] as String?,
      total: map['total'] as double,
      // Decode JSON string back to List<TransactionItem>
      items: (jsonDecode(map['items'] as String) as List)
          .map((itemMap) => TransactionItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'TransactionAC(id: $id, date: $date, customerName: $customerName, customerAddress: $customerAddress, total: $total, items: $items)';
  }
}

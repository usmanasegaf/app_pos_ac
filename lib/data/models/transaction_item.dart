// lib/data/models/transaction_item.dart

/// Represents a single item within a transaction.
/// This model is used to store details of service items included in a transaction
/// as a JSON string within the main Transaction table.
class TransactionItem {
  final int serviceItemId;
  final String serviceName;
  final double servicePrice;
  final int quantity;
  final double subtotal;

  TransactionItem({
    required this.serviceItemId,
    required this.serviceName,
    required this.servicePrice,
    required this.quantity,
    required this.subtotal,
  });

  /// Converts a [TransactionItem] object into a [Map] for JSON encoding.
  Map<String, dynamic> toMap() {
    return {
      'serviceItemId': serviceItemId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  /// Creates a [TransactionItem] object from a [Map] (JSON decoded).
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      serviceItemId: map['serviceItemId'] as int,
      serviceName: map['serviceName'] as String,
      servicePrice: map['servicePrice'] as double,
      quantity: map['quantity'] as int,
      subtotal: map['subtotal'] as double,
    );
  }

  @override
  String toString() {
    return 'TransactionItem(serviceItemId: $serviceItemId, serviceName: $serviceName, servicePrice: $servicePrice, quantity: $quantity, subtotal: $subtotal)';
  }
}

// lib/data/models/service_item.dart

/// Represents a service item available for AC service.
class ServiceItem {
  final int? id;
  final String name;
  final double price;

  ServiceItem({
    this.id,
    required this.name,
    required this.price,
  });

  /// Converts a [ServiceItem] object into a [Map] for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  /// Creates a [ServiceItem] object from a [Map] retrieved from the database.
  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: map['price'] as double,
    );
  }

  /// Creates a new [ServiceItem] instance with updated values.
  ServiceItem copyWith({
    int? id,
    String? name,
    double? price,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  @override
  String toString() {
    return 'ServiceItem(id: $id, name: $name, price: $price)';
  }
}

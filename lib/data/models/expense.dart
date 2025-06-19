// lib/data/models/expense.dart

/// Represents an expense record in the application.
class Expense {
  final int? id; // Null for new expenses
  final String description;
  final double amount; // Amount of the expense (should always be positive)
  final DateTime date;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  /// Converts an [Expense] object into a [Map] for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(), // Store date as ISO 8601 string
    };
  }

  /// Creates an [Expense] object from a [Map] retrieved from the database.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
    );
  }

  /// Creates a new [Expense] instance with updated values.
  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, description: $description, amount: $amount, date: $date)';
  }
}

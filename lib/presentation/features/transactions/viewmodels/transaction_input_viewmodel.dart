// lib/presentation/features/transactions/viewmodels/transaction_input_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart';
import 'package:app_pos_ac/data/repositories/transaction_repository.dart';

/// Represents an item currently in the transaction cart.
class CartItem {
  final ServiceItem serviceItem;
  int quantity;

  CartItem({required this.serviceItem, this.quantity = 1});

  double get subtotal => serviceItem.price * quantity;

  // For UI updates, allowing a copy with new quantity
  CartItem copyWith({
    ServiceItem? serviceItem,
    int? quantity,
  }) {
    return CartItem(
      serviceItem: serviceItem ?? this.serviceItem,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// StateNotifier for managing the current transaction being built.
class TransactionInputNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final TransactionRepository _transactionRepository;

  // Initial state is an empty list of cart items.
  TransactionInputNotifier(this._transactionRepository) : super(const AsyncValue.data([]));

  String _customerName = '';
  String? _customerAddress;

  String get customerName => _customerName;
  String? get customerAddress => _customerAddress;

  /// Sets the customer name for the current transaction.
  void setCustomerName(String name) {
    _customerName = name;
  }

  /// Sets the customer address for the current transaction.
  void setCustomerAddress(String? address) {
    _customerAddress = address;
  }

  /// Adds a service item to the cart. If the item already exists, increments its quantity.
  void addItemToCart(ServiceItem item) {
    final currentItems = state.value ?? [];
    final existingItemIndex = currentItems.indexWhere((cartItem) => cartItem.serviceItem.id == item.id);

    if (existingItemIndex != -1) {
      // Item already in cart, increment quantity
      final updatedItems = List<CartItem>.from(currentItems);
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
        quantity: updatedItems[existingItemIndex].quantity + 1,
      );
      state = AsyncValue.data(updatedItems);
    } else {
      // New item, add to cart
      state = AsyncValue.data([...currentItems, CartItem(serviceItem: item)]);
    }
  }

  /// Updates the quantity of an item in the cart.
  /// If quantity is 0 or less, removes the item from the cart.
  void updateItemQuantity(ServiceItem item, int newQuantity) {
    final currentItems = state.value ?? [];
    final updatedItems = currentItems.map((cartItem) {
      if (cartItem.serviceItem.id == item.id) {
        return cartItem.copyWith(quantity: newQuantity);
      }
      return cartItem;
    }).toList();

    state = AsyncValue.data(updatedItems.where((item) => item.quantity > 0).toList());
  }

  /// Removes an item from the cart.
  void removeItemFromCart(ServiceItem item) {
    final currentItems = state.value ?? [];
    state = AsyncValue.data(currentItems.where((cartItem) => cartItem.serviceItem.id != item.id).toList());
  }

  /// Calculates the total amount of the current transaction.
  double calculateTotal() {
    final currentItems = state.value ?? [];
    return currentItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Finalizes the transaction and saves it to the database.
  Future<void> finalizeTransaction() async {
    final currentItems = state.value ?? [];
    if (currentItems.isEmpty || _customerName.isEmpty) {
      // Handle error: no items or customer name missing
      throw Exception('Transaction must have items and a customer name.');
    }

    try {
      state = AsyncValue.loading(); // Indicate loading state
      final transactionItems = currentItems.map((cartItem) {
        return TransactionItem(
          serviceItemId: cartItem.serviceItem.id!,
          serviceName: cartItem.serviceItem.name,
          servicePrice: cartItem.serviceItem.price,
          quantity: cartItem.quantity,
          subtotal: cartItem.subtotal,
        );
      }).toList();

      final newTransaction = TransactionAC( // Use TransactionAC
        date: DateTime.now(),
        customerName: _customerName,
        customerAddress: _customerAddress,
        total: calculateTotal(),
        items: transactionItems,
      );

      await _transactionRepository.addTransaction(newTransaction);
      state = const AsyncValue.data([]); // Clear cart after successful transaction
      _customerName = ''; // Clear customer name
      _customerAddress = null; // Clear customer address
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Revert to previous state or show error message
      rethrow; // Re-throw to be caught by UI
    }
  }

  /// Clears the current transaction cart and customer details.
  void clearTransaction() {
    state = const AsyncValue.data([]);
    _customerName = '';
    _customerAddress = null;
  }
}

/// Provider for [TransactionInputNotifier].
final transactionInputProvider = StateNotifierProvider<TransactionInputNotifier, AsyncValue<List<CartItem>>>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return TransactionInputNotifier(transactionRepository);
});

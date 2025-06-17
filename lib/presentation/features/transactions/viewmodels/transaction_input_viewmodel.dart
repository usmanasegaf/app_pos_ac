import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_pos_ac/data/models/service_item.dart';
import 'package:app_pos_ac/data/models/transaction.dart'; // TransactionAC
import 'package:app_pos_ac/data/models/transaction_item.dart';
import 'package:app_pos_ac/data/repositories/transaction_repository.dart';
import 'package:app_pos_ac/presentation/features/transactions/viewmodels/transaction_history_viewmodel.dart';
import 'dart:ui';

class CartItem {
  final ServiceItem serviceItem;
  int quantity;

  CartItem({required this.serviceItem, this.quantity = 1});

  double get subtotal => serviceItem.price * quantity;

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

class TransactionInputNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final TransactionRepository _transactionRepository;
  final VoidCallback? _onTransactionFinalized; // Jadikan nullable dan aman

  TransactionInputNotifier(this._transactionRepository, [this._onTransactionFinalized])
      : super(const AsyncValue.data([]));

  String _customerName = '';
  String? _customerAddress;

  String get customerName => _customerName;
  String? get customerAddress => _customerAddress;

  void setCustomerName(String name) {
    _customerName = name;
  }

  void setCustomerAddress(String? address) {
    _customerAddress = address;
  }

  void addItemToCart(ServiceItem item) {
    final currentItems = state.value ?? [];
    final existingItemIndex = currentItems.indexWhere((cartItem) => cartItem.serviceItem.id == item.id);

    if (existingItemIndex != -1) {
      final updatedItems = List<CartItem>.from(currentItems);
      updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
        quantity: updatedItems[existingItemIndex].quantity + 1,
      );
      state = AsyncValue.data(updatedItems);
    } else {
      state = AsyncValue.data([...currentItems, CartItem(serviceItem: item)]);
    }
  }

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

  void removeItemFromCart(ServiceItem item) {
    final currentItems = state.value ?? [];
    state = AsyncValue.data(currentItems.where((cartItem) => cartItem.serviceItem.id != item.id).toList());
  }

  double calculateTotal() {
    final currentItems = state.value ?? [];
    return currentItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  Future<void> finalizeTransaction() async {
    final currentItems = state.value ?? [];
    if (currentItems.isEmpty || _customerName.isEmpty) {
      throw Exception('Transaction must have items and a customer name.');
    }

    final transactionItems = currentItems.map((cartItem) {
      return TransactionItem(
        serviceItemId: cartItem.serviceItem.id!,
        serviceName: cartItem.serviceItem.name,
        servicePrice: cartItem.serviceItem.price,
        quantity: cartItem.quantity,
        subtotal: cartItem.subtotal,
      );
    }).toList();

    final totalAmount = calculateTotal();

    final newTransaction = TransactionAC(
      date: DateTime.now(),
      customerName: _customerName,
      customerAddress: _customerAddress,
      total: totalAmount,
      items: transactionItems,
    );

    try {
      state = AsyncValue.loading();
      await _transactionRepository.addTransaction(newTransaction);
      state = const AsyncValue.data([]); // Clear cart after successful transaction
      _customerName = '';
      _customerAddress = null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    } finally {
      // Panggil callback jika ada, untuk refresh history
      if (_onTransactionFinalized != null) {
        await Future.delayed(Duration.zero);
        _onTransactionFinalized!();
      }
    }
  }

  void clearTransaction() {
    state = const AsyncValue.data([]);
    _customerName = '';
    _customerAddress = null;
  }
}

final transactionInputProvider = StateNotifierProvider<TransactionInputNotifier, AsyncValue<List<CartItem>>>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final onTransactionFinalized = () {
    ref.invalidate(transactionHistoryProvider);
  };
  return TransactionInputNotifier(transactionRepository, onTransactionFinalized);
});
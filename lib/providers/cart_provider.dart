import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/topping_selection_model.dart';


// ===== Cart State =====
class CartState {
  final List<CartItemModel> items;
  final String? note;
  final String? storeName;
  final String? distance;
  final IconData? icon;

  const CartState({
    this.items = const [],
    this.note,
    this.storeName,
    this.distance,
    this.icon,
  });

  CartState copyWith({
    List<CartItemModel>? items,
    String? note,
    String? storeName,
    String? distance,
    IconData? icon,
  }) {
    return CartState(
      items: items ?? this.items,
      note: note ?? this.note,
      storeName: storeName ?? this.storeName,
      distance: distance ?? this.distance,
      icon: icon ?? this.icon,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  // Simulated discount (matches web app mock: -19000)
  int get discount => items.isNotEmpty ? 19000 : 0;

  int get total => subtotal - discount;

  bool get isEmpty => items.isEmpty;
}

// ===== Cart Notifier =====
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState(items: []));

  void addItem(
    CartItemModel item, {
    String? storeName,
    String? distance,
    IconData? icon,
  }) {
    final existingIndex = state.items.indexWhere((i) => i.id == item.id);
    List<CartItemModel> updatedItems;
    if (existingIndex >= 0) {
      final updated = List<CartItemModel>.from(state.items);
      updated[existingIndex] = updated[existingIndex]
          .copyWith(quantity: updated[existingIndex].quantity + item.quantity);
      updatedItems = updated;
    } else {
      updatedItems = [...state.items, item];
    }
    state = state.copyWith(
      items: updatedItems,
      storeName: storeName ?? state.storeName,
      distance: distance ?? state.distance,
      icon: icon ?? state.icon,
    );
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final updated = state.items.map((item) {
      if (item.id == id) return item.copyWith(quantity: quantity);
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void updateItem(
    String id, {
    required int quantity,
    String? note,
    required List<ToppingSelectionModel> selectedToppings,
  }) {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(
          quantity: quantity,
          note: note,
          selectedToppings: selectedToppings,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = const CartState();
  }
}

// ===== Provider =====
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

// Derived providers
final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).totalItems,
);

final cartTotalProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).total,
);

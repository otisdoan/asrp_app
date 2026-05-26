import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item_model.dart';
import '../data/repositories/mock_data.dart';

// ===== Cart State =====
class CartState {
  final List<CartItemModel> items;
  final String? note;

  const CartState({
    this.items = const [],
    this.note,
  });

  CartState copyWith({
    List<CartItemModel>? items,
    String? note,
  }) {
    return CartState(
      items: items ?? this.items,
      note: note ?? this.note,
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
  CartNotifier() : super(CartState(items: MockData.initialCartItems));

  void addItem(CartItemModel item) {
    final existingIndex = state.items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      final updated = List<CartItemModel>.from(state.items);
      updated[existingIndex] = updated[existingIndex]
          .copyWith(quantity: updated[existingIndex].quantity + item.quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
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

  void clearCart() {
    state = state.copyWith(items: []);
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


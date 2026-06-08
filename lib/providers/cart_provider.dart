import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/topping_selection_model.dart';

// ===== Cart State =====
class CartState {
  final List<CartItemModel> items;
  final String? note;
  final String? storeName;
  final String? distance;
  final String? deliveryTime;
  final String? storeImageUrl;
  final IconData? icon;

  const CartState({
    this.items = const [],
    this.note,
    this.storeName,
    this.distance,
    this.deliveryTime,
    this.storeImageUrl,
    this.icon,
  });

  CartState copyWith({
    List<CartItemModel>? items,
    String? note,
    String? storeName,
    String? distance,
    String? deliveryTime,
    String? storeImageUrl,
    IconData? icon,
  }) {
    return CartState(
      items: items ?? this.items,
      note: note ?? this.note,
      storeName: storeName ?? this.storeName,
      distance: distance ?? this.distance,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      storeImageUrl: storeImageUrl ?? this.storeImageUrl,
      icon: icon ?? this.icon,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  // Removed mock discount (set to 0)
  int get discount => 0;

  int get total => subtotal;

  bool get isEmpty => items.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      if (note != null) 'note': note,
      if (storeName != null) 'storeName': storeName,
      if (distance != null) 'distance': distance,
      if (deliveryTime != null) 'deliveryTime': deliveryTime,
      if (storeImageUrl != null) 'storeImageUrl': storeImageUrl,
      if (icon != null) ...{
        'iconCodePoint': icon!.codePoint,
        'iconFontFamily': icon!.fontFamily,
        'iconFontPackage': icon!.fontPackage,
      }
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    IconData? parsedIcon;
    if (json['iconCodePoint'] != null) {
      parsedIcon = IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      );
    }
    return CartState(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      note: json['note'] as String?,
      storeName: json['storeName'] as String?,
      distance: json['distance'] as String?,
      deliveryTime: json['deliveryTime'] as String?,
      storeImageUrl: json['storeImageUrl'] as String?,
      icon: parsedIcon,
    );
  }
}

// ===== Cart Notifier =====
class CartNotifier extends StateNotifier<CartState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _storageKey = 'local_cart_state';

  CartNotifier() : super(const CartState(items: [])) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
        state = CartState.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('[CartNotifier] Error loading cart from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonStr = json.encode(state.toJson());
      await _storage.write(key: _storageKey, value: jsonStr);
    } catch (e) {
      debugPrint('[CartNotifier] Error saving cart to storage: $e');
    }
  }

  void addItem(
    CartItemModel item, {
    String? storeName,
    String? distance,
    String? deliveryTime,
    String? storeImageUrl,
    IconData? icon,
  }) {
    if (state.storeName != null && storeName != null && state.storeName != storeName && state.items.isNotEmpty) {
      state = const CartState();
    }

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
      deliveryTime: deliveryTime ?? state.deliveryTime,
      storeImageUrl: storeImageUrl ?? state.storeImageUrl,
      icon: icon ?? state.icon,
    );
    _saveToStorage();
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
    _saveToStorage();
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
    _saveToStorage();
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
    _saveToStorage();
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
    _saveToStorage();
  }

  void clearCart() {
    state = const CartState();
    _saveToStorage();
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

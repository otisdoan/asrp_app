import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/topping_selection_model.dart';

// ===== Branch Cart State =====
class BranchCart {
  final List<CartItemModel> items;
  final String? note;
  final String? storeName;
  final String? distance;
  final String? deliveryTime;
  final String? storeImageUrl;
  final IconData? icon;
  final String? branchId;

  const BranchCart({
    this.items = const [],
    this.note,
    this.storeName,
    this.distance,
    this.deliveryTime,
    this.storeImageUrl,
    this.icon,
    this.branchId,
  });

  BranchCart copyWith({
    List<CartItemModel>? items,
    String? note,
    String? storeName,
    String? distance,
    String? deliveryTime,
    String? storeImageUrl,
    IconData? icon,
    String? branchId,
  }) {
    return BranchCart(
      items: items ?? this.items,
      note: note ?? this.note,
      storeName: storeName ?? this.storeName,
      distance: distance ?? this.distance,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      storeImageUrl: storeImageUrl ?? this.storeImageUrl,
      icon: icon ?? this.icon,
      branchId: branchId ?? this.branchId,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get total => subtotal;

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      if (note != null) 'note': note,
      if (storeName != null) 'storeName': storeName,
      if (distance != null) 'distance': distance,
      if (deliveryTime != null) 'deliveryTime': deliveryTime,
      if (storeImageUrl != null) 'storeImageUrl': storeImageUrl,
      if (branchId != null) 'branchId': branchId,
      if (icon != null) ...{
        'iconCodePoint': icon!.codePoint,
        'iconFontFamily': icon!.fontFamily,
        'iconFontPackage': icon!.fontPackage,
      }
    };
  }

  factory BranchCart.fromJson(Map<String, dynamic> json) {
    IconData? parsedIcon;
    if (json['iconCodePoint'] != null) {
      parsedIcon = IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      );
    }
    return BranchCart(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      note: json['note'] as String?,
      storeName: json['storeName'] as String?,
      distance: json['distance'] as String?,
      deliveryTime: json['deliveryTime'] as String?,
      storeImageUrl: json['storeImageUrl'] as String?,
      branchId: json['branchId'] as String?,
      icon: parsedIcon,
    );
  }
}

// ===== Global Cart State =====
class CartState {
  final Map<String, BranchCart> carts;

  const CartState({this.carts = const {}});

  int get totalItems => carts.values.fold(0, (sum, cart) => sum + cart.totalItems);
  int get subtotal => carts.values.fold(0, (sum, cart) => sum + cart.subtotal);
  int get total => carts.values.fold(0, (sum, cart) => sum + cart.total);
  int get discount => 0;
  bool get isEmpty => carts.isEmpty || carts.values.every((c) => c.items.isEmpty);

  // Backward Compatibility Getters (returns first branch cart's info or fallback)
  List<CartItemModel> get items => carts.values.isNotEmpty ? carts.values.first.items : const [];
  String? get note => carts.values.isNotEmpty ? carts.values.first.note : null;
  String? get storeName => carts.values.isNotEmpty ? carts.values.first.storeName : null;
  String? get distance => carts.values.isNotEmpty ? carts.values.first.distance : null;
  String? get deliveryTime => carts.values.isNotEmpty ? carts.values.first.deliveryTime : null;
  String? get storeImageUrl => carts.values.isNotEmpty ? carts.values.first.storeImageUrl : null;
  IconData? get icon => carts.values.isNotEmpty ? carts.values.first.icon : null;
  String? get branchId => carts.values.isNotEmpty ? carts.values.first.branchId : null;

  Map<String, dynamic> toJson() {
    return {
      'carts': carts.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('carts')) {
      final cartsJson = json['carts'] as Map<String, dynamic>;
      final parsedCarts = cartsJson.map(
        (key, value) => MapEntry(
          key,
          BranchCart.fromJson(value as Map<String, dynamic>),
        ),
      );
      return CartState(carts: parsedCarts);
    }
    // Backward compatibility for legacy single-cart JSON format
    final oldCart = BranchCart.fromJson(json);
    if (oldCart.items.isNotEmpty) {
      final bid = oldCart.branchId ?? 'default_branch';
      return CartState(carts: {bid: oldCart});
    }
    return const CartState();
  }
}

// ===== Cart Notifier =====
class CartNotifier extends StateNotifier<CartState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _storageKey = 'local_cart_state';

  CartNotifier() : super(const CartState()) {
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
    String? branchId,
  }) {
    final bid = branchId ?? 'default_branch';
    final existingCart = state.carts[bid] ?? BranchCart(
      items: [],
      branchId: bid,
      storeName: storeName,
      distance: distance,
      deliveryTime: deliveryTime,
      storeImageUrl: storeImageUrl,
      icon: icon,
    );

    final existingIndex = existingCart.items.indexWhere((i) {
      if (i.menuItemId != item.menuItemId) return false;
      if (i.sizeId != item.sizeId) return false;
      if (i.selectedToppings.length != item.selectedToppings.length) return false;
      
      final iToppings = i.selectedToppings.map((t) => t.toppingId).toList()..sort();
      final itemToppings = item.selectedToppings.map((t) => t.toppingId).toList()..sort();
      for (int k = 0; k < iToppings.length; k++) {
        if (iToppings[k] != itemToppings[k]) return false;
      }
      
      if (i.note != item.note) return false;
      return true;
    });

    List<CartItemModel> updatedItems;
    if (existingIndex >= 0) {
      final updated = List<CartItemModel>.from(existingCart.items);
      updated[existingIndex] = updated[existingIndex]
          .copyWith(quantity: updated[existingIndex].quantity + item.quantity);
      updatedItems = updated;
    } else {
      updatedItems = [...existingCart.items, item];
    }

    final newBranchCart = existingCart.copyWith(
      items: updatedItems,
      storeName: storeName ?? existingCart.storeName,
      distance: distance ?? existingCart.distance,
      deliveryTime: deliveryTime ?? existingCart.deliveryTime,
      storeImageUrl: storeImageUrl ?? existingCart.storeImageUrl,
      icon: icon ?? existingCart.icon,
    );

    final newCarts = Map<String, BranchCart>.from(state.carts);
    newCarts[bid] = newBranchCart;

    state = CartState(carts: newCarts);
    _saveToStorage();
  }

  void removeItem(String id) {
    final newCarts = Map<String, BranchCart>.from(state.carts);
    String? targetBranchId;
    for (var entry in newCarts.entries) {
      if (entry.value.items.any((i) => i.id == id)) {
        targetBranchId = entry.key;
        break;
      }
    }
    if (targetBranchId != null) {
      final currentBranchCart = newCarts[targetBranchId]!;
      final updatedItems = currentBranchCart.items.where((i) => i.id != id).toList();
      if (updatedItems.isEmpty) {
        newCarts.remove(targetBranchId);
      } else {
        newCarts[targetBranchId] = currentBranchCart.copyWith(items: updatedItems);
      }
      state = CartState(carts: newCarts);
      _saveToStorage();
    }
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final newCarts = Map<String, BranchCart>.from(state.carts);
    String? targetBranchId;
    for (var entry in newCarts.entries) {
      if (entry.value.items.any((i) => i.id == id)) {
        targetBranchId = entry.key;
        break;
      }
    }
    if (targetBranchId != null) {
      final currentBranchCart = newCarts[targetBranchId]!;
      final updatedItems = currentBranchCart.items.map((item) {
        if (item.id == id) return item.copyWith(quantity: quantity);
        return item;
      }).toList();
      newCarts[targetBranchId] = currentBranchCart.copyWith(items: updatedItems);
      state = CartState(carts: newCarts);
      _saveToStorage();
    }
  }

  void setNoteForBranch(String branchId, String note) {
    final newCarts = Map<String, BranchCart>.from(state.carts);
    if (newCarts.containsKey(branchId)) {
      newCarts[branchId] = newCarts[branchId]!.copyWith(note: note);
      state = CartState(carts: newCarts);
      _saveToStorage();
    }
  }

  void setNote(String note) {
    if (state.carts.isNotEmpty) {
      setNoteForBranch(state.carts.keys.first, note);
    }
  }

  void updateItem(
    String id, {
    required int quantity,
    String? note,
    required List<ToppingSelectionModel> selectedToppings,
  }) {
    final newCarts = Map<String, BranchCart>.from(state.carts);
    String? targetBranchId;
    for (var entry in newCarts.entries) {
      if (entry.value.items.any((i) => i.id == id)) {
        targetBranchId = entry.key;
        break;
      }
    }
    if (targetBranchId != null) {
      final currentBranchCart = newCarts[targetBranchId]!;
      final updatedItems = currentBranchCart.items.map((item) {
        if (item.id == id) {
          return item.copyWith(
            quantity: quantity,
            note: note,
            selectedToppings: selectedToppings,
          );
        }
        return item;
      }).toList();
      newCarts[targetBranchId] = currentBranchCart.copyWith(items: updatedItems);
      state = CartState(carts: newCarts);
      _saveToStorage();
    }
  }

  void clearBranchCart(String branchId) {
    final newCarts = Map<String, BranchCart>.from(state.carts);
    newCarts.remove(branchId);
    state = CartState(carts: newCarts);
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

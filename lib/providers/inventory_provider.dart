import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===== MODELS =====

class InventoryIngredient {
  final String id;
  final String name;
  final String unit;
  final double currentStock;
  final double minStockLevel;
  final String supplier;
  final String status; // 'Đủ hàng', 'Kho thấp', 'Cảnh báo', 'Sắp hết', 'Hết hàng'
  final Color statusColor;

  const InventoryIngredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
    required this.supplier,
    required this.status,
    required this.statusColor,
  });

  double get ratio => minStockLevel > 0 ? (currentStock / minStockLevel).clamp(0.0, 1.0) : 1.0;
  int get percentage => (ratio * 100).toInt();

  InventoryIngredient copyWith({
    String? id,
    String? name,
    String? unit,
    double? currentStock,
    double? minStockLevel,
    String? supplier,
    String? status,
    Color? statusColor,
  }) {
    return InventoryIngredient(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
    );
  }
}

class RecipeItem {
  final String ingredientId;
  final String ingredientName;
  final double quantityNeeded;
  final String unit;
  final int costEstimate;

  const RecipeItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityNeeded,
    required this.unit,
    required this.costEstimate,
  });

  RecipeItem copyWith({
    String? ingredientId,
    String? ingredientName,
    double? quantityNeeded,
    String? unit,
    int? costEstimate,
  }) {
    return RecipeItem(
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantityNeeded: quantityNeeded ?? this.quantityNeeded,
      unit: unit ?? this.unit,
      costEstimate: costEstimate ?? this.costEstimate,
    );
  }
}

class MenuItemRecipe {
  final String menuItemId;
  final String menuItemName;
  final int sellPrice;
  final List<RecipeItem> items;

  const MenuItemRecipe({
    required this.menuItemId,
    required this.menuItemName,
    required this.sellPrice,
    required this.items,
  });

  int get totalFoodCost => items.fold(0, (sum, item) => sum + item.costEstimate);
  double get foodCostPercentage => sellPrice > 0 ? (totalFoodCost / sellPrice) * 100 : 0.0;

  MenuItemRecipe copyWith({
    String? menuItemId,
    String? menuItemName,
    int? sellPrice,
    List<RecipeItem>? items,
  }) {
    return MenuItemRecipe(
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      sellPrice: sellPrice ?? this.sellPrice,
      items: items ?? this.items,
    );
  }
}

class InventoryTransaction {
  final String id;
  final DateTime timestamp;
  final String ingredientName;
  final double quantityChange;
  final String unit;
  final double afterStock;
  final String type; // 'Import', 'Deduction', 'Adjustment'
  final String reference;
  final String reason;

  const InventoryTransaction({
    required this.id,
    required this.timestamp,
    required this.ingredientName,
    required this.quantityChange,
    required this.unit,
    required this.afterStock,
    required this.type,
    required this.reference,
    required this.reason,
  });
}

// ===== STATE CLASS =====

class InventoryState {
  final List<InventoryIngredient> ingredients;
  final List<MenuItemRecipe> recipes;
  final List<InventoryTransaction> transactions;

  const InventoryState({
    this.ingredients = const [],
    this.recipes = const [],
    this.transactions = const [],
  });

  InventoryState copyWith({
    List<InventoryIngredient>? ingredients,
    List<MenuItemRecipe>? recipes,
    List<InventoryTransaction>? transactions,
  }) {
    return InventoryState(
      ingredients: ingredients ?? this.ingredients,
      recipes: recipes ?? this.recipes,
      transactions: transactions ?? this.transactions,
    );
  }

  int get totalStockValue {
    // Mock prices: Mì trứng 32k, Bò Mỹ 210k, Hành lá 18k, Gia vị 15k, Tôm tươi 12k, Dầu ăn 24k
    double val = 0;
    for (var ing in ingredients) {
      double price = 0;
      if (ing.name.contains('Mì')) price = 32000;
      else if (ing.name.contains('Bò')) price = 21000;
      else if (ing.name.contains('Hành')) price = 18000;
      else if (ing.name.contains('Gia')) price = 15000;
      else if (ing.name.contains('Tôm')) price = 12000;
      else if (ing.name.contains('Dầu')) price = 24000;
      else price = 10000;
      val += ing.currentStock * price;
    }
    return val.toInt();
  }

  int get outOfStockCount => ingredients.where((e) => e.status == 'Hết hàng' || e.currentStock <= 0).length;
  int get lowStockCount => ingredients.where((e) => e.status == 'Kho thấp' || e.status == 'Cảnh báo' || e.status == 'Sắp hết').length;
}

// ===== STATE NOTIFIER =====

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState()) {
    _loadInitialMockData();
  }

  void _loadInitialMockData() {
    final list = [
      const InventoryIngredient(
        id: 'ing_1',
        name: 'Mì trứng',
        unit: 'kg',
        currentStock: 120,
        minStockLevel: 250,
        supplier: 'Đầu mối Loan',
        status: 'Đủ hàng',
        statusColor: Color(0xFF2ECC71),
      ),
      const InventoryIngredient(
        id: 'ing_2',
        name: 'Thịt bò Mỹ',
        unit: 'kg',
        currentStock: 65,
        minStockLevel: 150,
        supplier: 'Thực Phẩm Vissan',
        status: 'Kho thấp',
        statusColor: Color(0xFFF1C40F),
      ),
      const InventoryIngredient(
        id: 'ing_3',
        name: 'Hành lá',
        unit: 'kg',
        currentStock: 8,
        minStockLevel: 60,
        supplier: 'Rau Sạch Đà Lạt',
        status: 'Cảnh báo',
        statusColor: Color(0xFFE74C3C),
      ),
      const InventoryIngredient(
        id: 'ing_4',
        name: 'Gia vị tổng hợp',
        unit: 'kg',
        currentStock: 110,
        minStockLevel: 180,
        supplier: 'Gia vị Kim Biên',
        status: 'Đủ hàng',
        statusColor: Color(0xFF2ECC71),
      ),
      const InventoryIngredient(
        id: 'ing_5',
        name: 'Tôm tươi',
        unit: 'kg',
        currentStock: 18,
        minStockLevel: 90,
        supplier: 'Hải sản Bình Điền',
        status: 'Sắp hết',
        statusColor: Color(0xFFE67E22),
      ),
      const InventoryIngredient(
        id: 'ing_6',
        name: 'Dầu ăn',
        unit: 'lít',
        currentStock: 5,
        minStockLevel: 80,
        supplier: 'Tường An Oil',
        status: 'Hết hàng',
        statusColor: Color(0xFFE74C3C),
      ),
    ];

    final initialRecipes = [
      const MenuItemRecipe(
        menuItemId: 'menu_1',
        menuItemName: 'Hủ tiếu Nam Vang',
        sellPrice: 45000,
        items: [
          RecipeItem(ingredientId: 'ing_1', ingredientName: 'Mì trứng', quantityNeeded: 150, unit: 'gram', costEstimate: 4800),
          RecipeItem(ingredientId: 'ing_5', ingredientName: 'Tôm tươi', quantityNeeded: 2, unit: 'con', costEstimate: 6000),
          RecipeItem(ingredientId: 'ing_4', ingredientName: 'Gia vị tổng hợp', quantityNeeded: 10, unit: 'gram', costEstimate: 3500),
        ],
      ),
      const MenuItemRecipe(
        menuItemId: 'menu_2',
        menuItemName: 'Hủ tiếu bò kho',
        sellPrice: 50000,
        items: [
          RecipeItem(ingredientId: 'ing_1', ingredientName: 'Mì trứng', quantityNeeded: 150, unit: 'gram', costEstimate: 4800),
          RecipeItem(ingredientId: 'ing_2', ingredientName: 'Thịt bò Mỹ', quantityNeeded: 100, unit: 'gram', costEstimate: 21000),
          RecipeItem(ingredientId: 'ing_3', ingredientName: 'Hành lá', quantityNeeded: 15, unit: 'gram', costEstimate: 500),
        ],
      ),
    ];

    final initialTransactions = [
      InventoryTransaction(
        id: 'tx_1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ingredientName: 'Thịt bò Mỹ',
        quantityChange: -3.0,
        unit: 'kg',
        afterStock: 62.0,
        type: 'Adjustment',
        reference: 'Phiếu kiểm kho',
        reason: 'Hết hạn',
      ),
      InventoryTransaction(
        id: 'tx_2',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        ingredientName: 'Mì trứng',
        quantityChange: -0.3,
        unit: 'kg',
        afterStock: 119.7,
        type: 'Deduction',
        reference: 'Đơn #1002',
        reason: 'Bán hàng',
      ),
      InventoryTransaction(
        id: 'tx_3',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        ingredientName: 'Tôm tươi',
        quantityChange: -4,
        unit: 'con',
        afterStock: 86,
        type: 'Deduction',
        reference: 'Đơn #1002',
        reason: 'Bán hàng',
      ),
      InventoryTransaction(
        id: 'tx_4',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        ingredientName: 'Thịt bò Mỹ',
        quantityChange: 50.0,
        unit: 'kg',
        afterStock: 65.0,
        type: 'Import',
        reference: 'Phiếu #82',
        reason: 'Nhập hàng',
      ),
      InventoryTransaction(
        id: 'tx_5',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        ingredientName: 'Mì trứng',
        quantityChange: 100.0,
        unit: 'kg',
        afterStock: 120.0,
        type: 'Import',
        reference: 'Phiếu #82',
        reason: 'Nhập hàng',
      ),
    ];

    state = InventoryState(
      ingredients: list,
      recipes: initialRecipes,
      transactions: initialTransactions,
    );
  }

  // --- ACTIONS ---

  void importStock({
    required String supplier,
    required List<Map<String, dynamic>> items,
  }) {
    final updatedIngredients = List<InventoryIngredient>.from(state.ingredients);
    final List<InventoryTransaction> newTransactions = [];
    final now = DateTime.now();

    for (var item in items) {
      final ingredientId = item['ingredientId'] as String;
      final quantity = item['quantity'] as double;

      final idx = updatedIngredients.indexWhere((e) => e.id == ingredientId);
      if (idx >= 0) {
        final current = updatedIngredients[idx];
        final newStock = current.currentStock + quantity;
        
        // Dynamic status helper
        String status = 'Đủ hàng';
        Color color = const Color(0xFF2ECC71);
        double ratio = newStock / current.minStockLevel;
        if (newStock <= 0) {
          status = 'Hết hàng';
          color = const Color(0xFFE74C3C);
        } else if (ratio < 0.15) {
          status = 'Hết hàng'; // matches visual mockup for cooking oil (5/80)
          color = const Color(0xFFE74C3C);
        } else if (ratio < 0.25) {
          status = 'Sắp hết';
          color = const Color(0xFFE67E22);
        } else if (ratio < 0.4) {
          status = 'Cảnh báo';
          color = const Color(0xFFE74C3C);
        } else if (ratio < 0.5) {
          status = 'Kho thấp';
          color = const Color(0xFFF1C40F);
        }

        updatedIngredients[idx] = current.copyWith(
          currentStock: newStock,
          status: status,
          statusColor: color,
        );

        newTransactions.add(InventoryTransaction(
          id: 'tx_${now.millisecondsSinceEpoch}_$ingredientId',
          timestamp: now,
          ingredientName: current.name,
          quantityChange: quantity,
          unit: current.unit,
          afterStock: newStock,
          type: 'Import',
          reference: 'Phiếu #${now.millisecondsSinceEpoch.toString().substring(8)}',
          reason: 'Nhập hàng',
        ));
      }
    }

    state = state.copyWith(
      ingredients: updatedIngredients,
      transactions: [...newTransactions, ...state.transactions],
    );
  }

  void reconcileStock(List<Map<String, dynamic>> audits) {
    final updatedIngredients = List<InventoryIngredient>.from(state.ingredients);
    final List<InventoryTransaction> newTransactions = [];
    final now = DateTime.now();

    for (var audit in audits) {
      final ingredientId = audit['ingredientId'] as String;
      final actualStock = audit['actualStock'] as double;
      final reason = audit['reason'] as String;

      final idx = updatedIngredients.indexWhere((e) => e.id == ingredientId);
      if (idx >= 0) {
        final current = updatedIngredients[idx];
        final diff = actualStock - current.currentStock;

        if (diff != 0) {
          // Dynamic status helper
          String status = 'Đủ hàng';
          Color color = const Color(0xFF2ECC71);
          double ratio = actualStock / current.minStockLevel;
          if (actualStock <= 0) {
            status = 'Hết hàng';
            color = const Color(0xFFE74C3C);
          } else if (ratio < 0.15) {
            status = 'Hết hàng';
            color = const Color(0xFFE74C3C);
          } else if (ratio < 0.25) {
            status = 'Sắp hết';
            color = const Color(0xFFE67E22);
          } else if (ratio < 0.4) {
            status = 'Cảnh báo';
            color = const Color(0xFFE74C3C);
          } else if (ratio < 0.5) {
            status = 'Kho thấp';
            color = const Color(0xFFF1C40F);
          }

          updatedIngredients[idx] = current.copyWith(
            currentStock: actualStock,
            status: status,
            statusColor: color,
          );

          newTransactions.add(InventoryTransaction(
            id: 'tx_${now.millisecondsSinceEpoch}_$ingredientId',
            timestamp: now,
            ingredientName: current.name,
            quantityChange: diff,
            unit: current.unit,
            afterStock: actualStock,
            type: 'Adjustment',
            reference: 'Phiếu kiểm kho',
            reason: reason,
          ));
        }
      }
    }

    state = state.copyWith(
      ingredients: updatedIngredients,
      transactions: [...newTransactions, ...state.transactions],
    );
  }

  void saveRecipe(String menuItemId, List<RecipeItem> items) {
    final idx = state.recipes.indexWhere((e) => e.menuItemId == menuItemId);
    if (idx >= 0) {
      final updatedRecipes = List<MenuItemRecipe>.from(state.recipes);
      updatedRecipes[idx] = updatedRecipes[idx].copyWith(items: items);
      state = state.copyWith(recipes: updatedRecipes);
    }
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(),
);

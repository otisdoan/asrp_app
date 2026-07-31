import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import 'auth_provider.dart';
import 'analytics_provider.dart';

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

  double get ratio {
    if (currentStock <= 0.001) return 0.0;
    if (minStockLevel <= 0.001) return 1.0;
    return (currentStock / minStockLevel).clamp(0.0, 1.0);
  }
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
  final bool isInitialized;

  const InventoryState({
    this.ingredients = const [],
    this.recipes = const [],
    this.transactions = const [],
    this.isInitialized = false,
  });

  InventoryState copyWith({
    List<InventoryIngredient>? ingredients,
    List<MenuItemRecipe>? recipes,
    List<InventoryTransaction>? transactions,
    bool? isInitialized,
  }) {
    return InventoryState(
      ingredients: ingredients ?? this.ingredients,
      recipes: recipes ?? this.recipes,
      transactions: transactions ?? this.transactions,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  int get totalStockValue {
    // Mock prices: Mì trứng 32k, Bò Mỹ 210k, Hành lá 18k, Gia vị 15k, Tôm tươi 12k, Dầu ăn 24k
    double val = 0;
    for (var ing in ingredients) {
      double price = 0;
      final nameLower = ing.name.toLowerCase();
      if (nameLower.contains('mì')) {
        price = 32000;
      } else if (nameLower.contains('bò')) {
        price = 21000;
      } else if (nameLower.contains('hành')) {
        price = 18000;
      } else if (nameLower.contains('gia')) {
        price = 15000;
      } else if (nameLower.contains('tôm')) {
        price = 12000;
      } else if (nameLower.contains('dầu')) {
        price = 24000;
      } else {
        price = 10000;
      }
      val += ing.currentStock * price;
    }
    return val.toInt();
  }

  int get outOfStockCount => ingredients.where((e) => e.status == 'Hết hàng' || e.currentStock <= 0).length;
  int get lowStockCount => ingredients.where((e) => e.status == 'Kho thấp' || e.status == 'Cảnh báo' || e.status == 'Sắp hết').length;
}

// ===== STATE NOTIFIER =====

class InventoryNotifier extends StateNotifier<InventoryState> {
  final Ref _ref;
  final DioClient _dioClient = DioClient();
  String? _branchId;

  InventoryNotifier(this._ref) : super(const InventoryState()) {
    fetchInventory();
  }

  Future<String?> _resolveBranchId() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;
    if (user.branchId != null && user.branchId!.isNotEmpty) {
      return user.branchId;
    }
    
    // Fallback 1: Query api/branches with brandId
    try {
      final response = await _dioClient.dio.get('/branches', queryParameters: {'brandId': user.brandId});
      final rawData = response.data;
      if (rawData is List && rawData.isNotEmpty) {
        return rawData.first['id'] as String?;
      }
      if (rawData is Map<String, dynamic>) {
        final items = rawData['items'] ?? rawData['data'];
        if (items is List && items.isNotEmpty) {
          return items.first['id'] as String? ?? items.first['branchId'] as String?;
        }
      }
    } catch (e) {
      print('[InventoryNotifier] Error resolving branchId via /branches: $e');
    }

    // Fallback 2: Query api/brands/me/branches
    try {
      final response = await _dioClient.dio.get('/brands/me/branches');
      final rawData = response.data;
      if (rawData is List && rawData.isNotEmpty) {
        return rawData.first['id'] as String? ?? rawData.first['branchId'] as String?;
      }
      if (rawData is Map<String, dynamic>) {
        final items = rawData['items'] ?? rawData['data'] ?? rawData['branches'];
        if (items is List && items.isNotEmpty) {
          return items.first['id'] as String? ?? items.first['branchId'] as String?;
        }
      }
    } catch (e) {
      print('[InventoryNotifier] Error resolving branchId via /brands/me/branches: $e');
    }

    // Fallback 3: Query api/analytics/brand-dashboard
    try {
      final response = await _dioClient.dio.get('/analytics/brand-dashboard');
      final rawData = response.data;
      if (rawData is Map<String, dynamic> && rawData['branches'] is List) {
        final List branches = rawData['branches'];
        if (branches.isNotEmpty) {
          return branches.first['branchId'] as String?;
        }
      }
    } catch (e) {
      print('[InventoryNotifier] Error resolving branchId via brand-dashboard: $e');
    }

    return null;
  }

  Future<void> fetchInventory() async {
    try {
      final branchId = await _resolveBranchId();
      if (branchId == null) {
        state = state.copyWith(isInitialized: true);
        return;
      }
      _branchId = branchId;

      print('[InventoryNotifier] Fetching inventory for branch: $branchId');
      
      final List<InventoryIngredient> ingredientsList = [];
      final List<InventoryTransaction> transactionsList = [];
      final List<MenuItemRecipe> recipesList = [];

      // 1. Fetch ingredients / branch inventory
      try {
        final invResponse = await _dioClient.dio.get('/inventory/branches/$branchId');
        final rawInv = invResponse.data;
        print('[InventoryNotifier] rawInv type: ${rawInv.runtimeType}');
        final invData = rawInv is List 
            ? rawInv 
            : (rawInv is Map<String, dynamic> && rawInv['data'] is List ? rawInv['data'] as List : []);
        print('[InventoryNotifier] Parsed ${invData.length} inventory items');

        for (var item in invData) {
          print('[InventoryNotifier] item map: $item');
          final double currentStock = (item['currentStock'] as num?)?.toDouble() ?? 0.0;
          final double minStockLevel = (item['minStockLevel'] as num?)?.toDouble() ?? 0.0;
          
          double ratio;
          if (currentStock <= 0.001) {
            ratio = 0.0;
          } else if (minStockLevel <= 0.001) {
            ratio = 1.0;
          } else {
            ratio = currentStock / minStockLevel;
          }
          
          String status = 'Đủ hàng';
          Color color = const Color(0xFF2ECC71);
          
          if (currentStock <= 0.001) {
            status = 'Hết hàng';
            color = const Color(0xFFE74C3C);
          } else if (minStockLevel > 0) {
            if (ratio < 0.25) {
              status = 'Hết hàng';
              color = const Color(0xFFE74C3C);
            } else if (ratio < 0.5) {
              status = 'Sắp hết';
              color = const Color(0xFFE67E22);
            } else if (ratio < 0.75) {
              status = 'Cảnh báo';
              color = const Color(0xFFE67E22);
            } else if (ratio < 1.0) {
              status = 'Kho thấp';
              color = const Color(0xFFF1C40F);
            }
          }

          ingredientsList.add(InventoryIngredient(
            id: item['ingredientId'] as String? ?? item['id'] as String? ?? '',
            name: item['ingredientName'] as String? ?? '',
            unit: item['unit'] as String? ?? 'kg',
            currentStock: currentStock,
            minStockLevel: minStockLevel,
            supplier: 'Nhà cung cấp',
            status: status,
            statusColor: color,
          ));
        }
      } catch (e) {
        print('[InventoryNotifier] Error fetching ingredients: $e');
      }

      // 2. Fetch transactions
      try {
        final txResponse = await _dioClient.dio.get('/inventory/transactions', queryParameters: {'branchId': branchId});
        final rawTx = txResponse.data;
        
        List<dynamic> txData = [];
        if (rawTx is List) {
          txData = rawTx;
        } else if (rawTx is Map<String, dynamic>) {
          txData = rawTx['items'] ?? rawTx['data'] ?? [];
        }

        for (var item in txData) {
          transactionsList.add(InventoryTransaction(
            id: item['id'] as String? ?? '',
            timestamp: item['createdAt'] != null ? DateTime.parse(item['createdAt'] as String) : DateTime.now(),
            ingredientName: item['ingredientName'] as String? ?? '',
            quantityChange: (item['quantityChange'] as num?)?.toDouble() ?? 0.0,
            unit: item['unit'] as String? ?? 'kg',
            afterStock: (item['afterStock'] as num?)?.toDouble() ?? 0.0,
            type: item['type'] as String? ?? 'Import',
            reference: item['reference'] as String? ?? '',
            reason: item['reason'] as String? ?? '',
          ));
        }
      } catch (e) {
        print('[InventoryNotifier] Error fetching transactions: $e');
      }

      // 3. Fetch recipes for menu items
      try {
        final menuResponse = await _dioClient.dio.get('/branches/$branchId/menu-builder');
        final rawMenu = menuResponse.data;
        print('[InventoryNotifier] rawMenu type: ${rawMenu.runtimeType}, keys: ${rawMenu is Map ? (rawMenu as Map).keys.toList() : "N/A"}');
        
        final List<dynamic> menuGroups = rawMenu is List 
            ? rawMenu 
            : (rawMenu is Map<String, dynamic> 
                ? (rawMenu['categories'] as List? ?? rawMenu['menuGroups'] as List? ?? rawMenu['data'] as List? ?? [])
                : []);

        final List<Map<String, dynamic>> menuItems = [];
        for (var g in menuGroups) {
          final items = g['items'] as List?;
          if (items != null) {
            for (var it in items) {
              menuItems.add(Map<String, dynamic>.from(it as Map));
            }
          }
        }

        for (var mi in menuItems) {
          final miId = mi['id'] as String;
          final miName = mi['name'] as String;
          final sellPrice = (mi['originalPrice'] as num? ?? mi['price'] as num?)?.toInt() ?? 0;

          try {
            final recipeResponse = await _dioClient.dio.get('/recipes/menu-items/$miId');
            final rawRecipe = recipeResponse.data;
            
            final List<dynamic> recipeItemsRaw = rawRecipe is List 
                ? rawRecipe 
                : (rawRecipe is Map<String, dynamic> && rawRecipe['data'] is List ? rawRecipe['data'] as List : []);

            final List<RecipeItem> recipeItems = recipeItemsRaw.map((e) {
              final double qtyNeeded = (e['quantityNeeded'] as num?)?.toDouble() ?? 0.0;
              final ingName = e['ingredientName'] as String? ?? '';
              final String rawUnit = e['ingredientUnit'] as String? ?? e['unit'] as String? ?? 'kg';
              
              double displayQty = qtyNeeded;
              String displayUnit = rawUnit;
              if (rawUnit == 'kg') {
                displayQty = qtyNeeded * 1000.0;
                displayUnit = 'gram';
              } else if (rawUnit == 'litre' || rawUnit == 'lít') {
                displayQty = qtyNeeded * 1000.0;
                displayUnit = 'ml';
              }
              
              int baseCost = 0;
              final nameLower = ingName.toLowerCase();
              if (nameLower.contains('mì')) {
                baseCost = 32;
              } else if (nameLower.contains('bò')) {
                baseCost = 210;
              } else if (nameLower.contains('hành')) {
                baseCost = 18;
              } else if (nameLower.contains('gia')) {
                baseCost = 15;
              } else if (nameLower.contains('tôm')) {
                baseCost = 3000;
              } else if (nameLower.contains('dầu')) {
                baseCost = 24;
              } else {
                baseCost = 10;
              }

              return RecipeItem(
                ingredientId: e['ingredientId'] as String? ?? '',
                ingredientName: ingName,
                quantityNeeded: displayQty,
                unit: displayUnit,
                costEstimate: (displayQty * baseCost).toInt(),
              );
            }).toList();

            recipesList.add(MenuItemRecipe(
              menuItemId: miId,
              menuItemName: miName,
              sellPrice: sellPrice,
              items: recipeItems,
            ));
          } catch (e) {
            recipesList.add(MenuItemRecipe(
              menuItemId: miId,
              menuItemName: miName,
              sellPrice: sellPrice,
              items: const [],
            ));
          }
        }
      } catch (e) {
        print('[InventoryNotifier] Error fetching recipes: $e');
      }

      state = InventoryState(
        ingredients: ingredientsList,
        recipes: recipesList,
        transactions: transactionsList,
        isInitialized: true,
      );
      if (branchId != null) {
        _ref.invalidate(branchInventoriesProvider(branchId));
      }
    } catch (e) {
      print('[InventoryNotifier] Error loading inventory data: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  // --- ACTIONS ---

  Future<void> importStock({
    required String supplier,
    required List<Map<String, dynamic>> items,
  }) async {
    final branchId = _branchId;
    if (branchId == null) return;

    try {
      for (var item in items) {
        final ingredientId = item['ingredientId'] as String;
        final quantity = item['quantity'] as double;

        final ing = state.ingredients.firstWhere((e) => e.id == ingredientId);

        await _dioClient.dio.post(
          '/inventory/import',
          data: {
            'branchId': branchId,
            'ingredientId': ingredientId,
            'quantity': quantity,
            'minStockLevel': ing.minStockLevel,
          },
        );
      }
      await fetchInventory();
    } catch (e) {
      print('[InventoryNotifier] Error importing stock: $e');
      rethrow;
    }
  }

  Future<void> reconcileStock(List<Map<String, dynamic>> audits) async {
    final branchId = _branchId;
    if (branchId == null) return;

    try {
      for (var audit in audits) {
        final ingredientId = audit['ingredientId'] as String;
        final actualStock = audit['actualStock'] as double;
        final reason = audit['reason'] as String;

        final ing = state.ingredients.firstWhere((e) => e.id == ingredientId);
        final diff = actualStock - ing.currentStock;

        if (diff != 0) {
          await _dioClient.dio.post(
            '/inventory/adjust',
            data: {
              'branchId': branchId,
              'ingredientId': ingredientId,
              'quantityChange': diff,
              'reason': reason,
            },
          );
        }
      }
      await fetchInventory();
    } catch (e) {
      print('[InventoryNotifier] Error reconciling stock: $e');
      rethrow;
    }
  }

  Future<void> updateMinStockLevel(String ingredientId, double minStockLevel) async {
    final branchId = _branchId;
    if (branchId == null) return;

    try {
      await _dioClient.dio.put(
        '/inventory/branches/$branchId/ingredients/$ingredientId/min-stock',
        data: {
          'minStockLevel': minStockLevel,
        },
      );
      await fetchInventory();
    } catch (e) {
      print('[InventoryNotifier] Error updating min stock level: $e');
      rethrow;
    }
  }

  Future<void> saveRecipe(String menuItemId, List<RecipeItem> items) async {
    try {
      final oldRecipe = state.recipes.firstWhere(
        (e) => e.menuItemId == menuItemId,
        orElse: () => MenuItemRecipe(menuItemId: menuItemId, menuItemName: '', sellPrice: 0, items: const []),
      );
      
      for (var oldItem in oldRecipe.items) {
        final existsInNew = items.any((e) => e.ingredientId == oldItem.ingredientId);
        if (!existsInNew) {
          await _dioClient.dio.delete('/recipes/menu-items/$menuItemId/ingredients/${oldItem.ingredientId}');
        }
      }

      for (var newItem in items) {
        final ing = state.ingredients.firstWhere((e) => e.id == newItem.ingredientId, orElse: () => state.ingredients.first);
        double quantityToSend = newItem.quantityNeeded;
        if (ing.unit == 'kg' && newItem.unit == 'gram') {
          quantityToSend = newItem.quantityNeeded / 1000.0;
        } else if ((ing.unit == 'litre' || ing.unit == 'lít') && newItem.unit == 'ml') {
          quantityToSend = newItem.quantityNeeded / 1000.0;
        }

        await _dioClient.dio.post(
          '/recipes',
          data: {
            'menuItemId': menuItemId,
            'ingredientId': newItem.ingredientId,
            'quantityNeeded': quantityToSend,
          },
        );
      }

      await fetchInventory();
    } catch (e) {
      print('[InventoryNotifier] Error saving recipe: $e');
      rethrow;
    }
  }

  Future<InventoryIngredient> createIngredient({required String name, required String unit}) async {
    try {
      final response = await _dioClient.dio.post('/ingredients', data: {
        'name': name,
        'unit': unit,
      });
      final data = response.data;
      final newIngredient = InventoryIngredient(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? name,
        unit: data['unit'] as String? ?? unit,
        currentStock: 0.0,
        minStockLevel: 0.0,
        supplier: 'Chưa có',
        status: 'Chưa nhập',
        statusColor: const Color(0xFF95A5A6),
      );

      state = state.copyWith(
        ingredients: [...state.ingredients, newIngredient],
      );

      return newIngredient;
    } catch (e) {
      print('[InventoryNotifier] Error creating ingredient: $e');
      bool isConflict = e.toString().contains('409');
      try {
        final dynamic dynErr = e;
        if (dynErr.response?.statusCode == 409) {
          isConflict = true;
        }
      } catch (_) {}
      
      if (isConflict) {
        try {
          final getRes = await _dioClient.dio.get('/ingredients');
          final rawData = getRes.data;
          final List<dynamic> items = rawData is List
              ? rawData
              : (rawData is Map<String, dynamic>
                  ? (rawData['items'] as List? ?? rawData['data'] as List? ?? [])
                  : []);
          final existing = items.firstWhere(
            (item) => (item['name'] as String).trim().toLowerCase() == name.trim().toLowerCase(),
            orElse: () => null,
          );
          if (existing != null) {
            final existingIng = InventoryIngredient(
              id: existing['id'] as String? ?? '',
              name: existing['name'] as String? ?? name,
              unit: existing['unit'] as String? ?? unit,
              currentStock: 0.0,
              minStockLevel: 0.0,
              supplier: 'Chưa có',
              status: 'Chưa nhập',
              statusColor: const Color(0xFF95A5A6),
            );
            if (!state.ingredients.any((element) => element.id == existingIng.id)) {
              state = state.copyWith(
                ingredients: [...state.ingredients, existingIng],
              );
            }
            return existingIng;
          }
        } catch (findErr) {
          print('[InventoryNotifier] Error looking up existing ingredient on 409: $findErr');
        }
        throw Exception('Nguyên liệu "$name" đã tồn tại trong hệ thống');
      }
      rethrow;
    }
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(ref),
);

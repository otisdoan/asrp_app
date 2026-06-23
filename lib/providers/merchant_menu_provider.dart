import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../data/repositories/branch_repository.dart';
import 'branch_registration_provider.dart';

// ===== Models =====

class MerchantCategory {
  final String id;
  final String name;
  final int priority;
  final bool isActive;

  const MerchantCategory({
    required this.id,
    required this.name,
    required this.priority,
    this.isActive = true,
  });

  MerchantCategory copyWith({
    String? id,
    String? name,
    int? priority,
    bool? isActive,
  }) {
    return MerchantCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MerchantOptionItem {
  final String id;
  final String itemName;
  final double extraPrice;
  final bool isAvailable;

  const MerchantOptionItem({
    required this.id,
    required this.itemName,
    required this.extraPrice,
    this.isAvailable = true,
  });

  MerchantOptionItem copyWith({
    String? id,
    String? itemName,
    double? extraPrice,
    bool? isAvailable,
  }) {
    return MerchantOptionItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      extraPrice: extraPrice ?? this.extraPrice,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class MerchantOptionGroup {
  final String id;
  final String groupName;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final List<MerchantOptionItem> items;

  const MerchantOptionGroup({
    required this.id,
    required this.groupName,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.isRequired = false,
    required this.items,
  });

  MerchantOptionGroup copyWith({
    String? id,
    String? groupName,
    int? minSelect,
    int? maxSelect,
    bool? isRequired,
    List<MerchantOptionItem>? items,
  }) {
    return MerchantOptionGroup(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ?? this.maxSelect,
      isRequired: isRequired ?? this.isRequired,
      items: items ?? this.items,
    );
  }
}

class MerchantDish {
  final String id;
  final String name;
  final double originalPrice;
  final double? discountPrice;
  final String imageUrl;
  final String description;
  final String availability; // 'available' | 'sold_out_today' | 'disabled'
  final List<MerchantOptionGroup> optionGroups;

  const MerchantDish({
    required this.id,
    required this.name,
    required this.originalPrice,
    this.discountPrice,
    this.imageUrl = '',
    this.description = '',
    this.availability = 'available',
    this.optionGroups = const [],
  });

  MerchantDish copyWith({
    String? id,
    String? name,
    double? originalPrice,
    double? discountPrice,
    String? imageUrl,
    String? description,
    String? availability,
    List<MerchantOptionGroup>? optionGroups,
  }) {
    return MerchantDish(
      id: id ?? this.id,
      name: name ?? this.name,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      availability: availability ?? this.availability,
      optionGroups: optionGroups ?? this.optionGroups,
    );
  }
}

class MerchantMenuState {
  final List<MerchantCategory> categories;
  final Map<String, List<MerchantDish>> categoryDishes; // Key: categoryId
  final String? selectedCategoryId;
  final bool isLoading;
  final String? errorMessage;

  const MerchantMenuState({
    this.categories = const [],
    this.categoryDishes = const {},
    this.selectedCategoryId,
    this.isLoading = false,
    this.errorMessage,
  });

  MerchantMenuState copyWith({
    List<MerchantCategory>? categories,
    Map<String, List<MerchantDish>>? categoryDishes,
    String? selectedCategoryId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MerchantMenuState(
      categories: categories ?? this.categories,
      categoryDishes: categoryDishes ?? this.categoryDishes,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ===== Notifier =====

class MerchantMenuNotifier extends StateNotifier<MerchantMenuState> {
  final Ref _ref;
  final DioClient _dioClient = DioClient();
  String? _branchId;

  MerchantMenuNotifier(this._ref) : super(const MerchantMenuState());

  Future<void> initializeMenu() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Get branch ID. We try to read approvedFirstBranchId from the registration state first.
      var registrationData = _ref.read(branchRegistrationProvider);
      if (registrationData.approvedFirstBranchId == null || registrationData.approvedFirstBranchId!.isEmpty) {
        try {
          await _ref.read(branchRegistrationProvider.notifier).fetchApplicationStatus();
          registrationData = _ref.read(branchRegistrationProvider);
        } catch (e) {
          print('[MerchantMenuNotifier] Error fetching application status for branch ID: $e');
        }
      }

      String? branchId = registrationData.approvedFirstBranchId;

      if (branchId == null || branchId.isEmpty) {
        final branchRepo = BranchRepository();
        final branches = await branchRepo.getBranches();
        
        if (branches.isEmpty) {
          throw Exception('Không tìm thấy chi nhánh nào. Vui lòng đăng ký chi nhánh trước.');
        }
        
        branchId = branches.first.id;
      }
      
      _branchId = branchId;
      await fetchMenuBuilderDetails();
    } catch (e) {
      print('[MerchantMenuNotifier] Error initializing menu: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchMenuBuilderDetails() async {
    if (_branchId == null) return;
    
    try {
      final response = await _dioClient.dio.get('/branches/$_branchId/menu-builder');
      final data = response.data['data'] ?? response.data;
      print('[MerchantMenuNotifier] API Response Data: $data');
      final rawCategories = data['categories'] as List<dynamic>? ?? data['Categories'] as List<dynamic>? ?? [];
      
      final List<MerchantCategory> categories = [];
      final Map<String, List<MerchantDish>> categoryDishes = {};
      
      for (final rawCat in rawCategories) {
        final catId = (rawCat['id'] ?? rawCat['Id']).toString();
        final category = MerchantCategory(
          id: catId,
          name: (rawCat['name'] ?? rawCat['Name']).toString(),
          priority: (rawCat['priority'] ?? rawCat['Priority']) as int? ?? 0,
          isActive: (rawCat['isActive'] ?? rawCat['IsActive']) as bool? ?? true,
        );
        categories.add(category);
        
        final List<MerchantDish> dishes = [];
        final rawItems = rawCat['items'] as List<dynamic>? ?? rawCat['Items'] as List<dynamic>? ?? [];
        for (final rawItem in rawItems) {
          final rawGroups = rawItem['optionGroups'] as List<dynamic>? ?? 
                             rawItem['OptionGroups'] as List<dynamic>? ?? 
                             rawItem['customizationGroups'] as List<dynamic>? ?? 
                             rawItem['CustomizationGroups'] as List<dynamic>? ?? [];
          final List<MerchantOptionGroup> optionGroups = [];
          
          for (final rawGroup in rawGroups) {
            final rawOptionItems = rawGroup['items'] as List<dynamic>? ?? 
                                   rawGroup['Items'] as List<dynamic>? ?? 
                                   rawGroup['toppings'] as List<dynamic>? ?? 
                                   rawGroup['Toppings'] as List<dynamic>? ?? [];
            final List<MerchantOptionItem> optionItems = [];
            for (final rawOpt in rawOptionItems) {
              optionItems.add(MerchantOptionItem(
                id: (rawOpt['id'] ?? rawOpt['Id'])?.toString() ?? '',
                itemName: (rawOpt['itemName'] ?? rawOpt['ItemName'] ?? rawOpt['toppingName'] ?? rawOpt['ToppingName'] ?? rawOpt['label'] ?? rawOpt['Label'] ?? '').toString(),
                extraPrice: ((rawOpt['extraPrice'] ?? rawOpt['ExtraPrice'] ?? rawOpt['toppingPrice'] ?? rawOpt['ToppingPrice'] ?? rawOpt['price'] ?? rawOpt['Price'] ?? 0.0) as num).toDouble(),
                isAvailable: (rawOpt['isAvailable'] ?? rawOpt['IsAvailable'] ?? true) as bool? ?? true,
              ));
            }
            
            optionGroups.add(MerchantOptionGroup(
              id: (rawGroup['id'] ?? rawGroup['Id'])?.toString() ?? '',
              groupName: (rawGroup['groupName'] ?? rawGroup['GroupName'] ?? rawGroup['label'] ?? rawGroup['Label'] ?? '').toString(),
              minSelect: (rawGroup['minSelect'] ?? rawGroup['MinSelect'] ?? 0) as int,
              maxSelect: (rawGroup['maxSelect'] ?? rawGroup['MaxSelect'] ?? 1) as int,
              isRequired: (rawGroup['isRequired'] ?? rawGroup['IsRequired'] ?? false) as bool,
              items: optionItems,
            ));
          }
          
          dishes.add(MerchantDish(
            id: (rawItem['id'] ?? rawItem['Id']).toString(),
            name: (rawItem['name'] ?? rawItem['Name']).toString(),
            originalPrice: ((rawItem['originalPrice'] ?? rawItem['OriginalPrice'] ?? 0.0) as num).toDouble(),
            discountPrice: (rawItem['discountPrice'] ?? rawItem['DiscountPrice']) != null
                ? ((rawItem['discountPrice'] ?? rawItem['DiscountPrice']) as num).toDouble()
                : null,
            imageUrl: (rawItem['imageUrl'] ?? rawItem['ImageUrl'])?.toString() ?? '',
            description: (rawItem['description'] ?? rawItem['Description'])?.toString() ?? '',
            availability: (rawItem['availability'] ?? rawItem['Availability'])?.toString() ?? 'available',
            optionGroups: optionGroups,
          ));
        }
        
        categoryDishes[catId] = dishes;
      }
      
      // Sort categories by priority
      categories.sort((a, b) => a.priority.compareTo(b.priority));
      
      String? selectedId = state.selectedCategoryId;
      if (selectedId == null || !categories.any((c) => c.id == selectedId)) {
        selectedId = categories.isNotEmpty ? categories.first.id : null;
      }
      
      state = MerchantMenuState(
        categories: categories,
        categoryDishes: categoryDishes,
        selectedCategoryId: selectedId,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      print('[MerchantMenuNotifier] Error fetching menu details: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  // ===== Category Operations =====

  void selectCategory(String id) {
    state = state.copyWith(selectedCategoryId: id);
  }

  Future<void> addCategory(String name) async {
    if (_branchId == null) return;
    
    try {
      final priority = state.categories.length;
      final response = await _dioClient.dio.post(
        '/branches/$_branchId/menu-builder/categories',
        data: {
          'name': name,
          'priority': priority,
        },
      );
      
      final data = response.data['data'] ?? response.data;
      final newCat = MerchantCategory(
        id: data['id'].toString(),
        name: data['name'].toString(),
        priority: data['priority'] as int? ?? priority,
        isActive: data['isActive'] as bool? ?? true,
      );
      
      state = state.copyWith(
        categories: [...state.categories, newCat],
        categoryDishes: {
          ...state.categoryDishes,
          newCat.id: [],
        },
        selectedCategoryId: state.selectedCategoryId ?? newCat.id,
      );
    } catch (e) {
      print('[MerchantMenuNotifier] Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String id, String name) async {
    if (_branchId == null) return;
    
    try {
      final category = state.categories.firstWhere((c) => c.id == id);
      await _dioClient.dio.patch(
        '/branches/$_branchId/menu-builder/categories/$id',
        data: {
          'name': name,
          'priority': category.priority,
        },
      );
      
      final updatedList = state.categories.map((c) {
        if (c.id == id) return c.copyWith(name: name);
        return c;
      }).toList();
      
      state = state.copyWith(categories: updatedList);
    } catch (e) {
      print('[MerchantMenuNotifier] Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    if (_branchId == null) return;
    
    try {
      await _dioClient.dio.delete(
        '/branches/$_branchId/menu-builder/categories/$id',
      );
      
      final updatedCats = state.categories.where((c) => c.id != id).toList();
      final updatedDishes = Map<String, List<MerchantDish>>.from(state.categoryDishes)..remove(id);
      
      String? newSelected = state.selectedCategoryId;
      if (newSelected == id) {
        newSelected = updatedCats.isNotEmpty ? updatedCats.first.id : null;
      }
      
      state = state.copyWith(
        categories: updatedCats,
        categoryDishes: updatedDishes,
        selectedCategoryId: newSelected,
      );
    } catch (e) {
      print('[MerchantMenuNotifier] Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (_branchId == null) return;
    
    final list = List<MerchantCategory>.from(state.categories);
    int index = newIndex;
    if (oldIndex < newIndex) {
      index -= 1;
    }
    
    final item = list.removeAt(oldIndex);
    list.insert(index, item);
    
    // Update priorities
    final prioritized = List.generate(list.length, (i) {
      return list[i].copyWith(priority: i);
    });
    
    state = state.copyWith(categories: prioritized);
    
    try {
      final payload = {
        'categories': prioritized.map((c) => {
          'categoryId': c.id,
          'priority': c.priority,
        }).toList()
      };
      
      await _dioClient.dio.patch(
        '/branches/$_branchId/menu-builder/categories/reorder',
        data: payload,
      );
    } catch (e) {
      print('[MerchantMenuNotifier] Error reordering categories: $e');
      await fetchMenuBuilderDetails();
    }
  }

  // ===== Dish Operations =====

  Future<void> _syncOptionGroups(
    String itemId,
    List<MerchantOptionGroup> originalGroups,
    List<MerchantOptionGroup> updatedGroups,
  ) async {
    // 1. Delete groups that are in original but not in updated
    final updatedGroupIds = updatedGroups.map((g) => g.id).toSet();
    for (final origGroup in originalGroups) {
      if (!updatedGroupIds.contains(origGroup.id)) {
        try {
          await _dioClient.dio.delete(
            '/branches/$_branchId/menu-builder/items/$itemId/option-groups/${origGroup.id}',
          );
        } catch (e) {
          print('[MerchantMenuNotifier] Error deleting option group ${origGroup.id}: $e');
        }
      } else {
        // Group still exists, check for deleted items within it
        final updatedGroup = updatedGroups.firstWhere((g) => g.id == origGroup.id);
        final updatedItemIds = updatedGroup.items.map((it) => it.id).toSet();
        for (final origItem in origGroup.items) {
          if (!updatedItemIds.contains(origItem.id)) {
            try {
              await _dioClient.dio.delete(
                '/branches/$_branchId/menu-builder/items/$itemId/option-groups/${origGroup.id}/option-items/${origItem.id}',
              );
            } catch (e) {
              print('[MerchantMenuNotifier] Error deleting option item ${origItem.id}: $e');
            }
          }
        }
      }
    }

    // 2. Create or Update groups
    for (final group in updatedGroups) {
      final isNewGroup = group.id.startsWith('opt-grp-');
      if (isNewGroup) {
        // Create new group
        final groupRes = await _dioClient.dio.post(
          '/branches/$_branchId/menu-builder/items/$itemId/option-groups',
          data: {
            'groupName': group.groupName,
            'minSelect': group.minSelect,
            'maxSelect': group.maxSelect,
            'isRequired': group.isRequired,
          },
        );
        final newGroupData = groupRes.data['data'] ?? groupRes.data;
        final newGroupId = newGroupData['id'].toString();

        // Create items for this new group
        for (final item in group.items) {
          await _dioClient.dio.post(
            '/branches/$_branchId/menu-builder/items/$itemId/option-groups/$newGroupId/option-items',
            data: {
              'itemName': item.itemName,
              'extraPrice': item.extraPrice,
              'isAvailable': item.isAvailable,
            },
          );
        }
      } else {
        // Update existing group
        await _dioClient.dio.patch(
          '/branches/$_branchId/menu-builder/items/$itemId/option-groups/${group.id}',
          data: {
            'groupName': group.groupName,
            'minSelect': group.minSelect,
            'maxSelect': group.maxSelect,
            'isRequired': group.isRequired,
          },
        );

        // Update items inside existing group
        for (final item in group.items) {
          final isNewItem = item.id.startsWith('item-');
          if (isNewItem) {
            await _dioClient.dio.post(
              '/branches/$_branchId/menu-builder/items/$itemId/option-groups/${group.id}/option-items',
              data: {
                'itemName': item.itemName,
                'extraPrice': item.extraPrice,
                'isAvailable': item.isAvailable,
              },
            );
          } else {
            await _dioClient.dio.patch(
              '/branches/$_branchId/menu-builder/items/$itemId/option-groups/${group.id}/option-items/${item.id}',
              data: {
                'itemName': item.itemName,
                'extraPrice': item.extraPrice,
                'isAvailable': item.isAvailable,
              },
            );
          }
        }
      }
    }
  }

  Future<void> addDish(String categoryId, MerchantDish dish) async {
    if (_branchId == null) return;
    try {
      final response = await _dioClient.dio.post(
        '/branches/$_branchId/menu-builder/items',
        data: {
          'name': dish.name,
          'originalPrice': dish.originalPrice,
          'discountPrice': dish.discountPrice,
          'imageUrl': dish.imageUrl,
          'description': dish.description,
          'availability': dish.availability,
          'categoryId': categoryId,
        },
      );
      
      final newItemData = response.data['data'] ?? response.data;
      final newItemId = newItemData['id'].toString();
      
      // Sync option groups
      await _syncOptionGroups(newItemId, [], dish.optionGroups);
      
      // Refresh local menu state from server
      await fetchMenuBuilderDetails();
    } catch (e) {
      print('[MerchantMenuNotifier] Error adding dish: $e');
      rethrow;
    }
  }

  Future<void> updateDish(String categoryId, MerchantDish dish) async {
    if (_branchId == null) return;
    try {
      await _dioClient.dio.patch(
        '/branches/$_branchId/menu-builder/items/${dish.id}',
        data: {
          'name': dish.name,
          'originalPrice': dish.originalPrice,
          'discountPrice': dish.discountPrice,
          'imageUrl': dish.imageUrl,
          'description': dish.description,
          'availability': dish.availability,
          'categoryId': categoryId,
        },
      );
      
      // Find original option groups from local state to compute diff
      final originalDishes = state.categoryDishes[categoryId] ?? [];
      final originalDish = originalDishes.firstWhere((d) => d.id == dish.id, orElse: () => dish);
      
      // Sync option groups
      await _syncOptionGroups(dish.id, originalDish.optionGroups, dish.optionGroups);
      
      // Refresh local menu state from server
      await fetchMenuBuilderDetails();
    } catch (e) {
      print('[MerchantMenuNotifier] Error updating dish: $e');
      rethrow;
    }
  }

  Future<void> deleteDish(String categoryId, String dishId) async {
    if (_branchId == null) return;
    try {
      await _dioClient.dio.delete(
        '/branches/$_branchId/menu-builder/items/$dishId',
      );
      
      final dishes = List<MerchantDish>.from(state.categoryDishes[categoryId] ?? [])
        ..removeWhere((d) => d.id == dishId);

      final updatedMap = Map<String, List<MerchantDish>>.from(state.categoryDishes)
        ..[categoryId] = dishes;

      state = state.copyWith(categoryDishes: updatedMap);
    } catch (e) {
      print('[MerchantMenuNotifier] Error deleting dish: $e');
      rethrow;
    }
  }

  Future<void> toggleDishAvailability(String categoryId, String dishId, String availability) async {
    if (_branchId == null) return;
    try {
      await _dioClient.dio.patch(
        '/branches/$_branchId/menu-builder/items/$dishId/availability',
        data: {
          'availability': availability,
        },
      );
      
      final dishes = List<MerchantDish>.from(state.categoryDishes[categoryId] ?? []);
      final index = dishes.indexWhere((d) => d.id == dishId);
      if (index != -1) {
        dishes[index] = dishes[index].copyWith(availability: availability);
      }

      final updatedMap = Map<String, List<MerchantDish>>.from(state.categoryDishes)
        ..[categoryId] = dishes;

      state = state.copyWith(categoryDishes: updatedMap);
    } catch (e) {
      print('[MerchantMenuNotifier] Error toggling dish availability: $e');
      rethrow;
    }
  }
}

final merchantMenuProvider =
    StateNotifierProvider<MerchantMenuNotifier, MerchantMenuState>(
  (ref) => MerchantMenuNotifier(ref),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const MerchantMenuState({
    this.categories = const [],
    this.categoryDishes = const {},
    this.selectedCategoryId,
  });

  MerchantMenuState copyWith({
    List<MerchantCategory>? categories,
    Map<String, List<MerchantDish>>? categoryDishes,
    String? selectedCategoryId,
  }) {
    return MerchantMenuState(
      categories: categories ?? this.categories,
      categoryDishes: categoryDishes ?? this.categoryDishes,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

// ===== Notifier =====

class MerchantMenuNotifier extends StateNotifier<MerchantMenuState> {
  MerchantMenuNotifier() : super(const MerchantMenuState()) {
    _loadPrefilledMenu();
  }

  void _loadPrefilledMenu() {
    final cat1 = MerchantCategory(id: 'cat-phở', name: 'Phở Truyền Thống', priority: 0);
    final cat2 = MerchantCategory(id: 'cat-drink', name: 'Đồ Uống', priority: 1);
    final cat3 = MerchantCategory(id: 'cat-topping', name: 'Topping Thêm', priority: 2);

    final sizeOptionGroup = MerchantOptionGroup(
      id: 'opt-size',
      groupName: 'Chọn kích cỡ phở',
      isRequired: true,
      minSelect: 1,
      maxSelect: 1,
      items: const [
        MerchantOptionItem(id: 'item-sz-nho', itemName: 'Tô vừa (Thường)', extraPrice: 0),
        MerchantOptionItem(id: 'item-sz-lon', itemName: 'Tô khổng lồ (Lớn)', extraPrice: 15000),
        MerchantOptionItem(id: 'item-sz-db', itemName: 'Tô đặc biệt VIP', extraPrice: 25000),
      ],
    );

    final extraToppingGroup = MerchantOptionGroup(
      id: 'opt-extras',
      groupName: 'Thêm Topping ngon',
      isRequired: false,
      minSelect: 0,
      maxSelect: 4,
      items: const [
        MerchantOptionItem(id: 'item-tp-trung', itemName: 'Trứng chần hột gà', extraPrice: 5000),
        MerchantOptionItem(id: 'item-tp-quay', itemName: 'Quẩy giòn rụm', extraPrice: 5000),
        MerchantOptionItem(id: 'item-tp-bo', itemName: 'Thịt bò tái thêm', extraPrice: 20000),
        MerchantOptionItem(id: 'item-tp-tiet', itemName: 'Tiết hột gà thơm ngon', extraPrice: 10000),
      ],
    );

    final dish1 = MerchantDish(
      id: 'dish-pho-dac-biet',
      name: 'Phở Đặc Biệt DineX',
      originalPrice: 65000,
      discountPrice: 59000,
      description: 'Phở bò tái, nạm, gầu, gân, bò viên đầy đủ hành thơm lừng bánh phở tươi.',
      imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&q=80',
      optionGroups: [sizeOptionGroup, extraToppingGroup],
    );

    final dish2 = MerchantDish(
      id: 'dish-pho-tai-chin',
      name: 'Phở Tái Chín Thơm Ngon',
      originalPrice: 50000,
      description: 'Phở bò nạm tái chín vừa ngọt thanh thanh nước dùng xương hầm 24h.',
      imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&q=80',
      optionGroups: [sizeOptionGroup],
    );

    final dish3 = MerchantDish(
      id: 'dish-tra-da',
      name: 'Trà Đá Mát Lạnh',
      originalPrice: 5000,
      description: 'Ly trà đá đậm vị mát rượi giải nhiệt.',
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80',
    );

    final dish4 = MerchantDish(
      id: 'dish-sua-dau-nanh',
      name: 'Sữa Đậu Nành Organic',
      originalPrice: 15000,
      description: 'Sữa đậu nành nguyên chất thơm phức béo ngậy.',
      imageUrl: 'https://images.unsplash.com/photo-1464454709291-11881a4c7940?w=500&q=80',
    );

    final dish5 = MerchantDish(
      id: 'dish-quay',
      name: 'Quẩy Giòn Vàng',
      originalPrice: 5000,
      description: 'Quẩy giòn ăn kèm nước lèo phở ngon nhức nách.',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
    );

    state = MerchantMenuState(
      categories: [cat1, cat2, cat3],
      categoryDishes: {
        'cat-phở': [dish1, dish2],
        'cat-drink': [dish3, dish4],
        'cat-topping': [dish5],
      },
      selectedCategoryId: 'cat-phở',
    );
  }

  // ===== Category Operations =====

  void selectCategory(String id) {
    state = state.copyWith(selectedCategoryId: id);
  }

  void addCategory(String name) {
    final id = 'cat-${DateTime.now().millisecondsSinceEpoch}';
    final priority = state.categories.length;
    final newCat = MerchantCategory(id: id, name: name, priority: priority);
    
    state = state.copyWith(
      categories: [...state.categories, newCat],
      categoryDishes: {
        ...state.categoryDishes,
        id: [],
      },
      selectedCategoryId: state.selectedCategoryId ?? id,
    );
  }

  void updateCategory(String id, String name) {
    final updatedList = state.categories.map((c) {
      if (c.id == id) return c.copyWith(name: name);
      return c;
    }).toList();

    state = state.copyWith(categories: updatedList);
  }

  void deleteCategory(String id) {
    final updatedCats = state.categories.where((c) => c.id != id).toList();
    
    // Clean dishes
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
  }

  void reorderCategories(int oldIndex, int newIndex) {
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
  }

  // ===== Dish Operations =====

  void addDish(String categoryId, MerchantDish dish) {
    final dishes = List<MerchantDish>.from(state.categoryDishes[categoryId] ?? []);
    dishes.add(dish);

    final updatedMap = Map<String, List<MerchantDish>>.from(state.categoryDishes)
      ..[categoryId] = dishes;

    state = state.copyWith(categoryDishes: updatedMap);
  }

  void updateDish(String categoryId, MerchantDish dish) {
    final dishes = List<MerchantDish>.from(state.categoryDishes[categoryId] ?? []);
    final index = dishes.indexWhere((d) => d.id == dish.id);
    if (index != -1) {
      dishes[index] = dish;
    }

    final updatedMap = Map<String, List<MerchantDish>>.from(state.categoryDishes)
      ..[categoryId] = dishes;

    state = state.copyWith(categoryDishes: updatedMap);
  }

  void deleteDish(String categoryId, String dishId) {
    final dishes = List<MerchantDish>.from(state.categoryDishes[categoryId] ?? [])
      ..removeWhere((d) => d.id == dishId);

    final updatedMap = Map<String, List<MerchantDish>>.from(state.categoryDishes)
      ..[categoryId] = dishes;

    state = state.copyWith(categoryDishes: updatedMap);
  }

  void toggleDishAvailability(String categoryId, String dishId, String availability) {
    final dishes = List<MerchantDish>.from(state.categoryDishes[categoryId] ?? []);
    final index = dishes.indexWhere((d) => d.id == dishId);
    if (index != -1) {
      dishes[index] = dishes[index].copyWith(availability: availability);
    }

    final updatedMap = Map<String, List<MerchantDish>>.from(state.categoryDishes)
      ..[categoryId] = dishes;

    state = state.copyWith(categoryDishes: updatedMap);
  }
}

final merchantMenuProvider =
    StateNotifierProvider<MerchantMenuNotifier, MerchantMenuState>(
  (ref) => MerchantMenuNotifier(),
);

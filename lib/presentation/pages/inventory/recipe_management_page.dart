import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';
import '../../../core/utils/top_notification.dart';

class RecipeManagementPage extends ConsumerStatefulWidget {
  const RecipeManagementPage({super.key});

  @override
  ConsumerState<RecipeManagementPage> createState() => _RecipeManagementPageState();
}

class _RecipeManagementPageState extends ConsumerState<RecipeManagementPage> {
  String? _selectedRecipeId;
  final List<Map<String, dynamic>> _editingItems = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inventoryProvider.notifier).fetchInventory();
    });
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _loadRecipe(MenuItemRecipe recipe) {
    _editingItems.clear();
    for (var item in recipe.items) {
      _editingItems.add({
        'ingredientId': item.ingredientId,
        'ingredientName': item.ingredientName,
        'unit': item.unit,
        'quantityController': TextEditingController(text: item.quantityNeeded.toStringAsFixed(0)),
        'costEstimate': item.costEstimate,
      });
    }
  }

  void _addRecipeItemRow(InventoryIngredient ing) {
    if (_editingItems.any((e) => e['ingredientId'] == ing.id)) {
      TopNotification.show(context, message: '${ing.name} đã nằm trong công thức', isError: true);
      return;
    }

    final double defaultQty = ing.unit == 'kg' ? 100 : (ing.unit == 'lít' ? 50 : 1);
    final String defaultUnit = ing.unit == 'kg' ? 'gram' : (ing.unit == 'lít' ? 'ml' : ing.unit);

    // Mock unit cost calculation
    int baseCost = 0;
    final nameLower = ing.name.toLowerCase();
    if (nameLower.contains('mì')) {
      baseCost = 32; // 32k/kg = 32đ/gram
    } else if (nameLower.contains('bò')) {
      baseCost = 210; // 210k/kg = 210đ/gram
    } else if (nameLower.contains('hành')) {
      baseCost = 18; // 18k/kg = 18đ/gram
    } else if (nameLower.contains('gia')) {
      baseCost = 15; // 15k/kg = 15đ/gram
    } else if (nameLower.contains('tôm')) {
      baseCost = 3000; // 3000đ/con
    } else if (nameLower.contains('dầu')) {
      baseCost = 24; // 24đ/ml
    } else {
      baseCost = 10;
    }

    final costEst = (defaultQty * baseCost).toInt();

    setState(() {
      _editingItems.add({
        'ingredientId': ing.id,
        'ingredientName': ing.name,
        'unit': defaultUnit,
        'quantityController': TextEditingController(text: defaultQty.toStringAsFixed(0)),
        'costEstimate': costEst,
      });
    });
  }

  void _recalculateCostRow(Map<String, dynamic> item) {
    final double qty = double.tryParse(item['quantityController'].text) ?? 0;
    
    // Get ingredient unit cost
    int baseCost = 0;
    final itemLower = item['ingredientName'].toString().toLowerCase();
    if (itemLower.contains('mì')) {
      baseCost = 32;
    } else if (itemLower.contains('bò')) {
      baseCost = 210;
    } else if (itemLower.contains('hành')) {
      baseCost = 18;
    } else if (itemLower.contains('gia')) {
      baseCost = 15;
    } else if (itemLower.contains('tôm')) {
      baseCost = 3000;
    } else if (itemLower.contains('dầu')) {
      baseCost = 24;
    } else {
      baseCost = 10;
    }

    setState(() {
      item['costEstimate'] = (qty * baseCost).toInt();
    });
  }

  int get _totalFoodCost {
    int total = 0;
    for (var item in _editingItems) {
      total += item['costEstimate'] as int;
    }
    return total;
  }

  void _showIngredientSelector(List<InventoryIngredient> ingredients) {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase();
            final filtered = query.isEmpty
                ? ingredients
                : ingredients.where((e) => e.name.toLowerCase().contains(query)).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn nguyên liệu thêm vào công thức',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm nguyên liệu...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off, size: 40, color: AppColors.textSecondary),
                                    SizedBox(height: 8),
                                    Text('Không tìm thấy nguyên liệu', style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final ing = filtered[index];
                                return ListTile(
                                  title: Text(ing.name, style: const TextStyle(color: AppColors.textPrimary)),
                                  subtitle: Text('Tồn hiện tại: ${ing.currentStock} ${ing.unit}', style: const TextStyle(color: AppColors.textSecondary)),
                                  trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _addRecipeItemRow(ing);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveRecipe() {
    if (_selectedRecipeId == null) return;

    final List<RecipeItem> itemsPayload = [];
    for (var item in _editingItems) {
      final double qty = double.tryParse(item['quantityController'].text) ?? 0;
      if (qty <= 0) {
        TopNotification.show(context, message: 'Định lượng của ${item['ingredientName']} phải lớn hơn 0', isError: true);
        return;
      }
      itemsPayload.add(RecipeItem(
        ingredientId: item['ingredientId'],
        ingredientName: item['ingredientName'],
        quantityNeeded: qty,
        unit: item['unit'],
        costEstimate: item['costEstimate'] as int,
      ));
    }

    ref.read(inventoryProvider.notifier).saveRecipe(_selectedRecipeId!, itemsPayload);
    TopNotification.show(context, message: 'Đã lưu công thức định lượng thành công');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    if (!state.isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.onPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Công thức món ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.recipes.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.onPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Công thức món ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Chưa có món ăn nào trong thực đơn chi nhánh',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    if (state.recipes.isNotEmpty && _selectedRecipeId == null) {
      _selectedRecipeId = state.recipes.first.menuItemId;
      _loadRecipe(state.recipes.first);
    }

    final activeRecipe = state.recipes.firstWhere((e) => e.menuItemId == _selectedRecipeId, orElse: () => state.recipes.first);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Công thức món ăn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ===== MENU ITEM SELECTOR =====
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('Món ăn:', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRecipeId,
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        items: state.recipes.map((recipe) {
                          return DropdownMenuItem<String>(
                            value: recipe.menuItemId,
                            child: Text(recipe.menuItemName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRecipeId = val;
                              final target = state.recipes.firstWhere((e) => e.menuItemId == val);
                              _loadRecipe(target);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== RECIPE LIST HEADER =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ĐỊNH LƯỢNG NGUYÊN LIỆU',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Thêm định lượng',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onPressed: () => _showIngredientSelector(state.ingredients),
                ),
              ],
            ),
          ),

          // ===== RECIPE LIST VIEW =====
          Expanded(
            child: _editingItems.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa cấu hình công thức cho món ăn này',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16),
                    itemCount: _editingItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _editingItems[index];
                      return _buildRecipeItemCard(item, index);
                    },
                  ),
          ),

          // ===== PRICE BREAKDOWN & SAVE BAR =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giá bán món ăn:',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_formatPrice(activeRecipe.sellPrice)}đ',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ước tính Food Cost:',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_formatPrice(_totalFoodCost)}đ (${(activeRecipe.sellPrice > 0 ? (_totalFoodCost / activeRecipe.sellPrice) * 100 : 0).toStringAsFixed(1)}% Giá bán)',
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: (_totalFoodCost / activeRecipe.sellPrice) > 0.5 ? AppColors.primary : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveRecipe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Lưu công thức', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRecipeItemCard(Map<String, dynamic> item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['ingredientName'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giá vốn ước tính: ${_formatPrice(item['costEstimate'] as int)}đ',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quantity inputs
          Expanded(
            flex: 3,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: item['quantityController'],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        _recalculateCostRow(item);
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  Text(
                    item['unit'],
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () {
              setState(() {
                _editingItems.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }
}

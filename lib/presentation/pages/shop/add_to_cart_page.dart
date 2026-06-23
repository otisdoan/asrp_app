import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/topping_selection_model.dart';
import '../../../data/repositories/branch_repository.dart';

/// Represents a single option group (e.g. "Topping thêm", "Kích cỡ")
class _OptionGroupData {
  final String id;
  final String groupName;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final List<Map<String, dynamic>> items;

  _OptionGroupData({
    required this.id,
    required this.groupName,
    this.minSelect = 0,
    this.maxSelect = 0,
    this.isRequired = false,
    required this.items,
  });

  /// If maxSelect == 1, treat as single-select (radio). Otherwise multi-select (checkbox).
  bool get isSingleSelect => maxSelect == 1;
}

/// Add to Cart Page — topping selection, size, notes, quantity.
/// Follows RULE: UI-only, uses AppColors, responsive.
class AddToCartPage extends StatefulWidget {
  final String name;
  final String price;
  final IconData icon;
  final String? imageUrl;
  final int? initialQuantity;
  final List<ToppingSelectionModel>? initialSelectedToppings;
  final String? initialNote;
  final bool isEditing;
  final String? menuItemId;
  final String? branchId;

  const AddToCartPage({
    super.key,
    required this.name,
    required this.price,
    required this.icon,
    this.imageUrl,
    this.initialQuantity,
    this.initialSelectedToppings,
    this.initialNote,
    this.isEditing = false,
    this.menuItemId,
    this.branchId,
  });

  @override
  State<AddToCartPage> createState() => _AddToCartPageState();
}

class _AddToCartPageState extends State<AddToCartPage> {
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  /// Parsed option groups from API (each group has its own items, minSelect, maxSelect, etc.)
  List<_OptionGroupData> _optionGroups = [];

  /// Selected item indices per group. Key = group index, Value = set of selected item indices.
  final Map<int, Set<int>> _selectedItems = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchItemDetailsAndInit();
  }

  Future<void> _fetchItemDetailsAndInit() async {
    final branchId = widget.branchId;
    final menuItemId = widget.menuItemId;

    if (branchId == null || branchId.isEmpty || menuItemId == null || menuItemId.isEmpty) {
      setState(() {
        _optionGroups = [];
        _isLoading = false;
      });
      _applyInitialSelections();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = BranchRepository();
      final detail = await repo.getMenuItemDetail(
        branchId: branchId,
        menuItemId: menuItemId,
      );
      print('[AddToCartPage] detail payload: $detail');

      final List<_OptionGroupData> groups = [];

      // --- Parse customizationGroups (BE returns {id, label} only, no items inside) ---
      final rawCustGroups = detail['customizationGroups'] 
          ?? detail['CustomizationGroups'] ?? [];
      // Build a map: groupId -> {id, label}
      final Map<String, String> groupDefs = {};
      if (rawCustGroups is List) {
        for (final cg in rawCustGroups) {
          if (cg is! Map) continue;
          final gId = (cg['id'] ?? cg['Id'])?.toString() ?? '';
          final gLabel = (cg['label'] ?? cg['Label'] ?? 'Tùy chọn').toString();
          if (gId.isNotEmpty) groupDefs[gId] = gLabel;
        }
      }

      // --- Parse flat toppings and group them by customizationGroupId ---
      final rawToppings = detail['toppings'] ?? detail['Toppings'] ?? [];
      // Map: groupId -> list of parsed topping items
      final Map<String, List<Map<String, dynamic>>> toppingsByGroup = {};
      final List<Map<String, dynamic>> ungroupedToppings = [];

      if (rawToppings is List) {
        for (final t in rawToppings) {
          if (t is! Map) continue;
          final parsed = {
            'id': (t['id'] ?? t['Id'])?.toString() ?? '',
            'name': (t['toppingName'] ?? t['ToppingName'] 
                ?? t['label'] ?? t['Label'] ?? '').toString(),
            'price': _parsePrice(t['toppingPrice'] ?? t['ToppingPrice'] 
                ?? t['price'] ?? t['Price'] ?? 0),
          };
          final custGroupId = (t['customizationGroupId'] ?? t['CustomizationGroupId'])?.toString();
          if (custGroupId != null && custGroupId.isNotEmpty && groupDefs.containsKey(custGroupId)) {
            toppingsByGroup.putIfAbsent(custGroupId, () => []);
            toppingsByGroup[custGroupId]!.add(parsed);
          } else {
            ungroupedToppings.add(parsed);
          }
        }
      }

      // --- Build option groups from customizationGroups + grouped toppings ---
      if (groupDefs.isNotEmpty) {
        for (final entry in groupDefs.entries) {
          final gId = entry.key;
          final gLabel = entry.value;
          final items = toppingsByGroup[gId] ?? [];
          if (items.isNotEmpty) {
            groups.add(_OptionGroupData(
              id: gId,
              groupName: gLabel,
              minSelect: 0,
              maxSelect: items.length,
              isRequired: false,
              items: items,
            ));
          }
        }
        // Add ungrouped toppings as a separate group if any
        if (ungroupedToppings.isNotEmpty) {
          groups.add(_OptionGroupData(
            id: 'ungrouped_toppings',
            groupName: 'Topping khác',
            minSelect: 0,
            maxSelect: ungroupedToppings.length,
            isRequired: false,
            items: ungroupedToppings,
          ));
        }
      } else if (rawToppings is List && rawToppings.isNotEmpty) {
        // No customizationGroups defined — put all toppings into one group
        final allToppings = [...ungroupedToppings];
        for (final items in toppingsByGroup.values) {
          allToppings.addAll(items);
        }
        if (allToppings.isNotEmpty) {
          groups.add(_OptionGroupData(
            id: 'toppings_fallback',
            groupName: 'Topping',
            minSelect: 0,
            maxSelect: allToppings.length,
            isRequired: false,
            items: allToppings,
          ));
        }
      }

      // --- Parse sizes as a separate group ---
      final rawSizes = detail['sizes'] ?? detail['Sizes'] ?? [];
      if (rawSizes is List && rawSizes.isNotEmpty) {
        final List<Map<String, dynamic>> sizeItems = [];
        for (final s in rawSizes) {
          if (s is! Map) continue;
          sizeItems.add({
            'id': (s['id'] ?? s['Id'])?.toString() ?? '',
            'name': (s['sizeName'] ?? s['SizeName'] ?? s['label'] ?? s['Label'] ?? '').toString(),
            'price': _parsePrice(s['sizePrice'] ?? s['SizePrice'] ?? s['price'] ?? s['Price'] ?? 0),
          });
        }
        if (sizeItems.isNotEmpty) {
          groups.add(_OptionGroupData(
            id: 'sizes_group',
            groupName: 'Kích cỡ',
            minSelect: 0,
            maxSelect: 1,
            isRequired: false,
            items: sizeItems,
          ));
        }
      }

      // --- Fallback: try optionGroups (structured format from menu-builder API) ---
      if (groups.isEmpty) {
        final rawOptionGroups = detail['optionGroups'] ?? detail['OptionGroups'] ?? [];
        if (rawOptionGroups is List && rawOptionGroups.isNotEmpty) {
          for (final rawGroup in rawOptionGroups) {
            if (rawGroup is! Map) continue;
            final groupId = (rawGroup['id'] ?? rawGroup['Id'])?.toString() ?? '';
            final groupName = (rawGroup['groupName'] ?? rawGroup['GroupName'] ?? 'Tùy chọn').toString();
            final minSelect = _parseIntSafe(rawGroup['minSelect'] ?? rawGroup['MinSelect'] ?? 0);
            final maxSelect = _parseIntSafe(rawGroup['maxSelect'] ?? rawGroup['MaxSelect'] ?? 0);
            final isRequired = (rawGroup['isRequired'] ?? rawGroup['IsRequired'] ?? false) == true;

            final rawItems = rawGroup['items'] as List<dynamic>? 
                ?? rawGroup['Items'] as List<dynamic>? ?? [];
            final List<Map<String, dynamic>> items = [];
            for (final rawItem in rawItems) {
              if (rawItem is! Map) continue;
              items.add({
                'id': (rawItem['id'] ?? rawItem['Id'])?.toString() ?? '',
                'name': (rawItem['itemName'] ?? rawItem['ItemName'] ?? '').toString(),
                'price': _parsePrice(rawItem['extraPrice'] ?? rawItem['ExtraPrice'] ?? 0),
              });
            }
            if (items.isNotEmpty) {
              groups.add(_OptionGroupData(
                id: groupId,
                groupName: groupName,
                minSelect: minSelect,
                maxSelect: maxSelect,
                isRequired: isRequired,
                items: items,
              ));
            }
          }
        }
      }

      setState(() {
        _optionGroups = groups;
        // Initialize empty selection sets for each group
        for (int i = 0; i < groups.length; i++) {
          _selectedItems.putIfAbsent(i, () => {});
        }
        _isLoading = false;
      });

      _applyInitialSelections();
    } catch (e) {
      print('[AddToCartPage] Error loading menu item details: $e');
      setState(() {
        _errorMessage = 'Không thể tải tùy chọn món ăn: $e';
        _isLoading = false;
      });
    }
  }

  int _parsePrice(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }

  int _parseIntSafe(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _applyInitialSelections() {
    if (widget.initialQuantity != null) {
      _quantity = widget.initialQuantity!;
    }
    if (widget.initialNote != null) {
      _noteController.text = widget.initialNote!;
    }
    if (widget.initialSelectedToppings != null && widget.initialSelectedToppings!.isNotEmpty) {
      for (final selection in widget.initialSelectedToppings!) {
        // Try to match by groupId first, then by item id/name within that group
        bool matched = false;

        for (int gi = 0; gi < _optionGroups.length; gi++) {
          final group = _optionGroups[gi];

          // If selection has groupId, try to match group first
          if (selection.groupId != null && selection.groupId!.isNotEmpty) {
            if (group.id != selection.groupId) continue;
          }

          // Try to match item within this group
          for (int ii = 0; ii < group.items.length; ii++) {
            final item = group.items[ii];
            final itemId = item['id']?.toString() ?? '';
            final itemName = item['name']?.toString() ?? '';

            final selectionName = selection.name.startsWith('Size ')
                ? selection.name.substring(5)
                : selection.name;

            if ((itemId.isNotEmpty && itemId == selection.toppingId) ||
                (itemName.trim().toLowerCase() == selectionName.trim().toLowerCase())) {
              _selectedItems.putIfAbsent(gi, () => {});
              _selectedItems[gi]!.add(ii);
              matched = true;
              break;
            }
          }
          if (matched) break;
        }

        // If no group matched by groupId, try matching across all groups
        if (!matched && selection.groupId != null) {
          for (int gi = 0; gi < _optionGroups.length; gi++) {
            final group = _optionGroups[gi];
            for (int ii = 0; ii < group.items.length; ii++) {
              final item = group.items[ii];
              final itemId = item['id']?.toString() ?? '';
              final itemName = item['name']?.toString() ?? '';

              final selectionName = selection.name.startsWith('Size ')
                  ? selection.name.substring(5)
                  : selection.name;

              if ((itemId.isNotEmpty && itemId == selection.toppingId) ||
                  (itemName.trim().toLowerCase() == selectionName.trim().toLowerCase())) {
                _selectedItems.putIfAbsent(gi, () => {});
                _selectedItems[gi]!.add(ii);
                matched = true;
                break;
              }
            }
            if (matched) break;
          }
        }
      }
    }
    setState(() {});
  }

  int get _basePrice {
    final priceStr = widget.price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(priceStr) ?? 0;
  }

  int get _optionsTotal {
    int total = 0;
    for (int gi = 0; gi < _optionGroups.length; gi++) {
      final selected = _selectedItems[gi] ?? {};
      for (final ii in selected) {
        total += _optionGroups[gi].items[ii]['price'] as int;
      }
    }
    return total;
  }

  int get _totalPrice => (_basePrice + _optionsTotal) * _quantity;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : (_errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchItemDetailsAndInit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // ─── Image Header ───────────────────────────────────
                    _buildImageHeader(context),

                    // ─── Food Name + Price ──────────────────────────────
                    SliverToBoxAdapter(child: _buildFoodHeader()),

                    // ─── Option Groups (Toppings / Sizes / etc.) ────────
                    ..._buildOptionGroupSections(),

                    // ─── Note Section ───────────────────────────────────
                    SliverToBoxAdapter(child: _buildNoteSection()),

                    // ─── Quantity Section ───────────────────────────────
                    SliverToBoxAdapter(child: _buildQuantitySection()),

                    // Bottom spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                )),
      // ─── Bottom Add to Cart Button ──────────────────────────
      bottomNavigationBar: _isLoading || _errorMessage != null ? null : _buildBottomButton(),
    );
  }

  // ─── Image Header ──────────────────────────────────────────────────────
  Widget _buildImageHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.inverseSurface.withValues(alpha: 0.26),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: AppColors.onPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: null,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface.withValues(alpha: 0.26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, color: AppColors.onPrimary, size: 18),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.bgWarm,
                  child: Icon(widget.icon, size: 80, color: AppColors.primary),
                ),
              )
            : Container(
                color: AppColors.bgWarm,
                child: Icon(widget.icon, size: 80, color: AppColors.primary),
              ),
      ),
    );
  }

  // ─── Food Header ──────────────────────────────────────────────────────
  Widget _buildFoodHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Price
              Text(
                widget.price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          const Text(
            'Món ăn thơm ngon, được chế biến từ nguyên liệu tươi sạch mỗi ngày.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Option Group Sections ─────────────────────────────────────────────
  List<Widget> _buildOptionGroupSections() {
    final List<Widget> widgets = [];
    for (int gi = 0; gi < _optionGroups.length; gi++) {
      widgets.add(SliverToBoxAdapter(child: _buildOptionGroupSection(gi)));
    }
    return widgets;
  }

  Widget _buildOptionGroupSection(int groupIndex) {
    final group = _optionGroups[groupIndex];
    final selected = _selectedItems[groupIndex] ?? {};

    // Build constraint label
    String constraintLabel;
    if (group.isRequired && group.maxSelect == 1) {
      constraintLabel = 'Bắt buộc, chọn 1';
    } else if (group.isRequired) {
      constraintLabel = 'Bắt buộc, chọn ${group.minSelect}-${group.maxSelect}';
    } else if (group.maxSelect == 1) {
      constraintLabel = 'Không bắt buộc, tối đa 1';
    } else if (group.maxSelect > 0) {
      constraintLabel = 'Không bắt buộc, tối đa ${group.maxSelect}';
    } else {
      constraintLabel = 'Không bắt buộc';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  group.groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  constraintLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Items
          ...List.generate(group.items.length, (itemIndex) {
            final item = group.items[itemIndex];
            final isSelected = selected.contains(itemIndex);
            final price = item['price'] as int;

            if (group.isSingleSelect) {
              return _buildRadioItem(
                name: item['name'] as String,
                price: price > 0 ? '+${_formatPrice(price)}' : '+0',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedItems.putIfAbsent(groupIndex, () => {});
                    if (isSelected) {
                      // Deselect if not required
                      if (!group.isRequired) {
                        _selectedItems[groupIndex]!.remove(itemIndex);
                      }
                    } else {
                      _selectedItems[groupIndex] = {itemIndex};
                    }
                  });
                },
              );
            } else {
              return _buildCheckboxItem(
                name: item['name'] as String,
                price: price > 0 ? '+${_formatPrice(price)}' : '+0',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedItems.putIfAbsent(groupIndex, () => {});
                    if (isSelected) {
                      _selectedItems[groupIndex]!.remove(itemIndex);
                    } else {
                      // Check max selection limit
                      if (group.maxSelect <= 0 || _selectedItems[groupIndex]!.length < group.maxSelect) {
                        _selectedItems[groupIndex]!.add(itemIndex);
                      }
                    }
                  });
                },
              );
            }
          }),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Note Section ──────────────────────────────────────────────────────
  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Thêm lưu ý cho quán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Không bắt buộc',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text field
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Việc thực hiện yêu cầu còn tùy thuộc vào khả năng của quán.',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Quantity Section ──────────────────────────────────────────────────
  Widget _buildQuantitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minus button
          GestureDetector(
            onTap: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _quantity > 1 ? AppColors.primary : AppColors.bgSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                size: 20,
                color: _quantity > 1 ? AppColors.onPrimary : AppColors.textTertiary,
              ),
            ),
          ),
          // Quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: () => setState(() => _quantity++),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Checkbox Item ─────────────────────────────────────────────────────
  Widget _buildCheckboxItem({
    required String name,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Price
            Text(
              price,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Radio Item (single select) ────────────────────────────────────────
  Widget _buildRadioItem({
    required String name,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Price
            Text(
              price,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Add to Cart Button ─────────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final selectedToppingsList = <ToppingSelectionModel>[];

              for (int gi = 0; gi < _optionGroups.length; gi++) {
                final group = _optionGroups[gi];
                final selected = _selectedItems[gi] ?? {};
                final isSizeGroup = group.id == 'sizes_group';

                for (final ii in selected) {
                  final item = group.items[ii];
                  selectedToppingsList.add(ToppingSelectionModel(
                    toppingId: item['id']?.toString() ?? 'item_${gi}_$ii',
                    name: isSizeGroup
                        ? 'Size ${item['name']}'
                        : item['name'] as String,
                    price: item['price'] as int,
                    groupId: group.id,
                    groupName: group.groupName,
                  ));
                }
              }

              // Find sizeId from size group
              String? sizeId;
              for (int gi = 0; gi < _optionGroups.length; gi++) {
                final group = _optionGroups[gi];
                if (group.id == 'sizes_group') {
                  final selected = _selectedItems[gi] ?? {};
                  if (selected.isNotEmpty) {
                    final ii = selected.first;
                    sizeId = group.items[ii]['id']?.toString();
                  }
                  break;
                }
              }

              Navigator.pop(context, {
                'quantity': _quantity,
                'total': _totalPrice,
                'note': _noteController.text.trim(),
                'selectedToppings': selectedToppingsList,
                'menuItemId': widget.menuItemId,
                'sizeId': sizeId,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.isEditing
                  ? 'Cập nhật - ${_formatPrice(_totalPrice)}đ'
                  : 'Thêm vào giỏ hàng - ${_formatPrice(_totalPrice)}đ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

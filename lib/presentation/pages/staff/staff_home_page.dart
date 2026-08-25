import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/topping_selection_model.dart';
import '../shop/add_to_cart_page.dart';
import '../../../data/repositories/order_repository.dart';
import 'package:dio/dio.dart';
import '../../../providers/order_provider.dart';

/// Staff Home Page — minimal, fast interface for in-store ordering.
/// Shows branch info, search, category tabs, menu items with quick-add.
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});
  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage> {
  final _searchController = TextEditingController();
  String _selectedCategoryName = 'Tất cả';
  String _searchQuery = '';
  int? _selectedTable;
  DateTime? _selectedHistoryDate;

  // Current order
  final List<_OrderItem> _orderItems = [];

  @override
  void initState() {
    super.initState();
  }

  List<_MenuItem> getDynamicMenuItems(BranchDetailModel? detail) {
    if (detail == null || detail.menu == null || detail.menu!.isEmpty) {
      return [];
    }
    final List<_MenuItem> items = [];
    for (final section in detail.menu!) {
      for (final item in section.items) {
        final priceVal =
            int.tryParse(item.price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        items.add(_MenuItem(
          id: item.menuItemId ?? (item.id ?? ''),
          name: item.name,
          price: priceVal,
          imageUrl: item.imageUrl,
          category: section.name,
        ));
      }
    }
    return items;
  }

  List<_MenuItem> _getFilteredItems(List<_MenuItem> allItems) {
    var items = allItems;
    if (_selectedCategoryName != 'Tất cả') {
      items = items.where((i) => i.category == _selectedCategoryName).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items
          .where(
              (i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return items;
  }

  int get _totalItems =>
      _orderItems.fold(0, (sum, item) => sum + item.quantity);
  int get _totalPrice =>
      _orderItems.fold(0, (sum, item) => sum + item.totalPrice);

  void _addItem(_MenuItem menuItem) {
    _openCustomizationSheet(menuItem);
  }

  Future<void> _openCustomizationSheet(_MenuItem menuItem,
      {int? existingIndex}) async {
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn bàn trước khi chọn món!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      _showTableSelector();
      return;
    }

    final user = ref.read(currentUserProvider);
    final branchId = user?.branchId ?? '';
    if (branchId.isEmpty) return;

    final existingItem =
        existingIndex != null ? _orderItems[existingIndex] : null;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToCartPage(
        name: menuItem.name,
        price: _formatPrice(menuItem.price),
        imageUrl: menuItem.imageUrl,
        menuItemId: menuItem.id,
        branchId: branchId,
        icon: Icons.fastfood_rounded,
        initialQuantity: existingItem?.quantity ?? 1,
        initialSelectedToppings: existingItem?.selectedToppings ?? [],
        initialNote: existingItem?.note,
        isEditing: existingItem != null,
        isStaffOrder: true,
      ),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      final q = result['quantity'] as int;
      final note = result['note'] as String?;
      final toppings =
          result['selectedToppings'] as List<ToppingSelectionModel>;
      final sizeId = result['sizeId'] as String?;

      setState(() {
        if (existingIndex != null) {
          if (q == 0) {
            _orderItems.removeAt(existingIndex);
          } else {
            _orderItems[existingIndex] = _OrderItem(
              menuItem: menuItem,
              quantity: q,
              note: note,
              selectedToppings: toppings,
              sizeId: sizeId,
            );
          }
        } else {
          // Kiểm tra xem đã có món tương tự với cùng tùy chọn hay chưa
          final duplicateIndex = _orderItems.indexWhere((item) =>
              item.menuItem.id == menuItem.id &&
              item.note == note &&
              item.sizeId == sizeId &&
              _areToppingsEqual(item.selectedToppings, toppings));

          if (duplicateIndex != -1) {
            _orderItems[duplicateIndex].quantity += q;
          } else {
            _orderItems.add(_OrderItem(
              menuItem: menuItem,
              quantity: q,
              note: note,
              selectedToppings: toppings,
              sizeId: sizeId,
            ));
          }
        }
      });
    }
  }

  bool _areToppingsEqual(
      List<ToppingSelectionModel> list1, List<ToppingSelectionModel> list2) {
    if (list1.length != list2.length) return false;
    final ids1 = list1.map((e) => e.toppingId).toList()..sort();
    final ids2 = list2.map((e) => e.toppingId).toList()..sort();
    for (int i = 0; i < ids1.length; i++) {
      if (ids1[i] != ids2[i]) return false;
    }
    return true;
  }

  void _removeItem(_MenuItem menuItem) {
    setState(() {
      final index =
          _orderItems.lastIndexWhere((i) => i.menuItem.id == menuItem.id);
      if (index != -1) {
        if (_orderItems[index].quantity > 1) {
          _orderItems[index].quantity--;
        } else {
          _orderItems.removeAt(index);
        }
      }
    });
  }

  int _getItemQuantity(_MenuItem menuItem) {
    return _orderItems
        .where((i) => i.menuItem.id == menuItem.id)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  void _clearOrder() {
    setState(() {
      _orderItems.clear();
      _selectedTable = null;
    });
  }

  void _showTableSelector() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn bàn phục vụ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn số bàn để bắt đầu order',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: 20,
              itemBuilder: (_, index) {
                final table = index + 1;
                final selected = _selectedTable == table;
                final currentOrders = ref.read(orderProvider);
                final isOccupied = currentOrders.any((o) =>
                    o.pagerNumber == '$table' &&
                    o.status != MockOrderStatus.completed &&
                    o.status != MockOrderStatus.cancelled
                );

                return GestureDetector(
                  onTap: () {
                    if (isOccupied) {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Bàn $table đã có đơn hàng!', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                          content: Text('Bàn số $table hiện đang có đơn hàng chưa hoàn tất. Vui lòng thanh toán hoặc hoàn tất đơn cũ trước khi đặt đơn mới.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    setState(() => _selectedTable = table);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : (isOccupied ? const Color(0xFFFEF2F2) : AppColors.surfaceContainerLowest),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : (isOccupied ? const Color(0xFFFCA5A5) : AppColors.outlineVariant),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$table${isOccupied ? '\n(Có đơn)' : ''}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isOccupied ? 12 : 16,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.onPrimary
                              : (isOccupied ? AppColors.error : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formattedđ';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final branchId = user?.branchId;

    BranchDetailModel? branchDetail;
    bool isBranchLoading = false;
    if (branchId != null && branchId.isNotEmpty) {
      final detailAsync = ref.watch(branchDetailFutureProvider(branchId));
      branchDetail = detailAsync.asData?.value;
      isBranchLoading = detailAsync.isLoading;
    }

    final allItems = getDynamicMenuItems(branchDetail);
    final filteredItems = _getFilteredItems(allItems);

    // Dynamic categories from branch detail menu
    final dynamicCategories = branchDetail?.menu
        ?.map((m) => CategoryModel(id: m.name, name: m.name, imageUrl: ''))
        .toList();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ─── Orange Header ─────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: 10),

            // ─── Table Selector & Search Bar (Placed above categories list) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildTableAndSearchRow(),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: isBranchLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : Column(
                      children: [
                        // ─── Categories ──────────────────────────────────────
                        _buildCategoriesWidget(dynamicCategories),
                        const SizedBox(height: 12),
                        // ─── Menu Items ──────────────────────────────────────
                        Expanded(child: _buildMenuList(filteredItems)),
                      ],
                    ),
            ),
          ],
        ),
        // ─── Bottom Order Bar ────────────────────────────────────
        bottomNavigationBar: _orderItems.isNotEmpty && !isBranchLoading
            ? _buildOrderBar()
            : null,
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = ref.watch(currentUserProvider);
    final rawName = user?.displayName;
    final displayName =
        (rawName == null || rawName.trim().isEmpty) ? 'Nhân viên' : rawName;
    final initialChar = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'S';

    final branchId = user?.branchId ?? '';
    String branchName = 'Đang tải chi nhánh...';
    if (branchId.isNotEmpty) {
      final detailAsync = ref.watch(branchDetailFutureProvider(branchId));
      branchName = detailAsync.value?.name ?? 'Chi nhánh';
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Clickable profile area (Avatar)
            GestureDetector(
              onTap: () => context.push(AppConstants.routeProfile),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initialChar,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppConstants.routeProfile),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${displayName.isNotEmpty ? displayName : 'Nhân viên'} · $branchName',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Actions: Active Receipt badge and the exact Admin Logout button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_orderItems.isNotEmpty) ...[
                  GestureDetector(
                    onTap: _showOrderDetail,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white30, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalItems',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: Colors.white,
                  ),
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: Colors.white, size: 22),
                    ),
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'history') {
                        _showOrderHistoryBottomSheet();
                      } else if (value == 'logout') {
                        _confirmLogout();
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem<String>(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded,
                                size: 18, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Lịch sử gọi món',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 18, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text(
                              'Thoát / Đăng xuất',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Table Selector & Search Bar Widget ────────────────────────────────
  Widget _buildTableAndSearchRow() {
    return Row(
      children: [
        // Search Bar (On the left)
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tìm món nhanh...',
              hintStyle: const TextStyle(
                  color: AppColors.textPlaceholder, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textTertiary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.textTertiary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Table Selector Icon Button (On the right)
        GestureDetector(
          onTap: _showTableSelector,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTable != null
                        ? AppColors.primary.withValues(alpha: 0.8)
                        : AppColors.divider.withValues(alpha: 0.8),
                    width: _selectedTable != null ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    color: _selectedTable != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              if (_selectedTable != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_selectedTable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Về trang Khách hàng?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn quay lại giao diện đặt món của Khách hàng không?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppConstants.routeProfile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  // ─── Categories ────────────────────────────────────────────────────────
  Widget _buildCategoriesWidget(List<CategoryModel>? dynamicCategories) {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    return categoriesAsync.when(
      data: (categories) => _buildCategories(dynamicCategories ?? categories),
      loading: () => _buildCategories(dynamicCategories ?? const []),
      error: (_, __) => _buildCategories(dynamicCategories ?? const []),
    );
  }

  Widget _buildCategories(List<CategoryModel> categories) {
    final list = [
      const CategoryModel(id: 'all', name: 'Tất cả', imageUrl: ''),
      ...categories,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = list[index];
          final name = cat.name;
          final selected = _selectedCategoryName == name;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryName = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        )
                      ]
                    : null,
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuList(List<_MenuItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy món',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final qty = _getItemQuantity(item);
        return _buildMenuItem(item, qty);
      },
    );
  }

  Widget _buildMenuItem(_MenuItem item, int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: qty > 0
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Food image
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : Image.asset(
                      item.imageUrl.isNotEmpty
                          ? item.imageUrl
                          : 'assets/images/tra_sua.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(item.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          if (qty > 0) ...[
            GestureDetector(
              onTap: () => _removeItem(item),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove,
                    size: 16, color: AppColors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$qty',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          // Add button
          GestureDetector(
            onTap: () => _addItem(item),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.add, size: 16, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order Bar ─────────────────────────────────────────────────────────
  Widget _buildOrderBar() {
    if (_orderItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Redesigned Price & Detail Info
            Expanded(
              child: GestureDetector(
                onTap: _showOrderDetail,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatPrice(_totalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_totalItems món',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Xem chi tiết đơn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Confirm button
            ElevatedButton(
              onPressed: _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                'Xác nhận đơn',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Order Detail Bottom Sheet ─────────────────────────────────────────
  void _showOrderDetail() {
    final user = ref.read(currentUserProvider);
    final branchId = user?.branchId ?? '';
    String branchName = 'Chi nhánh';
    if (branchId.isNotEmpty) {
      final detail = ref.read(branchDetailFutureProvider(branchId)).value;
      if (detail != null) {
        branchName = detail.name;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đơn hiện tại',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _clearOrder();
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              'Xóa tất cả',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error),
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.divider.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _selectedTable != null
                            ? 'Bàn $_selectedTable · $branchName'
                            : 'Chưa chọn bàn · $branchName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            // Items list (scrolling internally, no controller needed)
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _orderItems.length,
                itemBuilder: (_, index) {
                  final item = _orderItems[index];
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: AppColors.divider, width: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Dish details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuItem.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (item.selectedToppings.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.selectedToppings
                                      .map((t) => t.name)
                                      .join(', '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                              if (item.note != null &&
                                  item.note!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Ghi chú: "${item.note}"',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textTertiary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _openCustomizationSheet(item.menuItem,
                                      existingIndex: index);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_note_rounded,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sửa tùy chọn',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Price & Counter controls
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPrice(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (item.quantity > 1) {
                                        item.quantity--;
                                      } else {
                                        _orderItems.removeAt(index);
                                      }
                                    });
                                    if (_orderItems.isEmpty) Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgSoft,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.divider
                                              .withValues(alpha: 0.5)),
                                    ),
                                    child: const Icon(Icons.remove,
                                        size: 14, color: AppColors.textPrimary),
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      item.quantity++;
                                    });
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add,
                                        size: 14, color: AppColors.onPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Total & Action Button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng cộng',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          _formatPrice(_totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xác nhận đơn',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
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

  // ─── Confirm Order ─────────────────────────────────────────────────────
  Future<void> _confirmOrder() async {
    if (_orderItems.isEmpty) return;
    final user = ref.read(currentUserProvider);
    final branchId = user?.branchId ?? '';
    if (branchId.isEmpty) return;

    // Hiển thị hộp thoại loading chặn UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);

      bool isUuid(String? str) {
        if (str == null) return false;
        return uuidRegex.hasMatch(str);
      }

      final itemsPayload = _orderItems.map((item) {
        // Tìm kích cỡ nếu có (ưu tiên sizeId đã được chọn lưu trong item)
        String? sizeId = item.sizeId;
        if (sizeId == null || sizeId.isEmpty) {
          final sizeTopping = item.selectedToppings.firstWhere(
            (t) => t.name.toLowerCase().contains('size') && isUuid(t.toppingId),
            orElse: () => const ToppingSelectionModel(toppingId: '', name: '', price: 0),
          );
          if (sizeTopping.toppingId.isNotEmpty) {
            sizeId = sizeTopping.toppingId;
          }
        }

        // Danh sách toppings đi kèm
        final toppingsList = item.selectedToppings
            .where((t) => !t.name.toLowerCase().contains('size') && isUuid(t.toppingId))
            .map((t) => {"toppingId": t.toppingId, "quantity": 1})
            .toList();

        return {
          "menuItemId": item.menuItem.id,
          "sizeId": sizeId,
          "quantity": item.quantity,
          "note": item.note,
          "toppings": toppingsList,
        };
      }).toList();

      final user = ref.read(currentUserProvider);
      final staffName = user?.fullName ?? user?.username ?? 'Nhân viên';
      final payload = {
        "branchId": branchId,
        "paymentMethod": "Cash", // Cash (Tiền mặt) - Yêu cầu dạng String do Backend sử dụng JsonStringEnumConverter
        "items": itemsPayload,
        "note": "Yêu cầu bởi: $staffName${_selectedTable != null ? ' - Bàn $_selectedTable' : ''}",
        "pagerNumber": _selectedTable?.toString(),
      };

      print('[StaffHomePage] Gửi đơn hàng kiosk lên server: $payload');
      final repository = OrderRepository();
      await repository.placeKioskOrder(payload);

      // Đóng hộp thoại loading
      if (mounted) Navigator.pop(context);

      // Hiển thị hộp thoại thông báo thành công
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.successContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      size: 36, color: AppColors.success),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đã gửi đơn!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bàn $_selectedTable · $_totalItems món · ${_formatPrice(_totalPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đơn đã gửi đến thu ngân',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _clearOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Tạo đơn mới',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Đóng hộp thoại loading
      if (mounted) Navigator.pop(context);

      String errorDetail = e.toString();
      if (e is DioException) {
        final resp = e.response?.data;
        if (resp is Map<String, dynamic>) {
          final title = resp['title'] ?? resp['Title'];
          final msg = resp['message'] ?? resp['Message'] ?? resp['error'] ?? resp['Error'];
          final errorsObj = resp['errors'] ?? resp['Errors'];
          
          if (title != null || msg != null || errorsObj != null) {
            errorDetail = '';
            if (title != null) errorDetail += '$title. ';
            if (msg != null) errorDetail += '$msg. ';
            if (errorsObj != null) {
              errorDetail += 'Chi tiết: ${errorsObj.toString()}';
            }
          } else {
            errorDetail = e.message ?? e.toString();
          }
        } else if (resp is String && resp.isNotEmpty) {
          errorDetail = resp;
        } else if (e.response?.statusMessage != null) {
          errorDetail = 'Lỗi ${e.response?.statusCode}: ${e.response?.statusMessage}';
        } else {
          errorDetail = e.message ?? e.toString();
        }
      }

      // Hiển thị lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi đơn lên server: $errorDetail'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOrderHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final user = ref.watch(currentUserProvider);
            final staffName = user?.fullName ?? user?.username ?? 'Nhân viên';
            final allOrders = ref.watch(orderProvider);
            
            // Filter branch orders
            final branchOrders = allOrders.where((o) => o.branchId == user?.branchId).toList();
            var myOrders = branchOrders.where((o) => o.storeNote?.contains(staffName) == true).toList();
            
            if (_selectedHistoryDate != null) {
              myOrders = myOrders.where((o) =>
                o.orderTime.year == _selectedHistoryDate!.year &&
                o.orderTime.month == _selectedHistoryDate!.month &&
                o.orderTime.day == _selectedHistoryDate!.day
              ).toList();
            }
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Lịch sử gọi món',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date Filter Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lọc theo ngày:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedHistoryDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _selectedHistoryDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedHistoryDate != null ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedHistoryDate != null ? AppColors.primary : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 14,
                                  color: _selectedHistoryDate != null ? AppColors.primary : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedHistoryDate == null
                                      ? 'Tất cả thời gian'
                                      : '${_selectedHistoryDate!.day.toString().padLeft(2, '0')}/${_selectedHistoryDate!.month.toString().padLeft(2, '0')}/${_selectedHistoryDate!.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedHistoryDate != null ? AppColors.primary : const Color(0xFF475569),
                                  ),
                                ),
                                if (_selectedHistoryDate != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _selectedHistoryDate = null;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // List content
                  Expanded(
                    child: _buildHistoryOrderList(myOrders, staffName),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryOrderList(List<MockOrder> orders, String staffName) {
    final user = ref.read(currentUserProvider);

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          if (user?.branchId != null) {
            await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
          }
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'Không có đơn hàng nào',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (user?.branchId != null) {
          await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
        }
      },
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: orders.length,
        itemBuilder: (ctx, index) {
          final order = orders[index];
          
          // Status Badge color mapping
          Color statusColor;
          Color statusBg;
          String statusLabel;
          
          switch (order.status) {
            case MockOrderStatus.pendingConfirm:
              statusColor = const Color(0xFFD97706);
              statusBg = const Color(0xFFFEF3C7);
              statusLabel = 'Chờ xác nhận';
              break;
            case MockOrderStatus.preparing:
              statusColor = const Color(0xFF2563EB);
              statusBg = const Color(0xFFDBEAFE);
              statusLabel = 'Đang chuẩn bị';
              break;
            case MockOrderStatus.ready:
              statusColor = const Color(0xFF059669);
              statusBg = const Color(0xFFD1FAE5);
              statusLabel = 'Sẵn sàng';
              break;
            case MockOrderStatus.completed:
              statusColor = const Color(0xFF64748B);
              statusBg = const Color(0xFFF1F5F9);
              statusLabel = 'Đã hoàn thành';
              break;
            case MockOrderStatus.cancelled:
              statusColor = const Color(0xFFDC2626);
              statusBg = const Color(0xFFFEE2E2);
              statusLabel = 'Đã hủy';
              break;
          }

          final timeStr = '${order.orderTime.hour.toString().padLeft(2, '0')}:${order.orderTime.minute.toString().padLeft(2, '0')} · ${order.orderTime.day.toString().padLeft(2, '0')}/${order.orderTime.month.toString().padLeft(2, '0')}/${order.orderTime.year}';
          final totalStr = '${order.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600, 
                                color: Color(0xFF475569),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (order.pagerNumber != null && order.pagerNumber!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bàn ${order.pagerNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Detailed Items List
                ...order.items.map((item) {
                  final hasSize = item.sizeLabel != null && item.sizeLabel!.isNotEmpty;
                  final hasExtras = item.extras != null && item.extras!.isNotEmpty;
                  final hasNote = item.note != null && item.note!.trim().isNotEmpty;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(item.price * item.quantity).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        if (hasSize) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Size: ${item.sizeLabel}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                        if (hasExtras) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Topping: ${item.extras}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                        if (hasNote) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ghi chú: ${item.note}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                
                if (order.storeNote != null && order.storeNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Text(
                      order.storeNote!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thời gian: $timeStr',
                      style: const TextStyle(
                        fontSize: 11, 
                        color: Color(0xFF94A3B8), 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      totalStr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────

class _MenuItem {
  final String id;
  final String name;
  final int price;
  final String category;
  final String imageUrl;

  _MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}

class _OrderItem {
  final _MenuItem menuItem;
  int quantity;
  String? note;
  List<ToppingSelectionModel> selectedToppings;
  String? sizeId;

  _OrderItem({
    required this.menuItem,
    required this.quantity,
    this.note,
    this.selectedToppings = const [],
    this.sizeId,
  });

  int get unitPrice {
    final toppingsPrice =
        selectedToppings.fold<int>(0, (sum, t) => sum + t.price);
    return menuItem.price + toppingsPrice;
  }

  int get totalPrice => unitPrice * quantity;
}

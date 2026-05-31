import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

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

  // Current order
  final List<_OrderItem> _orderItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTableSelector();
    });
  }

  // Mock menu items
  static final _menuItems = [
    _MenuItem(name: 'Phở bò tái', price: 45000, category: 'Phở', imageUrl: 'assets/images/pho.jpg'),
    _MenuItem(name: 'Phở bò viên', price: 45000, category: 'Phở', imageUrl: 'assets/images/pho.jpg'),
    _MenuItem(name: 'Phở bò tái nạm', price: 50000, category: 'Phở', imageUrl: 'assets/images/pho.jpg'),
    _MenuItem(name: 'Phở gà', price: 45000, category: 'Phở', imageUrl: 'assets/images/pho.jpg'),
    _MenuItem(name: 'Phở đặc biệt', price: 60000, category: 'Phở', imageUrl: 'assets/images/pho.jpg'),
    _MenuItem(name: 'Cơm sườn nướng', price: 55000, category: 'Cơm', imageUrl: 'assets/images/com.webp'),
    _MenuItem(name: 'Cơm gà xối mỡ', price: 50000, category: 'Cơm', imageUrl: 'assets/images/com.webp'),
    _MenuItem(name: 'Cơm tấm bì chả', price: 45000, category: 'Cơm', imageUrl: 'assets/images/com.webp'),
    _MenuItem(name: 'Cơm chiên dương châu', price: 50000, category: 'Cơm', imageUrl: 'assets/images/com.webp'),
    _MenuItem(name: 'Bún bò Huế', price: 50000, category: 'Bún', imageUrl: 'assets/images/pho_bo.png'),
    _MenuItem(name: 'Bún chả Hà Nội', price: 48000, category: 'Bún', imageUrl: 'assets/images/pho_bo.png'),
    _MenuItem(name: 'Bún riêu cua', price: 45000, category: 'Bún', imageUrl: 'assets/images/pho_bo.png'),
    _MenuItem(name: 'Trà đào cam sả', price: 29000, category: 'Nước', imageUrl: 'assets/images/tra_sua.jpg'),
    _MenuItem(name: 'Cà phê sữa đá', price: 25000, category: 'Nước', imageUrl: 'assets/images/tra_sua.jpg'),
    _MenuItem(name: 'Nước ép cam', price: 30000, category: 'Nước', imageUrl: 'assets/images/tra_sua.jpg'),
    _MenuItem(name: 'Sinh tố bơ', price: 35000, category: 'Nước', imageUrl: 'assets/images/tra_sua.jpg'),
    _MenuItem(name: 'Trà sữa trân châu', price: 35000, category: 'Nước', imageUrl: 'assets/images/tra_sua.jpg'),
    _MenuItem(name: 'Chè khúc bạch', price: 25000, category: 'Tráng miệng', imageUrl: 'assets/images/tra_sua.jpg'),
    _MenuItem(name: 'Bánh flan', price: 20000, category: 'Tráng miệng', imageUrl: 'assets/images/tra_sua.jpg'),
  ];

  List<_MenuItem> get _filteredItems {
    var items = _menuItems;
    // Filter by category
    if (_selectedCategoryName != 'Tất cả') {
      items = items.where((i) => i.category == _selectedCategoryName).toList();
    }
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return items;
  }

  int get _totalItems => _orderItems.fold(0, (sum, item) => sum + item.quantity);
  int get _totalPrice => _orderItems.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));

  void _addItem(_MenuItem menuItem) {
    setState(() {
      final existing = _orderItems.where((i) => i.menuItem.name == menuItem.name);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _orderItems.add(_OrderItem(menuItem: menuItem, quantity: 1));
      }
    });
  }

  void _removeItem(_MenuItem menuItem) {
    setState(() {
      final existing = _orderItems.where((i) => i.menuItem.name == menuItem.name);
      if (existing.isNotEmpty) {
        if (existing.first.quantity > 1) {
          existing.first.quantity--;
        } else {
          _orderItems.removeWhere((i) => i.menuItem.name == menuItem.name);
        }
      }
    });
  }

  int _getItemQuantity(_MenuItem menuItem) {
    final existing = _orderItems.where((i) => i.menuItem.name == menuItem.name);
    return existing.isNotEmpty ? existing.first.quantity : 0;
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
      isDismissible: _selectedTable != null,
      enableDrag: _selectedTable != null,
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
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTable = table);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$table',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.onPrimary : AppColors.textPrimary,
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
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return '$price';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── Orange Header ─────────────────────────────────────
          _buildHeader(),
          // ─── Categories ──────────────────────────────────────
          _buildCategoriesWidget(),
          const SizedBox(height: 12),
          // ─── Menu Items ──────────────────────────────────────
          Expanded(child: _buildMenuList()),
        ],
      ),
      // ─── Bottom Order Bar ────────────────────────────────────
      bottomNavigationBar: _orderItems.isNotEmpty ? _buildOrderBar() : null,
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'Nhân viên';
    final initialChar = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'S';

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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Row (Profile + Actions)
            Row(
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
                        const Text(
                          'DineX Staff · Nhân viên',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
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
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                      onPressed: _confirmLogout,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Bottom row: Table Selector & Search Bar
            Row(
              children: [
                // Table Selector
                GestureDetector(
                  onTap: _showTableSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.table_restaurant_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTable != null ? 'Bàn $_selectedTable' : 'Chọn bàn',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Search Bar
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tìm món nhanh...',
                      hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                              onPressed: () {
                                _searchController.clear();
                                  setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
            Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Đăng xuất tài khoản?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi màn hình nhân viên phục vụ không?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppConstants.routeLogin);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  // ─── Categories ────────────────────────────────────────────────────────
  Widget _buildCategoriesWidget() {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    return categoriesAsync.when(
      data: (categories) => _buildCategories(categories),
      loading: () => _buildCategories(const []),
      error: (_, __) => _buildCategories(const []),
    );
  }

  Widget _buildCategories(List<CategoryModel> categories) {
    final list = [
      const CategoryModel(id: 'all', name: 'Tất cả', imageUrl: ''),
      ...categories,
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = list[index];
          final name = cat.name;
          final imageUrl = cat.imageUrl;
          final selected = _selectedCategoryName == name;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryName = name),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? (imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : Image.asset(
                                imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ))
                        : Container(
                            color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Menu List ─────────────────────────────────────────────────────────
  Widget _buildMenuList() {
    final items = _filteredItems;
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
        border: qty > 0 ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
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
              child: Image.asset(item.imageUrl, fit: BoxFit.cover),
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
                child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
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
              child: const Icon(Icons.add, size: 16, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order Bar ─────────────────────────────────────────────────────────
  Widget _buildOrderBar() {
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
            // Order info
            Expanded(
              child: GestureDetector(
                onTap: _showOrderDetail,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_totalItems món · ${_formatPrice(_totalPrice)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        const Text(
                          'Xem chi tiết đơn',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
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
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.table_restaurant, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Bàn $_selectedTable · Chi nhánh Quận 1',
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
              // Items
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _orderItems.length,
                  itemBuilder: (_, index) {
                    final item = _orderItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(item.menuItem.price * item.quantity),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Qty controls
                          GestureDetector(
                            onTap: () {
                              _removeItem(item.menuItem);
                              if (_orderItems.isEmpty) Navigator.pop(ctx);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.bgSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _addItem(item.menuItem),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.add, size: 16, color: AppColors.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Total
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
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Confirm Order ─────────────────────────────────────────────────────
  void _confirmOrder() {
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
              child: const Icon(Icons.check_circle, size: 36, color: AppColors.success),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Tạo đơn mới', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────

class _MenuItem {
  final String name;
  final int price;
  final String category;
  final String imageUrl;

  _MenuItem({required this.name, required this.price, required this.category, required this.imageUrl});
}

class _OrderItem {
  final _MenuItem menuItem;
  int quantity;

  _OrderItem({required this.menuItem, required this.quantity});
}

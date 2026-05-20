import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

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
  int _selectedCategory = 0;
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

  // Mock categories with icons
  static const _categories = [
    {'name': 'Tất cả', 'icon': '🍽️'},
    {'name': 'Phở', 'icon': '🍲'},
    {'name': 'Cơm', 'icon': '🍚'},
    {'name': 'Bún', 'icon': '🍜'},
    {'name': 'Nước', 'icon': '🧋'},
    {'name': 'Tráng miệng', 'icon': '🍰'},
  ];

  // Mock menu items
  static final _menuItems = [
    _MenuItem(name: 'Phở bò tái', price: 45000, category: 'Phở', emoji: '🍲'),
    _MenuItem(name: 'Phở bò viên', price: 45000, category: 'Phở', emoji: '🍲'),
    _MenuItem(name: 'Phở bò tái nạm', price: 50000, category: 'Phở', emoji: '🍲'),
    _MenuItem(name: 'Phở gà', price: 45000, category: 'Phở', emoji: '🐔'),
    _MenuItem(name: 'Phở đặc biệt', price: 60000, category: 'Phở', emoji: '⭐'),
    _MenuItem(name: 'Cơm sườn nướng', price: 55000, category: 'Cơm', emoji: '🥩'),
    _MenuItem(name: 'Cơm gà xối mỡ', price: 50000, category: 'Cơm', emoji: '🍗'),
    _MenuItem(name: 'Cơm tấm bì chả', price: 45000, category: 'Cơm', emoji: '🍚'),
    _MenuItem(name: 'Cơm chiên dương châu', price: 50000, category: 'Cơm', emoji: '🍳'),
    _MenuItem(name: 'Bún bò Huế', price: 50000, category: 'Bún', emoji: '🌶️'),
    _MenuItem(name: 'Bún chả Hà Nội', price: 48000, category: 'Bún', emoji: '🥢'),
    _MenuItem(name: 'Bún riêu cua', price: 45000, category: 'Bún', emoji: '🦀'),
    _MenuItem(name: 'Trà đào cam sả', price: 29000, category: 'Nước', emoji: '🍑'),
    _MenuItem(name: 'Cà phê sữa đá', price: 25000, category: 'Nước', emoji: '☕'),
    _MenuItem(name: 'Nước ép cam', price: 30000, category: 'Nước', emoji: '🍊'),
    _MenuItem(name: 'Sinh tố bơ', price: 35000, category: 'Nước', emoji: '🥑'),
    _MenuItem(name: 'Trà sữa trân châu', price: 35000, category: 'Nước', emoji: '🧋'),
    _MenuItem(name: 'Chè khúc bạch', price: 25000, category: 'Tráng miệng', emoji: '🍮'),
    _MenuItem(name: 'Bánh flan', price: 20000, category: 'Tráng miệng', emoji: '🍮'),
  ];

  List<_MenuItem> get _filteredItems {
    var items = _menuItems;
    // Filter by category
    if (_selectedCategory > 0) {
      final cat = (_categories[_selectedCategory]['name'] as String);
      items = items.where((i) => i.category == cat).toList();
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
          _buildCategories(),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryActive, AppColors.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              // Branch info row
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: AppColors.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BMC Phở Express',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Chi nhánh Quận 1 · Tầng 1',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _showTableSelector,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedTable != null
                                  ? AppColors.onPrimary
                                  : AppColors.onPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.table_restaurant,
                                  size: 16,
                                  color: _selectedTable != null
                                      ? AppColors.primary
                                      : AppColors.onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedTable != null
                                      ? 'Bàn $_selectedTable'
                                      : 'Chọn bàn',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _selectedTable != null
                                        ? AppColors.primary
                                        : AppColors.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: _selectedTable != null
                                      ? AppColors.primary
                                      : AppColors.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Order count badge
                  if (_orderItems.isNotEmpty)
                    GestureDetector(
                      onTap: _showOrderDetail,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long, size: 16, color: AppColors.onPrimary),
                            const SizedBox(width: 4),
                            Text(
                              '$_totalItems',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Search bar
              TextField(
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Categories ────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          final cat = _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['icon'] as String, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
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
          // Food image placeholder with emoji
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
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
  final String emoji;

  _MenuItem({required this.name, required this.price, required this.category, required this.emoji});
}

class _OrderItem {
  final _MenuItem menuItem;
  int quantity;

  _OrderItem({required this.menuItem, required this.quantity});
}

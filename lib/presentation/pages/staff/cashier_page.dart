import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

/// Cashier Page — receives orders from staff + creates takeaway orders.
/// Two tabs: "Đơn chờ" (pending from staff) and "Tạo đơn mang đi".
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class CashierPage extends ConsumerStatefulWidget {
  const CashierPage({super.key});
  @override
  ConsumerState<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends ConsumerState<CashierPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;

  // Takeaway order
  final List<_OrderItem> _takeawayItems = [];

  // Mock pending orders from staff
  final List<_PendingOrder> _pendingOrders = [
    _PendingOrder(
      id: '#001',
      table: 5,
      items: [
        _OrderItem(menuItem: _MenuItem(name: 'Phở bò tái', price: 45000, imageUrl: 'assets/images/pho.jpg'), quantity: 2),
        _OrderItem(menuItem: _MenuItem(name: 'Cà phê sữa đá', price: 25000, imageUrl: 'assets/images/tra_sua.jpg'), quantity: 1),
      ],
      time: '2 phút trước',
      isNew: true,
    ),
    _PendingOrder(
      id: '#002',
      table: 2,
      items: [
        _OrderItem(menuItem: _MenuItem(name: 'Cơm sườn nướng', price: 55000, imageUrl: 'assets/images/com.webp'), quantity: 1),
        _OrderItem(menuItem: _MenuItem(name: 'Trà đào cam sả', price: 29000, imageUrl: 'assets/images/tra_sua.jpg'), quantity: 2),
      ],
      time: '5 phút trước',
      isNew: false,
    ),
    _PendingOrder(
      id: '#003',
      table: 8,
      items: [
        _OrderItem(menuItem: _MenuItem(name: 'Bún bò Huế', price: 50000, imageUrl: 'assets/images/pho_bo.png'), quantity: 3),
      ],
      time: '8 phút trước',
      isNew: false,
    ),
  ];

  // Menu for takeaway
  static const _categories = [
    {'name': 'Tất cả', 'imageUrl': ''},
    {'name': 'Phở', 'imageUrl': 'assets/images/pho.jpg'},
    {'name': 'Cơm', 'imageUrl': 'assets/images/com.webp'},
    {'name': 'Bún', 'imageUrl': 'assets/images/pho_bo.png'},
    {'name': 'Nước', 'imageUrl': 'assets/images/tra_sua.jpg'},
    {'name': 'Tráng miệng', 'imageUrl': 'assets/images/tra_sua.jpg'},
  ];

  static final _menuItems = [
    _MenuItem(name: 'Phở bò tái', price: 45000, imageUrl: 'assets/images/pho.jpg', category: 'Phở'),
    _MenuItem(name: 'Phở bò viên', price: 45000, imageUrl: 'assets/images/pho.jpg', category: 'Phở'),
    _MenuItem(name: 'Phở đặc biệt', price: 60000, imageUrl: 'assets/images/pho.jpg', category: 'Phở'),
    _MenuItem(name: 'Cơm sườn nướng', price: 55000, imageUrl: 'assets/images/com.webp', category: 'Cơm'),
    _MenuItem(name: 'Cơm gà xối mỡ', price: 50000, imageUrl: 'assets/images/com.webp', category: 'Cơm'),
    _MenuItem(name: 'Cơm tấm bì chả', price: 45000, imageUrl: 'assets/images/com.webp', category: 'Cơm'),
    _MenuItem(name: 'Bún bò Huế', price: 50000, imageUrl: 'assets/images/pho_bo.png', category: 'Bún'),
    _MenuItem(name: 'Bún chả Hà Nội', price: 48000, imageUrl: 'assets/images/pho_bo.png', category: 'Bún'),
    _MenuItem(name: 'Trà đào cam sả', price: 29000, imageUrl: 'assets/images/tra_sua.jpg', category: 'Nước'),
    _MenuItem(name: 'Cà phê sữa đá', price: 25000, imageUrl: 'assets/images/tra_sua.jpg', category: 'Nước'),
    _MenuItem(name: 'Sinh tố bơ', price: 35000, imageUrl: 'assets/images/tra_sua.jpg', category: 'Nước'),
    _MenuItem(name: 'Chè khúc bạch', price: 25000, imageUrl: 'assets/images/tra_sua.jpg', category: 'Tráng miệng'),
  ];

  List<_MenuItem> get _filteredItems {
    var items = _menuItems;
    if (_selectedCategory > 0) {
      final cat = _categories[_selectedCategory]['name'] as String;
      items = items.where((i) => i.category == cat).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return items;
  }

  int get _takeawayTotal => _takeawayItems.fold(0, (sum, i) => sum + (i.menuItem.price * i.quantity));
  int get _takeawayCount => _takeawayItems.fold(0, (sum, i) => sum + i.quantity);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addTakeawayItem(_MenuItem item) {
    setState(() {
      final existing = _takeawayItems.where((i) => i.menuItem.name == item.name);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _takeawayItems.add(_OrderItem(menuItem: item, quantity: 1));
      }
    });
  }

  void _removeTakeawayItem(_MenuItem item) {
    setState(() {
      final existing = _takeawayItems.where((i) => i.menuItem.name == item.name);
      if (existing.isNotEmpty) {
        if (existing.first.quantity > 1) {
          existing.first.quantity--;
        } else {
          _takeawayItems.removeWhere((i) => i.menuItem.name == item.name);
        }
      }
    });
  }

  int _getTakeawayQty(_MenuItem item) {
    final existing = _takeawayItems.where((i) => i.menuItem.name == item.name);
    return existing.isNotEmpty ? existing.first.quantity : 0;
  }

  String _formatPrice(int price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}k';
    return '$price';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingOrdersTab(),
                _buildTakeawayTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabController.index == 1 && _takeawayItems.isNotEmpty
          ? _buildTakeawayBar()
          : null,
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppColors.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thu ngân',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'BMC Phở Express · Chi nhánh Q1',
                          style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
                        ),
                      ],
                    ),
                  ),
                  // Pending count
                  if (_pendingOrders.where((o) => o.isNew).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active, size: 14, color: AppColors.onPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '${_pendingOrders.where((o) => o.isNew).length}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onPrimary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicator: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onPrimary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Đơn chờ (${_pendingOrders.length})'),
                    const Tab(text: 'Tạo đơn mang đi'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pending Orders Tab ────────────────────────────────────────────────
  Widget _buildPendingOrdersTab() {
    if (_pendingOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('Chưa có đơn chờ', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingOrders.length,
      itemBuilder: (_, index) => _buildPendingOrderCard(_pendingOrders[index], index),
    );
  }

  Widget _buildPendingOrderCard(_PendingOrder order, int index) {
    final total = order.items.fold(0, (sum, i) => sum + (i.menuItem.price * i.quantity));
    final itemCount = order.items.fold(0, (sum, i) => sum + i.quantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: order.isNew ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              if (order.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('MỚI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onPrimary)),
                ),
              Text(
                'Bàn ${order.table}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(order.id, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const Spacer(),
              Text(order.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          // Items preview
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(item.menuItem.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.menuItem.name} x${item.quantity}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  _formatPrice(item.menuItem.price * item.quantity),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          )),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          // Footer
          Row(
            children: [
              Text(
                '$itemCount món · ${_formatPrice(total)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _confirmPendingOrder(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Xác nhận & In bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmPendingOrder(int index) {
    final order = _pendingOrders[index];
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
              decoration: const BoxDecoration(color: AppColors.successContainer, shape: BoxShape.circle),
              child: const Icon(Icons.print, size: 32, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Đã xác nhận!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Bàn ${order.table} · ${order.id}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Bill đã gửi đến bếp', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _pendingOrders.removeAt(index));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Takeaway Tab ──────────────────────────────────────────────────────
  Widget _buildTakeawayTab() {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tìm món...',
              hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                      onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Categories
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (_, index) {
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
                      border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: (cat['imageUrl'] as String).isNotEmpty
                                ? Image.asset(cat['imageUrl'] as String, fit: BoxFit.cover)
                                : Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 12,
                                    color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                                  ),
                          ),
                        ),
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
        ),
        const SizedBox(height: 8),
        // Menu list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: _filteredItems.length,
            itemBuilder: (_, index) {
              final item = _filteredItems[index];
              final qty = _getTakeawayQty(item);
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(10)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(item.imageUrl, fit: BoxFit.cover, width: 44, height: 44),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(_formatPrice(item.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    if (qty > 0) ...[
                      GestureDetector(
                        onTap: () => _removeTakeawayItem(item),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(7)),
                          child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('$qty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                    ],
                    GestureDetector(
                      onTap: () => _addTakeawayItem(item),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                        child: const Icon(Icons.add, size: 16, color: AppColors.onPrimary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Takeaway Bottom Bar ───────────────────────────────────────────────
  Widget _buildTakeawayBar() {
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
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mang đi · $_takeawayCount món · ${_formatPrice(_takeawayTotal)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  const Text('Bấm để xác nhận và in bill', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _confirmTakeaway,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Xác nhận & In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTakeaway() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.successContainer, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, size: 36, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Đơn mang đi hoàn tất!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('$_takeawayCount món · ${_formatPrice(_takeawayTotal)}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Bill đã gửi bếp + in cho khách', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _takeawayItems.clear());
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
  final String imageUrl;
  final String category;

  _MenuItem({required this.name, required this.price, required this.imageUrl, this.category = ''});
}

class _OrderItem {
  final _MenuItem menuItem;
  int quantity;

  _OrderItem({required this.menuItem, required this.quantity});
}

class _PendingOrder {
  final String id;
  final int table;
  final List<_OrderItem> items;
  final String time;
  bool isNew;

  _PendingOrder({required this.id, required this.table, required this.items, required this.time, this.isNew = false});
}

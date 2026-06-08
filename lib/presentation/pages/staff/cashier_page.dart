import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/constants/app_constants.dart';


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
  String _selectedCategoryName = 'Tất cả';

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
    if (_selectedCategoryName != 'Tất cả') {
      items = items.where((i) => i.category == _selectedCategoryName).toList();
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
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'Quản lý';
    final initialChar = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'M';
    final newPendingCount = _pendingOrders.where((o) => o.isNew).length;

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
                          'DineX Cashier · Thu ngân',
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
                // Actions: Notification bell and the exact Admin Logout button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            _tabController.animateTo(0);
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                          ),
                          tooltip: 'Đơn chờ',
                        ),
                        if (newPendingCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary, width: 1.5),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '$newPendingCount',
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
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
            // TabBar section
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'Đơn chờ (${_pendingOrders.length})'),
                  const Tab(text: 'Tạo đơn mang đi'),
                ],
              ),
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
            Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Về trang Khách hàng?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppConstants.routeProfile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  // ─── Pending Orders Tab ────────────────────────────────────────────────
  Widget _buildPendingOrdersTab() {
    final customerOrders = ref.watch(orderProvider);

    if (_pendingOrders.isEmpty && customerOrders.isEmpty) {
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Phân hệ đơn hàng Self-Pickup từ Khách trực tuyến
        if (customerOrders.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.takeout_dining_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ĐƠN SELF-PICKUP KHÁCH ĐẶT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${customerOrders.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...customerOrders.map((order) => _buildCustomerPickupOrderCard(order)),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),
        ],

        // 2. Đơn phục vụ tại bàn của Nhân viên gửi lên
        if (_pendingOrders.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.table_restaurant_rounded, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Text(
                'ĐƠN PHỤC VỤ TẠI BÀN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _pendingOrders.length,
            (index) => _buildPendingOrderCard(_pendingOrders[index], index),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerPickupOrderCard(MockOrder order) {
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (order.status) {
      case MockOrderStatus.pendingConfirm:
        statusBgColor = const Color(0xFFFFF3CD);
        statusTextColor = const Color(0xFF856404);
        statusText = 'Chờ xác nhận';
        break;
      case MockOrderStatus.preparing:
        statusBgColor = const Color(0xFFFFE8D6);
        statusTextColor = const Color(0xFFD35400);
        statusText = 'Đang chuẩn bị';
        break;
      case MockOrderStatus.ready:
        statusBgColor = const Color(0xFFD4EDDA);
        statusTextColor = const Color(0xFF155724);
        statusText = 'Chờ nhận món';
        break;
      case MockOrderStatus.completed:
        statusBgColor = const Color(0xFFE2E3E5);
        statusTextColor = const Color(0xFF383D41);
        statusText = 'Đã lấy món';
        break;
      case MockOrderStatus.cancelled:
        statusBgColor = const Color(0xFFF8D7DA);
        statusTextColor = const Color(0xFF721C24);
        statusText = 'Đã hủy đơn';
        break;
    }

    final total = order.totalAmount;
    final formattedPickupTime =
        '${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: order.status == MockOrderStatus.pendingConfirm
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5)
            : Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.takeout_dining_rounded, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('SELF-PICKUP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.id,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items preview
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.name} x${item.quantity}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      _formatPrice(item.price * item.quantity),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )),

          if (order.items.isNotEmpty && order.items[0].extras != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                order.items[0].extras!,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Time & Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khách hẹn lấy lúc: $formattedPickupTime',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: order.extraMinutes > 0 ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  if (order.extraMinutes > 0)
                    Text(
                      'Đã cộng thêm +${order.extraMinutes} phút',
                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                    )
                  else
                    Text(
                      'Thời gian gốc: ${order.originalMinutes}p',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    )
                ],
              ),
              Text(
                '${(total / 1000).toStringAsFixed(0)}k đ',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Interactive Action Buttons
          if (order.status != MockOrderStatus.completed)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Nút "Xin thêm phút"
                if (order.status == MockOrderStatus.pendingConfirm || order.status == MockOrderStatus.preparing) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showRequestMinutesDialog(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                      side: BorderSide(color: Colors.orange.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.more_time_rounded, size: 16),
                    label: const Text('Xin thêm phút', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],

                // 2. Nút hành động chính theo trạng thái
                ElevatedButton(
                  onPressed: () {
                    final notifier = ref.read(orderProvider.notifier);
                    if (order.status == MockOrderStatus.pendingConfirm) {
                      notifier.confirmOrder(order.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xác nhận đơn hàng và bắt đầu chuẩn bị món!')),
                      );
                    } else if (order.status == MockOrderStatus.preparing) {
                      notifier.makeReady(order.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã hoàn thành món! Đã gửi thông báo cho khách hàng.')),
                      );
                    } else if (order.status == MockOrderStatus.ready) {
                      notifier.completeOrder(order.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã hoàn thành giao hàng cho khách!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.status == MockOrderStatus.pendingConfirm
                        ? AppColors.primary
                        : (order.status == MockOrderStatus.preparing ? Colors.green : Colors.blue),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  child: Text(
                    order.status == MockOrderStatus.pendingConfirm
                        ? 'Xác nhận đơn'
                        : (order.status == MockOrderStatus.preparing ? 'Xong & Báo khách' : 'Khách đã lấy món'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showRequestMinutesDialog(MockOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.more_time_rounded, color: Colors.orange.shade800, size: 24),
            const SizedBox(width: 8),
            const Text('Xin thêm phút chuẩn bị', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Do đơn hàng tại quán đang quá tải, bạn muốn xin thêm bao nhiêu phút để chuẩn bị đơn ${order.id}?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [5, 10, 15].map((mins) {
              return ElevatedButton(
                onPressed: () {
                  ref.read(orderProvider.notifier).requestExtraMinutes(order.id, mins);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xin thêm $mins phút! Hệ thống đã gửi thông báo đến khách hàng.'),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                child: Text('+$mins phút', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        ],
      ),
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

  Widget _buildTakeawayTab() {
    final categoriesAsync = ref.watch(categoriesFutureProvider);

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
        categoriesAsync.when(
          data: (categories) => _buildCategories(categories),
          loading: () => _buildCategories(const []),
          error: (_, __) => _buildCategories(const []),
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

  // Categories list builder helper
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';

/// Cashier Page — receives orders from staff + creates takeaway orders.
/// Two tabs: "Đơn chờ" (pending from staff) and "Tạo đơn mang đi".
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class CashierPage extends ConsumerStatefulWidget {
  const CashierPage({super.key});
  @override
  ConsumerState<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends ConsumerState<CashierPage>
    with SingleTickerProviderStateMixin {
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
        _OrderItem(
            menuItem: _MenuItem(
                name: 'Phở bò tái',
                price: 45000,
                imageUrl: 'assets/images/pho.jpg'),
            quantity: 2),
        _OrderItem(
            menuItem: _MenuItem(
                name: 'Cà phê sữa đá',
                price: 25000,
                imageUrl: 'assets/images/tra_sua.jpg'),
            quantity: 1),
      ],
      time: '2 phút trước',
      isNew: true,
    ),
    _PendingOrder(
      id: '#002',
      table: 2,
      items: [
        _OrderItem(
            menuItem: _MenuItem(
                name: 'Cơm sườn nướng',
                price: 55000,
                imageUrl: 'assets/images/com.webp'),
            quantity: 1),
        _OrderItem(
            menuItem: _MenuItem(
                name: 'Trà đào cam sả',
                price: 29000,
                imageUrl: 'assets/images/tra_sua.jpg'),
            quantity: 2),
      ],
      time: '5 phút trước',
      isNew: false,
    ),
    _PendingOrder(
      id: '#003',
      table: 8,
      items: [
        _OrderItem(
            menuItem: _MenuItem(
                name: 'Bún bò Huế',
                price: 50000,
                imageUrl: 'assets/images/pho_bo.png'),
            quantity: 3),
      ],
      time: '8 phút trước',
      isNew: false,
    ),
  ];

  static final _menuItems = [
    _MenuItem(
        name: 'Phở bò tái',
        price: 45000,
        imageUrl: 'assets/images/pho.jpg',
        category: 'Phở'),
    _MenuItem(
        name: 'Phở bò viên',
        price: 45000,
        imageUrl: 'assets/images/pho.jpg',
        category: 'Phở'),
    _MenuItem(
        name: 'Phở đặc biệt',
        price: 60000,
        imageUrl: 'assets/images/pho.jpg',
        category: 'Phở'),
    _MenuItem(
        name: 'Cơm sườn nướng',
        price: 55000,
        imageUrl: 'assets/images/com.webp',
        category: 'Cơm'),
    _MenuItem(
        name: 'Cơm gà xối mỡ',
        price: 50000,
        imageUrl: 'assets/images/com.webp',
        category: 'Cơm'),
    _MenuItem(
        name: 'Cơm tấm bì chả',
        price: 45000,
        imageUrl: 'assets/images/com.webp',
        category: 'Cơm'),
    _MenuItem(
        name: 'Bún bò Huế',
        price: 50000,
        imageUrl: 'assets/images/pho_bo.png',
        category: 'Bún'),
    _MenuItem(
        name: 'Bún chả Hà Nội',
        price: 48000,
        imageUrl: 'assets/images/pho_bo.png',
        category: 'Bún'),
    _MenuItem(
        name: 'Trà đào cam sả',
        price: 29000,
        imageUrl: 'assets/images/tra_sua.jpg',
        category: 'Nước'),
    _MenuItem(
        name: 'Cà phê sữa đá',
        price: 25000,
        imageUrl: 'assets/images/tra_sua.jpg',
        category: 'Nước'),
    _MenuItem(
        name: 'Sinh tố bơ',
        price: 35000,
        imageUrl: 'assets/images/tra_sua.jpg',
        category: 'Nước'),
    _MenuItem(
        name: 'Chè khúc bạch',
        price: 25000,
        imageUrl: 'assets/images/tra_sua.jpg',
        category: 'Tráng miệng'),
  ];

  List<_MenuItem> getDynamicMenuItems(BranchDetailModel? detail) {
    if (detail == null || detail.menu == null || detail.menu!.isEmpty) {
      return _menuItems;
    }
    final List<_MenuItem> items = [];
    for (final section in detail.menu!) {
      for (final item in section.items) {
        final priceVal =
            int.tryParse(item.price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        items.add(_MenuItem(
          id: item.menuItemId ?? item.id,
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

  int get _takeawayTotal =>
      _takeawayItems.fold(0, (sum, i) => sum + (i.menuItem.price * i.quantity));
  int get _takeawayCount =>
      _takeawayItems.fold(0, (sum, i) => sum + i.quantity);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      ref
          .read(orderProvider.notifier)
          .fetchBranchOrders(branchId: user?.branchId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addTakeawayItem(_MenuItem item) {
    setState(() {
      final existing =
          _takeawayItems.where((i) => i.menuItem.name == item.name);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _takeawayItems.add(_OrderItem(menuItem: item, quantity: 1));
      }
    });
  }

  void _removeTakeawayItem(_MenuItem item) {
    setState(() {
      final existing =
          _takeawayItems.where((i) => i.menuItem.name == item.name);
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
    final user = ref.watch(currentUserProvider);
    final branchId = user?.branchId;

    BranchDetailModel? branchDetail;
    if (branchId != null && branchId.isNotEmpty) {
      final detailAsync = ref.watch(branchDetailFutureProvider(branchId));
      branchDetail = detailAsync.asData?.value;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingOrdersTab(branchId),
                _buildTakeawayTab(branchDetail),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _tabController.index == 1 && _takeawayItems.isNotEmpty
              ? _buildTakeawayBar(branchId)
              : null,
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = ref.watch(currentUserProvider);
    final rawName = user?.displayName;
    final displayName =
        (rawName == null || rawName.trim().isEmpty) ? 'Quản lý' : rawName;
    final initialChar = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'M';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.primary, width: 1.5),
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
                      icon: const Icon(Icons.swap_horiz_rounded,
                          color: Colors.white, size: 22),
                      onPressed: _confirmLogout,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

  // ─── Pending Orders Tab ────────────────────────────────────────────────
  Widget _buildPendingOrdersTab(String? branchId) {
    final actualCustomerOrders = ref.watch(orderProvider);

    // Mock 1 customer pickup order if empty so the user can review the UI layout
    final customerOrders = actualCustomerOrders.isEmpty
        ? [
            MockOrder(
              id: 'mock_self_pickup_1',
              storeName: 'DineX Restaurant',
              items: const [
                MockOrderItem(
                  name: 'Bún bò Huế đặc biệt',
                  price: 55000,
                  quantity: 2,
                  extras: 'Giò heo, Thịt bò nạm, Chả cua',
                  note: 'Nước dùng đậm đà, không cay',
                ),
                MockOrderItem(
                  name: 'Trà đào cam sả',
                  price: 29000,
                  quantity: 1,
                ),
              ],
              totalAmount: 139000,
              status: MockOrderStatus.pendingConfirm,
              orderTime: DateTime.now().subtract(const Duration(minutes: 8)),
              pickupTime: DateTime.now().add(const Duration(minutes: 15)),
              originalMinutes: 20,
              extraMinutes: 0,
              storeNote: 'Không hành tây, nhiều rau sống ăn kèm.',
              timeline: ['19:24 - Đơn hàng được tạo thành công.'],
              orderNumber: 'ONL2606001',
              paymentStatus: 'Paid',
              orderType: 'Online',
            )
          ]
        : actualCustomerOrders;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderProvider.notifier)
          .fetchBranchOrders(branchId: branchId),
      color: AppColors.primary,
      child: customerOrders.isEmpty && _pendingOrders.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 56, color: AppColors.textTertiary),
                    SizedBox(height: 12),
                    Text('Chưa có đơn chờ',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Phân hệ đơn hàng Self-Pickup từ Khách trực tuyến
                if (customerOrders.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.takeout_dining_rounded,
                          color: AppColors.primary, size: 20),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${customerOrders.length}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...customerOrders
                      .map((order) => _buildCustomerPickupOrderCard(order)),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 20),
                ],

                // 2. Đơn phục vụ tại bàn của Nhân viên gửi lên
                if (_pendingOrders.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'ĐƠN PHỤC VỤ TẠI BÀN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_pendingOrders.length}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _pendingOrders.length,
                    (index) =>
                        _buildPendingOrderCard(_pendingOrders[index], index),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildCustomerPickupOrderCard(MockOrder order) {
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (order.status) {
      case MockOrderStatus.pendingConfirm:
        statusBgColor = const Color(0xFFFEF3C7); // Amber-100
        statusTextColor = const Color(0xFFD97706); // Amber-600
        statusText = 'Chờ xác nhận';
        break;
      case MockOrderStatus.preparing:
        statusBgColor = const Color(0xFFDBEAFE); // Blue-100
        statusTextColor = const Color(0xFF2563EB); // Blue-600
        statusText = 'Đang chuẩn bị';
        break;
      case MockOrderStatus.ready:
        statusBgColor = const Color(0xFFD1FAE5); // Green-100
        statusTextColor = const Color(0xFF059669); // Green-600
        statusText = 'Chờ nhận món';
        break;
      case MockOrderStatus.completed:
        statusBgColor = const Color(0xFFF3F4F6); // Gray-100
        statusTextColor = const Color(0xFF4B5563); // Gray-600
        statusText = 'Đã lấy món';
        break;
      case MockOrderStatus.cancelled:
        statusBgColor = const Color(0xFFFEE2E2); // Red-100
        statusTextColor = const Color(0xFFDC2626); // Red-600
        statusText = 'Đã hủy đơn';
        break;
    }

    final total = order.totalAmount;
    final formattedPickupTime =
        '${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}';

    final isPending = order.status == MockOrderStatus.pendingConfirm;

    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending
                ? AppColors.primary.withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
            width: isPending ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row 1: Tag + Order Number
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.takeout_dining_rounded,
                                    size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'SELF-PICKUP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.orderNumber.isNotEmpty
                                  ? '#${order.orderNumber}'
                                  : '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Payment status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.isPaid
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.isPaid
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_rounded,
                                  size: 10,
                                  color: order.isPaid
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  order.isPaid ? 'Đã TT' : 'Chưa TT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: order.isPaid
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 12),

                      // Time information row
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary),
                              children: [
                                const TextSpan(text: 'Khách hẹn lấy lúc: '),
                                TextSpan(
                                  text: formattedPickupTime,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            order.extraMinutes > 0
                                ? 'Đã thêm +${order.extraMinutes}p'
                                : '${order.originalMinutes}p chuẩn bị',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: order.extraMinutes > 0
                                  ? Colors.red
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),

                      // Customer Note container
                      if (order.storeNote != null &&
                          order.storeNote!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7), // soft amber
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFDE68A), width: 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.notes_rounded,
                                    size: 14, color: Color(0xFFD97706)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.storeNote!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF92400E),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 12),

                      // Items Section Title
                      const Text(
                        'CHI TIẾT MÓN ĂN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Items list preview
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    item.effectiveImageUrl,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 38,
                                      height: 38,
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(Icons.fastfood_outlined,
                                          size: 16,
                                          color: AppColors.textTertiary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (item.extras != null &&
                                          item.extras!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.extras!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatPrice(item.price * item.quantity),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 12),

                      // Footer Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TỔNG CỘNG',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPrice(total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          // Interactive Actions
                          if (order.status != MockOrderStatus.completed &&
                              order.status != MockOrderStatus.cancelled)
                            Row(
                              children: [
                                // Reject button — visible for pendingConfirm and preparing
                                if (order.status ==
                                        MockOrderStatus.pendingConfirm ||
                                    order.status ==
                                        MockOrderStatus.preparing) ...[
                                  SizedBox(
                                    height: 34,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _showRejectOrderBottomSheet(order);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFDC2626),
                                        side: const BorderSide(
                                            color: Color(0xFFFCA5A5),
                                            width: 1.0),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.close_rounded, size: 14),
                                          SizedBox(width: 3),
                                          Text('Từ chối',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],

                                // Add minutes button
                                if (order.status ==
                                        MockOrderStatus.pendingConfirm ||
                                    order.status ==
                                        MockOrderStatus.preparing) ...[
                                  SizedBox(
                                    height: 34,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _showRequestMinutesBottomSheet(order);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange.shade800,
                                        side: BorderSide(
                                            color: Colors.orange.shade300,
                                            width: 1.0),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.more_time_rounded,
                                              size: 14),
                                          SizedBox(width: 3),
                                          Text('+Phút',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],

                                // Primary action button with confirmation
                                SizedBox(
                                  height: 34,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showConfirmActionDialog(order);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: order.status ==
                                              MockOrderStatus.pendingConfirm
                                          ? AppColors.primary
                                          : (order.status ==
                                                  MockOrderStatus.preparing
                                              ? const Color(0xFF059669)
                                              : AppColors.primary),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      order.status ==
                                              MockOrderStatus.pendingConfirm
                                          ? 'Xác nhận'
                                          : (order.status ==
                                                  MockOrderStatus.preparing
                                              ? 'Xong món'
                                              : 'Đã lấy'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
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

  // ─── Reject Order Bottom Sheet ────────────────────────────────────────
  void _showRejectOrderBottomSheet(MockOrder order) {
    final reasonController = TextEditingController();
    String? selectedReason;
    final reasons = [
      'Hết nguyên liệu',
      'Quán quá tải',
      'Sai thông tin đơn hàng',
      'Ngoài giờ phục vụ',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cancel_outlined,
                              color: Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Từ chối đơn hàng',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đơn #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reason label
                    const Text(
                      'Vui lòng chọn lý do từ chối:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick reason chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasons.map((reason) {
                        final isSelected = selectedReason == reason;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedReason = isSelected ? null : reason;
                              if (!isSelected) reasonController.text = reason;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFFDC2626)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Custom reason text field
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      onChanged: (_) =>
                          setModalState(() => selectedReason = null),
                      decoration: InputDecoration(
                        hintText: 'Hoặc nhập lý do khác...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textPlaceholder),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFDC2626), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Hủy',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Vui lòng chọn hoặc nhập lý do từ chối!'),
                                      backgroundColor: Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);
                                ref
                                    .read(orderProvider.notifier)
                                    .cancelOrder(order.id, reason);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Đã từ chối đơn #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}. Khách hàng đã được thông báo.'),
                                    backgroundColor: const Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.cancel_rounded, size: 18),
                              label: const Text('Xác nhận từ chối',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // ─── Request Extra Minutes Bottom Sheet ────────────────────────────────
  void _showRequestMinutesBottomSheet(MockOrder order) {
    final reasonController = TextEditingController();
    int selectedMinutes = 0;
    String? selectedReason;
    final reasons = [
      'Quán đông khách',
      'Nguyên liệu cần chuẩn bị thêm',
      'Đơn hàng phức tạp',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.more_time_rounded,
                              color: Colors.orange.shade800, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xin thêm thời gian',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đơn #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Minutes selection
                    const Text(
                      'Chọn số phút cần thêm:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [5, 10, 15, 20].map((mins) {
                        final isSelected = selectedMinutes == mins;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: mins != 20 ? 8 : 0),
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedMinutes = mins),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '+$mins',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'phút',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white70
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Reason label
                    const Text(
                      'Lý do xin thêm phút:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick reason chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasons.map((reason) {
                        final isSelected = selectedReason == reason;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedReason = isSelected ? null : reason;
                              if (!isSelected) reasonController.text = reason;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange.shade600
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.orange.shade800
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Custom reason text field
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      onChanged: (_) =>
                          setModalState(() => selectedReason = null),
                      decoration: InputDecoration(
                        hintText: 'Hoặc nhập lý do khác...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textPlaceholder),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.orange.shade600, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Hủy',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (selectedMinutes == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Vui lòng chọn số phút cần thêm!'),
                                      backgroundColor: Colors.orange.shade800,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);

                                // Call API — requestExtraMinutes handles pickup time calculation internally
                                ref
                                    .read(orderProvider.notifier)
                                    .requestExtraMinutes(
                                        order.id, selectedMinutes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Đã xin thêm $selectedMinutes phút! Khách hàng đã được thông báo.'),
                                    backgroundColor: Colors.orange.shade800,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                selectedMinutes > 0
                                    ? 'Gửi yêu cầu +$selectedMinutes phút'
                                    : 'Gửi yêu cầu',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // ─── Confirm Action Dialog ─────────────────────────────────────────────
  void _showConfirmActionDialog(MockOrder order) {
    String title;
    String description;
    String confirmText;
    IconData icon;
    Color iconColor;
    Color iconBgColor;
    VoidCallback onConfirm;

    final orderLabel = order.orderNumber.isNotEmpty
        ? '#${order.orderNumber}'
        : '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}';

    switch (order.status) {
      case MockOrderStatus.pendingConfirm:
        title = 'Xác nhận đơn hàng?';
        description =
            'Bạn xác nhận nhận đơn $orderLabel và bắt đầu chuẩn bị món cho khách hàng?';
        confirmText = 'Xác nhận đơn';
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primaryContainer;
        onConfirm = () {
          ref.read(orderProvider.notifier).confirmOrder(order.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận đơn hàng! Bắt đầu chuẩn bị món.'),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        };
        break;
      case MockOrderStatus.preparing:
        title = 'Đã chuẩn bị xong?';
        description =
            'Xác nhận đơn $orderLabel đã hoàn thành chuẩn bị và sẵn sàng để khách đến lấy?';
        confirmText = 'Xong & Báo khách';
        icon = Icons.restaurant_rounded;
        iconColor = const Color(0xFF059669);
        iconBgColor = const Color(0xFFD1FAE5);
        onConfirm = () {
          ref.read(orderProvider.notifier).makeReady(order.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Đã hoàn thành món! Thông báo đã gửi cho khách hàng.'),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        };
        break;
      case MockOrderStatus.ready:
        title = 'Khách đã nhận món?';
        description =
            'Xác nhận khách hàng đã nhận đơn $orderLabel tại quầy thành công?';
        confirmText = 'Đã lấy món';
        icon = Icons.handshake_outlined;
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primaryContainer;
        onConfirm = () {
          ref.read(orderProvider.notifier).completeOrder(order.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hoàn tất! Đơn hàng đã được giao cho khách.'),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        };
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hủy',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(confirmText,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrderCard(_PendingOrder order, int index) {
    final total =
        order.items.fold(0, (sum, i) => sum + (i.menuItem.price * i.quantity));
    final itemCount = order.items.fold(0, (sum, i) => sum + i.quantity);

    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.isNew
                ? AppColors.primary.withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
            width: order.isNew ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: order.isNew
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.08), // Soft Orange
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.table_restaurant_rounded,
                                    size: 13, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'TẠI BÀN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bàn ${order.table}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.id,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textTertiary),
                          ),
                          const Spacer(),
                          if (order.isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'MỚI',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            )
                          else
                            Text(
                              order.time,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 12),

                      // Items Section Title
                      const Text(
                        'CHI TIẾT MÓN ĂN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Items list preview
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFF1F3F5)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      item.menuItem.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFF3F4F6),
                                        child: const Icon(
                                            Icons.fastfood_outlined,
                                            size: 16,
                                            color: AppColors.textTertiary),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.menuItem.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatPrice(
                                      item.menuItem.price * item.quantity),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 12),

                      // Footer Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TỔNG CỘNG ($itemCount MÓN)',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPrice(total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () => _confirmPendingOrder(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Xác nhận & In bill',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
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
              decoration: const BoxDecoration(
                  color: AppColors.successContainer, shape: BoxShape.circle),
              child:
                  const Icon(Icons.print, size: 32, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Đã xác nhận!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Bàn ${order.table} · ${order.id}',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Bill đã gửi đến bếp',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Đóng',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeawayTab(BranchDetailModel? detail) {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    final allItems = getDynamicMenuItems(detail);
    final filteredItems = _getFilteredItems(allItems);

    // Dynamic categories from branch detail menu
    final dynamicCategories = detail?.menu
        ?.map((m) => CategoryModel(id: m.name, name: m.name, imageUrl: ''))
        .toList();

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
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Categories
        categoriesAsync.when(
          data: (categories) {
            final cats = dynamicCategories ?? categories;
            return _buildCategories(cats);
          },
          loading: () => _buildCategories(dynamicCategories ?? const []),
          error: (_, __) => _buildCategories(dynamicCategories ?? const []),
        ),
        const SizedBox(height: 8),
        // Menu list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: filteredItems.length,
            itemBuilder: (_, index) {
              final item = filteredItems[index];
              final qty = _getTakeawayQty(item);
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: qty > 0
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(10)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.imageUrl.startsWith('http')
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                width: 44,
                                height: 44,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fastfood,
                                    color: AppColors.textTertiary),
                              )
                            : Image.asset(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                width: 44,
                                height: 44,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fastfood,
                                    color: AppColors.textTertiary),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(_formatPrice(item.price),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                    if (qty > 0) ...[
                      GestureDetector(
                        onTap: () => _removeTakeawayItem(item),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: AppColors.bgSoft,
                              borderRadius: BorderRadius.circular(7)),
                          child: const Icon(Icons.remove,
                              size: 16, color: AppColors.textPrimary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('$qty',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                    ],
                    GestureDetector(
                      onTap: () => _addTakeawayItem(item),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(7)),
                        child: const Icon(Icons.add,
                            size: 16, color: AppColors.onPrimary),
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
  Widget _buildTakeawayBar(String? branchId) {
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
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  const Text('Bấm để xác nhận và in bill',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _confirmTakeaway(branchId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Xác nhận & In',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTakeaway(String? branchId) async {
    if (branchId == null || branchId.isEmpty) {
      _showSuccessDialog();
      return;
    }

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final itemsPayload = _takeawayItems.map((item) {
        return {
          'menuItemId': item.menuItem.id ?? '',
          'quantity': item.quantity,
          'note': '',
        };
      }).toList();

      await ref.read(orderProvider.notifier).createKioskOrder(
            branchId: branchId,
            items: itemsPayload,
          );

      Navigator.pop(context); // Đóng loading dialog
      _showSuccessDialog();
    } catch (e) {
      Navigator.pop(context); // Đóng loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo đơn hàng: $e')),
      );
    }
  }

  void _showSuccessDialog() {
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
                  color: AppColors.successContainer, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  size: 36, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Đơn mang đi hoàn tất!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('$_takeawayCount món · ${_formatPrice(_takeawayTotal)}',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Bill đã gửi bếp + in cho khách',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
                            color: selected
                                ? AppColors.primary
                                : AppColors.surfaceContainerLowest,
                            child: Icon(
                              Icons.restaurant_menu_rounded,
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
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
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
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
  final String? id;
  final String name;
  final int price;
  final String imageUrl;
  final String category;

  _MenuItem(
      {this.id,
      required this.name,
      required this.price,
      required this.imageUrl,
      this.category = ''});
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

  _PendingOrder(
      {required this.id,
      required this.table,
      required this.items,
      required this.time,
      this.isNew = false});
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/topping_selection_model.dart';
import '../shop/add_to_cart_page.dart';
import '../../../core/utils/receipt_printer_helper.dart';
import '../../widgets/staff/staff_qr_scanner_dialog.dart';
import '../../widgets/staff/order_handover_dialog.dart';

String _parseError(dynamic e) {
  String errorMsg = e.toString().replaceAll('Exception: ', '');
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['detail'] ?? 
                  data['Detail'] ?? 
                  data['message'] ?? 
                  data['error'] ?? 
                  data['title'] ?? 
                  data['Title'];
      if (msg != null) {
        errorMsg = msg.toString();
      }
    }
  }
  return errorMsg;
}

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
  String _selectedOrderFilter = 'All'; // 'All', 'Pickup', 'DineIn'
  String _filterPaymentStatus = 'All'; // 'All', 'Paid', 'Pending'
  String _filterOrderStatus =
      'All'; // 'All', 'PendingConfirm', 'Preparing', 'Ready'
  bool _hasActiveFilter = false;
  bool _isFirstLoading = true;
  bool _showTableMap = false;
  String? _selectedTableForNewOrder;
  DateTime? _selectedHistoryDate;
  Timer? _refreshTimer;

  // Takeaway order
  final List<_OrderItem> _takeawayItems = [];

  // Pending orders from staff
  final List<_PendingOrder> _pendingOrders = [];

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      try {
        await ref
            .read(orderProvider.notifier)
            .fetchBranchOrders(branchId: user?.branchId);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isFirstLoading = false;
        });
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user?.branchId != null && user!.branchId!.isNotEmpty) {
        ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user.branchId);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTakeawayCustomization(_MenuItem menuItem,
      {int? existingIndex}) async {
    final user = ref.read(currentUserProvider);
    final branchId = user?.branchId ?? '';
    if (branchId.isEmpty) return;

    final existingItem =
        existingIndex != null ? _takeawayItems[existingIndex] : null;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToCartPage(
        name: menuItem.name,
        price: _formatPriceFull(menuItem.price),
        imageUrl: menuItem.imageUrl,
        menuItemId: menuItem.id ?? '',
        branchId: branchId,
        icon: Icons.fastfood_rounded,
        initialQuantity: existingItem?.quantity ?? 1,
        initialSelectedToppings: existingItem?.selectedToppings ?? [],
        initialNote: existingItem?.note,
        isEditing: existingItem != null,
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
            _takeawayItems.removeAt(existingIndex);
          } else {
            _takeawayItems[existingIndex] = _OrderItem(
              menuItem: menuItem,
              quantity: q,
              note: note,
              selectedToppings: toppings,
              sizeId: sizeId,
            );
          }
        } else {
          final duplicateIndex = _takeawayItems.indexWhere((item) =>
              item.menuItem.id == menuItem.id &&
              item.note == note &&
              item.sizeId == sizeId &&
              _areToppingsEqual(item.selectedToppings, toppings));

          if (duplicateIndex != -1) {
            _takeawayItems[duplicateIndex].quantity += q;
          } else {
            _takeawayItems.add(_OrderItem(
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

  void _removeTakeawayItem(_MenuItem item) {
    setState(() {
      final index =
          _takeawayItems.lastIndexWhere((i) => i.menuItem.id == item.id);
      if (index != -1) {
        if (_takeawayItems[index].quantity > 1) {
          _takeawayItems[index].quantity--;
        } else {
          _takeawayItems.removeAt(index);
        }
      }
    });
  }

  int _getTakeawayQty(_MenuItem item) {
    return _takeawayItems
        .where((i) => i.menuItem.id == item.id)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  String _formatPrice(int price) {
    return _formatPriceFull(price);
  }

  String _formatPriceFull(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formattedđ';
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

    final showLoading = isBranchLoading || _isFirstLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: showLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : TabBarView(
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
          !showLoading && _tabController.index == 1 && _takeawayItems.isNotEmpty
              ? _buildTakeawayBar(branchId)
              : null,
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = ref.watch(currentUserProvider);
    final actualCustomerOrders = ref.watch(orderProvider);
    final rawName = user?.displayName;
    final displayName =
        (rawName == null || rawName.trim().isEmpty) ? 'Quản lý' : rawName;
    final initialChar = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'M';
    final newPendingCount = _pendingOrders.where((o) => o.isNew).length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary, // Brand Orange
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
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
                // Actions: Notification bell and the exact Admin Logout button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        StaffQrScannerDialog.show(
                          context,
                          onOrderScanned: (orderId) {
                            OrderHandoverDialog.show(context, orderId);
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.qr_code_scanner_rounded,
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
                      tooltip: 'Quét QR Lấy Hàng',
                    ),
                    const SizedBox(width: 8),
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
                  Tab(
                      text:
                          'Đơn chờ (${actualCustomerOrders.length + _pendingOrders.length})'),
                  const Tab(text: 'Tạo đơn'),
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

  // ─── Filter Bottom Sheet ──────────────────────────────────────────────
  void _showFilterBottomSheet() {
    String tempPayment = _filterPaymentStatus;
    String tempOrder = _filterOrderStatus;
    String tempTab = _selectedOrderFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            Widget buildRadioGroup({
              required String title,
              required String groupValue,
              required List<Map<String, String>> options,
              required ValueChanged<String> onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final isSelected = groupValue == opt['id'];
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            onChanged(opt['id']!);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            opt['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title row
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded,
                          size: 22, color: Color(0xFF334155)),
                      const SizedBox(width: 10),
                      const Text(
                        'Bộ lọc nâng cao',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (tempPayment != 'All' || tempOrder != 'All')
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              tempPayment = 'All';
                              tempOrder = 'All';
                              tempTab = 'All';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Xoá lọc',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tab filter
                  buildRadioGroup(
                    title: 'Loại đơn hàng',
                    groupValue: tempTab,
                    options: [
                      {'id': 'All', 'label': 'Tất cả'},
                      {'id': 'Pickup', 'label': 'Khách tự lấy'},
                      {'id': 'DineIn', 'label': 'Tại bàn'},
                    ],
                    onChanged: (val) => tempTab = val,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 20),

                  // Payment status
                  buildRadioGroup(
                    title: 'Trạng thái thanh toán',
                    groupValue: tempPayment,
                    options: [
                      {'id': 'All', 'label': 'Tất cả'},
                      {'id': 'Paid', 'label': 'Đã thanh toán'},
                      {'id': 'Pending', 'label': 'Chưa thanh toán'},
                    ],
                    onChanged: (val) => tempPayment = val,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 20),

                  // Preparation status
                  buildRadioGroup(
                    title: 'Trạng thái chuẩn bị',
                    groupValue: tempOrder,
                    options: [
                      {'id': 'All', 'label': 'Tất cả'},
                      {'id': 'PendingConfirm', 'label': 'Chờ xác nhận'},
                      {'id': 'Preparing', 'label': 'Đang chuẩn bị'},
                      {'id': 'Ready', 'label': 'Sẵn sàng'},
                    ],
                    onChanged: (val) => tempOrder = val,
                  ),
                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterPaymentStatus = tempPayment;
                          _filterOrderStatus = tempOrder;
                          _selectedOrderFilter = tempTab;
                          _hasActiveFilter =
                              tempPayment != 'All' || tempOrder != 'All';
                        });
                        Navigator.pop(ctx2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Áp dụng bộ lọc',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Pending Orders Tab ────────────────────────────────────────────────
  Widget _buildPendingOrdersTab(String? branchId) {
    final customerOrders = ref.watch(orderProvider);

    final selfPickupOrders = customerOrders
        .where((o) => o.orderType == 'Online' || o.orderType == '0')
        .toList();
    final dineInServerOrders = customerOrders
        .where((o) =>
            o.orderType == 'Kiosk' ||
            (o.orderType != 'Online' && o.orderType != '0'))
        .toList();

    Widget buildFilterBar() {
      final filters = [
        {'id': 'All', 'label': 'Tất cả', 'icon': Icons.all_inbox_rounded},
        {
          'id': 'Pickup',
          'label': 'Khách tự lấy',
          'icon': Icons.takeout_dining_rounded
        },
        {
          'id': 'DineIn',
          'label': 'Tại bàn',
          'icon': Icons.table_restaurant_rounded
        },
      ];

      return Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: filters.map((f) {
                  final isSelected = _selectedOrderFilter == f['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOrderFilter = f['id'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              f['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showTableMap = !_showTableMap),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _showTableMap
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: _showTableMap
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1)
                    : null,
              ),
              child: Icon(
                _showTableMap ? Icons.list_alt_rounded : Icons.table_restaurant_rounded,
                size: 20,
                color: _showTableMap
                    ? AppColors.primary
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showFilterBottomSheet(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasActiveFilter
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: _hasActiveFilter
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: _hasActiveFilter
                        ? AppColors.primary
                        : const Color(0xFF64748B),
                  ),
                  if (_hasActiveFilter)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget buildEmptyState(String text) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.45,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // Apply advanced filters to MockOrder lists
    List<MockOrder> applyAdvancedFilter(List<MockOrder> orders) {
      var result = orders;
      if (_filterPaymentStatus != 'All') {
        result = result.where((o) {
          if (_filterPaymentStatus == 'Paid') return o.isPaid;
          if (_filterPaymentStatus == 'Pending') return !o.isPaid;
          return true;
        }).toList();
      }
      if (_filterOrderStatus != 'All') {
        result = result.where((o) {
          switch (_filterOrderStatus) {
            case 'PendingConfirm':
              return o.status == MockOrderStatus.pendingConfirm;
            case 'Preparing':
              return o.status == MockOrderStatus.preparing;
            case 'Ready':
              return o.status == MockOrderStatus.ready;
            default:
              return true;
          }
        }).toList();
      }
      return result;
    }

    final filteredPickup = applyAdvancedFilter(selfPickupOrders);
    final filteredDineIn = applyAdvancedFilter(dineInServerOrders);

    List<Widget> listItems = [];
    listItems.add(buildFilterBar());

    if (_showTableMap) {
      listItems.add(const SizedBox(height: 8));
      listItems.add(_buildTableMapWidget(customerOrders, branchId));
    } else if (_selectedOrderFilter == 'All') {
      // Merge all orders and sort by newest first
      final allOrders = [...filteredPickup, ...filteredDineIn]
        ..sort((a, b) => b.orderTime.compareTo(a.orderTime));
      final totalCount = allOrders.length + _pendingOrders.length;

      if (totalCount == 0) {
        listItems.add(buildEmptyState(_hasActiveFilter
            ? 'Không có đơn nào khớp bộ lọc'
            : 'Chưa có đơn chờ nào'));
      } else {
        listItems.addAll(
            allOrders.map((order) => _buildCustomerPickupOrderCard(order)));
        listItems.addAll(List.generate(
          _pendingOrders.length,
          (index) => _buildPendingOrderCard(_pendingOrders[index], index),
        ));
      }
    } else if (_selectedOrderFilter == 'Pickup') {
      if (filteredPickup.isEmpty) {
        listItems.add(buildEmptyState(_hasActiveFilter
            ? 'Không có đơn nào khớp bộ lọc'
            : 'Chưa có đơn self-pickup nào'));
      } else {
        listItems.addAll(filteredPickup
            .map((order) => _buildCustomerPickupOrderCard(order)));
      }
    } else if (_selectedOrderFilter == 'DineIn') {
      final totalDineInCount = filteredDineIn.length + _pendingOrders.length;
      if (totalDineInCount == 0) {
        listItems.add(buildEmptyState(_hasActiveFilter
            ? 'Không có đơn nào khớp bộ lọc'
            : 'Chưa có đơn tại bàn nào'));
      } else {
        listItems.addAll(filteredDineIn
            .map((order) => _buildCustomerPickupOrderCard(order)));
        listItems.addAll(List.generate(
          _pendingOrders.length,
          (index) => _buildPendingOrderCard(_pendingOrders[index], index),
        ));
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderProvider.notifier)
          .fetchBranchOrders(branchId: branchId),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: listItems,
      ),
    );
  }

  Widget _buildTableMapWidget(List<MockOrder> orders, String? branchId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        final table = index + 1;
        
        final tableOrders = orders.where((o) =>
            o.pagerNumber == '$table' &&
            o.status != MockOrderStatus.completed &&
            o.status != MockOrderStatus.cancelled
        ).toList();
        tableOrders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
        final activeOrder = tableOrders.isNotEmpty ? tableOrders.first : null;
        final isOccupied = activeOrder != null;

        Color bgColor;
        Color borderColor;
        Color textColor;
        IconData icon;
        Color iconColor;
        String subtext;

        if (isOccupied) {
          switch (activeOrder.status) {
            case MockOrderStatus.pendingConfirm:
              bgColor = const Color(0xFFFFFBEB); // amber-50
              borderColor = const Color(0xFFFCD34D); // amber-300
              textColor = const Color(0xFF92400E); // amber-800
              icon = Icons.pending_actions_rounded;
              iconColor = const Color(0xFFD97706);
              subtext = 'Chờ duyệt';
              break;
            case MockOrderStatus.preparing:
              bgColor = const Color(0xFFF0FDF4); // green-50
              borderColor = const Color(0xFF86EFAC); // green-300
              textColor = const Color(0xFF166534); // green-800
              icon = Icons.restaurant_rounded;
              iconColor = const Color(0xFF15803D);
              subtext = 'Đang làm';
              break;
            case MockOrderStatus.ready:
              bgColor = const Color(0xFFEFF6FF); // blue-50
              borderColor = const Color(0xFF93C5FD); // blue-300
              textColor = const Color(0xFF1E40AF); // blue-800
              icon = Icons.check_circle_rounded;
              iconColor = const Color(0xFF1D4ED8);
              subtext = 'Xong món';
              break;
            default:
              bgColor = const Color(0xFFF8FAFC);
              borderColor = const Color(0xFFCBD5E1);
              textColor = const Color(0xFF475569);
              icon = Icons.table_restaurant_rounded;
              iconColor = const Color(0xFF64748B);
              subtext = 'Hoạt động';
          }
        } else {
          bgColor = Colors.white;
          borderColor = const Color(0xFFE2E8F0);
          textColor = const Color(0xFF475569);
          icon = Icons.table_restaurant_outlined;
          iconColor = const Color(0xFF94A3B8);
          subtext = 'Bàn trống';
        }

        return GestureDetector(
          onTap: () {
            if (isOccupied) {
              _showOrderDetailsBottomSheet(activeOrder);
            } else {
              _showEmptyTableDialog(table);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(height: 6),
                Text(
                  'Bàn $table',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isOccupied ? iconColor : const Color(0xFF94A3B8),
                  ),
                ),
                if (isOccupied) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(activeOrder.totalAmount),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetailsBottomSheet(MockOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final currentOrders = ref.watch(orderProvider);
            final updatedOrder = currentOrders.firstWhere(
              (o) => o.id == order.id,
              orElse: () => order,
            );
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: _buildCustomerPickupOrderCard(updatedOrder, isFromTableMap: true),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showEmptyTableDialog(int table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Bàn $table đang trống', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bàn này chưa có khách ngồi hoặc đơn hàng đã hoàn tất thanh toán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedTableForNewOrder = '$table';
              });
              _tabController.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tạo đơn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPickupOrderCard(MockOrder order, {bool isFromTableMap = false}) {
    final isTakeaway = order.orderType == 'Online' || order.orderType == '0';
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending
                ? AppColors.primary.withValues(
                    alpha: 0.35) // Orange accent for pending confirm
                : const Color(0xFFE2E8F0),
            width: isPending ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
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
                              color: order.orderType == 'Kiosk'
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.orderType == 'Kiosk'
                                      ? Icons.table_restaurant_rounded
                                      : Icons.takeout_dining_rounded,
                                  size: 12,
                                  color: order.orderType == 'Kiosk'
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  order.orderType == 'Kiosk'
                                      ? 'KIOSK TẠI BÀN'
                                      : 'SELF-PICKUP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: order.orderType == 'Kiosk'
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF475569),
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
                          if (order.pagerNumber != null &&
                              order.pagerNumber!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                          ],
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
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              final user = ref.read(currentUserProvider);
                              ReceiptPrinterHelper.showBillPreviewModal(
                                context,
                                order,
                                cashierName: user?.fullName ?? 'Thu ngân',
                                onPrintConfirmed: () async {
                                  if (order.status == MockOrderStatus.pendingConfirm) {
                                    try {
                                      await ref.read(orderProvider.notifier).confirmOrder(order.id);
                                      if (user?.branchId != null) {
                                        await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
                                      }
                                    } catch (_) {}
                                  }
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: const Icon(Icons.print_rounded, size: 14, color: Color(0xFFE65100)),
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
                                      color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            order.extraMinutes > 0
                                ? 'Đã thêm +${order.extraMinutes}p'
                                : '${(order.originalMinutes > 180 || order.originalMinutes <= 0) ? 15 : order.originalMinutes}p chuẩn bị',
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

                      // Customer Note container (filtering auto customer info)
                      if (order.storeNote != null &&
                          order.storeNote!.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final noteCleaned = order.storeNote!
                                .replaceAll(RegExp(r'Người mua:\s*[^|]+\|\s*SĐT:\s*[^|]+\|\s*Địa chỉ:\s*.*', caseSensitive: false), '')
                                .trim();
                            if (noteCleaned.isEmpty) return const SizedBox.shrink();

                            final isCreatorInfo = noteCleaned.contains('Yêu cầu bởi:') || noteCleaned.contains('Tạo bởi:');
                            return Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCreatorInfo ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isCreatorInfo ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0), width: 1.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isCreatorInfo) ...[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.notes_rounded,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      noteCleaned,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isCreatorInfo ? FontWeight.w600 : FontWeight.w500,
                                        color: isCreatorInfo ? const Color(0xFF15803D) : const Color(0xFF334155),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 12),

                      // Customer Buyer Info Card on Cashier side
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_pin_circle_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 6),
                                Text(
                                  'Khách hàng: ${order.customerName ?? 'Khách đặt qua App'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ],
                            ),
                            if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SĐT: ${order.customerPhone}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (order.customerAddress != null && order.customerAddress!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Vị trí/Địa chỉ: ${order.customerAddress}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

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
                                      if (item.sizeLabel != null &&
                                          item.sizeLabel!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Size: ${item.sizeLabel}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (item.extras != null &&
                                          item.extras!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.extras!.split('\n').join(', '),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (item.note != null &&
                                          item.note!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.edit_note_rounded,
                                                size: 14,
                                                color: AppColors.primary),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                'Ghi chú: ${item.note}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
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
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPrice(total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                          // Interactive Actions
                          if (order.status != MockOrderStatus.completed &&
                              order.status != MockOrderStatus.cancelled)
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                // Reject button — visible for pendingConfirm and preparing
                                // Reject button — visible for pendingConfirm and preparing (takeaway only)
                                if (isTakeaway &&
                                    (order.status ==
                                            MockOrderStatus.pendingConfirm ||
                                        order.status ==
                                            MockOrderStatus.preparing)) ...[
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
                                        mainAxisSize: MainAxisSize.min,
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
                                ],

                                // Add minutes button (takeaway only)
                                if (isTakeaway &&
                                    (order.status ==
                                            MockOrderStatus.pendingConfirm ||
                                        order.status ==
                                            MockOrderStatus.preparing)) ...[
                                  SizedBox(
                                    height: 34,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _showRequestMinutesBottomSheet(order);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF475569),
                                        side: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                            width: 1.0),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                ],

                                // Primary action button with confirmation
                                // If pendingConfirm and unpaid, show "Xác nhận", "In bill", and "Thanh toán"
                                if (order.status == MockOrderStatus.pendingConfirm && !order.isPaid) ...[
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmActionDialog(order, customAction: 'confirm');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        elevation: 0,
                                      ),
                                      child: const Text('Xác nhận', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final user = ref.read(currentUserProvider);
                                        ReceiptPrinterHelper.showBillPreviewModal(
                                          context,
                                          order,
                                          cashierName: user?.fullName ?? 'Thu ngân',
                                          onPrintConfirmed: () async {
                                            try {
                                              await ref.read(orderProvider.notifier).confirmOrder(order.id);
                                              if (user?.branchId != null) {
                                                await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
                                              }
                                            } catch (_) {}
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.print_rounded, size: 14),
                                      label: const Text('In bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE65100),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmActionDialog(order, customAction: 'pay');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        elevation: 0,
                                      ),
                                      child: const Text('Thanh toán', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ]
                                // If preparing and unpaid, show both "Thanh toán" and "Xong món"
                                else if (order.status == MockOrderStatus.preparing && !order.isPaid) ...[
                                  SizedBox(
                                    height: 34,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _showConfirmActionDialog(order, customAction: 'make_ready');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF059669),
                                        side: const BorderSide(color: Color(0xFF059669), width: 1.0),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                      ),
                                      child: const Text('Xong món', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showConfirmActionDialog(order, customAction: 'pay');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        elevation: 0,
                                      ),
                                      child: const Text('Thanh toán', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ] else ...[
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
                                                : (order.isPaid ? 'Đã lấy' : 'Thanh toán')),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
    final minutesController = TextEditingController(text: '10');
    final reasonController = TextEditingController();
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
            final currentMins = int.tryParse(minutesController.text.trim()) ?? 0;
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

                    // Minutes input field
                    const Text(
                      'Nhập số phút cần xin thêm:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Nhập số phút (Ví dụ: 10, 15, 30...)',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textPlaceholder),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(
                            'phút',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
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
                                final mins =
                                    int.tryParse(minutesController.text.trim()) ?? 0;
                                if (mins <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Vui lòng nhập số phút cần thêm lớn hơn 0!'),
                                      backgroundColor: Colors.orange.shade800,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);

                                ref
                                    .read(orderProvider.notifier)
                                    .requestExtraMinutes(
                                      order.id,
                                      mins,
                                      reason: reasonController.text.trim(),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Đã xin thêm $mins phút! Khách hàng đã được thông báo.'),
                                    backgroundColor: Colors.orange.shade800,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                currentMins > 0
                                    ? 'Gửi yêu cầu +$currentMins phút'
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
  void _showConfirmActionDialog(MockOrder order, {String? customAction}) {
    String title;
    String description;
    String confirmText;
    IconData icon;
    Color iconColor;
    Color iconBgColor;
    Future<void> Function() onConfirm;

    final orderLabel = order.orderNumber.isNotEmpty
        ? '#${order.orderNumber}'
        : '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}';

    final action = customAction ??
        (order.status == MockOrderStatus.pendingConfirm
            ? 'confirm'
            : (order.status == MockOrderStatus.preparing
                ? 'make_ready'
                : 'complete'));

    switch (action) {
      case 'confirm':
        title = 'Xác nhận đơn hàng?';
        description =
            'Bạn xác nhận nhận đơn $orderLabel và bắt đầu chuẩn bị món cho khách hàng?';
        confirmText = 'Xác nhận đơn';
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primaryContainer;
        onConfirm = () async {
          final user = ref.read(currentUserProvider);
          try {
            await ref.read(orderProvider.notifier).confirmOrder(order.id);
            if (user?.branchId != null) {
              await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xác nhận đơn hàng! Bắt đầu chuẩn bị món.'),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi xác nhận đơn: ${_parseError(e)}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        };
        break;
      case 'make_ready':
        final isTakeaway = order.orderType == 'Online' || order.orderType == '0';
        if (isTakeaway) {
          title = 'Đã chuẩn bị xong?';
          description =
              'Xác nhận đơn $orderLabel đã hoàn thành chuẩn bị và sẵn sàng để khách đến lấy?';
          confirmText = 'Xong & Báo khách';
          icon = Icons.restaurant_rounded;
          iconColor = const Color(0xFF059669);
          iconBgColor = const Color(0xFFD1FAE5);
          onConfirm = () async {
            final user = ref.read(currentUserProvider);
            try {
              await ref.read(orderProvider.notifier).makeReady(order.id);
              if (user?.branchId != null) {
                await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hoàn thành món! Thông báo đã gửi cho khách hàng.'),
                    backgroundColor: Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi cập nhật đơn: ${_parseError(e)}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          };
        } else {
          title = 'Hoàn tất phục vụ?';
          description =
              'Xác nhận đơn $orderLabel đã hoàn thành chế biến và phục vụ xong tại bàn?';
          confirmText = 'Hoàn tất đơn';
          icon = Icons.check_circle_rounded;
          iconColor = const Color(0xFF059669);
          iconBgColor = const Color(0xFFD1FAE5);
          onConfirm = () async {
            final user = ref.read(currentUserProvider);
            try {
              await ref.read(orderProvider.notifier).completeOrder(order.id);
              if (user?.branchId != null) {
                await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đơn hàng tại bàn đã được hoàn tất phục vụ thành công!'),
                    backgroundColor: Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi hoàn tất đơn: ${_parseError(e)}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          };
        }
        break;
      case 'pay':
      case 'complete':
        title = order.isPaid ? 'Khách đã nhận món?' : 'Xác nhận thanh toán?';
        description = order.isPaid
            ? 'Xác nhận khách hàng đã nhận đơn $orderLabel tại quầy thành công?'
            : 'Xác nhận khách hàng đã thanh toán đơn $orderLabel tại quầy thành công?';
        confirmText = order.isPaid ? 'Đã lấy món' : 'Thanh toán';
        icon = order.isPaid
            ? Icons.handshake_outlined
            : Icons.monetization_on_rounded;
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primaryContainer;
        onConfirm = () async {
          final user = ref.read(currentUserProvider);
          try {
            await ref.read(orderProvider.notifier).completeOrder(order.id);
            if (user?.branchId != null) {
              await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(order.isPaid
                      ? 'Hoàn tất! Đơn hàng đã được giao cho khách.'
                      : 'Thanh toán thành công! Đơn hàng đã được hoàn tất.'),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi hoàn tất đơn: ${_parseError(e)}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
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
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await onConfirm();
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: order.isNew
                ? AppColors.primary.withValues(alpha: 0.35)
                : const Color(0xFFE2E8F0),
            width: order.isNew ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
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
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.table_restaurant_rounded,
                                    size: 13, color: Color(0xFF475569)),
                                SizedBox(width: 4),
                                Text(
                                  'TẠI BÀN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF475569),
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
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPrice(total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0),
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
              onPressed: () async {
                Navigator.pop(ctx);
                final user = ref.read(currentUserProvider);
                try {
                  if (order.id.isNotEmpty && !order.id.startsWith('mock_')) {
                    await ref.read(orderProvider.notifier).confirmOrder(order.id);
                  }
                  if (user?.branchId != null) {
                    await ref.read(orderProvider.notifier).fetchBranchOrders(branchId: user!.branchId);
                  }
                } catch (e) {
                  print('[CashierPage] Error confirming pending order: $e');
                }
                if (mounted) {
                  setState(() {
                    if (index < _pendingOrders.length) {
                      _pendingOrders.removeAt(index);
                    }
                  });
                }
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
        if (_selectedTableForNewOrder != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_restaurant_rounded, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang tạo đơn cho Bàn $_selectedTableForNewOrder',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTableForNewOrder = null;
                    });
                  },
                  child: const Icon(Icons.cancel_rounded, color: Color(0xFFB45309), size: 18),
                ),
              ],
            ),
          ),
        // Search bar (matching staff page style with border)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
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
        // Menu list (matching staff page style)
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: AppColors.textTertiary),
                      SizedBox(height: 12),
                      Text(
                        'Không tìm thấy món',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (_, index) {
                    final item = filteredItems[index];
                    final qty = _getTakeawayQty(item);
                    return GestureDetector(
                      onTap: () => _openTakeawayCustomization(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: qty > 0
                              ? Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Food image (52x52 matching staff)
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
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.restaurant,
                                                color: AppColors.textTertiary),
                                      )
                                    : Image.asset(
                                        item.imageUrl.isNotEmpty
                                            ? item.imageUrl
                                            : 'assets/images/tra_sua.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.restaurant,
                                                color: AppColors.textTertiary),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Item info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(_formatPriceFull(item.price),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary)),
                                ],
                              ),
                            ),
                            // Quantity controls
                            if (qty > 0) ...[
                              GestureDetector(
                                onTap: () => _removeTakeawayItem(item),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('$qty',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                            // Add button
                            GestureDetector(
                              onTap: () => _openTakeawayCustomization(item),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add,
                                    size: 16, color: AppColors.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Takeaway Bottom Bar (matching staff order bar) ─────────────────────
  Widget _buildTakeawayBar(String? branchId) {
    if (_takeawayItems.isEmpty) return const SizedBox.shrink();

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
            // Price & Detail Info (matching staff style)
            Expanded(
              child: GestureDetector(
                onTap: () => _showTakeawayOrderDetail(),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatPriceFull(_takeawayTotal),
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
                            '$_takeawayCount món',
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
              onPressed: () => _confirmTakeaway(branchId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Xác nhận đơn',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Takeaway Order Detail Bottom Sheet (matching staff page) ────────────
  void _showTakeawayOrderDetail() {
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
                              setState(() => _takeawayItems.clear());
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
                      const Icon(Icons.shopping_bag_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Đơn mang đi · $_takeawayCount món',
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
            // Items list
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _takeawayItems.length,
                itemBuilder: (_, index) {
                  final item = _takeawayItems[index];
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
                                  _openTakeawayCustomization(item.menuItem,
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
                              _formatPriceFull(item.totalPrice),
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
                                        _takeawayItems.removeAt(index);
                                      }
                                    });
                                    if (_takeawayItems.isEmpty) {
                                      Navigator.pop(ctx);
                                    }
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
                          _formatPriceFull(_takeawayTotal),
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
                        final user = ref.read(currentUserProvider);
                        _confirmTakeaway(user?.branchId);
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
          'note': item.note ?? '',
          'toppings': item.selectedToppings
              .map((t) => {'toppingId': t.toppingId, 'quantity': 1})
              .toList(),
        };
      }).toList();

      final user = ref.read(currentUserProvider);
      final cashierName = user?.fullName ?? user?.username ?? 'Thu ngân';
      await ref.read(orderProvider.notifier).createKioskOrder(
            branchId: branchId,
            items: itemsPayload,
            pagerNumber: _selectedTableForNewOrder,
            note: "Tạo bởi Thu ngân: $cashierName${_selectedTableForNewOrder != null ? ' - Bàn $_selectedTableForNewOrder' : ''}",
          );

      setState(() {
        _selectedTableForNewOrder = null;
      });

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

  void _showOrderHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final user = ref.watch(currentUserProvider);
            final cashierName = user?.fullName ?? user?.username ?? 'Thu ngân';
            final allOrders = ref.watch(orderProvider);
            
            // Filter branch orders created by this cashier
            var myOrders = allOrders.where((o) => 
              o.branchId == user?.branchId && 
              o.storeNote?.contains('Tạo bởi Thu ngân: $cashierName') == true
            ).toList();
            
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
                    child: _buildHistoryOrderList(myOrders, cashierName),
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
      required this.time}) : isNew = false;
}

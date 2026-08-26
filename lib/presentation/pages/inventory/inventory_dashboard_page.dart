import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../data/models/analytics_model.dart';
import 'stock_import_page.dart';
import 'recipe_management_page.dart';
import 'inventory_reconciliation_page.dart';
import 'inventory_ledger_page.dart';
import '../../../core/utils/top_notification.dart';

class InventoryDashboardPage extends ConsumerStatefulWidget {
  const InventoryDashboardPage({super.key});

  @override
  ConsumerState<InventoryDashboardPage> createState() =>
      _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends ConsumerState<InventoryDashboardPage>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  String _statusFilter = 'Tất cả';

  bool _wasKeyboardOpen = false;
  Timer? _branchRealtimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch latest stock values when entering the dashboard
    Future.microtask(() {
      ref.read(inventoryProvider.notifier).fetchInventory();
    });
    // Periodic realtime polling every 3 seconds for transfer tickets & branch stock
    _branchRealtimeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        final user = ref.read(authProvider).user;
        final branchId = user?.branchId;
        ref.invalidate(transferTicketsProvider(TransferTicketParams()));
        if (branchId != null) {
          ref.invalidate(transferTicketsProvider(TransferTicketParams(branchId: branchId)));
          ref.invalidate(transferTicketsProvider(TransferTicketParams(branchId: branchId, status: 'Pending')));
          ref.invalidate(transferTicketsProvider(TransferTicketParams(branchId: branchId, status: 'Dispatched')));
        }
        ref.read(inventoryProvider.notifier).fetchInventory();
      }
    });
  }

  @override
  void dispose() {
    _branchRealtimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    try {
      final double bottomInset =
          WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
              ? WidgetsBinding
                  .instance.platformDispatcher.views.first.viewInsets.bottom
              : 0.0;
      final bool isKeyboardOpen = bottomInset > 0;
      if (_wasKeyboardOpen && !isKeyboardOpen) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _wasKeyboardOpen = isKeyboardOpen;
    } catch (_) {}
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _formatStock(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    final filteredIngredients = state.ingredients.where((ing) {
      final matchesSearch =
          ing.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_statusFilter == 'Tất cả') return matchesSearch;
      if (_statusFilter == 'Hết hàng') {
        return matchesSearch &&
            (ing.status == 'Hết hàng' || ing.currentStock <= 0);
      }
      if (_statusFilter == 'Cảnh báo/Kho thấp') {
        return matchesSearch &&
            (ing.status == 'Kho thấp' ||
                ing.status == 'Cảnh báo' ||
                ing.status == 'Sắp hết');
      }
      return matchesSearch;
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.onPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Bảng điều khiển kho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart,
                  color: AppColors.onPrimary),
              tooltip: 'Xin cấp nguyên liệu',
              onPressed: () =>
                  _openRequestTransferBottomSheet(state.ingredients),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: AppColors.onPrimary),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InventoryLedgerPage()),
                );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.restaurant_menu, color: AppColors.onPrimary),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecipeManagementPage()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: !state.isInitialized
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải dữ liệu kho...',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== TOP KPI ROW =====
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _buildKpiCard(
                            title: 'TỔNG GIÁ TRỊ KHO',
                            value: '${_formatPrice(state.totalStockValue)}đ',
                            subtitle: '+1.2%',
                            subtitleColor: AppColors.success,
                            icon: Icons.monetization_on_outlined,
                            iconColor: AppColors.primary,
                            cardColor: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _buildKpiCard(
                            title: 'HẾT HÀNG',
                            value: '${state.outOfStockCount} mặt hàng',
                            subtitle: 'Cần nhập gấp',
                            subtitleColor: AppColors.textSecondary,
                            icon: Icons.error_outline,
                            iconColor: AppColors.error,
                            cardColor: Colors.white,
                            onTap: () {
                              setState(() {
                                _statusFilter = _statusFilter == 'Hết hàng'
                                    ? 'Tất cả'
                                    : 'Hết hàng';
                              });
                            },
                            isActive: _statusFilter == 'Hết hàng',
                          ),
                          const SizedBox(width: 12),
                          _buildKpiCard(
                            title: 'CẢNH BÁO KHO THẤP',
                            value: '${state.lowStockCount} mặt hàng',
                            subtitle: 'Dưới mức an toàn',
                            subtitleColor: AppColors.textSecondary,
                            icon: Icons.notifications_none,
                            iconColor: AppColors.accent,
                            cardColor: Colors.white,
                            onTap: () {
                              setState(() {
                                _statusFilter =
                                    _statusFilter == 'Cảnh báo/Kho thấp'
                                        ? 'Tất cả'
                                        : 'Cảnh báo/Kho thấp';
                              });
                            },
                            isActive: _statusFilter == 'Cảnh báo/Kho thấp',
                          ),
                        ],
                      ),
                    ),

                    // ===== SEARCH AND FILTER BAR =====
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariant),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.search,
                                color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Tìm kiếm nguyên liệu...',
                                  hintStyle: TextStyle(
                                      color: AppColors.textPlaceholder,
                                      fontSize: 14),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===== LIST HEADER =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DANH SÁCH NGUYÊN LIỆU',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_statusFilter != 'Tất cả')
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _statusFilter = 'Tất cả';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Xóa lọc',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.close,
                                        color: AppColors.primary, size: 10),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ===== INGREDIENT LIST =====
                    Expanded(
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          if (filteredIngredients.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 48,
                                        color: AppColors.textPlaceholder),
                                    SizedBox(height: 12),
                                    Text(
                                      'Không tìm thấy nguyên liệu phù hợp',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...filteredIngredients.map((ing) => Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 10),
                                  child: _buildIngredientCard(ing),
                                )),
                          const SizedBox(height: 8),
                          _buildIncomingTransferTicketsWidget(),
                        ],
                      ),
                    ),

                    // ===== BOTTOM ACTION BUTTONS =====
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon:
                                  const Icon(Icons.add_shopping_cart, size: 18),
                              label: const Text('Nhập kho',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const StockImportPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: AppColors.primary, width: 1),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.playlist_add_check,
                                  size: 18),
                              label: const Text('Kiểm kho',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const InventoryReconciliationPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ===== WIDGET BUILDERS =====

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? iconColor : AppColors.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMinStockEditDialog(InventoryIngredient ing) {
    final controller =
        TextEditingController(text: _formatStock(ing.minStockLevel));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Đặt ngưỡng cảnh báo',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nguyên liệu: ${ing.name}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Tồn hiện tại: ${_formatStock(ing.currentStock)} ${ing.unit}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ngưỡng tồn tối thiểu:',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Nhập ngưỡng...',
                  hintStyle: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixText: ing.unit,
                  suffixStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final double? val = double.tryParse(controller.text);
                if (val == null || val < 0) {
                  TopNotification.show(context,
                      message: 'Ngưỡng tối thiểu phải >= 0', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(inventoryProvider.notifier)
                      .updateMinStockLevel(ing.id, val);
                  TopNotification.show(context,
                      message:
                          'Đã cập nhật ngưỡng cảnh báo của ${ing.name} thành ${_formatStock(val)} ${ing.unit}');
                } catch (e) {
                  TopNotification.show(context,
                      message: 'Cập nhật thất bại: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngredientCard(InventoryIngredient ing) {
    IconData itemIcon = Icons.inventory_2;
    if (ing.name.contains('Mì')) {
      itemIcon = Icons.restaurant;
    } else if (ing.name.contains('Thịt'))
      itemIcon = Icons.kebab_dining;
    else if (ing.name.contains('Hành'))
      itemIcon = Icons.eco;
    else if (ing.name.contains('Tôm'))
      itemIcon = Icons.set_meal;
    else if (ing.name.contains('Dầu')) itemIcon = Icons.opacity;

    return GestureDetector(
      onTap: () => _showMinStockEditDialog(ing),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ingredient icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(itemIcon, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            // Info and progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ing.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ing.ratio,
                            minHeight: 5,
                            backgroundColor: AppColors.outlineVariant,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(ing.statusColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ing.percentage}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ing.statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tồn: ${_formatStock(ing.currentStock)} / ${_formatStock(ing.minStockLevel)} ${ing.unit}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ing.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: ing.statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                ing.status,
                style: TextStyle(
                  color: ing.statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingTransferTicketsWidget() {
    final user = ref.watch(authProvider).user;
    final branchId = user?.branchId;
    final ticketsAsync = ref.watch(transferTicketsProvider(
        TransferTicketParams(branchId: branchId)));

    return ticketsAsync.when(
      data: (allTickets) {
        final activeTickets = allTickets
            .where((t) => t.status == 'Dispatched' || t.status == 'Pending')
            .toList();

        if (activeTickets.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Logistics & Bếp trung tâm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${activeTickets.length} phiếu đang chạy',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          ref.invalidate(transferTicketsProvider(
                              TransferTicketParams(branchId: branchId)));
                        },
                        child: const Icon(Icons.refresh,
                            size: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...activeTickets.asMap().entries.map((entry) {
                final index = entry.key;
                final t = entry.value;
                final isDispatched = t.status == 'Dispatched';

                Color statusColor = isDispatched ? AppColors.primary : AppColors.accent;
                String statusText = isDispatched ? 'Đang vận chuyển' : 'Chờ duyệt';

                final srcName = t.sourceBranchName ?? 'Bếp trung tâm';
                final dstName = t.targetBranchName.isNotEmpty ? t.targetBranchName : 'Chi nhánh';

                return Column(
                  children: [
                    if (index > 0) const Divider(color: AppColors.divider, height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                t.ticketCode.length > 20
                                    ? '#${t.ticketCode.substring(0, 18)}...'
                                    : '#${t.ticketCode}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$srcName ➔ $dstName',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${t.quantity.toStringAsFixed(1)}${t.unit} ${t.ingredientName}${t.note != null && t.note!.isNotEmpty
                                        ? ' (${t.note})'
                                        : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              isDispatched
                                  ? 'Đang vận chuyển'
                                  : 'Chờ tổng quản duyệt',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        if (isDispatched) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _confirmTicketDelivery(t);
                                },
                                icon: const Icon(Icons.check_circle_rounded,
                                    size: 16),
                                label: const Text(
                                  'Xác nhận đã nhận',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  elevation: 2,
                                  shadowColor: const Color(0xFF10B981)
                                      .withValues(alpha: 0.35),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _confirmTicketDelivery(TransferTicketModel t) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );

    ref
        .read(analyticsRepositoryProvider)
        .confirmDelivery(ticketId: t.id)
        .then((_) {
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
      } catch (_) {}
      final user = ref.read(authProvider).user;
      final branchId = user?.branchId;
      ref.read(inventoryProvider.notifier).fetchInventory();
      ref.invalidate(
          transferTicketsProvider(TransferTicketParams(branchId: branchId)));
      ref.invalidate(transferTicketsProvider(
          TransferTicketParams(branchId: branchId, status: 'Dispatched')));
      ref.invalidate(transferTicketsProvider(TransferTicketParams()));
      ref.invalidate(chainInventoryMatrixProvider);
      TopNotification.show(
        context,
        message:
            'Đã nhận ${t.quantity.toStringAsFixed(1)}${t.unit} ${t.ingredientName} vào kho thành công!',
        isError: false,
      );
    }).catchError((err) {
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      TopNotification.show(context,
          message: 'Lỗi xác nhận nhận hàng: $err', isError: true);
    });
  }

  void _openRequestTransferBottomSheet(List<InventoryIngredient> ingredients) {
    if (ingredients.isEmpty) {
      TopNotification.show(context,
          message: 'Chưa có danh mục nguyên liệu để gửi yêu cầu',
          isError: true);
      return;
    }

    InventoryIngredient selectedIng = ingredients.first;
    final qtyController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Xin cấp nguyên liệu',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text('Chọn nguyên liệu thiếu *',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<InventoryIngredient>(
                        value: selectedIng,
                        isExpanded: true,
                        items: ingredients.map((ing) {
                          return DropdownMenuItem<InventoryIngredient>(
                            value: ing,
                            child: Text(
                                '${ing.name} (Tồn hiện tại: ${ing.currentStock}${ing.unit})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedIng = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Số lượng xin cấp (${selectedIng.unit}) *',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Nhập số lượng cần...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      suffixText: selectedIng.unit,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ghi chú / Lý do (tùy chọn)',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Khách đông đột biến cuối tuần...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final qty =
                            double.tryParse(qtyController.text.trim()) ?? 0;
                        if (qty <= 0) {
                          TopNotification.show(context,
                              message: 'Vui lòng nhập số lượng hợp lệ',
                              isError: true);
                          return;
                        }

                        final user = ref.read(authProvider).user;
                        final targetBranchId = user?.branchId ?? '';

                        if (targetBranchId.isEmpty) {
                          TopNotification.show(context,
                              message:
                                  'Không tìm thấy thông tin chi nhánh hiện tại',
                              isError: true);
                          return;
                        }

                        final rootNav = Navigator.of(context, rootNavigator: true);
                        Navigator.pop(ctx); // Close sheet
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        );

                        try {
                          await ref
                              .read(analyticsRepositoryProvider)
                              .createTransferRequest(
                                ingredientId: selectedIng.id,
                                targetBranchId: targetBranchId,
                                quantity: qty,
                                note: noteController.text.trim().isNotEmpty
                                    ? noteController.text.trim()
                                    : null,
                              );
                          try {
                            rootNav.pop(); // Close loading dialog safely
                          } catch (_) {}
                          if (context.mounted) {
                            TopNotification.show(
                              context,
                              message:
                                  'Đã gửi yêu cầu cấp $qty${selectedIng.unit} ${selectedIng.name} thành công. Vui lòng chờ Tổng quản trị duyệt!',
                              isError: false,
                            );
                          }
                          ref.invalidate(transferTicketsProvider(
                              TransferTicketParams()));
                          ref.invalidate(transferTicketsProvider(
                              TransferTicketParams(branchId: targetBranchId)));
                          ref.invalidate(transferTicketsProvider(
                              TransferTicketParams(branchId: targetBranchId, status: 'Pending')));
                          ref.invalidate(transferTicketsProvider(
                              TransferTicketParams(branchId: targetBranchId, status: 'Dispatched')));
                        } catch (e) {
                          try {
                            rootNav.pop();
                          } catch (_) {}
                          if (context.mounted) {
                            TopNotification.show(context,
                                message: 'Lỗi gửi yêu cầu: $e', isError: true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Gửi Yêu Cầu Cấp Hàng',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
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
}

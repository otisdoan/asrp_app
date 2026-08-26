import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../providers/order_provider.dart';

class AllTransactionsPage extends ConsumerStatefulWidget {
  final String? initialBranchId;

  const AllTransactionsPage({
    super.key,
    this.initialBranchId,
  });

  @override
  ConsumerState<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage>
    with SingleTickerProviderStateMixin {
  // ── Filters ──
  int _selectedTimeIndex = 0; // 0=Hôm nay, 1=Hôm qua, 2=Tuần này, 3=Tháng này, 4=Tất cả
  int _selectedStatusIndex = 0; // 0=Tất cả, 1=Hoàn thành, 2=Đang xử lý, 3=Đã hủy
  String _searchQuery = '';
  int? _expandedIndex;
  late String _branchId;

  late final TabController _statusTabController;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  static const _timeLabels = ['Hôm nay', 'Hôm qua', 'Tuần này', 'Tháng này', 'Tất cả'];
  static const _statusLabels = ['Tất cả', 'Hoàn thành', 'Đang xử lý', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialBranchId ?? '';
    _statusTabController = TabController(length: _statusLabels.length, vsync: this);
    _statusTabController.addListener(() {
      if (!_statusTabController.indexIsChanging) {
        setState(() => _selectedStatusIndex = _statusTabController.index);
      }
    });
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(branchOrdersProvider(_branchId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── SliverAppBar ──
          SliverAppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            pinned: true,
            floating: true,
            snap: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Lịch sử giao dịch',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                tooltip: 'Tải lại',
                onPressed: () => ref.invalidate(branchOrdersProvider(_branchId)),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: AppColors.primary,
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: _timeLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final isSelected = _selectedTimeIndex == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTimeIndex = i);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _timeLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Search + Status Tabs ──
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Tìm mã đơn, tên món, SĐT khách...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  // Status TabBar
                  TabBar(
                    controller: _statusTabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: _statusLabels.map((label) => Tab(height: 36, text: label)).toList(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Data content ──
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                ),
                error: (err, stack) => _buildErrorState(),
                data: (orders) {
                  final filtered = _filterOrders(orders);
                  final totalSum = filtered.fold<int>(0, (sum, o) => sum + o.totalAmount);

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(branchOrdersProvider(_branchId)),
                    child: Column(
                      children: [
                        // ── Summary bar ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFFF5F5F7),
                          child: Row(
                            children: [
                              Text(
                                '${filtered.length} giao dịch',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                FormatUtils.formatCurrency(totalSum),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),

                        // ── Transactions list ──
                        Expanded(
                          child: filtered.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, index) => _buildTransactionCard(filtered[index], index),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTION CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionCard(MockOrder order, int index) {
    // ── Derive display values ──
    final String orderCode;
    if (order.orderNumber.isNotEmpty) {
      // Shorten long order numbers: take last 6 characters
      final num = order.orderNumber;
      orderCode = num.length > 8 ? '#${num.substring(num.length - 6)}' : '#$num';
    } else {
      orderCode = '#${order.id.substring(0, 6).toUpperCase()}';
    }

    final timeStr = DateFormat('HH:mm').format(order.orderTime);
    final dateStr = DateFormat('dd/MM/yyyy').format(order.orderTime);
    final isExpanded = _expandedIndex == index;

    // Status styling
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (order.status) {
      case MockOrderStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'Đã hủy';
        statusIcon = Icons.cancel_rounded;
      case MockOrderStatus.completed:
        statusColor = AppColors.success;
        statusText = 'Hoàn thành';
        statusIcon = Icons.check_circle_rounded;
      default:
        statusColor = const Color(0xFFED6C02);
        statusText = 'Đang xử lý';
        statusIcon = Icons.schedule_rounded;
    }

    // Order source
    String sourceLabel;
    IconData sourceIcon;
    if (order.orderType == 'Kiosk' || order.orderType == '1') {
      sourceLabel = 'Kiosk';
      sourceIcon = Icons.tablet_mac_rounded;
    } else if (order.orderType == 'InStore' || order.orderType == '2') {
      sourceLabel = 'POS';
      sourceIcon = Icons.point_of_sale_rounded;
    } else {
      sourceLabel = 'Online';
      sourceIcon = Icons.language_rounded;
    }

    // Payment method
    String paymentLabel = 'Tiền mặt';
    if (order.payments.isNotEmpty) {
      paymentLabel = order.payments.first.method;
    } else if (order.isQrPayment) {
      paymentLabel = 'PayOS';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>(order.id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (v) => setState(() => _expandedIndex = v ? index : null),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: EdgeInsets.zero,

          // ── Leading status icon ──
          leading: Icon(statusIcon, color: statusColor, size: 22),

          // ── Title row: order code + amount ──
          title: Row(
            children: [
              Text(
                orderCode,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
              const Spacer(),
              Text(
                FormatUtils.formatCurrency(order.totalAmount),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),

          // ── Subtitle: time + items preview ──
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$timeStr · $dateStr',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 6),
                  Icon(sourceIcon, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 2),
                  Text(
                    sourceLabel,
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),

          // ── Expanded detail section ──
          children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items list
                  ...order.items.map(_buildItemRow),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 8),

                  // Info rows
                  _infoRow('Thanh toán', paymentLabel),
                  if (order.storeName.isNotEmpty) _infoRow('Chi nhánh', order.storeName),
                  if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                    _infoRow('Khách hàng', '${order.customerName ?? 'Khách'} · ${order.customerPhone}'),
                  const SizedBox(height: 6),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text(
                        FormatUtils.formatCurrency(order.totalAmount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(MockOrderItem item) {
    final total = item.price * item.quantity;
    final hasToppings = item.extras != null && item.extras!.trim().isNotEmpty;
    final hasNote = item.note != null && item.note!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.quantity}x ${item.name}${item.sizeLabel != null && item.sizeLabel!.isNotEmpty ? ' (${item.sizeLabel})' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                FormatUtils.formatCurrency(total),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (hasToppings)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                item.extras!.split('\n').where((t) => t.trim().isNotEmpty).map((t) => '+ $t').join('\n'),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ),
          if (hasNote)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                '📝 ${item.note}',
                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.tertiary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  List<MockOrder> _filterOrders(List<MockOrder> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return orders.where((order) {
      // 1. Status
      switch (_selectedStatusIndex) {
        case 1: // Hoàn thành
          if (order.status != MockOrderStatus.completed) return false;
        case 2: // Đang xử lý
          if (order.status == MockOrderStatus.completed || order.status == MockOrderStatus.cancelled) return false;
        case 3: // Đã hủy
          if (order.status != MockOrderStatus.cancelled) return false;
      }

      // 2. Time
      final orderDate = DateTime(order.orderTime.year, order.orderTime.month, order.orderTime.day);
      switch (_selectedTimeIndex) {
        case 0: // Hôm nay
          if (orderDate != today) return false;
        case 1: // Hôm qua
          if (orderDate != today.subtract(const Duration(days: 1))) return false;
        case 2: // Tuần này
          final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
          if (orderDate.isBefore(startOfWeek)) return false;
        case 3: // Tháng này
          if (orderDate.isBefore(DateTime(now.year, now.month, 1))) return false;
        // case 4: Tất cả - no filter
      }

      // 3. Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final code = order.orderNumber.toLowerCase();
        final matchCode = code.contains(q) || order.id.toLowerCase().contains(q);
        final matchItem = order.items.any((item) => item.name.toLowerCase().contains(q));
        final matchCustomer = (order.customerName ?? '').toLowerCase().contains(q) ||
            (order.customerPhone ?? '').contains(q);
        if (!matchCode && !matchItem && !matchCustomer) return false;
      }

      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY & ERROR STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 320,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Không có giao dịch',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Thử chọn mốc thời gian khác hoặc xóa bộ lọc',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Không thể tải giao dịch',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => ref.invalidate(branchOrdersProvider(_branchId)),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

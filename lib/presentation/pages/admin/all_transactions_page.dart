import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/branch_provider.dart';

class AllTransactionsPage extends ConsumerStatefulWidget {
  final String? initialBranchId;

  const AllTransactionsPage({
    super.key,
    this.initialBranchId,
  });

  @override
  ConsumerState<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage> {
  String _selectedStatusFilter = 'Tất cả';
  String _selectedTimeFilter = 'Hôm nay';
  DateTimeRange? _customDateRange;
  String _searchQuery = '';
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesFutureProvider);
    final fallbackBranchId = branchesAsync.asData?.value.firstOrNull?.id ?? '';
    final activeBranchId = (widget.initialBranchId != null && widget.initialBranchId!.isNotEmpty)
        ? widget.initialBranchId!
        : fallbackBranchId;

    final ordersAsync = ref.watch(branchOrdersProvider(activeBranchId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tất cả giao dịch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              if (activeBranchId.isNotEmpty) {
                ref.invalidate(branchOrdersProvider(activeBranchId));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search & Date Filter Bar
          _buildTopFilterHeader(),

          // 2. Status & Source Filter Chips
          _buildFilterChips(),

          // 3. Transactions Content List
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync_problem_rounded, color: AppColors.primary, size: 52),
                      const SizedBox(height: 14),
                      const Text(
                        'Không thể lấy danh sách giao dịch từ máy chủ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Phiên đăng nhập có thể đã hết hạn hoặc bạn không có quyền truy cập chi nhánh này.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => ref.invalidate(branchOrdersProvider(activeBranchId)),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Tải lại giao dịch', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (orders) {
                final filtered = _filterOrders(orders);
                final totalSum = filtered.fold<int>(0, (sum, o) => sum + o.totalAmount);

                return Column(
                  children: [
                    // Summary Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hiển thị ${filtered.length} giao dịch',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Tổng: ${FormatUtils.formatCurrency(totalSum)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List View
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không tìm thấy giao dịch phù hợp',
                                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final order = filtered[index];
                                return _buildTransactionCard(order, index);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.surfaceContainerLowest,
      child: Column(
        children: [
          // Search Input
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã đơn (HD-...), tên món...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textPlaceholder),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Time Filter Segment Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeFilterChip('Hôm nay'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Hôm qua'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Tuần này'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Tháng này'),
                const SizedBox(width: 8),
                _buildTimeFilterChip('Tất cả'),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(Icons.calendar_month_rounded, size: 14, color: _selectedTimeFilter == 'Tùy chọn' ? AppColors.primary : AppColors.textSecondary),
                  label: Text(
                    _customDateRange == null
                        ? 'Tùy chọn'
                        : '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedTimeFilter == 'Tùy chọn' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedTimeFilter == 'Tùy chọn' ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  backgroundColor: _selectedTimeFilter == 'Tùy chọn' ? const Color(0xFFFFF4F0) : const Color(0xFFF3F4F6),
                  side: BorderSide(
                    color: _selectedTimeFilter == 'Tùy chọn' ? AppColors.primary : const Color(0xFFE5E7EB),
                  ),
                  onPressed: _pickDateRange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(String label) {
    final isSelected = _selectedTimeFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF3F4F6),
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTimeFilter = label;
            _customDateRange = null;
          });
        }
      },
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surfaceContainerLowest,
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Trạng thái: ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('Tất cả'),
                      const SizedBox(width: 6),
                      _buildStatusChip('Hoàn thành'),
                      const SizedBox(width: 6),
                      _buildStatusChip('Đang xử lý'),
                      const SizedBox(width: 6),
                      _buildStatusChip('Đã hủy'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusLabel) {
    final isSelected = _selectedStatusFilter == statusLabel;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = statusLabel),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          statusLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedTimeFilter = 'Tùy chọn';
      });
    }
  }

  List<MockOrder> _filterOrders(List<MockOrder> orders) {
    final now = DateTime.now();

    return orders.where((order) {
      // 1. Status Filter
      if (_selectedStatusFilter == 'Hoàn thành' && order.status != MockOrderStatus.completed) {
        return false;
      }
      if (_selectedStatusFilter == 'Đang xử lý' && (order.status == MockOrderStatus.completed || order.status == MockOrderStatus.cancelled)) {
        return false;
      }
      if (_selectedStatusFilter == 'Đã hủy' && order.status != MockOrderStatus.cancelled) {
        return false;
      }

      // 2. Time Filter
      final orderDate = DateTime(order.orderTime.year, order.orderTime.month, order.orderTime.day);
      final today = DateTime(now.year, now.month, now.day);

      if (_selectedTimeFilter == 'Hôm nay') {
        if (orderDate != today) return false;
      } else if (_selectedTimeFilter == 'Hôm qua') {
        final yesterday = today.subtract(const Duration(days: 1));
        if (orderDate != yesterday) return false;
      } else if (_selectedTimeFilter == 'Tuần này') {
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        if (orderDate.isBefore(startOfWeek)) return false;
      } else if (_selectedTimeFilter == 'Tháng này') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        if (orderDate.isBefore(startOfMonth)) return false;
      } else if (_selectedTimeFilter == 'Tùy chọn' && _customDateRange != null) {
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        if (order.orderTime.isBefore(start) || order.orderTime.isAfter(end)) return false;
      }

      // 3. Search Query
      if (_searchQuery.isNotEmpty) {
        final orderCode = (order.orderNumber.isNotEmpty ? 'HD-${order.orderNumber}' : 'HD-${order.id}').toLowerCase();
        final matchCode = orderCode.contains(_searchQuery);
        final matchItems = order.items.any((item) => item.name.toLowerCase().contains(_searchQuery));
        if (!matchCode && !matchItems) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildTransactionCard(MockOrder order, int index) {
    final orderCode = order.orderNumber.isNotEmpty ? 'HD-${order.orderNumber}' : 'HD-${order.id.substring(0, 4).toUpperCase()}';
    final timeFormatted = DateFormat('HH:mm · dd/MM/yyyy').format(order.orderTime);
    final isExpanded = _expandedIndex == index;

    IconData statusIcon = Icons.check_circle_rounded;
    Color statusColor = AppColors.success;
    Color statusBgColor = AppColors.successContainer;
    String statusText = 'Hoàn thành';

    if (order.status == MockOrderStatus.cancelled) {
      statusIcon = Icons.cancel_rounded;
      statusColor = AppColors.error;
      statusBgColor = AppColors.badgeHotBg;
      statusText = 'Đã hủy';
    } else if (order.status != MockOrderStatus.completed) {
      statusIcon = Icons.hourglass_top_rounded;
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withValues(alpha: 0.15);
      statusText = 'Đang xử lý';
    }

    String orderSourceText = 'Đặt trực tuyến';
    if (order.orderType == 'Kiosk' || order.orderType == '1') {
      orderSourceText = 'Máy Kiosk';
    } else if (order.orderType == 'InStore' || order.orderType == '2') {
      orderSourceText = 'Ăn tại chỗ / POS';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>(order.id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _expandedIndex = expanded ? index : null);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  orderCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                FormatUtils.formatCurrency(order.totalAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  timeFormatted,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chi tiết món ăn & Topping:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          orderSourceText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Order items breakdown
                  ...order.items.map((item) => _buildOrderItemDetailWidget(item)),

                  const SizedBox(height: 10),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),

                  // Payment method and total breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phương thức thanh toán:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        order.payments.isNotEmpty ? order.payments.first.method : 'Tiền mặt',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền đơn hàng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
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

  Widget _buildOrderItemDetailWidget(MockOrderItem item) {
    final hasToppings = item.extras != null && item.extras!.trim().isNotEmpty;
    final hasNote = item.note != null && item.note!.trim().isNotEmpty;
    final itemTotal = item.price * item.quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item.name} x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                FormatUtils.formatCurrency(itemTotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (item.sizeLabel != null && item.sizeLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Size: ${item.sizeLabel}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          if (hasToppings) ...[
            const SizedBox(height: 6),
            const Text(
              'Topping chọn kèm:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            ...item.extras!.split('\n').where((t) => t.trim().isNotEmpty).map((toppingLine) {
              return Padding(
                padding: const EdgeInsets.only(left: 6.0, top: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        toppingLine,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (hasNote) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(
                'Ghi chú: ${item.note}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.tertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/order_provider.dart';
import 'cancel_success_page.dart';
import 'order_detail_page.dart';
import 'order_review_page.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../core/utils/top_notification.dart';

/// Order Status Page — shows orders filtered by status.
/// Navigated to when tapping a status category on the Orders page.
/// Follows RULE: UI-only, uses AppColors, responsive.
class OrderStatusPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const OrderStatusPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends ConsumerState<OrderStatusPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Tất cả', 'Chờ thanh toán', 'Chờ xác nhận', 'Chờ nhận đơn', 'Chờ đánh giá', 'Trả hàng'];

  // Removed unused static const _suggestedStores


  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).fetchMyOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Icon(Icons.search, size: 20, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm kiếm đơn hàng của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        titleSpacing: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 0. Tất cả
          OrderTabContent(orders: allOrders),
          // 1. Chờ thanh toán
          OrderTabContent(
              orders: allOrders
                  .where((o) =>
                      o.status == MockOrderStatus.pendingConfirm &&
                      !o.isPaid &&
                      o.isQrPayment)
                  .toList()),
          // 2. Chờ xác nhận
          OrderTabContent(
              orders: allOrders
                  .where((o) =>
                      o.status == MockOrderStatus.pendingConfirm &&
                      (o.isPaid || !o.isQrPayment))
                  .toList()),
          // 3. Chờ nhận đơn (preparing, ready)
          OrderTabContent(
              orders: allOrders
                  .where((o) =>
                      o.status == MockOrderStatus.preparing ||
                      o.status == MockOrderStatus.ready)
                  .toList()),
          // 4. Chờ đánh giá (completed)
          OrderTabContent(
              orders: allOrders
                  .where((o) => o.status == MockOrderStatus.completed)
                  .toList()),
          // 5. Trả hàng (Cancelled)
          OrderTabContent(
              orders: allOrders
                  .where((o) => o.status == MockOrderStatus.cancelled)
                  .toList()),
        ],
      ),
    );
  }
}

/// Paginated tab content for Order Status Page.
class OrderTabContent extends ConsumerStatefulWidget {
  final List<MockOrder> orders;

  const OrderTabContent({super.key, required this.orders});

  @override
  ConsumerState<OrderTabContent> createState() => _OrderTabContentState();
}

class _OrderTabContentState extends ConsumerState<OrderTabContent> {
  final ScrollController _scrollController = ScrollController();
  int _displayCount = 10;
  bool _isLoadingMore = false;

  // Mock suggested stores
  static const _suggestedStores = [
    {
      'name': 'Hiên Coffee - 32 Hồ Văn Huê',
      'rating': 4.7,
      'distance': '0.3km',
      'time': '15 phút',
      'badge': 'Mã giảm 11%',
      'icon': Icons.coffee,
    },
    {
      'name': 'Trạm Cà Phê - 77 Nguyễn Diêu',
      'rating': 5.0,
      'distance': '0.3km',
      'time': '22 phút',
      'badge': 'Mã giảm 11%',
      'icon': Icons.local_cafe,
    },
    {
      'name': 'Cơm Tấm Sài Gòn - A Vũ',
      'rating': 4.8,
      'distance': '1.2km',
      'time': '30 phút',
      'badge': 'Mã giảm 15%',
      'icon': Icons.rice_bowl,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 150) {
      _loadMore();
    }
  }

  void _loadMore() {
    final totalCount = widget.orders.length;
    if (_isLoadingMore || _displayCount >= totalCount) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _displayCount = (_displayCount + 10).clamp(0, totalCount);
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewedOrderIds = ref.watch(reviewedOrdersProvider);
    final visibleOrders = widget.orders.take(_displayCount).toList();
    final hasMore = _displayCount < widget.orders.length;

    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).fetchMyOrders(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            if (visibleOrders.isNotEmpty) ...[
              ...visibleOrders.map((o) => _buildOrderCard(o, isReviewed: reviewedOrderIds.contains(o.id))),
              const SizedBox(height: 12),
            ] else ...[
              // Màn hình rỗng
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        size: 24, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Không có đơn hàng liên quan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bắt đầu khám phá và tìm sản phẩm bạn yêu thích',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],

            // Loading / end of list indicators
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang tải thêm đơn hàng...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!hasMore && widget.orders.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Đã hiển thị tất cả đơn hàng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            // Luôn luôn hiển thị gợi ý cửa hàng ở phía dưới danh sách
            _buildSuggestedStores(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(MockOrder order, {required bool isReviewed}) {
    Color statusTextColor;
    String statusText;

    switch (order.status) {
      case MockOrderStatus.pendingConfirm:
        if (!order.isPaid && order.isQrPayment) {
          statusTextColor = Colors.orange.shade800;
          statusText = 'Chờ thanh toán';
        } else {
          statusTextColor = Colors.blue.shade700;
          statusText = 'Chờ xác nhận';
        }
        break;
      case MockOrderStatus.preparing:
        statusTextColor = AppColors.primary;
        statusText = 'Đang chuẩn bị';
        break;
      case MockOrderStatus.ready:
        statusTextColor = Colors.green.shade700;
        statusText = 'Chờ nhận món';
        break;
      case MockOrderStatus.completed:
        statusTextColor = Colors.grey.shade700;
        statusText = 'Đã lấy món';
        break;
      case MockOrderStatus.cancelled:
        statusTextColor = Colors.red.shade700;
        statusText = 'Đã hủy đơn';
        break;
    }

    final pickupTimeStr =
        '${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}';
    final hasAlert = order.hasNotification;

    return GestureDetector(
      onTap: () {
        if (order.hasNotification) {
          ref.read(orderProvider.notifier).clearNotification(order.id);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: order.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hasAlert ? AppColors.primary : AppColors.outlineVariant,
            width: hasAlert ? 1.5 : 1.0,
          ),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Store Name + Chevron + Tag + Status text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 16, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order.storeName.split(' - ')[0], // Tên ngắn gọn
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.textTertiary),
                        if (order.discountPercentage > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE8E7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Giảm ${order.discountPercentage}%',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. ETA Shipping Bar
              Builder(
                builder: (context) {
                  String shippingText = '';
                  Color shippingColor = AppColors.primary;
                  IconData shippingIcon = Icons.takeout_dining_outlined;

                  if (order.status == MockOrderStatus.cancelled) {
                    shippingText = 'Đơn hàng tự đến lấy này đã bị hủy.';
                    shippingColor = Colors.red;
                    shippingIcon = Icons.cancel_outlined;
                  } else if (order.status == MockOrderStatus.pendingConfirm) {
                    if (!order.isPaid && order.isQrPayment) {
                      shippingText =
                          'Vui lòng thanh toán đơn hàng này để cửa hàng bắt đầu chuẩn bị.';
                      shippingColor = Colors.orange.shade800;
                      shippingIcon = Icons.payment_outlined;
                    } else {
                      shippingText = 'Đơn hàng đang chờ cửa hàng xác nhận.';
                      shippingColor = Colors.blue.shade700;
                      shippingIcon = Icons.hourglass_empty_rounded;
                    }
                  } else if (order.status == MockOrderStatus.completed) {
                    shippingText = 'Đơn hàng đã hoàn thành.';
                    shippingColor = Colors.grey.shade700;
                    shippingIcon = Icons.check_circle_outline;
                  } else {
                    shippingText = 'Dự kiến sẵn sàng: $pickupTimeStr';
                    shippingColor = AppColors.primary;
                    shippingIcon = Icons.takeout_dining_outlined;
                  }

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: shippingColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          shippingIcon,
                          size: 16,
                          color: shippingColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shippingText,
                            style: TextStyle(
                              fontSize: 12,
                              color: shippingColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 3. Products List inside Card (Exactly like Shopee layout)
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.bgWarm,
                          child: item.effectiveImageUrl.isNotEmpty
                              ? Image.network(
                                  item.effectiveImageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fastfood_outlined,
                                    size: 26,
                                    color: AppColors.textTertiary,
                                  ),
                                )
                              : const Icon(
                                  Icons.fastfood_outlined,
                                  size: 26,
                                  color: AppColors.textTertiary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.sizeLabel != null &&
                                item.sizeLabel!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Size: ${item.sizeLabel}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500),
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
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (item.note != null &&
                                item.note!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.edit_note_rounded,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      'Ghi chú: ${item.note}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Price & Qty
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatPrice(item.price)}đ',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              if (order.storeNote != null &&
                  order.storeNote!.trim().isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgWarm.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ghi chú đơn hàng: ${order.storeNote}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Divider(height: 1, color: AppColors.outlineVariant),
              const SizedBox(height: 10),

              // 4. Summary Row (Total Price)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AppColors.textTertiary),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Tổng: ',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_formatPrice(order.totalAmount)}đ',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),

              // 5. Action Buttons (Cancel Order / Reorder / Review)
              if (order.status == MockOrderStatus.pendingConfirm) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showCancelReasonsSheet(order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Hủy đơn hàng',
                        style:
                            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ] else if (order.status == MockOrderStatus.completed) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _reorderOrder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Mua lại',
                        style:
                            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isReviewed ? null : () => _navigateToReviewPage(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReviewed ? const Color(0xFFE5E7EB) : AppColors.primary,
                        foregroundColor: isReviewed ? const Color(0xFF9CA3AF) : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 0,
                      ),
                      child: Text(
                        isReviewed ? 'Đã đánh giá' : 'Đánh giá',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isReviewed ? const Color(0xFF9CA3AF) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelReasonsSheet(String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? selectedReason;
        final reasons = [
          'Không cần nữa',
          'Cần thay đổi phương thức thanh toán',
          'Chi phí giao hàng cao',
          'Có giá tốt hơn',
          'Cần thay đổi địa chỉ giao hàng',
          'Người bán yêu cầu hủy đơn',
          'Người bán không trả lời thắc mắc',
        ];

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header / Close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        const Text(
                          'Chọn lý do',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Chọn lý do để hủy đơn ngay',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.outlineVariant),

                  // Reasons List
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reasons.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.outlineVariant),
                      itemBuilder: (context, index) {
                        final reason = reasons[index];
                        final isSelected = selectedReason == reason;
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 16),

                  // Button at the bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                // 1. Cancel order in provider
                                ref.read(orderProvider.notifier).cancelOrder(id);
                                // 2. Dismiss bottom sheet
                                Navigator.pop(ctx);
                                // 3. Navigate to CancelSuccessPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CancelSuccessPage(orderId: id),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Hủy đơn hàng',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildSuggestedStores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Có thể bạn cũng thích',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_suggestedStores.length, (index) {
                final store = _suggestedStores[index];
                return _buildStoreGridCard(store, cardWidth);
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoreGridCard(Map<String, dynamic> store, double cardWidth) {
    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Container(
                width: double.infinity,
                height: 100,
                color: AppColors.bgWarm,
                child: Icon(
                  store['icon'] as IconData,
                  size: 36,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        '${store['rating']}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${store['distance']}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${store['time']}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      store['badge'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReviewPage(MockOrder order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderReviewPage(order: order),
      ),
    );
    if (result == true) {
      ref.read(orderProvider.notifier).fetchMyOrders();
    }
  }

  void _reorderOrder(MockOrder order) {
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      for (final item in order.items) {
        final cartItem = CartItemModel(
          id: '${DateTime.now().microsecondsSinceEpoch}_${item.name}',
          menuItemId: item.menuItemId,
          sizeId: null,
          imageUrl: item.imageUrl ?? '',
          name: item.name,
          priceAmount: item.price,
          priceDisplay: '${item.price}đ',
          quantity: item.quantity,
          note: item.note,
          selectedToppings: [],
        );
        cartNotifier.addItem(
          cartItem,
          storeName: order.storeName,
          branchId: order.branchId.isNotEmpty ? order.branchId : null,
        );
      }
      TopNotification.show(context, message: 'Đã thêm toàn bộ món vào giỏ hàng!', isError: false);
    } catch (e) {
      TopNotification.show(context, message: 'Không thể mua lại: $e', isError: true);
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}

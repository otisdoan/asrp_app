import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/order_provider.dart';

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
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
          _buildTabContent(allOrders),
          // 1. Chờ thanh toán (Rỗng cho self-pickup)
          _buildTabContent(const []),
          // 2. Chờ xác nhận (pendingConfirm)
          _buildTabContent(allOrders.where((o) => o.status == MockOrderStatus.pendingConfirm).toList()),
          // 3. Chờ nhận đơn (preparing, ready)
          _buildTabContent(allOrders.where((o) => o.status == MockOrderStatus.preparing || o.status == MockOrderStatus.ready).toList()),
          // 4. Chờ đánh giá (completed)
          _buildTabContent(allOrders.where((o) => o.status == MockOrderStatus.completed).toList()),
          // 5. Trả hàng (Rỗng)
          _buildTabContent(const []),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<MockOrder> orders) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          if (orders.isNotEmpty) ...[
            ...orders.map((o) => _buildOrderCard(o)),
            const SizedBox(height: 24),
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
                  child: const Icon(Icons.receipt_long_outlined, size: 24, color: AppColors.primary),
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
          // Luôn luôn hiển thị gợi ý cửa hàng ở phía dưới danh sách
          _buildSuggestedStores(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOrderCard(MockOrder order) {
    Color statusTextColor;
    String statusText;

    switch (order.status) {
      case MockOrderStatus.pendingConfirm:
        statusTextColor = Colors.orange.shade800;
        statusText = 'Chờ xác nhận';
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

    final pickupTimeStr = '${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}';
    final hasAlert = order.hasNotification;

    return GestureDetector(
      onTap: () {
        if (order.status != MockOrderStatus.cancelled && order.status != MockOrderStatus.completed) {
          if (order.hasNotification) {
            ref.read(orderProvider.notifier).clearNotification(order.id);
          }
          _showOrderProgressSheet(order);
        }
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
                        const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order.storeName.split(' - ')[0], // Tên ngắn gọn
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE8E7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Giảm 11%',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. ETA Shipping Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      order.status == MockOrderStatus.cancelled ? Icons.cancel_outlined : Icons.takeout_dining_outlined,
                      size: 16,
                      color: order.status == MockOrderStatus.cancelled ? Colors.red : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.status == MockOrderStatus.cancelled
                            ? 'Đơn hàng tự đến lấy này đã bị hủy.'
                            : 'Dự kiến sẵn sàng: $pickupTimeStr (sau ${order.pickupTime.difference(DateTime.now()).inMinutes > 0 ? order.pickupTime.difference(DateTime.now()).inMinutes : order.originalMinutes}p)',
                        style: TextStyle(
                          fontSize: 12,
                          color: order.status == MockOrderStatus.cancelled ? Colors.red : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Products List inside Card (Exactly like Shopee layout)
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image mock container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.bgWarm,
                          child: const Icon(Icons.fastfood_outlined, size: 26, color: AppColors.textTertiary),
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
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.extras != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.extras!.replaceAll('\n', ', '),
                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                            '${(item.price / 1000).toStringAsFixed(0)}.000đ',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

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
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textTertiary),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Tổng: ',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${(order.totalAmount / 1000).toStringAsFixed(0)}.000đ',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),

              // 5. Action Buttons (Cancel Order)
              if (order.status == MockOrderStatus.pendingConfirm) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _confirmCancelOrder(order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Hủy đơn hàng',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

  void _confirmCancelOrder(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Hủy đơn hàng này?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn hủy đơn hàng tự đến lấy này không? Hành động này không thể hoàn tác.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Không', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(orderProvider.notifier).cancelOrder(id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đơn hàng đã được hủy thành công!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Đồng ý hủy'),
            ),
          ],
        );
      },
    );
  }

  // ─── Order Progress and Timeline Bottom Sheet ───────────────────────────
  void _showOrderProgressSheet(MockOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stContext, setStateSheet) {
            // Xem lại danh sách đơn hàng mới nhất từ provider để cập nhật Bottom Sheet thời gian thực
            final currentOrders = ref.watch(orderProvider);
            final currentOrder = currentOrders.firstWhere((o) => o.id == order.id, orElse: () => order);

            String statusTitle = '';
            IconData statusIcon = Icons.hourglass_top_rounded;
            Color statusColor = AppColors.primary;
            String statusSubtitle = '';

            switch (currentOrder.status) {
              case MockOrderStatus.pendingConfirm:
                statusTitle = 'Đơn hàng đang chờ xác nhận';
                statusIcon = Icons.hourglass_top_rounded;
                statusColor = Colors.orange;
                statusSubtitle = 'Thu ngân đang kiểm tra thực đơn và chuẩn bị xác nhận.';
                break;
              case MockOrderStatus.preparing:
                statusTitle = 'Đang chuẩn bị món ăn';
                statusIcon = Icons.soup_kitchen_outlined;
                statusColor = AppColors.primary;
                statusSubtitle = 'Quán đang chế biến đồ ăn nóng hổi cho bạn.';
                break;
              case MockOrderStatus.ready:
                statusTitle = 'Món ăn đã sẵn sàng!';
                statusIcon = Icons.check_circle_outline_rounded;
                statusColor = Colors.green;
                statusSubtitle = 'Mời bạn đến quầy nhận món và thanh toán QR.';
                break;
              case MockOrderStatus.completed:
                statusTitle = 'Đơn hàng hoàn tất';
                statusIcon = Icons.celebration_outlined;
                statusColor = Colors.blue;
                statusSubtitle = 'Cảm ơn bạn đã ủng hộ quán! Chúc ngon miệng!';
                break;
              case MockOrderStatus.cancelled:
                statusTitle = 'Đơn hàng đã bị hủy';
                statusIcon = Icons.cancel_outlined;
                statusColor = Colors.red;
                statusSubtitle = 'Đơn hàng tự đến lấy này đã bị hủy thành công.';
                break;
            }

            final formattedPickupTime =
                '${currentOrder.pickupTime.hour.toString().padLeft(2, '0')}:${currentOrder.pickupTime.minute.toString().padLeft(2, '0')}';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiến độ đơn hàng ${currentOrder.id}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentOrder.storeName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.outlineVariant),

                  // Alert note (If store requested extra minutes or confirmed)
                  if (currentOrder.storeNote != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: currentOrder.extraMinutes > 0
                            ? Colors.red.shade50
                            : AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentOrder.extraMinutes > 0 ? Colors.red.shade200 : AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentOrder.extraMinutes > 0 ? Icons.error_outline : Icons.notifications_active_outlined,
                            color: currentOrder.extraMinutes > 0 ? Colors.red : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentOrder.extraMinutes > 0 ? 'Quán xin thêm phút chuẩn bị' : 'Thông báo từ cửa hàng',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: currentOrder.extraMinutes > 0 ? Colors.red.shade900 : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentOrder.storeNote!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: currentOrder.extraMinutes > 0 ? Colors.red.shade800 : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Massive status info
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusSubtitle,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Giant ETA Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THỜI GIAN NHẬN MÓN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary, letterSpacing: 0.8),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Nhận hàng tại quầy',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedPickupTime,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: currentOrder.extraMinutes > 0 ? Colors.red : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentOrder.extraMinutes > 0
                                  ? 'Trễ thêm ${currentOrder.extraMinutes} phút'
                                  : 'Dự kiến đúng giờ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentOrder.extraMinutes > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timeline section title
                  const Text(
                    'Tiến trình thực tế',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Interactive Vertical Timeline logs
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      children: List.generate(currentOrder.timeline.length, (index) {
                        final log = currentOrder.timeline[currentOrder.timeline.length - 1 - index]; // Đảo ngược để sự kiện mới ở trên cùng
                        final isNewest = index == 0;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isNewest ? statusColor : Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                      border: isNewest
                                          ? Border.all(color: statusColor.withValues(alpha: 0.3), width: 3)
                                          : null,
                                    ),
                                  ),
                                  if (index != currentOrder.timeline.length - 1)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.substring(0, 5), // Time hh:mm
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isNewest ? statusColor : AppColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        log.substring(8), // Event details
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isNewest ? AppColors.textPrimary : AppColors.textSecondary,
                                          fontWeight: isNewest ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Summary items inside sheet
                  const Text(
                    'Chi tiết sản phẩm',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ...currentOrder.items.map((i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i.name} x ${i.quantity}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                Text('${(i.price * i.quantity / 1000).toStringAsFixed(0)}k đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 16, color: AppColors.outlineVariant),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng tiền', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('${(currentOrder.totalAmount / 1000).toStringAsFixed(0)}k đ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                      ],
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
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${store['distance']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${store['time']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}

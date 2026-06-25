import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/order_provider.dart';
import '../../../data/repositories/order_repository.dart';
import 'cancel_success_page.dart';
import 'qr_payment_page.dart';
import '../../../core/utils/top_notification.dart';

/// OrderDetailPage — Displays detailed progress and order information for a single order.
/// Follows self-pickup business model (No delivery, customer picks up at store, QR payment).
class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  static const _suggestedStores = [
    {
      'name': 'Hiên Coffee',
      'rating': 4.7,
      'distance': '0.3km',
      'time': '15 phút',
      'badge': 'Giảm 11%',
      'icon': Icons.coffee
    },
    {
      'name': 'Trạm Cà Phê',
      'rating': 5.0,
      'distance': '0.3km',
      'time': '22 phút',
      'badge': 'Giảm 11%',
      'icon': Icons.local_cafe
    },
    {
      'name': 'Cơm Tấm A Vũ',
      'rating': 4.8,
      'distance': '1.2km',
      'time': '30 phút',
      'badge': 'Giảm 15%',
      'icon': Icons.rice_bowl
    },
    {
      'name': 'Phở Hà Nội',
      'rating': 4.6,
      'distance': '0.8km',
      'time': '20 phút',
      'badge': 'Giảm 10%',
      'icon': Icons.ramen_dining
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).fetchOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(orderProvider);
    final order = allOrders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => MockOrder(
        id: widget.orderId,
        storeName: 'Quán ăn',
        items: [],
        totalAmount: 0,
        status: MockOrderStatus.pendingConfirm,
        orderTime: DateTime.now(),
        pickupTime: DateTime.now(),
        originalMinutes: 15,
        timeline: [],
        paymentStatus: 'Pending',
        orderType: 'Online',
      ),
    );

    String appBarTitle = 'Đã đặt hàng';
    if (order.status == MockOrderStatus.pendingConfirm) {
      if (!order.isPaid && order.isQrPayment) {
        appBarTitle = 'Chờ thanh toán';
      } else {
        appBarTitle = 'Chờ xác nhận';
      }
    } else {
      switch (order.status) {
        case MockOrderStatus.pendingConfirm:
          break;
        case MockOrderStatus.preparing:
          appBarTitle = 'Đang chuẩn bị';
          break;
        case MockOrderStatus.ready:
          appBarTitle = 'Chờ nhận món';
          break;
        case MockOrderStatus.completed:
          appBarTitle = 'Hoàn tất đơn hàng';
          break;
        case MockOrderStatus.cancelled:
          appBarTitle = 'Đã hủy đơn';
          break;
      }
    }

    final pickupTimeStr =
        '${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Soft grey background
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderProvider.notifier).fetchOrderDetail(widget.orderId),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Stepper Progress ────────────────────────────────────────────
              _buildProgressStepper(order.status),
              const SizedBox(height: 12),

            // ─── Status Informative Banner ───────────────────────────────────
            _buildStatusBanner(order, pickupTimeStr),
            const SizedBox(height: 12),

            if (order.hasNotification) ...[
              _buildProposedTimeBanner(order),
              const SizedBox(height: 12),
            ],

            // ─── Shop & Items Details Card ───────────────────────────────────
            _buildShopItemsCard(order),
            const SizedBox(height: 12),

            // ─── Order Summary & Metadata Card ────────────────────────────────
            _buildOrderMetadataCard(order, pickupTimeStr),
            const SizedBox(height: 24),

            // ─── Suggested Stores ("Có thể bạn cũng thích") ───────────────────
            _buildSuggestedStores(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
      bottomNavigationBar: _buildBottomActions(order),
    );
  }

  Widget _buildProgressStepper(MockOrderStatus status) {
    if (status == MockOrderStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đơn hàng đã bị hủy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đơn hàng tự đến lấy này đã được hủy thành công.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    int currentStep = 0;
    switch (status) {
      case MockOrderStatus.pendingConfirm:
        currentStep = 0;
        break;
      case MockOrderStatus.preparing:
        currentStep = 1;
        break;
      case MockOrderStatus.ready:
        currentStep = 2;
        break;
      case MockOrderStatus.completed:
        currentStep = 3;
        break;
      case MockOrderStatus.cancelled:
        currentStep = 0;
        break;
    }

    final steps = [
      {'title': 'Đã đặt hàng', 'icon': Icons.assignment_turned_in_rounded},
      {'title': 'Đang chuẩn bị', 'icon': Icons.soup_kitchen_rounded},
      {'title': 'Chờ nhận món', 'icon': Icons.takeout_dining_rounded},
      {'title': 'Hoàn tất', 'icon': Icons.celebration_rounded},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Left connecting line
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: index == 0
                            ? Colors.transparent
                            : (index <= currentStep ? AppColors.primary : AppColors.outlineVariant),
                      ),
                    ),
                    // Circle indicator icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.primary : (isCompleted ? AppColors.primaryContainer : Colors.white),
                        border: Border.all(
                          color: isCompleted || isActive ? AppColors.primary : AppColors.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted ? Icons.check : (step['icon'] as IconData),
                          size: 15,
                          color: isActive ? Colors.white : (isCompleted ? AppColors.primary : AppColors.textTertiary),
                        ),
                      ),
                    ),
                    // Right connecting line
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: index == steps.length - 1
                            ? Colors.transparent
                            : (index < currentStep ? AppColors.primary : AppColors.outlineVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.primary : (isCompleted ? AppColors.textPrimary : AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusBanner(MockOrder order, String pickupTimeStr) {
    IconData bannerIcon = Icons.info_outline;
    String titleText = '';
    String subText = '';
    Color iconColor = AppColors.primary;
    Color containerColor = AppColors.primaryContainer;

    if (order.status == MockOrderStatus.pendingConfirm) {
      if (!order.isPaid && order.isQrPayment) {
        bannerIcon = Icons.account_balance_wallet_outlined;
        titleText = 'Chờ thanh toán';
        subText = 'Vui lòng hoàn tất thanh toán chuyển khoản qua QR để quán bắt đầu chuẩn bị món.';
        iconColor = Colors.orange;
        containerColor = const Color(0xFFFFF9F5);
      } else {
        bannerIcon = Icons.hourglass_empty_rounded;
        titleText = 'Chờ quán xác nhận';
        subText = 'Quán đang kiểm tra đơn hàng và chuẩn bị xác nhận thời gian chuẩn bị món ăn.';
        iconColor = Colors.orange;
        containerColor = const Color(0xFFFFF9F5);
      }
    } else {
      switch (order.status) {
      case MockOrderStatus.pendingConfirm:
        break;
      case MockOrderStatus.preparing:
        bannerIcon = Icons.soup_kitchen_outlined;
        titleText = 'Đang chuẩn bị món';
        subText = 'Đầu bếp đang chuẩn bị những món ăn nóng hổi cho bạn. Dự kiến xong lúc $pickupTimeStr.';
        iconColor = AppColors.primary;
        containerColor = const Color(0xFFFFF4F0);
        break;
      case MockOrderStatus.ready:
        bannerIcon = Icons.check_circle_outline_rounded;
        titleText = 'Món ăn đã sẵn sàng!';
        subText = 'Vui lòng đến ngay quầy nhận món của quán và đưa mã đơn hàng để nhận đồ ăn.';
        iconColor = Colors.green;
        containerColor = const Color(0xFFE8F5E9);
        break;
      case MockOrderStatus.completed:
        bannerIcon = Icons.celebration_outlined;
        titleText = 'Đơn hàng hoàn tất';
        subText = 'Cảm ơn bạn đã đặt món! Chúc bạn có một bữa ăn thật ngon miệng.';
        iconColor = Colors.blue;
        containerColor = const Color(0xFFE3F2FD);
        break;
      case MockOrderStatus.cancelled:
        return const SizedBox.shrink(); // Stepper already displays cancel info
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(bannerIcon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItemsCard(MockOrder order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header Link
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Quán',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.storeName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),

          // Items list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Item Image
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
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (item.extras != null && item.extras!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.extras!.replaceAll('\n', ', '),
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quantity and Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatPrice(item.price)}đ',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMetadataCard(MockOrder order, String pickupTimeStr) {
    final orderDateStr =
        '${order.orderTime.day.toString().padLeft(2, '0')}/${order.orderTime.month.toString().padLeft(2, '0')}/${order.orderTime.year}';
    final orderTimeStr =
        '${order.orderTime.hour.toString().padLeft(2, '0')}:${order.orderTime.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chi tiết đơn hàng',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetadataRow(
            'Mã đơn hàng',
            order.orderNumber.isNotEmpty ? '#${order.orderNumber}' : order.id,
            isCopyable: true,
            copyValue: order.orderNumber.isNotEmpty ? order.orderNumber : order.id,
          ),
          const SizedBox(height: 10),
          _buildMetadataRow('Thời gian đặt hàng', '$orderTimeStr ngày $orderDateStr'),
          const SizedBox(height: 10),
          _buildMetadataRow('Thời gian nhận dự kiến', '$pickupTimeStr (sau ${order.originalMinutes}p)'),
          const SizedBox(height: 10),
          _buildMetadataRow('Phương thức nhận hàng', 'Tự đến lấy tại quán'),
          const SizedBox(height: 10),
          _buildMetadataRow(
            'Phương thức thanh toán',
            order.payments.isNotEmpty
                ? (order.payments.first.method == 'Tiền mặt' ? 'Thanh toán tiền mặt' : 'Quét mã QR (VietQR/PayOS)')
                : 'Quét mã QR tại quán',
          ),
          const Divider(height: 24, color: AppColors.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                '${_formatPrice(order.totalAmount)}đ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProposedTimeBanner(MockOrder order) {
    final newTimeStr = '${order.pickupTime.hour.toString().padLeft(2, '0')}:${order.pickupTime.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 22),
              const SizedBox(width: 8),
              Text(
                'Quán đề xuất thời gian mới',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cửa hàng đề xuất thời gian nhận hàng mới vào lúc $newTimeStr (xin thêm phút do quá tải). Bạn có đồng ý không?',
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(orderProvider.notifier).declineProposedTime(order.id);
                  TopNotification.show(
                    context,
                    message: 'Đã từ chối đề xuất và hủy đơn hàng.',
                    isError: true,
                  );
                },
                child: Text('Từ chối', style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(orderProvider.notifier).acceptProposedTime(order.id);
                  TopNotification.show(
                    context,
                    message: 'Đã đồng ý thời gian nhận mới!',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Đồng ý', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool isCopyable = false, String? copyValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyValue ?? value));
                  TopNotification.show(
                    context,
                    message: 'Đã sao chép mã đơn hàng vào bộ nhớ tạm!',
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestedStores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Có thể bạn cũng thích',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestedStores.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final store = _suggestedStores[index];
            return _buildStoreCard(store);
          },
        ),
      ],
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest, // White card background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Icon area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                width: double.infinity,
                color: AppColors.bgWarm,
                child: Icon(
                  store['icon'] as IconData,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          // Info Area
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['name'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                    const SizedBox(width: 2),
                    Text(
                      '${store['rating']}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${store['distance']}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    store['badge'] as String,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions(MockOrder order) {
    if (order.status != MockOrderStatus.pendingConfirm) {
      return null;
    }

    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final isUnpaidQr = !order.isPaid && order.isQrPayment;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomSafe + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: isUnpaidQr 
                    ? () => _showCancelReasonsSheet(order.id)
                    : () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Liên hệ quán'),
                            content: Text('Số điện thoại hotline của quán ${order.storeName} là: 1900 1234'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
                              ),
                            ],
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  isUnpaidQr ? 'Hủy đơn hàng' : 'Liên hệ quán',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: isUnpaidQr
                    ? () async {
                        try {
                          final paymentPayload = {
                            "method": 1, // QrBankTransfer (Enum PaymentMethod index 1)
                            "transactionReference": null,
                            "note": "Thanh toan don hang ${order.id}",
                            "returnUrl": "dinex://payment-success?orderId=${order.id}",
                            "cancelUrl": "dinex://payment-cancel?orderId=${order.id}"
                          };
                          final response = await OrderRepository().initiatePayment(order.id, paymentPayload);
                          final checkoutUrl = response['checkoutUrl'] as String?;
                          final qrCode = response['qrCode'] as String?;
                          final amountVal = (response['amount'] as num?)?.toDouble() ?? order.totalAmount.toDouble();

                          if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrPaymentPage(
                                    orderId: order.id,
                                    qrCode: qrCode ?? '',
                                    amount: amountVal,
                                    checkoutUrl: checkoutUrl,
                                  ),
                                ),
                              );
                            }
                          } else {
                            throw Exception('Không nhận được liên kết thanh toán từ PayOS');
                          }
                        } catch (e) {
                          TopNotification.show(
                            context,
                            message: 'Lỗi khởi tạo thanh toán: ${e.toString().replaceAll('Exception: ', '')}',
                            isError: true,
                          );
                        }
                      }
                    : () => _showCancelReasonsSheet(order.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isUnpaidQr ? 'Thanh toán ngay' : 'Hủy đơn hàng',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
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
                          child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
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

                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reasons.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                // 1. Cancel order
                                ref.read(orderProvider.notifier).cancelOrder(id);
                                // 2. Dismiss sheet
                                Navigator.pop(ctx);
                                // 3. Push CancelSuccessPage
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CancelSuccessPage(orderId: id),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Hủy đơn hàng',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}

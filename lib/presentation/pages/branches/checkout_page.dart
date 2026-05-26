import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/orders/order_provider.dart';
import '../../../data/orders/models/order_api_model.dart';

/// Checkout Page — order summary, pickup time, QR payment.
/// Business: No delivery. Customer orders online, picks up at store.
/// Only payment method: QR code at restaurant.
/// Follows RULE: UI-only, uses AppColors, responsive.
class CheckoutPage extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;
  final int itemCount;
  final String distance;
  final IconData icon;

  const CheckoutPage({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.itemCount,
    required this.distance,
    required this.icon,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  int _selectedTimeIndex = 0;

  static const _timeSlots = [
    {'label': 'Sớm nhất', 'time': '15 phút', 'note': 'Món hoàn thành nhanh nhất'},
    {'label': 'Sau 30 phút', 'time': '30 phút', 'note': ''},
    {'label': 'Sau 45 phút', 'time': '45 phút', 'note': ''},
    {'label': 'Hẹn giờ khác', 'time': '', 'note': ''},
  ];

  int get _serviceFee => 3000;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ───────────────────────────────────────────
          _buildAppBar(context),

          // ─── Order Summary ─────────────────────────────────────
          SliverToBoxAdapter(child: _buildOrderSummary()),

          // ─── Pickup Time ───────────────────────────────────────
          SliverToBoxAdapter(child: _buildPickupTime()),

          // ─── Payment Method ────────────────────────────────────
          SliverToBoxAdapter(child: _buildPaymentMethod()),

          // ─── Price Breakdown ───────────────────────────────────
          SliverToBoxAdapter(child: _buildPriceBreakdown()),

          // ─── Terms ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildTerms()),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // ─── Bottom Confirm Button ─────────────────────────────────
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.storeName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Khoảng cách tới quán: ${widget.distance}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  // ─── Order Summary ─────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tóm tắt đơn hàng',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Thêm món',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Order items
        ...List.generate(ref.watch(cartProvider).items.length, (index) {
          final item = ref.watch(cartProvider).items[index];
          return _buildOrderItem(item);
        }),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.outlineVariant),
      ],
    );
  }

  Widget _buildOrderItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 22, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                  if (item.note != null && item.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatPrice(item.priceAmount)}đ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Quantity badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Pickup Time ───────────────────────────────────────────────────────
  Widget _buildPickupTime() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.access_time_filled, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Thời gian nhận hàng tại quán',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn thời gian bạn đến quán lấy đồ',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          // Time slots
          ...List.generate(_timeSlots.length, (index) {
            final slot = _timeSlots[index];
            final isSelected = _selectedTimeIndex == index;
            return _buildTimeSlot(
              label: slot['label'] as String,
              time: slot['time'] as String,
              note: slot['note'] as String,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedTimeIndex = index),
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildTimeSlot({
    required String label,
    required String time,
    required String note,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        Text(
                          ' • $time',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Payment Method ────────────────────────────────────────────────────
  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin thanh toán',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          // QR Payment method (only option)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2, color: AppColors.onPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thanh toán qua mã QR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quét mã QR tại quán khi nhận hàng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Price Breakdown ───────────────────────────────────────────────────
  Widget _buildPriceBreakdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          // Subtotal
          _buildPriceRow('Tổng tạm tính', ref.watch(cartProvider).subtotal),
          const SizedBox(height: 10),
          // Service fee
          _buildPriceRow('Phí dịch vụ', _serviceFee),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 14),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_formatPrice(ref.watch(cartProvider).total + _serviceFee)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          '${_formatPrice(price)}đ',
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // ─── Terms ─────────────────────────────────────────────────────────────
  Widget _buildTerms() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          children: [
            TextSpan(text: 'Bằng việc đặt đơn này, bạn đã đồng ý '),
            TextSpan(
              text: 'Điều khoản Sử dụng',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' và '),
            TextSpan(
              text: 'Quy chế Hoạt động',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' của chúng tôi'),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Confirm Button ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_formatPrice(ref.watch(cartProvider).total + _serviceFee)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final cartItems = ref.read(cartProvider).items;
                  
                  DateTime pickupTime;
                  switch (_selectedTimeIndex) {
                    case 0:
                      pickupTime = DateTime.now().add(const Duration(minutes: 15));
                      break;
                    case 1:
                      pickupTime = DateTime.now().add(const Duration(minutes: 30));
                      break;
                    case 2:
                      pickupTime = DateTime.now().add(const Duration(minutes: 45));
                      break;
                    case 3:
                    default:
                      pickupTime = DateTime.now().add(const Duration(minutes: 60));
                      break;
                  }

                  final request = CreateOnlineOrderRequest(
                    branchId: widget.storeId,
                    pickupTime: pickupTime.toIso8601String(),
                    items: cartItems.map((item) => OrderItemRequest(
                      menuItemId: item.id,
                      quantity: item.quantity,
                      note: item.note,
                    )).toList(),
                  );
                  
                  final success = await ref.read(orderProvider.notifier).createOnlineOrder(request, useCash: true);
                  
                  if (success && context.mounted) {
                    ref.read(cartProvider.notifier).clearCart(); // We should add clearCart method to CartNotifier
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đơn hàng đã được xác nhận! Vui lòng đến quán nhận hàng.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đặt hàng thất bại. Vui lòng thử lại.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Xác nhận đơn hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

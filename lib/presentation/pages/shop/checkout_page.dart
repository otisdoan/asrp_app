import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/topping_selection_model.dart';
import 'add_to_cart_page.dart';
import 'order_success_page.dart';

/// Checkout Page — order summary, pickup time, QR payment.
/// Business: No delivery. Customer orders online, picks up at store.
/// Only payment method: QR code at restaurant.
/// Follows RULE: UI-only, uses AppColors, responsive.
class CheckoutPage extends ConsumerStatefulWidget {
  final String storeName;
  final int itemCount;
  final String distance;
  final IconData icon;

  const CheckoutPage({
    super.key,
    required this.storeName,
    required this.itemCount,
    required this.distance,
    required this.icon,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  late int _selectedMinutes;

  int get _minPrepTime {
    final travelTime = _calculateTravelTime(widget.distance);
    const basePrepTime = 12; // Base preparation time of mock items (mins)
    const buffer = 3; // Buffer time (mins)
    final maxVal = basePrepTime > travelTime ? basePrepTime : travelTime;
    return maxVal + buffer;
  }

  @override
  void initState() {
    super.initState();
    // Mặc định chọn chính xác mốc thời gian tối thiểu khả thi (ASAP) để khách lấy đồ nhanh nhất có thể
    _selectedMinutes = _minPrepTime;
  }

  bool _isExpanded = false;

  int get _serviceFee => 3000;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.subtotal;
    final total = subtotal + _serviceFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ───────────────────────────────────────────
          _buildAppBar(context),

          // ─── Order Summary ─────────────────────────────────────
          SliverToBoxAdapter(child: _buildOrderSummary(cart.items)),

          // ─── Pickup Time ───────────────────────────────────────
          SliverToBoxAdapter(child: _buildPickupTime()),

          // ─── Payment Method ────────────────────────────────────
          SliverToBoxAdapter(child: _buildPaymentMethod()),

          // ─── Price Breakdown ───────────────────────────────────
          SliverToBoxAdapter(child: _buildPriceBreakdown(subtotal, total)),

          // ─── Terms ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildTerms()),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // ─── Bottom Confirm Button ─────────────────────────────────
      bottomNavigationBar: _buildBottomBar(cart, total),
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
  Widget _buildOrderSummary(List<CartItemModel> items) {
    final displayItems = _isExpanded ? items : items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
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
                onTap: () {
                  Navigator.pop(context); // Thêm món: Quay lại để chọn thêm
                },
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
        ...displayItems.map((item) => _buildOrderItem(item)),

        // Xem thêm / Thu gọn button
        if (items.length > 3) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                _isExpanded ? 'Thu gọn' : 'Xem thêm (còn ${items.length - 3} món)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.outlineVariant),
      ],
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    final extrasList = <String>[];
    for (final topping in item.selectedToppings) {
      extrasList.add(topping.name);
    }
    if (item.note != null && item.note!.trim().isNotEmpty) {
      extrasList.add('Lưu ý: ${item.note!.trim()}');
    }
    final extras = extrasList.join('\n');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food icon / image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (item.imageUrl.isNotEmpty)
                  ? (item.imageUrl.startsWith('http')
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(widget.icon, size: 22, color: AppColors.textTertiary),
                        )
                      : Image.asset(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(widget.icon, size: 22, color: AppColors.textTertiary),
                        ))
                  : Icon(widget.icon, size: 22, color: AppColors.textTertiary),
            ),
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
                if (extras.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    extras,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _editOrderItem(item),
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
                '${_formatPrice(item.unitTotal)}đ',
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

  void _editOrderItem(CartItemModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddToCartPage(
          name: item.name,
          price: '${item.priceAmount}đ',
          icon: widget.icon,
          imageUrl: item.imageUrl,
          initialQuantity: item.quantity,
          initialSelectedToppings: item.selectedToppings
              .where((t) => !t.name.startsWith('Size'))
              .map((t) => t.name)
              .toList(),
          initialSize: item.selectedToppings
              .where((t) => t.name.startsWith('Size'))
              .map((t) => t.name.replaceAll('Size ', ''))
              .firstOrNull,
          initialNote: item.note,
          isEditing: true,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      ref.read(cartProvider.notifier).updateItem(
        item.id,
        quantity: result['quantity'] as int,
        note: result['note'] as String?,
        selectedToppings: result['selectedToppings'] as List<ToppingSelectionModel>,
      );
    }
  }

  // ─── Pickup Time ───────────────────────────────────────────────────────
  int _calculateTravelTime(String distanceStr) {
    final normalized = distanceStr.replaceAll(',', '.');
    final cleaned =
        normalized.toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(cleaned) ?? 1.0;
    if (distanceStr.toLowerCase().contains('m') &&
        !distanceStr.toLowerCase().contains('k')) {
      return (val / 80).ceil(); // ~80m per minute walking
    } else {
      return (val * 5).ceil(); // ~5 mins per km driving
    }
  }

  Widget _buildPickupTime() {
    // Calculate expected ready time
    final now = DateTime.now();
    final readyTime = now.add(Duration(minutes: _selectedMinutes));
    final readyTimeStr =
        '${readyTime.hour.toString().padLeft(2, '0')}:${readyTime.minute.toString().padLeft(2, '0')}';

    final maxMinutes = _minPrepTime > 120 ? _minPrepTime + 30 : 120;
    final lockedFlex = _minPrepTime;
    final selectedFlex = _selectedMinutes - _minPrepTime;
    final unselectedFlex = maxMinutes - _selectedMinutes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.access_time_filled,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Thời gian nhận hàng tại quán',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kéo thanh trượt để hẹn giờ bạn đến quán lấy đồ',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Custom Stacked Slider
          Stack(
            alignment: Alignment.center,
            children: [
              // Custom Colored Background Track
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // 1. Locked portion (always gray)
                    Expanded(
                      flex: lockedFlex,
                      child: Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    // 2. Selected active portion (solid primary color)
                    if (selectedFlex > 0)
                      Expanded(
                        flex: selectedFlex,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: unselectedFlex == 0
                                ? const BorderRadius.only(
                                    topRight: Radius.circular(3),
                                    bottomRight: Radius.circular(3),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    // 3. Unselected active portion (light primary color)
                    if (unselectedFlex > 0)
                      Expanded(
                        flex: unselectedFlex,
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(
                                0xFFFFEAE3), // Light primary color background
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Transparent-track Flutter Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 3,
                    pressedElevation: 6,
                  ),
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                ),
                child: Slider(
                  min: 0,
                  max: maxMinutes.toDouble(),
                  value: _selectedMinutes.toDouble(),
                  onChanged: (val) {
                    setState(() {
                      if (val < _minPrepTime) {
                        _selectedMinutes = _minPrepTime;
                      } else {
                        _selectedMinutes = val.toInt();
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          // Custom scale labels below slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('0m',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text('${_minPrepTime}m (Tối thiểu)',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold)),
                if (_minPrepTime < 45)
                  const Text('45m',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                if (_minPrepTime < 90)
                  const Text('90m',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text('${maxMinutes}m',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Expected Ready Time Display Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Dự kiến sẵn sàng: ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: readyTimeStr,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: ' (sau $_selectedMinutes phút)',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Payment Method ────────────────────────────────────────────────────
  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  child: const Icon(Icons.qr_code_2,
                      color: AppColors.onPrimary, size: 22),
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
                  child: const Icon(Icons.check,
                      size: 14, color: AppColors.onPrimary),
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
  Widget _buildPriceBreakdown(int subtotal, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      child: Column(
        children: [
          // Subtotal
          _buildPriceRow('Tổng tạm tính', subtotal),
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
                '${_formatPrice(total)}đ',
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
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          children: [
            TextSpan(text: 'Bằng việc đặt đơn này, bạn đã đồng ý '),
            TextSpan(
              text: 'Điều khoản Sử dụng',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' và '),
            TextSpan(
              text: 'Quy chế Hoạt động',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' của chúng tôi'),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Confirm Button ─────────────────────────────────────────────
  Widget _buildBottomBar(CartState cart, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
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
                  '${_formatPrice(total)}đ',
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
                onPressed: () {
                  final now = DateTime.now();
                  final readyTime =
                      now.add(Duration(minutes: _selectedMinutes));
                  final readyTimeStr =
                      '${readyTime.hour.toString().padLeft(2, '0')}:${readyTime.minute.toString().padLeft(2, '0')}';

                  // 1. Tạo đơn hàng Self-Pickup mock
                  final newOrder = MockOrder(
                    id: '#SP${(100 + (ref.read(orderProvider).length) * 7).toString()}',
                    storeName: widget.storeName,
                    items: cart.items.map((item) {
                      final extraList = <String>[];
                      if (item.selectedToppings.isNotEmpty) {
                        extraList.addAll(item.selectedToppings.map((t) => t.name));
                      }
                      if (item.note != null && item.note!.isNotEmpty) {
                        extraList.add('Lưu ý: ${item.note}');
                      }
                      return MockOrderItem(
                        name: item.name,
                        price: item.unitTotal,
                        quantity: item.quantity,
                        extras: extraList.isNotEmpty ? extraList.join('\n') : null,
                      );
                    }).toList(),
                    totalAmount: total,
                    status:
                        MockOrderStatus.pendingConfirm, // Ban đầu: Chờ xác nhận
                    orderTime: now,
                    pickupTime: readyTime,
                    originalMinutes: _selectedMinutes,
                    timeline: [
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - Khách hàng tạo đơn hàng và chọn thời gian chuẩn bị $_selectedMinutes phút (dự kiến $readyTimeStr).'
                    ],
                  );

                  // 2. Thêm vào provider quản lý đơn hàng
                  ref.read(orderProvider.notifier).addOrder(newOrder);

                  // 3. Clear giỏ hàng sau khi đặt thành công
                  ref.read(cartProvider.notifier).clearCart();

                  // Chuyển hướng đến trang đặt hàng thành công
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderSuccessPage(orderId: newOrder.id),
                    ),
                  );
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

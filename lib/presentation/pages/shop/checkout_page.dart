import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/topping_selection_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../providers/order_provider.dart';
import 'add_to_cart_page.dart';
import 'order_success_page.dart';
import 'qr_payment_page.dart';

/// Checkout Page — order summary, pickup time, QR payment.
/// Business: No delivery. Customer orders online, picks up at store.
/// Only payment method: QR code at restaurant.
/// Follows RULE: UI-only, uses AppColors, responsive.
class CheckoutPage extends ConsumerStatefulWidget {
  final String storeName;
  final int itemCount;
  final String distance;
  final IconData icon;
  final String? branchId;

  const CheckoutPage({
    super.key,
    required this.storeName,
    required this.itemCount,
    required this.distance,
    required this.icon,
    this.branchId,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  List<String> _availablePickupTimes = [];
  String? _selectedPickupTime;
  bool _isLoading = true;
  bool _isFirstLoad = true;
  int _previewDiscount = 0;
  final OrderRepository _orderRepository = OrderRepository();

  bool _isExpanded = false;

  int get _serviceFee => 0;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _formatTimeSlot(String utcString) {
    try {
      final dt = DateTime.parse(utcString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return utcString;
    }
  }

  Map<String, dynamic> _buildOrderPayload(CartState cart,
      {String? selectedTime}) {
    final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false);

    bool isUuid(String? str) {
      if (str == null) return false;
      return uuidRegex.hasMatch(str);
    }

    return {
      "branchId": widget.branchId ??
          cart.branchId ??
          "2ea54df9-f2b0-42d2-ad20-bcb01f7e8b0e",
      "pickupTime": selectedTime,
      "items": cart.items.map((item) {
        String? sizeId;
        if (item.sizeId != null && isUuid(item.sizeId)) {
          sizeId = item.sizeId;
        } else {
          final sizeTopping = item.selectedToppings.firstWhere(
            (t) => t.name.startsWith('Size ') && isUuid(t.toppingId),
            orElse: () =>
                const ToppingSelectionModel(toppingId: '', name: '', price: 0),
          );
          if (sizeTopping.toppingId.isNotEmpty) {
            sizeId = sizeTopping.toppingId;
          }
        }

        final toppingsList = item.selectedToppings
            .where((t) => !t.name.startsWith('Size ') && isUuid(t.toppingId))
            .map((t) => {"toppingId": t.toppingId, "quantity": 1})
            .toList();

        final menuItemId = isUuid(item.menuItemId)
            ? item.menuItemId
            : "3cf9ad92-b267-4dac-a01b-7ef3f61b414a"; // Fallback to a valid item UUID if mock

        return {
          "menuItemId": menuItemId,
          "sizeId": sizeId,
          "quantity": item.quantity,
          "note": item.note,
          "toppings": toppingsList,
        };
      }).toList(),
      "combos": [],
      "note": cart.note,
      "promotionId": null
    };
  }

  Future<void> _fetchOrderPreview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cart = ref.read(cartProvider);
      final payload =
          _buildOrderPayload(cart, selectedTime: _selectedPickupTime);
      final response = await _orderRepository.previewOrder(payload);

      setState(() {
        _availablePickupTimes =
            List<String>.from(response['availablePickupTimes'] ?? []);
        if (_availablePickupTimes.isNotEmpty && _selectedPickupTime == null) {
          _selectedPickupTime = _availablePickupTimes.first;
        }
        _previewDiscount = (response['discountAmount'] as num?)?.toInt() ?? 0;
        _isLoading = false;
        _isFirstLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tính toán giá đơn hàng: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrderPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    if (cart.items.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isLoading && _isFirstLoad) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final subtotal = cart.subtotal;
    final total =
        (subtotal - _previewDiscount + _serviceFee).clamp(0, 99999999);

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
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                _isExpanded
                    ? 'Thu gọn'
                    : 'Xem thêm (còn ${items.length - 3} món)',
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
                          errorBuilder: (_, __, ___) => Icon(widget.icon,
                              size: 22, color: AppColors.textTertiary),
                        )
                      : Image.asset(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(widget.icon,
                              size: 22, color: AppColors.textTertiary),
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
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    const Text(
                      '|',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.outlineVariant),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _confirmDeleteItem(item),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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

  void _confirmDeleteItem(CartItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa món ăn?'),
        content: Text(
            'Bạn có chắc chắn muốn xóa món "${item.name}" khỏi đơn hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(cartProvider.notifier).removeItem(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa "${item.name}" khỏi đơn hàng'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _editOrderItem(CartItemModel item) async {
    final cart = ref.read(cartProvider);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddToCartPage(
          name: item.name,
          price: '${item.priceAmount}đ',
          icon: widget.icon,
          imageUrl: item.imageUrl,
          menuItemId: item.menuItemId,
          branchId: widget.branchId ?? cart.branchId,
          initialQuantity: item.quantity,
          initialSelectedToppings: item.selectedToppings,
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
            selectedToppings:
                result['selectedToppings'] as List<ToppingSelectionModel>,
          );
    }
  }

  // ─── Pickup Time ───────────────────────────────────────────────────────

  String _dateTimeToIsoUtcString(DateTime dt) {
    final utc = dt.toUtc();
    final iso = utc.toIso8601String();
    if (iso.contains('.')) {
      return '${iso.split('.').first}Z';
    }
    return iso;
  }

  // ─── Pickup Time ───────────────────────────────────────────────────────

  Widget _buildPickupTime() {
    if (_isLoading && _isFirstLoad) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_availablePickupTimes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_filled,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thời gian nhận hàng',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Không có khung giờ nhận hàng khả dụng.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.outlineVariant),
          ],
        ),
      );
    }

    if (_availablePickupTimes.length == 1) {
      final slot = _availablePickupTimes.first;
      final formattedTime = _formatTimeSlot(slot);
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_filled,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thời gian nhận hàng',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Quán hẹn lúc: $formattedTime',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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

    final minTimeStr = _availablePickupTimes.first;
    final maxTimeStr = _availablePickupTimes.last;
    DateTime? minDateTime;
    DateTime? maxDateTime;
    try {
      minDateTime = DateTime.parse(minTimeStr).toLocal();
      maxDateTime = DateTime.parse(maxTimeStr).toLocal();
    } catch (_) {}

    if (minDateTime == null ||
        maxDateTime == null ||
        maxDateTime.isBefore(minDateTime) ||
        maxDateTime.isAtSameMomentAs(minDateTime)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_filled,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thời gian nhận hàng',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Hẹn lúc: ${_selectedPickupTime != null ? _formatTimeSlot(_selectedPickupTime!) : 'Chưa chọn'}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.outlineVariant),
          ],
        ),
      );
    }

    final double minVal = minDateTime.millisecondsSinceEpoch.toDouble();
    final double maxVal = maxDateTime.millisecondsSinceEpoch.toDouble();

    double currentVal = minVal;
    if (_selectedPickupTime != null) {
      try {
        final currentDT = DateTime.parse(_selectedPickupTime!).toLocal();
        currentVal = currentDT.millisecondsSinceEpoch.toDouble();
      } catch (_) {}
    }
    currentVal = currentVal.clamp(minVal, maxVal);
    final selectedDT = DateTime.fromMillisecondsSinceEpoch(currentVal.toInt());
    final selectedFormatted =
        '${selectedDT.hour.toString().padLeft(2, '0')}:${selectedDT.minute.toString().padLeft(2, '0')}';

    final diffMins = selectedDT.difference(DateTime.now()).inMinutes;
    final String timeSubText =
        diffMins > 0 ? '(sau $diffMins phút nữa)' : '(ngay bây giờ)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Chọn thời gian nhận hàng',
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
            'Kéo thanh trượt để chọn giờ bạn muốn đến quán để lấy đồ',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.outlineVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              valueIndicatorColor: AppColors.primary,
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: Slider(
              min: minVal,
              max: maxVal,
              value: currentVal,
              onChanged: (value) {
                final roundedMs = (value / 60000).round() * 60000;
                DateTime finalDT =
                    DateTime.fromMillisecondsSinceEpoch(roundedMs);
                if (finalDT.isBefore(minDateTime!)) {
                  finalDT = minDateTime;
                } else if (finalDT.isAfter(maxDateTime!)) {
                  finalDT = maxDateTime;
                }
                setState(() {
                  _selectedPickupTime = _dateTimeToIsoUtcString(finalDT);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sớm nhất: ${_formatTimeSlot(minTimeStr)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Muộn nhất: ${_formatTimeSlot(maxTimeStr)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Nhận hàng lúc: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  selectedFormatted,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timeSubText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
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
          if (_previewDiscount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Khuyến mãi',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  '-${_formatPrice(_previewDiscount)}đ',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
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
  Future<void> _handleConfirmCheckout(CartState cart, int total) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Call preview again to chốt final price
      final previewPayload =
          _buildOrderPayload(cart, selectedTime: _selectedPickupTime);
      final previewResponse =
          await _orderRepository.previewOrder(previewPayload);

      final finalAmount =
          (previewResponse['finalAmount'] as num?)?.toInt() ?? total;
      print('[Checkout] Final confirmed amount from preview: $finalAmount');

      // 2. Call placeOrder to create the order
      final orderResponse = await _orderRepository.placeOrder(previewPayload);
      final orderId = orderResponse['id'] as String?;
      if (orderId == null || orderId.isEmpty) {
        throw Exception('Không nhận được ID đơn hàng từ hệ thống');
      }

      // 3. Call payment to initiate VietQR / PayOS payment
      final paymentPayload = {
        "method": 1,
        "transactionReference": null,
        "note": "Thanh toan don hang $orderId",
        "returnUrl": "dinex://payment-success?orderId=$orderId",
        "cancelUrl": "dinex://payment-cancel?orderId=$orderId"
      };

      final paymentResponse =
          await _orderRepository.initiatePayment(orderId, paymentPayload);
      final checkoutUrl = paymentResponse['checkoutUrl'] as String?;
      final qrCode = paymentResponse['qrCode'] as String?;
      final amountVal = (paymentResponse['amount'] as num?)?.toDouble() ?? finalAmount.toDouble();

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Không nhận được liên kết thanh toán từ PayOS');
      }

      // 4. Clear cart after ordering successfully
      ref.read(cartProvider.notifier).clearCart();

      // Refresh orders list to include the newly placed order
      ref.read(orderProvider.notifier).fetchMyOrders();

      // 5. Navigate to QrPaymentPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QrPaymentPage(
              orderId: orderId,
              qrCode: qrCode ?? '',
              amount: amountVal,
              checkoutUrl: checkoutUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Lỗi đặt hàng'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
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
                onPressed: _isLoading
                    ? null
                    : () => _handleConfirmCheckout(cart, total),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Xác nhận đơn hàng',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/top_notification.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/auth_provider.dart';

/// OrderHandoverDialog — Modal for staff/cashier to process order handover & payment upon scanning QR code.
class OrderHandoverDialog extends ConsumerStatefulWidget {
  final String orderId;

  const OrderHandoverDialog({
    super.key,
    required this.orderId,
  });

  static Future<void> show(BuildContext context, String orderId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OrderHandoverDialog(orderId: orderId),
    );
  }

  @override
  ConsumerState<OrderHandoverDialog> createState() => _OrderHandoverDialogState();
}

class _OrderHandoverDialogState extends ConsumerState<OrderHandoverDialog> {
  bool _isSubmitting = false;
  String _selectedPaymentMethod = 'Tiền mặt'; // 'Tiền mặt' or 'Chuyển khoản'

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
    final staffBranchId = ref.watch(currentUserProvider)?.branchId;

    final order = allOrders.firstWhere(
      (o) => o.id.toLowerCase() == widget.orderId.toLowerCase() ||
             (o.orderNumber.isNotEmpty && o.orderNumber.toLowerCase() == widget.orderId.toLowerCase()) ||
             (o.id.length >= 8 && widget.orderId.length >= 8 && o.id.substring(0, 8).toLowerCase() == widget.orderId.substring(0, 8).toLowerCase()),
      orElse: () => MockOrder(
        id: widget.orderId,
        storeName: 'Chi nhánh hiện tại',
        items: [],
        totalAmount: 0,
        status: MockOrderStatus.ready,
        orderTime: DateTime.now(),
        pickupTime: DateTime.now(),
        originalMinutes: 15,
        timeline: [],
        paymentStatus: 'Pending',
        orderType: 'Online',
      ),
    );

    // Check branch scope mismatch
    final isBranchMismatch = staffBranchId != null &&
        staffBranchId.isNotEmpty &&
        order.branchId.isNotEmpty &&
        order.branchId.toLowerCase() != staffBranchId.toLowerCase();

    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final shortCode = order.orderNumber.isNotEmpty
        ? order.orderNumber
        : (order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Title ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'XÁC NHẬN GIAO ĐƠN HÀNG',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Mã đơn: #$shortCode',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // ─── Branch Scope Mismatch Warning ───────────────────────────────
            if (isBranchMismatch) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'ĐƠN HÀNG THUỘC CHI NHÁNH KHÁC',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đơn hàng này được tạo tại "${order.storeName}". Vui lòng hướng dẫn khách hàng đến đúng chi nhánh để nhận món.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              // ─── Order Status & Payment Badges ─────────────────────────────
              Row(
                children: [
                  _buildBadge(
                    label: order.isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                    color: order.isPaid ? Colors.green : Colors.red,
                    bgColor: order.isPaid ? Colors.green.shade50 : Colors.red.shade50,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    label: order.orderType.isNotEmpty ? order.orderType : 'Takeaway',
                    color: AppColors.primary,
                    bgColor: AppColors.primaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ─── Order Items List Scroll ───────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ListView.separated(
                    itemCount: order.items.isEmpty ? 1 : order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      if (order.items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Chi tiết đơn hàng đang cập nhật...',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        );
                      }
                      final item = order.items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (item.extras != null && item.extras!.isNotEmpty)
                                  Text(
                                    item.extras!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${currencyFormat.format(item.price * item.quantity)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ─── Total Amount ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TỔNG TIỀN ĐƠN HÀNG',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      '${currencyFormat.format(order.totalAmount)}đ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Payment Selection (If Unpaid) ─────────────────────────────
              if (!order.isPaid) ...[
                const Text(
                  'Phương thức thu tiền tại quầy:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPaymentMethod = 'Tiền mặt'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod == 'Tiền mặt' ? AppColors.primaryContainer : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedPaymentMethod == 'Tiền mặt' ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                size: 16,
                                color: _selectedPaymentMethod == 'Tiền mặt' ? AppColors.primary : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tiền mặt',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPaymentMethod == 'Tiền mặt' ? AppColors.primary : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPaymentMethod = 'Chuyển khoản'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod == 'Chuyển khoản' ? AppColors.primaryContainer : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedPaymentMethod == 'Chuyển khoản' ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 16,
                                color: _selectedPaymentMethod == 'Chuyển khoản' ? AppColors.primary : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'QR Chuyển khoản',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPaymentMethod == 'Chuyển khoản' ? AppColors.primary : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ─── Action Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          try {
                            // Update order status to completed via order notifier
                            await ref
                                .read(orderProvider.notifier)
                                .updateOrderStatus(order.id, MockOrderStatus.completed);

                            if (mounted) {
                              Navigator.pop(context);
                              TopNotification.showSuccess(
                                context,
                                message: 'Đã hoàn tất giao đơn #${shortCode} cho khách hàng thành công!',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                              TopNotification.showError(
                                context,
                                message: 'Lỗi giao đơn: ${e.toString()}',
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.isPaid ? Colors.green : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          order.isPaid ? 'XÁC NHẬN ĐÃ GIAO MÓN' : 'THU TIỀN & GIAO MÓN',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

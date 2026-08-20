import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../core/theme/app_colors.dart';

class PaidBillTicketCard extends StatelessWidget {
  final String orderId;
  final double amount;
  final String? storeName;
  final List<dynamic>? items;
  final String? orderStatus;
  final DateTime updatedAt;
  final VoidCallback onViewDetails;

  const PaidBillTicketCard({
    super.key,
    required this.orderId,
    required this.amount,
    this.storeName,
    this.items,
    this.orderStatus,
    required this.updatedAt,
    required this.onViewDetails,
  });

  String _formatPrice(double val) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '').format(val).trim();
  }

  Widget _buildOrderProgressTracker(String? statusStr) {
    final status = statusStr?.trim().toLowerCase() ?? 'pendingconfirmation';

    int currentStep = 0; // Default: Đã nhận đơn
    if (status.contains('prepar') || status == '2') {
      currentStep = 1; // Đang chế biến
    } else if (status.contains('ready') || status == '3') {
      currentStep = 2; // Chờ lấy
    } else if (status.contains('complet') || status == '4') {
      currentStep = 3; // Hoàn thành
    }

    final steps = [
      {'title': 'Đã nhận', 'icon': Icons.check_circle_outline_rounded},
      {'title': 'Chế biến', 'icon': Icons.soup_kitchen_rounded},
      {'title': 'Chờ lấy', 'icon': Icons.takeout_dining_rounded},
      {'title': 'Hoàn thành', 'icon': Icons.verified_rounded},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'TIẾN ĐỘ ĐƠN HÀNG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentStep;
              final isCurrent = index == currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 2.5,
                              color: index <= currentStep ? Colors.green : Colors.grey.shade300,
                            ),
                          ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.primary
                                : (isCompleted ? Colors.green.shade500 : Colors.white),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isCompleted ? Colors.green.shade500 : Colors.grey.shade300),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            steps[index]['icon'] as IconData,
                            size: 14,
                            color: (isCompleted || isCurrent) ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 2.5,
                              color: index < currentStep ? Colors.green : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index]['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.primary
                            : (isCompleted ? Colors.black87 : Colors.grey.shade500),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortOrderCode = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final timeStr = DateFormat('dd/MM HH:mm').format(updatedAt.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Status Banner ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                    SizedBox(width: 5),
                    Text(
                      'Đã đặt hàng & Thanh toán',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── QR Pickup Code Block ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD8CA)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'MÃ QR LẤY HÀNG TẠI QUÁN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: QrImageView(
                    data: 'ORDER_PICKUP_$orderId',
                    version: QrVersions.auto,
                    size: 150.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mã đơn: #$shortOrderCode',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shortOrderCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép mã đơn hàng: #$shortOrderCode'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Đưa mã QR này cho thu ngân khi tới quán để nhận món',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // ── Order Progress Tracker ─────────────────────────────────────────
          _buildOrderProgressTracker(orderStatus),
          const SizedBox(height: 10),

          // ── Store & Purchased Items Section ──────────────────────────────
          if (storeName != null && storeName!.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  storeName!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          if (items != null && items!.isNotEmpty) ...[
            ...items!.map((item) {
              if (item is! Map) return const SizedBox.shrink();
              final name = item['menu_item_name'] ?? item['name'] ?? 'Món ăn';
              final qty = item['quantity'] ?? 1;
              final price = (item['price'] as num?)?.toDouble() ?? 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$name x$qty',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (price > 0)
                      Text(
                        '${_formatPrice(price * qty)}đ',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // ── Metadata Rows (Exact user code specification) ────────────────
          const SizedBox(height: 6),
          _buildMetadataRow('Phương thức nhận hàng', 'Tự đến lấy tại quán'),
          const SizedBox(height: 8),
          _buildMetadataRow(
            'Phương thức thanh toán',
            'Quét mã QR (VietQR/PayOS)',
          ),
          const Divider(height: 24, color: AppColors.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_formatPrice(amount)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── View Order Details Action Button ──────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text(
                'Xem chi tiết đơn',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

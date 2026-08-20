import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../core/theme/app_colors.dart';

class OrderStatusNoticeCard extends StatelessWidget {
  final String orderId;
  final String status; // Backend OrderStatus Enum string
  final DateTime updatedAt;
  final String? qrCode;
  final double? amount;
  final VoidCallback onViewDetails;

  const OrderStatusNoticeCard({
    super.key,
    required this.orderId,
    required this.status,
    required this.updatedAt,
    this.qrCode,
    this.amount,
    required this.onViewDetails,
  });

  // Ánh xạ trạng thái sang UI
  Map<String, dynamic> _getStatusConfig() {
    switch (status) {
      case 'PAYMENT_SUCCESS':
        return {
          'title': 'Thanh toán thành công 🎉',
          'icon': Icons.check_circle,
          'color': Colors.green,
          'msg': 'Đơn hàng của bạn đã được thanh toán thành công và chuyển tới bếp chế biến!'
        };
      case 'PendingConfirmation':
        return {
          'title': 'Đang chờ xác nhận ⏳',
          'icon': Icons.hourglass_empty,
          'color': Colors.orange,
          'msg': '⏳ Quán đã nhận thông tin đơn và đang kiểm tra.'
        };
      case 'PendingInventory':
        return {
          'title': 'Kiểm tra kho 📦',
          'icon': Icons.inventory_2,
          'color': Colors.blueGrey,
          'msg': '📦 Quán đang kiểm tra kho nguyên liệu phục vụ đơn của bạn.'
        };
      case 'Preparing':
        return {
          'title': 'Bếp đang chế biến 👨‍🍳',
          'icon': Icons.soup_kitchen,
          'color': AppColors.primary,
          'msg': '👨‍🍳 Bếp đang chế biến món ăn của bạn.'
        };
      case 'ReadyForPickup':
        return {
          'title': 'Sẵn sàng nhận món! 🔔',
          'icon': Icons.notifications_active,
          'color': Colors.deepOrange,
          'msg': '🔔 Món ăn đã chuẩn bị xong! Mời bạn đến nhận món tại quầy.'
        };
      case 'Completed':
        return {
          'title': 'Đơn hàng hoàn thành 🎉',
          'icon': Icons.celebration,
          'color': Colors.purple,
          'msg': '🎉 Đơn hàng đã hoàn thành. Cảm ơn bạn!'
        };
      case 'Cancelled':
        return {
          'title': 'Đã hủy ❌',
          'icon': Icons.cancel,
          'color': Colors.grey,
          'msg': '❌ Đơn hàng đã được hủy.'
        };
      default:
        return {
          'title': 'Thông báo tiến trình đơn 📢',
          'icon': Icons.info_outline,
          'color': Colors.blue,
          'msg': 'Cập nhật trạng thái mới nhất cho đơn hàng của bạn.'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();
    final Color statusColor = config['color'] as Color;
    final shortOrderId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Assistant Notification Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'AI Notice',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd/MM HH:mm').format(updatedAt.toLocal()),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Status Header
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(config['icon'] as IconData, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã đơn: #$shortOrderId',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status message narrative
          Text(
            config['msg'] as String,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
          ),

          // Inline VietQR Payment Code Display (if present)
          if (qrCode != null && qrCode!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD8CA)),
              ),
              child: Column(
                children: [
                  const Text(
                    '💳 Mã QR Thanh Toán VietQR PayOS',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: QrImageView(
                      data: qrCode!,
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  if (amount != null && amount! > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Số tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // View Order Details / Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text(
                'Xem chi tiết đơn',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

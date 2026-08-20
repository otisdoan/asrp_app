import 'package:flutter/material.dart';
import '../../../../../core/utils/format_utils.dart';

/// Card hóa đơn mini inline trong chat — hiển thị kết quả
/// đặt hàng tạm tính do AI trả về.
class MiniInvoiceCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final VoidCallback? onOrder;

  const MiniInvoiceCard({
    super.key,
    required this.msg,
    this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final preview = msg['orderPreview'];
    final resolvedItems = msg['resolvedItems'] as List<dynamic>?;

    if (preview == null || resolvedItems == null || resolvedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final double subtotal = (preview['subtotal'] as num).toDouble();
    final double discount = (preview['discountAmount'] as num).toDouble();
    final double finalAmount = (preview['finalAmount'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECE2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: Color(0xFFEA580C), size: 18),
              SizedBox(width: 8),
              Text(
                'Chi tiết đơn hàng tạm tính',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFFF4F0), height: 1),
          const SizedBox(height: 12),

          // Item list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resolvedItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final item = resolvedItems[idx];
              final String size =
                  item['sizeLabel'] as String? ?? 'Size vừa';
              final List<dynamic> toppings =
                  item['toppingLabels'] as List<dynamic>? ?? [];
              final double price = (item['unitPrice'] as num).toDouble();
              final int qty = item['quantity'] as int;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${qty}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '$size${toppings.isNotEmpty ? " • ${toppings.join(", ")}" : ""}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    FormatUtils.formatCurrency(price * qty),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFFF4F0), height: 1),
          const SizedBox(height: 12),

          // Pricing rows
          _pricingRow('Tạm tính', subtotal, isTotal: false),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _discountRow(discount),
          ],
          const SizedBox(height: 8),
          _pricingRow('Tổng cộng', finalAmount, isTotal: true),
          const SizedBox(height: 16),

          // Confirm button
          if (onOrder != null)
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment_rounded,
                        size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Xác nhận đặt hàng & Thanh toán',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pricingRow(String label, double amount, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 13 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color:
                isTotal ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          FormatUtils.formatCurrency(amount),
          style: TextStyle(
            fontSize: isTotal ? 15 : 12,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.normal,
            color: isTotal
                ? const Color(0xFFEA580C)
                : const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _discountRow(double discount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Giảm giá',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(
          '-${FormatUtils.formatCurrency(discount)}',
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

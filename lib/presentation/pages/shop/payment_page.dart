import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/order_provider.dart';

/// Payment Page — shows payment options and recent transactions list loaded from real API.
/// Follows RULE: UI-only, uses AppColors, responsive.
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).fetchMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(orderProvider);
    
    // Flatten all payments across all orders and sort by date descending
    final List<Map<String, dynamic>> allPayments = [];
    for (var order in allOrders) {
      for (var payment in order.payments) {
        allPayments.add({
          'orderId': order.id,
          'storeName': order.storeName,
          'payment': payment,
        });
      }
    }
    allPayments.sort((a, b) {
      final dateA = (a['payment'] as MockPayment).date;
      final dateB = (b['payment'] as MockPayment).date;
      return dateB.compareTo(dateA);
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).fetchMyOrders(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Section (Purple gradient) ─────────────────
            _buildHeader(),

            // ─── Add Card Button ──────────────────────────────────
            _buildAddCardButton(),

            // ─── Recent Transactions ──────────────────────────────
            _buildRecentTransactions(allPayments),
          ],
        ),
      ),
    );
  }

  // ─── Purple Gradient Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryActive, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Title
            const Text(
              'Thanh toán',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thanh toán hằng ngày đơn giản,\nlinh hoạt',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Card — Thêm thẻ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.onPrimary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm thẻ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thanh toán không tiền mặt với thẻ tín dụng hoặ...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  // ─── Add Card Button ───────────────────────────────────────────────────
  Widget _buildAddCardButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Card',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recent Transactions ───────────────────────────────────────────────
  Widget _buildRecentTransactions(List<Map<String, dynamic>> transactions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 28, 12, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Giao dịch gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          if (transactions.isEmpty)
            // Empty state
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Không có hoạt động nào gần đây.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            // Real transactions list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outlineVariant),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final storeName = tx['storeName'] as String;
                final payment = tx['payment'] as MockPayment;
                
                IconData statusIcon = Icons.pending_outlined;
                Color statusColor = Colors.orange;
                if (payment.status == 'Đã thanh toán') {
                  statusIcon = Icons.check_circle_outline_rounded;
                  statusColor = Colors.green;
                } else if (payment.status == 'Thất bại') {
                  statusIcon = Icons.error_outline_rounded;
                  statusColor = Colors.red;
                } else if (payment.status == 'Đã hủy') {
                  statusIcon = Icons.cancel_outlined;
                  statusColor = Colors.grey;
                } else if (payment.status == 'Đã hoàn tiền') {
                  statusIcon = Icons.replay_rounded;
                  statusColor = Colors.blue;
                }

                final formattedDate = '${payment.date.day.toString().padLeft(2, '0')}/${payment.date.month.toString().padLeft(2, '0')} ${payment.date.hour.toString().padLeft(2, '0')}:${payment.date.minute.toString().padLeft(2, '0')}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Status Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName.split(' - ')[0],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${payment.method} · $formattedDate',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (payment.reference != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Mã GD: ${payment.reference}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatPrice(payment.amount)}đ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.status,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

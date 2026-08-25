import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';
import 'order_detail_page.dart';
import 'store_detail_page.dart';
import '../../widgets/shop/ai_recommended_grid_section.dart';

class OrderSuccessPage extends ConsumerWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background, // Light background
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Đặt hàng thành công',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Scrollable Content ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // ─── Success Confirmation Card ───────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 68,
                            color: AppColors.success, // Brand green success checkmark
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cảm ơn bạn đã đặt hàng!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Bạn sẽ nhận cập nhật trong phần thông báo ở hộp thư đến.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // View Order Button
                          SizedBox(
                            width: 220,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate directly to OrderDetailPage for this order
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailPage(orderId: orderId),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary, // Orange button
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Xem đơn hàng',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider line
                    Container(
                      height: 1,
                      color: AppColors.outlineVariant,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    const SizedBox(height: 20),

                    // ─── "Có thể bạn cũng thích" Section ──────────────────────
                    const AiRecommendedGridSection(
                      title: 'Có thể bạn cũng thích',
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'order_detail_page.dart';

/// OrderSuccessPage — Shown after successfully placing an order.
/// Displays confirmation message and a "You might also like" recommended store grid in light theme.
class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

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
    {
      'name': 'Bánh Mì Khói',
      'rating': 4.9,
      'distance': '0.5km',
      'time': '10 phút',
      'badge': 'Giảm 20%',
      'icon': Icons.lunch_dining
    },
    {
      'name': 'Gà Rán KFC',
      'rating': 4.5,
      'distance': '1.5km',
      'time': '25 phút',
      'badge': 'Giảm 30%',
      'icon': Icons.fastfood
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(height: 20),

                    // ─── "Có thể bạn cũng thích" Section ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
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
                          const SizedBox(height: 16),

                          // Two column store grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _suggestedStores.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) {
                              final store = _suggestedStores[index];
                              return _buildStoreCard(store);
                            },
                          ),
                        ],
                      ),
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
                  size: 36,
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                    const SizedBox(width: 2),
                    Text(
                      '${store['rating']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${store['distance']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    store['badge'] as String,
                    style: const TextStyle(
                      fontSize: 10,
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
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'order_status_page.dart';

/// Orders Page — shows order status categories and suggested stores.
/// Business: No delivery, customer picks up at store, QR payment.
/// Status flow: Chờ thanh toán → Chờ xác nhận → Chờ nhận đơn → Chờ đánh giá → Trả hàng
/// Follows RULE: UI-only, uses AppColors, responsive.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  // Order status categories
  static const _statusCategories = [
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Chờ thanh\ntoán', 'count': 0},
    {'icon': Icons.hourglass_top_rounded, 'label': 'Chờ xác\nnhận', 'count': 1},
    {'icon': Icons.takeout_dining_outlined, 'label': 'Chờ nhận\nđơn', 'count': 0},
    {'icon': Icons.rate_review_outlined, 'label': 'Chờ đánh\ngiá', 'count': 2},
    {'icon': Icons.replay_rounded, 'label': 'Trả hàng', 'count': 0},
  ];

  // Mock suggested stores (10 items for grid)
  static const _suggestedStores = [
    {'name': 'Hiên Coffee', 'rating': 4.7, 'distance': '0.3km', 'time': '15 phút', 'badge': 'Giảm 11%', 'icon': Icons.coffee},
    {'name': 'Trạm Cà Phê', 'rating': 5.0, 'distance': '0.3km', 'time': '22 phút', 'badge': 'Giảm 11%', 'icon': Icons.local_cafe},
    {'name': 'Cơm Tấm A Vũ', 'rating': 4.8, 'distance': '1.2km', 'time': '30 phút', 'badge': 'Giảm 15%', 'icon': Icons.rice_bowl},
    {'name': 'Phở Hà Nội', 'rating': 4.6, 'distance': '0.8km', 'time': '20 phút', 'badge': 'Giảm 10%', 'icon': Icons.ramen_dining},
    {'name': 'Bánh Mì Khói', 'rating': 4.9, 'distance': '0.5km', 'time': '10 phút', 'badge': 'Giảm 20%', 'icon': Icons.lunch_dining},
    {'name': 'Gà Rán KFC', 'rating': 4.5, 'distance': '1.5km', 'time': '25 phút', 'badge': 'Giảm 30%', 'icon': Icons.fastfood},
    {'name': 'Bún Bò Huế', 'rating': 4.7, 'distance': '2.0km', 'time': '35 phút', 'badge': 'Giảm 12%', 'icon': Icons.soup_kitchen},
    {'name': 'Trà Sữa ToCoToCo', 'rating': 4.4, 'distance': '0.6km', 'time': '12 phút', 'badge': 'Giảm 25%', 'icon': Icons.local_drink},
    {'name': 'Pizza Company', 'rating': 4.3, 'distance': '1.8km', 'time': '30 phút', 'badge': 'Giảm 18%', 'icon': Icons.local_pizza},
    {'name': 'Kem Bạch Đằng', 'rating': 4.6, 'distance': '0.9km', 'time': '15 phút', 'badge': 'Giảm 10%', 'icon': Icons.icecream},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Orange Header Area (covers status bar) ──────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryActive, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildStatusRow(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ─── Content ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Suggested stores grid
                _buildSuggestedStores(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đơn hàng',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đơn hàng của bạn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const OrderStatusPage(initialTabIndex: 0),
                  ));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem lịch sử',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: AppColors.onPrimary, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Status Icons Row ──────────────────────────────────────────────────
  Widget _buildStatusRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_statusCategories.length, (index) {
          final status = _statusCategories[index];
          return _buildStatusItem(
            context: context,
            icon: status['icon'] as IconData,
            label: status['label'] as String,
            count: status['count'] as int,
            tabIndex: index + 1, // +1 because tab 0 is "Tất cả"
          );
        }),
      ),
    );
  }

  Widget _buildStatusItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int count,
    required int tabIndex,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OrderStatusPage(initialTabIndex: tabIndex),
        ));
      },
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppColors.onPrimary),
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Suggested Stores (Grid 2 per row) ──────────────────────────────────
  Widget _buildSuggestedStores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Có thể bạn cũng thích',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_suggestedStores.length, (index) {
            final store = _suggestedStores[index];
            return _buildStoreGridCard(store);
          }),
        ),
      ],
    );
  }

  Widget _buildStoreGridCard(Map<String, dynamic> store) {
    final screenWidth = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final cardWidth = (screenWidth - 32 - 12) / 2; // 16 padding each side + 12 gap

    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Container(
                width: double.infinity,
                height: 100,
                color: AppColors.bgWarm,
                child: Icon(
                  store['icon'] as IconData,
                  size: 36,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        '${store['rating']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${store['distance']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${store['time']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      store['badge'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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
}

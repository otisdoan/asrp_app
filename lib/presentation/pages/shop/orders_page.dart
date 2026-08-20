import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/order_provider.dart';
import 'order_status_page.dart';
import '../../widgets/common/you_may_also_like_section.dart';

/// Orders Page — shows order status categories and suggested stores.
/// Business: No delivery, customer picks up at store, QR payment.
/// Status flow: Chờ thanh toán → Chờ xác nhận → Chờ nhận đơn → Chờ đánh giá → Trả hàng
/// Follows RULE: UI-only, uses AppColors, responsive.
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
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

    // Tính toán số đơn thực tế từ provider dựa trên business mapping
    final pendingPaymentCount = allOrders
        .where((o) =>
            o.status == MockOrderStatus.pendingConfirm &&
            !o.isPaid &&
            o.isQrPayment)
        .length;
    final pendingConfirmCount = allOrders
        .where((o) =>
            o.status == MockOrderStatus.pendingConfirm &&
            (o.isPaid || !o.isQrPayment))
        .length;
    final preparingAndReadyCount = allOrders
        .where((o) =>
            o.status == MockOrderStatus.preparing ||
            o.status == MockOrderStatus.ready)
        .length;
    final completedCount =
        allOrders.where((o) => o.status == MockOrderStatus.completed).length;
    final cancelledCount =
        allOrders.where((o) => o.status == MockOrderStatus.cancelled).length;

    final statusCategories = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Chờ thanh\ntoán',
        'count': pendingPaymentCount
      },
      {
        'icon': Icons.hourglass_top_rounded,
        'label': 'Chờ xác\nnhận',
        'count': pendingConfirmCount
      },
      {
        'icon': Icons.takeout_dining_outlined,
        'label': 'Chờ nhận\nđơn',
        'count': preparingAndReadyCount
      },
      {
        'icon': Icons.rate_review_outlined,
        'label': 'Chờ đánh\ngiá',
        'count': completedCount
      },
      {
        'icon': Icons.replay_rounded,
        'label': 'Trả hàng',
        'count': cancelledCount
      },
    ];

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
                _buildStatusRow(context, statusCategories),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ─── Content ─────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(orderProvider.notifier).fetchMyOrders(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OrderStatusPage(initialTabIndex: 0),
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
                    Icon(Icons.chevron_right,
                        color: AppColors.onPrimary, size: 18),
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
  Widget _buildStatusRow(
      BuildContext context, List<Map<String, dynamic>> categories) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(categories.length, (index) {
          final status = categories[index];
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
        Navigator.push(
            context,
            MaterialPageRoute(
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
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
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

  // ─── Suggested Dishes (Grid 3 per row) ──────────────────────────────────
  Widget _buildSuggestedStores() {
    return const YouMayAlsoLikeSection(
      subtitle: 'Gợi ý món ăn tối ưu theo khẩu vị & lịch sử của bạn',
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
    );
  }
}

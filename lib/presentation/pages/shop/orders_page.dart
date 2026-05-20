import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Orders Page — shows order status categories and order history.
/// Business: No delivery, customer picks up at store, QR payment.
/// Status flow: Chờ thanh toán → Chờ xác nhận → Chờ nhận đơn → Chờ đánh giá → Trả hàng
/// Follows RULE: UI-only, uses AppColors, responsive.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Order status categories
  static const _statusCategories = [
    {'icon': Icons.payment, 'label': 'Chờ thanh\ntoán', 'count': 0},
    {'icon': Icons.check_circle_outline, 'label': 'Chờ xác\nnhận', 'count': 1},
    {'icon': Icons.store_mall_directory_outlined, 'label': 'Chờ nhận\nđơn', 'count': 0},
    {'icon': Icons.star_border, 'label': 'Chờ đánh\ngiá', 'count': 2},
    {'icon': Icons.assignment_return_outlined, 'label': 'Trả hàng', 'count': 0},
  ];

  // Tab labels
  static const _tabs = ['Đang xử lý', 'Lịch sử', 'Đánh giá', 'Đơn nháp'];

  // Mock suggested stores
  static const _suggestedStores = [
    {
      'name': 'Hiên Coffee - 32 Hồ Văn Huê',
      'rating': 4.7,
      'distance': '0.3km',
      'time': '15 phút',
      'badge': 'Mã giảm 11%',
      'icon': Icons.coffee,
    },
    {
      'name': 'Trạm Cà Phê - 77 Nguyễn Diêu',
      'rating': 5.0,
      'distance': '0.3km',
      'time': '22 phút',
      'badge': 'Mã giảm 11%',
      'icon': Icons.local_cafe,
    },
    {
      'name': 'Cơm Tấm Sài Gòn - A Vũ',
      'rating': 4.8,
      'distance': '1.2km',
      'time': '30 phút',
      'badge': 'Mã giảm 15%',
      'icon': Icons.rice_bowl,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                _buildHeader(),
                _buildStatusRow(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ─── Tabs ────────────────────────────────────────────
        _buildTabs(),

        // ─── Tab Content ─────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveOrders(),
              _buildOrderHistory(),
              _buildReviews(),
              _buildDrafts(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Đơn hàng',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.onPrimary, size: 24),
          ),
        ],
      ),
    );
  }

  // ─── Status Icons Row ──────────────────────────────────────────────────
  Widget _buildStatusRow() {
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
            icon: status['icon'] as IconData,
            label: status['label'] as String,
            count: status['count'] as int,
          );
        }),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {},
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

  // ─── Tabs ──────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ─── Active Orders (Empty State) ───────────────────────────────────────
  Widget _buildActiveOrders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Empty state illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quên chưa đặt món rồi nè bạn ơi?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn sẽ nhìn thấy các món đang được chuẩn\nbị tại đây để kiểm tra đơn hàng nhanh hơn!',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Suggested stores
          _buildSuggestedStores(),
        ],
      ),
    );
  }

  // ─── Suggested Stores ──────────────────────────────────────────────────
  Widget _buildSuggestedStores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Có thể bạn cũng thích',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_suggestedStores.length, (index) {
          final store = _suggestedStores[index];
          return _buildSuggestedStoreItem(store);
        }),
      ],
    );
  }

  Widget _buildSuggestedStoreItem(Map<String, dynamic> store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          // Store image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              store['icon'] as IconData,
              size: 28,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          // Store info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.star),
                    const SizedBox(width: 3),
                    Text(
                      '${store['rating']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${store['distance']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${store['time']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    store['badge'] as String,
                    style: const TextStyle(
                      fontSize: 11,
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
    );
  }

  // ─── Order History ─────────────────────────────────────────────────────
  Widget _buildOrderHistory() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Chưa có lịch sử đơn hàng',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Reviews ───────────────────────────────────────────────────────────
  Widget _buildReviews() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Drafts ────────────────────────────────────────────────────────────
  Widget _buildDrafts() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drafts_outlined, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Chưa có đơn nháp nào',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

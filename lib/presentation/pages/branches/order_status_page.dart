import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Order Status Page — shows orders filtered by status.
/// Navigated to when tapping a status category on the Orders page.
/// Follows RULE: UI-only, uses AppColors, responsive.
class OrderStatusPage extends StatefulWidget {
  final int initialTabIndex;

  const OrderStatusPage({super.key, this.initialTabIndex = 0});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Tất cả', 'Chờ thanh toán', 'Chờ xác nhận', 'Chờ nhận đơn', 'Chờ đánh giá', 'Trả hàng'];

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
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Icon(Icons.search, size: 20, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm kiếm đơn hàng của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        titleSpacing: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) => _buildEmptyState()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Empty state
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Không có đơn hàng liên quan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bắt đầu khám phá và tìm sản phẩm bạn yêu thích',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Suggested stores
          _buildSuggestedStores(),
        ],
      ),
    );
  }

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
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_suggestedStores.length, (index) {
                final store = _suggestedStores[index];
                return _buildStoreGridCard(store, cardWidth);
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoreGridCard(Map<String, dynamic> store, double cardWidth) {
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

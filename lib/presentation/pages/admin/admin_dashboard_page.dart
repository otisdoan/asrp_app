import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

/// Admin Dashboard Page - Mobile layout with premium charts, metrics, and transaction details.
/// Follows RULE: UI-only widgets, AppColors 100%, high visual aesthetics.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  String _selectedTimeFilter =
      'Hôm nay'; // 'Hôm nay' | 'Tuần này' | 'Tháng này'
  int _selectedChartBarIndex = 4; // Default selection: Thứ 6
  int? _expandedTransactionIndex;

  // Mock revenue chart data per day for the current week
  final List<double> _weeklyRevenue = [
    18.2,
    22.4,
    19.8,
    25.6,
    32.8,
    45.2,
    38.5
  ]; // in million VND
  final List<String> _weeklyDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // Mock KPI data based on Time Filter
  Map<String, dynamic> get _stats {
    switch (_selectedTimeFilter) {
      case 'Tuần này':
        return {
          'revenue': '202,500,000đ',
          'growth': '+14.2%',
          'orders': '1,420 đơn',
          'avgBill': '142,600đ',
        };
      case 'Tháng này':
        return {
          'revenue': '842,900,000đ',
          'growth': '+18.5%',
          'orders': '5,890 đơn',
          'avgBill': '143,100đ',
        };
      case 'Hôm nay':
      default:
        return {
          'revenue': '32,800,000đ',
          'growth': '+12.4%',
          'orders': '234 đơn',
          'avgBill': '140,200đ',
        };
    }
  }

  // Mock transactions list
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'HD-9842',
      'time': '10:42 · Hôm nay',
      'total': 185000,
      'itemsCount': 3,
      'items': [
        {'name': 'Phở bò tái đặc biệt', 'qty': 2, 'price': 65000},
        {'name': 'Cà phê sữa đá Sài Gòn', 'qty': 1, 'price': 25000},
        {'name': 'Quẩy giòn rụm', 'qty': 2, 'price': 15000},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
    {
      'id': 'HD-9841',
      'time': '10:15 · Hôm nay',
      'total': 90000,
      'itemsCount': 2,
      'items': [
        {'name': 'Bún bò Huế giò heo', 'qty': 1, 'price': 55000},
        {'name': 'Trà đào cam sả', 'qty': 1, 'price': 29000},
        {'name': 'Khăn lạnh', 'qty': 2, 'price': 3000},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
    {
      'id': 'HD-9840',
      'time': '09:58 · Hôm nay',
      'total': 135000,
      'itemsCount': 2,
      'items': [
        {'name': 'Cơm tấm sườn bì chả', 'qty': 2, 'price': 55000},
        {'name': 'Nước ngọt Pepsi', 'qty': 2, 'price': 12500},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
    {
      'id': 'HD-9839',
      'time': '09:30 · Hôm nay',
      'total': 50000,
      'itemsCount': 1,
      'items': [
        {'name': 'Phở bò viên thập cẩm', 'qty': 1, 'price': 50000},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
  ];

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Đăng xuất tài khoản?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin không?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppConstants.routeLogin);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'Admin';
    final initialChar = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Sleek Gradient Header Section
              _buildHeader(displayName, initialChar),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 2. Interactive Time Filter Pill Row
                    _buildTimeFilterRow(),
                    const SizedBox(height: 18),

                    // 3. Metric KPI Cards Block
                    _buildKPISection(),
                    const SizedBox(height: 24),

                    // 4. Interactive custom Bar Chart
                    _buildInteractiveChartSection(),
                    const SizedBox(height: 24),

                    // 5. Best Seller share section
                    _buildBestSellersSection(),
                    const SizedBox(height: 24),

                    // 6. Recent transactions section with click-to-expand details
                    _buildRecentTransactionsSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Component Helpers ──────────────────────────────────────────────────

  Widget _buildHeader(String displayName, String initialChar) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary
          ], // Gradient thương hiệu chuẩn theo RULE_APP
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                // Quick Profile Navigate (Avatar)
                GestureDetector(
                  onTap: () => context.push(AppConstants.routeProfile),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        initialChar,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DineX Dashboard · Quản trị',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick POS/Cashier checks or Logout
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                  onPressed: _confirmLogout,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ['Hôm nay', 'Tuần này', 'Tháng này'].map((filter) {
          final isSelected = _selectedTimeFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKPISection() {
    final data = _stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        // KPI 1: Revenue
        _buildKPICard(
          title: 'Tổng doanh thu',
          value: data['revenue']!,
          icon: Icons.monetization_on_rounded,
          iconBg: AppColors.badgeBestBg,
          iconColor: AppColors.badgeBestText,
          growth: data['growth']!,
        ),
        // KPI 2: Orders
        _buildKPICard(
          title: 'Đơn hàng thành công',
          value: data['orders']!,
          icon: Icons.shopping_bag_rounded,
          iconBg: AppColors.successContainer,
          iconColor: AppColors.success,
          growth: '+5.4%',
        ),
        // KPI 3: Average Bill Value
        _buildKPICard(
          title: 'Trị giá trung bình bill',
          value: data['avgBill']!,
          icon: Icons.receipt_long_rounded,
          iconBg: AppColors.badgeNewBg,
          iconColor: AppColors.badgeNewText,
        ),
        // KPI 4: Active Users (mock static value)
        _buildKPICard(
          title: 'Khách hàng mới',
          value: '+45 khách',
          icon: Icons.people_alt_rounded,
          iconBg: AppColors.badgeHotBg,
          iconColor: AppColors.badgeHotText,
          growth: '+15.2%',
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? growth,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              if (growth != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    growth,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChartSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Doanh thu tuần này',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tổng: ${_weeklyRevenue.fold(0.0, (s, e) => s + e).toStringAsFixed(1)} Triệu',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Bar Chart Rendering
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyRevenue.length, (index) {
                final rev = _weeklyRevenue[index];
                final maxRev = _weeklyRevenue.reduce((a, b) => a > b ? a : b);
                final ratio = rev / maxRev;
                final isSelected = _selectedChartBarIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedChartBarIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Dynamic Tooltip above the selected bar
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${rev.toStringAsFixed(1)}M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Bar Container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 100 * ratio,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [AppColors.primary, AppColors.secondary]
                                  : [
                                      AppColors.primary.withValues(alpha: 0.15),
                                      AppColors.secondary
                                          .withValues(alpha: 0.15)
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Label
                        Text(
                          _weeklyDays[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // Highlights of Selected Day
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Doanh số ngày '),
                      TextSpan(
                        text:
                            'Thứ ${_selectedChartBarIndex + 2 == 8 ? 'Chủ Nhật' : _selectedChartBarIndex + 2}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      const TextSpan(text: ' đạt '),
                      TextSpan(
                        text:
                            '${(_weeklyRevenue[_selectedChartBarIndex] * 1000000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellersSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu mặt hàng bán chạy',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSellerProgressBar(
              'Phở bò đặc biệt tái chín', 0.42, '42%', AppColors.primary),
          _buildSellerProgressBar('Cơm sườn cốt lết nướng mật ong', 0.28, '28%',
              AppColors.secondary),
          _buildSellerProgressBar('Cà phê sữa đá pha phin Sài Gòn', 0.18, '18%',
              AppColors.tertiary),
          _buildSellerProgressBar(
              'Bún bò giò heo đặc sản Huế', 0.12, '12%', AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildSellerProgressBar(
      String name, double percentage, String label, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, color: barColor, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: AppColors.divider.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch hôm nay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Future route or snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Hiển thị bộ lọc nâng cao tất cả các giao dịch.')),
                );
              },
              child: const Text('Xem tất cả',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final trans = _transactions[index];
            final id = trans['id'] as String;
            final time = trans['time'] as String;
            final total = trans['total'] as int;
            final isExpanded = _expandedTransactionIndex == index;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey<String>(id),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedTransactionIndex = expanded ? index : null;
                    });
                  },
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.successContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 18),
                  ),
                  title: Row(
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(total / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    time,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: AppColors.divider, height: 1),
                          const SizedBox(height: 12),
                          const Text(
                            'Chi tiết đơn hàng:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...((trans['items'] as List).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['name']} x${item['qty']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '${((item['price'] * item['qty']) / 1000).toStringAsFixed(0)}k',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          })),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Nguồn đơn:',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Tại quầy mang đi',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

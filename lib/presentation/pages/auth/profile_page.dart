import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late ScrollController _scrollController;
  late ValueNotifier<double> _scrollOffsetNotifier;

  @override
  void initState() {
    super.initState();
    _scrollOffsetNotifier = ValueNotifier<double>(0.0);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffsetNotifier.value = _scrollController.offset;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = ref.watch(isAuthenticatedProvider);

    // Fallback if not logged in (though app bar filters, we add extra guard)
    if (!isLoggedIn || user == null) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa đăng nhập',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập để xem thông tin cá nhân và tích lũy điểm PhoXu hấp dẫn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppConstants.routeLogin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Đăng nhập ngay'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final Color iconColor = Colors.white;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // 1. Premium Gradient Header Section
                _buildHeader(context, user),

                // 2. Profile Details & Menu Actions
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overlapping Rewards Card inside Column with top transform or normal margin
                      _buildRewardsCard(context, user),
                      const SizedBox(height: 24),

                      // Special Promo Highlight for Birthdays
                      _buildBirthdayPromo(context),
                      const SizedBox(height: 24),

                      // Group 1: Loyalty & Savings (Ưu đãi & Tiết kiệm)
                      _buildSectionHeader('Ưu đãi & Tiết kiệm'),
                      _buildMenuItem(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Ví ưu đãi của tôi',
                        subtitle: '2 voucher giảm 15% đang khả dụng',
                        trailing: _buildBadge(
                            '2 mới', AppColors.primary, AppColors.bgSoft),
                        onTap: () {
                          _showSnackBar(context,
                              'Chức năng Ví ưu đãi đang được tích hợp.');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.wine_bar_outlined,
                        title: 'Thử thách nhận PhoXu',
                        subtitle: 'Ăn phở tích điểm, nhận quà cực to',
                        onTap: () {
                          _showSnackBar(context,
                              'Thử thách ăn Phở sắp ra mắt trong tháng này!');
                        },
                      ),
                      const SizedBox(height: 20),

                      // Group 2: Account & Utilities (Tài khoản & Tiện ích)
                      _buildSectionHeader('Tài khoản & Tiện ích'),
                      _buildMenuItem(
                        icon: Icons.favorite_border_rounded,
                        title: 'Món ăn yêu thích',
                        subtitle: 'Đặt nhanh tô Phở bò yêu quý của bạn',
                        onTap: () {
                          _showSnackBar(context, 'Danh sách món ăn yêu thích.');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.storefront_outlined,
                        title: 'Chi nhánh thường đặt',
                        subtitle: 'Quận 1 · Tầng 1 (Tự đến lấy)',
                        onTap: () {
                          _showSnackBar(context,
                              'Danh sách các chi nhánh của BMC Phở Express.');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.qr_code_scanner_outlined,
                        title: 'Phương thức thanh toán',
                        subtitle: 'Ví QR Code liên kết',
                        onTap: () {
                          _showSnackBar(
                              context, 'Quản lý phương thức thanh toán.');
                        },
                      ),
                      const SizedBox(height: 20),

                      // Group 3: App Settings (Cấu hình hệ thống)
                      _buildSectionHeader('Thiết lập & Cá nhân hóa'),
                      _buildMenuItem(
                        icon: Icons.psychology_outlined,
                        title: 'Khảo sát sở thích ăn uống',
                        subtitle:
                            'Cập nhật Onboarding để AI gợi ý món ăn chuẩn nhất',
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textTertiary),
                        onTap: () => context.push(AppConstants.routeOnboarding),
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Cài đặt thông báo',
                        onTap: () {
                          _showSnackBar(
                              context, 'Cài đặt nhận thông báo khuyến mãi.');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.language_rounded,
                        title: 'Ngôn ngữ',
                        trailing: const Text(
                          'Tiếng Việt',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        onTap: () {
                          _showSnackBar(
                              context, 'Ứng dụng hiện hỗ trợ Tiếng Việt.');
                        },
                      ),
                      const SizedBox(height: 20),

                      // Group 4: Special Admin / Staff controls (Hiển thị có điều kiện)
                      if (user.role == 'admin' ||
                          user.role == 'manager' ||
                          user.role == 'staff') ...[
                        _buildSectionHeader(
                            'Đặc quyền ${(user.role == 'admin' || user.role == 'manager') ? 'Quản lý' : 'Nhân viên'}'),
                        _buildMenuItem(
                          icon: Icons.point_of_sale_rounded,
                          title: 'Màn hình POS Nhân viên',
                          subtitle: 'Đặt món tại bàn cho khách chi nhánh',
                          onTap: () =>
                              context.push(AppConstants.routeStaffHome),
                        ),
                        if (user.role == 'admin' || user.role == 'manager')
                          _buildMenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Màn hình Cashier Thu ngân',
                            subtitle: 'Duyệt đơn hàng và quản lý doanh thu',
                            onTap: () =>
                                context.push(AppConstants.routeCashier),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // Group 5: Support (Hỗ trợ)
                      _buildSectionHeader('Hỗ trợ'),
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Trung tâm trợ giúp',
                        onTap: () {
                          _showSnackBar(context,
                              'Kết nối với bộ phận chăm sóc khách hàng.');
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.feedback_outlined,
                        title: 'Gửi ý kiến phản hồi',
                        onTap: () {
                          _showFeedbackDialog(context);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'Về BMC Phở Express',
                        subtitle: 'Phiên bản 1.0.0 (Smart Dining)',
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_rounded,
                              color: AppColors.primary, size: 18),
                          label: const Text(
                            'Đăng xuất tài khoản',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.primary, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: AppColors.bgSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Morphing AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffsetNotifier,
              builder: (context, scrollOffset, child) {
                final double scrollThresholdStart = 40.0;
                final double scrollThresholdEnd = 120.0;
                double opacity = 0.0;
                if (scrollOffset > scrollThresholdStart) {
                  opacity = ((scrollOffset - scrollThresholdStart) /
                          (scrollThresholdEnd - scrollThresholdStart))
                      .clamp(0.0, 1.0);
                }

                Widget titleWidget;
                if (opacity < 0.5) {
                  final double textOpacity =
                      (1.0 - (opacity * 2)).clamp(0.0, 1.0);
                  titleWidget = Text(
                    'Hồ sơ của tôi',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: textOpacity),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  final double textOpacity =
                      ((opacity - 0.5) * 2).clamp(0.0, 1.0);
                  titleWidget = Text(
                    user.displayName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: textOpacity),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                return Container(
                  height: statusBarHeight + 56,
                  padding: EdgeInsets.only(top: statusBarHeight),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: opacity),
                    boxShadow: opacity > 0.1
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.15 * opacity),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: iconColor, size: 20),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: titleWidget,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header UI Section ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, UserModel user) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final String initialChar = user.displayName.isNotEmpty
        ? user.displayName.trim().substring(0, 1).toUpperCase()
        : 'U';
    print('[Audit Avatar] ProfilePage render - user.avatar = ${user.avatar}');
    print(
        '[Audit Avatar] ProfilePage render - sẽ ${user.avatar != null && user.avatar!.isNotEmpty ? 'hiển thị ảnh' : 'fallback chữ cái đầu'}');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 64, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // User Avatar & Badges
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push(AppConstants.routeEditProfile),
                child: Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: (user.avatar != null && user.avatar!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                user.avatar!,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      initialChar,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                initialChar,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(user.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone ?? 'Chưa cập nhật SĐT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? 'Chưa cập nhật Email',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit profile button inside Header
          Align(
            alignment: Alignment.centerRight,
            child: IntrinsicWidth(
              child: GestureDetector(
                onTap: () => context.push(AppConstants.routeEditProfile),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Chỉnh sửa hồ sơ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Golden VIP Rewards Card ─────────────────────────────────────────────
  Widget _buildRewardsCard(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2E2E), Color(0xFF4A4A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFF3B844).withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3B844),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'BMC REWARDS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3B844).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFF3B844), width: 0.8),
                ),
                child: const Text(
                  'Hạng Vàng',
                  style: TextStyle(
                    color: Color(0xFFF5B63F),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Điểm tích lũy PhoXu',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 2),
          const Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                '150',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'PhoXu',
                style: TextStyle(
                  color: Color(0xFFF3B844),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tier Progress Bar
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            child: LinearProgressIndicator(
              value: 0.6,
              color: Color(0xFFF3B844),
              backgroundColor: Colors.white12,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Tích thêm 100 PhoXu để thăng hạng Bạch Kim',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showSnackBar(
                    context, 'Chức năng xem lịch sử giao dịch điểm.'),
                child: const Text(
                  'Xem lịch sử >',
                  style: TextStyle(
                    color: Color(0xFFF3B844),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Birthday Promo Badge ────────────────────────────────────────────────
  Widget _buildBirthdayPromo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cake_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ưu đãi mừng Sinh Nhật độc quyền!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nhận ngay voucher Giảm 15% vào tuần sinh nhật của bạn.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper UI Widgets ───────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Removed Clip.antiAlias to avoid Canvas.saveLayer offscreen rasterization bottlenecks during list scroll
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.bgSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    String label;
    if (role == 'admin' || role == 'manager') {
      badgeColor = const Color(0xFFF3B844);
      label = 'Quản lý';
    } else if (role == 'staff') {
      badgeColor = AppColors.secondary;
      label = 'Nhân viên';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded,
              color: Colors.white, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Feedback Dialog ─────────────────────────────────────────────────────
  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Gửi phản hồi cho chúng tôi',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ý kiến đóng góp của bạn sẽ giúp BMC Phở Express cải thiện chất lượng phục vụ ngày một tốt hơn.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung góp ý tại đây...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnackBar(context, 'Cảm ơn bạn đã đóng góp ý kiến phản hồi!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Gửi đi'),
          ),
        ],
      ),
    );
  }

  // ─── About Dialog ────────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BMC Phở Express',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nền tảng nhà hàng thông minh v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.outlineVariant, height: 1),
            const SizedBox(height: 16),
            const Text(
              'Hệ thống tích hợp đặt hàng trước tự đến lấy, thanh toán tại bàn bằng QR code và quản lý chuỗi phân quyền nhân viên/cashier ưu việt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirm Logout Dialog ───────────────────────────────────────────────
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          'Bạn có chắc chắn muốn đăng xuất khỏi phiên làm việc hiện tại không?',
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
              // Invoke logout notifier
              await ref.read(authProvider.notifier).logout();
              // Redirect to login using go_router
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
}

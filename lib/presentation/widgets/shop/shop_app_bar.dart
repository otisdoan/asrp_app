import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorite_shops_provider.dart';
import '../../../providers/branch_provider.dart';
import '../staff/staff_qr_scanner_dialog.dart';
import '../staff/order_handover_dialog.dart';
import 'customer_qr_scanner_dialog.dart';

class ShopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onChangeLocationTap;

  const ShopAppBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onChangeLocationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);
    final favoriteCount = ref.watch(favoriteShopsProvider).length;
    final userLocation = ref.watch(userLocationProvider);
    final userAddress = ref.watch(userAddressNameProvider);

    final initials = user != null && user.displayName.isNotEmpty
        ? user.displayName.trim().substring(0, 1).toUpperCase()
        : 'U';

    String locationText = 'Nhập địa chỉ giao hàng của bạn...';
    bool hasAddress = false;
    if (userAddress != null && userAddress.isNotEmpty) {
      locationText = userAddress;
      hasAddress = true;
    } else if (userLocation != null) {
      locationText = 'Đang tra cứu địa chỉ thực tế...';
    }

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      toolbarHeight: 92,
      title: Column(
        children: [
          // 0. Location Selector Bar (Top)
          GestureDetector(
            onTap: onChangeLocationTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Vị trí:',
                    style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasAddress ? 'Đổi địa chỉ' : 'Nhập địa chỉ',
                      style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Main Header Row
          Row(
            children: [
              // 1. Scanner Icon (Left)
              GestureDetector(
                onTap: () {
                  final role = user?.role.toLowerCase() ?? '';
                  if (role == 'staff' || role == 'manager' || role == 'admin') {
                    StaffQrScannerDialog.show(
                      context,
                      onOrderScanned: (orderId) {
                        OrderHandoverDialog.show(context, orderId);
                      },
                    );
                  } else {
                    CustomerQrScannerDialog.show(context);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.crop_free,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Search Bar (Center)
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: _AnimatedSearchPlaceholder(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 3. Red Heart Favorite Shops Button
              GestureDetector(
                onTap: () => context.push(AppConstants.routeFavoriteShops),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE24B4A), Color(0xFFFF2A55)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                    if (favoriteCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 15,
                            minHeight: 15,
                          ),
                          child: Center(
                            child: Text(
                              '$favoriteCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(
                  isLoggedIn ? AppConstants.routeProfile : AppConstants.routeLogin,
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: isLoggedIn
                        ? Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated Search Placeholder ─────────────────────────────────────────
class _AnimatedSearchPlaceholder extends ConsumerStatefulWidget {
  const _AnimatedSearchPlaceholder();

  @override
  ConsumerState<_AnimatedSearchPlaceholder> createState() => _AnimatedSearchPlaceholderState();
}

class _AnimatedSearchPlaceholderState extends ConsumerState<_AnimatedSearchPlaceholder>
    with SingleTickerProviderStateMixin {
  static const _hints = [
    'Phở bò tái nạm',
    'Cơm sườn nướng',
    'Trà sữa trân châu',
    'Bún bò Huế',
    'Gà rán giòn',
  ];

  int _currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _startCycling();
  }

  void _startCycling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (!mounted) return;

        final historyAsync = ref.read(searchHistoryProvider);
        final hints = historyAsync.maybeWhen(
          data: (list) => list.isNotEmpty ? list : _hints,
          orElse: () => _hints,
        );

        setState(() {
          _currentIndex = (_currentIndex + 1) % hints.length;
        });
        _controller.forward();
        _startCycling();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(searchHistoryProvider);
    final hints = historyAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : _hints,
      orElse: () => _hints,
    );

    final index = _currentIndex < hints.length ? _currentIndex : 0;

    return ClipRect(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Text(
            hints[index],
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w200,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

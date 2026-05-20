import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/shop/shop_app_bar.dart';
import '../../widgets/shop/promo_banner_section.dart';
import '../../widgets/shop/deals_section.dart';
import '../../widgets/shop/top_stores_section.dart';
import '../../widgets/shop/nearby_stores_section.dart';
import '../../widgets/shop/all_stores_section.dart';
import '../../widgets/shop/categories_section.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/shop_provider.dart';
import 'cart_page.dart';
import 'payment_page.dart';
import 'orders_page.dart';
import 'store_detail_page.dart';
import '../../../core/services/location_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Show location permission dialog after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionDialog();
    });
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cho phép ứng dụng truy cập vị trí để tìm cửa hàng gần bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Từ chối',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              LocationService.getCurrentAddress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text(
              'Cho phép',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductDetail(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(
          storeName: name,
          category: 'Quán ăn',
          rating: 4.8,
          reviews: 1240,
          deliveryTime: '25 phút',
          distance: '3.2 km',
          icon: Icons.restaurant,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Trang chủ'),
            _buildNavItem(
                1, Icons.account_balance_wallet_outlined, 'Thanh toán'),
            _buildNavItem(2, Icons.receipt_long_outlined, 'Đơn hàng'),
            _buildNavItem(3, Icons.chat_bubble_outline_rounded, 'Tin nhắn',
                badgeCount: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {int badgeCount = 0}) {
    final isSelected = _currentTabIndex == index;
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textSecondary;

    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(dynamic cart) {
    switch (_currentTabIndex) {
      case 1:
        return const PaymentPage();
      case 2:
        return const OrdersPage();
      case 3:
        // Placeholder for other tabs
        return const Center(
          child: Text(
            'Đang phát triển...',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        );
      default:
        return Column(children: [
          Expanded(
              child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Promo Banner
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                  child: const PromoBannerSection()),
              const SizedBox(height: 20),
              // Categories
              const CategoriesSection(),
              const SizedBox(height: 20),
              // Deals / Promotions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DealsSection(onItemTap: _openProductDetail),
              ),
              const SizedBox(height: 20),
              // Top Stores
              const TopStoresSection(),
              const SizedBox(height: 20),
              // Nearby Stores
              const NearbyStoresSection(),
              const SizedBox(height: 20),
              // All Stores
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const AllStoresSection()),
              const SizedBox(height: 100),
            ]),
          )),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null && !currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _currentTabIndex == 0
            ? ShopAppBar(
                searchController: _searchController,
                onSearchChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                  ref.read(menuCurrentPageProvider.notifier).state = 1;
                },
              )
            : null,
        body: _buildBody(cart),
        floatingActionButton: _currentTabIndex == 0 && !cart.isEmpty
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartPage()),
                ),
                backgroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF6B7280),
                      size: 26,
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error, // Red badge dot
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }
}

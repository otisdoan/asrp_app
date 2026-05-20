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
import '../../widgets/product/product_detail_sheet.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/shop_provider.dart';
import 'cart_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductDetail(String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(productName: name),
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
            _buildNavItem(2, Icons.receipt_long_outlined, 'Hoạt động'),
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
        appBar: ShopAppBar(
          searchController: _searchController,
          onSearchChanged: (query) {
            ref.read(searchQueryProvider.notifier).state = query;
            ref.read(menuCurrentPageProvider.notifier).state = 1;
          },
        ),
        body: Column(children: [
          // Main scrollable content
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
              // Deals / Promotions (Inspired by design reference)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DealsSection(onItemTap: _openProductDetail),
              ),
              const SizedBox(height: 20),
              // Top Stores (rating > 4.5)
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
        ]),
        floatingActionButton: !cart.isEmpty
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

import 'package:fe_asrp_app/presentation/widgets/branches/categories_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/branches/branches_app_bar.dart';
import '../../widgets/branches/home_bottom_navigation_bar.dart';
import '../../widgets/branches/home_tab_content.dart';
import '../../widgets/branches/location_permission_dialog.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/branches_provider.dart';
import 'cart_page.dart';
import 'payment_page.dart';
import 'orders_page.dart';
import 'branches_detail_page.dart';
import '../../../core/services/location_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLocation();
    });
  }

  Future<void> _handleLocation() async {
    const storage = FlutterSecureStorage();
    final locationAsked = await storage.read(key: 'location_asked');

    if (locationAsked == 'true') {
      // Already asked before → auto get location silently
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          print('[Location] Auto: ${position.latitude}, ${position.longitude}');
        }
      } catch (_) {}
    } else {
      // First time → show popup
      LocationPermissionDialog.show(context);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMenuItemDetail(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(storeId: '00000000-0000-0000-0000-000000000000',
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
        return HomeTabContent(onItemTap: _openMenuItemDetail);
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
        bottomNavigationBar: HomeBottomNavigationBar(
          currentTabIndex: _currentTabIndex,
          onTabTapped: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
        ),
      ),
    );
  }
}

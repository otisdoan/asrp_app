import 'package:fe_asrp_app/presentation/widgets/shop/categories_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/shop/shop_app_bar.dart';
import '../../widgets/shop/promo_banner_section.dart';
import '../../widgets/shop/deals_section.dart';
import '../../widgets/shop/top_stores_section.dart';
import '../../widgets/shop/nearby_stores_section.dart';
import '../../widgets/shop/all_stores_section.dart';
import '../../widgets/shop/ai_suggestions_section.dart';

import '../../../providers/cart_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ai_recommendation_provider.dart';
import '../../widgets/common/require_login_dialog.dart';
import 'cart_page.dart';
import 'payment_page.dart';
import 'orders_page.dart';
import 'store_detail_page.dart';
import 'chat_assistant_page.dart';
import '../../../core/services/location_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
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
    final savedAddress = await storage.read(key: 'user_address_text');
    final savedLat = await storage.read(key: 'user_lat');
    final savedLng = await storage.read(key: 'user_lng');

    if (savedLat != null && savedLng != null) {
      final lat = double.tryParse(savedLat);
      final lng = double.tryParse(savedLng);
      if (lat != null && lng != null && LocationService.isWithinVietnam(lat, lng)) {
        final pos = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        ref.read(userLocationProvider.notifier).state = pos;
        if (savedAddress != null && savedAddress.isNotEmpty) {
          ref.read(userAddressNameProvider.notifier).state = savedAddress;
        } else {
          LocationService.reverseGeocode(lat, lng).then((addr) {
            if (addr != null && mounted) {
              ref.read(userAddressNameProvider.notifier).state = addr;
            }
          });
        }
        return;
      }
    }

    final locationAsked = await storage.read(key: 'location_asked');
    if (locationAsked == 'true') {
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          ref.read(userLocationProvider.notifier).state = position;
          final realAddress = await LocationService.reverseGeocode(position.latitude, position.longitude);
          if (realAddress != null && mounted) {
            ref.read(userAddressNameProvider.notifier).state = realAddress;
          }
        }
      } catch (_) {}
    } else {
      _showLocationSelectionDialog();
    }
  }

  void _showLocationSelectionDialog() {
    final addressCtrl = TextEditingController(text: ref.read(userAddressNameProvider) ?? '');
    bool isGeocoding = false;
    String? geocodedResultText;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhập địa chỉ giao hàng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ưu tiên nhập địa chỉ thực tế để xác định GPS chuẩn 100%',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Option 1: Primary Manual Address Entry
                  const Text(
                    'Địa chỉ cụ thể của bạn *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      hintText: 'VD: 123 Nguyễn Huệ, Phường Bến Nghé, Quận 1...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary, size: 20),
                      suffixIcon: addressCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textTertiary),
                              onPressed: () {
                                addressCtrl.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),

                  if (geocodedResultText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              geocodedResultText!,
                              style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGeocoding
                          ? null
                          : () async {
                              final address = addressCtrl.text.trim();
                              if (address.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập địa chỉ cụ thể của bạn')),
                                );
                                return;
                              }
                              setDialogState(() {
                                isGeocoding = true;
                              });

                              final pos = await LocationService.geocodeAddress(address);
                              setDialogState(() {
                                isGeocoding = false;
                              });

                              if (pos != null) {
                                ref.read(userLocationProvider.notifier).state = pos;
                                ref.read(userAddressNameProvider.notifier).state = address;

                                const storage = FlutterSecureStorage();
                                await storage.write(key: 'location_asked', value: 'true');
                                await storage.write(key: 'user_address_text', value: address);
                                await storage.write(key: 'user_lat', value: pos.latitude.toString());
                                await storage.write(key: 'user_lng', value: pos.longitude.toString());

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã cập nhật địa chỉ giao hàng: $address'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                setDialogState(() {
                                  geocodedResultText = 'Không tự động tra được tọa độ cho chuỗi nhập này. Hệ thống sẽ áp dụng vị trí trung tâm địa bàn.';
                                });
                              }
                            },
                      icon: isGeocoding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        isGeocoding ? 'Đang tra cứu tọa độ GPS...' : 'Xác nhận địa chỉ này',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),

                  // Option 2: Automatic Reverse-Geocoded GPS Device Location
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            setDialogState(() {
                              isGeocoding = true;
                            });
                            const storage = FlutterSecureStorage();
                            await storage.write(key: 'location_asked', value: 'true');
                            try {
                              final pos = await LocationService.getCurrentPosition();
                              if (pos != null) {
                                ref.read(userLocationProvider.notifier).state = pos;
                                final realAddress = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
                                final displayAddr = realAddress ?? 'Quận 1, TP. Hồ Chí Minh';
                                ref.read(userAddressNameProvider.notifier).state = displayAddr;

                                await storage.write(key: 'user_address_text', value: displayAddr);
                                await storage.write(key: 'user_lat', value: pos.latitude.toString());
                                await storage.write(key: 'user_lng', value: pos.longitude.toString());
                              }
                            } catch (_) {} finally {
                              if (mounted) {
                                setDialogState(() {
                                  isGeocoding = false;
                                });
                                Navigator.pop(ctx);
                              }
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.textSecondary),
                          label: const Text(
                            'Tự động định vị vị trí hiện tại',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.outlineVariant),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(categoriesFutureProvider);
    ref.invalidate(branchesFutureProvider);
    ref.invalidate(recommendedBranchesProvider);
    ref.invalidate(myBrandBranchesFutureProvider);
    ref.invalidate(personalizedRecommendationsProvider);
    try {
      await Future.wait([
        ref.read(categoriesFutureProvider.future),
        ref.read(branchesFutureProvider.future),
      ]);
    } catch (e) {
      print('[HomePage] Refresh error: $e');
    }
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
      decoration: const BoxDecoration(
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
        if (index > 0) {
          final isLoggedIn = ref.read(isAuthenticatedProvider);
          if (!isLoggedIn) {
            RequireLoginDialog.show(
              context,
              message: index == 1
                  ? 'Vui lòng đăng nhập để sử dụng tính năng thanh toán & quản lý ví tiền.'
                  : (index == 2
                      ? 'Vui lòng đăng nhập để theo dõi và quản lý lịch sử đơn hàng của bạn.'
                      : 'Vui lòng đăng nhập để trò chuyện cùng Trợ lý AI DineX.'),
            );
            return;
          }
        }

        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatAssistantPage()),
          );
          return;
        }
        setState(() {
          _currentTabIndex = index;
        });
        if (index == 2) {
          ref.read(orderProvider.notifier).fetchMyOrders();
        }
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
        return const ChatAssistantPage();
      default:
        return Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo Banner
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 14, 8, 0),
                      child: PromoBannerSection(),
                    ),
                    const SizedBox(height: 12),
                    // Categories
                    const CategoriesSection(),
                    const SizedBox(height: 20),
                    // Deals / Promotions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DealsSection(onItemTap: _openProductDetail),
                    ),
                    const SizedBox(height: 12),
                    // AI Personalized Suggestions ("Được đề xuất cho bạn")
                    const AiSuggestionsSection(),
                    const SizedBox(height: 20),
                    // Top Stores
                    const TopStoresSection(),
                    const SizedBox(height: 20),
                    // Nearby Stores
                    const NearbyStoresSection(),
                    const SizedBox(height: 20),
                    // All Stores
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AllStoresSection(scrollController: _scrollController),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
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
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: _currentTabIndex == 0
            ? ShopAppBar(
                searchController: _searchController,
                onSearchChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                  ref.read(menuCurrentPageProvider.notifier).state = 1;
                },
                onChangeLocationTap: _showLocationSelectionDialog,
              )
            : null,
        body: _buildBody(cart),
        floatingActionButton: _currentTabIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  final isLoggedIn = ref.read(isAuthenticatedProvider);
                  if (!isLoggedIn) {
                    RequireLoginDialog.show(
                      context,
                      message: 'Vui lòng đăng nhập để xem và quản lý giỏ hàng của bạn.',
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
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
                          color: AppColors.error,
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

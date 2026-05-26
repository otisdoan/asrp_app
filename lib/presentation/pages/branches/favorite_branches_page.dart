import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/favorite_shops_provider.dart';
import 'branches_detail_page.dart';

class FavoriteShopsPage extends ConsumerWidget {
  const FavoriteShopsPage({super.key});

  static const List<Map<String, dynamic>> _allMockStores = [
    {
      'name': 'BMC Phở Express - Quận 1',
      'category': 'Phở · Bún · Cơm',
      'rating': 4.9,
      'reviews': 1240,
      'distance': '0.8 km',
      'time': '20 phút',
      'promo': 'Giảm 20% đơn từ 100K',
      'icon': Icons.restaurant,
    },
    {
      'name': 'Cơm Tấm Bụi Sài Gòn',
      'category': 'Cơm · Món Việt',
      'rating': 4.5,
      'reviews': 856,
      'distance': '0.3 km',
      'time': '15 phút',
      'promo': 'Freeship',
      'icon': Icons.rice_bowl,
    },
    {
      'name': 'Bún Đậu Mắm Tôm Hà Nội',
      'category': 'Bún · Đồ ăn vặt',
      'rating': 4.3,
      'reviews': 432,
      'distance': '0.5 km',
      'time': '18 phút',
      'promo': 'Giảm 15K đơn từ 80K',
      'icon': Icons.soup_kitchen,
    },
    {
      'name': 'Trà Sữa ToCoToCo - Lê Văn Sỹ',
      'category': 'Trà sữa · Đồ uống',
      'rating': 4.6,
      'reviews': 2100,
      'distance': '0.7 km',
      'time': '20 phút',
      'promo': 'Mua 1 tặng 1',
      'icon': Icons.local_drink,
    },
    {
      'name': 'Pizza Hut - Nguyễn Trãi',
      'category': 'Pizza · Gà rán',
      'rating': 4.4,
      'reviews': 1580,
      'distance': '1.0 km',
      'time': '25 phút',
      'promo': 'Giảm 50K đơn từ 200K',
      'icon': Icons.local_pizza,
    },
    {
      'name': 'Highlands Coffee - Pasteur',
      'category': 'Cà phê · Bánh ngọt',
      'rating': 4.5,
      'reviews': 3200,
      'distance': '1.2 km',
      'time': '28 phút',
      'promo': '',
      'icon': Icons.coffee,
    },
    {
      'name': 'Bánh Mì Huỳnh Hoa',
      'category': 'Bánh mì · Ăn sáng',
      'rating': 4.8,
      'reviews': 5600,
      'distance': '1.5 km',
      'time': '30 phút',
      'promo': 'Giảm 10K',
      'icon': Icons.breakfast_dining,
    },
    {
      'name': 'Phúc Long Coffee & Tea',
      'category': 'Cà phê · Trà',
      'rating': 4.4,
      'reviews': 4200,
      'distance': '0.9 km',
      'time': '22 phút',
      'promo': 'Freeship đơn từ 50K',
      'icon': Icons.local_cafe,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteNames = ref.watch(favoriteShopsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgMain, // Không dùng trắng tinh 100%
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Cửa hàng yêu thích',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: favoriteNames.isEmpty
          ? _buildEmptyState(context)
          : _buildListState(context, ref, favoriteNames),
    );
  }

  // ─── Trạng thái Trống (Empty State) ───────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trái tim lớn phát sáng
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.favorite,
                    size: 80,
                    color: Color(0xFFFF2A55),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Chưa có cửa hàng yêu thích',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hãy chạm vào biểu tượng Trái tim trên trang thông tin của quán ăn để lưu lại và tìm kiếm nhanh chóng bất kỳ lúc nào.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppConstants.routeHome),
                  icon: const Icon(Icons.explore_outlined, color: Colors.white, size: 20),
                  label: const Text(
                    'Khám phá quán ngon',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Trạng thái Danh sách (List State) ──────────────────────────────────────
  Widget _buildListState(BuildContext context, WidgetRef ref, List<String> favoriteNames) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: favoriteNames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final favoriteName = favoriteNames[index];
        final store = _allMockStores.firstWhere(
          (s) => s['name'] == favoriteName,
          orElse: () => {
            'name': favoriteName,
            'category': 'Món ăn ngon · Đồ uống',
            'rating': 4.5,
            'reviews': 150,
            'distance': '1.0 km',
            'time': '22 phút',
            'promo': 'Khuyến mãi đặc biệt',
            'icon': Icons.storefront,
          },
        );

        final String name = store['name'] as String;
        final String category = store['category'] as String;
        final double rating = store['rating'] as double;
        final int reviews = store['reviews'] as int;
        final String distance = store['distance'] as String;
        final String time = store['time'] as String;
        final String promo = store['promo'] as String;
        final IconData icon = store['icon'] as IconData;

        return _buildFavoriteStoreCard(
          context,
          ref,
          name: name,
          category: category,
          rating: rating,
          reviews: reviews,
          distance: distance,
          time: time,
          promo: promo,
          icon: icon,
        );
      },
    );
  }

  // ─── Thẻ cửa hàng yêu thích ────────────────────────────────────────────────
  Widget _buildFavoriteStoreCard(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required String category,
    required double rating,
    required int reviews,
    required String distance,
    required String time,
    required String promo,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailPage(storeId: '00000000-0000-0000-0000-000000000000',
              storeName: name,
              category: category,
              rating: rating,
              reviews: reviews,
              deliveryTime: time,
              distance: distance,
              icon: icon,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // Thẻ Card dùng màu trắng 100% để nổi bật trên nền nhạt
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh/Icon đại diện quán
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            // Thông tin quán
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Đánh giá + thời gian + khoảng cách
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        ' ($reviews+)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Flexible(
                        child: Text(
                          '$time · $distance',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Khuyến mãi nếu có
                  if (promo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.local_offer, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            promo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Nút xóa khỏi yêu thích nhanh
            IconButton(
              icon: const Icon(Icons.favorite, color: Color(0xFFFF2A55), size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                ref.read(favoriteShopsProvider.notifier).toggleFavorite(name);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "$name" khỏi danh sách yêu thích'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

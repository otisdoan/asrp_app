import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Tất cả quán" — vertical list with lazy loading (10 items at a time).
class AllStoresSection extends ConsumerStatefulWidget {
  const AllStoresSection({super.key});

  @override
  ConsumerState<AllStoresSection> createState() => _AllStoresSectionState();
}

class _AllStoresSectionState extends ConsumerState<AllStoresSection> {
  int _displayCount = 10;
  bool _isLoading = false;

  static const _stores = [
    {'name': 'BMC Phở Express - Quận 1', 'category': 'Phở · Bún · Cơm', 'rating': 4.9, 'reviews': 1240, 'distance': '0.8 km', 'time': '20 phút', 'promo': 'Giảm 20% đơn từ 100K', 'image': 'assets/images/pho.jpg'},
    {'name': 'Cơm Tấm Bụi Sài Gòn', 'category': 'Cơm · Món Việt', 'rating': 4.5, 'reviews': 856, 'distance': '0.3 km', 'time': '15 phút', 'promo': 'Freeship', 'image': 'assets/images/com.webp'},
    {'name': 'Bún Đậu Mắm Tôm Hà Nội', 'category': 'Bún · Đồ ăn vặt', 'rating': 4.3, 'reviews': 432, 'distance': '0.5 km', 'time': '18 phút', 'promo': 'Giảm 15K đơn từ 80K', 'image': 'assets/images/pho_bo.png'},
    {'name': 'Trà Sữa ToCoToCo - Lê Văn Sỹ', 'category': 'Trà sữa · Đồ uống', 'rating': 4.6, 'reviews': 2100, 'distance': '0.7 km', 'time': '20 phút', 'promo': 'Mua 1 tặng 1', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Pizza Hut - Nguyễn Trãi', 'category': 'Pizza · Gà rán', 'rating': 4.4, 'reviews': 1580, 'distance': '1.0 km', 'time': '25 phút', 'promo': 'Giảm 50K đơn từ 200K', 'image': 'assets/images/com.webp'},
    {'name': 'Highlands Coffee - Pasteur', 'category': 'Cà phê · Bánh ngọt', 'rating': 4.5, 'reviews': 3200, 'distance': '1.2 km', 'time': '28 phút', 'promo': '', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Bánh Mì Huỳnh Hoa', 'category': 'Bánh mì · Ăn sáng', 'rating': 4.8, 'reviews': 5600, 'distance': '1.5 km', 'time': '30 phút', 'promo': 'Giảm 10K', 'image': 'assets/images/com.webp'},
    {'name': 'Phúc Long Coffee & Tea', 'category': 'Cà phê · Trà', 'rating': 4.4, 'reviews': 4200, 'distance': '0.9 km', 'time': '22 phút', 'promo': 'Freeship đơn từ 50K', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Lẩu Hải Sản Biển Đông', 'category': 'Lẩu · Hải sản', 'rating': 4.2, 'reviews': 780, 'distance': '2.0 km', 'time': '35 phút', 'promo': 'Giảm 30% lẩu 2 người', 'image': 'assets/images/pho_bo.png'},
    {'name': 'Gà Rán KFC - Hai Bà Trưng', 'category': 'Gà rán · Fastfood', 'rating': 4.3, 'reviews': 2800, 'distance': '1.1 km', 'time': '25 phút', 'promo': 'Combo 99K', 'image': 'assets/images/com.webp'},
    {'name': 'Sushi Hokkaido - Đồng Khởi', 'category': 'Sushi · Nhật Bản', 'rating': 4.7, 'reviews': 920, 'distance': '1.8 km', 'time': '32 phút', 'promo': 'Giảm 20% set lunch', 'image': 'assets/images/pho.jpg'},
    {'name': 'Bò Né 3 Ngon - Quận 3', 'category': 'Bò né · Ăn sáng', 'rating': 4.5, 'reviews': 1100, 'distance': '1.3 km', 'time': '28 phút', 'promo': '', 'image': 'assets/images/pho_bo.png'},
    {'name': 'Quán Chay An Lạc', 'category': 'Chay · Healthy', 'rating': 4.6, 'reviews': 340, 'distance': '0.6 km', 'time': '18 phút', 'promo': 'Giảm 10% thứ 2', 'image': 'assets/images/com.webp'},
    {'name': 'Bánh Cuốn Thanh Trì', 'category': 'Bánh cuốn · Ăn sáng', 'rating': 4.4, 'reviews': 560, 'distance': '0.4 km', 'time': '15 phút', 'promo': 'Freeship', 'image': 'assets/images/pho.jpg'},
    {'name': 'Trà Đào Cam Sả - Phạm Ngũ Lão', 'category': 'Đồ uống · Trà', 'rating': 4.3, 'reviews': 1800, 'distance': '0.9 km', 'time': '20 phút', 'promo': 'Mua 2 giảm 15K', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Cơm Gà Xối Mỡ Tư Lý', 'category': 'Cơm · Gà', 'rating': 4.6, 'reviews': 2300, 'distance': '1.4 km', 'time': '28 phút', 'promo': 'Giảm 20K đơn từ 120K', 'image': 'assets/images/com.webp'},
    {'name': 'Bún Chả Hà Nội - Quận 1', 'category': 'Bún chả · Nem', 'rating': 4.5, 'reviews': 890, 'distance': '1.0 km', 'time': '24 phút', 'promo': '', 'image': 'assets/images/pho_bo.png'},
    {'name': 'The Coffee House - Nguyễn Du', 'category': 'Cà phê · Bánh', 'rating': 4.4, 'reviews': 3800, 'distance': '0.7 km', 'time': '20 phút', 'promo': 'Freeship đơn từ 40K', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Hủ Tiếu Nam Vang Liến Húa', 'category': 'Hủ tiếu · Mì', 'rating': 4.7, 'reviews': 1500, 'distance': '1.6 km', 'time': '30 phút', 'promo': 'Giảm 15K', 'image': 'assets/images/pho.jpg'},
    {'name': 'Gỏi Cuốn Bà Tám', 'category': 'Gỏi cuốn · Ăn vặt', 'rating': 4.3, 'reviews': 420, 'distance': '0.5 km', 'time': '16 phút', 'promo': 'Mua 5 tặng 1', 'image': 'assets/images/pho_bo.png'},
    {'name': 'Kem Bạch Đằng', 'category': 'Kem · Tráng miệng', 'rating': 4.5, 'reviews': 2600, 'distance': '1.2 km', 'time': '26 phút', 'promo': '', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Xôi Bắc - Chợ Bến Thành', 'category': 'Xôi · Ăn sáng', 'rating': 4.4, 'reviews': 780, 'distance': '0.8 km', 'time': '20 phút', 'promo': 'Giảm 5K', 'image': 'assets/images/com.webp'},
    {'name': 'Bánh Tráng Trộn Cô Ba', 'category': 'Ăn vặt · Snack', 'rating': 4.2, 'reviews': 1200, 'distance': '0.3 km', 'time': '12 phút', 'promo': 'Freeship', 'image': 'assets/images/pho.jpg'},
    {'name': 'Cháo Lòng Bà Út', 'category': 'Cháo · Ăn sáng', 'rating': 4.6, 'reviews': 650, 'distance': '0.6 km', 'time': '18 phút', 'promo': 'Giảm 10K đơn từ 50K', 'image': 'assets/images/pho_bo.png'},
    {'name': 'McDonald\'s - Bến Thành', 'category': 'Burger · Fastfood', 'rating': 4.3, 'reviews': 4500, 'distance': '1.0 km', 'time': '22 phút', 'promo': 'Combo 79K', 'image': 'assets/images/com.webp'},
    {'name': 'Lotteria - Lê Lợi', 'category': 'Gà rán · Burger', 'rating': 4.1, 'reviews': 2100, 'distance': '0.9 km', 'time': '20 phút', 'promo': 'Giảm 25K đơn từ 150K', 'image': 'assets/images/com.webp'},
    {'name': 'Chè Thái Bà Năm', 'category': 'Chè · Tráng miệng', 'rating': 4.5, 'reviews': 980, 'distance': '0.4 km', 'time': '14 phút', 'promo': '', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Mì Quảng Bà Mua', 'category': 'Mì Quảng · Món Trung', 'rating': 4.7, 'reviews': 1350, 'distance': '1.5 km', 'time': '30 phút', 'promo': 'Giảm 12K', 'image': 'assets/images/pho.jpg'},
    {'name': 'Cơm Niêu Sài Gòn', 'category': 'Cơm niêu · Món Việt', 'rating': 4.6, 'reviews': 870, 'distance': '2.2 km', 'time': '38 phút', 'promo': 'Giảm 30K đơn từ 200K', 'image': 'assets/images/com.webp'},
    {'name': 'Trà Sữa Gong Cha - Võ Văn Tần', 'category': 'Trà sữa · Đồ uống', 'rating': 4.4, 'reviews': 3100, 'distance': '1.1 km', 'time': '24 phút', 'promo': 'Mua 1 tặng 1 size M', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Bánh Xèo Mười Xiềm', 'category': 'Bánh xèo · Món Nam', 'rating': 4.8, 'reviews': 2200, 'distance': '1.7 km', 'time': '32 phút', 'promo': 'Giảm 15% cuối tuần', 'image': 'assets/images/pho.jpg'},
    {'name': 'Bò Kho Bà Hai', 'category': 'Bò kho · Bánh mì', 'rating': 4.5, 'reviews': 1600, 'distance': '0.8 km', 'time': '20 phút', 'promo': '', 'image': 'assets/images/pho_bo.png'},
    {'name': 'Dimsum Hồng Kông', 'category': 'Dimsum · Trung Hoa', 'rating': 4.6, 'reviews': 720, 'distance': '2.5 km', 'time': '40 phút', 'promo': 'Giảm 20% set 4 người', 'image': 'assets/images/pho.jpg'},
    {'name': 'Nước Ép Juice Plus', 'category': 'Nước ép · Healthy', 'rating': 4.3, 'reviews': 540, 'distance': '0.5 km', 'time': '15 phút', 'promo': 'Freeship', 'image': 'assets/images/tra_sua.jpg'},
    {'name': 'Phở 24 - Nguyễn Thiệp', 'category': 'Phở · Món Việt', 'rating': 4.4, 'reviews': 1900, 'distance': '1.3 km', 'time': '26 phút', 'promo': 'Giảm 10K đơn từ 80K', 'image': 'assets/images/pho.jpg'},
    {'name': 'Cà Phê Muối Huế - Quận 5', 'category': 'Cà phê · Đặc sản Huế', 'rating': 4.7, 'reviews': 680, 'distance': '1.8 km', 'time': '34 phút', 'promo': 'Giảm 8K ly thứ 2', 'image': 'assets/images/tra_sua.jpg'},
  ];

  void _loadMore(int totalCount) {
    if (_isLoading || _displayCount >= totalCount) return;
    setState(() => _isLoading = true);

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _displayCount = (_displayCount + 10).clamp(0, totalCount);
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesFutureProvider);

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return _buildContent(context, _stores.map((s) => BranchListItemModel(
            id: '',
            name: s['name'] as String,
            imageUrl: s['image'] as String,
            rating: s['rating'] as double,
            reviewsCount: s['reviews'] as int,
            distance: s['distance'] as String,
            deliveryTime: s['time'] as String,
            promo: s['promo'] as String,
            category: s['category'] as String,
          )).toList());
        }
        return _buildContent(context, branches);
      },
      loading: () => const _LoadingSection(),
      error: (err, stack) {
        print('[AllStoresSection] Lỗi tải chi nhánh: $err');
        return _buildContent(context, _stores.map((s) => BranchListItemModel(
          id: '',
          name: s['name'] as String,
          imageUrl: s['image'] as String,
          rating: s['rating'] as double,
          reviewsCount: s['reviews'] as int,
          distance: s['distance'] as String,
          deliveryTime: s['time'] as String,
          promo: s['promo'] as String,
          category: s['category'] as String,
        )).toList());
      },
    );
  }

  Widget _buildContent(BuildContext context, List<BranchListItemModel> branches) {
    final visibleStores = branches.take(_displayCount).toList();
    final hasMore = _displayCount < branches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text('', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Tất cả quán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${branches.length} quán',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Store list (vertical)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleStores.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: AppColors.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final store = visibleStores[index];
            final userLocation = ref.watch(userLocationProvider);

            // Calculate dynamic distance if user location is available
            String displayDistance = store.distance;
            print('[AllStoresSection] Branch: ${store.name}, lat: ${store.latitude}, lng: ${store.longitude}, userLocation: ${userLocation?.latitude}, ${userLocation?.longitude}');
            if (userLocation != null && store.latitude != null && store.longitude != null) {
              final meters = LocationService.distanceTo(
                userLocation.latitude,
                userLocation.longitude,
                store.latitude!,
                store.longitude!,
              );
              displayDistance = LocationService.formatDistance(meters);
              print('[AllStoresSection] Calculated distance: $displayDistance');
            } else if (displayDistance.isEmpty) {
              displayDistance = 'Gần đây';
            }

            // Fallback for empty deliveryTime
            String displayTime = store.deliveryTime;
            if (displayTime.isEmpty) {
              displayTime = '25 phút';
            }

            return _AllStoreCard(
              name: store.name,
              category: store.category ?? 'Đồ ăn · Đồ uống',
              rating: store.rating,
              reviews: store.reviewsCount ?? 100,
              distance: displayDistance,
              time: displayTime,
              promo: store.promo ?? '',
              image: store.imageUrl,
              icon: Icons.restaurant,
            );
          },
        ),
        // Load more / Loading indicator
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Center(
                    child: GestureDetector(
                      onTap: () => _loadMore(branches.length),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem thêm quán',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.expand_more, size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        // End of list indicator
        if (!hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Đã hiển thị tất cả quán 🎉',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AllStoreCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;
  final String time;
  final String promo;
  final String image;
  final IconData icon;

  const _AllStoreCard({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.time,
    required this.promo,
    required this.image,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => StoreDetailPage(
            storeName: name,
            category: category,
            rating: rating,
            reviews: reviews,
            deliveryTime: time,
            distance: distance,
            icon: icon,
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image.isNotEmpty
                    ? (image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => Icon(icon, size: 36, color: AppColors.textTertiary),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => Icon(icon, size: 36, color: AppColors.textTertiary),
                          ))
                    : Icon(icon, size: 36, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 12),
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Category
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rating + time + distance
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                  // Promo
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
          ],
        ),
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Top quán đỉnh trên 4.5" — horizontal scroll of top-rated store cards.
/// Wraps the entire section in a white rounded container with margins, preserving the original cards.
class TopStoresSection extends ConsumerWidget {
  const TopStoresSection({super.key});

  static const _stores = [
    {
      'name': 'Tiệm Trà Mơ - 52 Nguyễn Huệ',
      'tag': 'Quán Ngon',
      'rating': 4.8,
      'distance': '1.2 km',
      'time': '30 phút',
      'promo': 'Giảm 10.000đ · Giảm 8...',
      'discount': '56K',
      'image': 'assets/images/tra_sua.jpg',
      'adLabel': 'Quảng cáo',
    },
    {
      'name': 'Jollibee - Trần Hưng Đạo',
      'tag': '',
      'rating': 4.6,
      'distance': '4.6 km',
      'time': '34 phút trở lên',
      'promo': 'Giảm 10.000đ · Giảm 1...',
      'discount': '',
      'image': 'assets/images/com.webp',
      'adLabel': '',
    },
    {
      'name': 'Trà Sữa Happy Tea',
      'tag': '',
      'rating': 4.7,
      'distance': '2.1 km',
      'time': '27 phút',
      'promo': 'Giảm 11.000đ',
      'discount': '56K',
      'image': 'assets/images/tra_sua.jpg',
      'adLabel': 'Quảng cáo',
    },
    {
      'name': 'Phở Hà Nội - Lý Tự Trọng',
      'tag': 'Yêu thích',
      'rating': 4.9,
      'distance': '0.8 km',
      'time': '20 phút',
      'promo': 'Giảm 15.000đ · Freeship',
      'discount': '30K',
      'image': 'assets/images/pho.jpg',
      'adLabel': '',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesFutureProvider);

    return branchesAsync.when(
      data: (branches) {
        final topBranches = branches.where((b) => b.rating >= 4.5).toList();
        if (topBranches.isEmpty) {
          return _buildContent(
              context,
              ref,
              _stores
                  .map((s) => BranchListItemModel(
                        id: '',
                        name: s['name'] as String,
                        imageUrl: s['image'] as String,
                        rating: s['rating'] as double,
                        distance: s['distance'] as String,
                        deliveryTime: s['time'] as String,
                        promo: s['promo'] as String,
                        discount: s['discount'] as String,
                        tag: s['tag'] as String,
                        adLabel: s['adLabel'] as String,
                      ))
                  .toList());
        }
        return _buildContent(context, ref, topBranches);
      },
      loading: () => const _LoadingSection(),
      error: (err, stack) {
        print('[TopStoresSection] Lỗi tải chi nhánh: $err');
        return _buildContent(
            context,
            ref,
            _stores
                .map((s) => BranchListItemModel(
                      id: '',
                      name: s['name'] as String,
                      imageUrl: s['image'] as String,
                      rating: s['rating'] as double,
                      distance: s['distance'] as String,
                      deliveryTime: s['time'] as String,
                      promo: s['promo'] as String,
                      discount: s['discount'] as String,
                      tag: s['tag'] as String,
                      adLabel: s['adLabel'] as String,
                    ))
                .toList());
      },
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<BranchListItemModel> branches) {
    final userLocation = ref.watch(userLocationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12), // Align left and right margins
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top quán trên 4.5 sao',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE55333), // ShopeeFood Orange-Red
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Những quán ngon được đánh giá cao nhất',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/section-detail?type=top_rated&title=Top quán trên 4.5 sao'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Store cards
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: branches.length > 6 ? 6 : branches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final branch = branches[index];

                // Calculate dynamic distance if user location is available
                String displayDistance = branch.distance;
                if (userLocation != null &&
                    branch.latitude != null &&
                    branch.longitude != null) {
                  final meters = LocationService.distanceTo(
                    userLocation.latitude,
                    userLocation.longitude,
                    branch.latitude!,
                    branch.longitude!,
                  );
                  displayDistance = LocationService.formatDistance(meters);
                } else if (displayDistance.isEmpty) {
                  displayDistance = 'Gần đây';
                }

                // Fallback for empty deliveryTime
                String displayTime = branch.deliveryTime;
                if (displayTime.isEmpty) {
                  displayTime = '25 phút';
                }

                return _StoreCard(
                  name: branch.name,
                  tag: branch.tag ?? '',
                  rating: branch.rating,
                  distance: displayDistance,
                  time: displayTime,
                  promo: branch.promo ?? '',
                  discount: branch.discount ?? '',
                  image: branch.imageUrl,
                  adLabel: branch.adLabel ?? '',
                  branchId: branch.id,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final String name;
  final String tag;
  final double rating;
  final String distance;
  final String time;
  final String promo;
  final String discount;
  final String image;
  final String adLabel;
  final String? branchId;

  const _StoreCard({
    required this.name,
    required this.tag,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.discount,
    required this.image,
    required this.adLabel,
    this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailPage(
                storeName: name,
                category: 'Đồ ăn · Đồ uống',
                rating: rating,
                reviews: 100,
                deliveryTime: time,
                distance: distance,
                icon: Icons.store,
                branchId: branchId,
              ),
            ));
      },
      child: SizedBox(
        width: 135,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: AppColors.bgWarm,
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 110,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.store,
                                  color: AppColors.textTertiary, size: 30),
                            ),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 110,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.store,
                                  color: AppColors.textTertiary, size: 30),
                            ),
                          ),
                  ),
                ),
                // Tag badge (top-left)
                if (tag.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Discount badge (bottom-right)
                if (discount.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Ưu đãi\n',
                            style: TextStyle(
                                fontSize: 8, color: Colors.white, height: 1),
                          ),
                          Text(
                            discount,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo line
                    if (promo.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.local_offer,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              promo,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Store name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Bottom info: ad label · time · distance
                    Row(
                      children: [
                        if (adLabel.isNotEmpty) ...[
                          Text(
                            adLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const Text(' · ',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textTertiary)),
                        ],
                        Flexible(
                          child: Text(
                            '$time · $distance',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

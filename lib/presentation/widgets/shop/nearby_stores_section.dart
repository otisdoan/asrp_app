import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Gần bạn" — horizontal scroll of nearby store cards.
class NearbyStoresSection extends ConsumerWidget {
  const NearbyStoresSection({super.key});

  static const _stores = [
    {
      'name': 'Cơm Tấm Bụi Sài Gòn',
      'rating': 4.5,
      'distance': '0.3 km',
      'time': '15 phút',
      'promo': 'Freeship',
      'image': 'assets/images/com.webp',
    },
    {
      'name': 'Bún Đậu Mắm Tôm Hà Nội',
      'rating': 4.3,
      'distance': '0.5 km',
      'time': '18 phút',
      'promo': 'Giảm 20%',
      'image': 'assets/images/pho_bo.png',
    },
    {
      'name': 'Trà Sữa ToCoToCo',
      'rating': 4.6,
      'distance': '0.7 km',
      'time': '20 phút',
      'promo': 'Mua 1 tặng 1',
      'image': 'assets/images/tra_sua.jpg',
    },
    {
      'name': 'Pizza Hut - Nguyễn Trãi',
      'rating': 4.4,
      'distance': '1.0 km',
      'time': '25 phút',
      'promo': 'Giảm 50K',
      'image': 'assets/images/pho.jpg',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesFutureProvider);

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return _buildContent(context, ref, _stores.map((s) => BranchListItemModel(
            id: '',
            name: s['name'] as String,
            imageUrl: s['image'] as String,
            rating: s['rating'] as double,
            distance: s['distance'] as String,
            deliveryTime: s['time'] as String,
            promo: s['promo'] as String,
          )).toList());
        }
        return _buildContent(context, ref, branches);
      },
      loading: () => const _LoadingSection(),
      error: (err, stack) {
        print('[NearbyStoresSection] Lỗi tải chi nhánh: $err');
        return _buildContent(context, ref, _stores.map((s) => BranchListItemModel(
          id: '',
          name: s['name'] as String,
          imageUrl: s['image'] as String,
          rating: s['rating'] as double,
          distance: s['distance'] as String,
          deliveryTime: s['time'] as String,
          promo: s['promo'] as String,
        )).toList());
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<BranchListItemModel> branches) {
    final userLocation = ref.watch(userLocationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Gần bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Xem thêm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Store cards
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final branch = branches[index];

              // Calculate dynamic distance if user location is available
              String displayDistance = branch.distance;
              if (userLocation != null && branch.latitude != null && branch.longitude != null) {
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

              // Fallback for empty promo
              String displayPromo = branch.promo ?? '';
              if (displayPromo.isEmpty) {
                final fallbacks = ['Freeship', 'Giảm 20%', 'Mua 1 tặng 1', 'Giảm 50K'];
                displayPromo = fallbacks[index % fallbacks.length];
              }

              return _NearbyStoreCard(
                name: branch.name,
                rating: branch.rating,
                distance: displayDistance,
                time: displayTime,
                promo: displayPromo,
                image: branch.imageUrl,
                branchId: branch.id,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NearbyStoreCard extends StatelessWidget {
  final String name;
  final double rating;
  final String distance;
  final String time;
  final String promo;
  final String image;
  final String? branchId;

  const _NearbyStoreCard({
    required this.name,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.image,
    this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
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
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Container(
                height: 110,
                width: double.infinity,
                color: AppColors.bgSoft,
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 110,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.store, color: AppColors.textTertiary, size: 24),
                        ),
                      )
                    : Image.asset(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 110,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.store, color: AppColors.textTertiary, size: 24),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo line
                    if (promo.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.local_offer, size: 12, color: AppColors.primary),
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
                    const Spacer(),
                    // Rating + distance
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
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
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 150,
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

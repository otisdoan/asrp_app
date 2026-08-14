import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Gần bạn" — horizontal scroll of nearby store cards.
class NearbyStoresSection extends ConsumerWidget {
  const NearbyStoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesFutureProvider);

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContent(context, ref, branches);
      },
      loading: () => const _LoadingSection(),
      error: (err, stack) {
        print('[NearbyStoresSection] Lỗi tải chi nhánh: $err');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<BranchListItemModel> branches) {
    final userLocation = ref.watch(userLocationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                      'Gần bạn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE55333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Các quán ăn gần vị trí của bạn nhất',
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
                onTap: () => context.push('/section-detail?type=nearby&title=Gần bạn'),
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

                // Calculate 100% exact branch distance
                final displayDistance = LocationService.calculateBranchDistance(
                  userLocation: userLocation,
                  branchLat: branch.latitude,
                  branchLng: branch.longitude,
                  branchAddress: branch.address,
                  fallbackDistance: branch.distance,
                );

                // Dynamic estimated delivery time based on distance
                final displayTime = LocationService.calculateDeliveryTime(
                  deliveryTime: branch.deliveryTime,
                  distanceStr: displayDistance,
                );

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
                  status: branch.status,
                  isActive: branch.isActive,
                );
              },
            ),
          ),
        ],
      ),
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
  final String? status;
  final bool? isActive;

  const _NearbyStoreCard({
    required this.name,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.image,
    this.branchId,
    this.status,
    this.isActive,
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
            imageUrl: image,
          ),
        ));
      },
      child: SizedBox(
        width: 135,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (status?.toLowerCase() == 'busy')
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7EC),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Quán bận',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                          )
                        else if (isActive == false || status?.toLowerCase() == 'closed')
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Tạm đóng',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.error),
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Đang bán',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/branches/branches_detail_page.dart';
import '../../../providers/branches/branch_provider.dart';

/// Section "Gần bạn" — horizontal scroll of nearby store cards.
class NearbyStoresSection extends ConsumerWidget {
  const NearbyStoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNearby = ref.watch(nearbyBranchListProvider);

    return asyncNearby.when(
      data: (branches) {
        if (branches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📍', style: TextStyle(fontSize: 18)),
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
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: branches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final store = branches[index];
                  return _NearbyStoreCard(
                    id: store.id,
                    name: store.name,
                    rating: store.rating,
                    distance: store.distance,
                    time: store.deliveryTime,
                    promo: store.promo ?? '',
                    imageUrl: store.imageUrl,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _NearbyStoreCard extends StatelessWidget {
  final String id;
  final String name;
  final double rating;
  final String distance;
  final String time;
  final String promo;
  final String imageUrl;

  const _NearbyStoreCard({
    required this.id,
    required this.name,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => StoreDetailPage(
            storeId: id,
            storeName: name,
            category: 'Gần bạn',
            rating: rating,
            reviews: 100, // mock
            deliveryTime: time,
            distance: distance,
            icon: Icons.store,
          ),
        ));
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with promo tag
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: AppColors.bgWarm,
                  child: imageUrl.isNotEmpty && !imageUrl.startsWith('http')
                      ? Image.asset(imageUrl, fit: BoxFit.cover)
                      : imageUrl.isNotEmpty && imageUrl.startsWith('http')
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.store, size: 30, color: AppColors.textTertiary),
                ),
                if (promo.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        promo,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      Expanded(
                        child: Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

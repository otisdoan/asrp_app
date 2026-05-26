import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/branches/branches_detail_page.dart';
import '../../../providers/branches/branch_provider.dart';

/// Section "Gần bạn" - horizontal scroll of nearby store cards.
class NearbyStoresSection extends ConsumerWidget {
  const NearbyStoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Switch back to nearbyBranchListProvider when real location is ready.
    final asyncNearby = ref.watch(branchListProvider);

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
                    category: store.category ?? 'Ẩm thực',
                    rating: store.rating,
                    reviewsCount: store.reviewsCount ?? 0,
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _NearbyStoreCard extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewsCount;
  final String distance;
  final String time;
  final String promo;
  final String imageUrl;

  const _NearbyStoreCard({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.distance,
    required this.time,
    required this.promo,
    required this.imageUrl,
  });

  String get _offerLabel {
    if (promo.trim().isNotEmpty) return promo.trim();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final offerLabel = _offerLabel;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailPage(
              storeId: id,
              storeName: name,
              category: category,
              rating: rating,
              reviews: reviewsCount,
              deliveryTime: time,
              distance: distance,
              icon: Icons.store,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
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
                          : const Icon(
                              Icons.store,
                              size: 30,
                              color: AppColors.textTertiary,
                            ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
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
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
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
                    const Spacer(),
                    if (offerLabel.isNotEmpty)
                      _OfferChip(label: offerLabel),
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

class _OfferChip extends StatelessWidget {
  final String label;

  const _OfferChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E7E1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC05C3B),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

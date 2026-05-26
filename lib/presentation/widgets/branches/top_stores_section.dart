import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/branches/branches_detail_page.dart';
import '../../../providers/branches/branch_provider.dart';

/// Section "Top quán đánh giá trên 4.5" — horizontal scroll of store cards.
class TopStoresSection extends ConsumerWidget {
  const TopStoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBranches = ref.watch(branchListProvider);

    return asyncBranches.when(
      data: (branches) {
        // Filter for top branches rating >= 4.5 (or just take top 10 if none are >= 4.5 for demo)
        var topBranches = branches.where((b) => b.rating >= 4.5).toList();
        if (topBranches.isEmpty) {
          topBranches = branches.take(5).toList();
        }
        
        if (topBranches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Top quán đánh giá trên 4.5',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topBranches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final store = topBranches[index];
                  return _TopStoreCard(
                    id: store.id,
                    name: store.name,
                    tag: store.tag ?? 'Quán Ngon',
                    rating: store.rating,
                    distance: store.distance,
                    time: store.deliveryTime,
                    promo: store.promo ?? '',
                    discount: store.discount ?? '',
                    imageUrl: store.imageUrl,
                    adLabel: store.adLabel ?? '',
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

class _TopStoreCard extends StatelessWidget {
  final String id;
  final String name;
  final String tag;
  final double rating;
  final String distance;
  final String time;
  final String promo;
  final String discount;
  final String imageUrl;
  final String adLabel;

  const _TopStoreCard({
    required this.id,
    required this.name,
    required this.tag,
    required this.rating,
    required this.distance,
    required this.time,
    required this.promo,
    required this.discount,
    required this.imageUrl,
    required this.adLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => StoreDetailPage(
            storeId: id,
            storeName: name,
            category: 'Top Quán',
            rating: rating,
            reviews: 500, // mock
            deliveryTime: time,
            distance: distance,
            icon: Icons.star,
          ),
        ));
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: AppColors.bgWarm,
                  child: imageUrl.isNotEmpty && !imageUrl.startsWith('http')
                      ? Image.asset(imageUrl, fit: BoxFit.cover)
                      : imageUrl.isNotEmpty && imageUrl.startsWith('http')
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.restaurant, size: 40, color: AppColors.textTertiary),
                ),
                // Ad Label
                if (adLabel.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        adLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Heart icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  if (tag.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Rating & Distance
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Promo Text
                  if (promo.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_offer, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            promo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

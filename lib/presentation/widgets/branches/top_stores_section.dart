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
                    category: store.category ?? 'Ẩm thực',
                    reviewsCount: store.reviewsCount ?? 0,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
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
  final String category;
  final int reviewsCount;

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
    required this.category,
    required this.reviewsCount,
  });

  String get _formattedDiscount {
    final value = discount.trim();
    if (value.isEmpty) return '';

    final withoutTrailingZeroDecimals = value.replaceFirst(RegExp(r'\.0+$'), '');
    final numericValue =
        num.tryParse(withoutTrailingZeroDecimals.replaceAll(',', ''));

    if (numericValue != null &&
        numericValue != 0 &&
        numericValue % 1000 == 0) {
      final thousands = numericValue / 1000;
      final formattedThousands = thousands % 1 == 0
          ? thousands.toInt().toString()
          : thousands
              .toStringAsFixed(1)
              .replaceFirst(RegExp(r'\.0$'), '');
      return '${formattedThousands}K';
    }

    return withoutTrailingZeroDecimals;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDiscount = _formattedDiscount;

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
                          : const Icon(Icons.restaurant,
                              size: 40, color: AppColors.textTertiary),
                ),
                // Tag (Quán Ngon) at Top Left
                if (tag.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B874B), // Green color
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Discount (Ưu đãi 56K) at Bottom Right
                if (formattedDiscount.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC05C3B), // Orange/Brown color
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ưu đãi $formattedDiscount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo Text with red tag icon
                    if (promo.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_offer,
                              size: 12,
                              color: Color(0xFFC84C35)), // Reddish tag
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              promo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFC84C35),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                    const Spacer(),
                    // Bottom info: Quảng cáo · 30 phút · 1.2 km
                    Text(
                      [
                        if (adLabel.isNotEmpty) adLabel,
                        if (time.isNotEmpty) time,
                        if (distance.isNotEmpty) distance,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

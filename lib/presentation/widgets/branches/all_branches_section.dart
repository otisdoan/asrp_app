import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../pages/branches/branches_detail_page.dart';
import '../../../providers/branches/branch_provider.dart';

/// Section "Tất cả quán" — vertical list with lazy loading (10 items at a time).
class AllStoresSection extends ConsumerStatefulWidget {
  const AllStoresSection({super.key});

  @override
  ConsumerState<AllStoresSection> createState() => _AllStoresSectionState();
}

class _AllStoresSectionState extends ConsumerState<AllStoresSection> {
  int _displayCount = 10;
  bool _isLoading = false;

  void _loadMore(int totalLength) {
    if (_isLoading || _displayCount >= totalLength) return;
    setState(() => _isLoading = true);

    // Simulate network delay for pagination if not paginating from API
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _displayCount = (_displayCount + 10).clamp(0, totalLength);
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncBranches = ref.watch(branchListProvider);

    return asyncBranches.when(
      data: (branches) {
        if (branches.isEmpty) {
          return const SizedBox.shrink();
        }

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
                return _AllStoreCard(
                  id: store.id,
                  name: store.name,
                  category: store.category ?? 'Món Việt',
                  rating: store.rating,
                  reviews: store.reviewsCount ?? 0,
                  distance: store.distance,
                  time: store.deliveryTime,
                  promo: store.promo ?? '',
                  icon: Icons.restaurant,
                  imageUrl: store.imageUrl,
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
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('Không thể tải danh sách quán', style: TextStyle(color: AppColors.error))),
      ),
    );
  }
}

class _AllStoreCard extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;
  final String time;
  final String promo;
  final IconData icon;
  final String imageUrl;

  const _AllStoreCard({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.time,
    required this.promo,
    required this.icon,
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
              image: imageUrl.isNotEmpty && !imageUrl.startsWith('http') 
                  ? DecorationImage(image: AssetImage(imageUrl), fit: BoxFit.cover)
                  : imageUrl.isNotEmpty && imageUrl.startsWith('http')
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
            ),
            child: imageUrl.isEmpty ? Icon(icon, size: 36, color: AppColors.textTertiary) : null,
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

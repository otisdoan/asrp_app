import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../data/models/branch_model.dart';
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

  void _loadMore(int totalStores) {
    if (_isLoading || _displayCount >= totalStores) return;
    setState(() => _isLoading = true);

    // Simulate loading delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _displayCount = (_displayCount + 10).clamp(0, totalStores);
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsyncValue = ref.watch(branchesFutureProvider);

    return branchesAsyncValue.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
      data: (branches) {
        if (branches.isEmpty) {
          return _buildEmptyState();
        }

        final visibleStores = branches.take(_displayCount).toList();
        final hasMore = _displayCount < branches.length;

        print('[UI Check] All Stores Section đã nhận ${branches.length} cửa hàng, đang hiển thị $_displayCount cửa hàng.');

        return _buildContent(branches, visibleStores, hasMore);
      },
    );
  }

  Widget _buildLoadingState() {
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
          ],
        ),
        const SizedBox(height: 12),
        // Loading shimmer cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: AppColors.outlineVariant,
          ),
          itemBuilder: (_, __) => _buildShimmerCard(),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Không thể tải danh sách quán',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Chưa có quán nào',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<BranchListItemModel> allBranches,
    List<BranchListItemModel> visibleStores,
    bool hasMore,
  ) {
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
              '${allBranches.length} quán',
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
            final branch = visibleStores[index];
            return _AllStoreCard(
              branch: branch,
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
                      onTap: () => _loadMore(allBranches.length),
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
  final BranchListItemModel branch;

  const _AllStoreCard({
    required this.branch,
  });

  @override
  Widget build(BuildContext context) {
    // Safe mapping with fallbacks
    final displayName = branch.name.isNotEmpty ? branch.name : 'Đang cập nhật';
    final displayCategory = branch.category ?? 'Đồ ăn · Đồ uống';
    final displayRating = branch.rating ?? 0.0;
    final displayReviews = branch.reviewsCount ?? 0;
    final displayDistance = branch.distance.isNotEmpty ? branch.distance : '1.2 km';
    final displayTime = branch.deliveryTime.isNotEmpty ? branch.deliveryTime : '20 phút';
    final displayPromo = branch.promo ?? '';

    return Consumer(
      builder: (context, ref, child) {
        return GestureDetector(
          onTap: () {
            // Kích hoạt provider để fetch menu mới
            ref.read(selectedBranchProvider.notifier).state = branch.id ?? branch.branchId ?? '';
            
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => StoreDetailPage(
                storeName: displayName,
                category: displayCategory,
                rating: displayRating,
                reviews: displayReviews,
                deliveryTime: displayTime,
                distance: displayDistance,
                icon: Icons.restaurant,
              ),
            ));
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Store image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: AppColors.bgWarm,
              child: _buildImage(),
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
                  displayName,
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
                  displayCategory,
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
                      '$displayRating',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' ($displayReviews+)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    Flexible(
                      child: Text(
                        '$displayTime · $displayDistance',
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
                if (displayPromo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          displayPromo,
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
    },
    );
  }

  Widget _buildImage() {
    if (branch.imageUrl != null && branch.imageUrl!.isNotEmpty) {
      return Image.network(
        branch.imageUrl!,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.bgWarm,
            child: const Icon(
              Icons.storefront,
              size: 36,
              color: AppColors.textTertiary,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.bgWarm,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      );
    }
    return Container(
      color: AppColors.bgWarm,
      child: const Icon(
        Icons.storefront,
        size: 36,
        color: AppColors.textTertiary,
      ),
    );
  }
}

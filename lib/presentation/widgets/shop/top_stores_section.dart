import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Top quán đỉnh trên 4.5" — horizontal scroll of store cards.
/// Inspired by GrabFood/ShopeeFood store listing design.
class TopStoresSection extends ConsumerWidget {
  const TopStoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsyncValue = ref.watch(branchesFutureProvider);

    return branchesAsyncValue.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
      data: (branches) {
        // Filter branches with rating >= 4.5
        final topBranches = branches.where((b) => (b.rating ?? 0.0) >= 4.5).toList();
        
        print('[UI Check] Top Stores Section đã render xong ${branches.length} cửa hàng.');
        
        if (topBranches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text('', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Top quán đỉnh trên 4.5',
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
                itemCount: topBranches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final branch = topBranches[index];
                  print('[UI Check] Top Store Card: Đang vẽ thẻ cho ${branch.name} - Rating: ${branch.rating}');
                  return _StoreCard(
                    branch: branch,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Top quán đỉnh trên 4.5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => _buildShimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
}

class _StoreCard extends StatelessWidget {
  final BranchListItemModel branch;

  const _StoreCard({
    required this.branch,
  });

  @override
  Widget build(BuildContext context) {
    // Safe mapping with fallbacks
    final displayName = branch.name.isNotEmpty ? branch.name : 'Đang cập nhật';
    final displayRating = branch.rating ?? 0.0;
    final displayDistance = branch.distance.isNotEmpty ? branch.distance : '1.2 km';
    final displayTime = branch.deliveryTime.isNotEmpty ? branch.deliveryTime : '20 phút';
    final displayReviews = branch.reviewsCount ?? 100;
    final displayTag = branch.tag ?? '';
    final displayPromo = branch.promo ?? '';
    final displayDiscount = branch.discount ?? '';
    final displayAdLabel = branch.adLabel ?? '';

    return Consumer(
      builder: (context, ref, child) {
        return GestureDetector(
          onTap: () {
            // Kích hoạt provider để fetch menu mới
            ref.read(selectedBranchProvider.notifier).state = branch.id ?? branch.branchId ?? '';
            
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => StoreDetailPage(
                storeName: displayName,
                category: branch.category ?? 'Đồ ăn · Đồ uống',
                rating: displayRating,
                reviews: displayReviews,
                deliveryTime: displayTime,
                distance: displayDistance,
                icon: Icons.store,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  color: AppColors.bgWarm,
                  child: _buildImage(),
                ),
              ),
              // Tag badge (top-left)
              if (displayTag.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      displayTag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Discount badge (bottom-right)
              if (displayDiscount.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ưu đãi\n',
                          style: TextStyle(fontSize: 8, color: Colors.white, height: 1),
                        ),
                        Text(
                          displayDiscount,
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo line
                  if (displayPromo.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.local_offer, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayPromo,
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
                  // Store name
                  Text(
                    displayName,
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
                  // Bottom info: ad label · time · distance
                  Row(
                    children: [
                      if (displayAdLabel.isNotEmpty) ...[
                        Text(
                          displayAdLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                      ],
                      Flexible(
                        child: Text(
                          '$displayTime · $displayDistance',
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
                ],
              ),
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
        width: double.infinity,
        height: 110,
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

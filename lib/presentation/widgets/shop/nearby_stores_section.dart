import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Gần bạn" — horizontal scroll of nearby store cards.
class NearbyStoresSection extends ConsumerWidget {
  const NearbyStoresSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsyncValue = ref.watch(branchesFutureProvider);

    return branchesAsyncValue.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
      data: (branches) {
        if (branches.isEmpty) {
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
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: branches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return _NearbyStoreCard(
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
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
      width: 150,
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 95,
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
                    width: 80,
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

class _NearbyStoreCard extends StatelessWidget {
  final BranchListItemModel branch;

  const _NearbyStoreCard({
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
        width: 150,
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
              height: 95,
              width: double.infinity,
              color: AppColors.bgSoft,
              child: _buildImage(),
            ),
          ),
          // Info area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Rating + distance
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        displayRating.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                  const SizedBox(height: 4),
                  // Promo
                  if (displayPromo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.badgeHotBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayPromo,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.badgeHotText,
                        ),
                      ),
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
        height: 95,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.bgSoft,
            child: const Icon(
              Icons.storefront,
              size: 32,
              color: AppColors.textTertiary,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.bgSoft,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
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
      color: AppColors.bgSoft,
      child: const Icon(
        Icons.storefront,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }
}

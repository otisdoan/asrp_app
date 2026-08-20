import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/recommendation_card_item_model.dart';
import '../../../providers/recommendation_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Widget "Có thể bạn cũng thích" dùng chung duy nhất cho toàn ứng dụng.
/// Đồng bộ thiết kế UI, Shimmer Loading, và tích hợp 1-touch click tự động chuyển StoreDetailPage + autoAddToCart.
class YouMayAlsoLikeSection extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const YouMayAlsoLikeSection({
    super.key,
    this.title = 'Có thể bạn cũng thích',
    this.subtitle,
    this.margin = const EdgeInsets.symmetric(vertical: 16),
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  void _onOpenStoreAndAddToCart(BuildContext context, RecommendedCardItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(
          storeName: item.branchName,
          category: item.category,
          rating: item.rating,
          reviews: item.reviewsCount,
          deliveryTime: item.deliveryTime,
          distance: item.distance,
          icon: Icons.restaurant,
          branchId: item.branchId,
          imageUrl: item.imageUrl,
          highlightFoodName: item.dishName,
          autoAddToCart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(personalizedRecommendationsProvider);

    return Container(
      margin: margin,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Recommendation Content / Shimmer Skeleton ───────────────────────
          recommendationsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgWarm,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.location_off_rounded, color: AppColors.textTertiary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chưa tìm thấy cửa hàng gần vị trí của bạn. Vui lòng kiểm tra lại địa điểm nhận hàng!',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final displayItems = items.take(9).toList();

              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.52,
                ),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _buildItemCard(context, item);
                },
              );
            },
            loading: () => _buildSkeletonLoading(),
            error: (err, __) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgWarm,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: AppColors.textTertiary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang cập nhật danh sách gợi ý tối ưu cho khu vực của bạn...',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

  Widget _buildItemCard(BuildContext context, RecommendedCardItemModel item) {
    return GestureDetector(
      onTap: () => _onOpenStoreAndAddToCart(context, item),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container with badge
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: AppColors.bgWarm,
                    child: item.imageUrl.isNotEmpty
                        ? (item.imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.fastfood,
                                  size: 28,
                                  color: AppColors.textTertiary,
                                ),
                              )
                            : Image.asset(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.fastfood,
                                  size: 28,
                                  color: AppColors.textTertiary,
                                ),
                              ))
                        : const Icon(
                            Icons.fastfood,
                            size: 28,
                            color: AppColors.textTertiary,
                          ),
                  ),
                ),
              ),
              // Rating Badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dish Name
          Text(
            item.dishName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Branch Name
          Text(
            item.branchName,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Price & Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.priceDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 10, color: AppColors.textTertiary),
                  Text(
                    item.distance,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Add to Cart Button
          SizedBox(
            width: double.infinity,
            height: 26,
            child: ElevatedButton(
              onPressed: () => _onOpenStoreAndAddToCart(context, item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                '+ Chọn món',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer Skeleton animation during recommendations calculation / loading state
  Widget _buildSkeletonLoading() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.52,
      ),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        );
      },
    );
  }
}

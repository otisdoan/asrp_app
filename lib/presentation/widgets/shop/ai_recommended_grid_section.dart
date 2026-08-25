import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/ai_recommendation_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Reusable AI-Powered "Có thể bạn cũng thích" & "Được đề xuất" Grid Section
/// Displays personalized dishes and store recommendations with tags, prices, ratings, and distances.
class AiRecommendedGridSection extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final int maxItems;

  const AiRecommendedGridSection({
    super.key,
    this.title = 'Có thể bạn cũng thích',
    this.subtitle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.maxItems = 9,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiRecsAsync = ref.watch(personalizedRecommendationsProvider);
    final userLocation = ref.watch(userLocationProvider);

    return aiRecsAsync.when(
      data: (aiItems) {
        if (aiItems.isNotEmpty) {
          final displayItems = aiItems.take(maxItems).toList();
          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    return _buildAiItemCard(context, item);
                  },
                ),
              ],
            ),
          );
        }
        return _buildFallbackSection(context, ref, userLocation);
      },
      loading: () => _buildFallbackSection(context, ref, userLocation),
      error: (_, __) => _buildFallbackSection(context, ref, userLocation),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFFF7A45)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFFF6F3C)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, size: 11, color: Colors.white),
              SizedBox(width: 3),
              Text(
                'DineX AI',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiItemCard(BuildContext context, AiRecommendationModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailPage(
              branchId: item.branchId,
              storeName: item.storeName,
              category: 'Quán ăn',
              rating: item.rating,
              reviews: item.reviews > 0 ? item.reviews : 100,
              deliveryTime: item.deliveryTime,
              distance: item.distance,
              icon: Icons.store,
              imageUrl: item.imageUrl,
              highlightFoodName: item.dishName,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.bgWarm,
                    child: (item.imageUrl.isNotEmpty && item.imageUrl.startsWith('http'))
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.store, color: AppColors.textTertiary, size: 24),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.restaurant, color: AppColors.textTertiary, size: 24),
                          ),
                  ),
                ),
                if (item.tag.isNotEmpty)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      item.priceText,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.dishName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.storeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 2),
              Text(
                item.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Flexible(
                child: Text(
                  item.distance.isNotEmpty ? item.distance : '1.2 km',
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
    );
  }

  Widget _buildFallbackSection(BuildContext context, WidgetRef ref, dynamic userLocation) {
    final fallbackAsync = ref.watch(recommendedBranchesProvider);

    return fallbackAsync.when(
      data: (stores) {
        if (stores.isEmpty) return const SizedBox.shrink();
        final displayStores = stores.take(maxItems).toList();

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.65,
                ),
                itemCount: displayStores.length,
                itemBuilder: (context, index) {
                  final store = displayStores[index];
                  final displayDistance = LocationService.calculateBranchDistance(
                    userLocation: userLocation,
                    branchLat: store.latitude,
                    branchLng: store.longitude,
                    branchAddress: store.address,
                    fallbackDistance: store.distance,
                  );

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailPage(
                            branchId: store.id,
                            storeName: store.name,
                            category: store.category ?? 'Đồ ăn · Đồ uống',
                            rating: store.rating,
                            reviews: store.reviewsCount ?? 150,
                            deliveryTime: store.deliveryTime,
                            distance: displayDistance,
                            icon: Icons.store,
                            imageUrl: store.imageUrl,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              color: AppColors.bgWarm,
                              child: (store.imageUrl.isNotEmpty && store.imageUrl.startsWith('http'))
                                  ? Image.network(
                                      store.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.store, color: AppColors.textTertiary, size: 24),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.store, color: AppColors.textTertiary, size: 24),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(' · ', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                            Flexible(
                              child: Text(
                                displayDistance.isNotEmpty ? displayDistance : '1.2 km',
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
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

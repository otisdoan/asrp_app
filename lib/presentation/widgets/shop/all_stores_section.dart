import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../pages/shop/store_detail_page.dart';

/// Section "Tất cả quán" — vertical list with lazy loading (10 items at a time).
class AllStoresSection extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const AllStoresSection({super.key, required this.scrollController});

  @override
  ConsumerState<AllStoresSection> createState() => _AllStoresSectionState();
}

class _AllStoresSectionState extends ConsumerState<AllStoresSection> {
  int _displayCount = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final currentScroll = widget.scrollController.position.pixels;
    if (maxScroll - currentScroll <= 150) {
      final branches = ref.read(branchesFutureProvider).value;
      if (branches != null) {
        _loadMore(branches.length);
      }
    }
  }

  void _loadMore(int totalCount) {
    if (_isLoading || _displayCount >= totalCount) return;
    setState(() => _isLoading = true);

    if (mounted) {
      setState(() {
        _displayCount = (_displayCount + 10).clamp(0, totalCount);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesFutureProvider);

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContent(context, branches);
      },
      loading: () => const _LoadingSection(),
      error: (err, stack) {
        print('[AllStoresSection] Lỗi tải chi nhánh: $err');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(
      BuildContext context, List<BranchListItemModel> branches) {
    final visibleStores = branches.take(_displayCount).toList();
    final hasMore = _displayCount < branches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store list (vertical)
        ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleStores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final store = visibleStores[index];
              final userLocation = ref.watch(userLocationProvider);

              // Calculate dynamic distance if user location is available
              String displayDistance = store.distance;
              print(
                  '[AllStoresSection] Branch: ${store.name}, lat: ${store.latitude}, lng: ${store.longitude}, userLocation: ${userLocation?.latitude}, ${userLocation?.longitude}');
              if (userLocation != null &&
                  store.latitude != null &&
                  store.longitude != null) {
                final meters = LocationService.distanceTo(
                  userLocation.latitude,
                  userLocation.longitude,
                  store.latitude!,
                  store.longitude!,
                );
                displayDistance = LocationService.formatDistance(meters);
                print(
                    '[AllStoresSection] Calculated distance: $displayDistance');
              } else if (displayDistance.isEmpty) {
                displayDistance = 'Gần đây';
              }

              // Fallback for empty deliveryTime
              String displayTime = store.deliveryTime;
              if (displayTime.isEmpty) {
                displayTime = '25 phút';
              }

              return _AllStoreCard(
                name: store.name,
                category: store.category ?? 'Đồ ăn · Đồ uống',
                rating: store.rating,
                reviews: store.reviewsCount ?? 100,
                distance: displayDistance,
                time: displayTime,
                promo: store.promo ?? '',
                image: store.imageUrl,
                icon: Icons.restaurant,
                branchId: store.id,
              );
            },
          ),
          // Load more / Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // End of list indicator
          if (!hasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Đã hiển thị tất cả quán',
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
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;
  final String time;
  final String promo;
  final String image;
  final IconData icon;
  final String? branchId;

  const _AllStoreCard({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.time,
    required this.promo,
    required this.image,
    required this.icon,
    this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailPage(
                storeName: name,
                category: category,
                rating: rating,
                reviews: reviews,
                deliveryTime: time,
                distance: distance,
                icon: icon,
                branchId: branchId,
                imageUrl: image,
              ),
            ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image.isNotEmpty
                    ? (image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => Icon(icon,
                                size: 36, color: AppColors.textTertiary),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => Icon(icon,
                                size: 36, color: AppColors.textTertiary),
                          ))
                    : Icon(icon, size: 36, color: AppColors.textTertiary),
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
                      const Text(' · ',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textTertiary)),
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
                        const Icon(Icons.local_offer,
                            size: 12, color: AppColors.primary),
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

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 104,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

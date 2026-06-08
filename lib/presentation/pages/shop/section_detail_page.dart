import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/branch_model.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/services/location_service.dart';
import 'store_detail_page.dart';

class SectionDetailPage extends ConsumerStatefulWidget {
  final String type; // 'deals', 'top_rated', 'nearby'
  final String title;

  const SectionDetailPage({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<SectionDetailPage> createState() => _SectionDetailPageState();
}

class _SectionDetailPageState extends ConsumerState<SectionDetailPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Gần tôi', 'Bán chạy', 'Đánh giá', 'Giao nhanh'];
  late ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const collapsedThreshold = 200.0 - kToolbarHeight;
    final collapsed = _scrollController.hasClients &&
        _scrollController.offset > collapsedThreshold;
    if (collapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = collapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesFutureProvider);
    final userLocation = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: branchesAsync.when(
        data: (branches) {
          final filteredBranches = _getFilteredAndSortedBranches(branches, userLocation);
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Cover Banner with Collapsing Header
              _buildSliverAppBar(),
              
              // Title, Description Block
              SliverToBoxAdapter(
                child: _buildTitleBlock(),
              ),

              // Sticky Filter Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  child: _buildTabBar(),
                ),
              ),

              // Branch List Items
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                sliver: filteredBranches.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Không tìm thấy chi nhánh nào',
                              style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final branch = filteredBranches[index];
                            return _BranchCardWithMenu(
                              branch: branch,
                              userLocation: userLocation,
                            );
                          },
                          childCount: filteredBranches.length,
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Có lỗi xảy ra khi tải dữ liệu', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(branchesFutureProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    String bannerImage = 'assets/images/com.webp';
    if (widget.type == 'deals') {
      bannerImage = 'assets/images/tra_sua.jpg';
    } else if (widget.type == 'top_rated') {
      bannerImage = 'assets/images/pho.jpg';
    }

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _isCollapsed ? Colors.white : AppColors.primary,
      elevation: 0,
      centerTitle: true,
      title: _isCollapsed
          ? Text(
              widget.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isCollapsed
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: _isCollapsed ? const Color(0xFFE55333) : Colors.white,
                size: _isCollapsed ? 24 : 20,
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isCollapsed
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_outlined,
                color: _isCollapsed ? const Color(0xFFE55333) : Colors.white,
                size: _isCollapsed ? 22 : 18,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              bannerImage,
              fit: BoxFit.cover,
            ),
            // Top/Bottom overlay gradient to ensure high readability of header icons
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    String subtitle = 'Quán ngon gợi ý cực chất dành riêng cho bạn';
    if (widget.type == 'deals') {
      subtitle = 'Quán ngon mới mở nhiều deal hời hấp dẫn\nMua ngay nhận ưu đãi giảm đậm 50.000Đ!\nSố lượng mã ưu đãi có hạn mỗi ngày.';
    } else if (widget.type == 'top_rated') {
      subtitle = 'Những thương hiệu chất lượng được đông đảo người dùng đánh giá cao nhất trên hệ thống.';
    } else if (widget.type == 'nearby') {
      subtitle = 'Khám phá ẩm thực phong phú xung quanh vị trí hiện tại của bạn, giao cực nhanh.';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(0),
          _buildTabDivider(),
          _buildTabItem(1),
          _buildTabDivider(),
          _buildTabItem(2),
          _buildTabDivider(),
          _buildTabItem(3),
        ],
      ),
    );
  }

  Widget _buildTabDivider() {
    return Container(
      width: 1,
      height: 14,
      color: const Color(0xFFE5E5E5),
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = index == _selectedTabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFFE55333) : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _tabs[index],
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFFE55333) : const Color(0xFF2D2D2D),
            ),
          ),
        ),
      ),
    );
  }

  List<BranchListItemModel> _getFilteredAndSortedBranches(
    List<BranchListItemModel> allBranches,
    dynamic userLocation,
  ) {
    List<BranchListItemModel> filtered = [];
    
    // 1. Filtering based on section type
    if (widget.type == 'top_rated') {
      filtered = allBranches.where((b) => b.rating >= 4.5).toList();
    } else if (widget.type == 'deals') {
      filtered = allBranches.where((b) => (b.promo != null && b.promo!.isNotEmpty) || (b.discount != null && b.discount!.isNotEmpty)).toList();
      if (filtered.isEmpty) {
        filtered = List.from(allBranches);
      }
    } else {
      filtered = List.from(allBranches);
    }

    // 2. Sorting based on active tab
    int parseTime(String time) {
      final digits = RegExp(r'\d+').firstMatch(time)?.group(0);
      return int.tryParse(digits ?? '') ?? 999;
    }

    double getDistanceMeters(BranchListItemModel b) {
      if (userLocation != null && b.latitude != null && b.longitude != null) {
        return LocationService.distanceTo(
          userLocation.latitude,
          userLocation.longitude,
          b.latitude!,
          b.longitude!,
        );
      }
      return 9999999;
    }

    if (_selectedTabIndex == 0) {
      // Gần tôi (Sort by distance)
      filtered.sort((a, b) => getDistanceMeters(a).compareTo(getDistanceMeters(b)));
    } else if (_selectedTabIndex == 1) {
      // Bán chạy (Sort by reviewsCount or displays)
      filtered.sort((a, b) => (b.reviewsCount ?? 0).compareTo(a.reviewsCount ?? 0));
    } else if (_selectedTabIndex == 2) {
      // Đánh giá (Sort by rating)
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedTabIndex == 3) {
      // Giao nhanh (Sort by time)
      filtered.sort((a, b) => parseTime(a.deliveryTime).compareTo(parseTime(b.deliveryTime)));
    }

    return filtered;
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 48.0;
  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

/// A Card displaying branch details and its first 2 menu items
class _BranchCardWithMenu extends ConsumerWidget {
  final BranchListItemModel branch;
  final dynamic userLocation;

  const _BranchCardWithMenu({
    required this.branch,
    required this.userLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(branchDetailFutureProvider(branch.id));

    String displayDistance = branch.distance;
    if (userLocation != null && branch.latitude != null && branch.longitude != null) {
      final meters = LocationService.distanceTo(
        userLocation.latitude,
        userLocation.longitude,
        branch.latitude!,
        branch.longitude!,
      );
      displayDistance = LocationService.formatDistance(meters);
    } else if (displayDistance.isEmpty) {
      displayDistance = 'Gần đây';
    }

    String displayTime = branch.deliveryTime;
    if (displayTime.isEmpty) {
      displayTime = '25 phút';
    }

    final cleanedDistance = displayDistance.replaceAll(' ', '');
    final cleanedTime = displayTime.replaceAll(' ', '');

    String promoTag = branch.promo ?? branch.discount ?? '';
    if (promoTag.contains(' · ')) {
      promoTag = promoTag.split(' · ').first;
    }
    if (promoTag.isEmpty) {
      promoTag = 'Mã giảm 10%';
    } else if (!promoTag.toLowerCase().contains('giảm') && !promoTag.toLowerCase().contains('freeship')) {
      promoTag = 'Mã giảm $promoTag';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Branch Row
          GestureDetector(
            onTap: () => _navigateToDetail(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: AppColors.bgSoft,
                    child: branch.imageUrl.startsWith('http')
                        ? Image.network(
                            branch.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppColors.textTertiary, size: 28),
                          )
                        : Image.asset(
                            branch.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppColors.textTertiary, size: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Branch Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verified + Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(
                              Icons.verified_user,
                              size: 14,
                              color: Color(0xFFFF9900), // Gold verified shield badge
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              branch.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Rating | Distance | Time
                      Row(
                        children: [
                          Icon(
                            branch.rating > 0 ? Icons.star : Icons.star_border,
                            size: 13,
                            color: branch.rating > 0 ? const Color(0xFFF2994A) : const Color(0xFFBDBDBD),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            branch.rating > 0 ? branch.rating.toString() : 'Chưa có',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: branch.rating > 0 ? FontWeight.bold : FontWeight.w400,
                              color: const Color(0xFF757575),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '|',
                              style: TextStyle(fontSize: 11, color: Color(0xFFE5E5E5)),
                            ),
                          ),
                          Text(
                            cleanedDistance,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '|',
                              style: TextStyle(fontSize: 11, color: Color(0xFFE5E5E5)),
                            ),
                          ),
                          Text(
                            cleanedTime,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      
                      // Promo Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          border: Border.all(color: const Color(0xFFFFCCCC), width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          promoTag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE55333),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 2. Menu Items Sublist (indented left by 88px to align with details column)
          detailAsync.when(
            data: (detail) {
              final allItems = detail.menu?.expand((sec) => sec.items).toList() ?? [];
              if (allItems.isEmpty) return const SizedBox.shrink();
              
              final displayItems = allItems.take(2).toList();
              return Padding(
                padding: const EdgeInsets.only(left: 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final item = displayItems[idx];
                        return GestureDetector(
                           onTap: () => _navigateToDetail(context, highlightFoodName: item.name),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Food Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  color: AppColors.bgSoft,
                                  child: item.imageUrl.startsWith('http')
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_outlined, color: AppColors.textTertiary, size: 16),
                                        )
                                      : Image.asset(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_outlined, color: AppColors.textTertiary, size: 16),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              
                              // Food Name & Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w400,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatPrice(item.price),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE55333),
                                      ),
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, {String? highlightFoodName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(
          storeName: branch.name,
          category: 'Đồ ăn · Đồ uống',
          rating: branch.rating,
          reviews: branch.reviewsCount ?? 100,
          deliveryTime: branch.deliveryTime.isNotEmpty ? branch.deliveryTime : '25 phút',
          distance: branch.distance.isNotEmpty ? branch.distance : '1.5 km',
          icon: Icons.store,
          branchId: branch.id,
          highlightFoodName: highlightFoodName,
          imageUrl: branch.imageUrl,
        ),
      ),
    );
  }

  String _formatPrice(String priceStr) {
    if (priceStr.isEmpty) return '0đ';
    if (priceStr.contains('đ') || priceStr.contains('.')) {
      return priceStr.endsWith('đ') ? priceStr : '$priceStrđ';
    }
    final val = double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (val != null) {
      final formatted = val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '$formattedđ';
    }
    return '$priceStrđ';
  }
}

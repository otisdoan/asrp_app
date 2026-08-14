import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/favorite_shops_provider.dart';
import '../../../core/network/dio_client.dart';

/// Store Reviews Page showing ratings breakdown, AI review summary, and a list of all real dish comments from API.
class StoreReviewsPage extends ConsumerStatefulWidget {
  final String? branchId;
  final String storeName;
  final String category;
  final double rating;
  final int reviewsCount;
  final String deliveryTime;
  final String distance;
  final String? imageUrl;
  final IconData? icon;

  const StoreReviewsPage({
    super.key,
    this.branchId,
    required this.storeName,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.deliveryTime,
    required this.distance,
    this.imageUrl,
    this.icon,
  });

  @override
  ConsumerState<StoreReviewsPage> createState() => _StoreReviewsPageState();
}

class _StoreReviewsPageState extends ConsumerState<StoreReviewsPage> {
  final Set<String> _likedReviews = {};
  String _selectedFilter = 'Tất cả';

  late ScrollController _scrollController;
  final ValueNotifier<bool> _isCollapsedNotifier = ValueNotifier<bool>(false);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _apiReviews = [];
  Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  double _avgRating = 0.0;
  int _totalReviews = 0;
  String _aiSummary = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > 140;
      if (collapsed != _isCollapsedNotifier.value) {
        _isCollapsedNotifier.value = collapsed;
      }
    });

    _fetchReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isCollapsedNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    if (widget.branchId == null || widget.branchId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _avgRating = widget.rating;
        _totalReviews = widget.reviewsCount;
        _aiSummary = 'Chưa có đánh giá tổng hợp AI cho chi nhánh này.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await DioClient().dio.get('/branches/${widget.branchId}/reviews');
      final data = response.data;
      final List<dynamic> items = data is Map ? (data['items'] as List<dynamic>? ?? []) : [];

      Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double totalRatingSum = 0;
      List<Map<String, dynamic>> reviewsList = [];

      for (var item in items) {
        final rating = (item['rating'] as num?)?.toInt() ?? 5;
        final customerName = item['customerName'] as String? ?? 'Khách hàng';
        final avatarUrl = item['customerAvatarUrl'] as String?;
        final content = item['content'] as String? ?? '';
        final images = List<String>.from(item['images'] as List? ?? []);
        final tags = List<String>.from(item['tags'] as List? ?? []);
        final reply = item['reply'] as String? ?? '';
        final createdAtStr = item['createdAt'] as String? ?? '';
        final likeCount = (item['likeCount'] as num?)?.toInt() ?? 0;

        counts[rating] = (counts[rating] ?? 0) + 1;
        totalRatingSum += rating;

        String formattedDate = '';
        if (createdAtStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();
            formattedDate = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            formattedDate = createdAtStr;
          }
        }

        reviewsList.add({
          'id': item['id'],
          'user': customerName,
          'avatarUrl': avatarUrl,
          'rating': rating,
          'date': formattedDate,
          'content': content,
          'images': images,
          'imageCount': images.length,
          'tags': tags,
          'reply': reply,
          'likes': likeCount,
        });
      }

      final count = reviewsList.length;
      final avg = count > 0 ? (totalRatingSum / count) : widget.rating;
      final displayCount = count > 0 ? count : widget.reviewsCount;

      String aiText = '';
      if (count > 0) {
        final commentsWithText = reviewsList
            .where((r) => (r['content'] as String).trim().isNotEmpty)
            .map((r) => r['content'] as String)
            .toList();
        if (commentsWithText.isNotEmpty) {
          aiText = '${commentsWithText.take(3).join('. ')}.';
        } else {
          aiText = 'Khách hàng đánh giá rất cao chất lượng món ăn và phong cách phục vụ của ${widget.storeName}.';
        }
      } else {
        aiText = 'Chưa có đánh giá trực tiếp nào từ khách hàng cho chi nhánh này.';
      }

      setState(() {
        _apiReviews = reviewsList;
        _starCounts = counts;
        _avgRating = avg;
        _totalReviews = displayCount;
        _aiSummary = aiText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải đánh giá từ máy chủ.';
        _avgRating = widget.rating;
        _totalReviews = widget.reviewsCount;
        _aiSummary = 'Chưa có đánh giá trực tiếp nào từ khách hàng cho chi nhánh này.';
      });
    }
  }

  static const List<String> _filters = [
    'Tất cả',
    'Kèm hình ảnh',
    '5 sao',
    '4 sao',
    '3 sao',
    '2 sao',
    '1 sao'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: RefreshIndicator(
        onRefresh: _fetchReviews,
        color: AppColors.primary,
        child: Stack(
          children: [
            // ─── 1. Background Banner Image ───
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: _buildHeaderImage(),
            ),
            // ─── 2. Scrollable Content sheet overlapping background ───
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 180), // Creates the overlap spacing
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.bgMain,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 16,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildStoreInfoHeader(),
                          const SizedBox(height: 12),
                          _buildRatingsCard(),
                          _buildAISummaryCard(),
                          _buildSectionHeader(),
                          _buildFilterBar(),
                          const SizedBox(height: 12),
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            )
                          else if (_errorMessage != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _fetchReviews,
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                      child: const Text('Tải lại', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            _buildCommentsList(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ─── 3. Sticky / Floating App Bar ───
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildStickyAppBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header Image Widget ───────────────────────────────────────────────────
  Widget _buildHeaderImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.bgSoft),
        errorWidget: (_, __, ___) => _buildFallbackHeaderBg(),
      );
    }
    return _buildFallbackHeaderBg();
  }

  Widget _buildFallbackHeaderBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFF7A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          widget.icon ?? Icons.restaurant_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ─── Sticky App Bar (Animates title & bg on scroll) ───────────────────────
  Widget _buildStickyAppBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isCollapsedNotifier,
      builder: (context, isCollapsed, _) {
        final favoriteShops = ref.watch(favoriteShopsProvider);
        final isFav = favoriteShops.contains(widget.storeName);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            bottom: 10,
            left: 12,
            right: 12,
          ),
          decoration: BoxDecoration(
            color: isCollapsed ? Colors.white : Colors.transparent,
            boxShadow: isCollapsed
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCollapsed
                        ? AppColors.bgSoft
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isCollapsed ? AppColors.textPrimary : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Store Title
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isCollapsed ? 1.0 : 0.0,
                  child: Text(
                    widget.storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Favorite Button
              GestureDetector(
                onTap: () {
                  ref.read(favoriteShopsProvider.notifier).toggleFavorite(widget.storeName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? 'Đã xóa ${widget.storeName} khỏi danh sách yêu thích'
                            : 'Đã thêm ${widget.storeName} vào danh sách yêu thích!',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCollapsed
                        ? AppColors.bgSoft
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFav
                        ? AppColors.primary
                        : (isCollapsed ? AppColors.textPrimary : Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Store Info Header ────────────────────────────────────────────────────
  Widget _buildStoreInfoHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.storeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.category,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Đang mở cửa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.distance.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.distance,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Ratings Breakdown Card ────────────────────────────────────────────────
  Widget _buildRatingsCard() {
    final double displayRating = _avgRating > 0 ? _avgRating : widget.rating;
    final int displayCount = _totalReviews > 0 ? _totalReviews : widget.reviewsCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Giant Rating Number
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                // Stars row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    if (i < displayRating.floor()) {
                      return const Icon(Icons.star_rounded, size: 16, color: AppColors.star);
                    } else if (i < displayRating) {
                      return const Icon(Icons.star_half_rounded, size: 16, color: AppColors.star);
                    }
                    return const Icon(Icons.star_border_rounded, size: 16, color: AppColors.star);
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '$displayCount đánh giá',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            height: 80,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(width: 16),
          // Right: Star Progress Bars
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildStarProgressRow(5, displayCount > 0 ? ((_starCounts[5] ?? 0) / displayCount) : 0.0),
                const SizedBox(height: 4),
                _buildStarProgressRow(4, displayCount > 0 ? ((_starCounts[4] ?? 0) / displayCount) : 0.0),
                const SizedBox(height: 4),
                _buildStarProgressRow(3, displayCount > 0 ? ((_starCounts[3] ?? 0) / displayCount) : 0.0),
                const SizedBox(height: 4),
                _buildStarProgressRow(2, displayCount > 0 ? ((_starCounts[2] ?? 0) / displayCount) : 0.0),
                const SizedBox(height: 4),
                _buildStarProgressRow(1, displayCount > 0 ? ((_starCounts[1] ?? 0) / displayCount) : 0.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgressRow(int starCount, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          child: Text(
            '$starCount',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.outlineVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.star),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── AI Summary Card ───────────────────────────────────────────────────────
  Widget _buildAISummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.5),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tóm tắt bởi AI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _aiSummary.isNotEmpty
                ? _aiSummary
                : 'Chưa có đánh giá tổng hợp AI cho chi nhánh này.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        'Ý kiến người dùng',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─── Filter Bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredComments {
    final list = _apiReviews;
    if (_selectedFilter == 'Tất cả') {
      return list;
    } else if (_selectedFilter == 'Kèm hình ảnh') {
      return list.where((c) => (c['imageCount'] as int) > 0).toList();
    } else if (_selectedFilter == '5 sao') {
      return list.where((c) => c['rating'] == 5).toList();
    } else if (_selectedFilter == '4 sao') {
      return list.where((c) => c['rating'] == 4).toList();
    } else if (_selectedFilter == '3 sao') {
      return list.where((c) => c['rating'] == 3).toList();
    } else if (_selectedFilter == '2 sao') {
      return list.where((c) => c['rating'] == 2).toList();
    } else if (_selectedFilter == '1 sao') {
      return list.where((c) => c['rating'] == 1).toList();
    }
    return list;
  }

  // ─── Comments List ─────────────────────────────────────────────────────────
  Widget _buildCommentsList() {
    final filtered = _filteredComments;
    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: const Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'Không có đánh giá nào',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Chưa có bình luận nào cho chi nhánh này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: AppColors.outlineVariant),
      ),
      itemBuilder: (context, index) {
        final review = filtered[index];
        final id = review['id'].toString();
        final user = review['user'] as String;
        final avatarUrl = review['avatarUrl'] as String?;
        final hasReply = (review['reply'] as String).isNotEmpty;
        final tags = List<String>.from(review['tags'] as List);
        final images = List<String>.from(review['images'] as List);
        final isLiked = _likedReviews.contains(id);
        final initialLikes = review['likes'] as int;
        final currentLikes = initialLikes + (isLiked ? 1 : 0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.bgSoft,
                  shape: BoxShape.circle,
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.person, size: 20, color: AppColors.textTertiary),
                        ),
                      )
                    : const Icon(Icons.person, size: 20, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 12),
              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Text(
                      user,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stars & Date Row
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < (review['rating'] as int) ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 14,
                              color: AppColors.star,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['date'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Content Text
                    if ((review['content'] as String).isNotEmpty)
                      Text(
                        review['content'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    // Review images
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: images.map((imgUrl) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imgUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(width: 70, height: 70, color: AppColors.bgSoft),
                            errorWidget: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: AppColors.bgWarm,
                              child: const Icon(Icons.broken_image_outlined, size: 20, color: AppColors.textTertiary),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                    // Recommended Dishes Tags
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Heart Interaction Row
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            _likedReviews.remove(id);
                          } else {
                            _likedReviews.add(id);
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: isLiked ? AppColors.primary : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentLikes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLiked ? AppColors.primary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Merchant Reply (Quán phản hồi)
                    if (hasReply) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.storefront, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Phản hồi từ Cửa hàng:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              review['reply'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

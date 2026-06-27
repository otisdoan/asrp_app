import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/branch_repository.dart';
import 'add_to_cart_page.dart';

/// Food Item Detail Page — shows food image, info, price, and reviews.
/// Follows RULE: UI-only, uses AppColors, responsive.
class FoodDetailPage extends StatefulWidget {
  final String name;
  final String price;
  final String sold;
  final int likes;
  final IconData icon;
  final String? imageUrl;
  final String? menuItemId;
  final String? branchId;

  const FoodDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.sold,
    required this.likes,
    required this.icon,
    this.imageUrl,
    this.menuItemId,
    this.branchId,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late ScrollController _scrollController;
  bool _isCollapsed = false;
  final Set<String> _likedReviews = {};
  bool _isProductLiked = false;
  late int _productLikes;

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  String? _reviewsErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _productLikes = widget.likes;
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final branchId = widget.branchId;
    final menuItemId = widget.menuItemId;
    
    if (branchId == null || branchId.isEmpty || menuItemId == null || menuItemId.isEmpty) {
      setState(() {
        _reviews = [];
        _isLoadingReviews = false;
      });
      return;
    }

    setState(() {
      _isLoadingReviews = true;
      _reviewsErrorMessage = null;
    });

    try {
      final repo = BranchRepository();
      final rawReviews = await repo.getMenuItemReviews(
        branchId: branchId,
        menuItemId: menuItemId,
      );

      final mapped = rawReviews.map((r) => _mapBackendReviewToUi(r)).toList();

      setState(() {
        _reviews = mapped;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('[FoodDetailPage] Error fetching reviews: $e');
      setState(() {
        _reviewsErrorMessage = 'Không thể tải bình luận: $e';
        _isLoadingReviews = false;
      });
    }
  }

  Map<String, dynamic> _mapBackendReviewToUi(Map<String, dynamic> review) {
    final user = review['customerName'] ?? review['CustomerName'] ?? 'Người dùng';
    final rating = (review['rating'] ?? review['Rating'] ?? 5) as int;
    final content = review['content'] ?? review['Content'] ?? '';

    String dateStr = '';
    final rawDate = review['createdAt'] ?? review['CreatedAt'];
    if (rawDate != null) {
      try {
        final parsedDate = DateTime.parse(rawDate.toString());
        final day = parsedDate.day.toString().padLeft(2, '0');
        final month = parsedDate.month.toString().padLeft(2, '0');
        final year = parsedDate.year;
        final hour = parsedDate.hour.toString().padLeft(2, '0');
        final minute = parsedDate.minute.toString().padLeft(2, '0');
        dateStr = '$day-$month-$year $hour:$minute';
      } catch (e) {
        dateStr = rawDate.toString();
      }
    }

    final rawImages = review['images'] ?? review['Images'];
    final List<String> images = rawImages != null ? List<String>.from(rawImages as List) : [];
    final imageCount = images.isNotEmpty ? images.length : ((review['imageCount'] ?? review['ImageCount'] ?? 0) as int);
    final tags = List<String>.from(review['tags'] ?? review['Tags'] ?? []);

    String replyContent = '';
    final rawReply = review['reply'] ?? review['Reply'];
    if (rawReply != null) {
      if (rawReply is Map) {
        replyContent = rawReply['content'] ?? rawReply['Content'] ?? '';
      } else {
        replyContent = rawReply.toString();
      }
    }

    final likes = (review['likeCount'] ?? review['LikeCount'] ?? review['helpfulCount'] ?? review['HelpfulCount'] ?? 0) as int;

    return {
      'user': user,
      'rating': rating,
      'date': dateStr,
      'content': content,
      'images': images,
      'imageCount': imageCount,
      'tags': tags,
      'reply': replyContent,
      'likes': likes,
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const collapsedThreshold = 260.0 - kToolbarHeight;
    final collapsed = _scrollController.hasClients &&
        _scrollController.offset > collapsedThreshold;
    if (collapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = collapsed;
      });
    }
  }

  // Mock description
  String get _description {
    switch (widget.name) {
      case 'Combo 1: Phần gà + khoai':
        return 'Gà rán giòn rụm kèm khoai tây chiên. Phần ăn vừa đủ cho 1 người.';
      case 'Set sum vầy (4 người)':
        return 'Set gà rán đặc biệt cho 4 người, kèm khoai tây, nước uống và salad.';
      case 'Phở bò tái chín':
        return 'Nước dùng ninh 12 tiếng, thịt bò tái chín mềm ngọt. Kèm rau thơm và giá.';
      default:
        return 'Món ăn thơm ngon, được chế biến từ nguyên liệu tươi sạch mỗi ngày.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ─── Image Header ───────────────────────────────────
          _buildImageHeader(context),

          // ─── Food Info ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildFoodInfo(context)),

          // ─── Reviews Section ────────────────────────────────
          SliverToBoxAdapter(child: _buildReviewsHeader()),

          // ─── Review List or Loading ─────────────────────────
          _isLoadingReviews
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : (_reviewsErrorMessage != null
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _reviewsErrorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    )
                  : (_reviews.isNotEmpty
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildReviewCard(_reviews[index]),
                            childCount: _reviews.length,
                          ),
                        )
                      : SliverToBoxAdapter(child: _buildEmptyReviews()))),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      // ─── Bottom Add to Cart Bar ─────────────────────────────
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ─── Image Header ──────────────────────────────────────────────────────
  Widget _buildImageHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _isCollapsed ? Colors.white : AppColors.primary,
      elevation: 0,
      centerTitle: true,
      title: _isCollapsed
          ? Text(
              widget.name,
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
                color: _isCollapsed ? Colors.transparent : Colors.black26,
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
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isProductLiked = !_isProductLiked;
                if (_isProductLiked) {
                  _productLikes++;
                } else {
                  _productLikes--;
                }
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isCollapsed ? Colors.transparent : Colors.black26,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isProductLiked ? Icons.favorite : Icons.favorite_border,
                color: _isProductLiked
                    ? const Color(0xFFE55333)
                    : (_isCollapsed ? const Color(0xFFE55333) : Colors.white),
                size: _isCollapsed ? 22 : 18,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isCollapsed ? Colors.transparent : Colors.black26,
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
        background: Container(
          color: AppColors.bgWarm,
          child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              ? (widget.imageUrl!.startsWith('http')
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(widget.icon,
                          size: 100, color: AppColors.textTertiary),
                    )
                  : Image.asset(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(widget.icon,
                          size: 100, color: AppColors.textTertiary),
                    ))
              : Icon(widget.icon, size: 100, color: AppColors.textTertiary),
        ),
      ),
    );
  }

  // ─── Food Info Section ─────────────────────────────────────────────────
  Widget _buildFoodInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            _description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Sold + Likes
          Row(
            children: [
              Text(
                '${widget.sold} đã bán',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: AppColors.outlineVariant),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isProductLiked = !_isProductLiked;
                    if (_isProductLiked) {
                      _productLikes++;
                    } else {
                      _productLikes--;
                    }
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isProductLiked ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: _isProductLiked
                          ? const Color(0xFFE55333)
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_productLikes lượt thích',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isProductLiked
                            ? const Color(0xFFE55333)
                            : AppColors.textTertiary,
                        fontWeight: _isProductLiked
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Price row
          Row(
            children: [
              Text(
                widget.price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              // Add button
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddToCartPage(
                          name: widget.name,
                          price: widget.price,
                          icon: widget.icon,
                          imageUrl: widget.imageUrl,
                          menuItemId: widget.menuItemId,
                          branchId: widget.branchId,
                        ),
                      ));
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Reviews Header ────────────────────────────────────────────────────
  Widget _buildReviewsHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        'Bình luận',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─── Empty Reviews State ───────────────────────────────────────────────
  Widget _buildEmptyReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          // Illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.rate_review_outlined,
                size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có đánh giá',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cùng chia sẻ trải nghiệm đặt hàng của bạn với mọi người nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Review Card ───────────────────────────────────────────────────────
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final hasReply = (review['reply'] as String).isNotEmpty;
    final tags = List<String>.from(review['tags'] as List);
    final imageCount = review['imageCount'] as int;
    final images = List<String>.from(review['images'] ?? []);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (left)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.bgSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    size: 18, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 10),
              // All content (right)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Text(
                      review['user'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stars
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < (review['rating'] as int)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: AppColors.star,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Review content
                    Text(
                      review['content'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    // Review images
                    if (imageCount > 0) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 80,
                        child: Row(
                          children: List.generate(
                            imageCount > 3 ? 3 : imageCount,
                            (i) {
                              final isLast = i == 2 && imageCount > 3;
                              final imageUrl = i < images.length ? images[i] : '';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: AppColors.bgWarm,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  size: 28,
                                                  color: AppColors.textTertiary
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: AppColors.bgWarm,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 28,
                                                color: AppColors.textTertiary
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                    ),
                                    if (isLast)
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.photo_library,
                                                  size: 14,
                                                  color: Colors.white),
                                              const SizedBox(width: 3),
                                              Text(
                                                '+${imageCount - 2}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    // Likes
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final user = review['user'] as String;
                          if (_likedReviews.contains(user)) {
                            _likedReviews.remove(user);
                          } else {
                            _likedReviews.add(user);
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _likedReviews.contains(review['user'] as String)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color:
                                _likedReviews.contains(review['user'] as String)
                                    ? const Color(0xFFE55333)
                                    : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(review['likes'] as int? ?? tags.length) + (_likedReviews.contains(review['user'] as String) ? 1 : 0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _likedReviews
                                      .contains(review['user'] as String)
                                  ? const Color(0xFFE55333)
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Date
                    Text(
                      review['date'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    // Store reply
                    if (hasReply) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phản hồi từ Quán:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review['reply'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.3,
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  // ─── Bottom Add to Cart Bar ────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Price
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giá',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    widget.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Add to cart button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddToCartPage(
                          name: widget.name,
                          price: widget.price,
                          icon: widget.icon,
                          imageUrl: widget.imageUrl,
                          menuItemId: widget.menuItemId,
                          branchId: widget.branchId,
                        ),
                      ));
                  if (result != null && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Thêm vào giỏ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Store Reviews Page showing ratings breakdown, AI review summary, and a list of all dish comments.
/// Follows DineX Premium visual style and matches user's reference UI.
class StoreReviewsPage extends StatefulWidget {
  final String storeName;
  final String category;
  final double rating;
  final int reviewsCount;
  final String deliveryTime;
  final String distance;

  const StoreReviewsPage({
    super.key,
    required this.storeName,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.deliveryTime,
    required this.distance,
  });

  @override
  State<StoreReviewsPage> createState() => _StoreReviewsPageState();
}

class _StoreReviewsPageState extends State<StoreReviewsPage> {
  final Set<String> _likedReviews = {};
  String _selectedFilter = 'Tất cả';

  static const List<String> _filters = [
    'Tất cả',
    'Kèm hình ảnh',
    '5 sao',
    '4 sao',
    '3 sao',
    '2 sao',
    '1 sao'
  ];

  // Mock comments from various dishes of the restaurant
  final List<Map<String, dynamic>> _comments = [
    {
      'user': 'ngoc_anh_99',
      'rating': 5,
      'date': '05-06-2026 12:30',
      'content': 'Trà sữa ở đây rất thơm ngon, Milo dầm trân châu nhiều topping. Giao nhanh và đóng gói siêu cẩn thận luôn ạ!',
      'imageCount': 2,
      'tags': ['Milo Dầm Trân Châu'],
      'reply': 'Dạ quán cảm ơn bạn Ngọc Anh nhiều nha! Rất vui vì bạn đã có trải nghiệm hài lòng 🥰',
      'likes': 24,
    },
    {
      'user': 'hoang_duy',
      'rating': 5,
      'date': '04-06-2026 18:45',
      'content': 'Trà Nhãn Thái Lan siêu ngon ngọt mát lạnh, nhãn tươi cùi dày ăn giòn sần sật. Sẽ tiếp tục đặt tiếp món này.',
      'imageCount': 1,
      'tags': ['Trà Nhãn Thái Lan'],
      'reply': '',
      'likes': 15,
    },
    {
      'user': 'thuy_trang',
      'rating': 4,
      'date': '03-06-2026 15:10',
      'content': 'Trà Hoa Antiso uống lạ miệng nhưng rất thanh mát, ít ngọt đúng ý mình. Thêm đá lạnh uống giải nhiệt cực tốt.',
      'imageCount': 0,
      'tags': ['Trà Hoa Antiso'],
      'reply': '',
      'likes': 9,
    },
    {
      'user': 'hoang_lan_88',
      'rating': 3,
      'date': '01-06-2026 20:15',
      'content': 'Đặt combo 2 ly nhưng giao thiếu mất ống hút trân châu to nên hút hơi khó khăn 🥲 Vị nước thì vẫn ngon như mọi khi. Quán chú ý kiểm hàng kỹ hơn.',
      'imageCount': 0,
      'tags': [],
      'reply': 'Dạ quán thành thật xin lỗi bạn về sự sơ suất này ạ. Lần sau đặt bạn ghi chú để quán bù thêm cho bạn nha 🥺',
      'likes': 2,
    },
    {
      'user': 'minh_quan',
      'rating': 5,
      'date': '29-05-2026 11:20',
      'content': 'Quán ruột của mình luôn, đồ uống món nào cũng ngon hết nấc! Trân châu hoàng kim dẻo mềm thơm mùi mật ong.',
      'imageCount': 3,
      'tags': ['Trà Sữa Trân Châu', 'Milo Dầm Trân Châu'],
      'reply': 'Cảm ơn khách yêu đã luôn tin tưởng và ủng hộ tiệm ạ! Chúc bạn một ngày tràn đầy năng lượng nha 🥳',
      'likes': 31,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Đánh giá cửa hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Card 1: Store Information Summary ────────────────────────
            _buildStoreSummaryCard(),

            // ─── Card 2: Ratings Breakdown Section ───────────────────────
            _buildRatingBreakdownCard(),

            // ─── Card 3: AI Review Summary ───────────────────────────────
            _buildAISummaryCard(),

            // ─── List Section Header ─────────────────────────────────────
            _buildSectionHeader(),

            // ─── Filter Bar ──────────────────────────────────────────────
            _buildFilterBar(),
            const SizedBox(height: 12),

            // ─── Card 4: Comments List ───────────────────────────────────
            _buildCommentsList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Store Information Card ────────────────────────────────────────────────
  Widget _buildStoreSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name
          Text(
            widget.storeName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Store Category
          Text(
            widget.category,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Status + Distance Row (Clean UI matching screenshot)
          Row(
            children: [
              // Open Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đang mở cửa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đóng cửa vào ${widget.deliveryTime == '15 phút' ? '11:59 CH' : '10:00 CH'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Distance
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.distance,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Ratings Breakdown Section ─────────────────────────────────────────────
  Widget _buildRatingBreakdownCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Rating Summary
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
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
                    if (i < widget.rating.floor()) {
                      return const Icon(Icons.star_rounded, size: 16, color: AppColors.star);
                    } else if (i < widget.rating) {
                      return const Icon(Icons.star_half_rounded, size: 16, color: AppColors.star);
                    }
                    return const Icon(Icons.star_border_rounded, size: 16, color: AppColors.star);
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.reviewsCount} đánh giá',
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
                _buildStarProgressRow(5, 0.70),
                const SizedBox(height: 4),
                _buildStarProgressRow(4, 0.18),
                const SizedBox(height: 4),
                _buildStarProgressRow(3, 0.07),
                const SizedBox(height: 4),
                _buildStarProgressRow(2, 0.03),
                const SizedBox(height: 4),
                _buildStarProgressRow(1, 0.02),
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
                value: progress,
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
          const Text(
            'Nhiều món nước ngon mát, trái cây tươi sạch. Milo dầm trân châu ngọt thơm đậm đà, topping đầy đặn được yêu thích nhất. Giá cả ở mức trung bình cao nhưng hoàn toàn xứng đáng với chất lượng. Giao hàng cực kỳ nhanh và đóng gói cốc nước kỹ càng.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Comments List Section Header ──────────────────────────────────────────
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
    if (_selectedFilter == 'Tất cả') {
      return _comments;
    } else if (_selectedFilter == 'Kèm hình ảnh') {
      return _comments.where((c) => (c['imageCount'] as int) > 0).toList();
    } else if (_selectedFilter == '5 sao') {
      return _comments.where((c) => c['rating'] == 5).toList();
    } else if (_selectedFilter == '4 sao') {
      return _comments.where((c) => c['rating'] == 4).toList();
    } else if (_selectedFilter == '3 sao') {
      return _comments.where((c) => c['rating'] == 3).toList();
    } else if (_selectedFilter == '2 sao') {
      return _comments.where((c) => c['rating'] == 2).toList();
    } else if (_selectedFilter == '1 sao') {
      return _comments.where((c) => c['rating'] == 1).toList();
    }
    return _comments;
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
              'Chưa có bình luận nào phù hợp với bộ lọc đã chọn.',
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
        final user = review['user'] as String;
        final hasReply = (review['reply'] as String).isNotEmpty;
        final tags = List<String>.from(review['tags'] as List);
        final isLiked = _likedReviews.contains(user);
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
                child: const Icon(Icons.person, size: 20, color: AppColors.textTertiary),
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
                    Text(
                      review['content'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    // Mock image placeholders
                    if (review['imageCount'] as int > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(
                          review['imageCount'] as int,
                          (i) => Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bgWarm,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 24,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
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

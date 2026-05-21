import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

/// Search Page — shows search suggestions and recommended stores.
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  // Mock search history
  final List<String> _searchHistory = [
    'Phở bò tái', 'Cơm sườn nướng', 'Trà sữa trân châu',
  ];

  // Mock search suggestions
  static const _suggestions = [
    'Phở', 'Cơm', 'Bún bò', 'Trà sữa', 'Gà rán',
    'Cơm tấm', 'Bánh mì', 'Lẩu', 'Pizza', 'Sushi',
  ];

  // Mock recommended stores
  static final _recommendedStores = [
    _Store(name: 'BMC Phở Express', address: 'Chi nhánh Q1', distance: '1.2km', rating: 4.8, image: 'assets/images/pho.jpg'),
    _Store(name: 'Phở Bò Tái Nạm', address: '256 Hùng Vương', distance: '2.1km', rating: 4.5, image: 'assets/images/pho_bo.png'),
    _Store(name: 'Cơm Văn Phòng', address: '45 Trần Phú', distance: '0.8km', rating: 4.3, image: 'assets/images/com.webp'),
    _Store(name: 'Trà Sữa ToCoToCo', address: '12 Lê Lợi', distance: '1.5km', rating: 4.6, image: 'assets/images/tra_sua.jpg'),
    _Store(name: 'BMC Phở Gà', address: 'Chi nhánh Q3', distance: '3.2km', rating: 4.7, image: 'assets/images/pho.jpg'),
    _Store(name: 'Cơm Tấm Sài Gòn', address: '89 Nguyễn Huệ', distance: '2.5km', rating: 4.4, image: 'assets/images/com.webp'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    if (_searchHistory.isNotEmpty) _buildHistorySection(),
                    if (_searchHistory.isNotEmpty) const SizedBox(height: 24),
                    _buildSuggestionsSection(),
                    const SizedBox(height: 24),
                    _buildRecommendedSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  // ─── Search Header ─────────────────────────────────────────────────────
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            // Search field (white, same as home)
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Bạn có muốn ăn gì không?',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── History Section ────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử tìm kiếm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _searchHistory.clear()),
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((s) => _buildHistoryChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        setState(() => _query = text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _searchHistory.remove(text)),
              child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Suggestions Section ───────────────────────────────────────────────
  Widget _buildSuggestionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) => _buildSuggestionChip(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        setState(() => _query = text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recommended Section ───────────────────────────────────────────────
  Widget _buildRecommendedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Được đề xuất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: _recommendedStores.length,
            itemBuilder: (_, index) => _buildStoreCard(_recommendedStores[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(_Store store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store image
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(store.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Store name
        Text(
          store.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        // Distance + rating
        Row(
          children: [
            Text(
              store.distance,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (store.rating > 0) ...[
              const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
              const SizedBox(width: 2),
              Text(
                store.rating.toString(),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────
class _Store {
  final String name;
  final String address;
  final String distance;
  final double rating;
  final String image;

  _Store({
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.image,
  });
}

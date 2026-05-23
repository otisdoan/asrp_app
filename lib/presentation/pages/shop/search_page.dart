import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/mock_data.dart';
import 'store_detail_page.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../data/models/category_model.dart';

/// Search Page — two states:
/// 1. Typing: autocomplete suggestions
/// 2. Submitted: search results with filters + store/food cards
/// Follows RULE: UI-only widgets, AppColors 100%, responsive.
class SearchPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  const SearchPage({super.key, this.initialCategory});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  bool _submitted = false;
  String _selectedFilter = 'Đúng nhất';
  String? _selectedCategory;

  // Mock autocomplete data
  static const _allSuggestions = [
    'Phở', 'Phở bò tái', 'Phở gà', 'Phở bò viên',
    'Cơm', 'Cơm tấm', 'Cơm sườn', 'Cơm gà',
    'Bún bò', 'Bún bò Huế', 'Bún chả',
    'Trà sữa', 'Trà sữa trân châu', 'Trà đào',
    'Bánh canh', 'Bánh canh cua', 'Bánh canh cá lóc', 'Bánh canh ghẹ',
    'Bánh mì', 'Gà rán', 'Lẩu', 'Pizza',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _query = widget.initialCategory!;
      _searchController.text = widget.initialCategory!;
      _submitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCategoryProvider.notifier).state = widget.initialCategory!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmitted(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      _submitted = true;
      _query = value.trim();
    });
    _focusNode.unfocus();
  }

  List<String> _getAutocompleteSuggestions() {
    if (_query.isEmpty) return [];
    return _allSuggestions
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(selectedCategoryProvider.notifier).state = 'Tất cả';
          ref.read(menuCurrentPageProvider.notifier).state = 1;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _submitted ? _buildResultsView() : _buildTypingView(),
            ),
          ],
        ),
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
            // Search field
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
                        onChanged: (v) => setState(() {
                          _query = v;
                          _submitted = false;
                        }),
                        onSubmitted: _onSubmitted,
                        textInputAction: TextInputAction.search,
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
                          setState(() {
                            _query = '';
                            _submitted = false;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE 1: TYPING — Autocomplete suggestions
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTypingView() {
    final suggestions = _getAutocompleteSuggestions();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Autocomplete suggestions
        if (suggestions.isNotEmpty) ...[
          ...suggestions.map((s) => _buildSuggestionItem(s)),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Search in categories
          _buildSearchInCategory('Nhà hàng'),
          _buildSearchInCategory('Món ăn'),
        ],
        // Default state (no query yet)
        if (_query.isEmpty) ...[
          const SizedBox(height: 12),
          _buildHistorySection(),
          const SizedBox(height: 24),
          _buildQuickSuggestionsSection(),
          const SizedBox(height: 24),
          _buildRecommendedSection(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSuggestionItem(String text) {
    // Highlight matching part
    final lowerQuery = _query.toLowerCase();
    final lowerText = text.toLowerCase();
    final matchStart = lowerText.indexOf(lowerQuery);

    return InkWell(
      onTap: () {
        _searchController.text = text;
        _onSubmitted(text);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 14),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  children: matchStart >= 0
                      ? [
                          TextSpan(text: text.substring(0, matchStart)),
                          TextSpan(
                            text: text.substring(matchStart, matchStart + _query.length),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: text.substring(matchStart + _query.length)),
                        ]
                      : [TextSpan(text: text)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInCategory(String category) {
    return InkWell(
      onTap: () => _onSubmitted(_query),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
            children: [
              const TextSpan(text: 'Tìm kiếm "'),
              TextSpan(
                text: _query,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: '" trong $category'),
            ],
          ),
        ),
      ),
    );
  }

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
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {}),
                child: const Text(
                  'Xóa',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._buildHistoryItems(),
        ],
      ),
    );
  }

  List<Widget> _buildHistoryItems() {
    final history = ['Phở bò tái', 'Cơm sườn nướng', 'Trà sữa trân châu'];
    return history.map((item) => InkWell(
      onTap: () {
        _searchController.text = item;
        _onSubmitted(item);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ),
            Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    )).toList();
  }

  Widget _buildQuickSuggestionsSection() {
    const suggestions = ['Phở', 'Cơm', 'Bún bò', 'Trà sữa', 'Gà rán', 'Cơm tấm', 'Bánh mì'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) => GestureDetector(
              onTap: () {
                _searchController.text = s;
                _onSubmitted(s);
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
                    Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final stores = [
      {'name': 'BMC Phở Express', 'distance': '1.2km', 'rating': 4.8, 'image': 'assets/images/pho.jpg'},
      {'name': 'Phở Bò Tái Nạm', 'distance': '2.1km', 'rating': 4.5, 'image': 'assets/images/pho_bo.png'},
      {'name': 'Cơm Văn Phòng', 'distance': '0.8km', 'rating': 4.3, 'image': 'assets/images/com.webp'},
      {'name': 'Trà Sữa ToCoToCo', 'distance': '1.5km', 'rating': 4.6, 'image': 'assets/images/tra_sua.jpg'},
      {'name': 'BMC Phở Gà', 'distance': '3.2km', 'rating': 4.7, 'image': 'assets/images/pho.jpg'},
      {'name': 'Cơm Tấm Sài Gòn', 'distance': '2.5km', 'rating': 4.4, 'image': 'assets/images/com.webp'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Được đề xuất',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
            itemCount: stores.length,
            itemBuilder: (_, index) {
              final store = stores[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: AssetImage(store['image'] as String),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store['name'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        store['distance'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        store['rating'].toString(),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildResultsView() {
    return Column(
      children: [
        if (_selectedCategory != null) _buildCategoryRow(),
        _buildFilterChips(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _storeResults.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (_, index) => _buildStoreResultCard(_storeResults[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow() {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    return categoriesAsync.when(
      data: (categories) => _buildCategoryList(categories.isEmpty ? MockData.categories : categories),
      loading: () => _buildCategoryList(MockData.categories),
      error: (err, stack) => _buildCategoryList(MockData.categories),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, index) {
            final cat = categories[index];
            final name = cat.name;
            final image = cat.imageUrl;
            final isSelected = _selectedCategory == name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = name;
                  _query = name;
                  _searchController.text = name;
                });
                ref.read(selectedCategoryProvider.notifier).state = name;
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: image.startsWith('http')
                              ? Image.network(
                                  image,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : Image.asset(
                                  image,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.restaurant_menu_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _FilterSheetContent(),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Đúng nhất', 'Gần tôi', 'Bán chạy', 'Đánh giá', 'Khuyến mãi'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showFilterSheet(),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.tune, size: 16, color: Colors.grey[600]),
              ),
            ),
            ...filters.map((f) {
              final isSelected = f == _selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Mock store results with food items
  static final _storeResults = [
    _StoreResult(
      name: 'BÚN, BÁNH CANH & CƠM GÀ XỐI MỠ - 296 Diên Hồng',
      rating: 4.9,
      distance: '6.9km',
      time: '37 phút',
      discount: 'Mã giảm 19%',
      image: 'assets/images/pho.jpg',
      foods: [
        _FoodItem(name: 'Bánh canh chả cá', price: '27.000', image: 'assets/images/pho.jpg'),
        _FoodItem(name: 'Bánh canh xương bò', price: '32.000', image: 'assets/images/pho_bo.png'),
        _FoodItem(name: 'Bánh canh riêu', price: '27.000', image: 'assets/images/com.webp'),
        _FoodItem(name: 'Bánh canh tái', price: '30.000', image: 'assets/images/tra_sua.jpg'),
      ],
    ),
    _StoreResult(
      name: 'Bánh Canh & Bánh Cuốn - Phượng - 423 Nguyễn Thị Minh Khai',
      rating: 4.8,
      distance: '7.8km',
      time: '42 phút',
      discount: 'Mã giảm 11%',
      image: 'assets/images/pho_bo.png',
      foods: [
        _FoodItem(name: 'Bánh Canh Chả Cá (sợi to)', price: '32.000', image: 'assets/images/pho_bo.png'),
        _FoodItem(name: 'Bánh Canh Chả Cá (sợi nhỏ)', price: '32.000', image: 'assets/images/pho.jpg'),
        _FoodItem(name: 'Bánh Canh Xương (sợi to)', price: '38.000', image: 'assets/images/com.webp'),
        _FoodItem(name: 'Bánh Canh Đặc Biệt', price: '52.000', image: 'assets/images/tra_sua.jpg'),
      ],
    ),
    _StoreResult(
      name: 'Bếp Mẹ Gấu - Bún Thịt Nướng, Bánh Canh & Cơm - Nguyễn Thị Minh Khai',
      rating: 4.8,
      distance: '7.2km',
      time: '37 phút',
      discount: 'Mã giảm 19%',
      image: 'assets/images/com.webp',
      foods: [
        _FoodItem(name: 'Cơm sườn nướng', price: '35.000', image: 'assets/images/com.webp'),
        _FoodItem(name: 'Bún thịt nướng', price: '30.000', image: 'assets/images/pho.jpg'),
        _FoodItem(name: 'Bánh canh cua', price: '40.000', image: 'assets/images/pho_bo.png'),
        _FoodItem(name: 'Cơm gà xối mỡ', price: '38.000', image: 'assets/images/tra_sua.jpg'),
      ],
    ),
  ];

  Widget _buildStoreResultCard(_StoreResult store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Store image only
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StoreDetailPage(
                  storeName: store.name,
                  category: 'Đồ ăn · Đồ uống',
                  rating: store.rating,
                  reviews: 150,
                  deliveryTime: store.time,
                  distance: store.distance,
                  icon: Icons.store,
                ),
              ));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                store.image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Right: All content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StoreDetailPage(
                        storeName: store.name,
                        category: 'Đồ ăn · Đồ uống',
                        rating: store.rating,
                        reviews: 150,
                        deliveryTime: store.time,
                        distance: store.distance,
                        icon: Icons.store,
                      ),
                    ));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name with verified badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified, color: AppColors.success, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Rating | Distance | Time
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 3),
                          Text(
                            '${store.rating}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                          _buildInfoDivider(),
                          Text(store.distance, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          _buildInfoDivider(),
                          Text(store.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          store.discount,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Food items horizontal scroll
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.foods.length,
                    itemBuilder: (_, index) {
                      final food = store.foods[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => StoreDetailPage(
                              storeName: store.name,
                              category: 'Đồ ăn · Đồ uống',
                              rating: store.rating,
                              reviews: 150,
                              deliveryTime: store.time,
                              distance: store.distance,
                              icon: Icons.store,
                              highlightFoodName: food.name,
                            ),
                          ));
                        },
                        child: Container(
                          width: 105,
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  food.image,
                                  width: 105,
                                  height: 85,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                food.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.2),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${food.price}đ',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 1,
        height: 12,
        color: AppColors.outlineVariant,
      ),
    );
  }
}

// ─── Filter Sheet ────────────────────────────────────────────────────────────
class _FilterSheetContent extends StatefulWidget {
  const _FilterSheetContent();
  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  // Lọc theo
  String _sortBy = 'Được đề xuất';
  // Tùy chọn quán
  final Set<String> _storeOptions = {};
  // Phí giao hàng
  String _deliveryFee = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.85,
      minChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24, color: AppColors.textPrimary),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // ─── Lọc theo ───
                _buildSectionTitle('Lọc theo'),
                const SizedBox(height: 12),
                _buildRadioItem(Icons.thumb_up_outlined, 'Được đề xuất', _sortBy, (v) => setState(() => _sortBy = v)),
                _buildRadioItem(Icons.star_outline, 'Đánh giá', _sortBy, (v) => setState(() => _sortBy = v)),
                _buildRadioItem(Icons.location_on_outlined, 'Khoảng cách', _sortBy, (v) => setState(() => _sortBy = v)),
                const Divider(height: 32),

                // ─── Tùy chọn quán ───
                _buildSectionTitle('Tùy chọn quán'),
                const SizedBox(height: 12),
                _buildCheckboxItem(Icons.star_outline, 'Từ 4.4 sao', 'rating'),
                _buildCheckboxItem(Icons.local_offer_outlined, 'Khuyến mãi', 'promo'),
                _buildCheckboxItem(Icons.local_fire_department_outlined, 'Bán chạy', 'bestseller'),
                _buildCheckboxItem(Icons.near_me_outlined, 'Gần đây', 'nearby'),
                const Divider(height: 32),

                // ─── Giá ───
                _buildSectionTitle('Giá'),
                const SizedBox(height: 12),
                _buildRadioItem(null, 'Tất cả', _deliveryFee, (v) => setState(() => _deliveryFee = v)),
                _buildRadioItem(null, 'Dưới 30.000đ', _deliveryFee, (v) => setState(() => _deliveryFee = v)),
                _buildRadioItem(null, 'Dưới 50.000đ', _deliveryFee, (v) => setState(() => _deliveryFee = v)),
                _buildRadioItem(null, 'Dưới 100.000đ', _deliveryFee, (v) => setState(() => _deliveryFee = v)),
                const Divider(height: 32),

                // ─── Loại ẩm thực ───
                _buildSectionTitle('Loại ẩm thực'),
                const SizedBox(height: 12),
                _buildCuisineGrid(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortBy = 'Được đề xuất';
                        _storeOptions.clear();
                        _deliveryFee = 'Tất cả';
                      });
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineVariant),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    );
  }

  Widget _buildRadioItem(IconData? icon, String label, String groupValue, ValueChanged<String> onChanged) {
    final isSelected = label == groupValue;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 10, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(IconData icon, String label, String key) {
    final isChecked = _storeOptions.contains(key);
    return GestureDetector(
      onTap: () => setState(() {
        if (isChecked) {
          _storeOptions.remove(key);
        } else {
          _storeOptions.add(key);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isChecked ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isChecked ? AppColors.primary : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineGrid() {
    final cuisines = [
      {'name': 'Phở', 'image': 'assets/images/pho.jpg'},
      {'name': 'Bún', 'image': 'assets/images/pho_bo.png'},
      {'name': 'Cơm', 'image': 'assets/images/com.webp'},
      {'name': 'Đồ uống', 'image': 'assets/images/tra_sua.jpg'},
      {'name': 'Tráng miệng', 'image': 'assets/images/tra_sua.jpg'},
      {'name': 'Mì', 'image': 'assets/images/pho.jpg'},
      {'name': 'Chay', 'image': 'assets/images/com.webp'},
      {'name': 'Đồ ăn vặt', 'image': 'assets/images/pho_bo.png'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cuisines.map((c) => SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  c['image']!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              c['name']!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────
class _StoreResult {
  final String name;
  final double rating;
  final String distance;
  final String time;
  final String discount;
  final String image;
  final List<_FoodItem> foods;

  _StoreResult({
    required this.name,
    required this.rating,
    required this.distance,
    required this.time,
    required this.discount,
    required this.image,
    required this.foods,
  });
}

class _FoodItem {
  final String name;
  final String price;
  final String image;

  _FoodItem({required this.name, required this.price, required this.image});
}


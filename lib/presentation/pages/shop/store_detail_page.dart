import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/favorite_shops_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/menu_item_model.dart';
import 'food_detail_page.dart';
import 'checkout_page.dart';

/// Store Detail Page — shows store info, promos, popular items, and full menu.
/// Follows RULE: UI-only, uses AppColors, responsive.
class StoreDetailPage extends ConsumerStatefulWidget {
  final String storeName;
  final String category;
  final double rating;
  final int reviews;
  final String deliveryTime;
  final String distance;
  final IconData icon;
  final String? highlightFoodName;

  const StoreDetailPage({
    super.key,
    required this.storeName,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.deliveryTime,
    required this.distance,
    required this.icon,
    this.highlightFoodName,
  });

  @override
  ConsumerState<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends ConsumerState<StoreDetailPage> {
  int _selectedCategoryIndex = 0;
  bool _isCollapsed = false;
  bool _isTabTapping = false;
  late ScrollController _scrollController;
  late List<GlobalKey> _sectionKeys;

  // Cart state
  int _cartItemCount = 0;
  int _cartTotal = 0;

  // Search state
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool _isSearchActive = false;

  // Highlight key for auto-scrolling
  final GlobalKey _highlightedItemKey = GlobalKey();
  String? _firstMatchingFoodName;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _sectionKeys = List.generate(6, (_) => GlobalKey());

    // Search initialization
    _searchController = TextEditingController(text: widget.highlightFoodName ?? '');
    _searchQuery = widget.highlightFoodName ?? '';
    _isSearchActive = widget.highlightFoodName != null && widget.highlightFoodName!.isNotEmpty;

    _findFirstMatchingFood();

    if (_searchQuery.isNotEmpty) {
      _activateTabForHighlightedItem();
    }

    // Auto-scroll to highlighted item
    if (_firstMatchingFoodName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) {
            _scrollToHighlightedItem();
          }
        });
      });
    }
  }

  void _findFirstMatchingFood() {
    if (_searchQuery.isEmpty) {
      _firstMatchingFoodName = null;
      return;
    }
    final allItems = _getMenuItems();
    for (final item in allItems) {
      if (item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        _firstMatchingFoodName = item.name;
        return;
      }
    }
    _firstMatchingFoodName = null;
  }

  void _scrollToHighlightedItem() {
    if (_searchQuery.isEmpty || _firstMatchingFoodName == null) return;

    // 1. Find which category contains the matching product
    final categories = _getCategories();
    final allItems = _getMenuItems();
    
    int targetCategoryIndex = -1;
    for (final item in allItems) {
      if (item.name == _firstMatchingFoodName) {
        // Find category index
        targetCategoryIndex = categories.indexWhere((cat) => cat.id == item.categoryId);
        break;
      }
    }

    if (targetCategoryIndex == -1) return;

    // 2. Set the active tab state
    setState(() {
      _selectedCategoryIndex = targetCategoryIndex;
    });

    // 3. Scroll to the category header first
    final categoryKey = _sectionKeys[targetCategoryIndex];
    if (categoryKey.currentContext != null) {
      _isTabTapping = true;
      Scrollable.ensureVisible(
        categoryKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) {
        _isTabTapping = false;
        _scrollItemIntoView();
      });
    } else {
      _scrollItemIntoView();
    }
  }

  void _scrollItemIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _highlightedItemKey.currentContext != null) {
          Scrollable.ensureVisible(
            _highlightedItemKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            alignment: 0.12,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > 140;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }

    // Auto-highlight tab based on visible section
    if (_isTabTapping) return;
    _updateActiveTab();
  }

  void _updateActiveTab() {
    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      if (key.currentContext == null) continue;
      final box = key.currentContext!.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero);
      // If the section title is at or above the tabs area (~kToolbarHeight + 48)
      if (position.dy <= kToolbarHeight + 100) {
        if (_selectedCategoryIndex != i) {
          setState(() => _selectedCategoryIndex = i);
        }
        return;
      }
    }
  }

  void _activateTabForHighlightedItem() {
    if (_searchQuery.isEmpty) return;
    final categories = _getCategories();
    final allItems = _getMenuItems();
    
    for (final item in allItems) {
      if (item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        final catIndex = categories.indexWhere((cat) => cat.id == item.categoryId);
        if (catIndex != -1) {
          setState(() {
            _selectedCategoryIndex = catIndex;
          });
        }
        return;
      }
    }
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key.currentContext == null) return;
    _isTabTapping = true;
    setState(() => _selectedCategoryIndex = index);
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    ).then((_) {
      _isTabTapping = false;
    });
  }

  // Helper methods to get data from providers
  List<CategoryModel> _getCategories() {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    return categoriesAsync.maybeWhen(
      data: (categories) {
        print('[UI Check] StoreDetail: Đã nạp thành công ${categories.length} Danh mục (Tab).');
        return categories;
      },
      orElse: () => [],
    );
  }

  List<MenuItemModel> _getMenuItems() {
    final menuAsync = ref.watch(branchMenuItemsProvider);
    return menuAsync.maybeWhen(
      data: (items) {
        print('[UI Check] StoreDetail: Đã nạp thành công ${items.length} Món ăn thuộc chi nhánh này.');
        return items;
      },
      orElse: () => [],
    );
  }

  List<MenuItemModel> _getPopularItems() {
    final allItems = _getMenuItems();
    // Filter items with soldCount > 100 or sort by soldCount
    final popular = allItems.where((item) => (item.soldCount ?? 0) > 100).toList();
    popular.sort((a, b) => (b.soldCount ?? 0).compareTo(a.soldCount ?? 0));
    final result = popular.take(6).toList();
    print('[UI Check] StoreDetail: Đã lọc được ${result.length} Món phổ biến (soldCount > 100).');
    return result;
  }

  // Mock promos (keeping for now - can be replaced with API later)
  static const _promos = [
    'Giảm 50% · Đơn từ 55k',
    'Giảm 50% · Đơn từ 55k',
    'Giảm 50% · Đơn từ 99k',
    'Freeship · Đơn từ 30k',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ─── App Bar with image ─────────────────────────────
          _buildSliverAppBar(context),

          // ─── Store Info ─────────────────────────────────────
          SliverToBoxAdapter(child: _buildStoreInfo()),

          // ─── Delivery Info ──────────────────────────────────
          SliverToBoxAdapter(child: _buildDeliveryInfo()),

          // ─── Promos ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildPromos()),

          // ─── Popular Items ──────────────────────────────────
          SliverToBoxAdapter(child: _buildPopularItems()),

          // Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ─── Category Tabs ──────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryTabsDelegate(
              categories: _getCategories().map((c) => c.name).toList(),
              selectedIndex: _selectedCategoryIndex,
              onSelected: _scrollToSection,
            ),
          ),

          // ─── All Menu Items grouped by category ──────────
          ..._buildAllMenuSections(),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      // ─── Floating Cart Bar ─────────────────────────────────
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartBar() : null,
    );
  }

  // ─── Cart Bar ──────────────────────────────────────────────────────────
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => CheckoutPage(
                storeName: widget.storeName,
                itemCount: _cartItemCount,
                distance: widget.distance,
                icon: widget.icon,
              ),
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppColors.onPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Giỏ hàng - $_cartItemCount món',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_formatCartPrice(_cartTotal)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCartPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _handleCartResult(dynamic result) {
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _cartItemCount += result['quantity'] as int;
        _cartTotal += result['total'] as int;
      });
    }
  }

  // ─── Build all menu sections (category title + items) ───────────────────
  List<Widget> _buildAllMenuSections() {
    final List<Widget> slivers = [];
    final categories = _getCategories();
    final allItems = _getMenuItems();

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final items = allItems.where((item) => item.categoryId == category.id).toList();

      print('[UI Check] StoreDetail: Đang vẽ Section cho Danh mục "${category.name}" với ${items.length} món ăn.');

      if (items.isEmpty) continue;

      // Category title
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            key: _sectionKeys[i],
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '${category.name} (${items.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );

      // Category items
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildMenuItem(items[index]),
            childCount: items.length,
          ),
        ),
      );
    }

    return slivers;
  }

  // ─── Sliver App Bar ──────────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: (_isCollapsed || _isSearchActive)
          ? Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 18, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                          _isSearchActive = _searchQuery.isNotEmpty;
                          _findFirstMatchingFood();
                        });
                        if (_isSearchActive) {
                          _activateTabForHighlightedItem();
                          _scrollToHighlightedItem();
                        }
                      },
                      onSubmitted: (value) {
                        _scrollToHighlightedItem();
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: 'Tìm món trong quán',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
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
                  if (_searchController.text.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _isSearchActive = false;
                          _firstMatchingFoodName = null;
                        });
                      },
                      child: const Icon(Icons.close, size: 18, color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            )
          : null,
      actions: [
        if (!_isCollapsed && !_isSearchActive)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearchActive = true;
              });
            },
          ),
        Consumer(
          builder: (context, ref, child) {
            final favorites = ref.watch(favoriteShopsProvider);
            final isFav = favorites.contains(widget.storeName);
            return IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? const Color(0xFFFF2A55) : Colors.white,
              ),
              onPressed: () {
                ref.read(favoriteShopsProvider.notifier).toggleFavorite(widget.storeName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFav
                          ? 'Đã xóa "${widget.storeName}" khỏi cửa hàng yêu thích'
                          : 'Đã thêm "${widget.storeName}" vào cửa hàng yêu thích',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            );
          },
        ),
        IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.bgWarm,
          child: Icon(widget.icon, size: 80, color: AppColors.textTertiary),
        ),
      ),
    );
  }


  // ─── Store Info Section ──────────────────────────────────────────────────
  Widget _buildStoreInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Yêu thích" badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Yêu thích',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              // Verified icon
              const Icon(Icons.verified, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              // Store name
              Expanded(
                child: Text(
                  widget.storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rating + Reviews + Time + Favorite
          Row(
            children: [
              // Stars (compact)
              ...List.generate(5, (i) {
                if (i < widget.rating.floor()) {
                  return const Icon(Icons.star, size: 14, color: AppColors.star);
                } else if (i < widget.rating) {
                  return const Icon(Icons.star_half, size: 14, color: AppColors.star);
                }
                return const Icon(Icons.star_border, size: 14, color: AppColors.star);
              }),
              const SizedBox(width: 4),
              // Rating + reviews (flexible to prevent overflow)
              Flexible(
                child: Text(
                  '${widget.rating} (${widget.reviews}+ Bình luận) >',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Divider
              Container(width: 1, height: 14, color: AppColors.outlineVariant),
              const SizedBox(width: 8),
              // Delivery time
              const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                widget.deliveryTime,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              // Favorite
              Consumer(
                builder: (context, ref, child) {
                  final isFav = ref.watch(favoriteShopsProvider).contains(widget.storeName);
                  return GestureDetector(
                    onTap: () {
                      ref.read(favoriteShopsProvider.notifier).toggleFavorite(widget.storeName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav
                                ? 'Đã xóa "${widget.storeName}" khỏi yêu thích'
                                : 'Đã thêm "${widget.storeName}" vào yêu thích',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFav ? const Color(0xFFFF2A55) : AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Delivery Info Section ──────────────────────────────────────────────
  Widget _buildDeliveryInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          // Delivery row
          Row(
            children: [
              const Icon(Icons.delivery_dining, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              const Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Giao ngay  ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Dự kiến giao lúc 16:05',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Thay đổi >',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Promo row
          Row(
            children: [
              const Icon(Icons.local_offer, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ưu đãi dành cho bạn',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Xem thêm >',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Promos Section ─────────────────────────────────────────────────────
  Widget _buildPromos() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _promos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                border: Border.all(color: const Color(0xFF80CBC4)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _promos[index],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF00897B)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Popular Items Section ──────────────────────────────────────────────
  Widget _buildPopularItems() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Món phổ biến',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getPopularItems().length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final item = _getPopularItems()[index];
                return _buildPopularItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItemCard(MenuItemModel item) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoodDetailPage(
            name: item.name,
            price: item.price,
            sold: '${item.soldCount ?? 0}+',
            likes: 0,
            icon: Icons.fastfood,
          ),
        ));
        _handleCartResult(result);
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with sold badge
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: AppColors.bgWarm,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => 
                            const Icon(Icons.fastfood, size: 32, color: AppColors.textTertiary))
                        : const Icon(Icons.fastfood, size: 32, color: AppColors.textTertiary),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.soldCount ?? 0}+ đã bán',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.price,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ],
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

  // ─── Menu Item Card ─────────────────────────────────────────────────────
  Widget _buildMenuItem(MenuItemModel item) {
    final isHighlighted = _firstMatchingFoodName != null &&
        item.name.toLowerCase() == _firstMatchingFoodName!.toLowerCase();

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoodDetailPage(
            name: item.name,
            price: item.price,
            sold: '${item.soldCount ?? 0}+',
            likes: 0,
            icon: Icons.fastfood,
          ),
        ));
        _handleCartResult(result);
      },
      child: Container(
        key: isHighlighted ? _highlightedItemKey : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.bgSoft : Colors.transparent,
          border: isHighlighted
              ? Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5)
              : null,
          borderRadius: isHighlighted ? BorderRadius.circular(12) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.bgWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => 
                      const Icon(Icons.fastfood, size: 28, color: AppColors.textTertiary))
                  : const Icon(Icons.fastfood, size: 28, color: AppColors.textTertiary),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.soldCount ?? 0}+ đã bán',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '0 lượt thích',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Add button
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Tabs Persistent Header Delegate ──────────────────────────────
class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  _CategoryTabsDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, index) {
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        categories[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 2,
                        width: 30,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabsDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

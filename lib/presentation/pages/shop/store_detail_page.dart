import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/favorite_shops_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../providers/branch_provider.dart';
import 'food_detail_page.dart';
import 'checkout_page.dart';
import 'store_reviews_page.dart';

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
  final String? branchId;

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
    this.branchId,
  });

  @override
  ConsumerState<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends ConsumerState<StoreDetailPage> {
  // ── Performance: use ValueNotifier so scroll NEVER calls setState ──
  final ValueNotifier<int> _selectedCategoryNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isCollapsedNotifier = ValueNotifier<bool>(false);
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
  BranchDetailModel? _lastResolvedDetail;

  // ── Performance: cached computed values ──
  List<dynamic>? _cachedMenuItems;
  List<String>? _cachedCategories;
  static final _priceRegExp = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

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

  List<dynamic> get _currentMenuItems {
    if (_cachedMenuItems != null) return _cachedMenuItems!;
    final detailVal = _lastResolvedDetail;
    if (detailVal != null) {
      final menu = detailVal.menu;
      if (menu != null && menu.isNotEmpty) {
        final dynamicSections = menu.map((e) => e.items).toList();
        _cachedMenuItems = [ _popularItems, ...dynamicSections ];
        return _cachedMenuItems!;
      }
    }
    return [ _popularItems ];
  }

  List<String> get _currentCategories {
    if (_cachedCategories != null) return _cachedCategories!;
    final detailVal = _lastResolvedDetail;
    if (detailVal != null) {
      final menu = detailVal.menu;
      if (menu != null && menu.isNotEmpty) {
        final dynamicCats = menu.map((e) => e.name).toList();
        _cachedCategories = [ 'Món phổ biến', ...dynamicCats ];
        return _cachedCategories!;
      }
    }
    return [ 'Món phổ biến' ];
  }

  void _invalidateMenuCache() {
    _cachedMenuItems = null;
    _cachedCategories = null;
  }

  void _findFirstMatchingFood() {
    if (_searchQuery.isEmpty) {
      _firstMatchingFoodName = null;
      return;
    }
    final itemsList = _currentMenuItems;
    for (int i = 0; i < itemsList.length; i++) {
      final items = itemsList[i] as List<dynamic>;
      for (final item in items) {
        final String name = item is MenuItemModel ? item.name : (item['name'] as String);
        if (name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          _firstMatchingFoodName = name;
          return;
        }
      }
    }
    _firstMatchingFoodName = null;
  }

  void _scrollToHighlightedItem() {
    if (_searchQuery.isEmpty || _firstMatchingFoodName == null) return;

    final itemsList = _currentMenuItems;
    // 1. Find which category contains the matching product
    int targetCategoryIndex = -1;
    for (int i = 0; i < itemsList.length; i++) {
      final items = itemsList[i] as List<dynamic>;
      for (final item in items) {
        final String name = item is MenuItemModel ? item.name : (item['name'] as String);
        if (name == _firstMatchingFoodName) {
          targetCategoryIndex = i;
          break;
        }
      }
      if (targetCategoryIndex != -1) break;
    }

    if (targetCategoryIndex == -1) return;

    // 2. Set the active tab state (no setState needed)
    _selectedCategoryNotifier.value = targetCategoryIndex;

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
    _selectedCategoryNotifier.dispose();
    _isCollapsedNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update notifier — NO setState, only the ValueListenableBuilder rebuilds
    final collapsed = _scrollController.offset > 140;
    if (collapsed != _isCollapsedNotifier.value) {
      _isCollapsedNotifier.value = collapsed;
    }

    if (_isTabTapping) return;
    _updateActiveTab();
  }

  void _updateActiveTab() {
    int newIndex = _selectedCategoryNotifier.value;
    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      if (key.currentContext == null) continue;
      final box = key.currentContext!.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final position = box.localToGlobal(Offset.zero);
      if (position.dy <= kToolbarHeight + 100) {
        newIndex = i;
        break;
      }
    }
    // Update notifier — NO setState, only the ValueListenableBuilder rebuilds
    if (newIndex != _selectedCategoryNotifier.value) {
      _selectedCategoryNotifier.value = newIndex;
    }
  }

  void _activateTabForHighlightedItem() {
    if (_searchQuery.isEmpty) return;
    final itemsList = _currentMenuItems;
    for (int i = 0; i < itemsList.length; i++) {
      final items = itemsList[i] as List<dynamic>;
      for (final item in items) {
        final String name = item is MenuItemModel ? item.name : (item['name'] as String);
        if (name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          _selectedCategoryNotifier.value = i;
          return;
        }
      }
    }
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key.currentContext == null) return;
    _isTabTapping = true;
    _selectedCategoryNotifier.value = index;
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    ).then((_) {
      _isTabTapping = false;
    });
  }



  // Mock popular items (horizontal scroll)
  static const _popularItems = [
    {'name': 'Set sum vầy', 'sold': '600+', 'price': '53.000đ', 'icon': Icons.dinner_dining},
    {'name': 'Gà rán combo', 'sold': '200+', 'price': '89.000đ', 'icon': Icons.fastfood},
    {'name': 'Gà sốt cay', 'sold': '150+', 'price': '55.000đ', 'icon': Icons.local_fire_department},
  ];

  Widget _buildLoadingScaffold(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMainScaffold(BuildContext context, BranchDetailModel? detail) {
    final categories = _currentCategories;
    final menuItems = _currentMenuItems;

    // Check key initialization
    if (_sectionKeys.length != categories.length) {
      _sectionKeys.clear();
      _sectionKeys.addAll(List.generate(categories.length, (_) => GlobalKey()));
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ─── App Bar with image ─────────────────────────────
            _buildSliverAppBar(context, detail),

            // ─── Store Info ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildStoreInfo(detail)),

            // ─── Delivery Info ──────────────────────────────────
            SliverToBoxAdapter(child: _buildDeliveryInfo(detail)),

            // ─── Promos ─────────────────────────────────────────
            SliverToBoxAdapter(child: _buildPromos(detail)),

            // ─── Popular Items ──────────────────────────────────
            SliverToBoxAdapter(child: _buildPopularItems(detail)),

            // Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ─── Category Tabs ──────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryTabsDelegate(
                categories: categories,
                selectedIndexNotifier: _selectedCategoryNotifier,
                onSelected: _scrollToSection,
              ),
            ),

            // ─── All Menu Items grouped by category ──────────
            ..._buildAllMenuSections(categories, menuItems),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        // ─── Floating Cart Bar ─────────────────────────────────
        bottomNavigationBar: _cartItemCount > 0 ? _buildCartBar() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branchId != null && widget.branchId!.isNotEmpty) {
      final detailAsync = ref.watch(branchDetailFutureProvider(widget.branchId!));
      return detailAsync.when(
        data: (detail) {
          if (_lastResolvedDetail != detail) {
            _lastResolvedDetail = detail;
            _invalidateMenuCache();
          }
          return _buildMainScaffold(context, detail);
        },
        loading: () => _buildLoadingScaffold(context),
        error: (err, stack) {
          print('[StoreDetailPage] Error loading branch: $err');
          return _buildMainScaffold(context, null);
        },
      );
    }
    return _buildMainScaffold(context, null);
  }

  // ─── Cart Bar ──────────────────────────────────────────────────────────
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
      _priceRegExp,
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
  List<Widget> _buildAllMenuSections(List<String> categories, List<dynamic> menuSections) {
    final List<Widget> slivers = [];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final items = menuSections[i] as List<dynamic>;

      // Category title
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            key: _sectionKeys[i],
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Text(
              '$category (${items.length})',
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
            (context, index) => RepaintBoundary(
              child: _buildMenuItem(items[index]),
            ),
            childCount: items.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false, // We add RepaintBoundary manually above
          ),
        ),
      );
    }

    return slivers;
  }

  // ─── Sliver App Bar ──────────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context, BranchDetailModel? detail) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      // ── Title: only rebuilds when _isCollapsedNotifier changes ──
      title: ValueListenableBuilder<bool>(
        valueListenable: _isCollapsedNotifier,
        builder: (context, isCollapsed, _) {
          if (!(isCollapsed || _isSearchActive)) return const SizedBox.shrink();
          return Container(
            height: 36,
            decoration: BoxDecoration(
              color: isCollapsed
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isCollapsed
                  ? null
                  : const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search,
                  size: 18,
                  color: isCollapsed ? Colors.white70 : AppColors.textSecondary,
                ),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: isCollapsed ? Colors.white : AppColors.textPrimary,
                    ),
                    cursorColor: isCollapsed ? Colors.white : AppColors.primary,
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      hintText: 'Tìm món trong quán',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isCollapsed ? Colors.white70 : AppColors.textTertiary,
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
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isCollapsed ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        // ── Search icon: only rebuilds when _isCollapsedNotifier changes ──
        ValueListenableBuilder<bool>(
          valueListenable: _isCollapsedNotifier,
          builder: (context, isCollapsed, _) {
            if (!isCollapsed && !_isSearchActive) {
              return IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearchActive = true;
                  });
                },
              );
            }
            return const SizedBox.shrink();
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
          child: (detail != null && detail.imageUrl.isNotEmpty)
              ? (detail.imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: detail.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Icon(widget.icon, size: 80, color: AppColors.textTertiary),
                    )
                  : Image.asset(
                      detail.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(widget.icon, size: 80, color: AppColors.textTertiary),
                    ))
              : Icon(widget.icon, size: 80, color: AppColors.textTertiary),
        ),
      ),
    );
  }


  // ─── Store Info Section ──────────────────────────────────────────────────
  Widget _buildStoreInfo(BranchDetailModel? detail) {
    final name = detail?.name ?? widget.storeName;
    final rating = detail?.rating ?? widget.rating;
    final reviews = detail?.reviewsCount ?? widget.reviews;
    final deliveryTime = (detail?.deliveryTime != null && detail!.deliveryTime.isNotEmpty) ? detail.deliveryTime : widget.deliveryTime;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
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
                  name,
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
              // Interactive Rating + reviews
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreReviewsPage(
                        storeName: name,
                        category: widget.category,
                        rating: rating,
                        reviewsCount: reviews,
                        deliveryTime: deliveryTime,
                        distance: widget.distance,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stars (compact)
                    ...List.generate(5, (i) {
                      if (i < rating.floor()) {
                        return const Icon(Icons.star, size: 14, color: AppColors.star);
                      } else if (i < rating) {
                        return const Icon(Icons.star_half, size: 14, color: AppColors.star);
                      }
                      return const Icon(Icons.star_border, size: 14, color: AppColors.star);
                    }),
                    const SizedBox(width: 4),
                    // Rating + reviews text
                    Text(
                      '$rating ($reviews+ Bình luận) >',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
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
                deliveryTime,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              // Favorite
              Consumer(
                builder: (context, ref, child) {
                  final isFav = ref.watch(favoriteShopsProvider).contains(name);
                  return GestureDetector(
                    onTap: () {
                      ref.read(favoriteShopsProvider.notifier).toggleFavorite(name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav
                                ? 'Đã xóa "$name" khỏi yêu thích'
                                : 'Đã thêm "$name" vào yêu thích',
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
  Widget _buildDeliveryInfo(BranchDetailModel? detail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
          // Address row
          if (detail != null && detail.address != null && detail.address!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail.address!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
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
        ],
      ),
    );
  }

  Widget _buildPromos(BranchDetailModel? detail) {
    final promos = detail != null ? (detail.promos ?? []) : const <String>[];
    if (promos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: promos.length,
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
                    promos[index],
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
  Widget _buildPopularItems(BranchDetailModel? detail) {
    const popularItemsList = _popularItems;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: popularItemsList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final item = popularItemsList[index];
                return _buildPopularItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItemCard(dynamic item) {
    final String name = item is MenuItemModel ? item.name : (item['name'] as String);
    final String priceStr = item is MenuItemModel ? item.price : (item['price'] as String);
    final String price = _formatPriceString(priceStr);
    final String sold = item is MenuItemModel ? '${item.soldCount ?? 0}+' : (item['sold'] as String);
    final String? imageUrl = item is MenuItemModel ? item.imageUrl : null;
    final IconData icon = item is MenuItemModel ? Icons.restaurant : (item['icon'] as IconData);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoodDetailPage(
            name: name,
            price: price,
            sold: sold,
            likes: 0,
            icon: icon,
            imageUrl: imageUrl,
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
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? (imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Icon(icon, size: 32, color: AppColors.textTertiary),
                                errorWidget: (_, __, ___) => Icon(icon, size: 32, color: AppColors.textTertiary),
                              )
                            : Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, size: 32, color: AppColors.textTertiary)))
                        : Icon(icon, size: 32, color: AppColors.textTertiary),
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
                        '$sold đã bán',
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
                      name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
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
  String _formatPriceString(String priceStr) {
    if (priceStr.isEmpty) return '0đ';
    final parsedDouble = double.tryParse(priceStr);
    if (parsedDouble != null) {
      final intPrice = parsedDouble.toInt();
      return '${_formatCartPrice(intPrice)}đ';
    }
    return priceStr;
  }

  Widget _buildMenuItem(dynamic item) {
    final String name = item is MenuItemModel ? item.name : (item['name'] as String);
    final String priceStr = item is MenuItemModel ? item.price : (item['price'] as String);
    final String price = _formatPriceString(priceStr);
    final String sold = item is MenuItemModel ? '${item.soldCount ?? 0}+' : (item['sold'] as String);
    final int likes = item is MenuItemModel ? (item.likesCount ?? 0) : (item['likes'] as int? ?? 0);
    final String? imageUrl = item is MenuItemModel ? item.imageUrl : null;
    final IconData icon = item is MenuItemModel ? Icons.restaurant : (item['icon'] as IconData);

    final isHighlighted = _firstMatchingFoodName != null &&
        name.toLowerCase() == _firstMatchingFoodName!.toLowerCase();

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoodDetailPage(
            name: name,
            price: price,
            sold: sold,
            likes: likes,
            icon: icon,
            imageUrl: imageUrl,
          ),
        ));
        _handleCartResult(result);
      },
      child: Container(
        key: isHighlighted ? _highlightedItemKey : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? (imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(icon, size: 28, color: AppColors.textTertiary),
                            errorWidget: (_, __, ___) => Icon(icon, size: 28, color: AppColors.textTertiary),
                          )
                        : Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, size: 28, color: AppColors.textTertiary)))
                    : Icon(icon, size: 28, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                        '$sold đã bán',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$likes lượt thích',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
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
// Uses ValueNotifier + ValueListenableBuilder so tab highlight changes
// NEVER trigger a parent setState / full page rebuild.
class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final ValueNotifier<int> selectedIndexNotifier;
  final ValueChanged<int> onSelected;

  _CategoryTabsDelegate({
    required this.categories,
    required this.selectedIndexNotifier,
    required this.onSelected,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedIndexNotifier,
      builder: (context, selectedIndex, _) {
        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
      },
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabsDelegate oldDelegate) {
    // Only rebuild when categories list changes — NOT for index changes
    // (index changes are handled internally by ValueListenableBuilder)
    return oldDelegate.categories != categories;
  }
}

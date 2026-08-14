import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/menu_item_model.dart';
import 'dart:io';

/// A pixel-perfect, high-fidelity customer storefront preview simulator.
/// Replicates [StoreDetailPage] exactly without any custom additions.
class MockStoreDetailPage extends ConsumerStatefulWidget {
  final String? branchId;
  final String storeName;
  final String logoUrl;
  final String coverUrl;
  final String category;
  final String hotline;
  final String storeStatus;
  final String openingTime;
  final String closingTime;

  const MockStoreDetailPage({
    super.key,
    this.branchId,
    required this.storeName,
    required this.logoUrl,
    required this.coverUrl,
    required this.category,
    required this.hotline,
    required this.storeStatus,
    required this.openingTime,
    required this.closingTime,
  });

  @override
  ConsumerState<MockStoreDetailPage> createState() => _MockStoreDetailPageState();
}

class _MockStoreDetailPageState extends ConsumerState<MockStoreDetailPage> {
  final ValueNotifier<int> _selectedCategoryNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isCollapsedNotifier = ValueNotifier<bool>(false);
  bool _isTabTapping = false;
  late ScrollController _scrollController;
  late List<GlobalKey> _sectionKeys;

  // Search Mock state
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool _isSearchActive = false;
  bool _isFav = false;

  List<dynamic>? _cachedMenuItems;
  List<String>? _cachedCategories;
  List<dynamic>? _cachedPopularItems;
  BranchDetailModel? _lastResolvedDetail;

  List<dynamic> get _currentMenuItems {
    if (_cachedMenuItems != null) return _cachedMenuItems!;
    final detailVal = _lastResolvedDetail;
    if (detailVal != null) {
      final menu = detailVal.menu;
      if (menu != null && menu.isNotEmpty) {
        final dynamicSections = menu.map((e) => e.items).toList();
        _cachedMenuItems = dynamicSections;
        return _cachedMenuItems!;
      }
    }
    return [];
  }

  List<String> get _currentCategories {
    if (_cachedCategories != null) return _cachedCategories!;
    final detailVal = _lastResolvedDetail;
    if (detailVal != null) {
      final menu = detailVal.menu;
      if (menu != null && menu.isNotEmpty) {
        final dynamicCats = menu.map((e) => e.name).toList();
        _cachedCategories = dynamicCats;
        return _cachedCategories!;
      }
    }
    return [];
  }

  List<dynamic> get _currentPopularItems {
    if (_cachedPopularItems != null) return _cachedPopularItems!;
    final detailVal = _lastResolvedDetail;
    if (detailVal != null) {
      final List<MenuItemModel> allItems = [];
      if (detailVal.menu != null) {
        for (final section in detailVal.menu!) {
          allItems.addAll(section.items);
        }
      }
      if (allItems.isNotEmpty) {
        allItems.sort((a, b) => (b.soldCount ?? 0).compareTo(a.soldCount ?? 0));
        _cachedPopularItems = allItems.take(6).toList();
        return _cachedPopularItems!;
      }
    }
    return [];
  }

  void _invalidateMenuCache() {
    _cachedMenuItems = null;
    _cachedCategories = null;
    _cachedPopularItems = null;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController = TextEditingController();

    _sectionKeys = [];
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
    if (newIndex != _selectedCategoryNotifier.value) {
      _selectedCategoryNotifier.value = newIndex;
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
    ).then((_) {
      _isTabTapping = false;
    });
  }

  void _showSimulationNotice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Chế độ Mô phỏng', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Đây là bản mô phỏng giao diện hiển thị phía khách hàng. '
          'Các tính năng tương tác như đặt hàng, thêm giỏ hàng, tìm kiếm sẽ khả dụng đầy đủ '
          'khi khách hàng thực tế truy cập vào trang chi nhánh của bạn.',
          style: TextStyle(height: 1.4, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScaffold(BuildContext context, BranchDetailModel? detail) {
    final categories = _currentCategories;

    // Check key initialization
    if (_sectionKeys.length != categories.length) {
      _sectionKeys.clear();
      _sectionKeys.addAll(List.generate(categories.length, (_) => GlobalKey()));
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ─── Sliver App Bar with cover image ───
            _buildSliverAppBar(context, detail),

            // Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ─── Delivery Info Section (Pixel Perfect match to customer detail page) ───
            SliverToBoxAdapter(
              child: _buildDeliverySection(),
            ),

            // ─── Promos Section (Pixel Perfect match to customer detail page) ───
            SliverToBoxAdapter(
              child: _buildPromosSection(),
            ),

            // ─── Popular Items Section (Pixel Perfect match to customer detail page) ───
            SliverToBoxAdapter(
              child: _buildPopularSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ─── Category Tabs Persistent Header ───
            SliverPersistentHeader(
              pinned: true,
              delegate: _MockCategoryTabsDelegate(
                categories: categories,
                selectedIndexNotifier: _selectedCategoryNotifier,
                onSelected: _scrollToSection,
              ),
            ),

            // ─── Menu lists grouped by category ───
            ..._buildAllMenuSections(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
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
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, stack) {
          print('[MockStoreDetailPage] Error loading branch: $err');
          return _buildMainScaffold(context, null);
        },
      );
    }
    return _buildMainScaffold(context, null);
  }

  // ─── App Bar (100% exact copy of customer-facing page) ───
  Widget _buildSliverAppBar(BuildContext context, BranchDetailModel? detail) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: ValueListenableBuilder<bool>(
        valueListenable: _isCollapsedNotifier,
        builder: (context, isCollapsed, _) {
          if (!isCollapsed && !_isSearchActive) return const SizedBox.shrink();
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
                        _searchQuery = value;
                        _isSearchActive = value.isNotEmpty;
                      });
                    },
                    style: TextStyle(
                      fontSize: 13,
                      color: isCollapsed ? Colors.white : AppColors.textPrimary,
                    ),
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
        IconButton(
          icon: Icon(
            _isFav ? Icons.favorite : Icons.favorite_border,
            color: _isFav ? const Color(0xFFFF2A55) : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isFav = !_isFav;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isFav
                      ? 'Đã thêm "${widget.storeName}" vào cửa hàng yêu thích'
                      : 'Đã xóa "${widget.storeName}" khỏi cửa hàng yêu thích',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: _showSimulationNotice,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  final cover = _getCoverImageUrl(detail);
                  if (cover.startsWith('http')) {
                    return CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainer),
                    );
                  } else if (cover.isNotEmpty) {
                    return Image.file(
                      File(cover),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceContainer),
                    );
                  } else {
                    return Container(color: AppColors.surfaceContainer);
                  }
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Floating Status Badge (positioned lower to avoid toolbar overlap)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.storeStatus == 'busy'
                      ? const Color(0xFFFFF7EC)
                      : widget.storeStatus == 'closed'
                          ? AppColors.errorContainer
                          : AppColors.successContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (widget.storeStatus == 'busy'
                        ? AppColors.accent
                        : widget.storeStatus == 'closed'
                            ? AppColors.error
                            : AppColors.success).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.storeStatus == 'busy'
                      ? 'Quán đang bận'
                      : widget.storeStatus == 'closed'
                          ? 'Tạm đóng cửa'
                          : 'Đang hoạt động',
                  style: TextStyle(
                    color: widget.storeStatus == 'busy'
                        ? AppColors.accent
                        : widget.storeStatus == 'closed'
                            ? AppColors.error
                            : AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Floating Rating Badge (positioned lower to avoid toolbar overlap)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '4.8 (250+)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content overlay at the bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo/Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.logoUrl.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: widget.logoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, error, stackTrace) => Container(color: AppColors.primaryContainer),
                            )
                          : Image.file(
                              File(widget.logoUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.primaryContainer),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shop details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.storeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Category Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.openingTime} - ${widget.closingTime}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.phone_rounded, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              widget.hotline,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delivery Info Section (100% exact copy of customer-facing page) ───
  Widget _buildDeliverySection() {
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
                onTap: _showSimulationNotice,
                child: const Text(
                  'Thay đổi >',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                onTap: _showSimulationNotice,
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

  // ─── Promos Section (100% exact copy of customer-facing page) ───
  Widget _buildPromosSection() {
    final promos = [
      'Giảm 50% · Đơn từ 55k',
      'Giảm 50% · Đơn từ 55k',
      'Giảm 50% · Đơn từ 99k',
      'Freeship · Đơn từ 30k',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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

  String _getCoverImageUrl(BranchDetailModel? detail) {
    if (widget.coverUrl.isNotEmpty) {
      return widget.coverUrl;
    }
    if (detail?.coverImageUrl != null && detail!.coverImageUrl!.isNotEmpty) {
      return detail.coverImageUrl!;
    }
    // Fallback based on category
    final category = (detail?.category ?? widget.category).toLowerCase();
    if (category.contains('phở') || category.contains('bún')) {
      return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80';
    } else if (category.contains('cơm')) {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80';
    } else if (category.contains('uống') || category.contains('cà phê') || category.contains('nước')) {
      return 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80';
    } else if (category.contains('vặt') || category.contains('fast')) {
      return 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800&q=80';
    }
    // Default cozy cover
    return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80';
  }

  String _getName(dynamic item) => item is MenuItemModel ? item.name : (item['name'] as String);
  String _getPrice(dynamic item) => item is MenuItemModel ? item.price : (item['price'] as String);
  String _getSold(dynamic item) => item is MenuItemModel ? '${item.soldCount ?? 0}+' : (item['sold'] as String);
  int _getLikes(dynamic item) => item is MenuItemModel ? (item.likesCount ?? 0) : (item['likes'] as int? ?? 0);
  String? _getImageUrl(dynamic item) => item is MenuItemModel ? item.imageUrl : null;
  IconData _getIcon(dynamic item) => item is MenuItemModel ? Icons.restaurant : (item['icon'] as IconData);

  // ─── Popular Items Section (100% exact copy of customer-facing page) ───
  Widget _buildPopularSection() {
    final popular = _currentPopularItems;
    if (popular.isEmpty) return const SizedBox.shrink();

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
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final item = popular[index];
                final name = _getName(item);
                final price = _getPrice(item);
                final sold = _getSold(item);
                final imageUrl = _getImageUrl(item);
                final icon = _getIcon(item);

                return GestureDetector(
                  onTap: _showSimulationNotice,
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
                                        : Image.file(
                                            File(imageUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(icon, size: 32, color: AppColors.textTertiary),
                                          ))
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
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build grouped list of menu items (100% exact copy of customer-facing page) ───
  List<Widget> _buildAllMenuSections() {
    final List<Widget> slivers = [];
    final categories = _currentCategories;
    final menuItems = _currentMenuItems;

    if (categories.isEmpty || menuItems.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: 16),
                Text(
                  'Cửa hàng chưa có thực đơn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Vui lòng thêm danh mục và món ăn trong mục "Thiết lập Thực đơn" để xem trước giao diện cửa hàng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final items = menuItems[i];

      final filteredItems = _searchQuery.isEmpty
          ? items
          : items
              .where((item) => _getName(item).toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

      if (filteredItems.isEmpty && _searchQuery.isNotEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            key: _sectionKeys[i],
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '$category (${filteredItems.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = filteredItems[index];
              return _buildMenuItemCard(item);
            },
            childCount: filteredItems.length,
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildMenuItemCard(dynamic item) {
    final name = _getName(item);
    final price = _getPrice(item);
    final sold = _getSold(item);
    final likes = _getLikes(item);
    final imageUrl = _getImageUrl(item);
    final icon = _getIcon(item);

    return GestureDetector(
      onTap: _showSimulationNotice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        : Image.file(
                            File(imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(icon, size: 28, color: AppColors.textTertiary),
                          ))
                    : Icon(icon, size: 28, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 12),
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

// ─── Categories Tab Persistent Header Delegate (100% exact copy of customer-facing page) ───
class _MockCategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final ValueNotifier<int> selectedIndexNotifier;
  final ValueChanged<int> onSelected;

  _MockCategoryTabsDelegate({
    required this.categories,
    required this.selectedIndexNotifier,
    required this.onSelected,
  });

  @override
  double get minExtent => categories.isEmpty ? 0 : 48;

  @override
  double get maxExtent => categories.isEmpty ? 0 : 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if (categories.isEmpty) return const SizedBox.shrink();
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
      },
    );
  }

  @override
  bool shouldRebuild(covariant _MockCategoryTabsDelegate oldDelegate) {
    return oldDelegate.categories != categories;
  }
}

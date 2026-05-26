import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../providers/branches/branch_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/branches/detail/branch_cart_bar.dart';
import '../../widgets/branches/detail/branch_category_tabs.dart';
import '../../widgets/branches/detail/branch_delivery_info.dart';
import '../../widgets/branches/detail/branch_detail_app_bar.dart';
import '../../widgets/branches/detail/branch_menu_widgets.dart';
import '../../widgets/branches/detail/branch_promos_list.dart';
import '../../widgets/branches/detail/branch_store_info.dart';
import 'branch_detail_view_data.dart';
import 'checkout_page.dart';
import 'food_detail_page.dart';

class StoreDetailPage extends ConsumerStatefulWidget {
  final String storeId;
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
    required this.storeId,
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
  final GlobalKey _highlightedItemKey = GlobalKey();

  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  List<GlobalKey> _sectionKeys = const [];
  BranchDetailViewData _viewData = const BranchDetailViewData(
    menuSections: [],
    promos: [],
    popularItems: [],
  );

  int _selectedCategoryIndex = 0;
  bool _isCollapsed = false;
  bool _isTabTapping = false;
  bool _isSearchActive = false;
  bool _didAutoScrollToHighlight = false;
  String _searchQuery = '';
  String? _firstMatchingFoodName;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController(
      text: widget.highlightFoodName ?? '',
    );
    _searchQuery = widget.highlightFoodName ?? '';
    _isSearchActive = _searchQuery.isNotEmpty;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBranch = ref.watch(branchDetailProvider(widget.storeId));
    final cartItemCount = ref.watch(cartProvider).totalItems;

    return asyncBranch.when(
      data: (branchDetail) {
        _syncViewData(branchDetail);
        _syncHighlightAfterDataLoad();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              BranchDetailAppBar(
                branch: branchDetail,
                storeName: widget.storeName,
                fallbackIcon: widget.icon,
                showSearch: _isCollapsed || _isSearchActive,
                searchController: _searchController,
                onSearchChanged: _handleSearchChanged,
                onSearchSubmitted: (_) => _scrollToHighlightedItem(),
                onSearchTap: () => setState(() => _isSearchActive = true),
                onClearSearch: _clearSearch,
              ),
              SliverToBoxAdapter(
                child: BranchStoreInfo(
                  branch: branchDetail,
                  storeName: widget.storeName,
                  rating: widget.rating,
                  reviews: widget.reviews,
                ),
              ),
              const SliverToBoxAdapter(child: BranchDeliveryInfo()),
              if (_viewData.promos.isNotEmpty)
                SliverToBoxAdapter(
                  child: BranchPromosList(promos: _viewData.promos),
                ),
              if (_viewData.popularItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: BranchPopularItems(
                    items: _viewData.popularItems,
                    onItemTap: _openFoodDetail,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_viewData.menuSections.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: BranchCategoryTabsDelegate(
                    categories:
                        _viewData.menuSections.map((section) => section.name).toList(),
                    selectedIndex: _selectedCategoryIndex,
                    onSelected: _scrollToSection,
                  ),
                ),
              if (_viewData.menuSections.isNotEmpty)
                BranchMenuSectionSlivers(
                  sections: _viewData.menuSections,
                  sectionKeys: _sectionKeys,
                  highlightedItemName: _firstMatchingFoodName,
                  highlightedItemKey: _highlightedItemKey,
                  onItemTap: _openFoodDetail,
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          bottomNavigationBar: cartItemCount > 0
              ? BranchCartBar(
                  onTap: () => _openCheckout(branchDetail),
                )
              : null,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  void _syncViewData(BranchDetailModel branchDetail) {
    _viewData = BranchDetailViewData.fromBranch(branchDetail);
    if (_sectionKeys.length != _viewData.menuSections.length) {
      _sectionKeys = List.generate(
        _viewData.menuSections.length,
        (_) => GlobalKey(),
      );
      if (_selectedCategoryIndex >= _viewData.menuSections.length) {
        _selectedCategoryIndex = 0;
      }
    }
  }

  void _syncHighlightAfterDataLoad() {
    _findFirstMatchingFood();
    if (_didAutoScrollToHighlight || _firstMatchingFoodName == null) return;
    _didAutoScrollToHighlight = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _scrollToHighlightedItem();
      });
    });
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _isSearchActive = _searchQuery.isNotEmpty;
      _findFirstMatchingFood();
      _activateTabForHighlightedItem();
    });
    if (_isSearchActive) {
      _scrollToHighlightedItem();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearchActive = false;
      _firstMatchingFoodName = null;
    });
  }

  void _findFirstMatchingFood() {
    if (_searchQuery.isEmpty) {
      _firstMatchingFoodName = null;
      return;
    }

    final query = _searchQuery.toLowerCase();
    for (final section in _viewData.menuSections) {
      for (final item in section.items) {
        if (item.name.toLowerCase().contains(query)) {
          _firstMatchingFoodName = item.name;
          return;
        }
      }
    }
    _firstMatchingFoodName = null;
  }

  void _activateTabForHighlightedItem() {
    if (_firstMatchingFoodName == null) return;

    final targetIndex = _categoryIndexForItem(_firstMatchingFoodName!);
    if (targetIndex == -1 || targetIndex == _selectedCategoryIndex) return;
    _selectedCategoryIndex = targetIndex;
  }

  void _scrollToHighlightedItem() {
    if (_searchQuery.isEmpty || _firstMatchingFoodName == null) return;

    final targetCategoryIndex = _categoryIndexForItem(_firstMatchingFoodName!);
    if (targetCategoryIndex == -1) return;

    setState(() => _selectedCategoryIndex = targetCategoryIndex);
    final categoryKey = _sectionKeys[targetCategoryIndex];

    if (categoryKey.currentContext == null) {
      _scrollItemIntoView();
      return;
    }

    _isTabTapping = true;
    Scrollable.ensureVisible(
      categoryKey.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ).then((_) {
      _isTabTapping = false;
      _scrollItemIntoView();
    });
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

  int _categoryIndexForItem(String itemName) {
    for (var i = 0; i < _viewData.menuSections.length; i++) {
      final section = _viewData.menuSections[i];
      final containsItem = section.items.any(
        (item) => item.name.toLowerCase() == itemName.toLowerCase(),
      );
      if (containsItem) return i;
    }
    return -1;
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > 140;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
    if (!_isTabTapping) _updateActiveTab();
  }

  void _updateActiveTab() {
    for (var i = _sectionKeys.length - 1; i >= 0; i--) {
      final context = _sectionKeys[i].currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final position = box.localToGlobal(Offset.zero);
      if (position.dy <= kToolbarHeight + 100) {
        if (_selectedCategoryIndex != i) {
          setState(() => _selectedCategoryIndex = i);
        }
        return;
      }
    }
  }

  void _scrollToSection(int index) {
    if (index < 0 || index >= _sectionKeys.length) return;
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

  Future<void> _openFoodDetail(BranchMenuItemViewData item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailPage(
          id: item.id,
          name: item.name,
          price: item.price,
          sold: item.sold,
          likes: item.likes,
          icon: item.icon,
          imageUrl: item.imageUrl,
        ),
      ),
    );

    _handleCartResult(result, item);
  }

  void _handleCartResult(dynamic result, BranchMenuItemViewData item) {
    if (result is! Map<String, dynamic>) return;

    final quantity = result['quantity'] as int? ?? 0;
    if (quantity <= 0) return;

    final priceAmount =
        int.tryParse(item.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    ref.read(cartProvider.notifier).addItem(
          CartItemModel(
            id: item.id,
            imageUrl: item.imageUrl,
            name: item.name,
            priceAmount: priceAmount,
            priceDisplay: item.price,
            quantity: quantity,
          ),
        );
  }

  void _openCheckout(BranchDetailModel branchDetail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          storeId: branchDetail.id,
          storeName: branchDetail.name,
          itemCount: ref.read(cartProvider).totalItems,
          distance: branchDetail.distance,
          icon: widget.icon,
        ),
      ),
    );
  }
}

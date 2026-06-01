import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:io';

/// A pixel-perfect, high-fidelity customer storefront preview simulator.
/// Replicates [StoreDetailPage] exactly without any custom additions.
class MockStoreDetailPage extends StatefulWidget {
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
  State<MockStoreDetailPage> createState() => _MockStoreDetailPageState();
}

class _MockStoreDetailPageState extends State<MockStoreDetailPage> {
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

  late List<String> _categories;
  late List<List<Map<String, dynamic>>> _menuItems;
  late List<Map<String, dynamic>> _popularItems;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController = TextEditingController();

    _setupMockData();
    _sectionKeys = List.generate(_categories.length, (_) => GlobalKey());
  }

  void _setupMockData() {
    final cat = widget.category.trim();

    if (cat.contains('Phở') || cat.contains('Bún')) {
      _categories = ['Món phổ biến', 'Phở bò', 'Phở gà & Bún', 'Đồ uống'];
      _popularItems = [
        {'name': 'Combo phở bò chín + quẩy + nước', 'price': '65.000đ', 'sold': '120+', 'icon': Icons.ramen_dining},
        {'name': 'Phở bò tái nạm đặc biệt', 'price': '55.000đ', 'sold': '350+', 'icon': Icons.ramen_dining},
      ];
      _menuItems = [
        // Món phổ biến
        [
          {'name': 'Combo phở bò chín + quẩy + nước', 'price': '65.000đ', 'sold': '120+', 'likes': 25, 'icon': Icons.ramen_dining},
          {'name': 'Phở bò tái nạm đặc biệt', 'price': '55.000đ', 'sold': '350+', 'likes': 98, 'icon': Icons.ramen_dining},
        ],
        // Phở bò
        [
          {'name': 'Phở bò chín', 'price': '45.000đ', 'sold': '500+', 'likes': 110, 'icon': Icons.ramen_dining},
          {'name': 'Phở bò tái gàu', 'price': '50.000đ', 'sold': '400+', 'likes': 80, 'icon': Icons.ramen_dining},
          {'name': 'Phở nạm gân bò', 'price': '52.000đ', 'sold': '210+', 'likes': 45, 'icon': Icons.ramen_dining},
        ],
        // Phở gà & Bún
        [
          {'name': 'Phở gà ta xé phay', 'price': '45.000đ', 'sold': '300+', 'likes': 65, 'icon': Icons.ramen_dining},
          {'name': 'Bún sườn mọc dọc mùng', 'price': '40.000đ', 'sold': '150+', 'likes': 30, 'icon': Icons.soup_kitchen},
        ],
        // Đồ uống
        [
          {'name': 'Trà đá Hà Nội', 'price': '5.000đ', 'sold': '999+', 'likes': 230, 'icon': Icons.local_drink},
          {'name': 'Nước cam tươi nguyên chất', 'price': '20.000đ', 'sold': '180+', 'likes': 40, 'icon': Icons.local_drink},
        ],
      ];
    } else if (cat.contains('Cơm')) {
      _categories = ['Món phổ biến', 'Cơm tấm', 'Cơm gà', 'Đồ ăn kèm'];
      _popularItems = [
        {'name': 'Cơm tấm sườn bì chả đặc biệt', 'price': '55.000đ', 'sold': '800+', 'icon': Icons.rice_bowl},
        {'name': 'Cơm đùi gà xối mỡ giòn rụm', 'price': '48.000đ', 'sold': '620+', 'icon': Icons.rice_bowl},
      ];
      _menuItems = [
        // Món phổ biến
        [
          {'name': 'Cơm tấm sườn bì chả đặc biệt', 'price': '55.000đ', 'sold': '800+', 'likes': 150, 'icon': Icons.rice_bowl},
          {'name': 'Cơm đùi gà xối mỡ giòn rụm', 'price': '48.000đ', 'sold': '620+', 'likes': 120, 'icon': Icons.rice_bowl},
        ],
        // Cơm tấm
        [
          {'name': 'Cơm sườn cốt lết truyền thống', 'price': '45.000đ', 'sold': '450+', 'likes': 68, 'icon': Icons.rice_bowl},
          {'name': 'Cơm tấm sườn ốp la', 'price': '48.000đ', 'sold': '300+', 'likes': 42, 'icon': Icons.rice_bowl},
        ],
        // Cơm gà
        [
          {'name': 'Cơm cánh gà chiên nước mắm', 'price': '48.000đ', 'sold': '250+', 'likes': 56, 'icon': Icons.rice_bowl},
          {'name': 'Cơm gà xé phay Hội An', 'price': '45.000đ', 'sold': '180+', 'likes': 38, 'icon': Icons.rice_bowl},
        ],
        // Đồ ăn kèm
        [
          {'name': 'Canh khổ qua dồn thịt', 'price': '15.000đ', 'sold': '220+', 'likes': 34, 'icon': Icons.soup_kitchen},
          {'name': 'Trứng ốp la lòng đào thêm', 'price': '6.000đ', 'sold': '700+', 'likes': 80, 'icon': Icons.egg},
        ],
      ];
    } else if (cat.contains('Vặt')) {
      _categories = ['Món phổ biến', 'Ăn vặt hot', 'Bánh tráng', 'Trà sữa'];
      _popularItems = [
        {'name': 'Mẹt ăn vặt thập cẩm siêu to', 'price': '79.000đ', 'sold': '280+', 'icon': Icons.fastfood},
        {'name': 'Khoai tây chiên lắc phô mai', 'price': '35.000đ', 'sold': '420+', 'icon': Icons.fastfood},
      ];
      _menuItems = [
        // Món phổ biến
        [
          {'name': 'Mẹt ăn vặt thập cẩm siêu to', 'price': '79.000đ', 'sold': '280+', 'likes': 85, 'icon': Icons.fastfood},
          {'name': 'Khoai tây chiên lắc phô mai', 'price': '35.000đ', 'sold': '420+', 'likes': 70, 'icon': Icons.fastfood},
        ],
        // Ăn vặt hot
        [
          {'name': 'Nem chua rán Hà Nội (10 chiếc)', 'price': '30.000đ', 'sold': '990+', 'likes': 195, 'icon': Icons.fastfood},
          {'name': 'Phô mai que kéo sợi (5 chiếc)', 'price': '35.000đ', 'sold': '600+', 'likes': 110, 'icon': Icons.fastfood},
        ],
        // Bánh tráng
        [
          {'name': 'Bánh tráng trộn khô bò Tây Ninh', 'price': '25.000đ', 'sold': '850+', 'likes': 130, 'icon': Icons.fastfood},
          {'name': 'Bánh tráng cuộn sốt bơ trứng cút', 'price': '25.000đ', 'sold': '400+', 'likes': 72, 'icon': Icons.fastfood},
        ],
        // Trà sữa
        [
          {'name': 'Trà sữa trân châu hoàng kim', 'price': '30.000đ', 'sold': '750+', 'likes': 160, 'icon': Icons.local_drink},
          {'name': 'Trà sữa Matcha đậu đỏ', 'price': '35.000đ', 'sold': '210+', 'likes': 45, 'icon': Icons.local_drink},
        ],
      ];
    } else if (cat.contains('Uống')) {
      _categories = ['Món phổ biến', 'Cà phê', 'Trà trái cây', 'Đá xay'];
      _popularItems = [
        {'name': 'Cà phê sữa đá Sài Gòn truyền thống', 'price': '25.000đ', 'sold': '999+', 'icon': Icons.coffee},
        {'name': 'Trà đào cam sả thanh lọc', 'price': '39.000đ', 'sold': '480+', 'icon': Icons.local_drink},
      ];
      _menuItems = [
        // Món phổ biến
        [
          {'name': 'Cà phê sữa đá Sài Gòn truyền thống', 'price': '25.000đ', 'sold': '999+', 'likes': 320, 'icon': Icons.coffee},
          {'name': 'Trà đào cam sả thanh lọc', 'price': '39.000đ', 'sold': '480+', 'likes': 120, 'icon': Icons.local_drink},
        ],
        // Cà phê
        [
          {'name': 'Cà phê đen đá đậm vị', 'price': '20.000đ', 'sold': '650+', 'likes': 95, 'icon': Icons.coffee},
          {'name': 'Bạc xỉu thơm ngậy cốt dừa', 'price': '30.000đ', 'sold': '500+', 'likes': 110, 'icon': Icons.coffee},
          {'name': 'Cà phê muối béo ngậy', 'price': '30.000đ', 'sold': '420+', 'likes': 89, 'icon': Icons.coffee},
        ],
        // Trà trái cây
        [
          {'name': 'Trà dâu tằm Đà Lạt ngọt mát', 'price': '35.000đ', 'sold': '300+', 'likes': 65, 'icon': Icons.local_drink},
          {'name': 'Trà vải lài hoa hồng', 'price': '39.000đ', 'sold': '220+', 'likes': 50, 'icon': Icons.local_drink},
        ],
        // Đá xay
        [
          {'name': 'Matcha đá xay kem mặn', 'price': '45.000đ', 'sold': '180+', 'likes': 42, 'icon': Icons.coffee},
          {'name': 'Sô-cô-la bánh quy đá xay', 'price': '45.000đ', 'sold': '210+', 'likes': 55, 'icon': Icons.coffee},
        ],
      ];
    } else {
      _categories = ['Món phổ biến', 'Bánh mì mặn', 'Bánh mì ngọt', 'Nước uống'];
      _popularItems = [
        {'name': 'Bánh mì đặc biệt đầy đủ topping', 'price': '30.000đ', 'sold': '750+', 'icon': Icons.breakfast_dining},
        {'name': 'Bánh mì heo quay giòn bì siêu ngon', 'price': '32.000đ', 'sold': '450+', 'icon': Icons.breakfast_dining},
      ];
      _menuItems = [
        // Món phổ biến
        [
          {'name': 'Bánh mì đặc biệt đầy đủ topping', 'price': '30.000đ', 'sold': '750+', 'likes': 180, 'icon': Icons.breakfast_dining},
          {'name': 'Bánh mì heo quay giòn bì siêu ngon', 'price': '32.000đ', 'sold': '450+', 'likes': 110, 'icon': Icons.breakfast_dining},
        ],
        // Bánh mì mặn
        [
          {'name': 'Bánh mì chả lụa pate bơ', 'price': '20.000đ', 'sold': '500+', 'likes': 45, 'icon': Icons.breakfast_dining},
          {'name': 'Bánh mì xíu mại trứng muối', 'price': '28.000đ', 'sold': '350+', 'likes': 62, 'icon': Icons.breakfast_dining},
          {'name': 'Bánh mì gà xé cay ngũ vị', 'price': '22.000đ', 'sold': '280+', 'likes': 38, 'icon': Icons.breakfast_dining},
        ],
        // Bánh mì ngọt
        [
          {'name': 'Bánh mì bơ tỏi phô mai Hàn Quốc', 'price': '25.000đ', 'sold': '200+', 'likes': 50, 'icon': Icons.breakfast_dining},
          {'name': 'Bánh mì mứt dâu tây', 'price': '15.000đ', 'sold': '120+', 'likes': 15, 'icon': Icons.breakfast_dining},
        ],
        // Nước uống
        [
          {'name': 'Sữa đậu nành nguyên chất thơm mát', 'price': '10.000đ', 'sold': '850+', 'likes': 120, 'icon': Icons.local_drink},
          {'name': 'Nước sâm bí đao lá dứa', 'price': '12.000đ', 'sold': '390+', 'likes': 64, 'icon': Icons.local_drink},
        ],
      ];
    }
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
        title: Row(
          children: const [
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ─── Sliver App Bar with cover image ───
            _buildSliverAppBar(context),

            // ─── Store Info Section (Pixel Perfect match to customer detail page) ───
            SliverToBoxAdapter(
              child: _buildStoreInfoSection(),
            ),

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
                categories: _categories,
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

  // ─── App Bar (100% exact copy of customer-facing page) ───
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
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
              child: widget.coverUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: widget.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surfaceContainer),
                    )
                  : Image.file(
                      File(widget.coverUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceContainer),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Store Info Section (100% exact copy of customer-facing page) ───
  Widget _buildStoreInfoSection() {
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
              ...List.generate(5, (i) => const Icon(Icons.star, size: 14, color: AppColors.star)),
              const SizedBox(width: 4),
              // Rating + reviews (flexible to prevent overflow)
              Flexible(
                child: Text(
                  '4.8 (250+ Bình luận) >',
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
              const Text(
                '30 phút',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              // Favorite
              GestureDetector(
                onTap: () {
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
                child: Icon(
                  _isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _isFav ? const Color(0xFFFF2A55) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
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

  // ─── Popular Items Section (100% exact copy of customer-facing page) ───
  Widget _buildPopularSection() {
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
              itemCount: _popularItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final item = _popularItems[index];
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
                                child: Icon(item['icon'] as IconData, size: 32, color: AppColors.textTertiary),
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
                                    '${item['sold']} đã bán',
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
                                  item['name'] as String,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['price'] as String,
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

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];
      final items = _menuItems[i];

      final filteredItems = _searchQuery.isEmpty
          ? items
          : items
              .where((item) => (item['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
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

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
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
                child: Icon(item['icon'] as IconData, size: 28, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
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
                        '${item['sold']} đã bán',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item['likes']} lượt thích',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['price'] as String,
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

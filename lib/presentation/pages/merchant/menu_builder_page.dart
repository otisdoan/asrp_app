import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/branch_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/merchant_menu_provider.dart';
import '../../../core/utils/top_notification.dart';
import '../../../data/repositories/merchant_repository.dart';

class MenuBuilderPage extends ConsumerStatefulWidget {
  const MenuBuilderPage({super.key});

  @override
  ConsumerState<MenuBuilderPage> createState() => _MenuBuilderPageState();
}

class _MenuBuilderPageState extends ConsumerState<MenuBuilderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen to tab changes to rebuild FloatingActionButton
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(merchantMenuProvider.notifier).initializeMenu();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(merchantMenuProvider);
    final selectedCategoryId = menuState.selectedCategoryId;
    final categories = menuState.categories;
    final categoryDishes = menuState.categoryDishes;

    MerchantCategory? activeCategory;
    if (selectedCategoryId != null) {
      final index = categories.indexWhere((c) => c.id == selectedCategoryId);
      if (index >= 0) {
        activeCategory = categories[index];
      } else if (categories.isNotEmpty) {
        activeCategory = categories.first;
      }
    } else if (categories.isNotEmpty) {
      activeCategory = categories.first;
    }

    final currentCategory = activeCategory;

    final dishes = currentCategory != null
        ? (categoryDishes[currentCategory.id] ?? [])
        : <MerchantDish>[];

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Quản lý thực đơn & Topping',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant_menu_rounded, size: 20),
              text: 'Món ăn & Topping',
            ),
            Tab(
              icon: Icon(Icons.folder_open_rounded, size: 20),
              text: 'Quản lý danh mục',
            ),
          ],
        ),
      ),
      body: menuState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải thực đơn...',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : (menuState.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          menuState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(merchantMenuProvider.notifier)
                              .initializeMenu(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildBranchSelector(menuState),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // TAB 1: Món ăn & Topping
                          categories.isEmpty
                              ? _buildEmptyState()
                              : _buildDishesTab(currentCategory, dishes, categories),

                          // TAB 2: Quản lý Danh mục
                          categories.isEmpty
                              ? _buildEmptyState()
                              : _buildCategoriesTab(categories),
                        ],
                      ),
                    ),
                  ],
                )),
      // Floating Action Button only shown on Tab 1
      floatingActionButton: _tabController.index == 0 && currentCategory != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showDishEditorSheet(context, currentCategory.id, null),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Thêm món mới',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ================= TAB 1: DISHES LIST VIEW =================
  Widget _buildDishesTab(MerchantCategory? activeCategory,
      List<MerchantDish> dishes, List<MerchantCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Scrollable Category Chips selector
        Container(
          height: 60,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat.id == activeCategory?.id;

              // Count number of dishes in this category
              final count = ref
                      .watch(merchantMenuProvider)
                      .categoryDishes[cat.id]
                      ?.length ??
                  0;

              return GestureDetector(
                onTap: () {
                  ref
                      .read(merchantMenuProvider.notifier)
                      .selectCategory(cat.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.outlineVariant,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
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

        // Active category description header
        if (activeCategory != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.bgWarm.withValues(alpha: 0.3),
            child: Text(
              'Danh mục: ${activeCategory.name} · ${dishes.length} món ăn',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

        // Scrollable list of full-width dishes cards
        Expanded(
          child: dishes.isEmpty
              ? _buildEmptyDishesState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      16, 12, 16, 80), // bottom padding for floating button
                  physics: const BouncingScrollPhysics(),
                  itemCount: dishes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    return _buildSpaciousDishCard(
                        context, activeCategory!.id, dish);
                  },
                ),
        ),
      ],
    );
  }

  // Spacious, full-screen-width beautiful dish card for mobile view
  Widget _buildSpaciousDishCard(
      BuildContext context, String catId, MerchantDish dish) {
    // Availability tags format
    String availabilityText = 'Còn món';
    Color availabilityColor = AppColors.success;
    Color availabilityBgColor = AppColors.successContainer;

    if (dish.availability == 'sold_out_today') {
      availabilityText = 'Hết hôm nay';
      availabilityColor = AppColors.accent;
      availabilityBgColor = const Color(0xFFFFF7EC);
    } else if (dish.availability == 'disabled') {
      availabilityText = 'Tạm dừng bán';
      availabilityColor = AppColors.textSecondary;
      availabilityBgColor = AppColors.surfaceContainerHigh;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => _showDishEditorSheet(context, catId, dish),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dish Image (rounded 12px, clean borders)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: dish.imageUrl.isNotEmpty
                            ? Image.network(
                                dish.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.restaurant_menu_rounded,
                                        color: AppColors.primary, size: 32),
                              )
                            : const Icon(Icons.restaurant_menu_rounded,
                                color: AppColors.primary, size: 32),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Dish Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dish.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (dish.description.isNotEmpty)
                            Text(
                              dish.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (dish.discountPrice != null) ...[
                                Text(
                                  '${dish.discountPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${dish.originalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ] else
                                Text(
                                  '${dish.originalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
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
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Bottom Actions: option group indicator + availability toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Option groups summary pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgWarm.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${dish.optionGroups.length} nhóm tùy chọn',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Rapid availability dropdown popup
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: availabilityBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: availabilityColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: availabilityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            availabilityText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: availabilityColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: availabilityColor, size: 14),
                        ],
                      ),
                    ),
                    onSelected: (String statusVal) async {
                      try {
                        await ref
                            .read(merchantMenuProvider.notifier)
                            .toggleDishAvailability(catId, dish.id, statusVal);
                        TopNotification.show(
                          context,
                          message: 'Đã cập nhật trạng thái hoạt động món ăn.',
                        );
                      } catch (e) {
                        TopNotification.show(
                          context,
                          message:
                              'Lỗi khi cập nhật trạng thái: ${e.toString().replaceAll('Exception: ', '')}',
                          isError: true,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'available',
                        child: Text('Còn món (Khả dụng)',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const PopupMenuItem(
                        value: 'sold_out_today',
                        child:
                            Text('Hết hôm nay', style: TextStyle(fontSize: 13)),
                      ),
                      const PopupMenuItem(
                        value: 'disabled',
                        child: Text('Tạm dừng bán',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: CATEGORY LIST REORDER VIEW =================
  Widget _buildCategoriesTab(List<MerchantCategory> categories) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.bgSoft,
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nhấn giữ nút kéo ở bên trái danh mục và di chuyển để thay đổi thứ tự hiển thị trên app.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Full width Categories drag list
        Expanded(
          child: ReorderableListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              ref
                  .read(merchantMenuProvider.notifier)
                  .reorderCategories(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                key: Key(cat.id),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border:
                      Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: const Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 20),
                        onPressed: () => _confirmDeleteCategory(context, cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Persistent full-screen button at bottom of Tab 2
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(context, null),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Thêm danh mục mới',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                size: 80, color: AppColors.primaryContainer),
            const SizedBox(height: 16),
            const Text(
              'Thực đơn chưa có danh mục',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng khởi tạo danh mục đầu tiên để quản lý thực đơn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(context, null),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Thêm danh mục'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDishesState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals_rounded, size: 50, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            'Chưa có món ăn trong danh mục này',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Bottom Sheet: Add / Edit Category
  void _showCategoryDialog(BuildContext context, MerchantCategory? category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _CategorySheetContent(
            category: category,
            onSave: (name) {
              if (category != null) {
                ref
                    .read(merchantMenuProvider.notifier)
                    .updateCategory(category.id, name);
              } else {
                ref.read(merchantMenuProvider.notifier).addCategory(name);
              }
              Navigator.pop(ctx);
            },
          ),
        );
      },
    );
  }

  // Dialog: Confirm Delete Category
  void _confirmDeleteCategory(BuildContext context, MerchantCategory category) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận xóa danh mục',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            'Hành động này sẽ xóa danh mục "${category.name}". Bạn chắc chắn muốn xóa?',
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                try {
                  await ref
                      .read(merchantMenuProvider.notifier)
                      .deleteCategory(category.id);
                  navigator.pop();
                  TopNotification.show(
                    context,
                    message: 'Đã xóa danh mục "${category.name}" thành công.',
                  );
                } catch (e) {
                  navigator.pop();
                  String errorMsg = e.toString().replaceAll('Exception: ', '');
                  if (errorMsg.contains('Category has menu items') ||
                      errorMsg.contains('400')) {
                    errorMsg =
                        'Không thể xóa danh mục vì vẫn còn món ăn bên trong. Vui lòng xóa hết món ăn trước.';
                  }
                  TopNotification.show(
                    context,
                    message: 'Không thể xóa: $errorMsg',
                    isError: true,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Xóa bỏ'),
            ),
          ],
        );
      },
    );
  }

  // Bottom Sheet: Add/Edit Dish (Using a self-contained stateful widget to prevent leaks)
  void _showDishEditorSheet(
      BuildContext context, String catId, MerchantDish? dish) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _DishEditorSheetContent(
            categoryId: catId,
            dish: dish,
            onSave: (updatedDish) async {
              final navigator = Navigator.of(ctx);
              try {
                if (dish == null) {
                  await ref
                      .read(merchantMenuProvider.notifier)
                      .addDish(catId, updatedDish);
                  TopNotification.show(
                    context,
                    message: 'Đã thêm món "${updatedDish.name}" thành công.',
                  );
                } else {
                  await ref
                      .read(merchantMenuProvider.notifier)
                      .updateDish(catId, updatedDish);
                  TopNotification.show(
                    context,
                    message:
                        'Đã cập nhật món "${updatedDish.name}" thành công.',
                  );
                }
                navigator.pop();
              } catch (e) {
                navigator.pop();
                TopNotification.show(
                  context,
                  message:
                      'Lỗi khi lưu món ăn: ${e.toString().replaceAll('Exception: ', '')}',
                  isError: true,
                );
              }
            },
            onDelete: dish != null
                ? () async {
                    final navigator = Navigator.of(ctx);
                    try {
                      await ref
                          .read(merchantMenuProvider.notifier)
                          .deleteDish(catId, dish.id);
                      navigator.pop();
                      TopNotification.show(
                        context,
                        message: 'Đã xóa món ăn thành công.',
                      );
                    } catch (e) {
                      navigator.pop();
                      TopNotification.show(
                        context,
                        message:
                            'Lỗi khi xóa món ăn: ${e.toString().replaceAll('Exception: ', '')}',
                        isError: true,
                      );
                    }
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBranchSelector(MerchantMenuState menuState) {
    if (menuState.branches.isEmpty) return const SizedBox.shrink();
    
    final currentBranch = menuState.branches.firstWhere(
      (b) => b.id == menuState.selectedBranchId,
      orElse: () => menuState.branches.first,
    );

    return InkWell(
      onTap: menuState.branches.length > 1
          ? () => _showBranchPicker(
                context,
                menuState.branches,
                menuState.selectedBranchId!,
                (newId) {
                  ref.read(merchantMenuProvider.notifier).switchBranch(newId);
                },
              )
          : null,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.store_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Chi nhánh: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                currentBranch.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (menuState.branches.length > 1) ...[
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${menuState.branches.length} chi nhánh',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBranchPicker(BuildContext context, List<BranchListItemModel> branches, String currentBranchId, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar indicator
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Chọn chi nhánh quản lý',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.outlineVariant),
              
              // Branches List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final isSelected = branch.id == currentBranchId;
                    
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(branch.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Branch Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.bgSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: branch.imageUrl.isNotEmpty
                                    ? Image.network(
                                        branch.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.store_rounded,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.store_rounded,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Branch Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    branch.category ?? 'Chi nhánh hệ thống',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Checkmark Icon
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// Isolated Stateful Content for Category Add/Edit Bottom Sheet
// ==========================================
class _CategorySheetContent extends StatefulWidget {
  final MerchantCategory? category;
  final void Function(String) onSave;

  const _CategorySheetContent({
    this.category,
    required this.onSave,
  });

  @override
  State<_CategorySheetContent> createState() => _CategorySheetContentState();
}

class _CategorySheetContentState extends State<_CategorySheetContent> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return _KeyboardAvoidPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tên danh mục thực đơn *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Đồ ăn vặt, Đồ uống, Tráng miệng...',
                      hintStyle: const TextStyle(
                          color: AppColors.textPlaceholder, fontSize: 13),
                      prefixIcon: const Icon(Icons.category_outlined,
                          color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.error, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên danh mục';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bottom buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                          child: const Text(
                            'Hủy bỏ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSave(_controller.text.trim());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEdit ? 'Lưu thay đổi' : 'Thêm mới',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Isolated Stateful Content for Dish Editor Bottom Sheet
// ==========================================
class _DishEditorSheetContent extends ConsumerStatefulWidget {
  final String categoryId;
  final MerchantDish? dish;
  final void Function(MerchantDish) onSave;
  final VoidCallback? onDelete;

  const _DishEditorSheetContent({
    required this.categoryId,
    this.dish,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<_DishEditorSheetContent> createState() =>
      _DishEditorSheetContentState();
}

class _DishEditorSheetContentState extends ConsumerState<_DishEditorSheetContent> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _descController;

  // Focus Nodes
  late FocusNode _nameNode;
  late FocusNode _priceNode;
  late FocusNode _discountNode;
  late FocusNode _descNode;

  // Selected availability and prefilled mock images
  String _availability = 'available';
  String _selectedImageUrl = '';
  late List<String> _mockFoodImages;

  // Option groups and toppings list state
  List<MerchantOptionGroup> _optionGroups = [];

  @override
  void initState() {
    super.initState();
    final d = widget.dish;

    _nameController = TextEditingController(text: d?.name ?? '');
    _priceController = TextEditingController(
        text: d != null ? d.originalPrice.toInt().toString() : '');
    _discountController = TextEditingController(
        text: (d != null && d.discountPrice != null)
            ? d.discountPrice!.toInt().toString()
            : '');
    _descController = TextEditingController(text: d?.description ?? '');

    _nameNode = FocusNode();
    _priceNode = FocusNode();
    _discountNode = FocusNode();
    _descNode = FocusNode();

    _mockFoodImages = [
      'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&q=80', // Pho
      'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80', // Soft drink
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80', // Crispy bread
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500&q=80', // Vietnamese Coffee
    ];

    _availability = d?.availability ?? 'available';
    _selectedImageUrl = d?.imageUrl ?? _mockFoodImages[0];

    if (d != null && d.imageUrl.isNotEmpty && !_mockFoodImages.contains(d.imageUrl)) {
      _mockFoodImages.insert(0, d.imageUrl);
    }

    // Deep copy option groups
    _optionGroups = d != null ? List.from(d.optionGroups) : [];
  }

  Future<void> _pickAndUploadCustomImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      final menuNotifier = ref.read(merchantMenuProvider.notifier);
      final branchId = menuNotifier.branchId;
      final isMockBranch = branchId == null || branchId.isEmpty || branchId.startsWith('mock_');
      final isMockDish = widget.dish == null || widget.dish!.id.startsWith('mock_');

      if (isMockBranch || isMockDish) {
        // Mock flow: Add local path directly
        setState(() {
          if (!_mockFoodImages.contains(image.path)) {
            _mockFoodImages.insert(0, image.path);
          }
          _selectedImageUrl = image.path;
        });
        if (mounted) {
          TopNotification.show(
            context,
            message: 'Đã chọn ảnh món ăn!',
          );
        }
        return;
      }

      // Show uploading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải ảnh lên...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      final String folder;
      if (widget.dish != null && widget.dish!.id.isNotEmpty) {
        folder = 'menu-items/${widget.dish!.id}';
      } else {
        folder = 'branches/$branchId';
      }

      final merchantRepo = MerchantRepository();
      final uploadedUrl = await merchantRepo.uploadImage(
        image.path,
        folder,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        if (!_mockFoodImages.contains(uploadedUrl)) {
          _mockFoodImages.insert(0, uploadedUrl);
        }
        _selectedImageUrl = uploadedUrl;
      });

      if (mounted) {
        TopNotification.show(
          context,
          message: 'Tải ảnh món ăn lên thành công!',
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint('Error picking/uploading image for dish: $e');
      if (mounted) {
        TopNotification.show(
          context,
          message: 'Lỗi tải ảnh: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _descController.dispose();

    _nameNode.dispose();
    _priceNode.dispose();
    _discountNode.dispose();
    _descNode.dispose();
    super.dispose();
  }

  // Topping Option Group helpers
  void _addNewOptionGroup() {
    setState(() {
      final newGroupId = 'opt-grp-${DateTime.now().millisecondsSinceEpoch}';
      _optionGroups.add(
        MerchantOptionGroup(
          id: newGroupId,
          groupName: 'Nhóm tùy chọn mới',
          isRequired: false,
          minSelect: 0,
          maxSelect: 1,
          items: const [
            MerchantOptionItem(
                id: 'item-1', itemName: 'Lựa chọn 1', extraPrice: 0),
          ],
        ),
      );
    });
  }

  void _removeOptionGroup(int grpIndex) {
    setState(() {
      _optionGroups.removeAt(grpIndex);
    });
  }

  void _addOptionItemToGroup(int grpIndex) {
    setState(() {
      final grp = _optionGroups[grpIndex];
      final newItems = List<MerchantOptionItem>.from(grp.items);
      newItems.add(
        MerchantOptionItem(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}',
          itemName: 'Tùy chọn mới',
          extraPrice: 5000,
        ),
      );
      _optionGroups[grpIndex] = grp.copyWith(items: newItems);
    });
  }

  void _removeOptionItemFromGroup(int grpIndex, int itemIndex) {
    setState(() {
      final grp = _optionGroups[grpIndex];
      final newItems = List<MerchantOptionItem>.from(grp.items);
      newItems.removeAt(itemIndex);
      _optionGroups[grpIndex] = grp.copyWith(items: newItems);
    });
  }

  // Submit / Save form details
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final originalPrice = double.tryParse(_priceController.text) ?? 0.0;
    final discountPrice = double.tryParse(_discountController.text);

    final finalDish = MerchantDish(
      id: widget.dish?.id ?? 'dish-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      originalPrice: originalPrice,
      discountPrice:
          discountPrice != null && discountPrice > 0 ? discountPrice : null,
      description: _descController.text.trim(),
      imageUrl: _selectedImageUrl,
      availability: _availability,
      optionGroups: _optionGroups,
    );

    widget.onSave(finalDish);
  }

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: _KeyboardAvoidPadding(
        child: Column(
          children: [
            // Drag handle indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.dish == null
                        ? 'Thêm món ăn mới'
                        : 'Chỉnh sửa món ăn',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: AppColors.error),
                      onPressed: () {
                        _showConfirmDeleteDish();
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // Scrollable Editor Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dish Name
                      _buildFieldLabel('Tên món ăn *'),
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameNode,
                        style: const TextStyle(fontSize: 14),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Nhập tên món ăn'
                                : null,
                        decoration: _buildInputDec(
                            'Nhập tên món ví dụ: Phở nạm, Bánh mì trứng...'),
                      ),
                      const SizedBox(height: 14),

                      // Price and Discount Price
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Giá gốc (VNĐ) *'),
                                TextFormField(
                                  controller: _priceController,
                                  focusNode: _priceNode,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nhập giá bán';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Không hợp lệ';
                                    }
                                    return null;
                                  },
                                  decoration: _buildInputDec('Ví dụ: 50000'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Giá khuyến mãi (đ)'),
                                TextFormField(
                                  controller: _discountController,
                                  focusNode: _discountNode,
                                  style: const TextStyle(fontSize: 14),
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      _buildInputDec('Bỏ trống nếu không giảm'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      _buildFieldLabel('Mô tả chi tiết'),
                      TextFormField(
                        controller: _descController,
                        focusNode: _descNode,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        decoration: _buildInputDec(
                            'Hành trần, giá sống, nước dùng trong thơm lừng...'),
                      ),
                      const SizedBox(height: 14),

                      // Image picker prefilled slider
                      _buildFieldLabel('Chọn hình ảnh món ăn'),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _mockFoodImages.length + 1,
                          itemBuilder: (context, idx) {
                            if (idx == 0) {
                              // Custom image upload card
                              return GestureDetector(
                                onTap: _pickAndUploadCustomImage,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(0xFFF9FAFB),
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: AppColors.textTertiary,
                                        size: 20,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tải ảnh lên',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textTertiary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final imgUrl = _mockFoodImages[idx - 1];
                            final isSelected = imgUrl == _selectedImageUrl;
                            final isNetworkImage = imgUrl.startsWith('http://') || imgUrl.startsWith('https://');

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedImageUrl = imgUrl),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.outlineVariant,
                                    width: isSelected ? 3.0 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: isNetworkImage
                                      ? Image.network(imgUrl, fit: BoxFit.cover)
                                      : Image.file(File(imgUrl), fit: BoxFit.cover),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Availability Status
                      _buildFieldLabel('Trạng thái hoạt động'),
                      Row(
                        children: [
                          _buildStatusChoice(
                              'available', 'Khả dụng', AppColors.success),
                          const SizedBox(width: 10),
                          _buildStatusChoice('sold_out_today', 'Hết hôm nay',
                              AppColors.accent),
                          const SizedBox(width: 10),
                          _buildStatusChoice(
                              'disabled', 'Tạm ngưng', AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // ⚙️ ADVANCED OPTION GROUPS (TOPPINGS) BUILDER
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel('Nhóm tùy chọn / Topping đi kèm'),
                          GestureDetector(
                            onTap: _addNewOptionGroup,
                            child: const Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Thêm nhóm',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_optionGroups.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.bgWarm.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.outlineVariant,
                                style: BorderStyle.solid),
                          ),
                          child: const Center(
                            child: Text(
                              'Chưa thiết lập topping. Bấm "Thêm nhóm" ở trên để tạo size hoặc topping đính kèm món ăn!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _optionGroups.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, grpIdx) {
                            final grp = _optionGroups[grpIdx];
                            return _buildOptionGroupEditorCard(grp, grpIdx);
                          },
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: const Text('Hủy bỏ',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Lưu thay đổi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  // Option Group Container widget inside Bottom Sheet builder
  Widget _buildOptionGroupEditorCard(MerchantOptionGroup grp, int grpIdx) {
    return Card(
      elevation: 0,
      color: AppColors.bgSoft.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option group header: Name and delete button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: grp.groupName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    onChanged: (val) {
                      final currentGrp = _optionGroups[grpIdx];
                      _optionGroups[grpIdx] =
                          currentGrp.copyWith(groupName: val);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Tên nhóm tùy chọn',
                      labelStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                      floatingLabelStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.outlineVariant),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded,
                      color: AppColors.error, size: 18),
                  onPressed: () => _removeOptionGroup(grpIdx),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Option details: IsRequired checkbox and min/max limits
            Row(
              children: [
                Checkbox(
                  value: grp.isRequired,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      final currentGrp = _optionGroups[grpIdx];
                      _optionGroups[grpIdx] = currentGrp.copyWith(
                          isRequired: val ?? false,
                          minSelect: (val ?? false) ? 1 : 0);
                    });
                  },
                ),
                const Text('Bắt buộc chọn (e.g. Size)',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('Chọn tối đa:',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                DropdownButton<int>(
                  value: grp.maxSelect,
                  elevation: 1,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        final currentGrp = _optionGroups[grpIdx];
                        _optionGroups[grpIdx] =
                            currentGrp.copyWith(maxSelect: val);
                      });
                    }
                  },
                  items: List.generate(5, (index) => index + 1).map((val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text('$val'),
                    );
                  }).toList(),
                ),
              ],
            ),
            const Divider(height: 12, color: AppColors.divider),

            // Option items list
            const Text(
              'Lựa chọn con (Topping):',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grp.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, itemIdx) {
                final item = grp.items[itemIdx];
                return Row(
                  children: [
                    // Item Name input
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: item.itemName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary),
                        onChanged: (val) {
                          final currentGrp = _optionGroups[grpIdx];
                          final newItems =
                              List<MerchantOptionItem>.from(currentGrp.items);
                          newItems[itemIdx] =
                              newItems[itemIdx].copyWith(itemName: val);
                          _optionGroups[grpIdx] =
                              currentGrp.copyWith(items: newItems);
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Ví dụ: Trứng chần...',
                          hintStyle: const TextStyle(
                              color: AppColors.textPlaceholder, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Extra Price input
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.extraPrice.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final currentGrp = _optionGroups[grpIdx];
                          final newItems =
                              List<MerchantOptionItem>.from(currentGrp.items);
                          newItems[itemIdx] = newItems[itemIdx].copyWith(
                              extraPrice: double.tryParse(val) ?? 0.0);
                          _optionGroups[grpIdx] =
                              currentGrp.copyWith(items: newItems);
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: '+Giá: 5000',
                          hintStyle: const TextStyle(
                              color: AppColors.textPlaceholder, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: AppColors.error, size: 18),
                      onPressed: () =>
                          _removeOptionItemFromGroup(grpIdx, itemIdx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // Button to add option item inside group
            Center(
              child: TextButton.icon(
                onPressed: () => _addOptionItemToGroup(grpIdx),
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: const Text('Thêm lựa chọn con',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Radio button generator for availability status in modal
  Widget _buildStatusChoice(String statusVal, String label, Color color) {
    final isSelected = _availability == statusVal;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _availability = statusVal),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.outlineVariant,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _showConfirmDeleteDish() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa món ăn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
              'Bạn chắc chắn muốn xóa món ăn "${_nameController.text}" khỏi thực đơn?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                if (widget.onDelete != null) widget.onDelete!();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: const Text('Xóa bỏ'),
            ),
          ],
        );
      },
    );
  }
}

class _KeyboardAvoidPadding extends StatelessWidget {
  final Widget child;
  const _KeyboardAvoidPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    );
  }
}

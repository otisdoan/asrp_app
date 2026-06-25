import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';
import 'stock_import_page.dart';
import 'recipe_management_page.dart';
import 'inventory_reconciliation_page.dart';
import 'inventory_ledger_page.dart';

class InventoryDashboardPage extends ConsumerStatefulWidget {
  const InventoryDashboardPage({super.key});

  @override
  ConsumerState<InventoryDashboardPage> createState() =>
      _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends ConsumerState<InventoryDashboardPage>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  String _statusFilter = 'Tất cả';

  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    try {
      final double bottomInset =
          WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
              ? WidgetsBinding
                  .instance.platformDispatcher.views.first.viewInsets.bottom
              : 0.0;
      final bool isKeyboardOpen = bottomInset > 0;
      if (_wasKeyboardOpen && !isKeyboardOpen) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _wasKeyboardOpen = isKeyboardOpen;
    } catch (_) {}
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);

    final filteredIngredients = state.ingredients.where((ing) {
      final matchesSearch =
          ing.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_statusFilter == 'Tất cả') return matchesSearch;
      if (_statusFilter == 'Hết hàng')
        return matchesSearch &&
            (ing.status == 'Hết hàng' || ing.currentStock <= 0);
      if (_statusFilter == 'Cảnh báo/Kho thấp') {
        return matchesSearch &&
            (ing.status == 'Kho thấp' ||
                ing.status == 'Cảnh báo' ||
                ing.status == 'Sắp hết');
      }
      return matchesSearch;
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.onPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Bảng điều khiển kho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: AppColors.onPrimary),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InventoryLedgerPage()),
                );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.restaurant_menu, color: AppColors.onPrimary),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecipeManagementPage()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TOP KPI ROW =====
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildKpiCard(
                      title: 'TỔNG GIÁ TRỊ KHO',
                      value: '${_formatPrice(state.totalStockValue)}đ',
                      subtitle: '+1.2%',
                      subtitleColor: AppColors.success,
                      icon: Icons.monetization_on_outlined,
                      iconColor: AppColors.primary,
                      cardColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    _buildKpiCard(
                      title: 'HẾT HÀNG',
                      value: '${state.outOfStockCount} mặt hàng',
                      subtitle: 'Cần nhập gấp',
                      subtitleColor: AppColors.textSecondary,
                      icon: Icons.error_outline,
                      iconColor: AppColors.error,
                      cardColor: Colors.white,
                      onTap: () {
                        setState(() {
                          _statusFilter = _statusFilter == 'Hết hàng'
                              ? 'Tất cả'
                              : 'Hết hàng';
                        });
                      },
                      isActive: _statusFilter == 'Hết hàng',
                    ),
                    const SizedBox(width: 12),
                    _buildKpiCard(
                      title: 'CẢNH BÁO KHO THẤP',
                      value: '${state.lowStockCount} mặt hàng',
                      subtitle: 'Dưới mức an toàn',
                      subtitleColor: AppColors.textSecondary,
                      icon: Icons.notifications_none,
                      iconColor: AppColors.accent,
                      cardColor: Colors.white,
                      onTap: () {
                        setState(() {
                          _statusFilter = _statusFilter == 'Cảnh báo/Kho thấp'
                              ? 'Tất cả'
                              : 'Cảnh báo/Kho thấp';
                        });
                      },
                      isActive: _statusFilter == 'Cảnh báo/Kho thấp',
                    ),
                  ],
                ),
              ),

              // ===== SEARCH AND FILTER BAR =====
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm nguyên liệu...',
                            hintStyle: TextStyle(
                                color: AppColors.textPlaceholder, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== LIST HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DANH SÁCH NGUYÊN LIỆU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_statusFilter != 'Tất cả')
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _statusFilter = 'Tất cả';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Xóa lọc',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.close,
                                  color: AppColors.primary, size: 10),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ===== INGREDIENT LIST =====
              Expanded(
                child: filteredIngredients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 48, color: AppColors.textPlaceholder),
                            const SizedBox(height: 12),
                            const Text(
                              'Không tìm thấy nguyên liệu phù hợp',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredIngredients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildIngredientCard(
                              filteredIngredients[index]);
                        },
                      ),
              ),

              // ===== BOTTOM ACTION BUTTONS =====
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.outlineVariant),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Nhập kho',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const StockImportPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                                color: AppColors.primary, width: 1),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.playlist_add_check, size: 18),
                        label: const Text('Kiểm kho',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const InventoryReconciliationPage()),
                          );
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== WIDGET BUILDERS =====

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? iconColor : AppColors.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(InventoryIngredient ing) {
    IconData itemIcon = Icons.inventory_2;
    if (ing.name.contains('Mì'))
      itemIcon = Icons.restaurant;
    else if (ing.name.contains('Thịt'))
      itemIcon = Icons.kebab_dining;
    else if (ing.name.contains('Hành'))
      itemIcon = Icons.eco;
    else if (ing.name.contains('Tôm'))
      itemIcon = Icons.set_meal;
    else if (ing.name.contains('Dầu')) itemIcon = Icons.opacity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ingredient icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(itemIcon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          // Info and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ing.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ing.ratio,
                          minHeight: 5,
                          backgroundColor: AppColors.outlineVariant,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(ing.statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ing.percentage}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ing.statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tồn: ${ing.currentStock.toStringAsFixed(0)} / ${ing.minStockLevel.toStringAsFixed(0)} ${ing.unit}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ing.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ing.statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              ing.status,
              style: TextStyle(
                color: ing.statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

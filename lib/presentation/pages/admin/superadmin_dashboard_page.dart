import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

/// SuperAdmin Dashboard Page - Brand-level overview across multiple branches.
/// Includes KPIs, branch comparative revenue charts, top/bottom seller popularity analytics,
/// core ingredient stock levels per branch, and a reactive stock transfer coordinator.
class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState
    extends ConsumerState<SuperAdminDashboardPage> {
  String _selectedBranchFilter =
      'Tất cả chi nhánh'; // 'Tất cả chi nhánh' | 'Quận 1' | 'Quận 3' | 'Phú Nhuận'
  String _selectedTimeFilter =
      'Hôm nay'; // 'Hôm nay' | 'Tuần này' | 'Tháng này' | 'Tùy chọn'
  DateTimeRange? _selectedDateRange;
  int _selectedChartBarIndex = 0; // Selected branch in comparison chart

  int get _customRangeDays {
    if (_selectedDateRange == null) return 7;
    return _selectedDateRange!.duration.inDays + 1;
  }

  int _selectedTabIdx =
      0; // 0: Tài chính chuỗi, 1: Kho chuỗi, 2: Vận hành chuỗi

  // Dynamic Tab Title
  String get _selectedTabTitle {
    switch (_selectedTabIdx) {
      case 1:
        return 'Tồn kho toàn chuỗi';
      case 2:
        return 'Vận hành toàn chuỗi';
      case 0:
      default:
        return 'Doanh thu toàn chuỗi';
    }
  }

  // Interactive Live Inventory Stock Levels (Reactive state)
  final Map<String, Map<String, double>> _inventory = {
    'Bánh phở tươi': {
      'Quận 1': 4.5,
      'Quận 3': 48.0,
      'Phú Nhuận': 22.0,
    },
    'Thịt bò tái': {
      'Quận 1': 28.0,
      'Quận 3': 6.5,
      'Phú Nhuận': 25.0,
    },
    'Sườn heo non': {
      'Quận 1': 8.0,
      'Quận 3': 32.0,
      'Phú Nhuận': 5.0,
    },
    'Hành lá': {
      'Quận 1': 1.2,
      'Quận 3': 10.0,
      'Phú Nhuận': 5.5,
    },
  };

  // Safe stock thresholds for alert notifications
  double _getSafeThreshold(String ingredient) {
    if (ingredient == 'Hành lá') return 3.0; // 3kg
    return 10.0; // 10kg default
  }

  // Mock branch revenue datasets based on Time Filter
  Map<String, double> get _branchRevenues {
    if (_selectedTimeFilter == 'Tùy chọn') {
      final double factor = _customRangeDays.toDouble();
      return {
        'Quận 1': 42.5 * factor,
        'Quận 3': 38.2 * factor,
        'Phú Nhuận': 27.5 * factor,
      };
    }

    switch (_selectedTimeFilter) {
      case 'Tuần này':
        return {
          'Quận 1': 285.4,
          'Quận 3': 242.8,
          'Phú Nhuận': 184.2,
        };
      case 'Tháng này':
        return {
          'Quận 1': 1145.2,
          'Quận 3': 958.6,
          'Phú Nhuận': 728.4,
        };
      case 'Hôm nay':
      default:
        return {
          'Quận 1': 42.5,
          'Quận 3': 38.2,
          'Phú Nhuận': 27.5,
        };
    }
  }

  // Calculated brand KPIs
  double get _totalRevenue =>
      _branchRevenues.values.fold(0.0, (sum, val) => sum + val);

  double get _currentFilteredRevenue {
    if (_selectedBranchFilter == 'Tất cả chi nhánh') {
      return _totalRevenue;
    }
    return _branchRevenues[_selectedBranchFilter] ?? 0.0;
  }

  int get _activeBranchesCount => _branchRevenues.keys.length;

  Future<void> _selectCustomDateRange() async {
    final initialRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _selectedDateRange = pickedRange;
        _selectedTimeFilter = 'Tùy chọn';
      });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Về trang Khách hàng?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn quay lại giao diện đặt món của Khách hàng không?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppConstants.routeProfile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  // Opens the beautiful bottom sheet to transfer stocks
  void _openTransferBottomSheet(String defaultIngredient) {
    String selectedIngredient = defaultIngredient;
    String sourceBranch = 'Quận 3'; // default source with plenty of stock
    String targetBranch = 'Quận 1'; // default targets
    final qtyController = TextEditingController(text: '5.0');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final sourceStock =
                _inventory[selectedIngredient]?[sourceBranch] ?? 0.0;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
              ),
              child: _KeyboardAvoidPadding(
                extraBottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.swap_horizontal_circle_outlined,
                            color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Điều phối nguyên liệu chuỗi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Luân chuyển nguyên liệu từ chi nhánh dư thừa sang chi nhánh thiếu hụt',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),

                    // 1. Choose Ingredient
                    const Text('Chọn nguyên liệu',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedIngredient,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primary),
                          items: _inventory.keys.map((ing) {
                            return DropdownMenuItem(
                                value: ing, child: Text(ing));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedIngredient = val;
                                // Auto adjust branches if overlapping
                                if (sourceBranch == targetBranch) {
                                  targetBranch = sourceBranch == 'Quận 3'
                                      ? 'Quận 1'
                                      : 'Quận 3';
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Source and Target branch selection in a Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chi nhánh nguồn',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: sourceBranch,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: AppColors.primary),
                                    items: ['Quận 1', 'Quận 3', 'Phú Nhuận']
                                        .map((br) {
                                      return DropdownMenuItem(
                                          value: br, child: Text(br));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          sourceBranch = val;
                                          if (sourceBranch == targetBranch) {
                                            targetBranch =
                                                sourceBranch == 'Quận 3'
                                                    ? 'Quận 1'
                                                    : 'Quận 3';
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward,
                            color: AppColors.textTertiary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chi nhánh đích',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: targetBranch,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: AppColors.primary),
                                    items: ['Quận 1', 'Quận 3', 'Phú Nhuận']
                                        .map((br) {
                                      return DropdownMenuItem(
                                          value: br, child: Text(br));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          targetBranch = val;
                                          if (sourceBranch == targetBranch) {
                                            sourceBranch =
                                                targetBranch == 'Quận 3'
                                                    ? 'Quận 1'
                                                    : 'Quận 3';
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Current Source inventory display
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Tồn kho nguồn tại $sourceBranch: ',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${sourceStock.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sourceStock <=
                                    _getSafeThreshold(selectedIngredient)
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. Input quantity
                    const Text('Số lượng điều phối (kg)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: qtyController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Nhập số kg...',
                        filled: true,
                        fillColor: AppColors.bgSoft,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final transferQty =
                              double.tryParse(qtyController.text) ?? 0.0;
                          if (transferQty <= 0.0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Vui lòng nhập số lượng hợp lệ lớn hơn 0.')),
                            );
                            return;
                          }
                          if (transferQty > sourceStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Không đủ tồn kho nguồn để thực hiện! Tối đa: ${sourceStock.toStringAsFixed(1)}kg.')),
                            );
                            return;
                          }

                          // Execute reactive transfer in State
                          setState(() {
                            _inventory[selectedIngredient]![sourceBranch] =
                                sourceStock - transferQty;
                            final targetStock = _inventory[selectedIngredient]
                                    ?[targetBranch] ??
                                0.0;
                            _inventory[selectedIngredient]![targetBranch] =
                                targetStock + transferQty;
                          });

                          Navigator.pop(ctx);
                          _showTransferSuccessDialog(selectedIngredient,
                              sourceBranch, targetBranch, transferQty);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Xác nhận vận chuyển',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show a neat success pop up on coordinate completed
  void _showTransferSuccessDialog(
      String ing, String src, String dst, double qty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: AppColors.successContainer, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 30, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Điều phối thành công!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã chuyển thành công ${qty.toStringAsFixed(1)}kg $ing từ chi nhánh $src đến $dst.',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final rawName = user?.displayName;
    final displayName =
        (rawName == null || rawName.trim().isEmpty) ? 'Tổng quản trị' : rawName;
    final initialChar = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Sleek Gradient Header Section (Fixed at top)
            _buildHeader(displayName, initialChar),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Sliding Segmented Tab Selector (Primary navigation)
                      _buildTabSelector(),
                      const SizedBox(height: 16),

                      // 4. Dynamic Title & Filter Chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTabTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildFilterRow(),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 5. Dynamic Tab View contents
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildSelectedTabContent(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header UI ─────────────────────────────────────────────────────────
  Widget _buildHeader(String displayName, String initialChar) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Avatar profile push
            GestureDetector(
              onTap: () => context.push(AppConstants.routeProfile),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initialChar,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(AppConstants.routeProfile),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'DineX System · Tổng quản trị',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Quick logout button
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 22),
              onPressed: _confirmLogout,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Beautiful Modal Bottom Sheet to choose a report branch
  void _showBranchSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Chọn chi nhánh báo cáo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Xem số liệu doanh thu, tồn kho và độ phổ biến từ chi nhánh được chọn',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Branches options list
              ...['Tất cả chi nhánh', 'Quận 1', 'Quận 3', 'Phú Nhuận']
                  .map((branchName) {
                final isSelected = _selectedBranchFilter == branchName;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.bgSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        branchName == 'Tất cả chi nhánh'
                            ? Icons.all_inclusive_rounded
                            : Icons.store_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      branchName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 22)
                        : const Icon(Icons.circle_outlined,
                            color: AppColors.textSecondary, size: 20),
                    onTap: () {
                      setState(() {
                        _selectedBranchFilter = branchName;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ─── Unified Horizontal Filter Row ──────────────────────────────────────
  Widget _buildFilterRow() {
    final bool isCustom = _selectedTimeFilter == 'Tùy chọn';
    final String customLabel = isCustom && _selectedDateRange != null
        ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
        : 'Chọn ngày';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Branch Selector ActionChip
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(
                Icons.storefront_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedBranchFilter,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
              onPressed: _showBranchSelectorSheet,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              side: const BorderSide(color: AppColors.primary, width: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          // Time Filter Chips
          ...['Hôm nay', 'Tuần này', 'Tháng này'].map((filter) {
            final isSelected = _selectedTimeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedTimeFilter = filter;
                    });
                  }
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                elevation: 0,
                pressElevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: 0.8,
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: isCustom ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    customLabel.replaceAll(' ', '\u00A0'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCustom ? FontWeight.bold : FontWeight.w600,
                      color: isCustom ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              selected: isCustom,
              showCheckmark: false,
              onSelected: (val) {
                _selectCustomDateRange();
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              elevation: 0,
              pressElevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isCustom ? AppColors.primary : AppColors.divider,
                  width: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Elegant Gradient Net Sales Card ───────────────────────────────────
  Widget _buildNetSalesOverview() {
    final revenueText =
        '${(_currentFilteredRevenue * 1000000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';

    final String growth = _selectedTimeFilter == 'Hôm nay'
        ? '+18.5%'
        : _selectedTimeFilter == 'Tuần này'
            ? '+15.2%'
            : _selectedTimeFilter == 'Tháng này'
                ? '+19.8%'
                : '+16.5%';

    final String compareText = _selectedTimeFilter == 'Hôm nay'
        ? 'So với cùng kỳ hôm qua (92.4M)'
        : _selectedTimeFilter == 'Tuần này'
            ? 'So với tuần trước (612.0M)'
            : _selectedTimeFilter == 'Tháng này'
                ? 'So với tháng trước (2.56B)'
                : 'Dữ liệu tổng hợp theo khoảng ngày';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng doanh thu chuỗi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      growth,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            revenueText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            compareText,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Cards Section ─────────────────────────────────────────────────
  Widget _buildKPIsSection() {
    final isAll = _selectedBranchFilter == 'Tất cả chi nhánh';

    int ordersCount = isAll ? 1542 : 524;
    if (_selectedTimeFilter == 'Hôm nay') {
      ordersCount = isAll ? 180 : 60;
    } else if (_selectedTimeFilter == 'Tuần này') {
      ordersCount = isAll ? 1200 : 400;
    } else if (_selectedTimeFilter == 'Tùy chọn') {
      final factor = _customRangeDays;
      ordersCount = ((isAll ? 180 : 60) * factor).round();
    }

    final formattedOrders = ordersCount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    return Column(
      children: [
        _buildKPITile(
          title: 'Chi nhánh hoạt động',
          value: '$_activeBranchesCount / $_activeBranchesCount tốt',
          icon: Icons.store_rounded,
          iconBg: AppColors.successContainer,
          iconColor: AppColors.success,
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Lợi nhuận gộp ước tính',
          value:
              '${((_currentFilteredRevenue * 0.65) * 1000000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
          icon: Icons.trending_up_rounded,
          iconBg: AppColors.badgeBestBg,
          iconColor: AppColors.badgeBestText,
          badgeText: '65%',
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Đơn hàng thành công',
          value: '$formattedOrders đơn',
          icon: Icons.shopping_bag_rounded,
          iconBg: AppColors.badgeNewBg,
          iconColor: AppColors.badgeNewText,
          growth: _selectedTimeFilter == 'Hôm nay' ? '+12.4%' : null,
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Giá trị trung bình bill',
          value: '142,500đ',
          icon: Icons.receipt_long_rounded,
          iconBg: AppColors.badgeHotBg,
          iconColor: AppColors.badgeHotText,
        ),
      ],
    );
  }

  Widget _buildKPITile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? growth,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (growth != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                growth,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Comparative Chart UI ─────────────────────────────────────────────
  Widget _buildBranchComparisonChart() {
    final list = _branchRevenues.entries.toList();
    final double maxVal =
        list.fold(0.0, (max, entry) => entry.value > max ? entry.value : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Doanh thu so sánh chi nhánh',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              Text(
                'Tổng chuỗi: ${_totalRevenue.toStringAsFixed(1)}M',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(list.length, (index) {
                final entry = list[index];
                final isSelected = _selectedChartBarIndex == index;
                final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedChartBarIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              '${entry.value.toStringAsFixed(1)}M',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 80 * ratio,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [AppColors.primary, AppColors.secondary]
                                  : [
                                      AppColors.primary.withValues(alpha: 0.15),
                                      AppColors.secondary
                                          .withValues(alpha: 0.15)
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.2),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Label
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Chi nhánh ${list[_selectedChartBarIndex].key} dẫn đầu doanh thu với ${list[_selectedChartBarIndex].value.toStringAsFixed(1)} triệu VNĐ.',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Core Ingredient Stock Alerts UI ──────────────────────────────────
  Widget _buildStockAlertsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tồn kho & Điều phối cốt lõi',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Icon(Icons.inventory, color: AppColors.primary, size: 14),
                  SizedBox(width: 4),
                  Text('Theo chi nhánh',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inventory stock mapping
          ..._inventory.keys.map((ing) {
            final qtyMap = _inventory[ing]!;
            final threshold = _getSafeThreshold(ing);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ing,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      GestureDetector(
                        onTap: () => _openTransferBottomSheet(ing),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Điều phối',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Branches stock status list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: qtyMap.entries.map((branchEntry) {
                      final isLow = branchEntry.value <= threshold;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLow
                                  ? AppColors.error.withValues(alpha: 0.5)
                                  : AppColors.divider,
                              width: isLow ? 1.2 : 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                branchEntry.key,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${branchEntry.value.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isLow
                                      ? AppColors.error
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isLow
                                      ? AppColors.error.withValues(alpha: 0.1)
                                      : AppColors.successContainer
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isLow ? 'Thiếu hụt' : 'Đầy đủ',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isLow
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Best/Worst Sellers UI ─────────────────────────────────────────────
  Widget _buildDishPopularitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích phổ biến món ăn chuỗi',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          // 1. BEST SELLERS
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.success, size: 18),
              SizedBox(width: 6),
              Text(
                'Món bán chạy hàng đầu (Best Sellers)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPopularItemBar(
              'Phở bò đặc biệt tái chín', 0.44, '44%', AppColors.primary),
          _buildPopularItemBar(
              'Cơm sườn nướng mật ong', 0.28, '28%', AppColors.secondary),
          _buildPopularItemBar(
              'Cà phê sữa đá Sài Gòn', 0.18, '18%', AppColors.accent),

          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // 2. WORST SELLERS
          const Row(
            children: [
              Icon(Icons.trending_down, color: AppColors.error, size: 18),
              SizedBox(width: 6),
              Text(
                'Món bán chậm nhất (Cần tối ưu)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPopularItemBar('Bún riêu cua đồng (Phú Nhuận)', 0.03, '3%',
              const Color(0xFF90A4AE)),
          _buildPopularItemBar('Trà sữa trân châu (Quận 1)', 0.025, '2.5%',
              const Color(0xFFB0BEC5)),
          _buildPopularItemBar('Chè khúc bạch nhãn xuồng (Quận 3)', 0.012,
              '1.2%', const Color(0xFFCFD8DC)),
        ],
      ),
    );
  }

  Widget _buildPopularItemBar(
      String name, double percentage, String label, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, color: barColor, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 5,
              backgroundColor: AppColors.divider.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SuperAdmin Dashboard Sub-Tabs ──────────────────────────────────────

  Widget _buildTabSelector() {
    final List<String> tabs = [
      'Tài chính chuỗi',
      'Kho chuỗi',
      'Vận hành chuỗi'
    ];
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedTabIdx == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTabIdx = idx;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[idx],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIdx) {
      case 1:
        return _buildInventoryTab();
      case 2:
        return _buildOperationsTab();
      case 0:
      default:
        return _buildFinancialTab();
    }
  }

  Widget _buildFinancialTab() {
    final isAll = _selectedBranchFilter == 'Tất cả chi nhánh';

    return Column(
      key: const ValueKey('financial_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNetSalesOverview(),
        const SizedBox(height: 18),
        _buildKPIsSection(),
        const SizedBox(height: 16),
        if (isAll) ...[
          _buildBranchComparisonChart(),
          const SizedBox(height: 16),
        ],
        _buildConsolidatedPayments(),
        const SizedBox(height: 16),
        _buildConsolidatedOrderSources(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConsolidatedPayments() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu thanh toán toàn chuỗi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentRow(
              'Chuyển khoản (QR)', 0.52, AppColors.secondary, '52%'),
          const SizedBox(height: 8),
          _buildPaymentRow('Tiền mặt', 0.28, AppColors.primary, '28%'),
          const SizedBox(height: 8),
          _buildPaymentRow(
              'Ví điện tử (Momo/ZaloPay)', 0.20, AppColors.accent, '20%'),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
      String label, double pct, Color color, String pctText) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            Text(pctText,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: AppColors.divider.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildConsolidatedOrderSources() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu nguồn đơn hàng toàn chuỗi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentRow(
              'Ăn tại chỗ (Dine-in)', 0.64, AppColors.primary, '64%'),
          const SizedBox(height: 8),
          _buildPaymentRow(
              'Đặt trực tuyến / Mang đi', 0.36, AppColors.tertiary, '36%'),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      key: const ValueKey('inventory_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStockAlertsGrid(),
        const SizedBox(height: 16),
        _buildSupplyChainTracker(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSupplyChainTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Logistics & Bếp trung tâm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.local_shipping,
                      color: AppColors.primary, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '3 phiếu đang chạy',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLogisticsItem(
            code: 'CK-8942',
            route: 'Bếp trung tâm ➔ Chi nhánh Quận 1',
            status: 'Đang vận chuyển',
            statusColor: AppColors.primary,
            time: 'Dự kiến đến lúc 18:30',
            itemCount: '150kg bánh phở, 30kg bò',
          ),
          const Divider(color: AppColors.divider, height: 16),
          _buildLogisticsItem(
            code: 'CK-8941',
            route: 'Chi nhánh Quận 3 ➔ Chi nhánh Quận 1',
            status: 'Hoàn thành',
            statusColor: AppColors.success,
            time: 'Đã nhận lúc 15:40 (Đủ lượng)',
            itemCount: '5kg thịt bò tái (Điều phối cứu trợ)',
          ),
          const Divider(color: AppColors.divider, height: 16),
          _buildLogisticsItem(
            code: 'CK-8940',
            route: 'Bếp trung tâm ➔ Chi nhánh Phú Nhuận',
            status: 'Chờ xuất kho',
            statusColor: AppColors.accent,
            time: 'Dự kiến xuất lúc 19:00',
            itemCount: '80kg bánh phở, 20kg sườn',
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsItem({
    required String code,
    required String route,
    required String status,
    required Color statusColor,
    required String time,
    required String itemCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              code,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          route,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              itemCount,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            Text(
              time,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperationsTab() {
    return Column(
      key: const ValueKey('operations_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDishPopularitySection(),
        const SizedBox(height: 16),
        _buildBranchSpeedComparison(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBranchSpeedComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So sánh hiệu suất vận hành chi nhánh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpeedRow('Chi nhánh Quận 1', '12,5 phút', 0.65,
              AppColors.success, 'Tỷ lệ hủy: 1.5%'),
          const SizedBox(height: 12),
          _buildSpeedRow('Chi nhánh Quận 3', '11,8 phút', 0.58,
              AppColors.primary, 'Tỷ lệ hủy: 1.8%'),
          const SizedBox(height: 12),
          _buildSpeedRow('Chi nhánh Phú Nhuận', '13,2 phút', 0.72,
              AppColors.accent, 'Tỷ lệ hủy: 2.1%'),
        ],
      ),
    );
  }

  Widget _buildSpeedRow(String name, String timeText, double val, Color color,
      String cancelText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 4,
            backgroundColor: AppColors.divider.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cancelText,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _KeyboardAvoidPadding extends StatelessWidget {
  final Widget child;
  final double extraBottom;
  const _KeyboardAvoidPadding({required this.child, this.extraBottom = 0.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + extraBottom,
      ),
      child: child,
    );
  }
}

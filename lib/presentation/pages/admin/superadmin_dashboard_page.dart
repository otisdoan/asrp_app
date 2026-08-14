import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/analytics_model.dart';
import '../../../providers/analytics_provider.dart';
import '../../../core/utils/format_utils.dart';

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

  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    // Realtime polling every 3 seconds to keep chain dashboard inventory & transfer tickets synced automatically
    _realtimeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.invalidate(brandDashboardFutureProvider(_currentDateRange));
        ref.invalidate(transferTicketsProvider(TransferTicketParams()));
        final apiData = _currentApiData;
        if (apiData != null) {
          for (var b in apiData.branches) {
            ref.invalidate(branchInventoriesProvider(b.branchId));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }


  BrandDashboardResponseModel? _currentApiData;

  DateTimeRange? get _currentDateRange {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 'Hôm nay':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Tuần này':
        final diff = now.weekday - 1;
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: diff));
        return DateTimeRange(
          start: startOfWeek,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Tháng này':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(
          start: startOfMonth,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Tùy chọn':
      default:
        return _selectedDateRange;
    }
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



  // Safe stock thresholds for alert notifications
  double _getSafeThreshold(String ingredient) {
    if (ingredient == 'Hành lá') return 3.0; // 3kg
    return 10.0; // 10kg default
  }

  // Live branch revenue dataset from API data
  Map<String, double> get _branchRevenues {
    final apiData = _currentApiData;
    if (apiData == null || apiData.branches.isEmpty) {
      return {};
    }
    final Map<String, double> revenues = {};
    for (var branch in apiData.branches) {
      revenues[branch.branchName] = branch.revenue;
    }
    return revenues;
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
  void _openTransferBottomSheet(
    String defaultIngredientName,
    List<BranchDashboardItemModel> branches,
    Map<String, List<BranchInventoryItem>> branchInventories,
  ) {
    String selectedIngredientName = defaultIngredientName;

    final List<BranchInventoryItem> distinctIngredients = [];
    for (var list in branchInventories.values) {
      for (var item in list) {
        if (!distinctIngredients.any((e) => e.ingredientName == item.ingredientName)) {
          distinctIngredients.add(item);
        }
      }
    }

    if (distinctIngredients.isEmpty) return;

    BranchInventoryItem selectedIngredientItem = distinctIngredients.firstWhere(
      (e) => e.ingredientName == selectedIngredientName,
      orElse: () => distinctIngredients.first,
    );

    String sourceBranchId = branches.isNotEmpty ? branches.first.branchId : '';
    String targetBranchId = branches.length > 1
        ? branches.firstWhere((b) => b.branchId != sourceBranchId, orElse: () => branches.last).branchId
        : sourceBranchId;
    final qtyController = TextEditingController(text: '5.0');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final sourceList = branchInventories[sourceBranchId] ?? [];
            final sourceItem = sourceList.firstWhere(
              (e) => e.ingredientName == selectedIngredientName,
              orElse: () => BranchInventoryItem(
                id: '',
                branchId: sourceBranchId,
                branchName: '',
                ingredientId: selectedIngredientItem.ingredientId,
                ingredientName: selectedIngredientName,
                unit: selectedIngredientItem.unit,
                currentStock: 0.0,
                minStockLevel: 0.0,
              ),
            );
            final sourceStock = sourceItem.currentStock;

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
                    const Text('Chọn nguyên liệu *',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedIngredientName,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: AppColors.primary),
                          items: distinctIngredients.map((ing) {
                            return DropdownMenuItem(
                                value: ing.ingredientName, child: Text(ing.ingredientName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedIngredientName = val;
                                selectedIngredientItem = distinctIngredients.firstWhere(
                                  (e) => e.ingredientName == selectedIngredientName,
                                  orElse: () => distinctIngredients.first,
                                );
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
                              const Text('Chi nhánh nguồn *',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: sourceBranchId,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: AppColors.primary),
                                    items: branches.map((br) {
                                      return DropdownMenuItem(
                                          value: br.branchId, child: Text(br.branchName));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          sourceBranchId = val;
                                          if (sourceBranchId == targetBranchId) {
                                            targetBranchId = branches.firstWhere((b) => b.branchId != sourceBranchId, orElse: () => branches.first).branchId;
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
                              const Text('Chi nhánh đích *',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: targetBranchId,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down,
                                        color: AppColors.primary),
                                    items: branches.map((br) {
                                      return DropdownMenuItem(
                                          value: br.branchId, child: Text(br.branchName));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          targetBranchId = val;
                                          if (sourceBranchId == targetBranchId) {
                                            sourceBranchId = branches.firstWhere((b) => b.branchId != targetBranchId, orElse: () => branches.first).branchId;
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
                          'Tồn kho nguồn tại ${branches.firstWhere((b) => b.branchId == sourceBranchId, orElse: () => BranchDashboardItemModel(branchId: '', branchName: '', isActive: false, status: '', revenue: 0.0, orderCount: 0, completedOrders: 0, pendingOrders: 0, cancelledOrders: 0, averageOrderValue: 0.0, paidOrders: 0, paymentBreakdown: PaymentBreakdownModel(cash: 0.0, payOS: 0.0))).branchName}: ',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${sourceStock.toStringAsFixed(1)} ${selectedIngredientItem.unit.isNotEmpty ? selectedIngredientItem.unit : 'đơn vị'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sourceStock <=
                                    _getSafeThreshold(selectedIngredientName)
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. Input quantity with explicit Unit label & suffix
                    Text(
                      'Số lượng điều phối (${selectedIngredientItem.unit.isNotEmpty ? selectedIngredientItem.unit : 'đơn vị'}) *',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
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
                        hintText: 'Nhập số lượng chuyển...',
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: selectedIngredientItem.unit.isNotEmpty
                            ? selectedIngredientItem.unit
                            : null,
                        suffixStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (sourceBranchId == targetBranchId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chi nhánh nguồn và chi nhánh đích không được giống nhau! Vui lòng chọn 2 chi nhánh khác nhau.',
                                ),
                              ),
                            );
                            return;
                          }

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
                                      'Không đủ tồn kho nguồn để thực hiện! Tối đa: ${sourceStock.toStringAsFixed(1)} ${selectedIngredientItem.unit.isNotEmpty ? selectedIngredientItem.unit : 'đơn vị'}.')),
                            );
                            return;
                          }

                          // Capture root navigator reference before closing sheet
                          final rootNav = Navigator.of(context, rootNavigator: true);
                          Navigator.pop(ctx);

                          if (!mounted) return;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );

                          final targetIngId = sourceItem.ingredientId.isEmpty ? selectedIngredientItem.ingredientId : sourceItem.ingredientId;
                          try {
                            final ticket = await ref.read(analyticsRepositoryProvider).createDirectTransfer(
                              ingredientId: targetIngId,
                              sourceBranchId: sourceBranchId,
                              targetBranchId: targetBranchId,
                              quantity: transferQty,
                              note: 'Điều phối chủ động từ Tổng quản trị',
                            );
                            
                            try {
                              rootNav.pop(); // Close loading dialog
                            } catch (_) {}

                            for (final b in branches) {
                              ref.invalidate(branchInventoriesProvider(b.branchId));
                            }
                            ref.invalidate(transferTicketsProvider(TransferTicketParams()));
                            
                            _showTransferSuccessDialog(
                              selectedIngredientName,
                              branches.firstWhere((b) => b.branchId == sourceBranchId).branchName,
                              branches.firstWhere((b) => b.branchId == targetBranchId).branchName,
                              transferQty,
                              ticket.ticketCode,
                            );
                          } catch (err) {
                            try {
                              rootNav.pop(); // Close loading dialog
                            } catch (_) {}
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi vận chuyển: $err')),
                              );
                            }
                          }
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
      String ing, String src, String dst, double qty, [String? ticketCode]) {
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
              child: const Icon(Icons.local_shipping_rounded,
                  size: 30, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Khởi tạo lệnh xuất kho!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã tạo thành công lệnh điều phối ${ticketCode != null ? "#$ticketCode" : ""}.\nXuất ${qty.toStringAsFixed(1)}kg $ing từ chi nhánh "$src" gửi sang "$dst".\n\nTồn kho chi nhánh nguồn đã xuất kho. Tồn kho chi nhánh đích sẽ tự động cập nhật khi quản lý chi nhánh bấm "Xác nhận nhận hàng".',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
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
    final dashboardAsync = ref.watch(brandDashboardFutureProvider(_currentDateRange));
    final List<BranchDashboardItemModel> branchesList = dashboardAsync.value?.branches ?? [];
    final Map<String, List<BranchInventoryItem>> branchInventories = {};
    for (var branch in branchesList) {
      final invAsync = ref.watch(branchInventoriesProvider(branch.branchId));
      if (invAsync.hasValue) {
        branchInventories[branch.branchId] = invAsync.value!;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Sleek Gradient Header Section (Fixed at top)
            _buildHeader(displayName, initialChar, user?.role),

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
                        child: dashboardAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          ),
                          error: (err, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lỗi tải dữ liệu: $err',
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => ref.invalidate(brandDashboardFutureProvider(_currentDateRange)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                    ),
                                    child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          data: (dashboardData) {
                            _currentApiData = dashboardData;
                            // Ensure selected branch filter is valid or reset to all
                            if (_selectedBranchFilter != 'Tất cả chi nhánh' &&
                                !_branchRevenues.containsKey(_selectedBranchFilter)) {
                              _selectedBranchFilter = 'Tất cả chi nhánh';
                            }
                            return _buildSelectedTabContent(branchesList, branchInventories);
                          },
                        ),
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
  Widget _buildHeader(String displayName, String initialChar, String? role) {
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
                    Text(
                      role?.toLowerCase() == 'superadmin'
                          ? 'DineX System · Tổng quản trị'
                          : 'DineX System · Chủ thương hiệu',
                      style: const TextStyle(
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
    final revenueText = FormatUtils.formatCurrency(_currentFilteredRevenue);
    final String compareText = 'Doanh thu tổng hợp theo: $_selectedTimeFilter';

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng doanh thu chuỗi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
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
    final summary = _currentApiData?.summary;
    final int ordersCount = summary != null ? summary.completedOrders : 0;
    final double avgOrderVal = summary != null ? summary.averageOrderValue : 0.0;
    final double totalRevenue = summary != null ? summary.revenue : _currentFilteredRevenue;
    final int activeBranches = summary != null ? summary.activeBranches : _activeBranchesCount;

    final formattedOrders = ordersCount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    final avgBillStr = FormatUtils.formatCurrency(avgOrderVal);
    final grossProfitStr = FormatUtils.formatCurrency(totalRevenue * 0.65);

    return Column(
      children: [
        _buildKPITile(
          title: 'Chi nhánh hoạt động',
          value: '$activeBranches / $activeBranches tốt',
          icon: Icons.store_rounded,
          iconBg: AppColors.successContainer,
          iconColor: AppColors.success,
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Lợi nhuận gộp ước tính',
          value: grossProfitStr,
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
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Giá trị trung bình bill',
          value: avgBillStr,
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
                'Tổng chuỗi: ${FormatUtils.formatCurrency(_totalRevenue)}',
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
                              FormatUtils.formatCompactAmount(entry.value),
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
                    list.isNotEmpty && _selectedChartBarIndex < list.length
                        ? 'Chi nhánh ${list[_selectedChartBarIndex].key} dẫn đầu doanh thu với ${FormatUtils.formatCurrency(list[_selectedChartBarIndex].value)}.'
                        : 'Không có dữ liệu so sánh doanh thu chi nhánh.',
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

    Widget _buildStockAlertsGrid(
    List<BranchDashboardItemModel> branches,
    Map<String, List<BranchInventoryItem>> branchInventories,
  ) {
    final Set<String> ingredientNames = {};
    for (var list in branchInventories.values) {
      for (var item in list) {
        ingredientNames.add(item.ingredientName);
      }
    }

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

          if (ingredientNames.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'Không có nguyên liệu nào trong kho.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...ingredientNames.map((ing) {
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
                          onTap: () => _openTransferBottomSheet(ing, branches, branchInventories),
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: branches.map((branch) {
                        final branchItems = branchInventories[branch.branchId] ?? [];
                        final item = branchItems.firstWhere(
                          (e) => e.ingredientName == ing,
                          orElse: () => BranchInventoryItem(
                            id: '',
                            branchId: branch.branchId,
                            branchName: branch.branchName,
                            ingredientId: '',
                            ingredientName: ing,
                            unit: 'kg',
                            currentStock: 0.0,
                            minStockLevel: 0.0,
                          ),
                        );
                        
                        final double qty = item.currentStock;
                        final double minLevel = item.minStockLevel > 0 ? item.minStockLevel : threshold;
                        final isLow = qty < minLevel;

                        final sameNameBranches = branches.where((b) => b.branchName == branch.branchName).toList();
                        String branchDisplayName = branch.branchName;
                        if (sameNameBranches.length > 1) {
                          final idx = sameNameBranches.indexOf(branch) + 1;
                          branchDisplayName = '${branch.branchName} (#$idx)';
                        }

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
                                  branchDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${qty.toStringAsFixed(1)} ${item.unit}',
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

  void _openApproveTicketBottomSheet(BuildContext pageContext, WidgetRef ref, TransferTicketModel ticket, List<BranchDashboardItemModel> branches) {
    final availableSources = branches.where((b) => b.branchId != ticket.targetBranchId).toList();
    if (availableSources.isEmpty) {
      ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('Không tìm thấy chi nhánh nguồn thích hợp')));
      return;
    }

    String selectedSourceId = availableSources.first.branchId;

    showModalBottomSheet(
      context: pageContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Duyệt Yêu Cầu #${ticket.ticketCode}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('Nguyên liệu: ${ticket.quantity.toStringAsFixed(1)}${ticket.unit} ${ticket.ingredientName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('Chi nhánh yêu cầu: ${ticket.targetBranchName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  const Text('Chọn Chi nhánh Xuất Kho (Nguồn) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSourceId,
                        isExpanded: true,
                        items: availableSources.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.branchId,
                            child: Text(b.branchName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedSourceId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final rootNav = Navigator.of(pageContext, rootNavigator: true);
                        Navigator.pop(ctx); // Close sheet

                        if (!pageContext.mounted) return;

                        showDialog(
                          context: pageContext,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );

                        try {
                          await ref.read(analyticsRepositoryProvider).approveTransferTicket(
                            ticketId: ticket.id,
                            sourceBranchId: selectedSourceId,
                          );
                          try {
                            rootNav.pop(); // Close loading
                          } catch (_) {}
                          for (final b in branches) {
                            ref.invalidate(branchInventoriesProvider(b.branchId));
                          }
                          ref.invalidate(transferTicketsProvider(TransferTicketParams()));
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              const SnackBar(content: Text('Đã duyệt và xuất kho thành công! Chờ chi nhánh đích nhận hàng.')),
                            );
                          }
                        } catch (e) {
                          try {
                            rootNav.pop(); // Close loading
                          } catch (_) {}
                          if (pageContext.mounted) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(content: Text('Lỗi duyệt yêu cầu: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Phê Duyệt & Xuất Kho', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Best/Worst Sellers UI ─────────────────────────────────────────────
  Widget _buildDishPopularitySection() {
    final menuPerfAsync = ref.watch(menuPerformanceProvider(
      BranchAnalyticsParams(branchId: '', dateRange: _currentDateRange),
    ));

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
      child: menuPerfAsync.when(
        data: (perf) {
          final topSelling = perf.topSellingItems;
          final sortedByQty = List<MenuPerformanceItemModel>.from(topSelling)
            ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

          final bestSellers = sortedByQty.take(3).toList();
          final worstSellers = sortedByQty.length > 3
              ? sortedByQty.reversed.take(3).toList()
              : <MenuPerformanceItemModel>[];

          final int totalQty = sortedByQty.fold(0, (sum, item) => sum + item.quantitySold);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân tích phổ biến món ăn chuỗi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
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
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (bestSellers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa có dữ liệu bán món trong khoảng thời gian này.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...bestSellers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final double pct = totalQty > 0 ? (item.quantitySold / totalQty) : 0.0;
                  final colors = [AppColors.primary, AppColors.secondary, AppColors.accent];
                  final color = colors[idx % colors.length];

                  return _buildPopularItemBar(
                    item.name,
                    pct > 1.0 ? 1.0 : pct,
                    '${(pct * 100).toStringAsFixed(0)}% (${item.quantitySold} phần)',
                    color,
                  );
                }),

              if (worstSellers.isNotEmpty) ...[
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
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...worstSellers.map((item) {
                  final double pct = totalQty > 0 ? (item.quantitySold / totalQty) : 0.0;
                  return _buildPopularItemBar(
                    item.name,
                    pct > 1.0 ? 1.0 : (pct < 0.05 ? 0.05 : pct),
                    '${(pct * 100).toStringAsFixed(1)}% (${item.quantitySold} phần)',
                    const Color(0xFF90A4AE),
                  );
                }),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, _) => Text(
          'Lỗi tải phân tích món ăn: $err',
          style: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
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

  Widget _buildSelectedTabContent(
    List<BranchDashboardItemModel> branches,
    Map<String, List<BranchInventoryItem>> branchInventories,
  ) {
    switch (_selectedTabIdx) {
      case 1:
        return _buildInventoryTab(branches, branchInventories);
      case 2:
        return _buildOperationsTab(branches);
      case 0:
      default:
        return _buildFinancialTab(branches);
    }
  }

  Widget _buildFinancialTab(List<BranchDashboardItemModel> branches) {
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
          _buildBranchRevenueBreakdownList(branches),
          const SizedBox(height: 16),
        ],
        _buildConsolidatedPayments(branches),
        const SizedBox(height: 16),
        _buildConsolidatedOrderSources(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBranchRevenueBreakdownList(List<BranchDashboardItemModel> branches) {
    if (branches.isEmpty) return const SizedBox.shrink();

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
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Doanh thu từng chi nhánh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${branches.length} chi nhánh',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...branches.map((branch) {
            final revenueStr = FormatUtils.formatCurrency(branch.revenue);
            final avgOrderValStr = FormatUtils.formatCurrency(branch.averageOrderValue);
            final cashValStr = FormatUtils.formatCurrency(branch.paymentBreakdown.cash);
            final payOsValStr = FormatUtils.formatCurrency(branch.paymentBreakdown.payOS);

            final int displayOrders = branch.paidOrders > 0 ? branch.paidOrders : branch.completedOrders;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                branch.branchName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        revenueStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBranchMetricItem('Số đơn', '$displayOrders đơn'),
                      _buildBranchMetricItem('TB/Đơn', avgOrderValStr),
                      _buildBranchMetricItem('Tiền mặt', cashValStr),
                      _buildBranchMetricItem('PayOS', payOsValStr),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBranchMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildConsolidatedPayments(List<BranchDashboardItemModel> branches) {
    double totalCash = 0.0;
    double totalPayOS = 0.0;
    double totalRevenue = 0.0;

    for (var b in branches) {
      totalCash += b.paymentBreakdown.cash;
      totalPayOS += b.paymentBreakdown.payOS;
      totalRevenue += b.revenue;
    }

    if (totalRevenue == 0.0) {
      totalRevenue = totalCash + totalPayOS;
    }

    final double payOSPct = totalRevenue > 0 ? (totalPayOS / totalRevenue).clamp(0.0, 1.0) : 0.0;
    final double cashPct = totalRevenue > 0 ? (totalCash / totalRevenue).clamp(0.0, 1.0) : 0.0;

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
            'Chuyển khoản (PayOS / QR)',
            payOSPct,
            AppColors.secondary,
            '${(payOSPct * 100).toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _buildPaymentRow(
            'Tiền mặt',
            cashPct,
            AppColors.primary,
            '${(cashPct * 100).toStringAsFixed(1)}%',
          ),
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

  Widget _buildInventoryTab(
    List<BranchDashboardItemModel> branches,
    Map<String, List<BranchInventoryItem>> branchInventories,
  ) {
    return Column(
      key: const ValueKey('inventory_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStockAlertsGrid(branches, branchInventories),
        const SizedBox(height: 16),
        _buildSupplyChainTracker(branches),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSupplyChainTracker(List<BranchDashboardItemModel> branches) {
    final ticketsAsync = ref.watch(transferTicketsProvider(TransferTicketParams()));

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
      child: ticketsAsync.when(
        data: (tickets) {
          final activeCount = tickets.where((t) => t.status == 'Dispatched' || t.status == 'Pending').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Logistics & Bếp trung tâm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$activeCount phiếu đang chạy',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tickets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Chưa có phiếu vận chuyển hoặc điều phối nào.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...tickets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ticket = entry.value;
                  final isPending = ticket.status == 'Pending';
                  final isDispatched = ticket.status == 'Dispatched';
                  final isCompleted = ticket.status == 'Completed';
                  final isRejected = ticket.status == 'Rejected';

                  Color statusColor = AppColors.accent;
                  String statusText = 'Chờ duyệt';
                  if (isDispatched) {
                    statusColor = AppColors.primary;
                    statusText = 'Đang vận chuyển';
                  } else if (isCompleted) {
                    statusColor = AppColors.success;
                    statusText = 'Hoàn thành';
                  } else if (isRejected) {
                    statusColor = AppColors.error;
                    statusText = 'Đã từ chối';
                  }

                  final srcName = ticket.sourceBranchName ?? 'Bếp trung tâm';
                  final dstName = ticket.targetBranchName;

                  String timeText = '';
                  if (isCompleted) {
                    timeText = 'Hoàn tất giao hàng';
                  } else if (isDispatched) {
                    timeText = 'Đang vận chuyển';
                  } else if (isPending) {
                    timeText = 'Chờ tổng quản duyệt';
                  }

                  return Column(
                    children: [
                      if (index > 0) const Divider(color: AppColors.divider, height: 20),
                      _buildLogisticsItem(
                        ticket: ticket,
                        code: ticket.ticketCode.length > 20
                            ? '#${ticket.ticketCode.substring(0, 18)}...'
                            : '#${ticket.ticketCode}',
                        route: '$srcName ➔ $dstName',
                        status: statusText,
                        statusColor: statusColor,
                        time: timeText,
                        itemCount: '${ticket.quantity.toStringAsFixed(1)}${ticket.unit} ${ticket.ingredientName}${ticket.note != null && ticket.note!.isNotEmpty ? ' (${ticket.note})' : ''}',
                        branches: branches,
                      ),
                    ],
                  );
                }),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (err, _) => Text(
          'Lỗi tải dữ liệu logistics: $err',
          style: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLogisticsItem({
    required TransferTicketModel ticket,
    required String code,
    required String route,
    required String status,
    required Color statusColor,
    required String time,
    required String itemCount,
    required List<BranchDashboardItemModel> branches,
  }) {
    final isPending = ticket.status == 'Pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                itemCount,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (time.isNotEmpty)
              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        if (isPending) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () async {
                  try {
                    await ref.read(analyticsRepositoryProvider).rejectTransferTicket(ticketId: ticket.id);
                    for (final b in branches) {
                      ref.invalidate(branchInventoriesProvider(b.branchId));
                    }
                    ref.invalidate(transferTicketsProvider(TransferTicketParams()));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã từ chối yêu cầu điều phối.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Từ chối', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _openApproveTicketBottomSheet(context, ref, ticket, branches);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Duyệt & Chọn Kho Nguồn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOperationsTab(List<BranchDashboardItemModel> branches) {
    return Column(
      key: const ValueKey('operations_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDishPopularitySection(),
        const SizedBox(height: 16),
        _buildBranchSpeedComparison(branches),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBranchSpeedComparison(List<BranchDashboardItemModel> branches) {
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

          if (branches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Không có dữ liệu chi nhánh.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            )
          else
            ...branches.asMap().entries.map((entry) {
              final idx = entry.key;
              final branch = entry.value;

              final opsAsync = ref.watch(operationsAnalyticsProvider(
                BranchAnalyticsParams(branchId: branch.branchId, dateRange: _currentDateRange),
              ));

              return opsAsync.when(
                data: (ops) {
                  final double prepMinutes = ops.summary.averagePreparationMinutes ?? 12.0;
                  final double cancelRate = ops.summary.cancellationRate;
                  final colors = [AppColors.success, AppColors.primary, AppColors.accent, AppColors.secondary];
                  final color = colors[idx % colors.length];
                  final progressVal = (prepMinutes / 30.0).clamp(0.1, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildSpeedRow(
                      branch.branchName,
                      '${prepMinutes.toStringAsFixed(1)} phút',
                      progressVal,
                      color,
                      'Tỷ lệ hủy: ${cancelRate.toStringAsFixed(1)}% (${ops.summary.totalOrders} đơn)',
                    ),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(branch.branchName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    ],
                  ),
                ),
                error: (err, _) {
                  final double cancelRate = branch.orderCount > 0
                      ? (branch.cancelledOrders / branch.orderCount * 100)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildSpeedRow(
                      branch.branchName,
                      '12.0 phút',
                      0.5,
                      AppColors.primary,
                      'Tỷ lệ hủy: ${cancelRate.toStringAsFixed(1)}%',
                    ),
                  );
                },
              );
            }),
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

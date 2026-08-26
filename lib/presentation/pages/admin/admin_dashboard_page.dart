import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/analytics_model.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/utils/format_utils.dart';
import 'all_transactions_page.dart';

/// Admin Dashboard Page - Mobile layout with premium charts, metrics, and transaction details.
/// Follows RULE: UI-only widgets, AppColors 100%, high visual aesthetics.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  String _selectedTimeFilter = 'Hôm nay'; // 'Hôm nay' | 'Tuần này' | 'Tháng này' | 'Tùy chọn'
  int _selectedTabIdx = 0; // 0: Tài chính, 1: Thực đơn, 2: Vận hành, 3: Hao hụt kho
  int _selectedChartBarIndex = 0;
  int? _expandedTransactionIndex;
  DateTimeRange? _selectedDateRange;
  String? _selectedBranchId;



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

  Map<String, dynamic> _getCombinedFinancialData({
    required double revenue,
    required double totalDiscount,
    required double foodCost,
    required double grossMargin,
    required double wastageCost,
    required double netProfit,
    required double grossMarginPercentage,
    required double netProfitPercentage,
    required bool isProfitable,
    required int orderCount,
    required int cancelledOrders,
    required double cashVal,
    required double payOsVal,
    required List<OrderSourceBreakdownModel> orderSources,
  }) {
    final totalPayment = cashVal + payOsVal;
    final cashPct = totalPayment > 0 ? (cashVal / totalPayment) : 0.0;
    final payOsPct = totalPayment > 0 ? (payOsVal / totalPayment) : 0.0;

    final grossSales = revenue + totalDiscount;
    final netSalesStr = FormatUtils.formatCurrency(revenue);
    final grossSalesStr = FormatUtils.formatCurrency(grossSales);
    final discountsStr = FormatUtils.formatCurrency(totalDiscount);
    final foodCostStr = FormatUtils.formatCurrency(foodCost);
    final grossMarginStr = FormatUtils.formatCurrency(grossMargin);
    final wastageCostStr = FormatUtils.formatCurrency(wastageCost);
    final netProfitStr = FormatUtils.formatCurrency(netProfit);

    final foodCostPct = revenue > 0 ? (foodCost / revenue * 100).toStringAsFixed(1) : '0.0';
    final grossMarginPct = revenue > 0 ? (grossMargin / revenue * 100).toStringAsFixed(1) : '0.0';
    final netProfitPct = revenue > 0 ? (netProfit / revenue * 100).toStringAsFixed(1) : '0.0';

    final List<Map<String, dynamic>> updatedPaymentBreakdown = [
      {
        'method': 'Tiền mặt',
        'percentage': cashPct,
        'value': FormatUtils.formatCurrency(cashVal),
      },
      {
        'method': 'Chuyển khoản PayOS',
        'percentage': payOsPct,
        'value': FormatUtils.formatCurrency(payOsVal),
      },
      {
        'method': 'Ví điện tử',
        'percentage': 0.0,
        'value': '0đ',
      }
    ];

    List<Map<String, dynamic>> updatedOrderSources = orderSources.map((item) {
      return {
        'source': item.source,
        'percentage': item.percentage,
        'value': FormatUtils.formatCurrency(item.value),
      };
    }).toList();

    if (updatedOrderSources.isEmpty) {
      updatedOrderSources = [
        {
          'source': 'Tại bàn',
          'percentage': 0.0,
          'value': '0đ',
        },
        {
          'source': 'Đặt trực tuyến',
          'percentage': 0.0,
          'value': '0đ',
        },
        {
          'source': 'Mang đi / Giao hàng',
          'percentage': 0.0,
          'value': '0đ',
        },
      ];
    }

    return {
      'netSales': netSalesStr,
      'grossSales': grossSalesStr,
      'discounts': discountsStr,
      'foodCost': foodCostStr,
      'foodCostPct': '$foodCostPct%',
      'grossMargin': grossMarginStr,
      'grossMarginPct': '$grossMarginPct%',
      'wastageCost': wastageCostStr,
      'netProfit': netProfitStr,
      'netProfitRaw': netProfit,
      'netProfitPct': '$netProfitPct%',
      'isProfitable': isProfitable,
      'revenueRaw': revenue,
      'paymentBreakdown': updatedPaymentBreakdown,
      'orderSources': updatedOrderSources,
      'cancellationRate': orderCount > 0 
          ? '${(cancelledOrders / orderCount * 100).toStringAsFixed(1)}%'
          : '0.0%',
    };
  }

  Map<String, dynamic> _getCombinedMenuData(MenuPerformanceModel menuData) {
    // Convert categories
    final double totalCategoryRevenue = menuData.categoryPerformance.fold(0.0, (sum, item) => sum + item.revenue);
    final List<Map<String, dynamic>> updatedCategories = menuData.categoryPerformance.map((item) {
      final double pct = totalCategoryRevenue > 0 ? (item.revenue / totalCategoryRevenue) : 0.0;
      return {
        'name': item.categoryName ?? 'Khác',
        'percentage': pct,
        'value': FormatUtils.formatCurrency(item.revenue),
      };
    }).toList();

    // Convert topItems
    final List<Map<String, dynamic>> updatedTopItems = menuData.topSellingItems.map((item) {
      return {
        'name': item.name,
        'qty': item.quantitySold,
        'revenue': FormatUtils.formatCurrency(item.revenue),
      };
    }).toList();

    // Convert topToppings
    final List<Map<String, dynamic>> updatedTopToppings = menuData.topToppings.map((item) {
      return {
        'name': item.name,
        'qty': item.quantitySold,
        'revenue': FormatUtils.formatCurrency(item.revenue),
      };
    }).toList();

    return {
      'categories': updatedCategories,
      'topItems': updatedTopItems,
      'topToppings': updatedTopToppings,
    };
  }

  Map<String, dynamic> _getCombinedOperationsData(OperationsAnalyticsModel opsData) {
    final summary = opsData.summary;

    final double prepTime = summary.averagePreparationMinutes ?? 0.0;
    final String avgPrepTimeStr = '${prepTime.toStringAsFixed(1)} phút';

    final String cancellationRateStr = '${summary.cancellationRate.toStringAsFixed(1)}%';

    List<Map<String, dynamic>> updatedPeakHours = opsData.peakHours.map((ph) {
      final nextHour = (ph.hour + 1) % 24;
      return {
        'hour': '${ph.hour}h - ${nextHour}h',
        'value': ph.revenue / 1000000.0,
      };
    }).toList();

    return {
      'avgPrepTime': avgPrepTimeStr,
      'cancellationRate': cancellationRateStr,
      'peakHours': updatedPeakHours,
    };
  }

  Map<String, dynamic> _getCombinedWastageData(InventoryWastageAnalyticsModel wastageData) {
    final summary = wastageData.summary;

    final double totalWastageVal = summary.wasteValue ?? 0.0;
    final String wastageValueStr = FormatUtils.formatCurrency(totalWastageVal);

    // Map transactionBreakdown to wastageReasons
    List<Map<String, dynamic>> updatedWastageReasons = wastageData.transactionBreakdown.map((item) {
      final double itemVal = item.value ?? 0.0;
      final double pct = totalWastageVal > 0 ? (itemVal / totalWastageVal) : 0.0;
      
      String translatedReason = item.type;
      if (item.type == 'Wastage' || item.type == 'Waste') {
        translatedReason = 'Mất mát hao phí';
      } else if (item.type == 'Deduction') {
        translatedReason = 'Khấu trừ bếp';
      } else if (item.type == 'Adjustment') {
        translatedReason = 'Điều chỉnh kiểm kê';
      } else if (item.type == 'Import') {
        translatedReason = 'Nhập kho';
      } else if (item.type == 'Restore' || item.type == 'Reconciliation') {
        translatedReason = 'Hoàn kho / Nhận điều phối';
      } else if (item.type == 'Expired' || item.type == 'Spoiled') {
        translatedReason = 'Hết hạn / Hư hỏng';
      }

      return {
        'reason': translatedReason,
        'percentage': pct,
        'value': FormatUtils.formatCurrency(itemVal),
      };
    }).toList();

    if (updatedWastageReasons.isEmpty) {
      updatedWastageReasons = [
        {'reason': 'Nhập kho', 'percentage': 0.0, 'value': '0đ'},
        {'reason': 'Khấu trừ bếp', 'percentage': 0.0, 'value': '0đ'},
        {'reason': 'Hoàn kho / Nhận điều phối', 'percentage': 0.0, 'value': '0đ'},
        {'reason': 'Điều chỉnh kiểm kê', 'percentage': 0.0, 'value': '0đ'},
        {'reason': 'Mất mát hao phí', 'percentage': 0.0, 'value': '0đ'},
        {'reason': 'Hết hạn / Hư hỏng', 'percentage': 0.0, 'value': '0đ'},
      ];
    }

    // Map wastageItems to topWastedIngredients
    final List<Map<String, dynamic>> updatedTopWastedIngredients = wastageData.wastageItems.map((item) {
      final double itemVal = item.value ?? 0.0;
      return {
        'name': item.ingredientName,
        'qty': '${item.quantity.toStringAsFixed(1)} đơn vị',
        'value': FormatUtils.formatCurrency(itemVal),
      };
    }).toList();

    return {
      'wastageValue': wastageValueStr,
      'wastageReasons': updatedWastageReasons,
      'topWastedIngredients': updatedTopWastedIngredients,
    };
  }


  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorWidget(Object err, VoidCallback onRetry) {
    return Center(
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
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }



  // Dynamic Tab Title
  String get _selectedTabTitle {
    switch (_selectedTabIdx) {
      case 1:
        return 'Hiệu suất thực đơn';
      case 2:
        return 'Chỉ số vận hành';
      case 3:
        return 'Báo cáo hao hụt';
      case 0:
      default:
        return 'Tổng quan tài chính';
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
                color: AppColors.textPrimary,
              ),
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
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppConstants.routeProfile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  void _changeTimeFilter(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      _selectedChartBarIndex = 0; // Reset chart index on filter change
    });
    ref.invalidate(brandDashboardFutureProvider);
    ref.invalidate(branchDashboardDetailProvider);
    ref.invalidate(salesTrendProvider);
    ref.invalidate(menuPerformanceProvider);
    ref.invalidate(operationsAnalyticsProvider);
    ref.invalidate(inventoryWastageProvider);
    ref.invalidate(branchOrdersProvider);
  }

  Future<void> _selectCustomDateRange() async {
    final initialRange = _selectedDateRange ?? DateTimeRange(
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
        _selectedChartBarIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final rawName = user?.displayName;
    final displayName = (rawName == null || rawName.trim().isEmpty) ? 'Quản trị viên' : rawName;
    final initialChar = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'A';
    
    // Check if the user is a Brand Admin (doesn't have a fixed branchId)
    final isBrandAdmin = user?.branchId == null || user!.branchId!.isEmpty;
    final brandDashboardAsync = isBrandAdmin 
        ? ref.watch(brandDashboardFutureProvider(_currentDateRange))
        : null;

    String activeBranchId = '';
    List<BranchDashboardItemModel> availableBranches = [];

    if (!isBrandAdmin) {
      activeBranchId = user.branchId ?? '';
    } else {
      if (brandDashboardAsync != null) {
        final branchesList = brandDashboardAsync.value?.branches ?? [];
        availableBranches = branchesList;
        if (_selectedBranchId == null || _selectedBranchId == 'all') {
          activeBranchId = 'all';
        } else {
          final hasSelected = branchesList.any((b) => b.branchId == _selectedBranchId);
          activeBranchId = hasSelected ? _selectedBranchId! : 'all';
        }
      }
    }

    final params = BranchAnalyticsParams(
      branchId: activeBranchId,
      dateRange: _currentDateRange,
    );

    Widget tabContent;
    if (isBrandAdmin && brandDashboardAsync != null && brandDashboardAsync.isLoading && availableBranches.isEmpty) {
      tabContent = _buildLoadingWidget();
    } else if (isBrandAdmin && brandDashboardAsync != null && brandDashboardAsync.hasError && availableBranches.isEmpty) {
      tabContent = _buildErrorWidget(brandDashboardAsync.error!, () => ref.invalidate(brandDashboardFutureProvider(_currentDateRange)));
    } else if (!isBrandAdmin && activeBranchId.isEmpty) {
      tabContent = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'Không tìm thấy chi nhánh nào liên kết với tài khoản này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    } else {
      switch (_selectedTabIdx) {
        case 0:
          if (isBrandAdmin && activeBranchId == 'all') {
            if (brandDashboardAsync!.isLoading) {
              tabContent = _buildLoadingWidget();
            } else if (brandDashboardAsync.hasError) {
              tabContent = _buildErrorWidget(brandDashboardAsync.error!, () => ref.invalidate(brandDashboardFutureProvider(_currentDateRange)));
            } else if (brandDashboardAsync.value != null) {
              final brandData = brandDashboardAsync.value!;
              final trendAsync = ref.watch(salesTrendProvider(params));
              tabContent = trendAsync.when(
                loading: () => _buildLoadingWidget(),
                error: (err, stack) => _buildErrorWidget(err, () => ref.invalidate(salesTrendProvider(params))),
                data: (trendData) {
                  final summary = brandData.summary;
                  final totalCash = brandData.branches.fold(0.0, (sum, b) => sum + b.paymentBreakdown.cash);
                  final totalPayOs = brandData.branches.fold(0.0, (sum, b) => sum + b.paymentBreakdown.payOS);
                  final combinedData = _getCombinedFinancialData(
                    revenue: summary.revenue,
                    totalDiscount: summary.totalDiscount,
                    foodCost: summary.foodCost,
                    grossMargin: summary.grossMargin,
                    wastageCost: summary.wastageCost,
                    netProfit: summary.netProfit,
                    grossMarginPercentage: summary.grossMarginPercentage,
                    netProfitPercentage: summary.netProfitPercentage,
                    isProfitable: summary.isProfitable,
                    orderCount: summary.orderCount,
                    cancelledOrders: summary.cancelledOrders,
                    cashVal: totalCash,
                    payOsVal: totalPayOs,
                    orderSources: [],
                  );
                  return _buildFinancialTab(
                    data: combinedData,
                    trendData: trendData,
                    branches: brandData.branches,
                    isBrandView: true,
                  );
                },
              );
            } else {
              tabContent = const SizedBox.shrink();
            }
          } else {
            final detailAsync = ref.watch(branchDashboardDetailProvider(params));
            final trendAsync = ref.watch(salesTrendProvider(params));

            tabContent = detailAsync.when(
              loading: () => _buildLoadingWidget(),
              error: (err, stack) => _buildErrorWidget(err, () => ref.invalidate(branchDashboardDetailProvider(params))),
              data: (detailData) {
                return trendAsync.when(
                  loading: () => _buildLoadingWidget(),
                  error: (err, stack) => _buildErrorWidget(err, () => ref.invalidate(salesTrendProvider(params))),
                  data: (trendData) {
                    final summary = detailData.summary;
                    final combinedData = _getCombinedFinancialData(
                      revenue: summary.revenue,
                      totalDiscount: summary.totalDiscount,
                      foodCost: summary.foodCost,
                      grossMargin: summary.grossMargin,
                      wastageCost: summary.wastageCost,
                      netProfit: summary.netProfit,
                      grossMarginPercentage: summary.grossMarginPercentage,
                      netProfitPercentage: summary.netProfitPercentage,
                      isProfitable: summary.isProfitable,
                      orderCount: summary.orderCount,
                      cancelledOrders: summary.cancelledOrders,
                      cashVal: detailData.paymentBreakdown.cash,
                      payOsVal: detailData.paymentBreakdown.payOS,
                      orderSources: detailData.orderSources,
                    );
                    final ordersAsync = ref.watch(branchOrdersProvider(activeBranchId));
                    return _buildFinancialTab(
                      data: combinedData,
                      trendData: trendData,
                      ordersAsync: ordersAsync,
                      isBrandView: false,
                    );
                  },
                );
              },
            );
          }
          break;
        case 1:
          final menuAsync = ref.watch(menuPerformanceProvider(params));
          tabContent = menuAsync.when(
            loading: () => _buildLoadingWidget(),
            error: (err, stack) => _buildErrorWidget(err, () => ref.invalidate(menuPerformanceProvider(params))),
            data: (menuData) {
              final combinedData = _getCombinedMenuData(menuData);
              return _buildMenuPerformanceTab(combinedData, menuData);
            },
          );
          break;
        case 2:
          final opsAsync = ref.watch(operationsAnalyticsProvider(params));
          tabContent = opsAsync.when(
            loading: () => _buildLoadingWidget(),
            error: (err, stack) => _buildErrorWidget(err, () => ref.invalidate(operationsAnalyticsProvider(params))),
            data: (opsData) {
              final combinedData = _getCombinedOperationsData(opsData);
              return _buildOperationsTab(combinedData, opsData);
            },
          );
          break;
        case 3:
          final wastageAsync = ref.watch(inventoryWastageProvider(params));
          tabContent = wastageAsync.when(
            loading: () => _buildLoadingWidget(),
            error: (err, stack) => _buildErrorWidget(err, () => ref.invalidate(inventoryWastageProvider(params))),
            data: (wastageData) {
              final combinedData = _getCombinedWastageData(wastageData);
              return _buildWastageTab(combinedData, wastageData);
            },
          );
          break;
        default:
          tabContent = const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Sleek Gradient Header Section (Fixed at top)
            _buildHeader(displayName, initialChar),

            // 2. Scrollable Body
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(brandDashboardFutureProvider);
                  ref.invalidate(branchDashboardDetailProvider);
                  ref.invalidate(salesTrendProvider);
                  ref.invalidate(menuPerformanceProvider);
                  ref.invalidate(operationsAnalyticsProvider);
                  ref.invalidate(inventoryWastageProvider);
                  ref.invalidate(branchOrdersProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedTabTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isBrandAdmin && availableBranches.length > 1) ...[
                                  const SizedBox(width: 10),
                                  _buildBranchSelector(availableBranches, activeBranchId),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildTimeFilterChips(),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 5. Dynamic Tab View contents
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: tabContent,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Component Helpers ──────────────────────────────────────────────────

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
        child: Column(
          children: [
            Row(
              children: [
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
                        'DineX Dashboard · Quản trị',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                  onPressed: _confirmLogout,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSelector(List<BranchDashboardItemModel> branches, String activeBranchId) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeBranchId.isEmpty ? 'all' : activeBranchId,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 16),
          ),
          elevation: 2,
          isDense: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          borderRadius: BorderRadius.circular(8),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedBranchId = newValue;
              });
            }
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'all',
              child: Text('Tất cả chi nhánh'),
            ),
            ...branches.map<DropdownMenuItem<String>>((BranchDashboardItemModel branch) {
              return DropdownMenuItem<String>(
                value: branch.branchId,
                child: Text(branch.branchName),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterChips() {
    final bool isCustom = _selectedTimeFilter == 'Tùy chọn';
    final String customLabel = isCustom && _selectedDateRange != null
        ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
        : 'Chọn ngày';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...['Hôm nay', 'Tuần này', 'Tháng này'].map((filter) {
            final isSelected = _selectedTimeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ChoiceChip(
                label: Text(
                  filter.replaceAll(' ', '\u00A0'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (val) {
                  if (val) _changeTimeFilter(filter);
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                elevation: 0,
                pressElevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: 1,
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
                      fontSize: 10,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isCustom ? AppColors.primary : AppColors.divider,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final List<String> tabs = ['Tài chính', 'Thực đơn', 'Vận hành', 'Hao hụt kho'];
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
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
                  color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
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
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
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

  // ─── Financial Tab Widget ──────────────────────────────────────────────

  Widget _buildFinancialTab({
    required Map<String, dynamic> data, 
    required SalesTrendModel trendData,
    AsyncValue<List<MockOrder>>? ordersAsync,
    List<BranchDashboardItemModel>? branches,
    bool isBrandView = false,
  }) {
    final List<double> chartData = trendData.items.map((e) => e.revenue.toDouble()).toList();
    final List<String> labels = trendData.items.map((e) => e.label).toList();

    return Column(
      key: const ValueKey('financial_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sleek Gradient Net Sales & Profit Status Master Card
        _buildNetSalesOverview(data),
        const SizedBox(height: 18),

        // 2. Waterfall P&L Breakdown Card
        _buildWaterfallPLBreakdown(data),
        const SizedBox(height: 18),

        // 3. If Brand View: Branch Profitability & Performance Ranking Table
        if (isBrandView && branches != null && branches.isNotEmpty) ...[
          _buildBranchComparisonSection(branches),
          const SizedBox(height: 18),
        ],

        // 4. Interactive Revenue Trend Chart
        _buildTrendChart(chartData, labels),
        const SizedBox(height: 18),

        // 5. Payment Structure Breakdown
        _buildPaymentBreakdown(data['paymentBreakdown'] as List<dynamic>),
        const SizedBox(height: 18),

        // 6. Order Source Breakdown
        if (!isBrandView && (data['orderSources'] as List<dynamic>).isNotEmpty) ...[
          _buildOrderSourceBreakdown(data['orderSources'] as List<dynamic>),
          const SizedBox(height: 24),
        ],

        // 7. Transaction List Table
        if (!isBrandView && ordersAsync != null)
          _buildRecentTransactionsSection(ordersAsync),
      ],
    );
  }

  Widget _buildNetSalesOverview(Map<String, dynamic> data) {
    final double netProfitRaw = (data['netProfitRaw'] as num?)?.toDouble() ?? 0.0;
    final double revenueRaw = (data['revenueRaw'] as num?)?.toDouble() ?? 0.0;
    final String netProfitPct = data['netProfitPct'] as String? ?? '0.0%';

    String badgeLabel;
    IconData badgeIcon;
    if (netProfitRaw > 0) {
      badgeLabel = 'ĐANG LÃI $netProfitPct';
      badgeIcon = Icons.trending_up_rounded;
    } else if (netProfitRaw < 0) {
      badgeLabel = 'ĐANG LỖ $netProfitPct';
      badgeIcon = Icons.trending_down_rounded;
    } else {
      badgeLabel = revenueRaw > 0 ? 'HÒA VỐN 0.0%' : 'CHƯA CÓ ĐƠN';
      badgeIcon = Icons.trending_flat_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD84315),
            Color(0xFFFF6F00),
            Color(0xFFFF8F00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'DOANH THU THỰC TẾ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['netSales'] as String,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedTimeFilter == 'Hôm nay'
                ? 'Báo cáo doanh thu & kết quả kinh doanh hôm nay'
                : _selectedTimeFilter == 'Tuần này'
                    ? 'Báo cáo doanh thu & kết quả kinh doanh tuần này'
                    : _selectedTimeFilter == 'Tháng này'
                        ? 'Báo cáo doanh thu & kết quả kinh doanh tháng này'
                        : 'Báo cáo khoảng thời gian tùy chọn',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverviewMiniMetric(
                  label: 'Doanh thu gộp',
                  value: data['grossSales'] as String,
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                _buildOverviewMiniMetric(
                  label: 'Giá vốn nguyên liệu',
                  value: data['foodCost'] as String,
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                _buildOverviewMiniMetric(
                  label: 'Lợi nhuận ròng',
                  value: data['netProfit'] as String,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMiniMetric({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterfallPLBreakdown(Map<String, dynamic> data) {
    final double netProfitRaw = (data['netProfitRaw'] as num?)?.toDouble() ?? 0.0;
    final double revenueRaw = (data['revenueRaw'] as num?)?.toDouble() ?? 0.0;

    String statusLabel;
    Color statusBg;
    Color statusText;
    Color profitBoxBg;
    Color profitBoxBorder;
    Color profitBoxTextColor;
    Color profitBoxValueColor;

    if (netProfitRaw > 0) {
      statusLabel = 'Kinh doanh có lãi';
      statusBg = AppColors.badgeBestBg;
      statusText = AppColors.badgeBestText;
      profitBoxBg = const Color(0xFFE8F5E9);
      profitBoxBorder = const Color(0xFF81C784);
      profitBoxTextColor = const Color(0xFF2E7D32);
      profitBoxValueColor = const Color(0xFF1B5E20);
    } else if (netProfitRaw < 0) {
      statusLabel = 'Cảnh báo thâm hụt';
      statusBg = AppColors.badgeHotBg;
      statusText = AppColors.badgeHotText;
      profitBoxBg = const Color(0xFFFFEBEE);
      profitBoxBorder = const Color(0xFFE57373);
      profitBoxTextColor = const Color(0xFFC62828);
      profitBoxValueColor = const Color(0xFFB71C1C);
    } else {
      statusLabel = revenueRaw > 0 ? 'Hòa vốn' : 'Chưa có đơn';
      statusBg = const Color(0xFFFFF3E0);
      statusText = const Color(0xFFE65100);
      profitBoxBg = const Color(0xFFFFF8E1);
      profitBoxBorder = const Color(0xFFFFCC80);
      profitBoxTextColor = const Color(0xFFE65100);
      profitBoxValueColor = const Color(0xFFE65100);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Báo cáo Lãi / Lỗ kinh doanh',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPLRow(
            prefix: '(+)',
            title: 'Doanh thu gộp',
            subtitle: 'Tổng giá trị món ăn niêm yết',
            value: data['grossSales'] as String,
            color: AppColors.textPrimary,
          ),
          _buildPLDivider(),
          _buildPLRow(
            prefix: '(-)',
            title: 'Giảm giá khuyến mãi',
            subtitle: 'Chương trình ưu đãi giảm giá',
            value: '- ${data['discounts']}',
            color: const Color(0xFFE53935),
          ),
          _buildPLDivider(),
          _buildPLRow(
            prefix: '(=)',
            title: 'Doanh thu thực tế',
            subtitle: 'Thực thu từ khách hàng',
            value: data['netSales'] as String,
            color: const Color(0xFFD84315),
            isHighlighted: true,
          ),
          _buildPLDivider(),
          _buildPLRow(
            prefix: '(-)',
            title: 'Giá vốn nguyên liệu',
            subtitle: 'Chi phí định lượng nguyên vật liệu',
            value: '- ${data['foodCost']}',
            badgeText: data['foodCostPct'] as String,
            color: const Color(0xFFEF6C00),
          ),
          _buildPLDivider(),
          _buildPLRow(
            prefix: '(=)',
            title: 'Lợi nhuận gộp',
            subtitle: 'Doanh thu thực tế trừ giá vốn',
            value: data['grossMargin'] as String,
            badgeText: data['grossMarginPct'] as String,
            color: const Color(0xFF00897B),
          ),
          _buildPLDivider(),
          _buildPLRow(
            prefix: '(-)',
            title: 'Chi phí hao hụt kho',
            subtitle: 'Hao hụt, hư hỏng hoặc hết hạn',
            value: '- ${data['wastageCost']}',
            color: const Color(0xFFC2185B),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: profitBoxBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: profitBoxBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LỢI NHUẬN RÒNG THỰC TẾ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: profitBoxTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        netProfitRaw > 0
                            ? 'Biên lợi nhuận ròng: ${data['netProfitPct']}'
                            : netProfitRaw < 0
                                ? 'Tỷ lệ lỗ vốn: ${data['netProfitPct']}'
                                : 'Hòa vốn kinh doanh',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: profitBoxTextColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data['netProfit'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: profitBoxValueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPLRow({
    required String prefix,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    String? badgeText,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                prefix,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                    color: isHighlighted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 13 : 12,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPLDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(color: AppColors.divider, height: 1),
    );
  }

  Widget _buildBranchComparisonSection(List<BranchDashboardItemModel> branches) {
    if (branches.isEmpty) return const SizedBox.shrink();

    // Sort by Net Profit descending
    final sortedBranches = List<BranchDashboardItemModel>.from(branches)
      ..sort((a, b) => b.netProfit.compareTo(a.netProfit));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                'Hiệu quả Lãi/Lỗ giữa các chi nhánh',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${branches.length} chi nhánh',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sortedBranches.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            final isProfitable = b.isProfitable;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedBranchId = b.branchId;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isProfitable
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? Colors.amber.shade100
                            : idx == 1
                                ? Colors.grey.shade200
                                : AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: idx == 0 ? Colors.amber.shade900 : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.branchName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Doanh thu: ${FormatUtils.formatCurrency(b.revenue)} · ${b.completedOrders} đơn',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FormatUtils.formatCurrency(b.netProfit),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isProfitable ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isProfitable ? AppColors.badgeBestBg : AppColors.badgeHotBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isProfitable
                                ? 'Lãi ${b.netProfitPercentage.toStringAsFixed(1)}%'
                                : 'Lỗ ${b.netProfitPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isProfitable ? AppColors.badgeBestText : AppColors.badgeHotText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatLabel(String label) {
    if (label.length >= 10 && label.contains('-')) {
      try {
        final date = DateTime.parse(label);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      } catch (_) {
        final parts = label.split('-');
        if (parts.length >= 3) {
          return '${parts[2]}/${parts[1]}';
        }
      }
    }
    return label;
  }

  Widget _buildTrendChart(List<double> chartData, List<String> labels) {
    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }
    final double maxVal = chartData.reduce((a, b) => a > b ? a : b);

    if (_selectedChartBarIndex >= chartData.length) {
      _selectedChartBarIndex = 0;
    }

    final isScrollable = chartData.length > 7;

    Widget chartRow = Row(
      mainAxisAlignment: isScrollable ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(chartData.length, (idx) {
        final double val = chartData[idx];
        final double ratio = maxVal > 0 ? val / maxVal : 0;
        final bool isSelected = _selectedChartBarIndex == idx;
        final formattedLabel = _formatLabel(labels[idx]);

        final barWidget = GestureDetector(
          onTap: () => setState(() => _selectedChartBarIndex = idx),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    FormatUtils.formatCompactAmount(val),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 80 * ratio,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [AppColors.primary, AppColors.secondary]
                        : [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.secondary.withValues(alpha: 0.15)
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );

        if (isScrollable) {
          return SizedBox(
            width: 48,
            child: barWidget,
          );
        } else {
          return Expanded(
            child: barWidget,
          );
        }
      }),
    );

    if (isScrollable) {
      chartRow = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: chartRow,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                'Biểu đồ xu hướng doanh số',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Chi tiết điểm chạm',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: chartRow,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chartData.isEmpty || _selectedChartBarIndex >= chartData.length
                      ? 'Không có dữ liệu xu hướng'
                      : _selectedTimeFilter == 'Hôm nay'
                          ? 'Khoảng thời gian ${labels[_selectedChartBarIndex]} đạt ${FormatUtils.formatCurrency(chartData[_selectedChartBarIndex])}'
                          : 'Ngày ${labels[_selectedChartBarIndex]} đạt ${FormatUtils.formatCurrency(chartData[_selectedChartBarIndex])}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(List<dynamic> paymentList) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu thanh toán',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...paymentList.map((item) {
            final double pct = item['percentage'] as double;
            final String pctText = '${(pct * 100).toStringAsFixed(0)}%';
            Color barColor = AppColors.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['method'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${item['value']} ($pctText)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderSourceBreakdown(List<dynamic> sourcesList) {
    final List<dynamic> effectiveSources = sourcesList.isNotEmpty
        ? sourcesList
        : [
            {
              'source': 'Tại bàn (Kiosk/POS)',
              'percentage': 0.0,
              'value': '0đ',
            },
            {
              'source': 'Đặt trực tuyến (App/Web)',
              'percentage': 0.0,
              'value': '0đ',
            },
            {
              'source': 'Mang đi / Giao hàng',
              'percentage': 0.0,
              'value': '0đ',
            },
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ cấu nguồn đơn hàng',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...effectiveSources.map((item) {
            final double pct = item['percentage'] as double;
            final String pctText = '${(pct * 100).toStringAsFixed(0)}%';
            Color barColor = AppColors.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['source'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${item['value']} ($pctText)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Menu Performance Tab Widget ────────────────────────────────────────

  Widget _buildMenuPerformanceTab(Map<String, dynamic> data, MenuPerformanceModel apiData) {
    final List<dynamic> categories = data['categories'] as List<dynamic>;
    final List<dynamic> topItems = data['topItems'] as List<dynamic>;
    final List<dynamic> topToppings = data['topToppings'] as List<dynamic>;

    return Column(
      key: const ValueKey('menu_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Category Share
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Doanh số theo danh mục',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chưa có dữ liệu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            '0đ (0%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: 0,
                          minHeight: 5,
                          backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.outline),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...categories.map((item) {
                  final double pct = item['percentage'] as double;
                  final String pctText = '${(pct * 100).toStringAsFixed(0)}%';
                  Color barColor = AppColors.primary;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${item['value']} ($pctText)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Top 5 Best Sellers
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top 5 món bán chạy nhất',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (topItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Chưa có dữ liệu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '0 món',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: 0,
                                minHeight: 4,
                                backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.outline),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Doanh thu: 0đ',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(topItems.length, (index) {
                  final item = topItems[index];
                  final maxQty = topItems.first['qty'] as int;
                  final double pct = (item['qty'] as int) / maxQty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? AppColors.primary
                                : index == 1
                                    ? AppColors.secondary
                                    : AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: index < 2 ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${item['qty']} món',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 4,
                                  backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    index == 0 ? AppColors.primary : AppColors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Doanh thu: ${item['revenue']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Top Toppings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top topping bán kèm nhiều nhất',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (topToppings.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: AppColors.textTertiary, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Chưa có dữ liệu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'x0 (0đ)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...topToppings.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'x${item['qty']} (${item['revenue']})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Operations Tab Widget ─────────────────────────────────────────────

  Widget _buildOperationsTab(Map<String, dynamic> data, OperationsAnalyticsModel apiData) {
    final List<dynamic> peakHours = data['peakHours'] as List<dynamic>;
    final String avgPrepTime = data['avgPrepTime'] as String;
    final String cancellationRate = data['cancellationRate'] as String;

    return Column(
      key: const ValueKey('operations_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Operation Metrics Cards
        Row(
          children: [
            Expanded(
              child: _buildOperationMetricCard(
                title: 'Chuẩn bị món TB',
                value: avgPrepTime,
                icon: Icons.timer_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOperationMetricCard(
                title: 'Tỷ lệ hủy đơn',
                value: cancellationRate,
                icon: Icons.cancel_presentation_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Peak Hours Bar Chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khung giờ cao điểm trong ngày',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final bool isScrollable = peakHours.length > 5;
                  Widget chartRow = Row(
                    mainAxisAlignment: isScrollable ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: peakHours.map((item) {
                      final double val = item['value'] as double;
                      final double maxVal = peakHours.isEmpty ? 1.0 : peakHours.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b);
                      final double ratio = maxVal > 0 ? val / maxVal : 0;
                      
                      final barWidget = Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            FormatUtils.formatCompactAmount(val),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: 80 * ratio,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['hour'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );

                      if (isScrollable) {
                        return SizedBox(
                          width: 64,
                          child: barWidget,
                        );
                      } else {
                        return Expanded(
                          child: barWidget,
                        );
                      }
                    }).toList(),
                  );

                  if (isScrollable) {
                    chartRow = SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: chartRow,
                    );
                  }

                  return SizedBox(
                    height: 140,
                    child: chartRow,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Wastage Tab Widget ────────────────────────────────────────────────

  Widget _buildWastageTab(Map<String, dynamic> data, InventoryWastageAnalyticsModel apiData) {
    final String wastageValue = data['wastageValue'] as String;
    final List<dynamic> wastageReasons = data['wastageReasons'] as List<dynamic>;
    final List<dynamic> topWastedIngredients = data['topWastedIngredients'] as List<dynamic>;

    return Column(
      key: const ValueKey('wastage_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Total Wastage Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.badgeHotBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng giá trị hao hụt kho',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wastageValue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Wastage Reasons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cơ cấu lý do hao hụt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...wastageReasons.map((item) {
                final double pct = item['percentage'] as double;
                final String pctText = '${(pct * 100).toStringAsFixed(0)}%';
                Color barColor = AppColors.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['reason'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${item['value']} ($pctText)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Top Wasted Ingredients
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nguyên liệu hao hụt hàng đầu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (topWastedIngredients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'Chưa ghi nhận hao hụt nguyên liệu trong khoảng thời gian này.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...topWastedIngredients.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${item['qty']} (${item['value']})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Recent Transactions Section Widget ──────────────────────────────────

  String _formatOrderTime(DateTime orderTime) {
    final now = DateTime.now();
    final isToday = orderTime.year == now.year && orderTime.month == now.month && orderTime.day == now.day;
    final timeStr = '${orderTime.hour.toString().padLeft(2, '0')}:${orderTime.minute.toString().padLeft(2, '0')}';
    if (isToday) {
      return '$timeStr · Hôm nay';
    } else {
      return '$timeStr · ${orderTime.day.toString().padLeft(2, '0')}/${orderTime.month.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildRecentTransactionsSection(AsyncValue<List<MockOrder>> ordersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                final activeBranchId = _selectedBranchId ?? '';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllTransactionsPage(initialBranchId: activeBranchId),
                  ),
                );
              },
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ordersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Lỗi khi tải danh sách giao dịch: ${err.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có giao dịch nào gần đây.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: orders.length > 5 ? 5 : orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final id = order.orderNumber.isNotEmpty ? 'HD-${order.orderNumber}' : 'HD-${order.id.substring(0, 4).toUpperCase()}';
                final time = _formatOrderTime(order.orderTime);
                final total = order.totalAmount;
                final isExpanded = _expandedTransactionIndex == index;

                IconData statusIcon = Icons.check_rounded;
                Color statusColor = AppColors.success;
                Color statusBgColor = AppColors.successContainer;

                if (order.status == MockOrderStatus.cancelled) {
                  statusIcon = Icons.close_rounded;
                  statusColor = AppColors.error;
                  statusBgColor = AppColors.badgeHotBg;
                } else if (order.status != MockOrderStatus.completed) {
                  statusIcon = Icons.hourglass_empty_rounded;
                  statusColor = Colors.orange;
                  statusBgColor = Colors.orange.withValues(alpha: 0.15);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey<String>(order.id),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedTransactionIndex = expanded ? index : null;
                        });
                      },
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 18),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            FormatUtils.formatCompactAmount(total),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        time,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(color: AppColors.divider, height: 1),
                              const SizedBox(height: 12),
                              const Text(
                                'Chi tiết món ăn & Topping:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(order.items.map((item) {
                                final hasToppings = item.extras != null && item.extras!.trim().isNotEmpty;
                                final hasNote = item.note != null && item.note!.trim().isNotEmpty;
                                final itemTotal = item.price * item.quantity;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.name} x${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            FormatUtils.formatCurrency(itemTotal),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (hasToppings) ...[
                                        const SizedBox(height: 4),
                                        ...item.extras!.split('\n').where((t) => t.trim().isNotEmpty).map((toppingLine) {
                                          return Padding(
                                            padding: const EdgeInsets.only(left: 6.0, top: 2.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.add_circle_outline_rounded, size: 12, color: AppColors.primary),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    toppingLine,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                      if (hasNote) ...[
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6.0),
                                          child: Text(
                                            'Ghi chú: ${item.note}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.tertiary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList()),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nguồn đơn:',
                                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.orderType == 'Online' || order.orderType == '0' ? 'Đặt trực tuyến' : 'Tại quầy mang đi',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
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
                );
              },
            );
          },
        ),
      ],
    );
  }
}

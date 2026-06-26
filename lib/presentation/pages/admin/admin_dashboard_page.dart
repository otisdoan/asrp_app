import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

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

  // Calculate the number of days in the selected range
  int get _customRangeDays {
    if (_selectedDateRange == null) return 7;
    return _selectedDateRange!.duration.inDays + 1;
  }

  // Mock sales trend data based on selected filter
  List<double> get _trendChartData {
    if (_selectedTimeFilter == 'Tùy chọn') {
      final days = _customRangeDays;
      if (days <= 1) {
        return [3.5, 9.8, 5.2, 7.5];
      } else if (days <= 7) {
        return List.generate(days, (i) => 15.0 + (i * 2.5) % 12.0);
      } else {
        return [120.0, 145.5, 130.0, 155.2]; // weekly summaries
      }
    }

    switch (_selectedTimeFilter) {
      case 'Tuần này':
        return [18.2, 22.4, 19.8, 25.6, 32.8, 45.2, 38.5]; // in million VND
      case 'Tháng này':
        return [185.0, 210.5, 235.4, 212.0]; // in million VND
      case 'Hôm nay':
      default:
        return [4.2, 12.8, 6.2, 9.6]; // in million VND (Sáng, Trưa, Chiều, Tối)
    }
  }

  List<String> get _trendChartLabels {
    if (_selectedTimeFilter == 'Tùy chọn') {
      final days = _customRangeDays;
      if (days <= 1) {
        return ['Sáng', 'Trưa', 'Chiều', 'Tối'];
      } else if (days <= 7) {
        return List.generate(days, (i) => 'N${i + 1}');
      } else {
        return ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
      }
    }

    switch (_selectedTimeFilter) {
      case 'Tuần này':
        return ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      case 'Tháng này':
        return ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
      case 'Hôm nay':
      default:
        return ['Sáng', 'Trưa', 'Chiều', 'Tối'];
    }
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

  // Mock statistical data per filter
  Map<String, dynamic> get _dashboardData {
    if (_selectedTimeFilter == 'Tùy chọn') {
      final days = _customRangeDays;
      double factor = days.toDouble();
      if (days <= 1) factor = 0.8;
      
      final int netSalesVal = (32800000 * factor).round();
      final int discountsVal = (1200000 * factor).round();
      final int foodCostVal = (netSalesVal * 0.35).round();
      final int grossMarginVal = netSalesVal - foodCostVal;
      
      String fmt(int val) {
        return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
      }
      
      return {
        'netSales': fmt(netSalesVal),
        'discounts': fmt(discountsVal),
        'foodCost': fmt(foodCostVal),
        'foodCostPct': '35%',
        'grossMargin': fmt(grossMarginVal),
        'grossMarginPct': '65%',
        
        'paymentBreakdown': [
          {'method': 'Tiền mặt', 'percentage': 0.30, 'value': fmt((netSalesVal * 0.30).round())},
          {'method': 'Chuyển khoản', 'percentage': 0.50, 'value': fmt((netSalesVal * 0.50).round())},
          {'method': 'Ví điện tử', 'percentage': 0.20, 'value': fmt((netSalesVal * 0.20).round())},
        ],
        
        'orderSources': [
          {'source': 'Ăn tại chỗ', 'percentage': 0.65, 'value': fmt((netSalesVal * 0.65).round())},
          {'source': 'Đặt trực tuyến', 'percentage': 0.35, 'value': fmt((netSalesVal * 0.35).round())},
        ],
        
        'categories': [
          {'name': 'Đồ ăn', 'percentage': 0.70, 'value': fmt((netSalesVal * 0.70).round())},
          {'name': 'Đồ uống', 'percentage': 0.22, 'value': fmt((netSalesVal * 0.22).round())},
          {'name': 'Món ăn kèm', 'percentage': 0.08, 'value': fmt((netSalesVal * 0.08).round())},
        ],
        
        'topItems': [
          {'name': 'Phở bò tái đặc biệt', 'qty': (124 * factor).round(), 'revenue': fmt((8060000 * factor).round())},
          {'name': 'Cơm tấm sườn bì chả', 'qty': (98 * factor).round(), 'revenue': fmt((5390000 * factor).round())},
          {'name': 'Cà phê sữa đá Sài Gòn', 'qty': (86 * factor).round(), 'revenue': fmt((2150000 * factor).round())},
          {'name': 'Bún bò Huế giò heo', 'qty': (62 * factor).round(), 'revenue': fmt((3410000 * factor).round())},
          {'name': 'Trà đào cam sả', 'qty': (45 * factor).round(), 'revenue': fmt((1305000 * factor).round())},
        ],
        
        'topToppings': [
          {'name': 'Quẩy giòn rụm', 'qty': (68 * factor).round(), 'revenue': fmt((1020000 * factor).round())},
          {'name': 'Trứng ốp la', 'qty': (45 * factor).round(), 'revenue': fmt((450000 * factor).round())},
          {'name': 'Thịt sườn thêm', 'qty': (24 * factor).round(), 'revenue': fmt((720000 * factor).round())},
        ],
        
        'peakHours': [
          {'hour': '7h - 9h', 'value': 4.5 * factor},
          {'hour': '11h - 13h', 'value': 12.8 * factor},
          {'hour': '17h - 19h', 'value': 9.6 * factor},
          {'hour': '20h - 22h', 'value': 5.9 * factor},
        ],
        
        'avgPrepTime': '13,2 phút',
        'cancellationRate': '2.1%',
        
        'wastageValue': fmt((450000 * factor).round()),
        'wastageReasons': [
          {'reason': 'Hết hạn sử dụng', 'percentage': 0.50, 'value': fmt((225000 * factor).round())},
          {'reason': 'Hao hụt bếp', 'percentage': 0.35, 'value': fmt((157500 * factor).round())},
          {'reason': 'Mất mát hao phí', 'percentage': 0.15, 'value': fmt((67500 * factor).round())},
        ],
        'topWastedIngredients': [
          {'name': 'Thịt bò thăn', 'qty': '${(1.2 * factor).toStringAsFixed(1)} kg', 'value': fmt((300000 * factor).round())},
          {'name': 'Sữa tươi tiệt trùng', 'qty': '${(2 * factor).round()} lít', 'value': fmt((60000 * factor).round())},
          {'name': 'Rau thơm tổng hợp', 'qty': '${(1.5 * factor).toStringAsFixed(1)} kg', 'value': fmt((45000 * factor).round())},
          {'name': 'Trứng gà ta', 'qty': '${(6 * factor).round()} quả', 'value': fmt((24000 * factor).round())},
          {'name': 'Hành lá', 'qty': '${(2 * factor).round()} kg', 'value': fmt((20000 * factor).round())},
        ],
      };
    }

    switch (_selectedTimeFilter) {
      case 'Tuần này':
        return {
          'netSales': '202.500.000đ',
          'discounts': '8.200.000đ',
          'foodCost': '70.875.000đ',
          'foodCostPct': '35%',
          'grossMargin': '131.625.000đ',
          'grossMarginPct': '65%',
          
          'paymentBreakdown': [
            {'method': 'Tiền mặt', 'percentage': 0.35, 'value': '70.875.000đ'},
            {'method': 'Chuyển khoản', 'percentage': 0.45, 'value': '91.125.000đ'},
            {'method': 'Ví điện tử', 'percentage': 0.20, 'value': '40.500.000đ'},
          ],
          
          'orderSources': [
            {'source': 'Ăn tại chỗ', 'percentage': 0.60, 'value': '121.500.000đ'},
            {'source': 'Đặt trực tuyến', 'percentage': 0.40, 'value': '81.000.000đ'},
          ],
          
          'categories': [
            {'name': 'Đồ ăn', 'percentage': 0.65, 'value': '131.625.000đ'},
            {'name': 'Đồ uống', 'percentage': 0.25, 'value': '50.625.000đ'},
            {'name': 'Món ăn kèm', 'percentage': 0.10, 'value': '20.250.000đ'},
          ],
          
          'topItems': [
            {'name': 'Phở bò tái đặc biệt', 'qty': 820, 'revenue': '53.300.000đ'},
            {'name': 'Cơm tấm sườn bì chả', 'qty': 650, 'revenue': '35.750.000đ'},
            {'name': 'Cà phê sữa đá Sài Gòn', 'qty': 580, 'revenue': '14.500.000đ'},
            {'name': 'Bún bò Huế giò heo', 'qty': 420, 'revenue': '23.100.000đ'},
            {'name': 'Trà đào cam sả', 'qty': 310, 'revenue': '8.990.000đ'},
          ],
          
          'topToppings': [
            {'name': 'Quẩy giòn rụm', 'qty': 450, 'revenue': '6.750.000đ'},
            {'name': 'Trứng ốp la', 'qty': 320, 'revenue': '3.200.000đ'},
            {'name': 'Thịt sườn thêm', 'qty': 180, 'revenue': '5.400.000đ'},
          ],
          
          'peakHours': [
            {'hour': '7h - 9h', 'value': 28.5},
            {'hour': '11h - 13h', 'value': 75.2},
            {'hour': '17h - 19h', 'value': 62.4},
            {'hour': '20h - 22h', 'value': 36.4},
          ],
          
          'avgPrepTime': '12,5 phút',
          'cancellationRate': '1.8%',
          
          'wastageValue': '4.250.000đ',
          'wastageReasons': [
            {'reason': 'Hết hạn sử dụng', 'percentage': 0.55, 'value': '2.337.500đ'},
            {'reason': 'Hao hụt bếp', 'percentage': 0.30, 'value': '1.275.000đ'},
            {'reason': 'Mất mát hao phí', 'percentage': 0.15, 'value': '637.500đ'},
          ],
          'topWastedIngredients': [
            {'name': 'Thịt bò thăn', 'qty': '8.5 kg', 'value': '2.125.000đ'},
            {'name': 'Sữa tươi tiệt trùng', 'qty': '15 lít', 'value': '450.000đ'},
            {'name': 'Rau thơm tổng hợp', 'qty': '12 kg', 'value': '360.000đ'},
            {'name': 'Trứng gà ta', 'qty': '60 quả', 'value': '240.000đ'},
            {'name': 'Hành lá', 'qty': '15 kg', 'value': '150.000đ'},
          ],
        };
      case 'Tháng này':
        return {
          'netSales': '842.900.000đ',
          'discounts': '35.400.000đ',
          'foodCost': '295.015.000đ',
          'foodCostPct': '35%',
          'grossMargin': '547.885.000đ',
          'grossMarginPct': '65%',
          
          'paymentBreakdown': [
            {'method': 'Tiền mặt', 'percentage': 0.32, 'value': '269.728.000đ'},
            {'method': 'Chuyển khoản', 'percentage': 0.48, 'value': '404.592.000đ'},
            {'method': 'Ví điện tử', 'percentage': 0.20, 'value': '168.580.000đ'},
          ],
          
          'orderSources': [
            {'source': 'Ăn tại chỗ', 'percentage': 0.58, 'value': '488.882.000đ'},
            {'source': 'Đặt trực tuyến', 'percentage': 0.42, 'value': '354.018.000đ'},
          ],
          
          'categories': [
            {'name': 'Đồ ăn', 'percentage': 0.67, 'value': '564.743.000đ'},
            {'name': 'Đồ uống', 'percentage': 0.24, 'value': '202.296.000đ'},
            {'name': 'Món ăn kèm', 'percentage': 0.09, 'value': '75.861.000đ'},
          ],
          
          'topItems': [
            {'name': 'Phở bò tái đặc biệt', 'qty': 3420, 'revenue': '222.300.000đ'},
            {'name': 'Cơm tấm sườn bì chả', 'qty': 2750, 'revenue': '151.250.000đ'},
            {'name': 'Cà phê sữa đá Sài Gòn', 'qty': 2480, 'revenue': '62.000.000đ'},
            {'name': 'Bún bò Huế giò heo', 'qty': 1890, 'revenue': '103.950.000đ'},
            {'name': 'Trà đào cam sả', 'qty': 1320, 'revenue': '38.280.000đ'},
          ],
          
          'topToppings': [
            {'name': 'Quẩy giòn rụm', 'qty': 1950, 'revenue': '29.250.000đ'},
            {'name': 'Trứng ốp la', 'qty': 1380, 'revenue': '13.800.000đ'},
            {'name': 'Thịt sườn thêm', 'qty': 820, 'revenue': '24.600.000đ'},
          ],
          
          'peakHours': [
            {'hour': '7h - 9h', 'value': 118.5},
            {'hour': '11h - 13h', 'value': 315.2},
            {'hour': '17h - 19h', 'value': 262.4},
            {'hour': '20h - 22h', 'value': 146.8},
          ],
          
          'avgPrepTime': '11,8 phút',
          'cancellationRate': '1.5%',
          
          'wastageValue': '16.850.000đ',
          'wastageReasons': [
            {'reason': 'Hết hạn sử dụng', 'percentage': 0.58, 'value': '9.773.000đ'},
            {'reason': 'Hao hụt bếp', 'percentage': 0.28, 'value': '4.718.000đ'},
            {'reason': 'Mất mát hao phí', 'percentage': 0.14, 'value': '2.359.000đ'},
          ],
          'topWastedIngredients': [
            {'name': 'Thịt bò thăn', 'qty': '35.0 kg', 'value': '8.750.000đ'},
            {'name': 'Sữa tươi tiệt trùng', 'qty': '62 lít', 'value': '1.860.000đ'},
            {'name': 'Rau thơm tổng hợp', 'qty': '50 kg', 'value': '1.500.000đ'},
            {'name': 'Trứng gà ta', 'qty': '280 quả', 'value': '1.120.000đ'},
            {'name': 'Hành lá', 'qty': '58 kg', 'value': '580.000đ'},
          ],
        };
      case 'Hôm nay':
      default:
        return {
          'netSales': '32.800.000đ',
          'discounts': '1.200.000đ',
          'foodCost': '11.480.000đ',
          'foodCostPct': '35%',
          'grossMargin': '21.320.000đ',
          'grossMarginPct': '65%',
          
          'paymentBreakdown': [
            {'method': 'Tiền mặt', 'percentage': 0.30, 'value': '9.840.000đ'},
            {'method': 'Chuyển khoản', 'percentage': 0.50, 'value': '16.400.000đ'},
            {'method': 'Ví điện tử', 'percentage': 0.20, 'value': '6.560.000đ'},
          ],
          
          'orderSources': [
            {'source': 'Ăn tại chỗ', 'percentage': 0.65, 'value': '21.320.000đ'},
            {'source': 'Đặt trực tuyến', 'percentage': 0.35, 'value': '11.480.000đ'},
          ],
          
          'categories': [
            {'name': 'Đồ ăn', 'percentage': 0.70, 'value': '22.960.000đ'},
            {'name': 'Đồ uống', 'percentage': 0.22, 'value': '7.216.000đ'},
            {'name': 'Món ăn kèm', 'percentage': 0.08, 'value': '2.624.000đ'},
          ],
          
          'topItems': [
            {'name': 'Phở bò tái đặc biệt', 'qty': 124, 'revenue': '8.060.000đ'},
            {'name': 'Cơm tấm sườn bì chả', 'qty': 98, 'revenue': '5.390.000đ'},
            {'name': 'Cà phê sữa đá Sài Gòn', 'qty': 86, 'revenue': '2.150.000đ'},
            {'name': 'Bún bò Huế giò heo', 'qty': 62, 'revenue': '3.410.000đ'},
            {'name': 'Trà đào cam sả', 'qty': 45, 'revenue': '1.305.000đ'},
          ],
          
          'topToppings': [
            {'name': 'Quẩy giòn rụm', 'qty': 68, 'revenue': '1.020.000đ'},
            {'name': 'Trứng ốp la', 'qty': 45, 'revenue': '450.000đ'},
            {'name': 'Thịt sườn thêm', 'qty': 24, 'revenue': '720.000đ'},
          ],
          
          'peakHours': [
            {'hour': '7h - 9h', 'value': 4.5},
            {'hour': '11h - 13h', 'value': 12.8},
            {'hour': '17h - 19h', 'value': 9.6},
            {'hour': '20h - 22h', 'value': 5.9},
          ],
          
          'avgPrepTime': '13,2 phút',
          'cancellationRate': '2.1%',
          
          'wastageValue': '450.000đ',
          'wastageReasons': [
            {'reason': 'Hết hạn sử dụng', 'percentage': 0.50, 'value': '225.000đ'},
            {'reason': 'Hao hụt bếp', 'percentage': 0.35, 'value': '157.500đ'},
            {'reason': 'Mất mát hao phí', 'percentage': 0.15, 'value': '67.500đ'},
          ],
          'topWastedIngredients': [
            {'name': 'Thịt bò thăn', 'qty': '1.2 kg', 'value': '300.000đ'},
            {'name': 'Sữa tươi tiệt trùng', 'qty': '2 lít', 'value': '60.000đ'},
            {'name': 'Rau thơm tổng hợp', 'qty': '1.5 kg', 'value': '45.000đ'},
            {'name': 'Trứng gà ta', 'qty': '6 quả', 'value': '24.000đ'},
            {'name': 'Hành lá', 'qty': '2 kg', 'value': '20.000đ'},
          ],
        };
    }
  }

  // Mock transactions list (always visible at bottom of Financials tab)
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'HD-9842',
      'time': '10:42 · Hôm nay',
      'total': 185000,
      'itemsCount': 3,
      'items': [
        {'name': 'Phở bò tái đặc biệt', 'qty': 2, 'price': 65000},
        {'name': 'Cà phê sữa đá Sài Gòn', 'qty': 1, 'price': 25000},
        {'name': 'Quẩy giòn rụm', 'qty': 2, 'price': 15000},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
    {
      'id': 'HD-9841',
      'time': '10:15 · Hôm nay',
      'total': 90000,
      'itemsCount': 2,
      'items': [
        {'name': 'Bún bò Huế giò heo', 'qty': 1, 'price': 55000},
        {'name': 'Trà đào cam sả', 'qty': 1, 'price': 29000},
        {'name': 'Khăn lạnh', 'qty': 2, 'price': 3000},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
    {
      'id': 'HD-9840',
      'time': '09:58 · Hôm nay',
      'total': 135000,
      'itemsCount': 2,
      'items': [
        {'name': 'Cơm tấm sườn bì chả', 'qty': 2, 'price': 55000},
        {'name': 'Nước ngọt Pepsi', 'qty': 2, 'price': 12500},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
    {
      'id': 'HD-9839',
      'time': '09:30 · Hôm nay',
      'total': 50000,
      'itemsCount': 1,
      'items': [
        {'name': 'Phở bò viên thập cẩm', 'qty': 1, 'price': 50000},
      ],
      'branch': 'Chi nhánh Quận 1',
    },
  ];

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
    final data = _dashboardData;

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
                          _buildTimeFilterChips(),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 5. Dynamic Tab View contents
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildSelectedTabContent(data),
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

  Widget _buildSelectedTabContent(Map<String, dynamic> data) {
    switch (_selectedTabIdx) {
      case 1:
        return _buildMenuPerformanceTab(data);
      case 2:
        return _buildOperationsTab(data);
      case 3:
        return _buildWastageTab(data);
      case 0:
      default:
        return _buildFinancialTab(data);
    }
  }

  // ─── Financial Tab Widget ──────────────────────────────────────────────

  Widget _buildFinancialTab(Map<String, dynamic> data) {
    return Column(
      key: const ValueKey('financial_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sleek Gradient Net Sales Card
        _buildNetSalesOverview(data),
        const SizedBox(height: 18),

        // 2. Interactive Revenue Trend Chart
        _buildTrendChart(),
        const SizedBox(height: 18),

        // 3. KPI Financial Cards List Stacked to prevent horizontal truncation
        _buildFinancialKPIGrid(data),
        const SizedBox(height: 18),

        // 4. Payment Structure Breakdown
        _buildPaymentBreakdown(data['paymentBreakdown'] as List<dynamic>),
        const SizedBox(height: 18),

        // 5. Order Source Breakdown
        _buildOrderSourceBreakdown(data['orderSources'] as List<dynamic>),
        const SizedBox(height: 24),

        // 6. Transaction List Table
        _buildRecentTransactionsSection(),
      ],
    );
  }

  Widget _buildNetSalesOverview(Map<String, dynamic> data) {
    final String growth = _selectedTimeFilter == 'Hôm nay'
        ? '+12.4%'
        : _selectedTimeFilter == 'Tuần này'
            ? '+14.2%'
            : _selectedTimeFilter == 'Tháng này'
                ? '+18.5%'
                : '+15.4%'; // Default growth for custom range

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
                'Doanh thu ròng thực tế',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 14),
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
            data['netSales']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTimeFilter == 'Hôm nay'
                ? 'So với cùng kỳ hôm qua (30.1M)'
                : _selectedTimeFilter == 'Tuần này'
                    ? 'So với tuần trước (177.3M)'
                    : _selectedTimeFilter == 'Tháng này'
                        ? 'So với tháng trước (711.2M)'
                        : 'Báo cáo khoảng thời gian tùy chọn',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final double maxVal = _trendChartData.reduce((a, b) => a > b ? a : b);
    final List<double> chartData = _trendChartData;
    final List<String> labels = _trendChartLabels;

    if (_selectedChartBarIndex >= chartData.length) {
      _selectedChartBarIndex = 0;
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartData.length, (idx) {
                final double val = chartData[idx];
                final double ratio = maxVal > 0 ? val / maxVal : 0;
                final bool isSelected = _selectedChartBarIndex == idx;

                return Expanded(
                  child: GestureDetector(
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
                              '${val.toStringAsFixed(1)}M',
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
                          margin: const EdgeInsets.symmetric(horizontal: 6),
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
                          labels[idx],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
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
                  _selectedTimeFilter == 'Hôm nay'
                      ? 'Khoảng thời gian ${labels[_selectedChartBarIndex]} đạt ${chartData[_selectedChartBarIndex].toStringAsFixed(1)} triệuđ'
                      : _selectedTimeFilter == 'Tuần này'
                          ? 'Thứ ${labels[_selectedChartBarIndex] == 'CN' ? 'Chủ nhật' : labels[_selectedChartBarIndex].replaceAll('T', '')} đạt ${chartData[_selectedChartBarIndex].toStringAsFixed(1)} triệuđ'
                          : '${labels[_selectedChartBarIndex]} đạt ${chartData[_selectedChartBarIndex].toStringAsFixed(1)} triệuđ',
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

  Widget _buildFinancialKPIGrid(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildKPITile(
          title: 'Giảm giá khuyến mãi',
          value: data['discounts']!,
          icon: Icons.local_offer_rounded,
          iconBg: AppColors.badgeHotBg,
          iconColor: AppColors.badgeHotText,
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Chi phí nguyên liệu',
          value: data['foodCost']!,
          icon: Icons.kitchen_rounded,
          iconBg: AppColors.badgeNewBg,
          iconColor: AppColors.badgeNewText,
          badgeText: data['foodCostPct']!,
        ),
        const SizedBox(height: 10),
        _buildKPITile(
          title: 'Lợi nhuận gộp thực tế',
          value: data['grossMargin']!,
          icon: Icons.trending_up_rounded,
          iconBg: AppColors.badgeBestBg,
          iconColor: AppColors.badgeBestText,
          badgeText: data['grossMarginPct']!,
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
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
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
            if (item['method'] == 'Chuyển khoản') barColor = AppColors.secondary;
            if (item['method'] == 'Ví điện tử') barColor = AppColors.accent;
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
          ...sourcesList.map((item) {
            final double pct = item['percentage'] as double;
            final String pctText = '${(pct * 100).toStringAsFixed(0)}%';
            Color barColor = AppColors.primary;
            if (item['source'] == 'Đặt trực tuyến') barColor = AppColors.tertiary;
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

  Widget _buildMenuPerformanceTab(Map<String, dynamic> data) {
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
              ...categories.map((item) {
                final double pct = item['percentage'] as double;
                final String pctText = '${(pct * 100).toStringAsFixed(0)}%';
                Color barColor = AppColors.primary;
                if (item['name'] == 'Đồ uống') barColor = AppColors.secondary;
                if (item['name'] == 'Món ăn kèm') barColor = AppColors.tertiary;
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

  Widget _buildOperationsTab(Map<String, dynamic> data) {
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
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: peakHours.map((item) {
                    final double val = item['value'] as double;
                    final double maxVal = peakHours.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b);
                    final double ratio = maxVal > 0 ? val / maxVal : 0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${val.toStringAsFixed(1)}M',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
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
                  }).toList(),
                ),
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

  Widget _buildWastageTab(Map<String, dynamic> data) {
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
                if (item['reason'] == 'Hao hụt bếp') barColor = AppColors.secondary;
                if (item['reason'] == 'Mất mát hao phí') barColor = AppColors.tertiary;
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

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch hôm nay',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hiển thị bộ lọc nâng cao tất cả các giao dịch.')),
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final trans = _transactions[index];
            final id = trans['id'] as String;
            final time = trans['time'] as String;
            final total = trans['total'] as int;
            final isExpanded = _expandedTransactionIndex == index;

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
                  key: PageStorageKey<String>(id),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedTransactionIndex = expanded ? index : null;
                    });
                  },
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.successContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
                  ),
                  title: Row(
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(total / 1000).toStringAsFixed(0)}k',
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
                            'Chi tiết đơn hàng:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...((trans['items'] as List).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['name']} x${item['qty']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '${((item['price'] * item['qty']) / 1000).toStringAsFixed(0)}k',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })),
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
                                child: const Text(
                                  'Tại quầy mang đi',
                                  style: TextStyle(
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
        ),
      ],
    );
  }
}

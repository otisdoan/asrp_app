class BrandDashboardResponseModel {
  final BrandDashboardBrandModel brand;
  final DashboardPeriodModel period;
  final BrandDashboardSummaryModel summary;
  final List<BranchDashboardItemModel> branches;

  BrandDashboardResponseModel({
    required this.brand,
    required this.period,
    required this.summary,
    required this.branches,
  });

  factory BrandDashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return BrandDashboardResponseModel(
      brand: BrandDashboardBrandModel.fromJson(json['brand'] as Map<String, dynamic>),
      period: DashboardPeriodModel.fromJson(json['period'] as Map<String, dynamic>),
      summary: BrandDashboardSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => BranchDashboardItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BrandDashboardBrandModel {
  final String id;
  final String name;
  final int activeBranches;

  BrandDashboardBrandModel({
    required this.id,
    required this.name,
    required this.activeBranches,
  });

  factory BrandDashboardBrandModel.fromJson(Map<String, dynamic> json) {
    return BrandDashboardBrandModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      activeBranches: json['activeBranches'] as int? ?? 0,
    );
  }
}

class DashboardPeriodModel {
  final DateTime from;
  final DateTime to;

  DashboardPeriodModel({
    required this.from,
    required this.to,
  });

  factory DashboardPeriodModel.fromJson(Map<String, dynamic> json) {
    return DashboardPeriodModel(
      from: json['from'] != null ? DateTime.parse(json['from'] as String) : DateTime.now(),
      to: json['to'] != null ? DateTime.parse(json['to'] as String) : DateTime.now(),
    );
  }
}

class BrandDashboardSummaryModel {
  final double revenue;
  final int orderCount;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final int paidOrders;
  final int activeBranches;
  final double totalDiscount;
  final double foodCost;
  final double grossMargin;
  final double wastageCost;
  final double netProfit;
  final double grossMarginPercentage;
  final double netProfitPercentage;
  final bool isProfitable;

  BrandDashboardSummaryModel({
    required this.revenue,
    required this.orderCount,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.paidOrders,
    required this.activeBranches,
    this.totalDiscount = 0.0,
    this.foodCost = 0.0,
    this.grossMargin = 0.0,
    this.wastageCost = 0.0,
    this.netProfit = 0.0,
    this.grossMarginPercentage = 0.0,
    this.netProfitPercentage = 0.0,
    this.isProfitable = true,
  });

  factory BrandDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final rev = (json['revenue'] as num?)?.toDouble() ?? 0.0;
    final discount = (json['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final fc = (json['foodCost'] as num?)?.toDouble() ?? 0.0;
    final gm = (json['grossMargin'] as num?)?.toDouble() ?? (rev - fc);
    final wc = (json['wastageCost'] as num?)?.toDouble() ?? 0.0;
    final np = (json['netProfit'] as num?)?.toDouble() ?? (gm - wc);
    final gmPct = (json['grossMarginPercentage'] as num?)?.toDouble() ?? (rev > 0 ? (gm / rev * 100) : 0.0);
    final npPct = (json['netProfitPercentage'] as num?)?.toDouble() ?? (rev > 0 ? (np / rev * 100) : 0.0);
    final isProf = json['isProfitable'] as bool? ?? (np >= 0);

    return BrandDashboardSummaryModel(
      revenue: rev,
      orderCount: json['orderCount'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      paidOrders: json['paidOrders'] as int? ?? 0,
      activeBranches: json['activeBranches'] as int? ?? 0,
      totalDiscount: discount,
      foodCost: fc,
      grossMargin: gm,
      wastageCost: wc,
      netProfit: np,
      grossMarginPercentage: gmPct,
      netProfitPercentage: npPct,
      isProfitable: isProf,
    );
  }
}

class BranchDashboardItemModel {
  final String branchId;
  final String branchName;
  final bool isActive;
  final String status;
  final double revenue;
  final int orderCount;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final int paidOrders;
  final PaymentBreakdownModel paymentBreakdown;
  final double totalDiscount;
  final double foodCost;
  final double grossMargin;
  final double wastageCost;
  final double netProfit;
  final double netProfitPercentage;
  final bool isProfitable;

  BranchDashboardItemModel({
    required this.branchId,
    required this.branchName,
    required this.isActive,
    required this.status,
    required this.revenue,
    required this.orderCount,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.paidOrders,
    required this.paymentBreakdown,
    this.totalDiscount = 0.0,
    this.foodCost = 0.0,
    this.grossMargin = 0.0,
    this.wastageCost = 0.0,
    this.netProfit = 0.0,
    this.netProfitPercentage = 0.0,
    this.isProfitable = true,
  });

  factory BranchDashboardItemModel.fromJson(Map<String, dynamic> json) {
    final rev = (json['revenue'] as num?)?.toDouble() ?? 0.0;
    final discount = (json['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final fc = (json['foodCost'] as num?)?.toDouble() ?? 0.0;
    final gm = (json['grossMargin'] as num?)?.toDouble() ?? (rev - fc);
    final wc = (json['wastageCost'] as num?)?.toDouble() ?? 0.0;
    final np = (json['netProfit'] as num?)?.toDouble() ?? (gm - wc);
    final npPct = (json['netProfitPercentage'] as num?)?.toDouble() ?? (rev > 0 ? (np / rev * 100) : 0.0);
    final isProf = json['isProfitable'] as bool? ?? (np >= 0);

    return BranchDashboardItemModel(
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      status: json['status'] as String? ?? 'Closed',
      revenue: rev,
      orderCount: json['orderCount'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      paidOrders: json['paidOrders'] as int? ?? 0,
      paymentBreakdown: PaymentBreakdownModel.fromJson(
        (json['paymentBreakdown'] as Map<String, dynamic>?) ?? {},
      ),
      totalDiscount: discount,
      foodCost: fc,
      grossMargin: gm,
      wastageCost: wc,
      netProfit: np,
      netProfitPercentage: npPct,
      isProfitable: isProf,
    );
  }
}

class PaymentBreakdownModel {
  final double cash;
  final double payOS;

  PaymentBreakdownModel({
    required this.cash,
    required this.payOS,
  });

  factory PaymentBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdownModel(
      cash: (json['cash'] as num?)?.toDouble() ?? 0.0,
      payOS: (json['payOS'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesTrendModel {
  final SalesTrendPeriodModel period;
  final List<SalesTrendItemModel> items;

  SalesTrendModel({required this.period, required this.items});

  factory SalesTrendModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendModel(
      period: SalesTrendPeriodModel.fromJson(json['period'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SalesTrendItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class SalesTrendPeriodModel {
  final DateTime? from;
  final DateTime? to;
  final String granularity;
  final bool isAllTime;

  SalesTrendPeriodModel({this.from, this.to, required this.granularity, this.isAllTime = false});

  factory SalesTrendPeriodModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendPeriodModel(
      from: json['from'] != null ? DateTime.parse(json['from'] as String) : null,
      to: json['to'] != null ? DateTime.parse(json['to'] as String) : null,
      granularity: json['granularity'] as String? ?? 'Daily',
      isAllTime: json['isAllTime'] as bool? ?? false,
    );
  }
}

class SalesTrendItemModel {
  final String label;
  final DateTime from;
  final DateTime to;
  final double revenue;
  final int orderCount;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;

  SalesTrendItemModel({
    required this.label,
    required this.from,
    required this.to,
    required this.revenue,
    required this.orderCount,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
  });

  factory SalesTrendItemModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendItemModel(
      label: json['label'] as String? ?? '',
      from: json['from'] != null ? DateTime.parse(json['from'] as String) : DateTime.now(),
      to: json['to'] != null ? DateTime.parse(json['to'] as String) : DateTime.now(),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      orderCount: json['orderCount'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MenuPerformanceToppingModel {
  final String name;
  final int quantitySold;
  final double revenue;

  MenuPerformanceToppingModel({
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory MenuPerformanceToppingModel.fromJson(Map<String, dynamic> json) {
    return MenuPerformanceToppingModel(
      name: json['name'] as String? ?? '',
      quantitySold: json['quantitySold'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MenuPerformanceModel {
  final List<MenuPerformanceItemModel> topSellingItems;
  final List<MenuPerformanceItemModel> topRevenueItems;
  final List<CategoryPerformanceModel> categoryPerformance;
  final List<MenuPerformanceToppingModel> topToppings;

  MenuPerformanceModel({
    required this.topSellingItems,
    required this.topRevenueItems,
    required this.categoryPerformance,
    required this.topToppings,
  });

  factory MenuPerformanceModel.fromJson(Map<String, dynamic> json) {
    return MenuPerformanceModel(
      topSellingItems: (json['topSellingItems'] as List<dynamic>?)
              ?.map((e) => MenuPerformanceItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      topRevenueItems: (json['topRevenueItems'] as List<dynamic>?)
              ?.map((e) => MenuPerformanceItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      categoryPerformance: (json['categoryPerformance'] as List<dynamic>?)
              ?.map((e) => CategoryPerformanceModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      topToppings: (json['topToppings'] as List<dynamic>?)
              ?.map((e) => MenuPerformanceToppingModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class MenuPerformanceItemModel {
  final String menuItemId;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final int quantitySold;
  final int orderCount;
  final double revenue;

  MenuPerformanceItemModel({
    required this.menuItemId,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    required this.quantitySold,
    required this.orderCount,
    required this.revenue,
  });

  factory MenuPerformanceItemModel.fromJson(Map<String, dynamic> json) {
    return MenuPerformanceItemModel(
      menuItemId: json['menuItemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      quantitySold: json['quantitySold'] as int? ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryPerformanceModel {
  final String? categoryId;
  final String? categoryName;
  final int quantitySold;
  final int orderCount;
  final double revenue;

  CategoryPerformanceModel({
    this.categoryId,
    this.categoryName,
    required this.quantitySold,
    required this.orderCount,
    required this.revenue,
  });

  factory CategoryPerformanceModel.fromJson(Map<String, dynamic> json) {
    return CategoryPerformanceModel(
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      quantitySold: json['quantitySold'] as int? ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OperationsAnalyticsModel {
  final List<OperationsStatusDistributionModel> statusDistribution;
  final List<OperationsPeakHourModel> peakHours;
  final OperationsSummaryModel summary;

  OperationsAnalyticsModel({
    required this.statusDistribution,
    required this.peakHours,
    required this.summary,
  });

  factory OperationsAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return OperationsAnalyticsModel(
      statusDistribution: (json['statusDistribution'] as List<dynamic>?)
              ?.map((e) => OperationsStatusDistributionModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      peakHours: (json['peakHours'] as List<dynamic>?)
              ?.map((e) => OperationsPeakHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      summary: OperationsSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}

class OperationsStatusDistributionModel {
  final String status;
  final int count;

  OperationsStatusDistributionModel({required this.status, required this.count});

  factory OperationsStatusDistributionModel.fromJson(Map<String, dynamic> json) {
    return OperationsStatusDistributionModel(
      status: json['status'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class OperationsPeakHourModel {
  final int hour;
  final int orderCount;
  final double revenue;

  OperationsPeakHourModel({required this.hour, required this.orderCount, required this.revenue});

  factory OperationsPeakHourModel.fromJson(Map<String, dynamic> json) {
    return OperationsPeakHourModel(
      hour: json['hour'] as int? ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OperationsSummaryModel {
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final int readyForPickupOrders;
  final int preparingOrders;
  final double cancellationRate;
  final double? averagePreparationMinutes;
  final double? averagePickupDelayMinutes;
  final int? latePickupOrders;

  OperationsSummaryModel({
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.readyForPickupOrders,
    required this.preparingOrders,
    required this.cancellationRate,
    this.averagePreparationMinutes,
    this.averagePickupDelayMinutes,
    this.latePickupOrders,
  });

  factory OperationsSummaryModel.fromJson(Map<String, dynamic> json) {
    return OperationsSummaryModel(
      totalOrders: json['totalOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      readyForPickupOrders: json['readyForPickupOrders'] as int? ?? 0,
      preparingOrders: json['preparingOrders'] as int? ?? 0,
      cancellationRate: (json['cancellationRate'] as num?)?.toDouble() ?? 0.0,
      averagePreparationMinutes: (json['averagePreparationMinutes'] as num?)?.toDouble(),
      averagePickupDelayMinutes: (json['averagePickupDelayMinutes'] as num?)?.toDouble(),
      latePickupOrders: json['latePickupOrders'] as int?,
    );
  }
}

class InventoryWastageAnalyticsModel {
  final InventoryWastageSummaryModel summary;
  final List<LowStockItemModel> lowStockItems;
  final List<WastageItemModel> wastageItems;
  final List<TransactionBreakdownModel> transactionBreakdown;

  InventoryWastageAnalyticsModel({
    required this.summary,
    required this.lowStockItems,
    required this.wastageItems,
    required this.transactionBreakdown,
  });

  factory InventoryWastageAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return InventoryWastageAnalyticsModel(
      summary: InventoryWastageSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      lowStockItems: (json['lowStockItems'] as List<dynamic>?)
              ?.map((e) => LowStockItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      wastageItems: (json['wastageItems'] as List<dynamic>?)
              ?.map((e) => WastageItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      transactionBreakdown: (json['transactionBreakdown'] as List<dynamic>?)
              ?.map((e) => TransactionBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class InventoryWastageSummaryModel {
  final int lowStockCount;
  final int shortageCount;
  final int wasteTransactionCount;
  final double wasteQuantity;
  final double? wasteValue;
  final double importQuantity;
  final double deductionQuantity;
  final double adjustmentQuantity;

  InventoryWastageSummaryModel({
    required this.lowStockCount,
    required this.shortageCount,
    required this.wasteTransactionCount,
    required this.wasteQuantity,
    this.wasteValue,
    required this.importQuantity,
    required this.deductionQuantity,
    required this.adjustmentQuantity,
  });

  factory InventoryWastageSummaryModel.fromJson(Map<String, dynamic> json) {
    return InventoryWastageSummaryModel(
      lowStockCount: json['lowStockCount'] as int? ?? 0,
      shortageCount: json['shortageCount'] as int? ?? 0,
      wasteTransactionCount: json['wasteTransactionCount'] as int? ?? 0,
      wasteQuantity: (json['wasteQuantity'] as num?)?.toDouble() ?? 0.0,
      wasteValue: (json['wasteValue'] as num?)?.toDouble(),
      importQuantity: (json['importQuantity'] as num?)?.toDouble() ?? 0.0,
      deductionQuantity: (json['deductionQuantity'] as num?)?.toDouble() ?? 0.0,
      adjustmentQuantity: (json['adjustmentQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LowStockItemModel {
  final String ingredientId;
  final String ingredientName;
  final String branchId;
  final String branchName;
  final double quantity;
  final double minThreshold;
  final String unit;

  LowStockItemModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.branchId,
    required this.branchName,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
  });

  factory LowStockItemModel.fromJson(Map<String, dynamic> json) {
    return LowStockItemModel(
      ingredientId: json['ingredientId'] as String? ?? '',
      ingredientName: json['ingredientName'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      minThreshold: (json['minThreshold'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }
}

class WastageItemModel {
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final double? value;

  WastageItemModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    this.value,
  });

  factory WastageItemModel.fromJson(Map<String, dynamic> json) {
    return WastageItemModel(
      ingredientId: json['ingredientId'] as String? ?? '',
      ingredientName: json['ingredientName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble(),
    );
  }
}

class TransactionBreakdownModel {
  final String type;
  final double quantity;
  final double? value;
  final int count;

  TransactionBreakdownModel({
    required this.type,
    required this.quantity,
    this.value,
    required this.count,
  });

  factory TransactionBreakdownModel.fromJson(Map<String, dynamic> json) {
    return TransactionBreakdownModel(
      type: json['type'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble(),
      count: json['count'] as int? ?? 0,
    );
  }
}

class OrderSourceBreakdownModel {
  final String source;
  final double percentage;
  final double value;

  OrderSourceBreakdownModel({
    required this.source,
    required this.percentage,
    required this.value,
  });

  factory OrderSourceBreakdownModel.fromJson(Map<String, dynamic> json) {
    return OrderSourceBreakdownModel(
      source: json['source'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BranchDashboardDetailModel {
  final BranchDashboardBranchModel branch;
  final DashboardPeriodModel period;
  final BranchDashboardSummaryModel summary;
  final PaymentBreakdownModel paymentBreakdown;
  final List<OrderSourceBreakdownModel> orderSources;

  BranchDashboardDetailModel({
    required this.branch,
    required this.period,
    required this.summary,
    required this.paymentBreakdown,
    required this.orderSources,
  });

  factory BranchDashboardDetailModel.fromJson(Map<String, dynamic> json) {
    return BranchDashboardDetailModel(
      branch: BranchDashboardBranchModel.fromJson(json['branch'] as Map<String, dynamic>),
      period: DashboardPeriodModel.fromJson(json['period'] as Map<String, dynamic>),
      summary: BranchDashboardSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      paymentBreakdown: PaymentBreakdownModel.fromJson(
        (json['paymentBreakdown'] as Map<String, dynamic>?) ?? {},
      ),
      orderSources: (json['orderSources'] as List<dynamic>?)
              ?.map((e) => OrderSourceBreakdownModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BranchDashboardBranchModel {
  final String id;
  final String name;
  final bool isActive;
  final String status;

  BranchDashboardBranchModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.status,
  });

  factory BranchDashboardBranchModel.fromJson(Map<String, dynamic> json) {
    return BranchDashboardBranchModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      status: json['status'] as String? ?? 'Closed',
    );
  }
}

class BranchDashboardSummaryModel {
  final double revenue;
  final int orderCount;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final int paidOrders;
  final double totalDiscount;
  final double foodCost;
  final double grossMargin;
  final double wastageCost;
  final double netProfit;
  final double grossMarginPercentage;
  final double netProfitPercentage;
  final bool isProfitable;

  BranchDashboardSummaryModel({
    required this.revenue,
    required this.orderCount,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.paidOrders,
    required this.totalDiscount,
    required this.foodCost,
    required this.grossMargin,
    this.wastageCost = 0.0,
    this.netProfit = 0.0,
    this.grossMarginPercentage = 0.0,
    this.netProfitPercentage = 0.0,
    this.isProfitable = true,
  });

  factory BranchDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final rev = (json['revenue'] as num?)?.toDouble() ?? 0.0;
    final discount = (json['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final fc = (json['foodCost'] as num?)?.toDouble() ?? 0.0;
    final gm = (json['grossMargin'] as num?)?.toDouble() ?? (rev - fc);
    final wc = (json['wastageCost'] as num?)?.toDouble() ?? 0.0;
    final np = (json['netProfit'] as num?)?.toDouble() ?? (gm - wc);
    final gmPct = (json['grossMarginPercentage'] as num?)?.toDouble() ?? (rev > 0 ? (gm / rev * 100) : 0.0);
    final npPct = (json['netProfitPercentage'] as num?)?.toDouble() ?? (rev > 0 ? (np / rev * 100) : 0.0);
    final isProf = json['isProfitable'] as bool? ?? (np >= 0);

    return BranchDashboardSummaryModel(
      revenue: rev,
      orderCount: json['orderCount'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      paidOrders: json['paidOrders'] as int? ?? 0,
      totalDiscount: discount,
      foodCost: fc,
      grossMargin: gm,
      wastageCost: wc,
      netProfit: np,
      grossMarginPercentage: gmPct,
      netProfitPercentage: npPct,
      isProfitable: isProf,
    );
  }
}

class BranchInventoryItem {
  final String id;
  final String branchId;
  final String branchName;
  final String ingredientId;
  final String ingredientName;
  final String unit;
  final double currentStock;
  final double minStockLevel;

  BranchInventoryItem({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.ingredientId,
    required this.ingredientName,
    required this.unit,
    required this.currentStock,
    required this.minStockLevel,
  });

  factory BranchInventoryItem.fromJson(Map<String, dynamic> json) {
    return BranchInventoryItem(
      id: json['id'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      ingredientId: json['ingredientId'] as String? ?? '',
      ingredientName: json['ingredientName'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TransferTicketModel {
  final String id;
  final String ticketCode;
  final String? sourceBranchId;
  final String? sourceBranchName;
  final String targetBranchId;
  final String targetBranchName;
  final String ingredientId;
  final String ingredientName;
  final String unit;
  final double quantity;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;

  TransferTicketModel({
    required this.id,
    required this.ticketCode,
    this.sourceBranchId,
    this.sourceBranchName,
    required this.targetBranchId,
    required this.targetBranchName,
    required this.ingredientId,
    required this.ingredientName,
    required this.unit,
    required this.quantity,
    required this.status,
    this.note,
    required this.createdAt,
    this.dispatchedAt,
    this.completedAt,
  });

  factory TransferTicketModel.fromJson(Map<String, dynamic> json) {
    return TransferTicketModel(
      id: json['id'] as String? ?? '',
      ticketCode: json['ticketCode'] as String? ?? '',
      sourceBranchId: json['sourceBranchId'] as String?,
      sourceBranchName: json['sourceBranchName'] as String?,
      targetBranchId: json['targetBranchId'] as String? ?? '',
      targetBranchName: json['targetBranchName'] as String? ?? '',
      ingredientId: json['ingredientId'] as String? ?? '',
      ingredientName: json['ingredientName'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      dispatchedAt: json['dispatchedAt'] != null ? DateTime.parse(json['dispatchedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }
}



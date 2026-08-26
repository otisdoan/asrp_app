import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/analytics_model.dart';
import '../data/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

final brandDashboardFutureProvider = FutureProvider.autoDispose.family<BrandDashboardResponseModel, DateTimeRange?>((ref, dateRange) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getBrandDashboard(
    from: dateRange?.start,
    to: dateRange?.end,
  );
});

class BranchAnalyticsParams {
  final String branchId;
  final DateTimeRange? dateRange;

  BranchAnalyticsParams({required this.branchId, this.dateRange});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchAnalyticsParams &&
          runtimeType == other.runtimeType &&
          branchId == other.branchId &&
          dateRange?.start == other.dateRange?.start &&
          dateRange?.end == other.dateRange?.end;

  @override
  int get hashCode => branchId.hashCode ^ (dateRange?.start.hashCode ?? 0) ^ (dateRange?.end.hashCode ?? 0);
}

/// Provider cho chi tiết báo cáo chi nhánh
final branchDashboardDetailProvider = FutureProvider.autoDispose.family<BranchDashboardDetailModel, BranchAnalyticsParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getBranchDashboardDetail(
    params.branchId,
    from: params.dateRange?.start,
    to: params.dateRange?.end,
  );
});

/// Provider cho xu hướng doanh thu chi nhánh
final salesTrendProvider = FutureProvider.autoDispose.family<SalesTrendModel, BranchAnalyticsParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getSalesTrend(
    from: params.dateRange?.start,
    to: params.dateRange?.end,
    branchId: params.branchId,
  );
});

/// Provider cho hiệu suất thực đơn của chi nhánh
final menuPerformanceProvider = FutureProvider.autoDispose.family<MenuPerformanceModel, BranchAnalyticsParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getMenuPerformance(
    from: params.dateRange?.start,
    to: params.dateRange?.end,
    branchId: params.branchId,
  );
});

/// Provider cho hiệu suất vận hành của chi nhánh
final operationsAnalyticsProvider = FutureProvider.autoDispose.family<OperationsAnalyticsModel, BranchAnalyticsParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getOperations(
    from: params.dateRange?.start,
    to: params.dateRange?.end,
    branchId: params.branchId,
  );
});

/// Provider cho hao hụt kho của chi nhánh
final inventoryWastageProvider = FutureProvider.autoDispose.family<InventoryWastageAnalyticsModel, BranchAnalyticsParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getInventoryWastage(
    from: params.dateRange?.start,
    to: params.dateRange?.end,
    branchId: params.branchId,
  );
});

/// Provider cho tồn kho của chi nhánh
final branchInventoriesProvider = FutureProvider.autoDispose.family<List<BranchInventoryItem>, String>((ref, branchId) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getBranchInventory(branchId);
});

class TransferTicketParams {
  final String? branchId;
  final String? status;

  TransferTicketParams({this.branchId, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferTicketParams &&
          runtimeType == other.runtimeType &&
          branchId == other.branchId &&
          status == other.status;

  @override
  int get hashCode => (branchId?.hashCode ?? 0) ^ (status?.hashCode ?? 0);
}

final transferTicketsProvider = FutureProvider.autoDispose.family<List<TransferTicketModel>, TransferTicketParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getTransferTickets(
    branchId: params.branchId,
    status: params.status,
  );
});



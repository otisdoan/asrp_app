import '../../core/network/dio_client.dart';
import '../models/analytics_model.dart';

class AnalyticsRepository {
  final DioClient _dioClient = DioClient();

  /// Lấy dữ liệu báo cáo thương hiệu (GET /api/analytics/brand-dashboard)
  Future<BrandDashboardResponseModel> getBrandDashboard({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (from != null) {
        queryParams['from'] = from.toUtc().toIso8601String();
      }
      if (to != null) {
        queryParams['to'] = to.toUtc().toIso8601String();
      }

      print('[AnalyticsRepository] Fetching brand dashboard with queryParams: $queryParams');
      final response = await _dioClient.dio.get(
        '/analytics/brand-dashboard',
        queryParameters: queryParams,
      );

      print('[AnalyticsRepository] Response status code: ${response.statusCode}');
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        if (rawData['data'] is Map<String, dynamic>) {
          return BrandDashboardResponseModel.fromJson(rawData['data'] as Map<String, dynamic>);
        }
        return BrandDashboardResponseModel.fromJson(rawData);
      }
      throw Exception('Invalid response structure for brand dashboard');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching brand dashboard: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết báo cáo chi nhánh (GET /api/analytics/branches/{branchId}/dashboard)
  Future<BranchDashboardDetailModel> getBranchDashboardDetail(
    String branchId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (from != null) {
        queryParams['from'] = from.toUtc().toIso8601String();
      }
      if (to != null) {
        queryParams['to'] = to.toUtc().toIso8601String();
      }

      print('[AnalyticsRepository] Fetching branch dashboard detail for $branchId: $queryParams');
      final response = await _dioClient.dio.get(
        '/analytics/branches/$branchId/dashboard',
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataMap = rawData['data'] is Map<String, dynamic> 
            ? rawData['data'] as Map<String, dynamic> 
            : rawData;
        return BranchDashboardDetailModel.fromJson(dataMap);
      }
      throw Exception('Invalid response structure for branch dashboard detail');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching branch dashboard detail: $e');
      rethrow;
    }
  }

  /// Lấy xu hướng doanh số (GET /api/analytics/sales-trend)
  Future<SalesTrendModel> getSalesTrend({
    DateTime? from,
    DateTime? to,
    String? granularity,
    String? branchId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      if (granularity != null) queryParams['granularity'] = granularity;
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') queryParams['branchId'] = branchId;

      print('[AnalyticsRepository] Fetching sales trend: $queryParams');
      final response = await _dioClient.dio.get(
        '/analytics/sales-trend',
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataMap = rawData['data'] is Map<String, dynamic> 
            ? rawData['data'] as Map<String, dynamic> 
            : rawData;
        return SalesTrendModel.fromJson(dataMap);
      }
      throw Exception('Invalid response structure for sales trend');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching sales trend: $e');
      rethrow;
    }
  }

  /// Lấy hiệu suất thực đơn (GET /api/analytics/menu-performance)
  Future<MenuPerformanceModel> getMenuPerformance({
    DateTime? from,
    DateTime? to,
    String? branchId,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'limit': limit};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') queryParams['branchId'] = branchId;

      print('[AnalyticsRepository] Fetching menu performance: $queryParams');
      final response = await _dioClient.dio.get(
        '/analytics/menu-performance',
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataMap = rawData['data'] is Map<String, dynamic> 
            ? rawData['data'] as Map<String, dynamic> 
            : rawData;
        return MenuPerformanceModel.fromJson(dataMap);
      }
      throw Exception('Invalid response structure for menu performance');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching menu performance: $e');
      rethrow;
    }
  }

  /// Lấy hiệu suất vận hành (GET /api/analytics/operations)
  Future<OperationsAnalyticsModel> getOperations({
    DateTime? from,
    DateTime? to,
    String? branchId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') queryParams['branchId'] = branchId;

      print('[AnalyticsRepository] Fetching operations: $queryParams');
      final response = await _dioClient.dio.get(
        '/analytics/operations',
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataMap = rawData['data'] is Map<String, dynamic> 
            ? rawData['data'] as Map<String, dynamic> 
            : rawData;
        return OperationsAnalyticsModel.fromJson(dataMap);
      }
      throw Exception('Invalid response structure for operations');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching operations: $e');
      rethrow;
    }
  }

  /// Lấy hao hụt kho (GET /api/analytics/inventory-wastage)
  Future<InventoryWastageAnalyticsModel> getInventoryWastage({
    DateTime? from,
    DateTime? to,
    String? branchId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') queryParams['branchId'] = branchId;

      print('[AnalyticsRepository] Fetching inventory wastage: $queryParams');
      final response = await _dioClient.dio.get(
        '/analytics/inventory-wastage',
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        final dataMap = rawData['data'] is Map<String, dynamic> 
            ? rawData['data'] as Map<String, dynamic> 
            : rawData;
        return InventoryWastageAnalyticsModel.fromJson(dataMap);
      }
      throw Exception('Invalid response structure for inventory wastage');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching inventory wastage: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tồn kho của chi nhánh (GET /api/inventory/branches/{branchId})
  Future<List<BranchInventoryItem>> getBranchInventory(String branchId) async {
    try {
      print('[AnalyticsRepository] Fetching branch inventory for $branchId');
      final response = await _dioClient.dio.get('/inventory/branches/$branchId');
      final rawData = response.data;
      if (rawData is List) {
        return rawData.map((e) => BranchInventoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (rawData is Map<String, dynamic> && rawData['data'] is List) {
        return (rawData['data'] as List).map((e) => BranchInventoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Invalid response structure for branch inventory');
    } catch (e) {
      print('[AnalyticsRepository] Error fetching branch inventory: $e');
      rethrow;
    }
  }

  /// Điều phối nguyên vật liệu giữa các chi nhánh (POST /api/inventory/transfer)
  Future<void> transferInventory({
    required String ingredientId,
    required String sourceBranchId,
    required String targetBranchId,
    required double quantity,
  }) async {
    try {
      print('[AnalyticsRepository] Transferring $quantity of $ingredientId from $sourceBranchId to $targetBranchId');
      await _dioClient.dio.post(
        '/inventory/transfer',
        data: {
          'ingredientId': ingredientId,
          'sourceBranchId': sourceBranchId,
          'targetBranchId': targetBranchId,
          'quantity': quantity,
        },
      );
    } catch (e) {
      print('[AnalyticsRepository] Error transferring inventory: $e');
      rethrow;
    }
  }

  /// Phương án 1: Chi nhánh tạo Yêu cầu cấp nguyên liệu (POST /api/inventory/transfer-requests)
  Future<TransferTicketModel> createTransferRequest({
    required String ingredientId,
    required String targetBranchId,
    String? sourceBranchId,
    required double quantity,
    String? note,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/inventory/transfer-requests',
        data: {
          'ingredientId': ingredientId,
          'targetBranchId': targetBranchId,
          if (sourceBranchId != null && sourceBranchId.isNotEmpty) 'sourceBranchId': sourceBranchId,
          'quantity': quantity,
          if (note != null) 'note': note,
        },
      );
      return TransferTicketModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('[AnalyticsRepository] Error creating transfer request: $e');
      rethrow;
    }
  }

  /// Phương án 2: Tổng quản trị tạo lệnh xuất trực tiếp (POST /api/inventory/transfer-direct)
  Future<TransferTicketModel> createDirectTransfer({
    required String ingredientId,
    required String sourceBranchId,
    required String targetBranchId,
    required double quantity,
    String? note,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/inventory/transfer-direct',
        data: {
          'ingredientId': ingredientId,
          'sourceBranchId': sourceBranchId,
          'targetBranchId': targetBranchId,
          'quantity': quantity,
          if (note != null) 'note': note,
        },
      );
      return TransferTicketModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('[AnalyticsRepository] Error creating direct transfer: $e');
      rethrow;
    }
  }

  /// Duyệt Yêu cầu cấp hàng (POST /api/inventory/transfer-tickets/{id}/approve)
  Future<TransferTicketModel> approveTransferTicket({
    required String ticketId,
    required String sourceBranchId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/inventory/transfer-tickets/$ticketId/approve',
        data: {
          'sourceBranchId': sourceBranchId,
        },
      );
      return TransferTicketModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('[AnalyticsRepository] Error approving transfer ticket: $e');
      rethrow;
    }
  }

  /// Từ chối Yêu cầu cấp hàng (POST /api/inventory/transfer-tickets/{id}/reject)
  Future<TransferTicketModel> rejectTransferTicket({required String ticketId}) async {
    try {
      final response = await _dioClient.dio.post('/inventory/transfer-tickets/$ticketId/reject');
      return TransferTicketModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('[AnalyticsRepository] Error rejecting transfer ticket: $e');
      rethrow;
    }
  }

  /// Chi nhánh Đích xác nhận nhận hàng (POST /api/inventory/transfer-tickets/{id}/confirm-delivery)
  Future<TransferTicketModel> confirmDelivery({required String ticketId}) async {
    try {
      final response = await _dioClient.dio.post('/inventory/transfer-tickets/$ticketId/confirm-delivery');
      return TransferTicketModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('[AnalyticsRepository] Error confirming delivery: $e');
      rethrow;
    }
  }

  /// Lấy danh sách phiếu chuyển hàng (GET /api/inventory/transfer-tickets)
  Future<List<TransferTicketModel>> getTransferTickets({
    String? branchId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null && branchId.isNotEmpty) queryParams['branchId'] = branchId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _dioClient.dio.get(
        '/inventory/transfer-tickets',
        queryParameters: queryParams,
      );

      final rawData = response.data;
      if (rawData is List) {
        return rawData.map((e) => TransferTicketModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('[AnalyticsRepository] Error fetching transfer tickets: $e');
      return [];
    }
  }
}



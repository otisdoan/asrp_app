import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/branch_api_model.dart';

class BranchRemoteDataSource {
  final Dio _dio;

  BranchRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<PaginatedBranchResponse<BranchSummaryResponse>> getBranches({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive = true,
  }) async {
    try {
      final response = await _dio.get('/branches', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null) 'search': search,
        if (isActive != null) 'isActive': isActive,
      });

      // Handle standard response wrapper if needed, assume response.data is the exact JSON
      final data = response.data['data'] ?? response.data;
      return PaginatedBranchResponse.fromJson(
        data,
        (json) => BranchSummaryResponse.fromJson(json),
      );
    } catch (e, stack) {
      print('[BranchRemoteDataSource] getBranches Error: $e');
      print(stack);
      rethrow;
    }
  }

  Future<PaginatedBranchResponse<BranchSummaryResponse>> getNearbyBranches({
    required double latitude,
    required double longitude,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get('/branches/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'pageSize': pageSize,
      });

      final data = response.data['data'] ?? response.data;
      return PaginatedBranchResponse.fromJson(
        data,
        (json) => BranchSummaryResponse.fromJson(json), // Use NearbyBranchResponse if different, mapped to BranchSummaryResponse for simplicity since UI needs same model
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<BranchDetailResponse> getBranchDetail(String id) async {
    try {
      final response = await _dio.get('/branches/$id');
      final data = response.data['data'] ?? response.data;
      return BranchDetailResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
}

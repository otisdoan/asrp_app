import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/branch_model.dart';

class BranchRepository {
  final DioClient _dioClient = DioClient();

  /// Lấy danh sách chi nhánh từ Backend (GET /api/branches).
  Future<List<BranchListItemModel>> getBranches() async {
    final response = await _dioClient.dio.get(ApiConstants.branches);
    print('[BranchRepository] Response status code: ${response.statusCode}');

    final rawData = response.data;
    List<dynamic> list = [];
    
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData['branches'] is List) {
        list = rawData['branches'] as List;
      } else if (rawData['items'] is List) {
        list = rawData['items'] as List;
      }
    }
    
    return list
        .map((item) => BranchListItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lấy chi tiết chi nhánh từ Backend (GET /api/branches/{id}).
  Future<BranchDetailModel> getBranchDetail(String id) async {
    final response = await _dioClient.dio.get(ApiConstants.branchDetail(id));
    print('[BranchRepository] Detail Response status: ${response.statusCode}');

    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        return BranchDetailModel.fromJson(rawData['data'] as Map<String, dynamic>);
      }
      return BranchDetailModel.fromJson(rawData);
    }
    throw Exception('Invalid response structure for branch detail');
  }
}

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/branch_model.dart';

class BranchRepository {
  BranchRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  final DioClient _dioClient;

  Future<List<BranchListItemModel>> getBranches() async {
    try {
      print('[Audit Branch] 1. Bắt đầu gọi API: GET /api/branches...');
      final response = await _dioClient.dio.get(ApiConstants.getBranches);
      print('[Audit Branch] 2. API trả về StatusCode: ${response.statusCode}');
      print('[Audit Branch] 3. Dữ liệu thô: ${response.data}');
      final branchList = _extractBranchList(response.data);

      return branchList
          .whereType<Map<String, dynamic>>()
          .map(BranchListItemModel.fromJson)
          .toList();
    } on DioException catch (error) {
      print('[Audit Branch] 🔴 Lỗi API: $error');
      throw Exception(_extractErrorMessage(error));
    } catch (error) {
      print('[Audit Branch] 🔴 Lỗi API: $error');
      throw Exception('Không thể tải danh sách chi nhánh: $error');
    }
  }

  List<dynamic> _extractBranchList(dynamic rawData) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      final candidates = [
        rawData['data'],
        rawData['branches'],
        rawData['items'],
        rawData['results'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate;
        }
      }
    }

    return const [];
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] ?? responseData['error'];
      if (message != null) {
        return 'Không thể tải danh sách chi nhánh: $message';
      }
    }

    final dioMessage = error.message;
    if (dioMessage != null && dioMessage.isNotEmpty) {
      return 'Không thể tải danh sách chi nhánh: $dioMessage';
    }

    return 'Không thể tải danh sách chi nhánh';
  }
}

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/menu_item_model.dart';

class MenuRepository {
  MenuRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  final DioClient _dioClient;

  Future<List<MenuItemModel>> getMenuItems(String branchId) async {
    try {
      print(
          '[Audit Menu] 1. Bắt đầu gọi API: GET /api/branches/$branchId/menu-items...');
      final response =
          await _dioClient.dio.get(ApiConstants.getMenuByBranch(branchId));
      print('[Audit Menu] 2. API trả về StatusCode: ${response.statusCode}');
      print('[Audit Menu] 3. Parse data: ${response.data}');

      final items = _extractItems(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(MenuItemModel.fromJson)
          .toList();
    } on DioException catch (error) {
      print('[Audit Menu] 4. Báo lỗi: $error');
      throw Exception(_extractErrorMessage(error));
    } catch (error) {
      print('[Audit Menu] 4. Báo lỗi: $error');
      throw Exception('Không thể tải danh sách món ăn: $error');
    }
  }

  List<dynamic> _extractItems(dynamic rawData) {
    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      final candidates = [
        rawData['items'],
        rawData['data'],
        rawData['menuItems'],
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
        return 'Không thể tải danh sách món ăn: $message';
      }
    }

    final dioMessage = error.message;
    if (dioMessage != null && dioMessage.isNotEmpty) {
      return 'Không thể tải danh sách món ăn: $dioMessage';
    }

    return 'Không thể tải danh sách món ăn';
  }
}

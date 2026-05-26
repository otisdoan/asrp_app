import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  final DioClient _dioClient;

  /// Lấy danh sách danh mục từ Backend (GET /api/categories).
  Future<List<CategoryModel>> getCategories() async {
    try {
      // print('[Audit Categories] 1. Bắt đầu gọi API: GET /api/categories...');
      final response = await _dioClient.dio.get(ApiConstants.categories);
      print(
          '[Audit Categories] 2. API trả về StatusCode: ${response.statusCode}');
      // print('[Audit Categories] 3. Dữ liệu thô: ${response.data}');

      final rawData = response.data;
      List<dynamic> list = [];

      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map<String, dynamic>) {
        if (rawData['data'] is List) {
          list = rawData['data'] as List;
        } else if (rawData['categories'] is List) {
          list = rawData['categories'] as List;
        } else if (rawData['items'] is List) {
          list = rawData['items'] as List;
        }
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => CategoryModel.fromJson(item))
          .toList();
    } catch (e) {
      print('[Audit Categories] 🔴 Lỗi API: $e');
      rethrow;
    }
  }
}

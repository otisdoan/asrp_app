import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final DioClient _dioClient = DioClient();

  /// Lấy danh sách danh mục từ Backend (GET /api/categories).
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dioClient.dio.get(ApiConstants.categories);
    print('[CategoryRepository] Response status code: ${response.statusCode}');

    final rawData = response.data;
    List<dynamic> list = [];
    
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData['categories'] is List) {
        list = rawData['categories'] as List;
      }
    }
    
    return list
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

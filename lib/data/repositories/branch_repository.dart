
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/branch_model.dart';
import '../models/branch_search_model.dart';

class BranchRepository {
  final DioClient _dioClient = DioClient();

  /// Lấy danh sách chi nhánh từ Backend (GET /api/branches).
  Future<List<BranchListItemModel>> getBranches({String? brandId, int pageSize = 100}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'pageSize': pageSize,
      };
      if (brandId != null && brandId.isNotEmpty) {
        queryParams['brandId'] = brandId;
      }

      final response = await _dioClient.dio.get(
        ApiConstants.branches,
        queryParameters: queryParams,
      );

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
    } catch (e) {
      print('[BranchRepository] Error getting branches: $e');
      return [];
    }
  }

  /// Lấy danh sách chi nhánh thuộc Thương hiệu của Admin hiện tại (GET /api/brands/me/branches).
  Future<List<BranchListItemModel>> getMyBrandBranches() async {
    try {
      final response = await _dioClient.dio.get('/brands/me/branches');
      final rawData = response.data;
      List<dynamic> list = [];
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map<String, dynamic>) {
        if (rawData['items'] is List) {
          list = rawData['items'] as List;
        } else if (rawData['data'] is List) {
          list = rawData['data'] as List;
        }
      }
      return list
          .map((item) => BranchListItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[BranchRepository] Error getting my brand branches: $e');
      return [];
    }
  }

  /// Lấy danh mục menu của chi nhánh (GET /api/branches/{id}/menu).
  Future<List<BranchMenuSectionModel>> getBranchMenu(String branchId) async {
    final response = await _dioClient.dio.get(ApiConstants.branchMenu(branchId));

    final rawData = response.data;
    List<dynamic> list = [];

    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map<String, dynamic>) {
      if (rawData['categories'] is List) {
        list = rawData['categories'] as List;
      } else if (rawData['data'] is List) {
        list = rawData['data'] as List;
      } else if (rawData['menu'] is List) {
        list = rawData['menu'] as List;
      } else if (rawData['items'] is List) {
        list = rawData['items'] as List;
      }
    }

    return list
        .map((item) => BranchMenuSectionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lấy chi tiết chi nhánh từ Backend bao gồm cả menu (GET /api/branches/{id} & GET /api/branches/{id}/menu).
  Future<BranchDetailModel> getBranchDetail(String id) async {
    final responses = await Future.wait([
      _dioClient.dio.get(ApiConstants.branchDetail(id)),
      getBranchMenu(id).catchError((err, stack) {
        return <BranchMenuSectionModel>[];
      }),
    ]);

    final detailResponse = responses[0] as dynamic;
    final menuData = responses[1] as List<BranchMenuSectionModel>;

    final rawData = detailResponse.data;
    BranchDetailModel detail;
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        detail = BranchDetailModel.fromJson(rawData['data'] as Map<String, dynamic>);
      } else {
        detail = BranchDetailModel.fromJson(rawData);
      }
    } else {
      throw Exception('Invalid response structure for branch detail');
    }

    return detail.copyWith(menu: menuData);
  }

  /// Lấy đánh giá của món ăn (GET /api/branches/{branchId}/menu-items/{menuItemId}/reviews)
  Future<List<Map<String, dynamic>>> getMenuItemReviews({
    required String branchId,
    required String menuItemId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/branches/$branchId/menu-items/$menuItemId/reviews',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      print('[BranchRepository] Reviews Response status: ${response.statusCode}');
      
      final rawData = response.data;
      List<dynamic> list = [];
      
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map<String, dynamic>) {
        if (rawData['data'] is List) {
          list = rawData['data'] as List;
        } else if (rawData['items'] is List) {
          list = rawData['items'] as List;
        } else if (rawData['reviews'] is List) {
          list = rawData['reviews'] as List;
        }
      }
      
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[BranchRepository] Error getting menu item reviews: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết món ăn (GET /api/branches/{branchId}/menu-items/{menuItemId})
  Future<Map<String, dynamic>> getMenuItemDetail({
    required String branchId,
    required String menuItemId,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/branches/$branchId/menu-items/$menuItemId',
      );
      print('[BranchRepository] MenuItem Detail Response status: ${response.statusCode}');
      
      final rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        if (rawData['data'] is Map<String, dynamic>) {
          return rawData['data'] as Map<String, dynamic>;
        }
        return rawData;
      }
      throw Exception('Invalid response structure for menu item detail');
    } catch (e) {
      print('[BranchRepository] Error getting menu item detail: $e');
      rethrow;
    }
  }

  /// Lấy gợi ý hoàn thành tự động (autocomplete) khi gõ tìm kiếm (GET /api/branches/search/autocomplete).
  Future<List<String>> getSearchAutocomplete(String query) async {
    final response = await _dioClient.dio.get(
      '/branches/search/autocomplete',
      queryParameters: {'query': query},
    );
    final list = response.data as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// Lấy gợi ý tìm kiếm nhanh (GET /api/branches/search/quick-suggestions).
  Future<List<String>> getQuickSearchSuggestions() async {
    final response = await _dioClient.dio.get('/branches/search/quick-suggestions');
    final list = response.data as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// Lấy danh sách chi nhánh được đề xuất (GET /api/branches/search/recommended).
  Future<List<BranchListItemModel>> getRecommendedBranches({double? latitude, double? longitude}) async {
    final response = await _dioClient.dio.get(
      '/branches/search/recommended',
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    final list = response.data as List? ?? [];
    return list
        .map((item) => BranchListItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lấy kết quả tìm kiếm (GET /api/branches/search/results).
  Future<List<BranchSearchResultModel>> getSearchResults({
    String? query,
    String? sortBy,
    double? latitude,
    double? longitude,
    double? minRating,
    bool? hasPromo,
    double? maxPrice,
  }) async {
    final response = await _dioClient.dio.get(
      '/branches/search/results',
      queryParameters: {
        if (query != null) 'query': query,
        if (sortBy != null) 'sortBy': sortBy,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (minRating != null) 'minRating': minRating,
        if (hasPromo != null) 'hasPromo': hasPromo,
        if (maxPrice != null) 'maxPrice': maxPrice,
      },
    );
    final list = response.data as List? ?? [];
    return list
        .map((item) => BranchSearchResultModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lấy lịch sử tìm kiếm từ Database (GET /api/branches/search/history).
  Future<List<String>> getSearchHistory() async {
    final response = await _dioClient.dio.get('/branches/search/history');
    final list = response.data as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// Lưu từ khóa tìm kiếm vào Database (POST /api/branches/search/history).
  Future<void> addSearchHistory(String query) async {
    await _dioClient.dio.post(
      '/branches/search/history',
      queryParameters: {'query': query},
    );
  }

  /// Xóa toàn bộ lịch sử tìm kiếm trong Database (DELETE /api/branches/search/history).
  Future<void> clearSearchHistory() async {
    await _dioClient.dio.delete('/branches/search/history');
  }
}

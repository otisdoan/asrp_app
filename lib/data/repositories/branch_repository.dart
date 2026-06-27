import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/branch_model.dart';

class BranchRepository {
  final DioClient _dioClient = DioClient();

  /// Lấy danh sách chi nhánh từ Backend (GET /api/branches).
  Future<List<BranchListItemModel>> getBranches({String? brandId}) async {
    final token = _dioClient.accessToken;
    print('[BranchRepository] --- START GET BRANCHES ---');
    print('[BranchRepository] Access Token: ${token != null ? (token.length > 25 ? "${token.substring(0, 15)}... (len: ${token.length})" : token) : "NULL"}');
    
    final Map<String, dynamic> queryParams = {};
    if (brandId != null && brandId.isNotEmpty) {
      queryParams['brandId'] = brandId;
    }

    final response = await _dioClient.dio.get(
      ApiConstants.branches,
      queryParameters: queryParams,
    );
    print('[BranchRepository] Response status code: ${response.statusCode}');
    print('[BranchRepository] Response data: ${response.data}');
    print('[BranchRepository] --- END GET BRANCHES ---');

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

  /// Lấy danh mục menu của chi nhánh (GET /api/branches/{id}/menu).
  Future<List<BranchMenuSectionModel>> getBranchMenu(String branchId) async {
    final response = await _dioClient.dio.get(ApiConstants.branchMenu(branchId));
    print('[BranchRepository] Menu Response status: ${response.statusCode}');

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
      getBranchMenu(id).catchError((err) {
        print('[BranchRepository] Error getting branch menu: $err');
        return <BranchMenuSectionModel>[];
      }),
    ]);

    final detailResponse = responses[0] as dynamic;
    final menuData = responses[1] as List<BranchMenuSectionModel>;

    print('[BranchRepository] Detail Response status: ${detailResponse.statusCode}');

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
}

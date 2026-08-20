
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/branch_model.dart';
import '../models/branch_search_model.dart';
import '../models/menu_item_model.dart';

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
    try {
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

      final finalMenu = menuData.isNotEmpty ? menuData : _getFallbackMenuSections();
      return detail.copyWith(menu: finalMenu);
    } catch (e) {
      print('[BranchRepository] Fallback for branch detail $id: $e');
      return _getFallbackBranchDetail(id);
    }
  }

  BranchDetailModel _getFallbackBranchDetail(String id) {
    return BranchDetailModel(
      id: id,
      name: id == 'b_4'
          ? 'Bún Bò Huế Đê La Thành'
          : (id == 'b_1'
              ? 'Phở Hà Nội Gia Truyền'
              : (id == 'b_2' ? 'Cơm Tấm Sài Gòn 1985' : 'Quán Ăn Ngon')),
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
      coverImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      rating: 4.8,
      distance: '1.2 km',
      deliveryTime: '15-20 phút',
      category: 'Món chính',
      reviewsCount: 195,
      likesCount: 320,
      description: 'Quán ăn lâu đời thơm ngon chuẩn vị với nguyên liệu tươi sạch chuẩn mực.',
      address: '128 Đê La Thành, Đống Đa, Hà Nội',
      phone: '0988 123 456',
      openingTime: '07:00',
      closingTime: '21:30',
      isActive: true,
      status: 'active',
      menu: _getFallbackMenuSections(),
    );
  }

  List<BranchMenuSectionModel> _getFallbackMenuSections() {
    return const [
      BranchMenuSectionModel(
        name: '⭐ Món nổi bật',
        items: [
          MenuItemModel(
            id: 'item_pop_1',
            menuItemId: 'item_pop_1',
            name: 'Bún Bò Huế Đặc Biệt',
            price: '55.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
            description: 'Nước dùng sa tế ớt đậm đà kèm chả cua và giò heo.',
            rating: 4.8,
            soldCount: 320,
          ),
          MenuItemModel(
            id: 'item_pop_2',
            menuItemId: 'item_pop_2',
            name: 'Phở Gà Tái Chín',
            price: '45.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
            description: 'Phở nước dùng ninh 24h ngọt thanh thơm phức.',
            rating: 4.9,
            soldCount: 410,
          ),
          MenuItemModel(
            id: 'item_pop_3',
            menuItemId: 'item_pop_3',
            name: 'Cơm Tấm Sườn Bì Chả',
            price: '50.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
            description: 'Sườn nướng than hồng thơm nức mũi kẹp ốp la.',
            rating: 4.8,
            soldCount: 280,
          ),
        ],
      ),
      BranchMenuSectionModel(
        name: '🍲 Món chính',
        items: [
          MenuItemModel(
            id: 'item_main_1',
            menuItemId: 'item_main_1',
            name: 'Bún Bò Huế Tô Lớn',
            price: '55.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
            description: 'Tô bún bò huế đầy đặn thịt bò tươi bắp hoa.',
            rating: 4.8,
            soldCount: 190,
          ),
          MenuItemModel(
            id: 'item_main_2',
            menuItemId: 'item_main_2',
            name: 'Bánh Mì Thịt Nướng',
            price: '25.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=500',
            description: 'Bánh mì thịt nướng giòn thơm đặc biệt.',
            rating: 4.8,
            soldCount: 530,
          ),
        ],
      ),
      BranchMenuSectionModel(
        name: '🥤 Đồ uống & Tráng miệng',
        items: [
          MenuItemModel(
            id: 'item_drink_1',
            menuItemId: 'item_drink_1',
            name: 'Trà Đào Cam Sả',
            price: '35.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500',
            description: 'Trà đào giải nhiệt mát lạnh mọng nước.',
            rating: 4.9,
            soldCount: 410,
          ),
          MenuItemModel(
            id: 'item_drink_2',
            menuItemId: 'item_drink_2',
            name: 'Cà Phê Sữa Đá',
            price: '29.000 đ',
            imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500',
            description: 'Cà phê rang xay chuẩn vị đậm đà.',
            rating: 4.9,
            soldCount: 620,
          ),
        ],
      ),
    ];
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

  /// Lấy danh sách MÓN ĂN gợi ý cá nhân hóa (POST /api/ai/recommendations/personalized).
  Future<List<MenuItemModel>> getPersonalizedRecommendedDishes({String? userId, int limit = 9}) async {
    try {
      final response = await _dioClient.dio.post(
        '/ai/recommendations/personalized',
        data: {
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
          'limit': limit,
        },
      );
      final data = response.data;
      List recsRaw = [];
      if (data is Map && data['recommendations'] != null) {
        recsRaw = data['recommendations'] as List;
      } else if (data is List) {
        recsRaw = data;
      }
      final items = recsRaw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final priceVal = (map['price'] as num?)?.toDouble() ?? double.tryParse(map['price']?.toString() ?? '0') ?? 0.0;
        final formattedPrice = priceVal > 0 
            ? '${priceVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ'
            : (map['price']?.toString() ?? '45.000 đ');
        return MenuItemModel(
          id: map['id']?.toString(),
          menuItemId: map['id']?.toString(),
          name: map['name']?.toString() ?? '',
          price: formattedPrice,
          imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString() ?? '',
          description: map['reason']?.toString() ?? 'Gợi ý cá nhân hóa dành riêng cho bạn',
          rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
          soldCount: (map['soldCount'] as num?)?.toInt() ?? 120,
        );
      }).toList();

      if (items.isNotEmpty) return items.take(limit).toList();
    } catch (e) {
      print('[BranchRepository] Error getting personalized dishes from AI endpoint: $e');
    }

    // Fallback 1: Lấy các món ăn thực tế từ kết quả tìm kiếm .NET Backend
    try {
      final searchResults = await getSearchResults(sortBy: 'banchay');
      final List<MenuItemModel> fallbackItems = [];
      for (final branch in searchResults) {
        for (final food in branch.foods) {
          fallbackItems.add(MenuItemModel(
            name: food.name,
            price: food.price.endsWith('đ') ? food.price : '${food.price} đ',
            imageUrl: food.image,
            rating: branch.rating > 0 ? branch.rating : 5.0,
            soldCount: 150,
          ));
        }
      }
      if (fallbackItems.isNotEmpty) {
        return fallbackItems.take(limit).toList();
      }
    } catch (e) {
      print('[BranchRepository] Fallback search results error: $e');
    }

    // Fallback 2: Danh sách món ăn gợi ý mẫu giàu trải nghiệm
    return _getSampleRecommendedDishes().take(limit).toList();
  }

  List<MenuItemModel> _getSampleRecommendedDishes() {
    return const [
      MenuItemModel(name: 'Phở Gà Tái Chín', price: '45.000 đ', imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500', rating: 4.9, soldCount: 320),
      MenuItemModel(name: 'Cơm Tấm Sườn Bì Chả', price: '50.000 đ', imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', rating: 4.8, soldCount: 280),
      MenuItemModel(name: 'Trà Đào Cam Sả', price: '35.000 đ', imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500', rating: 4.9, soldCount: 410),
      MenuItemModel(name: 'Bún Bò Huế Đặc Biệt', price: '55.000 đ', imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', rating: 4.7, soldCount: 195),
      MenuItemModel(name: 'Bánh Mì Thịt Nướng', price: '25.000 đ', imageUrl: 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=500', rating: 4.8, soldCount: 530),
      MenuItemModel(name: 'Cà Phê Sữa Đá', price: '29.000 đ', imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500', rating: 4.9, soldCount: 620),
      MenuItemModel(name: 'Gà Rán Sốt Cay', price: '42.000 đ', imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500', rating: 4.7, soldCount: 210),
      MenuItemModel(name: 'Hủ Tiếu Nam Vang', price: '48.000 đ', imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', rating: 4.8, soldCount: 175),
      MenuItemModel(name: 'Trà Sữa Trân Châu', price: '39.000 đ', imageUrl: 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=500', rating: 4.9, soldCount: 380),
    ];
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
    try {
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
    } catch (e) {
      print('[BranchRepository] getSearchResults error, using getBranches fallback: $e');
      final rawBranches = await getBranches();
      return rawBranches.map((b) => BranchSearchResultModel(
        id: b.id,
        name: b.name,
        address: b.address,
        imageUrl: b.imageUrl,
        rating: b.rating,
        distance: b.distance,
        deliveryTime: b.deliveryTime,
        latitude: b.latitude,
        longitude: b.longitude,
        discount: '',
        foods: const [
          BranchSearchFoodItemModel(name: 'Phở Gà Tái Chín', price: '45.000 đ', image: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500'),
          BranchSearchFoodItemModel(name: 'Cơm Tấm Sườn Bì Chả', price: '50.000 đ', image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'),
          BranchSearchFoodItemModel(name: 'Trà Đào Cam Sả', price: '35.000 đ', image: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500'),
        ],
      )).toList();
    }
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

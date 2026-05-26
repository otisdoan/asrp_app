import '../../models/branch_model.dart';
import '../../models/menu_item_model.dart';
import '../data_sources/branch_remote_data_source.dart';
import '../models/branch_api_model.dart';

class BranchRepository {
  final BranchRemoteDataSource _remoteDataSource;

  BranchRepository({BranchRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? BranchRemoteDataSource();

  Future<List<BranchListItemModel>> getBranches({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final response = await _remoteDataSource.getBranches(
      page: page,
      pageSize: pageSize,
      search: search,
    );

    return response.items.map((apiModel) => _mapSummaryToAppModel(apiModel)).toList();
  }

  Future<List<BranchListItemModel>> getNearbyBranches({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _remoteDataSource.getNearbyBranches(
      latitude: latitude,
      longitude: longitude,
    );

    return response.items.map((apiModel) => _mapSummaryToAppModel(apiModel)).toList();
  }

  Future<BranchDetailModel> getBranchDetail(String id) async {
    final response = await _remoteDataSource.getBranchDetail(id);
    return _mapDetailToAppModel(response);
  }

  BranchListItemModel _mapSummaryToAppModel(BranchSummaryResponse apiModel) {
    return BranchListItemModel(
      id: apiModel.id,
      name: apiModel.name,
      imageUrl: apiModel.imageUrl,
      rating: apiModel.averageRating > 0 ? apiModel.averageRating : apiModel.rating,
      distance: apiModel.distance,
      deliveryTime: apiModel.deliveryTime,
      category: apiModel.category,
      reviewsCount: apiModel.reviewCount > 0 ? apiModel.reviewCount : apiModel.reviewsCount,
      promo: apiModel.promo ?? (apiModel.promos?.isNotEmpty == true ? apiModel.promos!.first : null),
      discount: apiModel.discount,
      tag: apiModel.tag,
      adLabel: apiModel.adLabel,
      isFavorite: apiModel.isFavorite,
      displayOrder: apiModel.displayOrder,
    );
  }

  BranchDetailModel _mapDetailToAppModel(BranchDetailResponse apiModel) {
    List<BranchMenuSectionModel> menuSections = [];
    
    if (apiModel.menu != null && apiModel.menu!.isNotEmpty) {
      // Group menu items by categoryName
      final Map<String, List<MenuItemModel>> groupedMenu = {};
      
      for (var item in apiModel.menu!) {
        final categoryName = item.categoryName.isNotEmpty ? item.categoryName : 'Khác';
        if (!groupedMenu.containsKey(categoryName)) {
          groupedMenu[categoryName] = [];
        }
        
        groupedMenu[categoryName]!.add(MenuItemModel(
          slug: item.slug,
          imageUrl: item.imageUrl,
          name: item.name,
          description: item.description,
          price: item.priceAmount > 0 ? item.priceAmount.toString() : item.price,
          badge: item.badgeLabel != null ? BadgeModel(
            label: item.badgeLabel!,
            type: _mapBadgeType(item.badgeType),
          ) : null,
          rating: item.rating,
          soldCount: item.soldCount,
          likesCount: item.likesCount,
        ));
      }

      groupedMenu.forEach((key, value) {
        menuSections.add(BranchMenuSectionModel(name: key, items: value));
      });
    }

    return BranchDetailModel(
      id: apiModel.id,
      name: apiModel.name,
      imageUrl: apiModel.imageUrl,
      rating: apiModel.averageRating > 0 ? apiModel.averageRating : apiModel.rating,
      distance: apiModel.distance,
      deliveryTime: apiModel.deliveryTime,
      category: apiModel.category,
      reviewsCount: apiModel.reviewCount > 0 ? apiModel.reviewCount : apiModel.reviewsCount,
      isFavorite: apiModel.isFavorite,
      likesCount: apiModel.likesCount,
      address: apiModel.address,
      description: apiModel.description,
      latitude: apiModel.latitude,
      longitude: apiModel.longitude,
      isActive: apiModel.isActive,
      promos: apiModel.promos,
      menu: menuSections.isNotEmpty ? menuSections : null,
    );
  }

  BadgeType _mapBadgeType(String? typeStr) {
    if (typeStr == null) return BadgeType.hot;
    switch (typeStr.toLowerCase()) {
      case 'new':
      case 'newitem':
        return BadgeType.newItem;
      case 'best':
        return BadgeType.best;
      case 'sale':
        return BadgeType.sale;
      default:
        return BadgeType.hot;
    }
  }
}

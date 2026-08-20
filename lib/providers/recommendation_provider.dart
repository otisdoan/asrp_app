import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/branch_model.dart';
import '../data/models/recommendation_card_item_model.dart';
import '../core/services/location_service.dart';
import 'branch_provider.dart';

/// Provider theo dõi từ khóa tìm kiếm gần đây để tính toán Search Intent
final searchIntentProvider = StateProvider<String?>((ref) => null);

/// Provider chính quản lý Động cơ Gợi ý Cá nhân hóa (Context-Aware Hybrid Recommendation Engine)
final personalizedRecommendationsProvider = FutureProvider<List<RecommendedCardItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  final location = ref.watch(userLocationProvider);

  // Fetch real branches from repository — 100% same data source as "Ở gần bạn" & "Deal hời"
  List<BranchListItemModel> realBranches = [];
  try {
    realBranches = await repository.getBranches();
  } catch (e) {
    print('[RecommendationProvider] Error fetching real branches: $e');
  }

  if (realBranches.isEmpty) {
    return const [];
  }

  final List<RecommendedCardItemModel> items = [];

  for (int i = 0; i < realBranches.length; i++) {
    final b = realBranches[i];

    // Calculate EXACT SAME distance string as "Ở gần bạn" and "Deal hời"
    final displayDistance = LocationService.calculateBranchDistance(
      userLocation: location,
      branchLat: b.latitude,
      branchLng: b.longitude,
      branchAddress: b.address,
      branchName: b.name,
      fallbackDistance: b.distance,
    );

    final displayTime = LocationService.calculateDeliveryTime(
      deliveryTime: b.deliveryTime,
      distanceStr: displayDistance,
    );

    String dishName = 'Món ăn đặc sắc';
    double priceVal = 45000;
    String priceDisplay = '45.000 đ';
    String imageUrl = b.imageUrl;
    String category = 'Món chính';
    bool foundMenu = false;

    try {
      final menuSections = await repository.getBranchMenu(b.id);
      for (final sec in menuSections) {
        for (final food in sec.items) {
          // 1. Filter out dishes that are sold out, disabled, or missing recipe configurations
          if (food.isSoldOut || !food.isAvailable || !food.hasRecipes) {
            continue;
          }

          final lowerFoodName = food.name.toLowerCase().trim();
          // 2. Filter out test/invalid dishes (like "bún thơm", "test")
          if (lowerFoodName.isEmpty || lowerFoodName.contains('bún thơm') || lowerFoodName.contains('test')) {
            continue;
          }

          // 3. Filter out unrealistic test prices (< 5,000đ like 500đ)
          final parsedPrice = double.tryParse(food.price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          if (parsedPrice < 5000) {
            continue;
          }

          dishName = food.name;
          imageUrl = food.imageUrl.isNotEmpty ? food.imageUrl : b.imageUrl;
          priceVal = parsedPrice;
          priceDisplay = food.price.contains('đ') ? food.price : '${food.price} đ';
          category = sec.name.replaceAll('⭐', '').replaceAll('🍲', '').replaceAll('🥤', '').trim();
          foundMenu = true;
          break;
        }
        if (foundMenu) break;
      }
    } catch (e) {
      print('[RecommendationProvider] Error fetching menu for branch ${b.id}: $e');
    }

    // Skip branch if no real, valid, available menu item was found (NEVER insert fake fallback dishes)
    if (!foundMenu) {
      continue;
    }

    items.add(
      RecommendedCardItemModel(
        id: '${b.id}_$dishName',
        branchId: b.id,
        branchName: b.name,
        dishName: dishName,
        price: priceVal,
        priceDisplay: priceDisplay,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        rating: b.rating > 0 ? b.rating : 4.8,
        reviewsCount: b.reviewsCount ?? 120,
        distance: displayDistance,
        deliveryTime: displayTime,
        category: category,
        recommendationReason: 'Món ngon nổi bật tại ${b.name}',
      ),
    );
  }

  // 🛡️ Sort items by distance ascending so the closest stores to user appear FIRST!
  items.sort((a, b) {
    final distA = parseDistanceInKm(a.distance);
    final distB = parseDistanceInKm(b.distance);
    return distA.compareTo(distB);
  });

  return items.take(9).toList();
});

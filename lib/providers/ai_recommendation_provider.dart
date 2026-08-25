import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import 'auth_provider.dart';

class AiRecommendationModel {
  final String branchId;
  final String menuItemId;
  final String storeName;
  final String dishName;
  final int priceAmount;
  final String priceText;
  final String distance;
  final String deliveryTime;
  final double rating;
  final int reviews;
  final String tag;
  final String imageUrl;

  AiRecommendationModel({
    required this.branchId,
    required this.menuItemId,
    required this.storeName,
    required this.dishName,
    required this.priceAmount,
    required this.priceText,
    required this.distance,
    required this.deliveryTime,
    required this.rating,
    required this.reviews,
    required this.tag,
    required this.imageUrl,
  });

  factory AiRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AiRecommendationModel(
      branchId: json['branchId']?.toString() ?? '',
      menuItemId: json['menuItemId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? 'DineX Store',
      dishName: json['dishName']?.toString() ?? '',
      priceAmount: (json['priceAmount'] as num?)?.toInt() ?? 0,
      priceText: json['priceText']?.toString() ?? '0đ',
      distance: json['distance']?.toString() ?? '1.0 km',
      deliveryTime: json['deliveryTime']?.toString() ?? '20-30 phút',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      tag: json['tag']?.toString() ?? 'Được đề xuất',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

final personalizedRecommendationsProvider = FutureProvider.autoDispose<List<AiRecommendationModel>>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) {
    return [];
  }

  try {
    final response = await DioClient().dio.get('/ai/recommendations/personalized', queryParameters: {'limit': 10});
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List).map((e) => AiRecommendationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    print('[AiRecommendationProvider] Error fetching recommendations: $e');
  }
  return [];
});


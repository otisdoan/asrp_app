import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoriteShopsProvider = StateNotifierProvider<FavoriteShopsNotifier, List<String>>((ref) {
  return FavoriteShopsNotifier();
});

class FavoriteShopsNotifier extends StateNotifier<List<String>> {
  FavoriteShopsNotifier() : super([]); // Mặc định trống để xem giao diện Empty State trước

  void toggleFavorite(String storeName) {
    if (state.contains(storeName)) {
      state = state.where((name) => name != storeName).toList();
    } else {
      state = [...state, storeName];
    }
  }

  bool isFavorite(String storeName) {
    return state.contains(storeName);
  }
}

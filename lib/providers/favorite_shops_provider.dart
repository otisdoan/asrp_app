import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final favoriteShopsProvider = StateNotifierProvider<FavoriteShopsNotifier, List<String>>((ref) {
  return FavoriteShopsNotifier();
});

class FavoriteShopsNotifier extends StateNotifier<List<String>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _storageKey = 'local_favorite_shops';

  FavoriteShopsNotifier() : super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonStr);
        state = list.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('[FavoriteShopsNotifier] Error loading favorites: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonStr = json.encode(state);
      await _storage.write(key: _storageKey, value: jsonStr);
    } catch (e) {
      debugPrint('[FavoriteShopsNotifier] Error saving favorites: $e');
    }
  }

  void toggleFavorite(String storeName) {
    if (state.contains(storeName)) {
      state = state.where((name) => name != storeName).toList();
    } else {
      state = [...state, storeName];
    }
    _saveToStorage();
  }

  bool isFavorite(String storeName) {
    return state.contains(storeName);
  }
}

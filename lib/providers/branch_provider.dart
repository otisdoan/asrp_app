import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/branch_model.dart';
import '../data/models/branch_search_model.dart';
import '../data/models/menu_item_model.dart';
import '../data/repositories/branch_repository.dart';
import 'auth_provider.dart';

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});

final branchesFutureProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getBranches();
});

final branchDetailFutureProvider = FutureProvider.family<BranchDetailModel, String>((ref, id) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getBranchDetail(id);
});

final userLocationProvider = StateProvider<Position?>((ref) => null);
final userAddressNameProvider = StateProvider<String?>((ref) => null);

final searchAutocompleteProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getSearchAutocomplete(query);
});

final quickSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getQuickSearchSuggestions();
});

double parseDistanceInKm(String? distStr) {
  if (distStr == null) return 999999.0;
  final str = distStr.toLowerCase().trim();
  if (str.isEmpty || str == 'n/a') return 999999.0;
  if (str.endsWith('km')) {
    final val = double.tryParse(str.replaceAll('km', '').trim());
    return val ?? 999999.0;
  }
  if (str.endsWith('m')) {
    final val = double.tryParse(str.replaceAll('m', '').trim());
    return val != null ? val / 1000.0 : 999999.0;
  }
  final val = double.tryParse(str);
  return val ?? 999999.0;
}

final recommendedBranchesProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  final location = ref.watch(userLocationProvider);
  final list = await repository.getRecommendedBranches(
    latitude: location?.latitude,
    longitude: location?.longitude,
  );
  if (location != null) {
    final validList = list.where((b) {
      final distStr = b.distance.trim().toLowerCase();
      return distStr.isNotEmpty &&
             distStr != 'n/a' &&
             distStr != '0 km' &&
             distStr != '0.0 km';
    }).toList();

    validList.sort((a, b) =>
        parseDistanceInKm(a.distance).compareTo(parseDistanceInKm(b.distance)));

    return validList;
  }
  return list;
});

final personalizedDishesProvider = FutureProvider<List<MenuItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser?.id;
  return repository.getPersonalizedRecommendedDishes(userId: userId, limit: 9);
});

class SearchQueryParams {
  final String query;
  final String sortBy;
  final double? minRating;
  final bool? hasPromo;
  final double? maxPrice;

  SearchQueryParams({
    required this.query,
    required this.sortBy,
    this.minRating,
    this.hasPromo,
    this.maxPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQueryParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          sortBy == other.sortBy &&
          minRating == other.minRating &&
          hasPromo == other.hasPromo &&
          maxPrice == other.maxPrice;

  @override
  int get hashCode =>
      query.hashCode ^
      sortBy.hashCode ^
      (minRating?.hashCode ?? 0) ^
      (hasPromo?.hashCode ?? 0) ^
      (maxPrice?.hashCode ?? 0);
}

final searchResultsProvider = FutureProvider.family<List<BranchSearchResultModel>, SearchQueryParams>((ref, params) async {
  final repository = ref.watch(branchRepositoryProvider);
  final location = ref.watch(userLocationProvider);
  final results = await repository.getSearchResults(
    query: params.query,
    sortBy: params.sortBy,
    latitude: location?.latitude,
    longitude: location?.longitude,
    minRating: params.minRating,
    hasPromo: params.hasPromo,
    maxPrice: params.maxPrice,
  );
  if (location != null) {
    return results.where((b) => b.distance != null && b.distance.trim().isNotEmpty && b.distance != 'N/A' && b.distance != '0 km' && b.distance != '0.0 km').toList();
  }
  return results;
});

class SearchHistoryNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final BranchRepository _repository;

  SearchHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final list = await _repository.getSearchHistory();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addQuery(String query) async {
    if (query.trim().isEmpty) return;
    try {
      await _repository.addSearchHistory(query);
      await loadHistory();
    } catch (e) {
      print('Error adding search history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearSearchHistory();
      state = const AsyncValue.data([]);
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, AsyncValue<List<String>>>((ref) {
  final repository = ref.watch(branchRepositoryProvider);
  return SearchHistoryNotifier(repository);
});

final myBrandBranchesFutureProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getMyBrandBranches();
});

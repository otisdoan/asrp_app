import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/branch_model.dart';
import '../data/models/branch_search_model.dart';
import '../data/repositories/branch_repository.dart';

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

final searchAutocompleteProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getSearchAutocomplete(query);
});

final quickSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  return repository.getQuickSearchSuggestions();
});

final recommendedBranchesProvider = FutureProvider<List<BranchListItemModel>>((ref) async {
  final repository = ref.watch(branchRepositoryProvider);
  final location = ref.watch(userLocationProvider);
  return repository.getRecommendedBranches(
    latitude: location?.latitude,
    longitude: location?.longitude,
  );
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
  return repository.getSearchResults(
    query: params.query,
    sortBy: params.sortBy,
    latitude: location?.latitude,
    longitude: location?.longitude,
    minRating: params.minRating,
    hasPromo: params.hasPromo,
    maxPrice: params.maxPrice,
  );
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

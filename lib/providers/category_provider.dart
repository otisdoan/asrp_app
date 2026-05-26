import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesFutureProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final categories = await repository.getCategories();
  // print(
  //     '[Audit Categories] Provider đã nhận được ${categories.length} danh mục từ API.');
  return categories;
});

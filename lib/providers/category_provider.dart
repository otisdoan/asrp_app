import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesFutureProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return const [
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1003',
      name: 'Cơm',
      imageUrl: 'https://i-giadinh.vnecdn.net/2023/11/11/Bc5Thnhphm15-1699693079-2955-1699693082.jpg',
    ),
    CategoryModel(
      id: 'ec3f1f78-2b21-4a30-80e8-14a374220f13',
      name: 'Phở',
      imageUrl: 'https://asrp-image.s3.ap-southeast-1.amazonaws.com/categories/ec3f1f78-2b21-4a30-80e8-14a374220f13/2026/06/77bd7af24dce42e79c4e302a4a2f09e5.jpg',
    ),
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1002',
      name: 'Bún',
      imageUrl: 'https://monngonmoingay.com/wp-content/uploads/2018/08/bun-bo-gio-heo-500-min.jpg',
    ),
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1007',
      name: 'Hủ tiếu',
      imageUrl: 'https://cooponline.vn/tin-tuc/wp-content/uploads/2025/10/hu-tieu-nam-vang-cong-thuc-nau-chuan-vi-sai-gon-nuoc-dung-ngot-thanh-dam-da-topping.png',
    ),
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1012',
      name: 'Ăn vặt',
      imageUrl: 'https://asrp-image.s3.ap-southeast-1.amazonaws.com/categories/e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1012/2026/06/be86c1bfc2864284ab8f78d89522dcec.jpg',
    ),
    CategoryModel(
      id: 'b09f7c22-222d-47c9-b11f-d9c9688680c5',
      name: 'Đồ uống',
      imageUrl: 'https://asrp-image.s3.ap-southeast-1.amazonaws.com/categories/b09f7c22-222d-47c9-b11f-d9c9688680c5/2026/06/c5178a8af27b4ea686d827c58fa5715d.jpg',
    ),
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1005',
      name: 'Tráng miệng',
      imageUrl: 'https://asrp-image.s3.ap-southeast-1.amazonaws.com/categories/e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1005/2026/06/3e3dd00f20604d1a8cc60b94f38e2006.jpg',
    ),
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1006',
      name: 'Món khai vị',
      imageUrl: 'https://asrp-image.s3.ap-southeast-1.amazonaws.com/categories/e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1006/2026/06/6745a7aff5914cd8846085c29f9010dc.jpg',
    ),
    CategoryModel(
      id: 'e528a1ba-1b91-4d1a-8e2b-ec1d2e1b1008',
      name: 'Món gỏi',
      imageUrl: 'https://cdn.tgdd.vn/2021/09/CookRecipe/Avatar/goi-buoi-tom-thit-thumbnail.jpg',
    ),
    CategoryModel(
      id: '477bce74-a761-48cc-92d2-b0f9fbb20750',
      name: 'Phở xào & trộn',
      imageUrl: 'https://asrp-image.s3.ap-southeast-1.amazonaws.com/categories/477bce74-a761-48cc-92d2-b0f9fbb20750/2026/06/d740cc7c8a4b40cebf669f374d26d44a.jpg',
    ),
  ];
});

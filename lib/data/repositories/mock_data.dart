import '../models/menu_item_model.dart';
import '../models/product_detail_model.dart';

class MockData {
  MockData._();

  // ===== PROMO BANNERS =====
  static const List<Map<String, String>> promoBanners = [
    {
      'tag': 'HOT HÔM NAY',
      'title': 'Giảm 20% phở đặc biệt',
      'desc': 'Áp dụng từ 11:00 – 14:00 hôm nay',
      'image': 'assets/images/pho.jpg',
    },
    {
      'tag': 'MÓN MỚI',
      'title': 'Phở bò tái nạm',
      'desc': 'Nước dùng hầm 12 tiếng, thơm đậm vị',
      'image': 'assets/images/pho_bo.png',
    },
    {
      'tag': 'COMBO TIẾT KIỆM',
      'title': 'Cơm trưa chỉ từ 45k',
      'desc': 'Cơm sườn, cơm gà, cơm tấm đầy đủ',
      'image': 'assets/images/com.webp',
    },
    {
      'tag': 'FREESHIP',
      'title': 'Trà sữa mua 1 tặng 1',
      'desc': 'Áp dụng cho đơn từ 2 ly trở lên',
      'image': 'assets/images/tra_sua.jpg',
    },
  ];

  // ===== QUICK FILTERS =====
  static const List<Map<String, String>> quickFilters = [
    {'imageUrl': 'assets/images/pho.jpg', 'name': 'Đang hot'},
    {'imageUrl': 'assets/images/pho_bo.png', 'name': 'Món mới'},
    {'imageUrl': 'assets/images/com.webp', 'name': 'Best seller'},
    {'imageUrl': 'assets/images/tra_sua.jpg', 'name': 'Combo tiết kiệm'},
  ];

  // ===== AI SUGGESTIONS =====
  static final List<MenuItemModel> aiSuggestions = [
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Phở bò tái',
      price: '85,000đ',
      description: 'Bạn hay gọi',
      badge: BadgeModel(label: 'Bạn hay gọi', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Nước mía tươi',
      price: '25,000đ',
      description: 'Hay kết hợp',
      badge: BadgeModel(label: 'Hay kết hợp', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Bánh quẩy',
      price: '10,000đ',
      description: 'Phổ biến nhất',
      badge: BadgeModel(label: 'Phổ biến nhất', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Trà đá chanh',
      price: '20,000đ',
      description: 'Hay kết hợp',
      badge: BadgeModel(label: 'Hay kết hợp', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Phở bò tái',
      price: '85,000đ',
      description: 'Bạn hay gọi',
      badge: BadgeModel(label: 'Bạn hay gọi', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Nước mía tươi',
      price: '25,000đ',
      description: 'Hay kết hợp',
      badge: BadgeModel(label: 'Hay kết hợp', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Bánh quẩy',
      price: '10,000đ',
      description: 'Phổ biến nhất',
      badge: BadgeModel(label: 'Phổ biến nhất', type: BadgeType.sale),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Trà đá chanh',
      price: '20,000đ',
      description: 'Hay kết hợp',
      badge: BadgeModel(label: 'Hay kết hợp', type: BadgeType.sale),
    ),
  ];

  // ===== HOT ITEMS =====
  static final List<MenuItemModel> hotItems = [
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Phở bò đặc biệt',
      price: '95,000đ',
      description: 'Nước dùng ninh 12 tiếng',
      badge: BadgeModel(label: 'HOT', type: BadgeType.hot),
      rating: 5,
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Bún bò Huế',
      price: '80,000đ',
      description: 'Sả huế, thịt bò đến từ Huế',
      badge: BadgeModel(label: 'HOT', type: BadgeType.hot),
      rating: 4,
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Cơm gà Hải Nam',
      price: '75,000đ',
      description: 'Cơm dầu gà, thịt gà hầm mềm',
      rating: 4,
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Sinh tố bơ',
      price: '45,000đ',
      description: 'Bơ sáp, sữa đặc, đá xay mịn',
      rating: 5,
    ),
  ];

  // ===== COMBOS =====
  static const List<Map<String, dynamic>> combos = [
    {
      'imageUrls': [
        'assets/images/pho.jpg',
        'assets/images/tra_sua.jpg',
        'assets/images/com.webp'
      ],
      'name': 'Combo phở đồng quê',
      'description': 'Phở bò + Nước mía + Bánh quẩy',
      'price': 115000,
      'originalPrice': 130000,
      'saving': 'Tiết kiệm 15k',
      'badge': 'COMBO',
    },
    {
      'imageUrls': [
        'assets/images/pho_bo.png',
        'assets/images/tra_sua.jpg',
        'assets/images/com.webp'
      ],
      'name': 'Combo bún Huế đặc biệt',
      'description': 'Bún bò Huế + trà đá + chè đậu',
      'price': 105000,
      'originalPrice': 120000,
      'saving': 'Tiết kiệm 15k',
      'badge': 'BEST',
    },
  ];

  // ===== NEW ITEMS =====
  static final List<MenuItemModel> newItems = [
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Mì Ý sốt bò băm',
      price: '95,000đ',
      description: 'Thịt bò băm, sốt cà chua, phô mai',
      badge: BadgeModel(label: 'MỚI', type: BadgeType.newItem),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Salad ức gà',
      price: '65,000đ',
      description: 'Ục gà áp chảo, rau xà lách tươi',
      badge: BadgeModel(label: 'MỚI', type: BadgeType.newItem),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Há cảo tôm',
      price: '45,000đ',
      description: 'Nhân tôm tươi, vỏ mỏng trong',
      badge: BadgeModel(label: 'MỚI', type: BadgeType.newItem),
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Tôm chiên xù',
      price: '95,000đ',
      description: 'Tôm sú tươi chiên giòn',
      badge: BadgeModel(label: 'MỚI', type: BadgeType.newItem),
    ),
  ];

  // ===== BEST SELLERS =====
  static const List<Map<String, dynamic>> bestSellers = [
    {
      'rank': 1,
      'imageUrl': 'assets/images/pho.jpg',
      'name': 'Phở bò đặc biệt',
      'price': '95,000đ',
      'sold': 1240
    },
    {
      'rank': 2,
      'imageUrl': 'assets/images/pho_bo.png',
      'name': 'Bún bò Huế',
      'price': '80,000đ',
      'sold': 985
    },
    {
      'rank': 3,
      'imageUrl': 'assets/images/com.webp',
      'name': 'Cơm gà Hải Nam',
      'price': '75,000đ',
      'sold': 763
    },
  ];

  // ===== MINI PROMOS =====
  static const List<Map<String, dynamic>> miniPromos = [
    {
      'imageUrl': 'assets/images/com.webp',
      'title': 'Tích điểm thành viên',
      'desc': 'Mọi đơn hàng đều được tích điểm',
      'bgColor': 0xFFFAEEDA,
      'textColor': 0xFF854F0B,
    },
    {
      'imageUrl': 'assets/images/tra_sua.jpg',
      'title': 'Ưu đãi sinh nhật',
      'desc': 'Giảm 15% trong ngày sinh nhật',
      'bgColor': 0xFFFAECE7,
      'textColor': 0xFF993C1D,
    },
  ];



  // ===== MOCK PRODUCT DETAIL =====
  // ===== MOCK PRODUCT DETAIL =====
  static ProductDetailModel getProductDetail(String slug) {
    return ProductDetailModel(
      slug: slug,
      imageUrl: 'assets/images/pho.jpg',
      name: 'Phở bò đặc biệt',
      priceDisplay: '95.000đ',
      priceAmount: 95000,
      description:
          'Nước dùng ninh 12 tiếng, thịt bò tươi thượng hạng, bánh phở dai ngon đặc trưng.',
      soldCount: '1240',
      likesCount: 128,
      sizes: const [
        ProductSizeModel(name: 'Nhỏ', price: 80000),
        ProductSizeModel(name: 'Vừa', price: 95000),
        ProductSizeModel(name: 'Lớn', price: 120000),
      ],
      toppings: const [
        ProductToppingModel(name: 'Thêm thịt bò', price: 25000),
        ProductToppingModel(name: 'Thêm gầu bò', price: 20000),
        ProductToppingModel(name: 'Thêm trứng chần', price: 10000),
        ProductToppingModel(name: 'Thêm bánh quẩy', price: 8000),
      ],
      reviews: const [
        ProductReviewModel(
          user: ReviewUserModel(name: 'N.T.H'),
          rating: 5,
          date: '3 ngày trước',
          content:
              'Nước dùng rất ngon, ngọt thanh tự nhiên. Thịt bò tươi và mềm. Sẽ quay lại ủng hộ thường xuyên!',
          images: [],
          reply:
              'Cảm ơn bạn đã ủng hộ nhà hàng. Rất mong được phục vụ bạn lần sau!',
          likes: 12,
        ),
        ProductReviewModel(
          user: ReviewUserModel(name: 'Trần Văn B.'),
          rating: 4,
          date: '1 tuần trước',
          content:
              'Phở ngon nhưng hơi đông nên phục vụ hơi lâu chút. Bù lại đồ ăn chất lượng.',
          images: [],
          likes: 5,
        ),
      ],
    );
  }
}

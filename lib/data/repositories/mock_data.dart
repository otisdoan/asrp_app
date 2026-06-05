import '../models/menu_item_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_detail_model.dart';
import '../models/category_model.dart';

class MockData {
  MockData._();

  // ===== PROMO BANNERS =====
  static const List<Map<String, String>> promoBanners = [
    {
      'tag': 'HOT HÔM NAY',
      'title': 'Giảm 20% Phở Đặc Biệt',
      'desc': 'Áp dụng từ 11:00 – 14:00 hôm nay',
      'image': 'assets/images/pho.jpg',
    },
    {
      'tag': 'MÓN MỚI',
      'title': 'Phở Bò Tái Nạm',
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
      'name': 'Combo Phở Đồng Quê',
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
      'name': 'Combo Bún Huế Đặc Biệt',
      'description': 'Bún bò Huế + Trà đá + Chè đậu',
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

  // ===== FULL MENU =====
  static final List<MenuItemModel> fullMenu = [
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Phở bò tái chín',
      description: 'Nước dùng trong, thịt bò tái + chín',
      price: '90,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Phở bò gầu',
      description: 'Gầu giòn, béo ngậy, nước dùng đậm',
      price: '90,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Phở gà ta',
      description: 'Gà ta thả vườn, nước trong thanh ngọt',
      price: '75,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Sinh tố bơ',
      description: 'Bơ sáp, sữa đặc, đá xay mịn',
      price: '45,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Trà sữa trân châu',
      description: 'Trân châu đen, trà Ô Long đậm',
      price: '40,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Bún riêu cua',
      description: 'Cua đồng, cà chua tươi, đậu hủ',
      price: '65,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Cơm gà Hải Nam',
      description: 'Cơm dầu gà, thịt gà hầm mềm',
      price: '75,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Bánh quẩy',
      description: 'Giòn rụm, ăn kèm phở hoặc súp',
      price: '10,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Bánh cuốn nhân thịt',
      description: 'Bánh mỏng mịn, nhân thịt băm hành',
      price: '55,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Cà phê sữa đá',
      description: 'Phin pha thủ công, sữa đặc đậm',
      price: '30,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Trà chanh mật ong',
      description: 'Thanh mát, giàu vitamin C',
      price: '25,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Chè đậu đỏ',
      description: 'Đậu đỏ hầm mềm, nước cốt dừa',
      price: '25,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Burger bò phô mai',
      description: 'Thịt bò Úc, phô mai Cheddar',
      price: '85,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Pizza hải sản',
      description: 'Tôm, mực, thanh cua, phô mai',
      price: '155,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Mì Ý sốt bò băm',
      description: 'Thịt bò băm, sốt cà chua, phô mai',
      price: '95,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Salad ức gà',
      description: 'Ục gà áp chảo, rau xà lách tươi',
      price: '65,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Sashimi cá hồi',
      description: 'Cá hồi Na Uy tươi sống',
      price: '125,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Há cảo tôm',
      description: 'Nhân tôm tươi, vỏ mỏng trong',
      price: '45,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Bento lươn Nhật',
      description: 'Lươn nướng sốt Kabayaki',
      price: '185,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Tôm chiên xù',
      description: 'Tôm sú tươi chiên giòn',
      price: '95,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Xiên que nướng',
      description: 'Thịt xiên nướng kiểu Thái',
      price: '35,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Khoai tây chiên',
      description: 'Khoai tây cắt sợi chiên giòn',
      price: '30,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Bánh táo nướng',
      description: 'Nhân táo quế thơm lừng',
      price: '45,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Kem vani',
      description: 'Kem tươi vani Madagascar',
      price: '25,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Bánh kem dâu',
      description: 'Cốt bánh bông lan, dâu tươi',
      price: '55,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Bánh donut',
      description: 'Phủ socola và cốm màu',
      price: '20,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Nước cam ép',
      description: 'Cam sành tươi ép nguyên chất',
      price: '35,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Nước chanh đá',
      description: 'Chanh tươi, đường phèn',
      price: '20,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Nước ép dứa',
      description: 'Dứa mật ngọt thanh',
      price: '35,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Nước ép dưa hấu',
      description: 'Dưa hấu đỏ ngọt lịm',
      price: '35,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Nước ép nho',
      description: 'Nho đen không hạt ép lạnh',
      price: '45,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/com.webp',
      name: 'Nước ép táo',
      description: 'Táo Mỹ ép nguyên quả',
      price: '40,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho.jpg',
      name: 'Trà đào sả',
      description: 'Miếng đào giòn, hương sả thơm',
      price: '45,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/pho_bo.png',
      name: 'Trà xanh lài',
      description: 'Trà xanh ướp hoa lài thơm ngát',
      price: '30,000đ',
    ),
    const MenuItemModel(
      imageUrl: 'assets/images/tra_sua.jpg',
      name: 'Cà phê đen đá',
      description: 'Cà phê Robusta đậm đà',
      price: '25,000đ',
    ),
  ];

  // ===== MOCK CART ITEMS =====
  static List<CartItemModel> get initialCartItems => [
        CartItemModel(
          id: '1',
          imageUrl: 'assets/images/pho.jpg',
          name: 'Phở bò đặc biệt',
          priceAmount: 95000,
          priceDisplay: '95,000đ',
          quantity: 1,
        ),
        CartItemModel(
          id: '2',
          imageUrl: 'assets/images/tra_sua.jpg',
          name: 'Nước mía tươi',
          priceAmount: 25000,
          priceDisplay: '25,000đ',
          quantity: 1,
        ),
        CartItemModel(
          id: '3',
          imageUrl: 'assets/images/com.webp',
          name: 'Bánh quẩy',
          priceAmount: 10000,
          priceDisplay: '10,000đ',
          quantity: 2,
        ),
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
          user: 'N.T.H',
          rating: 5,
          date: '3 ngày trước',
          content:
              'Nước dùng rất ngon, ngọt thanh tự nhiên. Thịt bò tươi và mềm. Sẽ quay lại ủng hộ thường xuyên!',
          imageCount: 12,
          tags: ['PHỞ BÒ ĐẶC BIỆT'],
          reply:
              'Cảm ơn bạn đã ủng hộ nhà hàng. Rất mong được phục vụ bạn lần sau!',
        ),
        ProductReviewModel(
          user: 'Trần Văn B.',
          rating: 4,
          date: '1 tuần trước',
          content:
              'Phở ngon nhưng hơi đông nên phục vụ hơi lâu chút. Bù lại đồ ăn chất lượng.',
          imageCount: 5,
          tags: ['PHỞ BÒ'],
        ),
      ],
    );
  }
}

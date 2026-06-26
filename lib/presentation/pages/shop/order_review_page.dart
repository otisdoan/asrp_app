import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/top_notification.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/merchant_repository.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';

class OrderReviewPage extends ConsumerStatefulWidget {
  final MockOrder order;

  const OrderReviewPage({super.key, required this.order});

  @override
  ConsumerState<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends ConsumerState<OrderReviewPage> {
  final _orderRepository = OrderRepository();
  bool _isSubmitting = false;
  String? _storeImageUrl;
  List<MockOrderItem> _itemsToReview = [];
  bool _isLoadingItems = true;

  // MenuItem Review States (mapped by orderItemId)
  final Map<String, int> _itemRatings = {};
  final Map<String, TextEditingController> _itemCommentControllers = {};
  final Map<String, List<String>> _selectedItemTags = {};
  final Map<String, List<String>> _itemImages = {};

  // MenuItem Suggestion Tags
  final List<String> _suggestedItemTags = [
    'Ngon miệng',
    'Nhiều topping',
    'Đậm đà',
    'Giá hợp lý',
    'Hình thức đẹp',
    'Sẽ mua lại'
  ];

  @override
  void initState() {
    super.initState();
    _loadBranchDetail();
    _loadReviewableItems();
  }

  Future<void> _loadReviewableItems() async {
    final isMock = widget.order.id.startsWith('mock_');
    if (isMock) {
      if (mounted) {
        setState(() {
          _itemsToReview = widget.order.items;
          for (var item in _itemsToReview) {
            final key = item.id ?? item.name;
            _itemRatings[key] = 5;
            _itemCommentControllers[key] = TextEditingController();
            _selectedItemTags[key] = [];
            _itemImages[key] = [];
          }
          _isLoadingItems = false;
        });
      }
      return;
    }

    try {
      final items = await _orderRepository.getReviewableItems(widget.order.id);
      
      // Check if all items are already reviewed
      final allReviewed = items.isNotEmpty && items.every((x) => x['isReviewed'] == true);
      if (allReviewed) {
        ref.read(reviewedOrdersProvider.notifier).markAsReviewed(widget.order.id);
        if (mounted) {
          TopNotification.show(
            context,
            message: 'Đơn hàng này đã được đánh giá rồi!',
            isError: false,
          );
          Navigator.pop(context, true);
        }
        return;
      }

      // Find the unreviewed items from widget.order.items
      final List<MockOrderItem> unreviewedItems = [];
      for (var raw in items) {
        if (raw['isReviewed'] != true) {
          final orderItemId = raw['orderItemId']?.toString();
          final match = widget.order.items.firstWhere(
            (x) => x.id == orderItemId,
            orElse: () => MockOrderItem(
              id: orderItemId,
              menuItemId: raw['menuItemId']?.toString(),
              name: raw['productName']?.toString() ?? '',
              price: (raw['priceAtTime'] as num?)?.toInt() ?? 0,
              quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
              imageUrl: raw['imageUrl']?.toString(),
            ),
          );
          unreviewedItems.add(match);
        }
      }

      // If for some reason the unreviewed list is empty but not caught by allReviewed
      if (unreviewedItems.isEmpty) {
        unreviewedItems.addAll(widget.order.items);
      }

      if (mounted) {
        setState(() {
          _itemsToReview = unreviewedItems;
          for (var item in _itemsToReview) {
            final key = item.id ?? item.name;
            _itemRatings[key] = 5;
            _itemCommentControllers[key] = TextEditingController();
            _selectedItemTags[key] = [];
            _itemImages[key] = [];
          }
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviewable items: $e');
      if (mounted) {
        setState(() {
          _itemsToReview = widget.order.items;
          for (var item in _itemsToReview) {
            final key = item.id ?? item.name;
            _itemRatings[key] = 5;
            _itemCommentControllers[key] = TextEditingController();
            _selectedItemTags[key] = [];
            _itemImages[key] = [];
          }
          _isLoadingItems = false;
        });
      }
    }
  }

  void _loadBranchDetail() async {
    if (widget.order.branchId.isEmpty || widget.order.branchId.startsWith('mock_')) return;
    try {
      final repo = BranchRepository();
      final detail = await repo.getBranchDetail(widget.order.branchId);
      if (mounted) {
        setState(() {
          _storeImageUrl = detail.imageUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading branch detail: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _itemCommentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Tệ';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Tuyệt vời';
      default:
        return '';
    }
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final isMock = widget.order.id.startsWith('mock_');

      if (isMock) {
        // Mock flow: Simulate API delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          ref.read(reviewedOrdersProvider.notifier).markAsReviewed(widget.order.id);
          TopNotification.show(
            context,
            message: 'Đăng đánh giá thành công (Dữ liệu mẫu)!',
            isError: false,
          );
          Navigator.pop(context, true);
        }
        return;
      }

      // 1. Submit Menu Item Reviews for remaining items
      for (var item in _itemsToReview) {
        final orderItemId = item.id;
        final key = item.id ?? item.name;
        if (orderItemId != null && orderItemId.isNotEmpty) {
          final rating = _itemRatings[key] ?? 5;
          final content = _itemCommentControllers[key]?.text.trim() ?? '';
          final tags = _selectedItemTags[key] ?? [];
          final images = _itemImages[key] ?? [];

          await _orderRepository.createMenuItemReview(
            orderItemId,
            rating: rating,
            content: content.isNotEmpty ? content : null,
            images: images.isNotEmpty ? images : null,
            tags: tags.isNotEmpty ? tags : null,
          );
        }
      }

      ref.read(reviewedOrdersProvider.notifier).markAsReviewed(widget.order.id);

      if (mounted) {
        TopNotification.show(
          context,
          message: 'Cảm ơn bạn đã gửi đánh giá dịch vụ!',
          isError: false,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      final errorMsg = e.toString();
      final isAlreadyReviewed = errorMsg.contains('409') || 
                                errorMsg.contains('already has a review') || 
                                errorMsg.contains('đã được đánh giá trước đó');
      
      if (isAlreadyReviewed) {
        ref.read(reviewedOrdersProvider.notifier).markAsReviewed(widget.order.id);
        if (mounted) {
          TopNotification.show(
            context,
            message: 'Đơn hàng này đã được đánh giá trước đó!',
            isError: false,
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          TopNotification.show(
            context,
            message: 'Lỗi gửi đánh giá: ${errorMsg.replaceAll('Exception: ', '').replaceAll('DioException [bad response]: ', '')}',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Đánh giá đơn hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting || _isLoadingItems
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                  const SizedBox(height: 16),
                  Text(
                    _isSubmitting ? 'Đang đăng đánh giá của bạn...' : 'Đang tải thông tin đơn hàng...',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Restaurant Header Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _storeImageUrl != null && _storeImageUrl!.isNotEmpty
                                ? Image.network(
                                    _storeImageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.storefront_rounded,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  )
                                : const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.storeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mã đơn hàng: ${widget.order.orderNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Menu Items Rating Block
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'ĐÁNH GIÁ MÓN ĂN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ..._itemsToReview.map(
                    (item) {
                      final key = item.id ?? item.name;
                      return _buildItemReviewSection(item, key);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Gửi đánh giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // MenuItem rating section builder
  Widget _buildItemReviewSection(MockOrderItem item, String key) {
    final currentRating = _itemRatings[key] ?? 5;
    final selectedTags = _selectedItemTags[key] ?? [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Info Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.effectiveImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: AppColors.bgWarm,
                    child: const Icon(Icons.fastfood_outlined, size: 24, color: AppColors.textTertiary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.sizeLabel != null && item.sizeLabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Size: ${item.sizeLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.outlineVariant),

          // Rating stars Row
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  final ratingVal = i + 1;
                  final isActive = ratingVal <= currentRating;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _itemRatings[key] = ratingVal;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(
                        isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isActive ? AppColors.star : const Color(0xFFD1D5DB),
                        size: 30,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                _getRatingText(currentRating),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Item Tags selection
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedItemTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTags.remove(tag);
                    } else {
                      selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Review content TextField
          TextField(
            controller: _itemCommentControllers[key],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập nhận xét về món ăn này...',
              hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 12),
          const Text(
            'Hình ảnh thực tế',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          _buildImagePickerGrid(key),
        ],
      ),
    );
  }

  Widget _buildImagePickerGrid(String key) {
    final images = _itemImages[key] ?? [];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...images.map((url) {
          final isNetworkImage = url.startsWith('http://') || url.startsWith('https://');
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isNetworkImage
                    ? Image.network(
                        url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.bgWarm,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.textTertiary),
                        ),
                      )
                    : Image.file(
                        File(url),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.bgWarm,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.broken_image_outlined, size: 24, color: AppColors.textTertiary),
                        ),
                      ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      images.remove(url);
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        if (images.length < 3)
          GestureDetector(
            onTap: () => _pickAndUploadImage(key),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                  width: 1,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(String key) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return;

      final isMockOrder = widget.order.id.startsWith('mock_') || widget.order.branchId.startsWith('mock_');
      final user = ref.read(currentUserProvider);
      final userId = user?.id;
      final isMockUser = userId == null || userId.isEmpty || userId.startsWith('mock_');

      if (isMockOrder || isMockUser) {
        setState(() {
          _itemImages[key]?.add(image.path);
        });
        if (mounted) {
          TopNotification.show(
            context,
            message: 'Đã chọn ảnh món ăn!',
          );
        }
        return;
      }

      // Show uploading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Đang tải ảnh lên...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      final merchantRepo = MerchantRepository();
      final uploadedUrl = await merchantRepo.uploadImage(
        image.path,
        'users/$userId/reviews',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        _itemImages[key]?.add(uploadedUrl);
      });

      if (mounted) {
        TopNotification.show(
          context,
          message: 'Tải ảnh món ăn lên thành công!',
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint('Error picking/uploading image for review: $e');
      if (mounted) {
        TopNotification.show(
          context,
          message: 'Lỗi tải ảnh: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }
}

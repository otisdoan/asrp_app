import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../providers/branch_provider.dart';
import 'store_detail_page.dart';
import 'add_to_cart_page.dart';
import '../../../data/models/topping_selection_model.dart';
import '../../../data/repositories/order_repository.dart';

final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, List<Map<String, dynamic>>>((ref) {
  return ChatHistoryNotifier();
});

class ChatHistoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _storageKey = 'asrp_ai_chat_history_v2';

  ChatHistoryNotifier() : super(_initialMessages()) {
    _loadFromStorage();
  }

  static List<Map<String, dynamic>> _initialMessages() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return [
      {
        'isUser': false,
        'text':
            'Xin chào! Tôi là Trợ lý AI DineX. Tôi có thể đồng hành và hỗ trợ bạn:',
        'time': timeStr,
        'isWelcome': true,
        'showChips': false,
        'recommendations': [
          'Có chi nhánh nào bán phở giá dưới 50k không?',
          'Tìm quán bún chả gần Quận 1',
          'Cho mình 2 tô phở bò tái nạm và 1 ly trà đá ít đường',
          'Có món nước gì giải khát giá rẻ không?'
        ],
      }
    ];
  }

  Future<void> _loadFromStorage() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final dynamic decoded = json.decode(jsonStr);
        if (decoded is List && decoded.isNotEmpty) {
          super.state = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ChatHistoryNotifier] Error loading local history: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonStr = json.encode(state);
      await _storage.write(key: _storageKey, value: jsonStr);
    } catch (e) {
      debugPrint('[ChatHistoryNotifier] Error saving local history: $e');
    }
  }

  @override
  set state(List<Map<String, dynamic>> value) {
    super.state = value;
    _saveToStorage();
  }

  void update(List<Map<String, dynamic>> Function(List<Map<String, dynamic>>) cb) {
    state = cb(state);
  }

  void clearHistory() {
    state = _initialMessages();
  }
}

class ChatAssistantPage extends ConsumerStatefulWidget {
  final String? initialBranchId;
  final String? initialBranchName;
  const ChatAssistantPage({
    super.key,
    this.initialBranchId,
    this.initialBranchName,
  });

  @override
  ConsumerState<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends ConsumerState<ChatAssistantPage> {
  String? _activeBranchId;
  String? _activeBranchName;

  String get _sessionId {
    final user = ref.read(currentUserProvider);
    if (user != null && user.id.isNotEmpty) {
      return 'session_user_${user.id}';
    }
    return 'session_guest_device';
  }

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  double _lastBottomInset = 0;
  bool _isTyping = false;
  OverlayEntry? _activeOverlayEntry;

  @override
  void initState() {
    super.initState();
    _activeBranchId = widget.initialBranchId;
    _activeBranchName = widget.initialBranchName;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(immediate: true);
      _checkAndResumePendingOrders();
      _loadChatHistory();
    });
  }

  void _checkAndResumePendingOrders() {
    final history = ref.read(chatHistoryProvider);
    for (var m in history) {
      if (m['paymentData'] != null && m['paymentData'] is Map) {
        final pd = m['paymentData'] as Map;
        final String orderId = pd['orderId']?.toString() ?? '';
        final bool isPaid = pd['isPaid'] == true;
        if (orderId.isNotEmpty && !isPaid) {
          _startPaymentStatusPolling(orderId);
        }
      }
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await DioClient()
          .dio
          .get('/ai/chat/history', queryParameters: {'sessionId': _sessionId});
      dynamic data = response.data;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is List && data.isNotEmpty) {
        final loadedMessages = data.map((item) {
          Map<String, dynamic>? paymentData;
          if (item['paymentData'] != null && item['paymentData'] is Map) {
            paymentData = Map<String, dynamic>.from(item['paymentData'] as Map);
          }
          return {
            'isUser': item['isUser'] as bool? ?? false,
            'text': item['text'] as String? ?? '',
            'time': item['time'] as String? ?? '',
            'orderDraft': item['orderDraft'],
            'orderPreview': item['orderDraftPreview'] ?? item['orderPreview'],
            'resolvedItems': item['resolvedItems'],
            'recommendations': item['recommendations'],
            'branchRecommendations': item['branchRecommendations'],
            'paymentData': paymentData,
            'showChips': false,
          };
        }).toList();

        ref.read(chatHistoryProvider.notifier).state = loadedMessages;
        _scrollToBottom(immediate: true);
        _checkAndResumePendingOrders();
      }
    } catch (e) {
      debugPrint('[ChatAssistant] Error loading chat history from database: $e');
    }
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử chat'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DioClient().dio.delete('/ai/chat/history',
                    queryParameters: {'sessionId': _sessionId});
              } catch (_) {}
              ref.read(chatHistoryProvider.notifier).clearHistory();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    // Schedule delayed scrolls to account for keyboard animation, dynamic card images and draft previews rendering
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Hide chips in previous messages and add user message
    ref.read(chatHistoryProvider.notifier).update((state) {
      final updated = state.map((msg) => {...msg, 'showChips': false}).toList();
      return [
        ...updated,
        {
          'isUser': true,
          'text': text,
          'time': timeStr,
          'showChips': false,
        }
      ];
    });

    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();

    // 2. Resolve active branch ID & User GPS Location
    String branchId = _activeBranchId ??
        widget.initialBranchId ??
        '00000000-0000-0000-0000-000000000000';
    final userLoc = ref.read(userLocationProvider);

    // 3. Format chat history
    final currentMessages = ref.read(chatHistoryProvider);
    final history = currentMessages
        .where((m) => m['isUser'] != null)
        .map((m) => {
              'role': m['isUser'] == true ? 'user' : 'assistant',
              'content': m['text'] as String,
            })
        .toList();
    // Exclude the last message we just added
    if (history.isNotEmpty) {
      history.removeLast();
    }

    try {
      final payload = {
        'branchId': branchId,
        'sessionId': _sessionId,
        'message': text,
        'chatHistory': history,
        if (userLoc != null)
          'userLocation': {
            'latitude': userLoc.latitude,
            'longitude': userLoc.longitude,
          },
      };

      final response = await DioClient().dio.post(
            '/ai/chat',
            data: payload,
          );

      if (!mounted) return;

      final data = response.data;
      final replyTime = DateTime.now();
      final replyTimeStr =
          '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      // Log API response for debugging
      print('================ [Flutter AI Chat] RESPONSE LOG ================');
      print('User Message: $text');
      print('AI Reply: ${data['reply']}');
      print('Recommendations (keywords): ${data['recommendations']}');
      print('BranchRecommendations (cards): ${data['branchRecommendations']}');
      print('===============================================================');

      // 1. If response has order draft for a branch, remember that branch
      final orderDraft = data['orderDraft'];
      if (orderDraft != null &&
          orderDraft is Map &&
          orderDraft['branchId'] != null) {
        final bId = orderDraft['branchId'].toString();
        if (bId.isNotEmpty && bId != '00000000-0000-0000-0000-000000000000') {
          _activeBranchId = bId;
        }
      }

      // 2. If response has branch recommendations belonging to a single branch (e.g. branch menu query), remember that branch!
      final branchRecs = data['branchRecommendations'] as List<dynamic>?;
      if (branchRecs != null && branchRecs.isNotEmpty) {
        final distinctBranchIds = branchRecs
            .map((r) => r is Map ? r['branchId']?.toString() : null)
            .where((id) =>
                id != null &&
                id.isNotEmpty &&
                id != '00000000-0000-0000-0000-000000000000')
            .toSet();
        if (distinctBranchIds.length == 1) {
          final bId = distinctBranchIds.first!;
          _activeBranchId = bId;
          final firstStoreName =
              (branchRecs.first as Map)['storeName']?.toString();
          if (firstStoreName != null && firstStoreName.isNotEmpty) {
            _activeBranchName = firstStoreName;
          }
        }
      }

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            {
              'isUser': false,
              'text': data['reply'] as String? ??
                  'Xin lỗi, hệ thống đang gặp sự cố.',
              'time': replyTimeStr,
              'orderPreview': data['orderDraftPreview'],
              'orderDraft': data['orderDraft'],
              'resolvedItems': data['resolvedItems'],
              'recommendations': data['recommendations'],
              'branchRecommendations': data['branchRecommendations'],
              'showChips': true,
            }
          ]);

      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      debugPrint('[ChatAssistant] Error calling AI chat: $e');

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            {
              'isUser': false,
              'text':
                  'Không thể kết nối đến máy chủ AI. Vui lòng kiểm tra lại kết nối mạng.',
              'time': timeStr,
              'showChips': true,
            }
          ]);

      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleConfirmDraftAndPay(
      Map<String, dynamic> draft, List<Map<String, dynamic>> displayItems) async {
    final isLoggedIn = ref.read(isAuthenticatedProvider);
    if (!isLoggedIn) {
      _showTopNotification(
        'Vui lòng đăng nhập để hoàn tất đặt món & thanh toán qua PayOS.',
        AppColors.primary,
        Icons.lock_outline,
      );
      return;
    }

    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      String branchId = (draft['branchId'] ?? draft['BranchId'] ?? _activeBranchId)?.toString() ?? '';
      if (branchId.isEmpty ||
          branchId == '00000000-0000-0000-0000-000000000000') {
        ref.read(branchesFutureProvider).whenData((list) {
          if (list.isNotEmpty) {
            branchId = list.first.id;
          }
        });
      }

      final payload = {
        'action': 'CREATE_ORDER',
        'pickupTime': null,
        'items': displayItems.map((it) {
          final toppingIdsRaw = it['toppingIds'];
          List<String>? toppingIdsList;
          if (toppingIdsRaw is List) {
            toppingIdsList = toppingIdsRaw
                .where((e) => e != null && e.toString().isNotEmpty)
                .map((e) => e.toString())
                .toList();
          }
          return {
            'menuItemId':
                it['menuItemId'] ?? '00000000-0000-0000-0000-000000000000',
            'branchId': branchId,
            'quantity': it['quantity'] ?? 1,
            'selectedSizeId': it['sizeId'],
            'note': it['note'],
            'toppingIds': toppingIdsList,
          };
        }).toList(),
      };

      final response = await DioClient().dio.post(
            '/ai/chat/direct-action',
            data: payload,
          );

      if (!mounted) return;

      final data = response.data;
      final paymentInfo = data['data'] ?? data;
      final replyTime = DateTime.now();
      final replyTimeStr =
          '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      final orderId = paymentInfo['orderId']?.toString() ?? '';
      final qrCode = paymentInfo['qrCode']?.toString() ?? '';
      final amount = (paymentInfo['amount'] as num?)?.toDouble() ?? 0.0;
      final checkoutUrl = paymentInfo['checkoutUrl']?.toString() ?? '';
      final bool requiresStaffConfirmation = paymentInfo['requiresStaffConfirmation'] == true;
      final String customMessage = paymentInfo['message']?.toString() ??
          (requiresStaffConfirmation
              ? '📋 Đơn hàng số lượng lớn (≥10 món) của bạn đã được chuyển tới quán. Quán sẽ kiểm tra và xác nhận thời gian chuẩn bị trước khi bạn thanh toán nhé!'
              : 'Mã QR thanh toán PayOS đã được tạo. Bạn vui lòng quét mã bên dưới để thanh toán nhé:');

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            {
              'isUser': false,
              'text': customMessage,
              'time': replyTimeStr,
              'paymentData': {
                'orderId': orderId,
                'qrCode': qrCode,
                'amount': amount,
                'checkoutUrl': checkoutUrl,
                'isPaid': false,
                'requiresStaffConfirmation': requiresStaffConfirmation,
              },
              'showChips': false,
            }
          ]);

      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();

      // Start automatic live status tracking
      _startPaymentStatusPolling(orderId);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[ChatAssistant] Error direct checkout: $e');
      setState(() {
        _isTyping = false;
      });
      _showTopNotification('Không thể tạo mã QR thanh toán: $e',
          AppColors.error, Icons.error_outline);
    }
  }

  Future<void> _customizeItem(Map<String, dynamic> item, int itemIndex,
      String? branchId, String storeName) async {
    final String? mItemId = item['menuItemId']?.toString();
    final String name = item['name']?.toString() ?? 'Món ăn';
    final double unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final String? note = item['note']?.toString();

    if (mItemId != null &&
        mItemId.isNotEmpty &&
        mItemId != '00000000-0000-0000-0000-000000000000') {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => AddToCartPage(
            name: name,
            price: FormatUtils.formatCurrency(unitPrice.toInt()),
            icon: Icons.fastfood_rounded,
            branchId: branchId,
            menuItemId: mItemId,
            initialQuantity: qty,
            initialNote: note,
            isEditing: true,
          ),
        ),
      );

      if (result != null) {
        _applyCustomizedItemUpdate(result, itemIndex, name);
      }
    } else if (branchId != null &&
        branchId.isNotEmpty &&
        branchId != '00000000-0000-0000-0000-000000000000') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreDetailPage(
            branchId: branchId,
            storeName: storeName,
            category: 'Quán ăn',
            rating: 5.0,
            reviews: 100,
            deliveryTime: '20-30 phút',
            distance: '1.0 km',
            icon: Icons.store,
            highlightFoodName: name,
          ),
        ),
      );
    }
  }

  void _applyCustomizedItemUpdate(
      Map<String, dynamic> result, int itemIndex, String itemName) {
    final updatedQty = result['quantity'] as int? ?? 1;
    final updatedTotal = (result['total'] as num?)?.toDouble() ?? 0.0;
    final updatedNote = result['note'] as String?;
    final selectedToppings =
        result['selectedToppings'] as List<ToppingSelectionModel>? ?? [];
    final sizeId = result['sizeId'] as String?;

    String? sizeLabel;
    final toppingLabels = <String>[];
    for (final t in selectedToppings) {
      if (t.name.startsWith('Size ')) {
        sizeLabel = t.name.substring(5);
      } else {
        toppingLabels.add(t.name);
      }
    }

    final history = ref.read(chatHistoryProvider);
    int targetMsgIdx = -1;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i]['orderDraft'] != null ||
          history[i]['resolvedItems'] != null ||
          history[i]['orderPreview'] != null ||
          history[i]['orderDraftPreview'] != null) {
        targetMsgIdx = i;
        break;
      }
    }

    if (targetMsgIdx != -1) {
      final msg = Map<String, dynamic>.from(history[targetMsgIdx]);
      
      // 1. Get existing display items or build initial list from draft / preview
      final List<Map<String, dynamic>> resolvedList = [];
      if (msg['resolvedItems'] is List && (msg['resolvedItems'] as List).isNotEmpty) {
        for (var it in (msg['resolvedItems'] as List)) {
          if (it is Map) resolvedList.add(Map<String, dynamic>.from(it));
        }
      } else if (msg['orderDraft'] != null && msg['orderDraft']['items'] is List) {
        for (var it in (msg['orderDraft']['items'] as List)) {
          if (it is Map) {
            resolvedList.add({
              'menuItemId': it['menuItemId'] ?? it['id'],
              'name': it['name'] ?? it['menuItemName'] ?? 'Món ăn',
              'unitPrice': (it['price'] ?? it['unitPrice'] ?? 0.0) as num,
              'quantity': it['quantity'] ?? 1,
              'sizeLabel': it['sizeLabel'],
              'toppingLabels': <String>[],
              'note': it['notes'] ?? it['note'],
            });
          }
        }
      } else if (msg['orderPreview'] != null && msg['orderPreview']['items'] is List) {
        for (var it in (msg['orderPreview']['items'] as List)) {
          if (it is Map) {
            resolvedList.add({
              'menuItemId': it['menuItemId'] ?? it['id'],
              'name': it['name'] ?? it['menuItemName'] ?? 'Món ăn',
              'unitPrice': (it['unitPrice'] ?? it['price'] ?? 0.0) as num,
              'quantity': it['quantity'] ?? 1,
              'sizeLabel': it['sizeLabel'],
              'toppingLabels': <String>[],
              'note': it['notes'] ?? it['note'],
            });
          }
        }
      }

      final unitPrice = updatedTotal > 0 && updatedQty > 0
          ? (updatedTotal / updatedQty)
          : 0.0;

      final toppingIds = selectedToppings
          .where((t) =>
              !t.name.startsWith('Size ') &&
              t.toppingId.isNotEmpty &&
              !t.toppingId.startsWith('item_'))
          .map((t) => t.toppingId)
          .toList();

      if (itemIndex < resolvedList.length) {
        final item = Map<String, dynamic>.from(resolvedList[itemIndex]);
        item['quantity'] = updatedQty;
        if (unitPrice > 0) {
          item['unitPrice'] = unitPrice;
          item['price'] = unitPrice;
        }
        if (sizeLabel != null) {
          item['sizeLabel'] = sizeLabel;
        }
        if (sizeId != null) {
          item['sizeId'] = sizeId;
          item['selectedSizeId'] = sizeId;
        }
        item['toppingLabels'] = toppingLabels;
        item['toppingIds'] = toppingIds;
        item['note'] = updatedNote;
        item['notes'] = updatedNote;
        resolvedList[itemIndex] = item;
      }

      msg['resolvedItems'] = resolvedList;
      // Invalidate preview cache so _buildOrderDraftCard prioritizes resolvedItems
      msg['orderPreview'] = null;
      msg['orderDraftPreview'] = null;

      if (msg['orderDraft'] != null && msg['orderDraft'] is Map) {
        final draftMap = Map<String, dynamic>.from(msg['orderDraft']);
        final draftItems = (draftMap['items'] as List<dynamic>?) != null
            ? List<dynamic>.from(draftMap['items'])
            : <dynamic>[];
        if (itemIndex < draftItems.length) {
          final dItem =
              Map<String, dynamic>.from(draftItems[itemIndex] as Map);
          dItem['quantity'] = updatedQty;
          if (sizeId != null) dItem['selectedSizeId'] = sizeId;
          dItem['notes'] = updatedNote;
          if (unitPrice > 0) dItem['price'] = unitPrice;
          draftItems[itemIndex] = dItem;
          draftMap['items'] = draftItems;
        }

        double newSubtotal = 0.0;
        for (var it in resolvedList) {
          final p = (it['unitPrice'] ?? it['price'] ?? 0.0) as num;
          final q = (it['quantity'] ?? 1) as num;
          newSubtotal += p.toDouble() * q.toInt();
        }
        draftMap['subtotal'] = newSubtotal;
        draftMap['finalAmount'] = newSubtotal;
        msg['orderDraft'] = draftMap;
      }

      final newHistory = List<Map<String, dynamic>>.from(history);
      newHistory[targetMsgIdx] = msg;
      ref.read(chatHistoryProvider.notifier).state = newHistory;
      setState(() {});

      _showTopNotification('Đã cập nhật đơn hàng với $itemName!',
          AppColors.success, Icons.check_circle_outline);
    }
  }

  void _showItemSelectionSheet(List<Map<String, dynamic>> displayItems,
      String? branchId, String storeName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFFEA580C), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chọn món bạn muốn tùy chỉnh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...displayItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final name = item['name'] as String;
                final qty = item['quantity'] as int;
                final unitPrice = item['unitPrice'] as double;
                final size = item['size'] as String?;
                final toppings = (item['toppings'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];

                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _customizeItem(item, idx, branchId, storeName);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFE5DA), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFFFF7A45)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${qty}x',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              if (unitPrice > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  FormatUtils.formatCurrency(
                                      unitPrice.toInt()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFEA580C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              if (size != null || toppings.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    if (size != null) 'Size: $size',
                                    if (toppings.isNotEmpty) ...toppings
                                  ].join(', '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_note_rounded,
                            color: Color(0xFFEA580C), size: 22),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _startPaymentStatusPolling(String orderId) {
    if (orderId.isEmpty) return;
    final orderRepo = OrderRepository();
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final ord = await orderRepo.getOrderById(orderId);
        final status = (ord['status'] ?? ord['orderStatus'])?.toString();
        final paymentStatus = ord['paymentStatus']?.toString();

        bool isPaid = false;
        if (paymentStatus == 'Paid' || paymentStatus == '1' || paymentStatus == '36') {
          isPaid = true;
        }
        final payments = ord['payments'] as List<dynamic>? ?? [];
        if (payments.isNotEmpty) {
          final firstPay = payments.first;
          final pStatus = firstPay['status']?.toString();
          if (pStatus == 'Paid' || pStatus == '36') {
            isPaid = true;
          }
        }
        if (status == 'Preparing' || status == '2' || status == 'ReadyForPickup' || status == '3' || status == 'Completed' || status == '4') {
          isPaid = true;
        }

        _updateOrderStatusInChat(orderId, isPaid: isPaid, orderStatus: status);

        if (status == 'Completed' || status == '4' || status == 'Cancelled' || status == '5') {
          timer.cancel();
        }
      } catch (_) {}
    });
  }

  void _updateOrderStatusInChat(String orderId, {required bool isPaid, String? orderStatus}) {
    final messages = ref.read(chatHistoryProvider);
    bool changed = false;
    final updated = messages.map((m) {
      if (m['paymentData'] != null && m['paymentData']['orderId'] == orderId) {
        final pd = Map<String, dynamic>.from(m['paymentData'] as Map);
        if (pd['isPaid'] != isPaid || pd['orderStatus'] != orderStatus) {
          pd['isPaid'] = isPaid;
          pd['orderStatus'] = orderStatus;
          changed = true;
          return {
            ...m,
            'paymentData': pd,
          };
        }
      }
      return m;
    }).toList();

    if (changed) {
      ref.read(chatHistoryProvider.notifier).state = updated;
      setState(() {});
    }
  }

  void _addToCart(Map<String, dynamic> branch) {
    final bid = branch['branchId'] as String;
    final realMenuItemId = branch['menuItemId'] as String?;
    final item = CartItemModel(
      id: realMenuItemId != null ? '${bid}_$realMenuItemId' : '${bid}_bunbo',
      menuItemId: realMenuItemId ?? '${bid}_bunbo',
      imageUrl: '',
      name: branch['dishName'] as String,
      priceAmount: (branch['priceAmount'] as num).toInt(),
      priceDisplay: branch['priceText'] as String,
      quantity: 1,
    );

    ref.read(cartProvider.notifier).addItem(
          item,
          storeName: branch['storeName'] as String,
          distance: branch['distance'] as String,
          deliveryTime: branch['deliveryTime'] as String,
          storeImageUrl: '',
          icon: Icons.restaurant,
          branchId: bid,
        );

    _showTopNotification(
      'Đã thêm ${branch['dishName']} của ${branch['storeName']} vào giỏ hàng!',
      AppColors.success,
      Icons.check_circle_outline,
    );
  }

  void _openStoreDetail(Map<String, dynamic> branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailPage(
          storeName: branch['storeName'] as String,
          category: 'Quán ăn',
          rating: (branch['rating'] as num).toDouble(),
          reviews: (branch['reviews'] as num).toInt(),
          deliveryTime: branch['deliveryTime'] as String,
          distance: branch['distance'] as String,
          icon: Icons.restaurant,
          branchId: branch['branchId'] as String,
          highlightFoodName: branch['dishName'] as String?,
        ),
      ),
    );
  }

  void _showTopNotification(String text, Color backgroundColor, IconData icon) {
    if (_activeOverlayEntry != null) {
      try {
        _activeOverlayEntry!.remove();
      } catch (_) {}
      _activeOverlayEntry = null;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _activeOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 2300), () {
      if (_activeOverlayEntry == overlayEntry) {
        try {
          overlayEntry.remove();
        } catch (_) {}
        _activeOverlayEntry = null;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    if (_activeOverlayEntry != null) {
      try {
        _activeOverlayEntry!.remove();
      } catch (_) {}
      _activeOverlayEntry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset > 0 && bottomInset != _lastBottomInset) {
      _lastBottomInset = bottomInset;
      _scrollToBottom();
    } else if (bottomInset == 0) {
      _lastBottomInset = 0;
    }

    final currentUser = ref.watch(currentUserProvider);
    final messages = ref.watch(chatHistoryProvider);
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFFDFB), // Ultra-clean light orange-tinted background
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ lý ảo AI DineX',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                if (_activeBranchName != null ||
                    widget.initialBranchName != null)
                  Text(
                    _activeBranchName ?? widget.initialBranchName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: 'Xóa lịch sử chat',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }

                final msg = messages[index];
                final isUser = msg['isUser'] as bool;
                final isWelcome = msg['isWelcome'] as bool? ?? false;
                final text = msg['text'] as String;
                final time = msg['time'] as String? ?? '';
                final showChips = msg['showChips'] as bool? ?? false;
                final recommendations =
                    msg['recommendations'] as List<dynamic>?;
                final branchRecommendations =
                    msg['branchRecommendations'] as List<dynamic>?;
                final orderDraft = msg['orderDraft'];
                final orderPreview = msg['orderPreview'];
                final resolvedItems = msg['resolvedItems'];
                final paymentData = msg['paymentData'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8, top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (isWelcome)
                              _buildAiWelcomeFeaturesCard(msg)
                            else
                              _buildChatBubble(text, isUser),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (orderDraft != null) ...[
                              const SizedBox(height: 12),
                              _buildOrderDraftCard(
                                  orderDraft, orderPreview, resolvedItems, text),
                            ],
                            if (paymentData != null) ...[
                              const SizedBox(height: 12),
                              _buildPaymentQrCard(paymentData),
                            ],
                            if (branchRecommendations != null &&
                                branchRecommendations.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildRecommendationsList(branchRecommendations),
                            ],
                            if (showChips) ...[
                              _buildInlineSuggestiveChips(recommendations),
                            ],
                          ],
                        ),
                      ),
                      if (isUser) ...[
                        _buildUserAvatar(currentUser),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input field row
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary
                ], // Elegant orange brand gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser
            ? null
            : const Color(0xFFFFFDFB), // Soft warm peach background for AI
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        border: isUser
            ? null
            : Border.all(
                color: const Color(0xFFFFE5DA),
                width: 1.0), // Warm orange border
        boxShadow: isUser
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: isUser ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const _BouncingDotsIndicator(),
        ],
      ),
    );
  }

  Widget _buildAiWelcomeFeaturesCard(Map<String, dynamic> msg) {
    final recommendations = msg['recommendations'] as List<dynamic>?;
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: const Color(0xFFFFE5DA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xin chào! Tôi là Trợ lý AI DineX. Tôi có thể hỗ trợ bạn:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _buildFeatureBullet(
              'Tìm quán & món theo giá, khoảng cách, đánh giá.'),
          const SizedBox(height: 6),
          _buildFeatureBullet(
              'Đặt món tự động theo số lượng và ghi chú của bạn.'),
          const SizedBox(height: 6),
          _buildFeatureBullet(
              'Tạo mã QR PayOS và tự động cập nhật thanh toán.'),
          if (recommendations != null && recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recommendations.map((chipText) {
                return GestureDetector(
                  onTap: () => _handleSubmitted(chipText.toString()),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFFFE5DA), width: 0.8),
                    ),
                    child: Text(
                      chipText.toString(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: Icon(Icons.circle, size: 5, color: AppColors.primary),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineSuggestiveChips(List<dynamic>? recommendations) {
    final chips = (recommendations != null && recommendations.isNotEmpty)
        ? recommendations.cast<String>()
        : [
            'Cho tôi chi nhánh bán món Bún Bò Huế ngon, rẻ nhất',
            'Phở bò ngon Quận 1',
            'Có món nước gì rẻ không?'
          ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((chipText) {
          return ActionChip(
            avatar: const Icon(
              Icons.auto_awesome,
              size: 12,
              color: Color(0xFFEA580C),
            ),
            label: Text(
              chipText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            onPressed: () => _handleSubmitted(chipText),
            backgroundColor: const Color(0xFFFFF4F0),
            side: const BorderSide(color: Color(0xFFFFECE2), width: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFFFE5DA), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.mic_none_rounded,
                        color: Color(0xFFEA580C),
                        size: 20,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: () {
                        _showTopNotification(
                          'Tính năng ghi âm giọng nói đang phát triển.',
                          AppColors.primary,
                          Icons.info_outline,
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _textController,
                        onTap: () => _scrollToBottom(),
                        onSubmitted: _handleSubmitted,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu hỏi của bạn...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _handleSubmitted(_textController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD84315), Color(0xFFFF6F3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD84315).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    if (user != null && user.avatar != null && user.avatar!.isNotEmpty) {
      if (user.avatar!.startsWith('http') || user.avatar!.startsWith('https')) {
        return Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 8, top: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(
              user.avatar!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultUserAvatar(user),
            ),
          ),
        );
      }
    }
    return _buildDefaultUserAvatar(user);
  }

  Widget _buildDefaultUserAvatar(UserModel? user) {
    final String initialChar = user != null && user.displayName.isNotEmpty
        ? user.displayName.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 8, top: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFE5DA), width: 1.0),
      ),
      child: Center(
        child: Text(
          initialChar,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(List<dynamic>? branchRecommendations) {
    if (branchRecommendations == null || branchRecommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    final list = branchRecommendations;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rec = list[index];
        final String tag = rec['tag'] as String? ?? '';

        Color tagBgColor;
        Color tagTextColor;

        if (tag == 'Rẻ nhất') {
          tagBgColor = const Color(0xFFDCFCE7); // Light green
          tagTextColor = const Color(0xFF15803D); // Dark green
        } else if (tag == 'Yêu thích') {
          tagBgColor = const Color(0xFFFEE2E2); // Light red
          tagTextColor = const Color(0xFFB91C1C); // Dark red
        } else if (tag == 'Bán chạy') {
          tagBgColor = const Color(0xFFFEF3C7); // Light amber
          tagTextColor = const Color(0xFFB45309); // Dark amber
        } else {
          tagBgColor = const Color(0xFFDBEAFE); // Light blue
          tagTextColor = const Color(0xFF1D4ED8); // Dark blue
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFF4F0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD84315).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFEA580C),
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rec['storeName'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: tagTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Details info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFFEDD5), width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: (rec['imageUrl'] != null &&
                              (rec['imageUrl'] as String).isNotEmpty)
                          ? Image.network(
                              rec['imageUrl'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFFF7ED),
                                      Color(0xFFFFEDD5)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.ramen_dining_rounded,
                                    color: Color(0xFFEA580C),
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFF7ED),
                                    Color(0xFFFFEDD5)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.ramen_dining_rounded,
                                  color: Color(0xFFEA580C),
                                  size: 32,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['dishName'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rec['priceText'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFF59E0B), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '${rec['rating']}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              ' (${rec['reviews']})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_outlined,
                                color: Color(0xFF9CA3AF), size: 11),
                            const SizedBox(width: 2),
                            Text(
                              rec['distance'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () => _openStoreDetail(rec),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFE2E8F0), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Xem menu & Topping',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEA580C).withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _addToCart(rec),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Thêm vào giỏ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderDraftCard(dynamic draft, dynamic orderPreview,
      dynamic resolvedItems, String? bubbleText) {
    if (draft == null || draft is! Map) return const SizedBox.shrink();
    final rawItems = (draft['items'] as List<dynamic>?) ?? [];

    // 1. Extract Store Name
    String storeName = _activeBranchName ?? 'Quán ăn';
    if (bubbleText != null && bubbleText.isNotEmpty) {
      final storeMatch = RegExp(r'\*\*([^*]+)\*\*').firstMatch(bubbleText);
      if (storeMatch != null && storeMatch.group(1) != null) {
        storeName = storeMatch.group(1)!.trim();
      }
    }

    // 2. Extract structured item list
    final List<Map<String, dynamic>> displayItems = [];

    if (resolvedItems != null &&
        resolvedItems is List &&
        resolvedItems.isNotEmpty) {
      for (int i = 0; i < resolvedItems.length; i++) {
        var it = resolvedItems[i];
        if (it is Map) {
          final name = it['name'] ?? it['Name'] ?? 'Món ăn';
          final qty = it['quantity'] ?? it['Quantity'] ?? 1;
          final price =
              (it['unitPrice'] ?? it['UnitPrice'] ?? it['price'] ?? 0) as num;
          final size = it['sizeLabel'] ?? it['SizeLabel'];
          final toppings = (it['toppingLabels'] ?? it['ToppingLabels'])
              as List<dynamic>?;
          final matchedRawItem = (rawItems.length > i && rawItems[i] is Map) ? rawItems[i] : null;
          final menuItemId = it['menuItemId'] ?? it['MenuItemId'] ?? it['id'] ?? matchedRawItem?['menuItemId'] ?? matchedRawItem?['MenuItemId'];

          displayItems.add({
            'menuItemId': menuItemId?.toString(),
            'name': name.toString(),
            'quantity': qty is int ? qty : int.tryParse(qty.toString()) ?? 1,
            'unitPrice': price.toDouble(),
            'totalPrice': price.toDouble() *
                (qty is int ? qty : int.tryParse(qty.toString()) ?? 1),
            'size': size?.toString(),
            'sizeId': it['sizeId'] ?? it['selectedSizeId'] ?? matchedRawItem?['selectedSizeId'],
            'toppings':
                toppings?.map((e) => e.toString()).toList() ?? <String>[],
            'toppingIds': it['toppingIds'] ?? matchedRawItem?['toppingIds'],
            'note': it['note'] ?? it['notes'],
          });
        }
      }
    } else if (orderPreview != null &&
        orderPreview is Map &&
        orderPreview['items'] is List &&
        (orderPreview['items'] as List).isNotEmpty) {
      for (var it in (orderPreview['items'] as List)) {
        if (it is Map) {
          final name = it['menuItemName'] ?? it['name'] ?? 'Món ăn';
          final qty = it['quantity'] ?? 1;
          final unitPrice =
              (it['unitPrice'] ?? it['price'] ?? 0) as num;
          final totalPrice =
              (it['totalPrice'] ?? (unitPrice * (qty is int ? qty : 1)))
                  as num;
          final size = it['sizeLabel'];
          final menuItemId = it['menuItemId'] ?? it['MenuItemId'] ?? it['id'];

          displayItems.add({
            'menuItemId': menuItemId?.toString(),
            'name': name.toString(),
            'quantity': qty is int ? qty : int.tryParse(qty.toString()) ?? 1,
            'unitPrice': unitPrice.toDouble(),
            'totalPrice': totalPrice.toDouble(),
            'size': size?.toString(),
            'sizeId': it['sizeId'] ?? it['selectedSizeId'],
            'toppings': <String>[],
            'toppingIds': it['toppingIds'],
            'note': it['note'] ?? it['notes'],
          });
        }
      }
    } else {
      for (var it in rawItems) {
        if (it is Map) {
          final name = it['name'] ?? it['menuItemName'] ?? 'Món ăn';
          final qty = it['quantity'] ?? 1;
          final price = (it['price'] ?? it['unitPrice'] ?? 0) as num;
          final menuItemId = it['menuItemId'] ?? it['MenuItemId'] ?? it['id'];

          displayItems.add({
            'menuItemId': menuItemId?.toString(),
            'name': name.toString(),
            'quantity': qty is int ? qty : int.tryParse(qty.toString()) ?? 1,
            'unitPrice': price.toDouble(),
            'totalPrice': price.toDouble() *
                (qty is int ? qty : int.tryParse(qty.toString()) ?? 1),
            'size': it['sizeLabel']?.toString(),
            'sizeId': it['sizeId'] ?? it['selectedSizeId'],
            'toppings': <String>[],
            'toppingIds': it['toppingIds'],
            'note': it['note'] ?? it['notes'],
          });
        }
      }
    }

    // 3. Fallback extraction from assistant bubble text
    if (displayItems.isEmpty && bubbleText != null && bubbleText.isNotEmpty) {
      final itemLines = RegExp(r'•\s*(\d+)x?\s+([^\n(]+)(?:\(([^)]+)\))?')
          .allMatches(bubbleText);
      for (final m in itemLines) {
        final qty = int.tryParse(m.group(1) ?? '1') ?? 1;
        final name = (m.group(2) ?? 'Món ăn').trim();
        final details = m.group(3);
        displayItems.add({
          'menuItemId': null,
          'name': name,
          'quantity': qty,
          'unitPrice': 0.0,
          'totalPrice': 0.0,
          'size': null,
          'toppings': <String>[],
          'note': details,
        });
      }
    }

    // Calculate subtotal & grand total
    double calculatedTotal = 0;
    for (var item in displayItems) {
      calculatedTotal += (item['totalPrice'] as double);
    }

    double finalTotal = 0;
    if (orderPreview != null && orderPreview is Map) {
      finalTotal = (orderPreview['total'] as num?)?.toDouble() ??
          (orderPreview['finalTotal'] as num?)?.toDouble() ??
          (orderPreview['subtotal'] as num?)?.toDouble() ??
          0;
    } else if (draft['finalAmount'] != null) {
      finalTotal = (draft['finalAmount'] as num).toDouble();
    } else if (draft['subtotal'] != null) {
      finalTotal = (draft['subtotal'] as num).toDouble();
    }

    if (finalTotal > 0 && calculatedTotal == 0) {
      if (displayItems.isNotEmpty) {
        if (displayItems.length == 1) {
          displayItems[0]['totalPrice'] = finalTotal;
          displayItems[0]['unitPrice'] =
              finalTotal / (displayItems[0]['quantity'] as int);
        }
      }
    }

    if (finalTotal == 0 && calculatedTotal > 0) {
      finalTotal = calculatedTotal;
    }

    final priceText = FormatUtils.formatCurrency(finalTotal.toInt());
    final branchId = (draft['branchId'] ?? draft['BranchId'] ?? _activeBranchId)?.toString();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD4BE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD84315).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Store info + Receipt tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF7F3), Color(0xFFFFF1EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFFD84315),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Đơn hàng dự kiến được tạo tự động bởi AI',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFD8BE), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 11, color: Color(0xFFC2410C)),
                      SizedBox(width: 3),
                      Text(
                        'Tạm tính',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Divider
          Container(
            height: 1,
            color: const Color(0xFFFFE5DA),
          ),

          // Items List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHI TIẾT MÓN ĐÃ CHỌN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 10),
                ...displayItems.map((item) {
                  final String name = item['name'] as String;
                  final int qty = item['quantity'] as int;
                  final double unitPrice = item['unitPrice'] as double;
                  final double itemTotal = item['totalPrice'] as double;
                  final String? size = item['size'] as String?;
                  final List<String> toppings =
                      (item['toppings'] as List<dynamic>?)
                              ?.map((e) => e.toString())
                              .toList() ??
                          [];
                  final String? note = item['note'] as String?;
                  final String? mItemId = item['menuItemId'] as String?;

                  return InkWell(
                    onTap: () {
                      if (mItemId != null &&
                          mItemId.isNotEmpty &&
                          mItemId != '00000000-0000-0000-0000-000000000000') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddToCartPage(
                              name: name,
                              price: FormatUtils.formatCurrency(unitPrice.toInt()),
                              icon: Icons.fastfood_rounded,
                              branchId: branchId,
                              menuItemId: mItemId,
                              initialQuantity: qty,
                              initialNote: note,
                            ),
                          ),
                        );
                      } else if (branchId != null &&
                          branchId.isNotEmpty &&
                          branchId != '00000000-0000-0000-0000-000000000000') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreDetailPage(
                              branchId: branchId,
                              storeName: storeName,
                              category: 'Quán ăn',
                              rating: 5.0,
                              reviews: 100,
                              deliveryTime: '20-30 phút',
                              distance: '1.0 km',
                              icon: Icons.store,
                              highlightFoodName: name,
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFF0EA), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEA580C), Color(0xFFFF7A45)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${qty}x',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                if (unitPrice > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Đơn giá: ${FormatUtils.formatCurrency(unitPrice.toInt())}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (size != null && size.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Size: $size',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ],
                                if (toppings.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: toppings
                                        .map((t) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEDD5),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '+ $t',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFC2410C),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                                if (note != null && note.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Ghi chú: $note',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (itemTotal > 0)
                            Text(
                              FormatUtils.formatCurrency(itemTotal.toInt()),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                // Divider
                Container(height: 1, color: const Color(0xFFF3F4F6)),
                const SizedBox(height: 10),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng thanh toán dự kiến',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    if (branchId != null &&
                        branchId.isNotEmpty &&
                        branchId != '00000000-0000-0000-0000-000000000000')
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () {
                              if (displayItems.length == 1) {
                                _customizeItem(displayItems.first, 0, branchId, storeName);
                              } else if (displayItems.length > 1) {
                                _showItemSelectionSheet(displayItems, branchId, storeName);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFFF7A45), width: 1.2),
                              foregroundColor: const Color(0xFFD84315),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.tune_rounded, size: 15),
                                SizedBox(width: 4),
                                Text(
                                  'Tùy chỉnh món',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (branchId != null &&
                        branchId.isNotEmpty &&
                        branchId != '00000000-0000-0000-0000-000000000000')
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD84315), Color(0xFFFF6F3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFD84315).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _handleConfirmDraftAndPay(
                              Map<String, dynamic>.from(draft), displayItems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded,
                                  size: 17, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Xác nhận & Nhận QR',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentQrCard(dynamic paymentData) {
    if (paymentData == null || paymentData is! Map) {
      return const SizedBox.shrink();
    }
    final String qrCode = paymentData['qrCode'] as String? ?? '';
    final double amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
    final String orderId = paymentData['orderId'] as String? ?? '';
    final bool isPaid = paymentData['isPaid'] as bool? ?? false;
    final bool requiresStaffConfirmation =
        paymentData['requiresStaffConfirmation'] as bool? ?? false;
    final String orderStatus = (paymentData['orderStatus'] as String? ??
        (isPaid ? 'Preparing' : 'PendingConfirmation'));
    final String priceText = FormatUtils.formatCurrency(amount.toInt());

    // 0: Waiting Payment, 1: Preparing, 2: ReadyForPickup, 3: Completed
    int currentStep = 0;
    if (isPaid || orderStatus == 'Preparing' || orderStatus == '2') {
      currentStep = 1;
    }
    if (orderStatus == 'ReadyForPickup' || orderStatus == '3') {
      currentStep = 2;
    }
    if (orderStatus == 'Completed' || orderStatus == '4') {
      currentStep = 3;
    }

    String statusTitle = 'Đang chờ thanh toán qua PayOS';
    IconData statusIcon = Icons.hourglass_top_rounded;
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusColor = const Color(0xFFB45309);

    if (requiresStaffConfirmation && qrCode.isEmpty && currentStep == 0) {
      statusTitle = '⏳ Chờ quán xác nhận đơn lớn';
      statusIcon = Icons.assignment_turned_in_rounded;
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
    } else if (currentStep == 1) {
      statusTitle = '✓ Đã thanh toán • Bếp đang chuẩn bị món';
      statusIcon = Icons.soup_kitchen_rounded;
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
    } else if (currentStep == 2) {
      statusTitle = '🎉 Món đã sẵn sàng • Mời bạn nhận món!';
      statusIcon = Icons.shopping_bag_rounded;
      statusBg = const Color(0xFFFFEDD5);
      statusColor = const Color(0xFFC2410C);
    } else if (currentStep == 3) {
      statusTitle = '✓ Đơn hàng đã hoàn tất';
      statusIcon = Icons.check_circle_rounded;
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: currentStep > 0
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFFD8BE),
          width: currentStep > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: currentStep > 0
                ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                : const Color(0xFFEA580C).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Visual Progress Stepper
          _buildOrderProgressStepper(currentStep),

          const SizedBox(height: 10),

          // Content based on status
          if (currentStep == 0 && requiresStaffConfirmation && qrCode.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.assignment_turned_in_rounded,
                      color: Color(0xFFD97706), size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Đơn hàng số lượng lớn (≥10 món)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quán đang kiểm tra và xác nhận thời gian chuẩn bị món. Sau khi quán xác nhận, mã QR thanh toán sẽ tự động hiển thị.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF78350F),
                      height: 1.3,
                    ),
                  ),
                  if (orderId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mã đơn: #${orderId.length > 8 ? orderId.substring(0, 8) : orderId} • $priceText',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (currentStep == 0 && qrCode.isNotEmpty) ...[
            Builder(builder: (context) {
              final qrImageUrl = qrCode.startsWith('http')
                  ? qrCode
                  : 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(qrCode)}';
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: SizedBox(
                  width: 190,
                  height: 190,
                  child: CachedNetworkImage(
                    imageUrl: qrImageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                    errorWidget: (_, __, ___) => _buildFallbackQrImage(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Text(
              'Số tiền thanh toán: $priceText',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEA580C),
              ),
            ),
            if (orderId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Mã đơn: #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFFEA580C),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Tự động nhận diện khi chuyển khoản thành công',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ] else if (currentStep >= 1) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: currentStep == 2
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: currentStep == 2
                      ? const Color(0xFFFFEDD5)
                      : const Color(0xFFDCFCE7),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    currentStep == 1
                        ? Icons.soup_kitchen_rounded
                        : (currentStep == 2
                            ? Icons.shopping_bag_rounded
                            : Icons.check_circle_rounded),
                    color: currentStep == 2
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF16A34A),
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStep == 1
                        ? 'Đơn hàng đang được chế biến tại bếp'
                        : (currentStep == 2
                            ? 'Món ăn của bạn đã sẵn sàng!'
                            : 'Đơn hàng đã hoàn tất!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: currentStep == 2
                          ? const Color(0xFF9A3412)
                          : const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStep == 1
                        ? 'Bếp đang làm món theo ghi chú của bạn. Trạng thái sẽ tự động cập nhật khi món hoàn tất.'
                        : (currentStep == 2
                            ? 'Vui lòng tới quầy thu ngân/nhận món để nhận phần ăn của bạn.'
                            : 'Cảm ơn bạn đã sử dụng dịch vụ. Chúc bạn ngon miệng!'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280), height: 1.3),
                  ),
                  if (orderId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mã đơn: #${orderId.length > 8 ? orderId.substring(0, 8) : orderId} • $priceText',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: currentStep == 2
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderProgressStepper(int currentStep) {
    final steps = [
      {'label': 'Thanh toán', 'icon': Icons.payment_rounded},
      {'label': 'Nấu món', 'icon': Icons.soup_kitchen_rounded},
      {'label': 'Sẵn sàng', 'icon': Icons.shopping_bag_rounded},
      {'label': 'Hoàn tất', 'icon': Icons.check_circle_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i % 2 == 1) {
            final prevStepIdx = (i - 1) ~/ 2;
            final isDoneLine = currentStep > prevStepIdx;
            return Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDoneLine
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          } else {
            final stepIdx = i ~/ 2;
            final isCompleted = currentStep > stepIdx;
            final isCurrent = currentStep == stepIdx;
            final item = steps[stepIdx];

            Color iconColor;
            Color bgColor;
            Color textColor;

            if (isCompleted) {
              iconColor = Colors.white;
              bgColor = const Color(0xFF16A34A);
              textColor = const Color(0xFF166534);
            } else if (isCurrent) {
              iconColor = Colors.white;
              bgColor = const Color(0xFFEA580C);
              textColor = const Color(0xFFEA580C);
            } else {
              iconColor = const Color(0xFF9CA3AF);
              bgColor = const Color(0xFFF3F4F6);
              textColor = const Color(0xFF9CA3AF);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEA580C)
                                  .withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_rounded
                        : (item['icon'] as IconData),
                    size: 13,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  Widget _buildFallbackQrImage() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 64, color: Color(0xFFEA580C)),
            SizedBox(height: 6),
            Text(
              'Mã QR PayOS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA580C)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingDotsIndicator extends StatefulWidget {
  const _BouncingDotsIndicator();

  @override
  State<_BouncingDotsIndicator> createState() => _BouncingDotsIndicatorState();
}

class _BouncingDotsIndicatorState extends State<_BouncingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double delay = index * 0.2;
              final double value = (_controller.value - delay) % 1.0;
              final double dy = -5 * (1 - (value - 0.5).abs() * 2);

              return Transform.translate(
                offset: Offset(0, dy.clamp(-5.0, 0.0)),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

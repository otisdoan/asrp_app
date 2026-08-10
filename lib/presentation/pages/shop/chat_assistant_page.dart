import 'dart:async';
import 'store_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../providers/chat_cart_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/chat_history_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../providers/branch_provider.dart';
import '../../../data/repositories/order_repository.dart';
import 'payment_success_page.dart';
import 'package:geolocator/geolocator.dart';

// ── chat_ai sub-components ──────────────────────────────────────────────────
import 'chat_ai/checkout_bar.dart';
import 'chat_ai/cart_details_bottom_sheet.dart';
import 'chat_ai/widgets/chat_bubble.dart';
import 'chat_ai/widgets/bouncing_dots_indicator.dart';
import 'chat_ai/widgets/mini_invoice_card.dart';
import 'chat_ai/widgets/recommendation_card.dart';

// ── shared payment widget ───────────────────────────────────────────────────
import '../../widgets/payment/inline_qr_payment_card.dart';

class ChatAssistantPage extends ConsumerStatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  ConsumerState<ChatAssistantPage> createState() =>
      _ChatAssistantPageState();
}

class _ChatAssistantPageState extends ConsumerState<ChatAssistantPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  late final String _sessionId = 'session_default_user';
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  OverlayEntry? _activeOverlayEntry;
  Position? _userPosition;
  HubConnection? _hubConnection;
  Timer? _pollingTimer;
  DateTime? _selectedPickupTime;
  bool _isNavigatingToSuccess = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    _hubConnection?.stop();
    if (_activeOverlayEntry != null) {
      try {
        _activeOverlayEntry!.remove();
      } catch (_) {}
      _activeOverlayEntry = null;
    }
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 100,
        ),
      );
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (e) {
      debugPrint('Failed to get user location: $e');
    }
  }

  // ── Chat History ───────────────────────────────────────────────────────────

  Future<void> _loadChatHistory() async {
    try {
      final response = await DioClient()
          .dio
          .get('/ai/chat/history',
              queryParameters: {'sessionId': _sessionId});
      final List<dynamic> list = response.data as List<dynamic>;
      if (list.isNotEmpty) {
        final loadedMessages = list.map((item) {
          return {
            'isUser': item['isUser'] as bool,
            'text': item['text'] as String? ?? '',
            'time': item['time'] as String? ?? '',
            'orderDraft': item['orderDraft'],
            'recommendations': item['recommendations'],
            'branchRecommendations': item['branchRecommendations'],
            'showChips': false,
          };
        }).toList();

        ref.read(chatHistoryProvider.notifier).state = loadedMessages;
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[ChatAssistant] Error loading chat history: $e');
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DioClient().dio.delete('/ai/chat/history',
                    queryParameters: {'sessionId': _sessionId});
              } catch (_) {}
              final now = DateTime.now();
              final timeStr =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              ref.read(chatHistoryProvider.notifier).state = [
                {
                  'isUser': false,
                  'text':
                      'Xin chào! Tôi là trợ lý ảo AI DineX. Tôi có thể giúp gì cho bạn hôm nay?',
                  'time': timeStr,
                  'showChips': true,
                }
              ];
            },
            child:
                const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Pickup Time ────────────────────────────────────────────────────────────

  List<DateTime> _generateAvailablePickupTimes() {
    final now = DateTime.now();
    final earliest = now.add(const Duration(minutes: 15));
    final minuteModulo = earliest.minute % 15;
    final minutesToAdd = minuteModulo == 0 ? 0 : 15 - minuteModulo;
    DateTime firstSlot =
        earliest.add(Duration(minutes: minutesToAdd));
    firstSlot = DateTime(firstSlot.year, firstSlot.month, firstSlot.day,
        firstSlot.hour, firstSlot.minute);
    return List.generate(
        5, (index) => firstSlot.add(Duration(minutes: 15 * index)));
  }

  void _showPickupTimePicker() {
    final availableSlots = _generateAvailablePickupTimes();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Chọn thời gian nhận món',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ...availableSlots.map((slot) {
                final label =
                    '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
                final isSelected = _selectedPickupTime != null &&
                    _selectedPickupTime == slot;
                return ListTile(
                  title: Text(label),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: Color(0xFFEA580C))
                      : null,
                  onTap: () {
                    setState(() => _selectedPickupTime = slot);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Cart Details Bottom Sheet ──────────────────────────────────────────────
  // FIX BUG: Hàm này trước đây bị thiếu, gây crash khi bấm khu vực giỏ hàng.

  void _showCartDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, controller) {
              return CartDetailsBottomSheet(
                scrollController: controller,
                onConfirm: _sendDirectAction,
              );
            },
          ),
        );
      },
    );
  }

  // ── Handle Submit (AI Chat) ────────────────────────────────────────────────

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    ref.read(chatHistoryProvider.notifier).update((state) {
      final updated =
          state.map((msg) => {...msg, 'showChips': false}).toList();
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

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Resolve branch ID: Ưu tiên lấy từ chatCartProvider, sau đó kiểm tra cartProvider (giỏ hàng chính)
    final chatCart = ref.read(chatCartProvider);
    final mainCart = ref.read(cartProvider);
    String branchId = '';

    if (chatCart.isNotEmpty && chatCart.first.branchId.isNotEmpty) {
      branchId = chatCart.first.branchId;
    } else {
      for (final bCart in mainCart.carts.values) {
        if (bCart.items.isNotEmpty && (bCart.branchId?.isNotEmpty ?? false)) {
          branchId = bCart.branchId!;
          break;
        }
      }
    }

    if (branchId.isEmpty) {
      final branchesAsync = ref.read(branchesFutureProvider);
      branchesAsync.whenData((list) {
        if (list.isNotEmpty) branchId = list.first.id;
      });
    }
    if (branchId.isEmpty) {
      branchId = '00000000-0000-0000-0000-000000000000';
    }

    // Build chat history context (exclude last user message)
    final currentMessages = ref.read(chatHistoryProvider);
    final history = currentMessages
        .where((m) => m['isUser'] != null)
        .map((m) => {
              'role': m['isUser'] == true ? 'user' : 'assistant',
              'content': m['text'] as String,
            })
        .toList();
    if (history.isNotEmpty) history.removeLast();

    try {
      final response = await DioClient().dio.post(
        '/ai/chat',
        data: {
          'branchId': branchId,
          'sessionId': _sessionId,
          'message': text,
          'chatHistory': history,
          'chatCart':
              ref.read(chatCartProvider.notifier).toAiContextJson(),
          'userLocation': _userPosition != null
              ? {
                  'latitude': _userPosition!.latitude,
                  'longitude': _userPosition!.longitude
                }
              : null,
        },
      );

      if (!mounted) return;

      final data = response.data;
      final replyTime = DateTime.now();
      final replyTimeStr =
          '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      debugPrint('================ [Flutter AI Chat] RESPONSE LOG ================');
      debugPrint('User Message: $text');
      debugPrint('AI Reply: ${data['reply']}');
      debugPrint('Recommendations: ${data['recommendations']}');
      debugPrint('BranchRecommendations: ${data['branchRecommendations']}');
      debugPrint('=================================================================');

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

      setState(() => _isTyping = false);
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

      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  // ── Proceed to Checkout (from Mini Invoice Card) ───────────────────────────

  Future<void> _proceedToCheckout(dynamic orderDraft) async {
    if (orderDraft == null || orderDraft is! Map) return;
    final Map<String, dynamic> draftMap = Map<String, dynamic>.from(orderDraft);

    _isNavigatingToSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child:
            CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final createOrderResponse = await DioClient().dio.post(
        '/orders/online',
        data: {
          'branchId': draftMap['branchId'],
          'items': draftMap['items'] ?? [],
          'combos': draftMap['combos'] ?? [],
          'note': draftMap['note'] ?? '',
          'promotionId': draftMap['promotionId'],
          if (draftMap['earliestPickupTime'] != null)
            'pickupTime': draftMap['earliestPickupTime'],
        },
      );

      final orderId = createOrderResponse.data['id'] as String;

      final paymentResponse = await DioClient().dio.post(
        '/orders/$orderId/payments',
        data: {
          'method': 1,
          'note': 'Thanh toan don hang dat qua AI Chat',
        },
      );

      final paymentData = paymentResponse.data;
      final checkoutUrl = paymentData['checkoutUrl'] as String? ?? '';
      final qrCode = paymentData['qrCode'] as String? ?? '';
      final double amount =
          (paymentData['amount'] as num?)?.toDouble() ?? 0.0;

      if (mounted) Navigator.pop(context);

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            {
              'isUser': false,
              'text':
                  'Đơn hàng của bạn đã được khởi tạo. Vui lòng quét mã QR bên dưới để hoàn tất thanh toán:',
              'time': timeStr,
              'orderId': orderId,
              'qrCode': qrCode,
              'amount': amount,
              'checkoutUrl': checkoutUrl,
              'secondsRemaining': 600,
              'showChips': false,
            }
          ]);

      _initSignalR(orderId);
      _startInlinePaymentPolling(orderId);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('[AI Checkout Error]: $e');
      if (mounted) {
        _showTopNotification(
          'Không thể khởi tạo thanh toán đơn hàng. Vui lòng thử lại.',
          AppColors.error,
          Icons.error_outline,
        );
      }
    }
  }

  // ── Direct Action — Tạo QR từ Chat Cart ───────────────────────────────────

  void _sendDirectAction() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng đăng nhập để tiếp tục đặt món và thanh toán.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push('/login');
      return;
    }

    final cart = ref.read(chatCartProvider);
    if (cart.isEmpty) return;

    _isNavigatingToSuccess = false;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    ref.read(chatHistoryProvider.notifier).update((state) {
      final updated =
          state.map((msg) => {...msg, 'showChips': false}).toList();
      return [
        ...updated,
        {
          'isUser': true,
          'text': 'Tạo QR thanh toán cho giỏ hàng chat của tôi.',
          'time': timeStr,
          'showChips': false,
        }
      ];
    });

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final response = await DioClient().dio.post(
        '/ai/chat/direct-action',
        data: {
          'action': 'CREATE_ORDER',
          'pickupTime':
              _selectedPickupTime?.toUtc().toIso8601String(),
          'items': cart
              .map((e) => {
                    'menuItemId': e.menuItemId,
                    'branchId': e.branchId,
                    'quantity': e.quantity,
                    'selectedSizeId': e.selectedSizeId.isNotEmpty ? e.selectedSizeId : null,
                  })
              .toList(),
        },
      );

      if (!mounted) return;

      final data = response.data;
      final replyTime = DateTime.now();
      final replyTimeStr =
          '${replyTime.hour.toString().padLeft(2, '0')}:${replyTime.minute.toString().padLeft(2, '0')}';

      if (data['messageType'] == 'PAYMENT_QR') {
        final qrData = data['data'];

        ref.read(chatCartProvider.notifier).clearCart();

        ref.read(chatHistoryProvider.notifier).update((state) => [
              ...state,
              {
                'isUser': false,
                'text':
                    'Đơn hàng của bạn đã được khởi tạo thành công! Vui lòng quét mã QR bên dưới để thanh toán.',
                'time': replyTimeStr,
                'orderId': qrData['orderId'],
                'qrCode': qrData['qrCode'],
                'amount':
                    (qrData['amount'] as num).toDouble(),
                'secondsRemaining': 600,
                'showChips': true,
              }
            ]);

        _initSignalR(qrData['orderId'] as String);
        _startInlinePaymentPolling(qrData['orderId'] as String);
      } else {
        throw Exception('Phản hồi không hợp lệ từ server.');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[ChatAssistant] Error direct action: $e');

      String errorMessage =
          'Đã xảy ra lỗi khi tạo đơn hàng hoặc sinh mã thanh toán. Vui lòng thử lại.';
      if (e is DioException) {
        debugPrint(
            '[ChatAssistant] Dio Error Status: ${e.response?.statusCode}');
        debugPrint(
            '[ChatAssistant] Dio Error Data: ${e.response?.data}');

        final errData = e.response?.data;
        if (errData is Map<String, dynamic>) {
          final serverMsg = errData['message'] ?? errData['Message'];
          final serverDetail =
              errData['detail'] ?? errData['Detail'];
          if (serverMsg != null) {
            errorMessage = serverMsg.toString();
            if (serverDetail != null) {
              errorMessage +=
                  '\nChi tiết: ${serverDetail.toString()}';
            }
          }
        }
      }

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            {
              'isUser': false,
              'text': errorMessage,
              'time': timeStr,
              'showChips': true,
            }
          ]);
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  // ── Payment Polling ────────────────────────────────────────────────────────

  void _startInlinePaymentPolling(String orderId) {
    _pollingTimer?.cancel();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isNavigatingToSuccess) {
        timer.cancel();
        return;
      }
      try {
        final orderRepository = OrderRepository();
        final orderJson =
            await orderRepository.getOrderById(orderId);
        final status = orderJson['orderStatus']?.toString();
        final paymentStatus =
            orderJson['paymentStatus']?.toString();

        bool isPaid = false;
        if (paymentStatus == 'Paid' || paymentStatus == '1') {
          isPaid = true;
        }

        final payments =
            orderJson['payments'] as List<dynamic>? ?? [];
        if (payments.isNotEmpty) {
          final payStatus =
              payments.first['status']?.toString();
          if (payStatus == 'Paid' || payStatus == '36') {
            isPaid = true;
          }
        }

        if (status == 'Preparing' ||
            status == '2' ||
            status == 'ReadyForPickup' ||
            status == '3' ||
            status == 'Completed' ||
            status == '4') {
          isPaid = true;
        }

        if (isPaid && !_isNavigatingToSuccess) {
          _isNavigatingToSuccess = true;
          timer.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PaymentSuccessPage(orderId: orderId),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[Inline Polling Error]: $e');
      }
    });
  }

  // ── SignalR ────────────────────────────────────────────────────────────────

  Future<void> _initSignalR(String orderId) async {
    if (_hubConnection != null &&
        _hubConnection!.state ==
            HubConnectionState.Connected) {
      try {
        await _hubConnection!
            .invoke('JoinOrderTracking', args: [orderId]);
        debugPrint('[SignalR] Joined group for order $orderId');
      } catch (e) {
        debugPrint(
            '[SignalR] Error invoking JoinOrderTracking: $e');
      }
      return;
    }

    final hubUrl = ApiConstants.chatAgentHubUrl;
    debugPrint('[SignalR] Connecting to $hubUrl');

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('ReceiveAgentMessage',
        (List<Object?>? args) {
      if (!mounted) return;
      if (args != null && args.isNotEmpty && args[0] is Map) {
        final payload = Map<String, dynamic>.from(args[0] as Map);
        debugPrint('[SignalR] Received payload: $payload');
        if (payload['messageType'] == 'PAYMENT_SUCCESS') {
          final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : <String, dynamic>{};
          final receivedOrderId = data['orderId']?.toString();
          final amount =
              (data['amount'] as num?)?.toDouble() ?? 0.0;

          if (receivedOrderId != null &&
              receivedOrderId == orderId) {
            _handlePaymentSuccessSignalR(
                receivedOrderId, amount);
          }
        }
      }
    });

    try {
      await _hubConnection!.start();
      await _hubConnection!
          .invoke('JoinOrderTracking', args: [orderId]);
      debugPrint(
          '[SignalR] Connected and joined order $orderId');
    } catch (e) {
      debugPrint('[SignalR] Error starting SignalR: $e');
    }
  }

  void _handlePaymentSuccessSignalR(
      String orderId, double amount) {
    if (!mounted || _isNavigatingToSuccess) return;
    _isNavigatingToSuccess = true;
    _pollingTimer?.cancel();

    ref.read(chatHistoryProvider.notifier).update((state) {
      return state.map((m) {
        if (m['orderId'] == orderId) {
          return {
            ...m,
            'qrCode': null,
            'text':
                'Cảm ơn bạn! Dạ em đã nhận được thanh toán ${amount.toInt()}đ. Đơn hàng đang được bếp chuẩn bị nhé!',
          };
        }
        return m;
      }).toList();
    });

    _showTopNotification(
      'Thanh toán thành công ${amount.toInt()}đ!',
      AppColors.success,
      Icons.check_circle_outline,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PaymentSuccessPage(orderId: orderId),
          ),
        );
      }
    });
  }

  // ── Store navigation ───────────────────────────────────────────────────────

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

  // ── Top Notification Overlay ───────────────────────────────────────────────

  void _showTopNotification(
      String text, Color backgroundColor, IconData icon) {
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
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

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messages = ref.watch(chatHistoryProvider);
    final cart = ref.watch(chatCartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFB),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý ảo AI DineX',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white),
            tooltip: 'Xóa lịch sử chat',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              itemCount:
                  messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return _buildTypingRow();
                }

                final msg = messages[index];
                final isUser = msg['isUser'] as bool;
                final text = msg['text'] as String;
                final time = msg['time'] as String? ?? '';
                final showChips =
                    msg['showChips'] as bool? ?? false;
                final recommendations =
                    msg['recommendations'] as List<dynamic>?;
                final branchRecommendations =
                    msg['branchRecommendations']
                        as List<dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (!isUser) const AiAvatar(),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            ChatBubble(
                                text: text, isUser: isUser),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 4),
                              child: Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color:
                                      AppColors.textTertiary,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                            // Mini invoice card
                            if (!isUser &&
                                msg['resolvedItems'] != null &&
                                msg['orderPreview'] != null)
                              MiniInvoiceCard(
                                msg: msg,
                                onOrder: () =>
                                    _proceedToCheckout(
                                        msg['orderDraft']),
                              ),
                            // QR payment card
                            if (!isUser &&
                                msg['qrCode'] != null)
                              InlineQrPaymentCard(
                                orderId: msg['orderId'],
                                qrCode: msg['qrCode'],
                                amount: msg['amount'],
                                initialSecondsRemaining:
                                    msg['secondsRemaining'] ??
                                        600,
                                onCancel: () {
                                  _pollingTimer?.cancel();
                                  _hubConnection?.stop();
                                  ref
                                      .read(chatHistoryProvider
                                          .notifier)
                                      .update((state) {
                                    return state.map((m) {
                                      if (m['orderId'] ==
                                          msg['orderId']) {
                                        return {
                                          ...m,
                                          'qrCode': null,
                                          'orderId': null,
                                          'amount': null,
                                        };
                                      }
                                      return m;
                                    }).toList();
                                  });
                                },
                              ),
                            // Branch recommendations
                            if (branchRecommendations != null &&
                                branchRecommendations
                                    .isNotEmpty) ...[
                              const SizedBox(height: 16),
                              RecommendationsList(
                                recommendations:
                                    branchRecommendations,
                                onOpenStore: _openStoreDetail,
                                onNotification:
                                    _showTopNotification,
                              ),
                            ],
                            // Suggestive chips
                            if (showChips)
                              SuggestiveChips(
                                recommendations:
                                    recommendations,
                                onChipTap: _handleSubmitted,
                              ),
                          ],
                        ),
                      ),
                      if (isUser)
                        UserAvatar(user: currentUser),
                    ],
                  ),
                );
              },
            ),
          ),

          // Floating Checkout Bar (Chỉ hiển thị khi trong giỏ hàng chatCart có sản phẩm)
          if (cart.isNotEmpty)
            CheckoutBar(
              onCartTap: () =>
                  _showCartDetailsBottomSheet(context),
              onPickupTimeTap: _showPickupTimePicker,
              onQrTap: _sendDirectAction,
              selectedPickupTime: _selectedPickupTime,
            ),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Typing row ─────────────────────────────────────────────────────────────

  Widget _buildTypingRow() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AiAvatar(),
          BouncingDotsIndicator(),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────

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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        controller: _textController,
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
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 4),
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
              onTap: () =>
                  _handleSubmitted(_textController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD84315),
                      Color(0xFFFF6F3C)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD84315)
                          .withValues(alpha: 0.3),
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
}

